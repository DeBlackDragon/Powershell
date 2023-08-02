function Get-AuthTokenViaClientCredentials {
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = "ClientId of Azure AD Application, which should be used for authentication. Default: d1ddf0e4-d672-4dae-b554-9d5bdfd93547 (Microsoft Intune PowerShell)"
        )]
        [String]
        #! ClientID of Application Registration needed
        $clientId,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Resource Scope for which the token should be requested. Default: https://graph.microsoft.com/"
        )]
        [String]
        $resourceScope = "https://graph.microsoft.com/.default offline_access",
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Tenant ID, where the request should be located."
        )]
        [String]
        #! TenantID of destination Tenant
        $tenantId,
        #! Secret of the used Application Registration
        [Parameter(Mandatory = $true)]
        [String]
        $clientSecret
    )

    Write-Verbose -Message $("Preparing Authentication.")

    $AccessTokenRequestParams = @{
        Method = 'POST'
        Uri    = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
        Body   = @{
            client_id     = $ClientId
            scope         = $resourceScope
            tenant        = $tenantId
            client_secret = $clientSecret
            grant_type    = "client_credentials"
        }
    }

    Write-Verbose -Message $("Send Request to endpoint [https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token]")
    try {

        $tokenResponse = Invoke-RestMethod @AccessTokenRequestParams

        Write-Verbose -Message $("Successfully fetched authentication code!")

        $global:accessToken = $($tokenResponse).access_token
        $global:authHeader = @{
            'Content-Type'  = 'application/json'
            'Authorization' = "Bearer " + $accessToken
        }

        Write-Verbose -Message $("Successfully fetched access token!")
    }
    catch {
        Write-Verbose -Message $("Couln´t fetch device code. Please check error.") -Level Warning
        Write-Verbose -Message $(Get-Error) -Level Error
    }
}