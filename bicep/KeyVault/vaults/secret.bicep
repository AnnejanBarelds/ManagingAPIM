param name string

@secure()
param value string

param keyVaultName string

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: name
  properties: {
    value: value
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

output secretUri string = secret.properties.secretUri
output name string = secret.name
