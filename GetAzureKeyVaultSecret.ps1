# The following is a custom function to pull secrets from a key vault using an SPN to authenticate.
# Only meant to be used in event where you are unable to use Az.Keyvault azure module

Function GetKeyVaultSecret{

    param(
        [parameter(Mandatory)]
        [string]$tenantId,
        [parameter(Mandatory)]
        [string]$appID,
        [parameter(Mandatory)]
        [string]$appSecret,
        [parameter(Mandatory)]
        [string]$vaultName,
        [parameter(Mandatory)]
        [string]$secretName

    )

    $body = @{
        grant_type    = "client_credentials"
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "https://vault.azure.net/.default"
    }
    try{
        $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$($tenantId)/oauth2/v2.0/token" `
                                        -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    }catch{
        write-host "Error getting token value using:
        
        ClientID=$($clientId)
        ClientSecret=$($clientSecret)
        TentantID=$($tenantId)  
        
        ErrDetails= $($_)" -ForegroundColor Red
    }

    $accessToken = $tokenResponse.access_token

    try{

        $vaultUri = "https://$($vaultName).vault.azure.net/secrets/$($secretName)?api-version=7.2"

        $response = Invoke-WebRequest -Uri $vaultUri -Method Get -Headers @{ Authorization = "Bearer $accessToken" }

        $secretValue = ($response.Content | ConvertFrom-Json).value
  
    }catch{
        write-host "Error getting secret value for $($secretName) in $($vaultName) | ErrDetails= $($_)" -ForegroundColor Red
    }

    return $secretValue
}
