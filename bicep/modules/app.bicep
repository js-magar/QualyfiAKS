param appGatewaySubnetName string
param appGatewayPIPName string
param appGatewayName string
param virtualNetworkName string

param RGLocation string
var applicationGatewayUserDefinedManagedIdentityName = '${appGatewayName}ManagedIdentity'
var applicationGatewayUserDefinedManagedIdentityId = applicationGatewayUserDefinedManagedIdentity.id
var appGWFIPConfigName = 'appGatewayFrontendConfig'
var appGWFPortName = 'frontendHttpPort80'
var appGWhttpListenerName='appGWHttpListener'
var appGWBAddressPoolName='backendAddressPool'
var appGWBHttpSettingsName = 'backendHttpPort80'
var wafPolicyName = '${appGatewayName}-WafPolicy'
var wafPolicyFileUploadLimitInMb = 100
var wafPolicyMaxRequestBodySizeInKb = 128
var wafPolicyRequestBodyCheck = true
var wafPolicyRuleSetType = 'OWASP'
var wafPolicyRuleSetVersion = '3.1'


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkName
}
resource AppGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: appGatewaySubnetName,parent: virtualNetwork}
resource appGatewayPIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: appGatewayPIPName
  location: RGLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
resource applicationGatewayUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: applicationGatewayUserDefinedManagedIdentityName
  location: RGLocation
}
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-05-01' = {
  name: wafPolicyName
  location: RGLocation
  properties: {
    customRules: [
      {
        name: 'BlockMe'
        priority: 1
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'QueryString'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              'blockme'
            ]
          }
        ]
      }
      {
        name: 'BlockEvilBot'
        priority: 2
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RequestHeaders'
                selector: 'User-Agent'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              'evilbot'
            ]
            transforms: [
              'Lowercase'
            ]
          }
        ]
      }
    ]
    policySettings: {
      requestBodyCheck: wafPolicyRequestBodyCheck
      maxRequestBodySizeInKb: wafPolicyMaxRequestBodySizeInKb
      fileUploadLimitInMb: wafPolicyFileUploadLimitInMb
      mode: 'Prevention'
      state: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: wafPolicyRuleSetType
          ruleSetVersion: wafPolicyRuleSetVersion
        }
      ]
    }
  }
}
resource appGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: appGatewayName
  location: RGLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${applicationGatewayUserDefinedManagedIdentityId}': {
      }
    }
  }
  properties:{
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    backendAddressPools:[
      {
        name:appGWBAddressPoolName
      }
    ]
    backendHttpSettingsCollection:[
      {
        name:appGWBHttpSettingsName
        properties:{
          port:80
          protocol:'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    frontendIPConfigurations:[
      {
        name:appGWFIPConfigName
        properties:{
          publicIPAddress:{
            id:appGatewayPIP.id
          }
        }
      }
    ]
    frontendPorts:[
      {
        name:appGWFPortName
        properties:{
          port:80
        }
      }
    ]
    gatewayIPConfigurations:[
      {
        name:'appGatewayIPConfig'
        properties:{
          subnet:{
            id:AppGatewaySubnet.id
          }
        }
      }
    ]
    httpListeners:[
      {
          name:appGWhttpListenerName
          properties:{
            frontendIPConfiguration:{
              id:resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, appGWFIPConfigName)
            }
            frontendPort:{
              id:resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, appGWFPortName)
            }
            protocol:'Http'
          }
      }
    ]
    requestRoutingRules:[
      {
        name:'appGWRoutingRule'
        properties:{
          ruleType:'Basic'
          priority: 1000
          httpListener:{
            id:resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, appGWhttpListenerName)
          }
          backendAddressPool:{
            id:resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, appGWBAddressPoolName)
          }
          backendHttpSettings:{
            id:resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, appGWBHttpSettingsName)
          }

        }
      }
    ]
    probes: [
      {
        name: 'defaultHttpProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
        }
      }
      {
        name: 'defaultHttpsProbe'
        properties: {
          protocol: 'Https'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
        }
      }
    ]
    autoscaleConfiguration:{
      minCapacity:0
      maxCapacity:10
    }
    firewallPolicy: {
      id: wafPolicy.id
    }
  }
}
output appGatwayId string = appGateway.id
output appGatwayUDMId string = applicationGatewayUserDefinedManagedIdentity.id
output appGatwayUDMName string = applicationGatewayUserDefinedManagedIdentity.name
