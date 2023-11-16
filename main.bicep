param entraGroupID string

var RGLocation = resourceGroup().location
var acrName = 'aksacrjash'
var acrSKU = 'Basic'
var linuxAdminUsername = 'username'
var linuxAdminSSH ='ssh'

var vnetAddressPrefix = '10.0'
var virtualNetworkName = 'virtualNetwork'
var appGatewaySubnetAddressPrefix = '1'
var appGatewaySubnetName = 'AppgwSubnet'
var appGatewayPIPName = 'pip-appGateway-jash-${RGLocation}-001'
var appGatewayName = 'appGateway-jash-${RGLocation}-001'

var aksSubnetAddressPrefix = '2'
var aksClusterName = 'aksclusterjash'
var aksSubnetName = 'aksClusterSubnet'


var bastionSubnetAddressPrefix = '3'
var bastionClusterName = 'bastion-jash-${RGLocation}-001'
var bastionSubnetName = 'AzureBastionSubnet'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name:'LAWAcrResource'
  location:RGLocation
  properties:{
    features:{
      enableLogAccessUsingOnlyResourcePermissions:true
    }
  }
}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: virtualNetworkName
  location: RGLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '${vnetAddressPrefix}.0.0/16'
      ]
    }
    subnets: [
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${appGatewaySubnetAddressPrefix}.0/24'
        }
      }
      {
        name: aksSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${aksSubnetAddressPrefix}.0/24'
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${bastionSubnetAddressPrefix}.0/24'
        }
      }
    ]
  }
}
module appGateway 'modules/app.bicep'={
  name:'appGatewayDeployment'
  params:{
    appGatewaySubnetName : appGatewaySubnetName
    appGatewayPIPName:appGatewayPIPName
    appGatewayName:appGatewayName
    virtualNetworkName:virtualNetworkName
  }
  dependsOn:[
    virtualNetwork
  ]
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
  
resource aksClusterResource 'Microsoft.ContainerService/managedClusters@2023-08-01' = {
    name: aksClusterName
    location: RGLocation
    sku: {
      name: 'Base'
      tier: 'Free'
    }
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      kubernetesVersion: '1.26.6' 
      enableRBAC: true
      dnsPrefix: 'akscluster-jash'
      aadProfile:{
        managed:true
        adminGroupObjectIDs:[
          entraGroupID
        ]
        tenantID:''
      }
      agentPoolProfiles: [
        {
          name: 'systempool'
          count: 1
          vmSize: 'Standard_DS2_v2' 
          maxPods:30
          maxCount:20
          minCount:1
          enableAutoScaling:true
          osType: 'Linux'
          osSKU: 'CBLMariner'
          mode: 'System'
        }
        {
          name: 'apppool'
          count: 1
          vmSize: 'Standard_DS2_v2' 
          maxPods:30
          maxCount:20
          minCount:1
          enableAutoScaling:true
          osType: 'Linux'
          osSKU: 'CBLMariner'
          mode: 'System'
          osDiskSizeGB: 30 // or specify the desired disk size
          osDiskType: 'Managed' // or choose 'Ephemeral' if supported
          osProfile: {
            linuxProfile: {
              adminUsername: linuxAdminUsername
              ssh: {
                publicKeys: [
                  {
                    keyData: linuxAdminSSH
                  }
                ]
              }
            }
          }
        }
      ]
      networkProfile: {
        loadBalancerSku: 'Standard'
        outboundType: 'loadBalancer'
    }
  }
}

