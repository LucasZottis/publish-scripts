# param(
#     [Parameter(Mandatory = $true)]
#     [string] $RepositoryPath,

#     [Parameter(Mandatory = $true)]
#     [string] $Version
# )

# $tag = "v$Version"

# # Troca o branch se não estiver no branch padrão
# if (-not (Test-IsCurrentBranch -branch tag)) {
#     Write-Info "Trocando para a tag: $tag"
#     Switch-ToTag -Tag $tag
# }

# $publishSettings = Get-PublishSettings -path "$RepositoryPath\publish.settings.json"
# Resolve-Publish -PublishSettings $publishSettings -Version $Version