param(
    [Parameter(Mandatory = $true)]
    [string] $repositoryPath,

    [Parameter(Mandatory = $true)]
    [string] $version
)

# Importação de módulos


# $repositoryPath = "D:\Projetos\SysPret\publish.settings.json"
# $version = "1.0.0"

# Arquivo de configuração que está no diretório de execução

# # Caso seja nova versão
# if ($Mode -eq "bump") {
#     Write-Info "Modo: Nova versão ($Bump)"
        
#     # Obtém o branch atual
#     $currentBranch = Get-CurrentBranch 

#     # Obtém versão atual
#     $currentVersion = Get-LastVersion
        
#     # Chama seu método existente
#     $newVersion = Resolve-NewVersion -CurrentVersion $currentVersion

#     if (-not $newTag) {
#         throw "Falha ao gerar nova versão."
#     }

#     Write-Info "Versão gerada: $newTag"
# }
# elseif ($Mode -eq "republish") {
#     Write-Info "Modo: Republicação da versão $TargetVersion"

#     git fetch --tags

#     $tag = "v$TargetVersion"
#     $exists = git tag -l $tag

#     if (-not $exists) {
#         throw "Tag $tag não encontrada."
#     }

#     $originalBranch = $currentBranch

#     Write-Info "Fazendo checkout da tag $tag"
#     git checkout $tag

#     $newTag = $tag
# }