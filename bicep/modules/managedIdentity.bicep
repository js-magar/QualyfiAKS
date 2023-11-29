param keyVaultName string
param aksResourceID string
param acrPullRDName string 
param contributorRoleDefName string
param readerRoleDefName string
param netContributorRoleDefName string
param aksClusterUserDefinedManagedIdentityName string
param applicationGatewayUserDefinedManagedIdentityName string
param kvManagedIdentityName string
param aksClusterName string

var aksContributorRoleAssignmentName = guid(aksClusterUserDefinedManagedIdentity.id, contributorRoleId, resourceGroup().id)
var appGwContributorRoleAssignmentName = guid(applicationGatewayUserDefinedManagedIdentity.id, contributorRoleId, resourceGroup().id)
var appGwNetContributorRoleAssignmentName = guid(applicationGatewayUserDefinedManagedIdentity.id, netContributorRoleId, resourceGroup().id)
var keyVaultReaderRoleAssignmentName = guid(kvUserDefinedManagedIdentity.id, readerRoleId, resourceGroup().id)

var acrPullRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRDName)
var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefName)
var readerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleDefName)
var netContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', netContributorRoleDefName)

var acrPullRoleAssignmentName = guid('${resourceGroup().id}acrPullRoleAssignment')

resource applicationGatewayUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing  = {name: applicationGatewayUserDefinedManagedIdentityName}
resource aksClusterUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {name: aksClusterUserDefinedManagedIdentityName}
resource kvUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing  = {name: kvManagedIdentityName}
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {name: keyVaultName}
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-08-01' existing = {name:aksClusterName}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: acrPullRoleAssignmentName
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: reference(aksResourceID, '2023-08-01', 'Full').properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}
resource aksContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: aksContributorRoleAssignmentName
  properties: {
    roleDefinitionId: contributorRoleId
    description: 'Assign the cluster user-defined managed identity contributor role on the resource group.'
    principalId: aksClusterUserDefinedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
resource appGwContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: appGwContributorRoleAssignmentName
  properties: {
    roleDefinitionId: contributorRoleId
    principalId: reference(aksResourceID, '2023-08-01', 'Full').properties.addonProfiles.ingressApplicationGateway.identity.objectId
    principalType: 'ServicePrincipal'
  }
}
resource appGwNetContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: appGwNetContributorRoleAssignmentName
  properties: {
    roleDefinitionId: netContributorRoleId
    principalId: reference(aksResourceID, '2023-08-01', 'Full').properties.addonProfiles.ingressApplicationGateway.identity.objectId
    principalType: 'ServicePrincipal'
  }
}
resource keyVaultReaderRoleAssignment  'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: keyVaultReaderRoleAssignmentName
  properties: {
    roleDefinitionId: readerRoleId
    principalId: kvUserDefinedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
resource keyVaultAdminRoleAssignment  'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(kvUserDefinedManagedIdentity.id, keyVaultSecretsAdminRole.id, resourceGroup().id)
  properties: {
    roleDefinitionId: keyVaultSecretsAdminRole.id
    principalId: kvUserDefinedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
resource keyVaultSecretsUserApplicationGatewayIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' =  {
  name: guid(keyVault.id, 'ApplicationGateway', 'keyVaultSecretsUser')
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRole.id
    principalType: 'ServicePrincipal'
    principalId: applicationGatewayUserDefinedManagedIdentity.properties.principalId
  }
}
resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '4633458b-17de-408a-b874-0445c86b69e6'
  scope: subscription()
}
resource keyVaultSecretsAdminRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  scope: subscription()
}
resource keyVaultCSIdriverSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksCluster.id, 'CSIDriver', keyVaultSecretsUserRole.id)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRole.id
    principalType: 'ServicePrincipal'
    principalId: aksCluster.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId
  }
}
