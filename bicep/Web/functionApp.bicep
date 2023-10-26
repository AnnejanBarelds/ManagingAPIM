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

param linuxFxVersion string = 'DOTNET|6.0'

@description('The value for the `FUNCTIONS_EXTENSION_VERSION` setting. Defaults to `~4`')
param functionsExtensionsVersion string = '~4'

@description('The value for the `FUNCTIONS_WORKER_RUNTIME` setting. Defaults to `dotnet`')
param functionsWorkerRuntime string = 'dotnet'

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

param privateEndpointVnetName string = ''

param privateEndpointSubnetName string = ''

param privateEndpointVnetResourceGroupName string = ''

param dnsZoneIdPrefix string = ''

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').functionApp}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

var defaultSettings = {
  FUNCTIONS_EXTENSION_VERSION: functionsExtensionsVersion
  FUNCTIONS_WORKER_RUNTIME: functionsWorkerRuntime
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: resourceName
  location: location
  tags: tags
  kind: 'linux,functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: asp.id
    httpsOnly: true
    virtualNetworkSubnetId: subnet.id
    clientAffinityEnabled: false
    publicNetworkAccess: createPrivateEndpoint ? 'Disabled' : 'Enabled'
  }
}

module configWeb 'Sites/configWeb.bicep' = {
  name: '${deployment().name}-configWeb'
  params: {
    linuxFxVersion: linuxFxVersion
    ipAddressesToWhitelist: ipAddressesToWhitelist
    siteName: functionApp.name
    subnetsToWhitelist: subnetsToWhitelist
    vnetRouteAllEnabled: environment != 'dev'
  }
}

module appSettings 'Sites/configAppSettings.bicep' = {
  name: '${deployment().name}-appSettings'
  params: {
    siteName: functionApp.name
    environment: environment
    appInsightsName: appInsights.outputs.name
    settings: union(union(settings, {AzureWebJobsStorage__accountName: storage.outputs.name}), defaultSettings)
    appConfigurationStoreName: appConfigurationStoreName
    appConfigurationStoreResourceGroupName: appConfigurationStoreResourceGroupName
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourceName}-diagnostic-setting'
  scope: functionApp
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'FunctionAppLogs'
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

module appInsights '../Insights/applicationInsights.bicep' = {
  name: '${deployment().name}-applicationInsights'
  params: {
    location: location
    name: resourceName
    environment: environment
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
  }
}

module appInsightsPermissions '../Authorization/roleAssignmentApplicationInsight.bicep' = {
  name: '${deployment().name}-appInsightsPermission'
  params: {
    appInsightName: appInsights.outputs.name
    environment: environment
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleName: 'MonitoringMetricsPublisher'
  }
}

module storage '../Storage/storageAccount.bicep' = {
  name: '${deployment().name}-storage'
  params: {
    ipAddressesToWhitelist: ['81.206.86.178']
    location: location
    name: uniqueString(subscription().subscriptionId, resourceName)
    environment: environment
    subnetsToWhitelist: [
      {
        resourceGroup: vnetResourceGroupName
        vnet: vnetName
        subnet: subnetName
      }
    ]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    createPrivateEndpoint: createPrivateEndpoint
    privateEndpointSubnetName: privateEndpointSubnetName
    privateEndpointVnetName: privateEndpointVnetName
    privateEndpointVnetResourceGroupName: privateEndpointVnetResourceGroupName
    dnsZoneIdPrefix: dnsZoneIdPrefix
  }
}

module storagePermission '../Authorization/roleAssignmentsStorage.bicep' = {
  name: '${deployment().name}-storagePermission'
  params: {
    environment: environment
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleName: 'StorageBlobDataOwner'
    storageAccountName: storage.outputs.name
  }
}

module privateEndpoint '../Network/privateEndpoint.bicep' = if(createPrivateEndpoint) {
  name: '${deployment().name}-privateEndpoint'
  params: {
    name: functionApp.name
    location: location
    environment: environment
    groupIds: [
      'sites'
    ]
    privateDnsZoneIds: [
      '${dnsZoneIdPrefix}.azurewebsites.net'
    ]
    privateLinkServiceId: functionApp.id
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

output id string = functionApp.id
output name string = functionApp.name
output principalId string = functionApp.identity.principalId
output appiConnectionString string = appInsights.outputs.connectionString
