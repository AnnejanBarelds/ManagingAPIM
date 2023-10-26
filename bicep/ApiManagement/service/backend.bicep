param name string

param webAppName string

param webAppResourceGroupName string

param apimName string

resource backend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: name
  parent: apim
  properties: {
    description: webApp.name
    protocol: 'http'
    resourceId: uri(environment().resourceManager, skip(webApp.id, 1))
    url: 'https://${webApp.properties.defaultHostName}'
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: webAppName
  scope: resourceGroup(webAppResourceGroupName)
}

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName
}
