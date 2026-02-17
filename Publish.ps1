param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("major", "minor", "patch")]
    [string]$Bump
    
    # [Parameter(Mandatory = $true)]
    # [string]$Project,
    
    # [Parameter(Mandatory = $false)]
    # [string]$Blazor
)

$ErrorActionPreference = "Stop"

# Importa módulo pelo caminho (ajuste se necessário)
Import-Module "$PSScriptRoot\publish-tools.psm1" -Force

Write-Host "========== PUBLISH =========="

# Garante que o repositório está limpo
Ensure-CleanWorkingTree

Write-Host "Verificando branch atual"
$releaseBranch = Get-ReleaseBranch
$currentBranch = Get-CurrentBranch

if ($currentBranch -ne $releaseBranch) {
    Write-Host "Trocando para '$releaseBranch'..."
    Switch-ToBranch -Branch $releaseBranch
}

Run-UnitTests

# Obtém versão atual
$currentVersion = Get-LastVersion
Write-Host "Versão atual: $currentVersion"

# Calcula nova versão
$newVersion = Get-BumpedVersion `
    -CurrentVersion $currentVersion `
    -Bump $Bump

Write-Host "Nova versão: $newVersion"

Update-VersionInProjects -NewVersion $newVersion



Commit-VersionUpdate -NewVersion $newVersion

Write-Host "========== RELEASE CONCLUÍDA =========="
