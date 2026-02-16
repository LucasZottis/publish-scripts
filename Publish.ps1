param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("major","minor","patch")]
    [string]$Bump
)

Write-Host "Iniciando release..."

# Verifica working tree limpa
if (git status --porcelain) {
    Write-Host "Working tree não está limpa."
    exit 1
}

# Troca para main se existir
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne "main") {
    git checkout main
}

git pull

# Pega última tag
$lastTag = git describe --tags --abbrev=0 2>$null
if (-not $lastTag) { $lastTag = "v0.0.0" }

$version = $lastTag.TrimStart("v")
$parts = $version.Split(".")

[int]$major = $parts[0]
[int]$minor = $parts[1]
[int]$patch = $parts[2]

switch ($Bump) {
    "major" { $major++; $minor = 0; $patch = 0 }
    "minor" { $minor++; $patch = 0 }
    "patch" { $patch++ }
}

$newVersion = "$major.$minor.$patch"
Write-Host "Nova versão: $newVersion"

# Atualiza todos os csproj encontrados
$projects = Get-ChildItem -Recurse -Filter *.csproj

foreach ($proj in $projects) {
    (Get-Content $proj.FullName) `
        -replace '<Version>.*?</Version>', "<Version>$newVersion</Version>" `
        | Set-Content $proj.FullName
}

git add .
git commit -m "release $newVersion"

# Build e Test
dotnet restore
dotnet build -c Release
dotnet test

# Criar pasta publish
if (Test-Path publish) { Remove-Item publish -Recurse -Force }
New-Item -ItemType Directory -Path publish | Out-Null

# Publica todos projetos Web
foreach ($proj in $projects) {
    $content = Get-Content $proj.FullName
    if ($content -match "<Project Sdk=`"Microsoft.NET.Sdk.Web`"") {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($proj.Name)
        dotnet publish $proj.FullName -c Release -o "publish/$name"
    }
}

# Compactar
$zipName = "$((Split-Path -Leaf (Get-Location)))-$newVersion.zip"
Compress-Archive publish/* $zipName -Force

# Criar tag
git tag "v$newVersion"
git push
git push --tags

# Criar release (GitHub CLI)
gh release create "v$newVersion" $zipName --title "v$newVersion"

Write-Host "Release criada com sucesso!"
