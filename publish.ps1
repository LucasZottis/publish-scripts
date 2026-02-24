param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Version
)

Import-Module "$PSScriptRoot\modules\DevToolz.psm1" -Force
Import-Module "$PSScriptRoot\modules\GitFunctions.psm1" -Force
Import-Module "$PSScriptRoot\modules\PublishFunctions.psm1" -Force

try {
    # Detecta se é bump ou versão específica
    $bumpTypes = @("major", "minor", "patch")

    if ($Command -ne "latest" -and $Command -ne "tag") {
        throw "Comando não reconhecido. Utilize publish help para obter ajuda."
    }
    elseif ($Command -eq "help") {
        throw "Não está implementado ainda"
    }

    if ($Version -notin $bumpTypes -and $Version -notmatch "^\d+\.\d+\.\d+$") {
        throw "Valor inválidode versão. Use: major, minor, patch ou uma versão válida (ex: 1.2.3)"
    }

    $global:PublisherRootPath = $PSScriptRoot

    # Garante que o repositório está limpo
    Test-CleanWorkingTree

    # Diretório onde o usuário executou o comando
    $executionRoot = (Get-Location).Path
    Write-Info "Executando publish a partir do diretório: $executionRoot"
  
    $arguments = @{}
    $arguments["RepositoryPath"] = $executionRoot
    $arguments["Version"] = $Version
    
    & "$PSScriptRoot\scripts\publish-$Command.ps1" @arguments
}
catch {
    Write-Error $_
    exit 1
}
finally {
    <#Do this after the try block regardless of whether an exception occurred or not#>
}