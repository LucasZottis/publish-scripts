$ErrorActionPreference = "Stop"

Write-Host "🔧 Criando arquivo de configuração..." -ForegroundColor Cyan

# Diretório onde o comando está sendo executado (repositório)
$repoPath = Get-Location
$destinationPath = Join-Path $repoPath "publish.settings.json"

# Diretório onde está o Publicador (onde está o script)
$publicadorPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $publicadorPath "json\publish.settings.template.json"

# Verifica se já existe configuração no repositório
if (Test-Path $destinationPath) {
    Write-Host "⚠ Já existe publish.settings.json neste repositório." -ForegroundColor Yellow
    return
}

# Verifica se o template existe no Publicador
if (-not (Test-Path $templatePath)) {
    throw "Arquivo modelo não encontrado em: $templatePath"
}

# Copia o arquivo
Copy-Item -Path $templatePath -Destination $destinationPath

Write-Host "✅ Arquivo criado com sucesso!" -ForegroundColor Green
Write-Host "📁 Caminho: $destinationPath"