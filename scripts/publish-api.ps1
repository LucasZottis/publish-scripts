param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Project,

    [Parameter(Mandatory = $true)]
    [string]$NewVersion
)

try {
    # # Importação de módulos
    Import-Module "$PSScriptRoot\..\modules\DotnetFunctions.psm1" -Force

    Write-Title "Projeto API: $($Project.Name)"

    # Executa testes unitários
    Start-UnitTests

    # Obtém última versão
    # $lastVersion = Get-LastVersion

    # Obtém nova versão
    # $newVersion = Get-BumpedVersion -CurrentVersion $lastVersion -Bump $Global:Bump

    $directory = Split-Path $Project.Path -Parent

    # Atualiza versão nos projetos
    Update-VersionInProjects -NewVersion $NewVersion -Path $directory

    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

    # BEFORE
    if ($Project.Scripts -and $Project.Scripts.Before) {

    }

    $projectPath = (Resolve-Path $Project.Path).Path
    $outputPath = [System.IO.Path]::GetFullPath($Project.PublishPath)

    Start-ApiPublish -ProjectPath $projectPath -OutputPath $outputPath

    # AFTER
    if ($Project.Scripts -and $Project.Scripts.After) {
        foreach ($script in $Project.Scripts.After) {
            Invoke-Script -ScriptConfig $script -ScriptRoot $scriptRoot
        }
    }

    # Write-Host "✔ $($Project.Name) publicado com sucesso!" -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}