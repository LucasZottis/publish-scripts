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
    
    # Atualiza versão nos projetos
    $directory = Split-Path $Project.Path -Parent
    Update-VersionInProjects -NewVersion $NewVersion -Path $directory

    # BEFORE
    if ($Project.Scripts -and $Project.Scripts.Before) {
        Resolve-PublishScripts -Scripts $Project.Scripts.Before
    }

    $projectPath = (Resolve-Path $Project.Path).Path
    $outputPath = [System.IO.Path]::GetFullPath($Project.PublishPath)

    Start-ApiPublish -ProjectPath $projectPath -OutputPath $outputPath

    # AFTER
    if ($Project.Scripts -and $Project.Scripts.After) {
        Resolve-PublishScripts -Scripts $Project.Scripts.After
    }

    # Write-Host "✔ $($Project.Name) publicado com sucesso!" -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}