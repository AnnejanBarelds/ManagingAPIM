param principalId string

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
  'ForeignGroup'
  'Device'
])
param principalType string

param keyVaultName string

param keyName string

@allowed([
  'KeyVaultSecretsUser'
  'KeyVaultAdministrator'
  'KeyVaultReader'
])
param roleName string

var roles = [
  {
    RoleName: 'KeyVaultSecretsUser'
    RoleId: '4633458b-17de-408a-b874-0445c86b69e6'
  }
  {
    RoleName: 'KeyVaultAdministrator'
    RoleId: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  }
  {
    RoleName: 'KeyVaultReader'
    RoleId: '21090545-7ca7-4776-b22c-e363652d74d2'
  }
]

var roleId = first(filter(roles, role => role.RoleName == roleName))!.RoleId

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource key 'Microsoft.KeyVault/vaults/keys@2023-02-01' existing = {
  name: keyName
  parent: keyVault
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(key.id, principalId, roleName)
  scope: key
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}
