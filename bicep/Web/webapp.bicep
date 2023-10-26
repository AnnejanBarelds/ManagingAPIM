param location string = resourceGroup().location

param settings object = {}

param appConfigurationStoreName string = ''

param appConfigurationStoreResourceGroupName string = ''

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param tags object = {}

param linuxFxVersion string = 'DOTNETCORE|6.0'

@description('''
A `subnetsToWhitelist` object contains a `resourceGroup`, `vnet`, `subnet`
''')
param subnetsToWhitelist array = []

@description('''
Contains IP addresses in CIDR notation. Single IP addresses should be represented as a /32 CIDR
''')
param ipAddressesToWhitelist array = []

param name string

param appServicePlanName string

param appServicePlanResourceGroupName string

param vnetName string

param vnetResourceGroupName string

param subnetName string

param logAnalyticsWorkspaceResourceId string

param createPrivateEndpoint bool = true

param allowPublicAccess bool = false

param privateEndpointVnetName string = vnetName

param privateEndpointSubnetName string = ''

param privateEndpointVnetResourceGroupName string = vnetResourceGroupName

param dnsZoneId string = ''

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').webApp}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: resourceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'linux,api'
  properties: {
    serverFarmId: asp.id
    virtualNetworkSubnetId: subnet.id
    httpsOnly: true
    clientAffinityEnabled: false
    publicNetworkAccess: allowPublicAccess ? 'Enabled' : 'Disabled'
  }
}

module configWeb 'Sites/configWeb.bicep' = {
  name: '${deployment().name}-configWeb'
  params: {
    linuxFxVersion: linuxFxVersion
    ipAddressesToWhitelist: ipAddressesToWhitelist
    siteName: webApp.name
    subnetsToWhitelist: subnetsToWhitelist
    vnetRouteAllEnabled: true
  }
}

module appSettings 'Sites/configAppSettings.bicep' = {
  name: '${deployment().name}-appSettings'
  params: {
    siteName: webApp.name
    environment: environment
    appInsightsName: appInsights.outputs.name
    settings: settings
    appConfigurationStoreName: appConfigurationStoreName
    appConfigurationStoreResourceGroupName: appConfigurationStoreResourceGroupName
  }
}

module appInsights '../Insights/applicationInsights.bicep' = {
  name: '${deployment().name}-applicationInsights'
  params: {
    location: location
    name: resourceName
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    environment: environment
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourceName}-diagnostic-setting'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

module appInsightsPermissions '../Authorization/roleAssignmentApplicationInsight.bicep' = {
  name: '${deployment().name}-appInsightsPermission'
  params: {
    appInsightName: appInsights.outputs.name
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleName: 'MonitoringMetricsPublisher'
  }
}

module privateEndpoint '../Network/privateEndpoint.bicep' = if(createPrivateEndpoint) {
  name: '${deployment().name}-privateEndpoint'
  params: {
    name: webApp.name
    location: location
    environment: environment
    groupIds: [
      'sites'
    ]
    privateDnsZoneIds: [
      dnsZoneId
    ]
    privateLinkServiceId: webApp.id
    subnetName: privateEndpointSubnetName
    vnetName: privateEndpointVnetName
    vnetResourceGroupName: privateEndpointVnetResourceGroupName
  }
}

resource asp 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: appServicePlanName
  scope: resourceGroup(appServicePlanResourceGroupName)
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: subnetName
  parent: vnet
}

output id string = webApp.id
output name string = webApp.name
output principalId string = webApp.identity.principalId
output appiConnectionString string = appInsights.outputs.connectionString
