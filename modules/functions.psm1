function Write-Info {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "-> $Message" -InformationAction Continue -ForegroundColor Cyan
}