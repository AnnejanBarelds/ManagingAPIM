param principalId string

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
  'ForeignGroup'
  'Device'
])
param principalType string

param appInsightName string

@allowed([
  'MonitoringContributor'
  'MonitoringMetricsPublisher'
  'MonitoringReader'
])
param roleName string

var roles = [
  {
    RoleName: 'MonitoringContributor'
    RoleId: '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
  }
  {
    RoleName: 'MonitoringMetricsPublisher'
    RoleId: '3913510d-42f4-4e42-8a64-420c390055eb'
  }
  {
    RoleName: 'MonitoringReader'
    RoleId: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
  }
]

var roleId = first(filter(roles, role => role.RoleName == roleName))!.RoleId

resource appInsight 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(appInsight.id, principalId, roleName)
  scope: appInsight
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}
