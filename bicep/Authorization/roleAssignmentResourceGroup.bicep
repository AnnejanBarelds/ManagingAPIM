param principalId string

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
  'ForeignGroup'
  'Device'
])
param principalType string

param resourceGroupName string

@allowed([
  'Contributor'
  'Owner'
  'Reader'
])
param roleName string

var roles = [
  {
    RoleName: 'Contributor'
    RoleId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  }
  {
    RoleName: 'Owner'
    RoleId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  }
  {
    RoleName: 'Reader'
    RoleId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  }
]

var roleId = first(filter(roles, role => role.RoleName == roleName))!.RoleId

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroupName, principalId, roleName)
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}
