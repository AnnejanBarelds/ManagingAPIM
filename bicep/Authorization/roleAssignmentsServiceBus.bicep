param principalId string

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
  'ForeignGroup'
  'Device'
])
param principalType string

param serviceBusNamespaceName string

@description('''
Specify a value for `queueName` if the role assignment should be scoped to a queue
''')
param queueName string = ''

@description('''
Specify a value for `topicName` if the role assignment should be scoped to a topic or a subscription
This value is ignored if `queueName` is also specified. To apply a role to both a queue and a topic, call this module twice
''')
param topicName string = ''

@description('''
Specify a value for `subscriptionName` if the role assignment should be scoped to a subscription; `topicName` should also be specified
This value is ignored if `queueName` is also specified. To apply a role to both a queue and a subscription, call this module twice
''')
param subscriptionName string = ''

@allowed([
  'AzureServiceBusDataOwner'
  'AzureServiceBusDataReceiver'
  'AzureServiceBusDataSender'
])
param roleName string

var roles = [
  {
    RoleName: 'AzureServiceBusDataOwner'
    RoleId: '090c5cfd-751d-490a-894a-3ce6f1109419'
  }
  {
    RoleName: 'AzureServiceBusDataReceiver'
    RoleId: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
  }
  {
    RoleName: 'AzureServiceBusDataSender'
    RoleId: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
  }
]

var roleId = first(filter(roles, role => role.RoleName == roleName))!.RoleId

resource roleAssignmentQueue 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(!empty(queueName)) {
  name: guid(serviceBusNamespace.id, queueName, topicName, subscriptionName, principalId, roleId)
  scope: queue
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}

resource roleAssignmentTopic 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(empty(queueName) && !empty(topicName) && empty(subscriptionName)) {
  name: guid(serviceBusNamespace.id, queueName, topicName, subscriptionName, principalId, roleId)
  scope: topic
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}

resource roleAssignmentSubscription 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(empty(queueName) && !empty(topicName) && !empty(subscriptionName)) {
  name: guid(serviceBusNamespace.id, queueName, topicName, subscriptionName, principalId, roleId)
  scope: subscription
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(empty(queueName) && empty(topicName) && empty(subscriptionName)) {
  name: guid(serviceBusNamespace.id, queueName, topicName, subscriptionName, principalId, roleId)
  scope: serviceBusNamespace
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: principalType
  }
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusNamespaceName
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' existing = {
  name: queueName
  parent: serviceBusNamespace
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' existing = {
  name: topicName
  parent: serviceBusNamespace
}

resource subscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' existing = {
  name: subscriptionName
  parent: topic
}
