param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("major", "minor", "patch")]
    [string]$Bump
)

$ErrorActionPreference = "Stop"

# Importação de módulos
Import-Module "$PSScriptRoot\modules\git-functions.psm1" -Force

# Garante que o repositório está limpo
Ensure-CleanWorkingTree

# Diretório onde o usuário executou o comando
$executionRoot = (Get-Location).Path

# Arquivo de configuração que está no diretório de execução
$publishSettings = Get-PublishSettings -path $executionRoot

foreach ($project in $publishSettings.Projects) {

    $type = $project.Type.ToLower()
    $scriptName = "publish-$type.ps1"
    $scriptPath = Join-Path $PSScriptRoot "scripts\$scriptName"

    if (-not (Test-Path $scriptPath)) {
        throw "Script de publicação não encontrado para o tipo '$($project.Type)': $scriptPath"
    }

    & $scriptPath -Project $project
}

