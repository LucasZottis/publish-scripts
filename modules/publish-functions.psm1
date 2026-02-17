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

function Invoke-CustomScript {
    param (
        [Parameter(Mandatory = $true)]
        [pscustomobject]$ScriptConfig,

        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot
    )

    switch ($ScriptConfig.Type.ToLower()) {

        "powershell" {
            Write-Host "→ Executando PowerShell inline"
            & ([scriptblock]::Create($ScriptConfig.Command))
        }

        "ps1" {
            Write-Host "→ Executando arquivo PS1"
        
            $resolvedPath = Resolve-ScriptPath `
                -RelativePath $ScriptConfig.Path `
                -PublisherRoot $ScriptRoot
        
            & $resolvedPath
        }

        "cmd" {
            Write-Host "→ Executando CMD"
            cmd.exe /c $ScriptConfig.Command
        }

        default {
            throw "Tipo de script inválido: $($ScriptConfig.Type)"
        }
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao executar script do tipo $($ScriptConfig.Type)"
    }
}

function Resolve-ScriptPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$PublisherRoot
    )

    # Se já for absoluto
    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        if (Test-Path $RelativePath) {
            return (Resolve-Path $RelativePath).Path
        }
        throw "Script não encontrado (caminho absoluto): $RelativePath"
    }

    # 1️⃣ Verifica na pasta onde foi executado
    $workingPath = Join-Path $PWD $RelativePath
    if (Test-Path $workingPath) {
        return (Resolve-Path $workingPath).Path
    }

    # 2️⃣ Verifica na raiz do publicador
    $publisherPath = Join-Path $PublisherRoot $RelativePath
    if (Test-Path $publisherPath) {
        return (Resolve-Path $publisherPath).Path
    }

    throw "Script não encontrado em nenhuma hierarquia: $RelativePath"
}

Export-ModuleMember -Function *
