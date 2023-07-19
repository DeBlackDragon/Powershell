<#
.SYNOPSIS
    This script lists the private endpoint records for a given tenant scope, subscription or management group.
    It uses the Resource Graph to query the private endpoints and exports the results to a CSV file.

.PARAMETER SubscriptionId
   The ID of the subscription to list private endpoint records for.

.PARAMETER ManagementGroup
    The ID of the management group to list private endpoint records for.

.NOTES
    Author: [Benjamin Dassow]
    Date: [19.07.2023]
    Version: [0.1]

.EXAMPLE
    List-PrivateEndpointsRecords.ps1 -ManagementGroup "myManagementGroup"

    This example lists the private endpoint records for the  "myManagementGroup" management group.

.EXAMPLE
    List-PrivateEndpointsRecords.ps1 SubscriptionId "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

    This example lists the private endpoint records for the  Subscription with the given Id.

.EXAMPLE
    List-PrivateEndpointsRecords.ps1

    This example lists the private endpoint records for the current tenant scope.    

#>
#Requires -Modules Az.Accounts, Az.ResourceGraph
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = "Subscription ID")]
    [string]
    $subscriptionId,
    [Parameter(Mandatory = $false, HelpMessage = "Management Group ID")]
    [string]
    $managementGroup
)
# Connect to Azure
try {
    $currentContext = Get-AzContext -ErrorAction Stop
    If ($null -eq $currentContext) {
        throw 
    }
    Write-Output "You are already connected to Azure."
}
catch {
    Write-Output "No active Session found. Please connect to Azure."
    Connect-AzAccount
}

# Prepare Resource Graph Query Configuration
$splatResourceGraph = @{
    Query = "Resources | where type =~ 'Microsoft.Network/privateEndpoints' | project name, customDnsConfigs=properties.customDnsConfigs"
}
# Check provided Parameters
if (($PSBoundParameters.ContainsKey('subscriptionId') -eq $false) -and ($PSBoundParameters.ContainsKey('managementGroup') -eq $false)) {
    Write-Output "No Subscription or Management Group provided. Using Tenant Scope"
    $splatResourceGraph.Add("UseTenantScope", $true)
}

# Check if both parameters are provided
if (($PSBoundParameters.ContainsKey('subscriptionId') -eq $true) -and ($PSBoundParameters.ContainsKey('managementGroup') -eq $true)) {
    Write-Output "Please provide either a Subscription or a Management Group. Not both."
    break
}

# Check if SubscriptionId is provided
if ($PSBoundParameters.ContainsKey('subscriptionId') -eq $true) {
    Write-Output "Setting scope to Subscription $subscriptionId"
    $splatResourceGraph.Add("Subscription", $subscriptionId)
}

# Check if ManagementGroup is provided
if ($PSBoundParameters.ContainsKey('managementGroup') -eq $true) {
    Write-Output "Setting scope to Subscription $managementGroup"
    $splatResourceGraph.Add("ManagementGroup", $managementGroup)
}

# Get all Private Endpoints via Resource Graph
$resourceGraphResult = Search-AzGraph @splatResourceGraph
$endpointCollection = New-Object 'System.Collections.Generic.List[System.Object]'

foreach ($entry in $resourceGraphResult) {
    if ($entry.customDnsConfigs.count -eq 0) {
        continue
    }
    $resourceName = $entry.customDnsConfigs.fqdn.split(".")[0]
    $resourceDNS = $("privatelink." + $($($entry.customDnsConfigs.fqdn.split("."))[1..$($entry.customDnsConfigs.fqdn.Length - 1)] -join "."))
    $endpointCollection.Add(@{
            "IpAddress"    = $entry.customDnsConfigs.ipAddresses
            "ResourceName" = $resourceName
            "DnsZone"      = $resourceDNS
        })
}

$fileName = $($(Get-Date -Format "yyyy-MM-dd") + "_PrivateEndpointRecords.csv")
$endpointCollection | Export-Csv -Path $fileName -NoTypeInformation
