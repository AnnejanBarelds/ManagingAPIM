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

param disableLocalAuth bool = true

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').applicationInsights}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: resourceName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceResourceId
    DisableLocalAuth: disableLocalAuth
  }
}

output name string = appInsights.name
output id string = appInsights.id
output connectionString string = appInsights.properties.ConnectionString
