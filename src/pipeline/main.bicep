targetScope = 'subscription'

param location string = deployment().location

@allowed([
  'dev'
  'tst'
])
param environment string

param name string = 'apimdemo-productsservice'

param tags object = {}

var deployApimBackend = environment == 'dev'

var rgNamePrefix = '${loadJsonContent('../../bicep/azResourceAbbreviations.json').resourceGroup}-'

var rgNameSuffix = '-${environment}'

var rgName = startsWith(name, rgNamePrefix) ? (endsWith(name, rgNameSuffix) ? name : '${name}${rgNameSuffix}') : (endsWith(name, rgNameSuffix) ? '${rgNamePrefix}${name}' : '${rgNamePrefix}${name}${rgNameSuffix}')

var vnetName = 'vnet-apimdemo-${environment}'

var vnetResourceGroupName = 'rg-apimdemo-${environment}'

var peSubnetName = 'snet-pe-apimdemo-${environment}'

var aspSubnetName = 'snet-asp-apimdemo-${environment}'

var aspName = 'asp-apimdemo-${environment}'

var aspResourceGroupName = 'rg-apimdemo-${environment}'

var apimName = 'apim-apimdemo-${environment}'

var apimResourceGroupName = 'rg-apimdemo-${environment}'

var lawName = 'log-apimdemo-${environment}'

var lawResourceGroupName = 'rg-apimdemo-${environment}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}

module webapp '../../bicep/Web/webapp.bicep' = {
  name: '${deployment().name}-webapp'
  scope: resourceGroup
  params: {
    name: 'products-service'
    location: location
    environment: environment
    appServicePlanName: aspName
    appServicePlanResourceGroupName: aspResourceGroupName
    subnetName: aspSubnetName
    vnetName: vnetName
    vnetResourceGroupName: vnetResourceGroupName
    logAnalyticsWorkspaceResourceId: law.id
    linuxFxVersion: 'DOTNETCORE|7.0'
    allowPublicAccess: true // Only for demo purposes so Hosted Agents can deploy to the app
    createPrivateEndpoint: true
    privateEndpointSubnetName: peSubnetName
    dnsZoneId: websitesPrivateDnsZone.id
    tags: tags
  }
}

module apimBackend '../../bicep/ApiManagement/service/backend.bicep' = if(deployApimBackend) {
  name: '${deployment().name}-apimBackend'
  scope: az.resourceGroup(apimResourceGroupName)
  params: {
    name: replace(webapp.outputs.name, '-${environment}', '')
    apimName: apimName
    webAppName: webapp.outputs.name
    webAppResourceGroupName: resourceGroup.name
  }
}

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: lawName
  scope: az.resourceGroup(lawResourceGroupName)
}


resource websitesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.azurewebsites.net'
  scope: az.resourceGroup(vnetResourceGroupName)
}

output webAppName string = webapp.outputs.name
