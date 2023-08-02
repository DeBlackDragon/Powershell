# Kudos to Liam Cleary for the original code:
# https://helloitsliam.com/2021/10/12/using-invoke-mggraphrequest-within-the-microsoft-graph-powershell/

function Get-MgAllPages {
    [CMDletbinding(
        ConfirmImpact = "Medium",
        DefaultParameterSetName = 'SearchResult'
    )]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "NextLink", ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('@odata.nextLink')]
        [string]$NextLink,
        [Parameter(Mandatory = $true, ParameterSetName = "SearchResult", ValueFromPipeline = $true)]
        [ValidateNotNull()]
        $SearchResult,
        [Parameter(Mandatory = $false)]
        [switch]$ToPSCustomObject
    )
    begin {}
    process {
        if ($PSCmdlet.ParameterSetName -eq 'SearchResult') {
            # Set the current page to the search result provided
            $page = $SearchResult

            # Extract the next link from the search result
            $currentNextLink = $page.'@odata.nextLink'

            # Check for current page count
            if ($page.ContainsKey('@odata.count')) {
                Write-Verbose "First page value count: $($page.'@odata.count')"
            }

            if ($($page.ContainsKey('@odata.nextLink')) -or $($page.ContainsKey('value'))) {
                $values = $page.value
            }
            else {
                $values = $page
            }

            if ($values) {
                if ($ToPSCustomObject) {
                    $values | Foreach-Object { [PSCustomObject]$_ }
                }
                else {
                    $values | Write-Output
                }
            }
        }
        while (-Not([string]::IsNullOrWhiteSpace($currentNextLink))) {
            try {
                $page = Invoke-MgGraphRequest -Uri $currentNextLink -Method Get 
            }
            catch {
                throw $_
            }
            $currentNextLink = $page.'@odata.nextLink'

            # Output the items in the page
            $values = $page.value

            if ($page.ContainsKey('@odata.count')) {
                Write-Verbose "Current page value count: $($Page.'@odata.count')"    
            }

            # Default returned objects are hashtables, so this makes for easy pscustomobject conversion on demand
            if ($ToPSCustomObject) {
                $values | ForEach-Object { [pscustomobject]$_ }   
            }
            else {
                $values | Write-Output
            }                
        }
    }
    end {}
}