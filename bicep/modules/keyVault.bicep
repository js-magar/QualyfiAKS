param location string
param keyVaultName string
param applicationGatewayManagedIdentityName string
var podIdentityUserDefinedManagedIdentityName = 'id-pod-${location}-001'

resource applicationGatewayManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing  = {
  name: applicationGatewayManagedIdentityName
}

resource podManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: podIdentityUserDefinedManagedIdentityName
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: [
      {
        tenantId: reference(applicationGatewayManagedIdentity.id, '2022-01-31-preview').tenantId
        objectId: reference(applicationGatewayManagedIdentity.id, '2022-01-31-preview').principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
          ]
        }
      }
      {
        tenantId: reference(podManagedIdentity.id, '2022-01-31-preview').tenantId
        objectId: reference(podManagedIdentity.id, '2022-01-31-preview').principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
          ]
        }
      }
    ]
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: false
  }
}

output podIdentityUserDefinedManagedIdentityName string = podManagedIdentity.name
