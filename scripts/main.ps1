param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("major", "minor", "patch")]
    [string]$Bump
)

$ErrorActionPreference = "Stop"

# Importação de módulos
Import-Module "$PSScriptRoot\modules\git-functions.psm1" -Force
Import-Module "$PSScriptRoot\modules\publish-functions.psm1" -Force

# Garante que o repositório está limpo
Ensure-CleanWorkingTree

# Diretório onde o usuário executou o comando
$executionRoot = (Get-Location).Path

# Arquivo de configuração que está no diretório de execução
$publishSettings = Get-PublishSettings -path $executionRoot

# Obtém o branch atual
$currentBranch = Get-CurrentBranch 

# Troca o branch se não estiver no branch padrão
if ($publishSettings.DefaultBranch -ne $currentBranch) {
    Switch-ToBranch -Branch $publishSettings.DefaultBranch
}

# Executa testes unitários
Run-UnitTests

# Obtém última versão
$lastVersion = Get-LastVersion

# Obtém nova versão
$newVersion = Get-BumpedVersion -CurrentVersion lastVersion -Bump $Bump

# Atualiza versão nos projetos
Update-VersionInProjects -NewVersion $newVersion

# BEFORE
if ($publishSettings.Scripts -and $publishSettings.Scripts.Before) {
    foreach ($script in $publishSettings.Scripts.Before) {
        Invoke-CustomScript -ScriptConfig $script -ScriptRoot $scriptRoot
    }
}

foreach ($project in $publishSettings.Projects) {
    $type = $project.Type.ToLower()
    $scriptName = "publish-$type.ps1"
    $scriptPath = Join-Path $PSScriptRoot $scriptName

    if (-not (Test-Path $scriptPath)) {
        throw "Script de publicação não encontrado para o tipo '$($project.Type)': $scriptPath"
    }

    & $scriptPath -Project $project
}

# AFTER
if ($publishSettings.Scripts -and $publishSettings.Scripts.After) {
    foreach ($script in $publishSettings.Scripts.After) {
        Invoke-CustomScript -ScriptConfig $script -ScriptRoot $scriptRoot
    }
}
