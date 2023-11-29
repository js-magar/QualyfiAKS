param aksClusterName string
param entraGroupID string
param logAnalyticsWorkspaceID string
param appGatewayID string
param vnetName string
param systemSubnetName string
param appSubnetName string
param podSubnetName string
param adminUsername string
param adminPasOrKey string

param location string
param aksClusterPodCidr string = '10.244.0.0/16'
param aksClusterServiceCidr string = '10.5.0.0/16'
param aksClusterDnsServiceIP string = '10.5.0.10'

var aksClusterUserDefinedManagedIdentityName = 'mi-${aksClusterName}-${location}'
var aksClusterDNSPrefix ='akscluster-jash'
var rgName = resourceGroup().name

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {name: vnetName}
resource AppPoolSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: appSubnetName,parent: virtualNetwork}
resource SystemPoolSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: systemSubnetName,parent: virtualNetwork}
resource PodSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: podSubnetName,parent: virtualNetwork}

resource aksClusterUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: aksClusterUserDefinedManagedIdentityName
  location: location
}
resource aksClusterResource 'Microsoft.ContainerService/managedClusters@2023-08-01' = {
  name: aksClusterName
  location: location
  sku: {
      name: 'Base'
      tier: 'Free'
  }
  identity: {
      type: 'UserAssigned'
      userAssignedIdentities: {
        '${aksClusterUserDefinedManagedIdentity.id}': {
        }
      }
  }
  properties: {
    kubernetesVersion: '1.26.6' 
    enableRBAC: true
    dnsPrefix: aksClusterDNSPrefix
    disableLocalAccounts:true
    aadProfile:{
        managed:true
        adminGroupObjectIDs:[
          '${entraGroupID}'
        ]
        tenantID:subscription().tenantId
    }
    agentPoolProfiles: [
        {name: 'systempool'
          count: 1
          vmSize: 'Standard_DS2_v2' 
          vnetSubnetID:SystemPoolSubnet.id
          podSubnetID:PodSubnet.id
          maxPods:30
          maxCount:20
          minCount:1
          enableAutoScaling:true
          osType: 'Linux'
          osSKU: 'CBLMariner'
          mode: 'System'

        }
        {name: 'apppool'
          count: 1
          vmSize: 'Standard_DS2_v2' 
          vnetSubnetID:AppPoolSubnet.id
          podSubnetID:PodSubnet.id
          maxPods:30
          maxCount:20
          minCount:1
          enableAutoScaling:true
          osType: 'Linux'
          osSKU: 'CBLMariner'
          mode: 'System'
        }
    ]
    linuxProfile: {
        adminUsername: adminUsername
        ssh:{
          publicKeys: [
            {
              keyData: 'ssh-rsa ${adminPasOrKey}\n'
            }
          ]
        }
    }
    networkProfile: {
      outboundType: 'userAssignedNATGateway'
      networkPlugin:'azure'
      networkPolicy: 'azure'
      podCidr: aksClusterPodCidr
      serviceCidr: aksClusterServiceCidr
      dnsServiceIP: aksClusterDnsServiceIP
    }
    nodeResourceGroup:'MC-${rgName}'
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceID
        }
      }
      aciConnectorLinux: {
        enabled: false
      }
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      kubeDashboard: {
        enabled: false
      }
      ingressApplicationGateway: {
        config: {
          applicationGatewayId: appGatewayID
        }
        enabled: true
      }
      azureKeyvaultSecretsProvider: {
        config: {
          enableSecretRotation: 'false'
        }
        enabled: true
      }
    }
    azureMonitorProfile: {
      metrics: {
        enabled: true
      }
    }
  }
}
output aksClusterId string = aksClusterResource.id
output aksClusterUserDefinedManagedIdentityName string = aksClusterUserDefinedManagedIdentity.name
