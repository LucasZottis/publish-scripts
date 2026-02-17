# Calcula nova versão
function Get-BumpedVersion {
    param(
        [string]$CurrentVersion,
        [ValidateSet("major", "minor", "patch")]
        [string]$Bump
    )

    $parts = $CurrentVersion.Split(".")
    [int]$major = $parts[0]
    [int]$minor = $parts[1]
    [int]$patch = $parts[2]

    switch ($Bump) {
        "major" { $major++; $minor = 0; $patch = 0 }
        "minor" { $minor++; $patch = 0 }
        "patch" { $patch++ }
    }

    return "$major.$minor.$patch"
}

function Get-PublishSettings {
    param( [string]$Path )

    $pathPublishSettings = "$Path/publish.settings.json"

    if (-not (Test-Path $pathPublishSettings)) {
        throw "Arquivo de publicação não existe"
    }
    
    try {
        $config = Get-Content $pathPublishSettings -Raw | ConvertFrom-Json
    }
    catch {
        throw "Erro ao ler ou converter o JSON do arquivo: $pathPublishSettings"
    }

    return $config
}

Export-ModuleMember -Function *
