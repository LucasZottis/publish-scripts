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

function Remove-File {
    param(
        [Parameter(Mandatory = $true)]
        $FilePath
    )

    if (-not (Test-Path $FilePath)) {
        $FilePath = [System.IO.Path]::GetFullPath($FilePath)
    }

    $fileName = [System.IO.Path]::GetFileName($FilePath)

    if (-not (Test-Path $FilePath)) {
        Write-Warn "$fileName não encontrado em: $FilePath"
    }
    else {
        Remove-Item -Path $FilePath
    }
}

function Remove-Folder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    # Converte para caminho absoluto sem exigir existência
    $fullPath = [System.IO.Path]::GetFullPath($FolderPath)

    if (-not (Test-Path $fullPath)) {
        Write-Warn "O caminho especificado não existe: $fullPath"
        exit 0
    }

    try {
        Remove-Item -Path $fullPath -Recurse -Force
        Write-Log "Pasta removida com sucesso: $fullPath"
    }
    catch {
        Write-Error "Erro ao remover a pasta: $_"
        exit 1
    }
}