@description('Storage Account type')
param storageAccountType string = 'Standard_LRS'

@description('Location for the storage account.')
param location string = resourceGroup().location

@description('The name of the Storage Account')
param storageAccountName string = 'store${uniqueString(resourceGroup().id)}'

@description('The name of the container')
param containerName string = 'scepman'

@description('Array of User ObjectIds of the service principal that will be used to access the storage account as Storage Blob Data Contributor')
param principalIds array = []

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {}
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${storageAccount.name}/default/${containerName}'
  properties: {
    publicAccess: 'None'
  }
}

// Storage Blob Data Contributor
@description('This is the built-in Storage Blob Data Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for principalId in principalIds: {
  scope: storageAccount
  name: guid(storageAccount.id, principalId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: principalId
    principalType: 'User'
  }
}]

var outputTemplate = [
  'subscription_id      = ${subscription().subscriptionId}'
  'storage_account_name = ${storageAccount.name}'
  'container_name       = ${containerName}'
  'key                  = scepman.tfstate'
  'use_azuread_auth     = true'
  'snapshot             = true'
]

output backendConfig array = outputTemplate
