param principalId string

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
  'ForeignGroup'
  'Device'
])
param principalType string

param appConfigurationName string

@allowed([
  'AppConfigurationDataOwner'
  'AppConfigurationDataReader'
])
param roleName string

var roles = [
  {
    RoleName: 'AppConfigurationDataOwner'
    RoleId: '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b'
  }
  {
    RoleName: 'AppConfigurationDataReader'
    RoleId: '516239f1-63e1-4d78-a4de-a74fb236a071'
  }
]

var roleId = first(filter(roles, role => role.RoleName == roleName))!.RoleId

resource appConfiguration 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigurationName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(appConfiguration.id, principalId, roleName)
  scope: appConfiguration
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}
