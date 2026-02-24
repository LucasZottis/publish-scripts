function Invoke-Script {
    param (
        [Parameter(Mandatory = $true)]
        [pscustomobject]$ScriptConfig,

        # [Parameter(Mandatory = $true)]
        # [string]$ScriptRoot
    )

    Write-Info "Executando script: $($ScriptConfig.Name) (Tipo: $($ScriptConfig.Type))"

    switch ($ScriptConfig.Type.ToLower()) {
        "powershell" {
            & ([scriptblock]::Create($ScriptConfig.Command))
        }

        "ps1" {
            $resolvedPath = Resolve-ScriptPath `
                -RelativePath $ScriptConfig.Path `
                -ScriptRoot $ScriptRoot
            
            # Write-Info "Executando arquivo .ps1 em: $resolvedPath"
            $arguments = Resolve-ScriptArguments -Arguments $ScriptConfig.Arguments

            & $resolvedPath @arguments
        }

        "cmd" {
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
        [string]$ScriptRoot
    )

    # 1️⃣ Verifica na pasta onde foi executado
    $workingPath = Join-Path $PWD $RelativePath
    if (Test-Path $workingPath) {
        return (Resolve-Path $workingPath).Path
    }

    # 2️⃣ Verifica na raiz do publicador
    $publisherPath = Join-Path $ScriptRoot $RelativePath    
    if (Test-Path $publisherPath) {
        return (Resolve-Path $publisherPath).Path
    }

    # Se já for absoluto
    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        if (Test-Path $RelativePath) {
            return (Resolve-Path $RelativePath).Path
        }
        throw "Script não encontrado (caminho absoluto): $RelativePath"
    }

    throw "Script não encontrado em nenhuma hierarquia: $RelativePath"
}

function Resolve-ScriptArguments {
    param (
        [Parameter(Mandatory = $false)]
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
