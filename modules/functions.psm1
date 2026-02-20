function Write-Info {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "-> $Message" -InformationAction Continue -ForegroundColor Cyan
}

function Write-Warn {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "** $Message **" -InformationAction Continue -ForegroundColor Yellow
}

function Write-Warn {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "-> $Message" -InformationAction Continue -ForegroundColor Green
}

function Write-Title {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "" -InformationAction Continue -ForegroundColor Magenta
    Write-Host "=================================================================" -InformationAction Continue -ForegroundColor Magenta
    Write-Host $Message -InformationAction Continue -ForegroundColor Magenta
    Write-Host "=================================================================" -InformationAction Continue -ForegroundColor Magenta
}