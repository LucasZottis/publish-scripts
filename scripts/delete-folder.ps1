param(
    [Parameter(Mandatory = $true)]
    [string]$FolderPath
)

Import-Module "$PSScriptRoot\..\modules\functions.psm1" -Force

# Converte para caminho absoluto sem exigir existência
$fullPath = [System.IO.Path]::GetFullPath($FolderPath)

if (-not (Test-Path $fullPath)) {
    Write-Warning "O caminho especificado não existe: $fullPath"
    exit 0
}

try {
    Remove-Item -Path $fullPath -Recurse -Force
    Write-Info "Pasta removida com sucesso: $fullPath"
}
catch {
    Write-Error "Erro ao remover a pasta: $_"
    exit 1
}