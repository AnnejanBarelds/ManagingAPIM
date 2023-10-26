param location string = resourceGroup().location

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param tags object = {}

param zoneRedundant bool = false

param workerCount int = 1

param name string

param logAnalyticsWorkspaceResourceId string

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').appServicePlan}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

@allowed([
  {
    tier: 'Basic'
    name: 'B1'
  }
])
param sku object = {
  tier: 'Basic'
  name: 'B1'
}

resource serverFarm 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: resourceName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    tier: sku.tier
    name: sku.name
    capacity: workerCount
  }
  properties: {
    reserved: true
    zoneRedundant: zoneRedundant
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourceName}-diagnostic-setting'
  scope: serverFarm
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output name string = serverFarm.name
output id string = serverFarm.id
