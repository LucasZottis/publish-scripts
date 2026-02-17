param(
  [Parameter(Mandatory = $true)]
  [pscustomobject]$Project
)

# Importação de módulos
Import-Module "$PSScriptRoot\modules\publish-functions.psm1" -Force
Import-Module "$PSScriptRoot\modules\dotnet-functions.psm1" -Force

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "=============================="
Write-Host "Publicando: $($Project.Name)"
Write-Host "=============================="

# BEFORE
if ($Project.Scripts -and $Project.Scripts.Before) {
    foreach ($script in $Project.Scripts.Before) {
        Invoke-CustomScript -ScriptConfig $script -ScriptRoot $scriptRoot
    }
}

$projectPath = Resolve-Path (Join-Path $scriptRoot $Project.Path)
$outputPath  = Join-Path $scriptRoot $Project.Output

Run-ApiPublish -ProjectPath $projectPath -OutputPath $outputPath

# AFTER
if ($project.Scripts -and $Project.Scripts.After) {
    foreach ($script in $Project.Scripts.After) {
        Invoke-CustomScript -ScriptConfig $script -ScriptRoot $scriptRoot
    }
}

Write-Host "✔ $($Project.Name) publicado com sucesso!"
