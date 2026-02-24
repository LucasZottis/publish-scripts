# Import-Module "$PSScriptRoot\functions.psm1" -Force

function Start-Commit {
    param(
        [Parameter(Mandatory)]
        [string]$NewVersion
    )

    git add
    
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

    git pull --ff-only
    
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao atualizar a branch '$Branch'."
    }
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
    
    Write-Info "Branch atual: $current"

    return $current
}

# Garante que o repositório está limpo
function Test-CleanWorkingTree {
    Write-Info "Verificando se o repositório está limpo"

    $status = git status --porcelain

    if ($status) {
        throw "Working tree não está limpa. Faça commit ou stash antes do release."
    }
}

# Obtém versão atual
function Get-CurrentVersion {

    # Verifica se está dentro de um repo Git
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "A pasta atual não é um repositório Git."
    }

    # 🔎 1️⃣ Tenta pegar o nome do branch atual
    $currentBranch = git branch --show-current 2>$null

    # Se não houver branch (ex: detached), tenta verificar se é uma tag
    if (-not $currentBranch) {

        $exactTag = git describe --tags --exact-match 2>$null

        if ($exactTag -and $exactTag -match "^v?\d+\.\d+\.\d+$") {
            $version = $exactTag.TrimStart("v")
            Write-Host "Executando em tag: $version" -ForegroundColor Cyan
            return $version
        }
    }

    # 🔁 2️⃣ Fluxo normal (pega maior versão existente)
    $tags = git tag --list

    if (-not $tags) {
        return "0.0.0"
    }

    $versions = $tags |
        Where-Object { $_ -match "^v?\d+\.\d+\.\d+$" } |
            ForEach-Object { $_.TrimStart("v") }

    if (-not $versions) {
        return "0.0.0"
    }

    $latest = $versions |
        Sort-Object { [version]$_ } -Descending |
            Select-Object -First 1

    Write-Success "Versão Atual: $latest"
    
    return $latest
}

function Test-IsCurrentBranch($branch) {
    $currentBranch = Get-CurrentBranch    
    return $currentBranch -eq $branch
}

Export-ModuleMember -Function *