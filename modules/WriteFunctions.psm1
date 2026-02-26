function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [boolean]$NewLine = $false
    )

    Write-Host "➜ $Message" -InformationAction Continue
}

function Write-Info {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [boolean]$NewLine = $false
    )

    Write-Host "ℹ️ $Message" -InformationAction Continue -ForegroundColor Cyan

    if ($NewLine) {
        Write-Host ""
    }
}

function Write-Warn {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [boolean]$NewLine = $false
    )

    Write-Host "⚠️ $Message" -InformationAction Continue -ForegroundColor Yellow

    if ($NewLine) {
        Write-Host ""
    }
}

function Write-Success {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [boolean]$NewLine = $false
    )

    Write-Host "✅ $Message" -InformationAction Continue -ForegroundColor Green

    if ($NewLine) {
        Write-Host ""
    }
}

function Write-Title {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    # Adiciona 2 espaços de cada lado
    $paddedTitle = "  $Title  "

    # Calcula o tamanho total (título + 4 espaços)
    $lineLength = $paddedTitle.Length

    # Gera linha dinâmica de "="
    $separator = "=" * $lineLength

    Write-Host "" -ForegroundColor Magenta
    Write-Host $separator -ForegroundColor Magenta
    Write-Host $paddedTitle -ForegroundColor Magenta
    Write-Host $separator -ForegroundColor Magenta
    Write-Host "" -ForegroundColor Magenta
} 

Export-ModuleMember -Function *