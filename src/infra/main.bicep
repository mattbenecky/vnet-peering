targetScope = 'subscription'

// ----------
// PARAMETERS
// ----------

param name string
param location string = deployment().location

@description('ISO 8601 format datetime when the application, workload, or service was first deployed.')
param startDate string = dateTimeAdd(utcNow(),'-PT5H','G')

@allowed(['Dev','Prod','QA','Stage','Test'])
@description('Deployment environment of the application, workload, or service.')
param env string

@description('When creating Hub VNet, you must specify a custom private IP address space using public and private (RFC 1918) addresses.')
param vnetHubAddressSpace object

// Array of subnets for Hub VNet provided in parameters JSON file
@description('Subnets to segment Hub VNet into one or more sub-networks and allocate a portion of the address space to each subnet.')
param vnetHubSubnets array

@description('When creating Spoke VNet, you must specify a custom private IP address space using public and private (RFC 1918) addresses.')
param vnetSpokeAddressSpace object

// Array of subnets for Spoke VNet provided in parameters JSON file
@description('Subnets to segment Spoke VNet into one or more sub-networks and allocate a portion of the address space to each subnet.')
param vnetSpokeSubnets array

// ---------
// VARIABLES
// ---------

var tags = {
  Env: env
  StartDate: startDate
}

// ---------
// RESOURCES
// ---------

// Virtual network peering to connect Hub VNet to Spoke VNet
module peerHub 'modules/peer.bicep' = {
  scope: rg
  name: 'VirtualNetworkPeeringHub'
  params: {
    vnetName: vnetHub.outputs.vnetName
    peerName: 'Hub-to-Spoke'
    remoteVirtualNetwork: vnetSpoke.outputs.ID
  }
}

// Virtual network peering to connect Spoke VNet to Hub VNet
module peerSpoke 'modules/peer.bicep' = {
  scope: rg
  name: 'VirtualNetworkPeeringSpoke'
  params: {
    vnetName: vnetSpoke.outputs.vnetName
    peerName: 'Spoke-to-Hub'
    remoteVirtualNetwork: vnetHub.outputs.ID
  }
}

// Resource group is a container that holds related resources for an Azure solution
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}-${env}'
  location: location
  tags: tags
}

// Hub virtual network acts as a central point of connectivity to spoke virtual networks
module vnetHub 'modules/vnet.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'VirtualNetwork-Hub'
  params: {
    name: 'hub-${name}-${env}'
    location: location
    tags: tags
    addressSpace: vnetHubAddressSpace
    subnets: vnetHubSubnets
  }
}

// Spoke virtual network that isolates workload
module vnetSpoke 'modules/vnet.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'VirtualNetwork-Spoke'
  params: {
    name: 'spoke-${name}-${env}'
    location: location
    tags: tags
    addressSpace: vnetSpokeAddressSpace
    subnets: vnetSpokeSubnets
  }
}
