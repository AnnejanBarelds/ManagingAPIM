param principalId string

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
  'ForeignGroup'
  'Device'
])
param principalType string

param storageAccountName string

@allowed([
  'StorageBlobDataOwner'
])
param roleName string

var roles = [
  {
    RoleName: 'StorageBlobDataOwner'
    RoleId: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
  }
]

var roleId = first(filter(roles, role => role.RoleName == roleName))!.RoleId

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount.id, principalId, roleName)
  scope: storageAccount
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}
