targetScope = 'subscription'

@description('Resource ID of the centralized Log Analytics workspace that all resource diagnostic logs should be routed to.')
param logAnalyticsWorkspaceId string = '/subscriptions/4a23dcea-b762-4569-b255-3c45517c941b/resourceGroups/rg-operations-shared/providers/Microsoft.OperationalInsights/workspaces/la-centralized-sentinel'

@description('Region for the assignment resource.')
param location string = 'eastus'

// Enable allLogs category group resource logging for supported resources to Log Analytics —
// built-in initiative (140 member policies, one per supported resource type) that deploys a
// diagnostic setting routing allLogs to the centralized workspace for every existing resource,
// and automatically catches newly created resources of the same types going forward since the
// underlying policies are DeployIfNotExists and evaluated on every resource write.
module centralizedLogging 'modules/policy-assignment-subscription.bicep' = {
  params: {
    assignmentName: 'centralized-diag-logging'
    displayName: 'Enable allLogs category group resource logging for supported resources to Log Analytics'
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/0884adba-2312-4468-abeb-5422caed1038'
    location: location
    identityType: 'SystemAssigned'
    parameters: {
      logAnalytics: {
        value: logAnalyticsWorkspaceId
      }
    }
    roleDefinitionIds: [
      '92aaf0da-9dab-42b6-94a3-d43ce8d16293' // Log Analytics Contributor, required by all 140 member policies
    ]
  }
}

output centralizedLoggingAssignmentId string = centralizedLogging.outputs.assignmentId

@description('Resource group where the Microsoft Defender for Cloud continuous export (Microsoft.Security/automations) configuration is deployed. Reuses the existing centralized operations resource group rather than creating a new one.')
param defenderExportResourceGroupName string = 'rg-operations-shared'

@description('Region of the resource group above, used by the policy to deploy the export configuration.')
param defenderExportResourceGroupLocation string = 'northcentralus'

// Deploy export to Log Analytics workspace for Microsoft Defender for Cloud data — single
// built-in DeployIfNotExists policy (not an initiative) that configures Defender for Cloud's
// "Continuous Export" feature, streaming security recommendations, alerts, secure score,
// secure score controls, and regulatory compliance data (plus weekly snapshots) to the
// centralized Log Analytics workspace. Reuses the existing rg-operations-shared resource
// group (createResourceGroup: false so the policy does not reset tags on it) since that is
// where the centralized workspace already lives.
module defenderContinuousExport 'modules/policy-assignment-subscription.bicep' = {
  params: {
    assignmentName: 'continuous-export-to-law'
    displayName: 'Deploy export to Log Analytics workspace for Microsoft Defender for Cloud data'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/ffb6f416-7bd2-4488-8828-56585fef2be9'
    location: location
    identityType: 'SystemAssigned'
    parameters: {
      workspaceResourceId: {
        value: logAnalyticsWorkspaceId
      }
      resourceGroupName: {
        value: defenderExportResourceGroupName
      }
      resourceGroupLocation: {
        value: defenderExportResourceGroupLocation
      }
      createResourceGroup: {
        value: false
      }
    }
    roleDefinitionIds: [
      'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor — required to create/manage the automation resource in the target resource group
    ]
  }
}

output defenderContinuousExportAssignmentId string = defenderContinuousExport.outputs.assignmentId
