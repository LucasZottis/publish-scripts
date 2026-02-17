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

# Obtém os projetos que serão publicados
$projects = $publishSettings.Projects

foreach ($project in $Config.Projects) {
    switch($project.Type) {
        "API" { & publish-api.ps1 -project $project }
        "Blazor" { & publish-blazor.ps1 -project $project }
    }
}
