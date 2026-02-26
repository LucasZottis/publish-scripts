function Remove-File {
    param(
        [Parameter(Mandatory = $true)]
        $FilePath
    )

    if (-not (Test-Path $FilePath)) {
        $FilePath = [System.IO.Path]::GetFullPath($FilePath)
    }

    $fileName = [System.IO.Path]::GetFileName($FilePath)

    if (-not (Test-Path $FilePath)) {
        Write-Warn "$fileName não encontrado em: $FilePath"
    }
    else {
        Remove-Item -Path $FilePath
    }
}

function Remove-Folder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    # Converte para caminho absoluto sem exigir existência
    $fullPath = [System.IO.Path]::GetFullPath($FolderPath)

    if (-not (Test-Path $fullPath)) {
        Write-Warn "O caminho especificado não existe: $fullPath"
        exit 0
    }

    try {
        Remove-Item -Path $fullPath -Recurse -Force
        Write-Log "Pasta removida com sucesso: $fullPath"
    }
    catch {
        Write-Error "Erro ao remover a pasta: $_"
        exit 1
    }
}

function Resolve-CacheBustingDateTagLinks {
    param(
        [string]$PublishPath
    )

    $indexPath = Join-Path $PublishPath "wwwroot\index.html"
    $tag = ([System.DateTime]::UtcNow.ToString("yyyyMMddHHmmss"))
    ((Get-Content $IndexPath) -replace '{CACHE_BUSTING_TOKEN}', $tag) | Set-Content $IndexPath
}

Export-ModuleMember -Function *