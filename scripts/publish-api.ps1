param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Project,

    [Parameter(Mandatory = $true)]
    [string]$NewVersion
)

try {
    Write-Title "Projeto API: $($Project.Name)"
    
    # # Importação de módulos
    Import-Module "$PSScriptRoot\..\modules\DotnetFunctions.psm1" -Force

    # Executa testes unitários
    Start-UnitTests

    # Atualiza versão nos projetos
    $directory = Split-Path $Project.Path -Parent
    Update-VersionInProjects -NewVersion $NewVersion -Path $directory

    # BEFORE
    if ($Project.Scripts -and $Project.Scripts.Before) {
        Invoke-PublishScripts -Scripts $Project.Scripts.Before
    }

    $projectPath = (Resolve-Path $Project.Path).Path
    $outputPath = [System.IO.Path]::GetFullPath($Project.PublishPath)
    Start-ApiPublish -ProjectPath $projectPath -OutputPath $outputPath

    # AFTER
    if ($Project.Scripts -and $Project.Scripts.After) {
        Invoke-PublishScripts -Scripts $Project.Scripts.After
    }

    Write-Success "✔ $($Project.Name) publicado com sucesso!"
}
catch {
    Write-Error $_
    exit 1
}
