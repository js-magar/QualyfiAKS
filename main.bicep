var RGLocation = resourceGroup().location
var aksClusterName = 'aksclusterjash'
var acrName = 'aksacrjash'
var acrSKU = 'Basic'
var AppgwSubnetName = 'AppgwSubnetName'
var linuxAdminUsername = 'username'
var linuxAdminSSH ='ssh'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name:'LAWAcrResource'
  location:RGLocation
  properties:{
    features:{
      enableLogAccessUsingOnlyResourcePermissions:true
    }
  }
}
/*
module appGateway 'modules/app.bicep'={
  name:'appGatewayDeployment'
  params:{
    appGatewaySubnetName :AppgwSubnetName
    vnetAddressPrefix:'10.0'
  }
}
*/
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
    name: 'aksclusterjash'
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
          name: 'applicationpool'
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
  /*
  module buildDaprImage 'br/public:deployment-scripts/build-acr:2.0.2' = {
    name: 'buildAcrImage-linux'
    params: {
      AcrName: acrName
      location: RGLocation
      gitRepositoryUrl:  ' https://github.com/Azure-Samples/azure-voting-app-redis.git'
      buildWorkingDirectory:  'azure-vote'
      imageName: 'mcr.microsoft.com/azuredocs/azure-vote-front'
    }
    dependsOn:[
      acrResource
    ]
  }
  */
/*{"code":"DeploymentScriptError","message":"WARNING: Sending context to registry: aksacrjash..."},
  {"code":"DeploymentScriptError","message":"WARNING: Queued a build with ID: ca2"},
  {"code":"DeploymentScriptError","message":"WARNING: Waiting for an agent..."},{"code":"DeploymentScriptError","message":"ERROR: Run failed"
*/

