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
            $fullPath = Join-Path $ScriptRoot $ScriptConfig.Path

            if (!(Test-Path $fullPath)) {
                throw "Script não encontrado: $fullPath"
            }

            & $fullPath
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

Export-ModuleMember -Function *
