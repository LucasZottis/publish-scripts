param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Project
)

try {
    # Importação de módulos
    Import-Module "$PSScriptRoot\..\modules\git-functions.psm1" -Force
    Import-Module "$PSScriptRoot\..\modules\publish-functions.psm1" -Force
    Import-Module "$PSScriptRoot\..\modules\dotnet-functions.psm1" -Force

    Write-Title "Iniciando publicação do projeto $($Project.Name)"

    # Executa testes unitários
    Start-UnitTests

    # Obtém última versão
    $lastVersion = Get-LastVersion

    # Obtém nova versão
    $newVersion = Get-BumpedVersion -CurrentVersion $lastVersion -Bump $Global:Bump

    $directory = Split-Path $Project.Path -Parent

    # Atualiza versão nos projetos
    Update-VersionInProjects -NewVersion $newVersion -Path $directory

    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

    # BEFORE
    if ($Project.Scripts -and $Project.Scripts.Before) {
        foreach ($script in $Project.Scripts.Before) {
            Invoke-CustomScript -ScriptConfig $script -ScriptRoot $scriptRoot
        }
    }

    $projectPath = (Resolve-Path $Project.Path).Path
    $outputPath = (Resolve-Path $Project.PublishPath).Path

    Start-ApiPublish -ProjectPath $projectPath -OutputPath $outputPath

    # # AFTER
    # if ($Project.Scripts -and $Project.Scripts.After) {
    #     foreach ($script in $Project.Scripts.After) {
    #         Invoke-CustomScript -ScriptConfig $script -ScriptRoot $scriptRoot
    #     }
    # }

    Write-Host "✔ $($Project.Name) publicado com sucesso!"
}
catch {
    Write-Error $_
    exit 1
}