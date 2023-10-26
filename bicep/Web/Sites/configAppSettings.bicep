param appConfigurationStoreName string = ''

param appConfigurationStoreResourceGroupName string = ''

param siteName string

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param appInsightsName string

param settings object

var aspNetCoreEnvironments = [
  {
    Environment: 'dev'
    AspNetCoreEnvironment: 'Development'
  }
  {
    Environment: 'tst'
    AspNetCoreEnvironment: 'Test'
  }
  {
    Environment: 'acc'
    AspNetCoreEnvironment: 'Acceptance'
  }
  {
    Environment: 'prd'
    AspNetCoreEnvironment: 'Production'
  }
]

var appInsightsSetting = !empty(appInsightsName) ? {
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
} : {}

var appConfigSettings = !empty(appConfigurationStoreName) ? {
  AppConfig__Endpoint: appConfigurationStore.properties.endpoint
} : {}

var internalSettings = union(union({
  ASPNETCORE_ENVIRONMENT: first(filter(aspNetCoreEnvironments, aspNetCoreEnvironment => aspNetCoreEnvironment.Environment == environment))!.AspNetCoreEnvironment
}, appInsightsSetting), appConfigSettings)

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource appConfigurationStore 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigurationStoreName
  scope: resourceGroup(appConfigurationStoreResourceGroupName)
}

resource config 'Microsoft.Web/sites/config@2021-03-01' = {
  name: '${siteName}/appsettings'
  properties: union(internalSettings, settings)
}
