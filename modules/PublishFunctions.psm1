# Calcula nova versão
function Resolve-NewVersion {
    param(
        [string]$CurrentVersion,

        [ValidateSet("major", "minor", "patch")]
        [string]$bump
    )

    $parts = $CurrentVersion.Split(".")
    [int]$major = $parts[0]
    [int]$minor = $parts[1]
    [int]$patch = $parts[2]

    switch ($bump) {
        "major" { $major++; $minor = 0; $patch = 0 }
        "minor" { $minor++; $patch = 0 }
        "patch" { $patch++ }
    }

    $newVersion = "$major.$minor.$patch";

    Write-Success "Nova Versão: $newVersion"
    return $newVersion
}

function Get-PublishSettings {
    param( 
        [string]$Path
    )

    # $pathPublishSettings = "$Path\publish.settings.json"
    Write-Info "Configurações de publicação serão carregadas do arquivo: $Path"

    if (-not (Test-Path $Path)) {
        throw "Arquivo de publicação não existe"
    }
    
    try {
        $config = Get-Content $Path -Raw | ConvertFrom-Json
    }
    catch {
        throw "Erro ao ler ou converter o JSON do arquivo: $Path"
    }

    if (-not $config.DefaultBranch) {
        throw "DefaultBranch não definido no publish.settings.json"
    }

    return $config
}

function Resolve-Publish {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject] $PublishSettings,

        [Parameter(Mandatory = $true)]
        [string]$NewVersion
    )

    # $projectRoot = Split-Path $PSScriptRoot -Parent
    $libPath = Join-Path $PublisherRootPath "scripts\lib"

    # BEFORE
    if ($PublishSettings.Scripts -and $PublishSettings.Scripts.Before) {
        foreach ($script in $PublishSettings.Scripts.Before) {
            Invoke-CustomScript -ScriptConfig $script -ScriptRoot $libPath
        }
    }

    foreach ($project in $PublishSettings.Projects) {
        $type = $project.Type.ToLower()
        $scriptName = "publish-$type.ps1"
        $scriptPath = Join-Path $PublisherRootPath "scripts" $scriptName

        if (-not (Test-Path $scriptPath)) {
            throw "Script de publicação não encontrado para o tipo '$($project.Type)': $scriptPath"
        }

        & $scriptPath -Project $project -NewVersion $NewVersion

        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao publicar o projeto '$($project.Name)'."
        }
    }

    # AFTER
    if ($PublishSettings.Scripts -and $PublishSettings.Scripts.After) {
        foreach ($script in $PublishSettings.Scripts.After) {
            Invoke-CustomScript -ScriptConfig $script -ScriptRoot $libPath
        }
    }
}

function Invoke-PublishScripts {
    param(
        [pscustomobject[]]$Scripts
    )

    foreach ($script in $Scripts) {
        Invoke-Script -Script $script
    }
}

Export-ModuleMember -Function *
