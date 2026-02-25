param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Project,

    [Parameter(Mandatory = $true)]
    [string]$NewVersion
)

try {
    # # Importação de módulos
    Import-Module "$PSScriptRoot\..\modules\DotnetFunctions.psm1" -Force
    Write-Title "Projeto: $($Project.Name)"

    # Executa testes unitários
    Write-Info "Executando testes unitários..."
    Start-UnitTests
    Write-Success "Testes unitários finalizados!"
    
    # Atualiza versão nos projetos
    Write-Info "Atualizando versão nos projetos..."
    $directory = Split-Path $Project.Path -Parent
    Update-VersionInProjects -NewVersion $NewVersion -Path $directory
    Write-Success "Projetos atualizados"

    # BEFORE
    if ($Project.Scripts -and $Project.Scripts.Before) {
        Write-Info "Iniciando execução dos scripts pré publicação do projeto..."
        Resolve-PublishScripts -Scripts $Project.Scripts.Before
        Write-Success "Scripts executados!"
    }

    $projectPath = (Resolve-Path $Project.Path).Path
    $outputPath = [System.IO.Path]::GetFullPath($Project.PublishPath)
    Start-ApiPublish -ProjectPath $projectPath -OutputPath $outputPath

    # AFTER
    if ($Project.Scripts -and $Project.Scripts.After) {
        Write-Info "Iniciando execução dos scripts pós publicação do projeto..."
        Resolve-PublishScripts -Scripts $Project.Scripts.After
        Write-Success "Scripts executados!"
    }

    Write-Success "Publicação de ""$($Project.Name)"" finalizado!"
}
catch {
    Write-Error $_
    exit 1
}