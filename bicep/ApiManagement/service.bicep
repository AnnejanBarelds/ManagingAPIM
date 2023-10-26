param location string = resourceGroup().location

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param name string

param logAnalyticsWorkspaceResourceId string

param keyVaultName string

param vnetName string

param subnetName string

param vnetResourceGroupName string

param privateDnsZonesResourceGroupName string

param privateDnsZonesSubscriptionId string

param deploySubResources bool = environment == 'dev'

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').apiManagementServiceInstance}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

var skuName = environment == 'prd' ? 'Premium' : 'Developer'

var privateDnsZones = [
  'azure-api.net'
  'portal.azure-api.net'
  'developer.azure-api.net'
  'management.azure-api.net'
  'scm.azure-api.net'
]

module publicIPAddress '../Network/publicIPAddress.bicep' = {
  name: '${deployment().name}-publicIPAddress'
  params: {
    name: resourceName
    location: location
    dnsLabelPrefix: resourceName
    environment: environment
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
  }
}

resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' = {
  name: resourceName
  location: location
  sku: {
    capacity: 1
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'beheer@customer.com'
    publisherName: 'Customer.com'
    virtualNetworkType: 'Internal'
    publicIpAddressId: publicIPAddress.outputs.id
    apiVersionConstraint: {
      minApiVersion: '2019-12-01'
    }
    virtualNetworkConfiguration: {
      subnetResourceId: subnet.id
    }
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_GCM_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'true'
    }
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourceName}-diagnostic-setting'
  scope: apim
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

module urlNamedValue 'service/namedValue.bicep' = if(deploySubResources) {
  name: '${deployment().name}-urlNamedValue'
  params: {
    apimName: apim.name
    name: 'gatewayUrl'
    value: apim.properties.gatewayUrl
  }
}

module appInsights '../Insights/applicationInsights.bicep' = {
  name: '${deployment().name}-appInsights'
  params: {
    environment: environment
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    name: resourceName
    disableLocalAuth: false
  }
}

module logger 'service/logger.bicep' = {
  name: '${resourceName}-logger'
  params: {
    name: 'appInsightsLogger'
    keyVaultName: keyVaultName
    apimName: apim.name
    appInsightsName: appInsights.outputs.name
    deploySubResources: deploySubResources
  }
  dependsOn: [
    dnsRecords
  ]
}

module dnsZones '../Network/privateDnsZone.bicep' = [for (privateDnsZone, i) in privateDnsZones: {
  name: '${deployment().name}-dnsZone-${i}'
  params: {
    name: '${apim.name}.${privateDnsZone}'
    vnetsToLink: [
      {
        name: vnetName
        resourceGroupName: vnetResourceGroupName
        subscriptionId: subscription().subscriptionId
      }
    ]
  }
}]

module dnsRecords '../Network/privateDnsZones/aRecord.bicep' = [for (privateDnsZone, i) in privateDnsZones: {
  name: take('${deployment().name}-dns-${i}', 64)
  scope: resourceGroup(privateDnsZonesSubscriptionId, privateDnsZonesResourceGroupName)
  params: {
    name: '@'
    ipAddresses: apim.properties.privateIPAddresses
    privateDnsZoneName: dnsZones[i].outputs.name
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: subnetName
  parent: vnet
}

output id string = apim.id
output name string = apim.name
output ipAddress array = apim.properties.privateIPAddresses
output gatewayUrl string = apim.properties.gatewayUrl
