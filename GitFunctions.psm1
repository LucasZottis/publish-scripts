function Commit-VersionUpdate {
    param(
            [Parameter(Mandatory)]
            [string]$NewVersion
    )

    git add *.csproj
    
    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao adicionar arquivos."
    }

    Write-Host "`nAlterações de versão:"
    git --no-pager diff --cached --name-only

    Write-Host ""
    Write-Host "[C] Continuar e commitar"
    Write-Host "[R] Reverter alterações"
    Write-Host ""

    $choice = Read-Host "Escolha (C/R)"

    switch ($choice.ToUpper()) {

        "C" {
            git commit -m "chore: bump version to $NewVersion"
            if ($LASTEXITCODE -ne 0) {
                throw "Erro ao criar commit."
            }
            Write-Host "Commit realizado."
        }

        "R" {
            git reset
            git checkout -- *.csproj
            Write-Host "Alterações revertidas."
            throw "Release cancelado pelo usuário."
        }

        default {
            throw "Opção inválida. Release cancelado."
        }
    }
}

# Troca para branch especificada e dá pull
function Switch-ToBranch {
    param(
        [Parameter(Mandatory)]
        [string]$Branch
    )

    git checkout $Branch

    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao trocar para a branch '$Branch'."
    }

    git pull
}

# Pega branch atual
function Get-CurrentBranch {

    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Não está dentro de um repositório Git."
    }

    $current = git rev-parse --abbrev-ref HEAD

    if ($current -eq "HEAD") {
        throw "Detached HEAD não permitido."
    }

    return $current
}

# Garante que o repositório está limpo
function Ensure-CleanWorkingTree {
    $status = git status --porcelain

    if ($status) {
        throw "Working tree não está limpa. Faça commit ou stash antes do release."
    }
}

# Obtém versão atual
function Get-LastVersion {

    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "A pasta atual não é um repositório Git."
    }

    $tags = git tag --list

    if (-not $tags) {
        return "0.0.0"
    }

    # remove prefixo v e ordena semanticamente
    $versions = $tags |
        Where-Object { $_ -match "^v?\d+\.\d+\.\d+$" } |
        ForEach-Object { $_.TrimStart("v") }

    if (-not $versions) {
        return "0.0.0"
    }

    $latest = $versions |
        Sort-Object {[version]$_} -Descending |
        Select-Object -First 1

    return $latest
}

Export-ModuleMember -Function *
