param name string

param apimName string

param appInsightsName string

param appInsightsResourceGroupName string = resourceGroup().name

param keyVaultName string

param deploySubResources bool

resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' existing = {
  name: apimName
  resource logger 'loggers' = if(deploySubResources) {
    name: name
    properties: {
      loggerType: 'applicationInsights'
      resourceId: appInsights.id
      credentials: {
        instrumentationKey: '{{appinsights-key}}'
      }
    }
    dependsOn: [
      apim::namedValueAppInsightsKey
    ]
  }
  resource namedValueAppInsightsKey 'namedValues' = if(deploySubResources) {
    name: 'appinsights-key'
    properties: {
      secret: true
      displayName: 'appinsights-key'
      keyVault: {
        secretIdentifier: kvSecret.outputs.secretUri
      }
    }
    dependsOn: [
      kvSecretPermission
    ]
  }
}

module kvSecret '../../KeyVault/vaults/secret.bicep' = {
  name: '${deployment().name}-kvSecret'
  params: {
    keyVaultName: keyVaultName
    name: 'APIMLoggerInstrumentationKey'
    value: appInsights.properties.InstrumentationKey
  }
}

module kvSecretPermission '../../Authorization/roleAssignmentKeyVaultSecret.bicep' = {
  name: '${deployment().name}-kvSecretPerm'
  params: {
    keyVaultName: keyVaultName
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
    roleName: 'KeyVaultSecretsUser'
    secretName: kvSecret.outputs.name
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
  scope: resourceGroup(appInsightsResourceGroupName)
}
