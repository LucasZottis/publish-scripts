$ErrorActionPreference = "Stop"

Write-Host "🔧 Inicializando configuração do repositório..." -ForegroundColor Cyan

# Diretório atual (raiz do repositório)
$repoPath = Get-Location
$configPath = Join-Path $repoPath "publish.settings.json"

# Verifica se já existe
if (Test-Path $configPath) {
    Write-Host "⚠ Já existe um arquivo publish.settings.json neste repositório." -ForegroundColor Yellow
    return
}

# Tenta obter branch atual
$defaultBranch = "main"

try {
    $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($gitBranch) {
        $defaultBranch = $gitBranch.Trim()
    }
}
catch {
    Write-Host "Git não encontrado ou não é um repositório git." -ForegroundColor DarkYellow
}

# Estrutura base
$config = @{
    DefaultBranch = $defaultBranch
    Projects = @(
        @{
            Name        = ""
            Path        = ""
            PublishPath = ""
            Type        = ""
            Scripts     = @{
                Before = @()
                After  = @()
            }
        }
    )
}

# Converte para JSON formatado
$json = $config | ConvertTo-Json -Depth 10

# Salva arquivo
Set-Content -Path $configPath -Value $json -Encoding UTF8

Write-Host "✅ Arquivo publish.settings.json criado com sucesso!" -ForegroundColor Green
Write-Host "📁 Caminho: $configPath"
