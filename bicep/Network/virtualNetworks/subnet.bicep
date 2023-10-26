param location string = resourceGroup().location

param name string

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param logAnalyticsWorkspaceResourceId string

param vnetName string

param addressPrefix string

param routeTableName string = ''

param routeTableResourceGroupName string = resourceGroup().name

param nsgResourceGroupName string = resourceGroup().name

param nsgSecurityRules array = []

param delegations array = []

param serviceEndpoints array = []

@allowed([
  'Enabled'
  'Disabled'
])
param privateEndpointNetworkPolicies string = 'Disabled'

var namePrefix = '${loadJsonContent('../../azResourceAbbreviations.json').virtualNetworkSubnet}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

var se = [for endpoint in serviceEndpoints: {
  service: endpoint
  locations: [
    'westeurope'
  ]
}]

var properties = !empty(routeTableName) ? {
  addressPrefix: addressPrefix
  delegations: delegations
  serviceEndpoints: se
  routeTable: {
    id: routeTable.id
  }
  networkSecurityGroup: {
    id: nsg.outputs.id
  }
  privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
} : {
  addressPrefix: addressPrefix
  delegations: delegations
  serviceEndpoints: se
  networkSecurityGroup: {
    id: nsg.outputs.id
  }
  privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  name: resourceName
  parent: vnet
  properties: properties
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vnetName
}

resource routeTable 'Microsoft.Network/routeTables@2022-11-01' existing = if(!empty(routeTableName)) {
  name: routeTableName
  scope: resourceGroup(routeTableResourceGroupName)
}

module nsg '../networkSecurityGroup.bicep' = {
  name: '${deployment().name}-nsg'
  scope: resourceGroup(nsgResourceGroupName)
  params: {
    environment: environment
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    name: resourceName
    securityRules: nsgSecurityRules
  }
}

output name string = subnet.name
output id string = subnet.id
output nsgId string = nsg.outputs.id
output nsgName string = nsg.outputs.name
