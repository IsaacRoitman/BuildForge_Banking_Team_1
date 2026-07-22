targetScope = 'subscription'

@description('Azure region for all resources.')
param location string = 'northcentralus'

@description('Name of the resource group to create.')
param resourceGroupName string = 'rg-operations-shared'

@description('Name of the Log Analytics workspace.')
param workspaceName string = 'la-centralized-sentinel'

@description('Log Analytics SKU.')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param workspaceSku string = 'PerGB2018'

@description('Data retention in days for the Log Analytics workspace.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@description('Tags to apply to all resources.')
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module sentinelWorkspace 'modules/sentinel-workspace.bicep' = {
  name: 'sentinelWorkspaceDeployment'
  scope: rg
  params: {
    location: location
    workspaceName: workspaceName
    workspaceSku: workspaceSku
    retentionInDays: retentionInDays
    tags: tags
  }
}

// Deployed after sentinelWorkspace (explicit dependsOn) so the target Log Analytics
// workspace is guaranteed to exist before Defender for Cloud Continuous Export is
// configured. Defender for Cloud plans themselves are enabled separately via the
// "Configure Microsoft Defender for Cloud plans" policy initiative (policy/main.bicep)
// and must be assigned/remediated before this module is deployed.
module defenderContinuousExport 'modules/defender-continuous-export.bicep' = {
  name: 'defenderContinuousExportDeployment'
  scope: rg
  params: {
    location: location
    subscriptionScopeId: subscription().id
    workspaceResourceId: sentinelWorkspace.outputs.workspaceId
    tags: tags
  }
}

output resourceGroupName string = rg.name
output workspaceId string = sentinelWorkspace.outputs.workspaceId
output workspaceName string = sentinelWorkspace.outputs.workspaceName
output defenderContinuousExportAutomationId string = defenderContinuousExport.outputs.automationId
