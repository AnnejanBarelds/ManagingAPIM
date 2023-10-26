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

@allowed([
  'KeyVaultSecretsUser'
  'KeyVaultAdministrator'
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
]

var roleId = first(filter(roles, role => role.RoleName == roleName))!.RoleId

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(keyVault.id, principalId, roleName)
  scope: keyVault
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}
