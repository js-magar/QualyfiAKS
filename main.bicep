param entraGroupID string
param acrRoleDefName string 
param contributorRoleDefName string
param readerRoleDefName string
param netContributorRoleDefName string

var RGLocation = resourceGroup().location
var acrName = 'aksacrjash'
var acrSKU = 'Basic'

var vnetAddressPrefix = '10'
var virtualNetworkName = 'virtualNetwork'

var systemPoolSubnetName = 'SystemPoolSubnet'
var systemPoolSubnetAddressPrefix = '1'
var appPoolSubnetName = 'AppPoolSubnet'
var appPoolSubnetAddressPrefix = '2'


var podSubnetAddressPrefix = '3'
var podSubnetName = 'PodSubnet'

var appgwbastionPrefix ='4'
var appGatewaySubnetAddressPrefix = '1'
var appGatewaySubnetName = 'AppgwSubnet'
var appGatewayPIPName = 'pip-appGateway-jash-${RGLocation}-001'
var appGatewayName = 'appGateway-jash-${RGLocation}-001'

var bastionSubnetAddressPrefix = '2'
var bastionName = 'bastion-jash-${RGLocation}-001'
var bastionSubnetName = 'AzureBastionSubnet'

var aksClusterName = 'aksclusterjash'
var natGatewayName = '${aksClusterName}NatGateway'
var natGatewayPIPPrefixName = '${aksClusterName}PIPPrefix'


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name:'LAWAcrResource'
  location:RGLocation
  properties:{
    features:{
      enableLogAccessUsingOnlyResourcePermissions:true
    }
  }
}
resource publicIPPrefix 'Microsoft.Network/publicIPPrefixes@2022-05-01' = {
  name: natGatewayPIPPrefixName
  location: RGLocation
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    prefixLength: 28
    publicIPAddressVersion: 'IPv4'
  }
}
resource natGateway 'Microsoft.Network/natGateways@2022-05-01' = {
  name: natGatewayName
  location: RGLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpPrefixes: [
      {
        id: publicIPPrefix.id
      }
    ]
  }
}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: virtualNetworkName
  location: RGLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '${vnetAddressPrefix}.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: systemPoolSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${systemPoolSubnetAddressPrefix}.0.0/16'
          natGateway:{
            id:natGateway.id
          }
        }
      }
      {
        name: appPoolSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${appPoolSubnetAddressPrefix}.0.0/16'
          natGateway:{
            id:natGateway.id
          }
        }
      }
      {
        name: podSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${podSubnetAddressPrefix}.0.0/16'
          natGateway:{
            id:natGateway.id
          }
          delegations: [
            {
              name: 'Delegation'
              properties: {
                serviceName: 'Microsoft.ContainerService/managedClusters'
              }
            }
          ]
        }
      }
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${appgwbastionPrefix}.${appGatewaySubnetAddressPrefix}.0/24'
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: '${vnetAddressPrefix}.${appgwbastionPrefix}.${bastionSubnetAddressPrefix}.0/24'
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
    RGLocation:RGLocation
  }
  dependsOn:[
    virtualNetwork
  ]
}
module acr 'modules/acr.bicep' = {
  name:'appContainerRegistryDeployment'
  params:{
    acrName:acrName
    logAnalyticsName:logAnalyticsWorkspace.name
    //acrSKU:acrSKU
    acrPullRDName:acrRoleDefName
    aksResourceID:aksCluster.outputs.aksClusterId
    contributorRoleDefName:contributorRoleDefName
    netContributorRoleDefName:netContributorRoleDefName
    //readerRoleDefName:readerRoleDefName
    aksClusterUserDefinedManagedIdentityName:aksCluster.outputs.aksClusterUserDefinedManagedIdentityName
    applicationGatewayUserDefinedManagedIdentityName:appGateway.outputs.appGatwayUDMName
    aksClusterName:aksClusterName
    appGatewayName:appGatewayName
    RGLocation:RGLocation
  }
}
module aksCluster 'modules/aksCluster.bicep' = {
  name: 'aksClusterDeployment'
  params:{
    aksClusterName:aksClusterName
    entraGroupID:entraGroupID
    logAnalyticsWorkspaceID :logAnalyticsWorkspace.id
    appGatewayID:appGateway.outputs.appGatwayId
    vnetName:virtualNetworkName
    appSubnetName:appPoolSubnetName
    systemSubnetName:systemPoolSubnetName
    podSubnetName:podSubnetName
    RGLocation:RGLocation
  }
  dependsOn:[
    appGateway
  ]
}
module metrics 'modules/monitor_metrics.bicep' = {
  name: 'metricsDeployment'
  params:{
    RGLocation:RGLocation
    clusterName:aksClusterName
  }
  dependsOn:[
    acr
    aksCluster
    appGateway
  ]
}
/*
resource containerInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'containerInsights'
  location: RGLocation
  plan: {
    name: 'containerInsights'
    promotionCode: ''
    product: 'OMSGallery/ContainerInsights'
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  dependsOn:[
    acr
  ]
}
*/
