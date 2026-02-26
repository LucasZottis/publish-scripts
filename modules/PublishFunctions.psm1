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

    Write-Info "Nova Versão: $newVersion"
    return $newVersion
}

function Get-PublishSettings {
    param( 
        [string]$Path
    )

    # $pathPublishSettings = "$Path\publish.settings.json"
    Write-Log "Configurações de publicação serão carregadas do arquivo: $Path"

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

    # BEFORE
    if ($PublishSettings.Scripts -and $PublishSettings.Scripts.Before) {
        Write-Log "Iniciando execução dos scripts iniciais..."
        Resolve-PublishScripts -Scripts $PublishSettings.Scripts.Before
        Write-Success "Scripts iniciais executados!"
    }

    foreach ($project in $PublishSettings.Projects) {
        $stack = $project.Stack.ToLower()
        $scriptName = "publish-$stack.ps1"
        $scriptPath = Join-Path $PublisherRootPath "scripts\stack" $scriptName

        if (-not (Test-Path $scriptPath)) {
            throw "A stack '$($project.Stack)' ainda não tem publicação implementada"
        }

        & $scriptPath -Project $project -NewVersion $NewVersion

        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao publicar o projeto '$($project.Name)'."
        }
    }

    # AFTER
    if ($PublishSettings.Scripts -and $PublishSettings.Scripts.After) {
        Write-Log "Iniciando execução dos scripts finais..."
        Resolve-PublishScripts -Scripts $PublishSettings.Scripts.After
        Write-Success "Scripts finais executados!"
    }

    Start-Commit -NewVersion $NewVersion
}

function Resolve-PublishScripts {
    param(
        [pscustomobject[]]$Scripts
    )

    foreach ($script in $Scripts) {
        Invoke-Script -Script $script
    }
}

function Resolve-Arguments {
    param (
        [Parameter(Mandatory = $true)]
        $Arguments
    )

    # Sem argumentos
    if (-not $Arguments) {
        return @{}
    }

    # Se vier como PSCustomObject (JSON padrão)
    if ($Arguments -is [pscustomobject]) {

        $hashtable = @{}

        foreach ($prop in $Arguments.PSObject.Properties) {

            if ([string]::IsNullOrWhiteSpace($prop.Name)) {
                throw "Argumento com nome inválido."
            }

            $hashtable[$prop.Name] = $prop.Value
        }

        return $hashtable
    }

    # Se já for hashtable
    if ($Arguments -is [hashtable]) {
        return $Arguments
    }

    # Se for array → rejeita (evita parâmetro posicional)
    if ($Arguments -is [array]) {
        throw "Arguments não pode ser array. Use objeto nomeado."
    }

    # Se for string → rejeita
    if ($Arguments -is [string]) {
        throw "Arguments não pode ser string. Use objeto nomeado."
    }

    throw "Formato inválido para Arguments."
}

Export-ModuleMember -Function *