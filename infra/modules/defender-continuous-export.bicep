@description('Name of the Microsoft.Security/automations resource.')
param automationName string = 'export-to-centralized-law'

@description('Azure region for the automation resource.')
param location string

@description('Fully qualified resource ID of the target Log Analytics workspace.')
param workspaceResourceId string

@description('Fully qualified subscription resource ID that continuous export applies to (e.g. subscription().id).')
param subscriptionScopeId string

@description('Tags to apply to the automation resource.')
param tags object = {}

// Deploys Microsoft.Security/automations directly (rather than relying solely on
// policy DeployIfNotExists remediation) so Defender for Cloud Continuous Export
// to the centralized Sentinel workspace is guaranteed at deployment time.
// Must be deployed after the target Log Analytics workspace exists and after
// Defender for Cloud plans have been enabled (see main.bicep dependsOn ordering).
resource continuousExport 'Microsoft.Security/automations@2019-01-01-preview' = {
  name: automationName
  location: location
  tags: tags
  properties: {
    description: 'Continuous export of Defender for Cloud data to the centralized Sentinel Log Analytics workspace.'
    isEnabled: true
    scopes: [
      {
        description: 'Subscription-wide scope'
        scopePath: subscriptionScopeId
      }
    ]
    sources: [
      { eventSource: 'Assessments' }
      { eventSource: 'AssessmentsSnapshot' }
      { eventSource: 'Alerts' }
      { eventSource: 'SecureScores' }
      { eventSource: 'SecureScoresSnapshot' }
      { eventSource: 'SecureScoreControls' }
      { eventSource: 'SecureScoreControlsSnapshot' }
      { eventSource: 'RegulatoryComplianceAssessment' }
      { eventSource: 'RegulatoryComplianceAssessmentSnapshot' }
    ]
    actions: [
      {
        actionType: 'Workspace'
        workspaceResourceId: workspaceResourceId
      }
    ]
  }
}

output automationId string = continuousExport.id
output automationName string = continuousExport.name
