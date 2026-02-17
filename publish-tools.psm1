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

# Garante que o repositório está limpo
function Ensure-CleanWorkingTree {
    $status = git status --porcelain

    if ($status) {
        throw "Working tree não está limpa. Faça commit ou stash antes do release."
    }
}

# Pega branch de release configurada no git config
function Get-ReleaseBranch {

    $branch = git config release.allowedBranch

    if (-not $branch) {
        throw "Branch de release não configurada. Execute: git config release.allowedBranch <nome>"
    }

    return $branch
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

# Executa testes unitários
function Run-UnitTests {

    Write-Host "Executando testes unitários..."

    dotnet test --configuration Release

    if ($LASTEXITCODE -ne 0) {
        throw "Testes unitários falharam. Release abortado."
    }
}

function Update-VersionInProjects {
    param(
        [Parameter(Mandatory)]
        [string]$NewVersion
    )

    $projects = Get-ChildItem -Recurse -Filter *.csproj |
                Where-Object { $_.FullName -notmatch "Test" }

    foreach ($proj in $projects) {

        # Write-Host "Atualizando versão em $($proj.Name)..."

        [xml]$xml = Get-Content $proj.FullName

        $propertyGroup = $xml.Project.PropertyGroup |
                         Where-Object { $_.Version } |
                         Select-Object -First 1

        if ($propertyGroup) {
            $propertyGroup.Version = $NewVersion
        }
        # else {
        #     # adiciona dentro do primeiro PropertyGroup
        #     $pg = $xml.Project.PropertyGroup[0]

        #     if (-not $pg) {
        #         $pg = $xml.CreateElement("PropertyGroup")
        #         $xml.Project.AppendChild($pg) | Out-Null
        #     }

        #     $versionNode = $xml.CreateElement("Version")
        #     $versionNode.InnerText = $NewVersion
        #     $pg.AppendChild($versionNode) | Out-Null
        # }

        $xml.Save($proj.FullName)
    }
}

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

Export-ModuleMember -Function *