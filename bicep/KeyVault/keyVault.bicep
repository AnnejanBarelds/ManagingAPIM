param location string = resourceGroup().location

param tags object = {}

@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param enablePurgeProtection bool = environment == 'prd'

param name string

param logAnalyticsWorkspaceResourceId string

param createPrivateEndpoint bool = true

param privateEndpointVnetName string

param privateEndpointSubnetName string

param privateEndpointVnetResourceGroupName string

param dnsZoneId string = ''

@description('''
A `subnetsToWhitelist` object contains a `resourceGroup`, `vnet`, `subnet`
''')
param subnetsToWhitelist array = []

@description('''
Contains IP addresses or CIDR ranges. Single IP addresses cannot be represented as a /32 CIDR
''')
param ipAddressesToWhitelist array = []

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').keyVault}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

var virtualNetworkRules = [for subnet in subnetsToWhitelist: {
  id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${subnet.resourceGroup}/providers/Microsoft.Network/virtualNetworks/${subnet.vnet}/subnets/${subnet.subnet}'
}]

var ipRules = [for ip in ipAddressesToWhitelist: {
  value: ip
}]

var baseProperties = {
  sku: {
    family: 'A'
    name: skuName
  }
  tenantId: tenant().tenantId
  enableSoftDelete: enablePurgeProtection ? true : false
  enableRbacAuthorization: true
  networkAcls: {
    bypass: 'AzureServices'
    defaultAction: 'Deny'
    virtualNetworkRules: createPrivateEndpoint ? [] : virtualNetworkRules
    ipRules: createPrivateEndpoint ? [] : ipRules
  }
  publicNetworkAccess: createPrivateEndpoint ? 'Disabled' : 'Enabled'
}

var properties = enablePurgeProtection ? union(baseProperties, { enablePurgeProtection: enablePurgeProtection }) : baseProperties

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: resourceName
  location: location
  tags: tags
  properties: properties
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourceName}-diagnostic-setting'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        categoryGroup: 'allLogs'
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

module privateEndpoint '../Network/privateEndpoint.bicep' = if(createPrivateEndpoint) {
  name: '${deployment().name}-privateEndpoint'
  params: {
    name: keyVault.name
    location: location
    environment: environment
    groupIds: [
      'vault'
    ]
    privateDnsZoneIds: [
      dnsZoneId
    ]
    privateLinkServiceId: keyVault.id
    subnetName: privateEndpointSubnetName
    vnetName: privateEndpointVnetName
    vnetResourceGroupName: privateEndpointVnetResourceGroupName
  }
}

output name string = keyVault.name
output id string = keyVault.id
