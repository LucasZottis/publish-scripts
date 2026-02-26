# Import-Module "$PSScriptRoot\functions.psm1" -Force

function Start-Commit {
    param(
        [Parameter(Mandatory)]
        [string]$NewVersion
    )

    git add -A
    
    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao adicionar arquivos."
    }

    Write-Log "Alterações de versão:"
    git --no-pager diff --cached --name-only

    Write-Host ""
    Write-Log "[C] Commitar e criar tag v$NewVersion"
    Write-Log "[R] Reverter alterações"
    Write-Host ""

    $choice = Read-Host "Escolha (C/R)"

    switch ($choice.ToUpper()) {

        "C" {
            git commit -m "v$NewVersion" || throw "Erro no commit."
            git push || throw "Erro no push."
            git tag "v$NewVersion" || throw "Erro ao criar tag."
            git push --tags || throw "Erro ao enviar tags."

            Write-Success "Release v$NewVersion publicada com sucesso."
        }

        "R" {
            Undo-Git
            throw "Release cancelado pelo usuário."
        }

        default {
            throw "Opção inválida. Release cancelado."
        }
    }
}

# Troca para branch especificada e dá pull
function Switch-Branch {
    param(
        [Parameter(Mandatory)]
        [string]$Branch
    )

    # Verifica se está dentro de um repositório git
    git rev-parse --is-inside-work-tree > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "O diretório atual não é um repositório Git."
    }

    # Verifica se branch existe localmente
    git show-ref --verify --quiet "refs/heads/$Branch"

    if ($LASTEXITCODE -eq 0) {
        # Existe localmente
        git checkout $Branch
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao trocar para a branch local '$Branch'."
        }
    }
    else {
        # Descobre remote configurado
        $remote = git remote | Select-Object -First 1
        if (-not $remote) {
            throw "Branch '$Branch' não existe localmente e nenhum remote está configurado."
        }

        # Atualiza referências
        git fetch $remote > $null 2>&1

        # Verifica se existe no remoto
        git ls-remote --exit-code --heads $remote $Branch > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "A branch '$Branch' não existe localmente nem no remoto '$remote'."
        }

        # Cria branch local rastreando remoto
        git checkout -b $Branch "$remote/$Branch"
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao criar branch local a partir de '$remote/$Branch'."
        }
    }

    # Atualiza branch (fast-forward only)
    git pull --ff-only
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao atualizar a branch '$Branch'."
    }

    # Write-Host "✔ Branch '$Branch' pronta e atualizada."
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
    Write-Log "Verificando se o repositório está limpo"

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
            Write-Log "Executando em tag: $version" -ForegroundColor Cyan
            return $version
        }
    }

    # 🔁 2️⃣ Fluxo normal (pega maior versão existente)
    $tags = git tag --list
    $latest = "0.0.0"

    if (-not $tags) {
        Write-Info "Versão Atual: $latest"
        return $latest
    }
    
    $versions = $tags | Where-Object { $_ -match "^v?\d+\.\d+\.\d+$" } | ForEach-Object { $_.TrimStart("v") }

    if (-not $versions) {
        Write-Info "Versão Atual: $latest"
        return $latest
    }

    $latest = $versions | Sort-Object { [version]$_ } -Descending | Select-Object -First 1

    Write-Info "Versão Atual: $latest"
    return $latest
}

function Test-IsCurrentBranch($branch) {
    $currentBranch = Get-CurrentBranch    
    return $currentBranch -eq $branch
}

function Undo-Git {
    Write-Warn "Revertendo todas as alterações"
    
    git reset --hard
    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao executar git reset --hard."
    }

    git clean -fd
    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao executar git clean."
    }

    Write-Warn "Repositório restaurado para o último commit."
}

Export-ModuleMember -Function *