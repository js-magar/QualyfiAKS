param acrName string
//param acrSKU string
param logAnalyticsName string
param aksResourceID string
param acrPullRDName string 
param contributorRoleDefName string
//param readerRoleDefName string
param aksClusterUserDefinedManagedIdentityName string
param applicationGatewayUserDefinedManagedIdentityName string
param aksClusterName string
param appGatewayName string

param RGLocation string
var aksContributorRoleAssignmentName = guid('${resourceGroup().id}${aksClusterUserDefinedManagedIdentityName}${aksClusterName}')
var appGwContributorRoleAssignmentName = guid('${resourceGroup().id}${applicationGatewayUserDefinedManagedIdentityName}${appGatewayName}')

var acrPullRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRDName)
var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefName)
//var readerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleDefName)

var acrPullRoleAssignmentName = '${guid('${resourceGroup().id}acrPullRoleAssignment')}'
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name:logAnalyticsName
}
resource acrResource 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  location: RGLocation
  name:acrName
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
      exportPolicy: {
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}
resource acrDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
    scope: acrResource
    name: 'default'
    properties: {
      workspaceId: logAnalyticsWorkspace.id
      metrics: [
        {
          timeGrain: 'PT1M'
          category: 'AllMetrics'
          enabled: true
        }
      ]
      logs: [
        {
          category: 'ContainerRegistryRepositoryEvents'
          enabled: true
        }
        {
          category: 'ContainerRegistryLoginEvents'
          enabled: true
        }
    ]
  }
}
resource aksClusterUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: aksClusterUserDefinedManagedIdentityName
}
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: acrPullRoleAssignmentName
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: reference(aksResourceID, '2023-08-01', 'Full').properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    acrResource
  ]
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
/*
resource keyVaultName_Microsoft_Authorization_id_readerRoleId 'Microsoft.KeyVault/vaults/providers/roleAssignments@2020-04-01-preview' = {
  name: '${keyVaultName}/Microsoft.Authorization/${guid(concat(resourceGroup().id), readerRoleId)}'
  properties: {
    roleDefinitionId: readerRoleId
    principalId: reference(aadPodIdentityUserDefinedManagedIdentityId).principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    keyVaultId
    aadPodIdentityUserDefinedManagedIdentityId
  ]
}
*/
