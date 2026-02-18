param(
    [Parameter(Mandatory = $true)]
    [string]$SourceFolder,

    [Parameter(Mandatory = $true)]
    [string]$DestinationFolder
)

try {
    if (-not (Test-Path $SourceFolder)) {
        throw "Pasta de origem não encontrada: $SourceFolder"
    }

    if (-not (Test-Path $DestinationFolder)) {
        Write-Host "Pasta de destino não encontrada. Criando: $DestinationFolder" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
    }

    Write-Host "Movendo arquivos de '$SourceFolder' para '$DestinationFolder'..." -ForegroundColor Green
    Move-Item -Path "$SourceFolder\*" -Destination $DestinationFolder -Force

    Write-Host "✔ Pasta movida com sucesso!" -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}