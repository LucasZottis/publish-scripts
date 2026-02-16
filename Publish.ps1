param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("major","minor","patch")]
    [string]$Bump
)

Write-Host "========== RELEASE =========="

# 1️⃣ Verifica working tree limpa
if (git status --porcelain) {
    Write-Host "Working tree não está limpa."
    exit 1
}

# 2️⃣ Vai para main e atualiza
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne "main") {
    git checkout main
}
git pull

# 5️⃣ Build + Test
dotnet restore
dotnet build -c Release
dotnet test

# 3️⃣ Pega última tag
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

# 4️⃣ Atualiza todos csproj (exceto testes)
$projects = Get-ChildItem -Recurse -Filter *.csproj | Where-Object {
    $_.FullName -notmatch "Test"
}

foreach ($proj in $projects) {
    (Get-Content $proj.FullName) `
        -replace '<Version>.*?</Version>', "<Version>$newVersion</Version>" `
        | Set-Content $proj.FullName
}

git add .
git commit -m "release $newVersion"

# Limpa pasta artifacts
if (Test-Path artifacts) { Remove-Item artifacts -Recurse -Force }
New-Item -ItemType Directory -Path artifacts | Out-Null

# 6️⃣ Processa cada projeto
foreach ($proj in $projects) {

    $content = Get-Content $proj.FullName -Raw
    $projName = [System.IO.Path]::GetFileNameWithoutExtension($proj.Name)

    # WEB PROJECT
    if ($content -match 'Sdk="Microsoft.NET.Sdk.Web"') {

        Write-Host "Publicando projeto Web: $projName"

        $publishPath = "artifacts/$projName"
        dotnet publish $proj.FullName -c Release -o $publishPath

        # Remove arquivos desnecessários
        Remove-Item "$publishPath/appsettings.Development.json" -ErrorAction SilentlyContinue

    }

    # LIBRARY (PACKABLE)
    if ($content -match '<IsPackable>true</IsPackable>' -or
        $content -match 'Sdk="Microsoft.NET.Sdk"' ) {

        Write-Host "Empacotando biblioteca: $projName"

        dotnet pack $proj.FullName -c Release -o artifacts
    }
}

# 7️⃣ Publica pacotes NuGet
$apiKey = $env:NUGET_API_KEY
if ($apiKey) {
    Get-ChildItem artifacts -Filter *.nupkg | ForEach-Object {
        dotnet nuget push $_.FullName `
            --api-key $apiKey `
            --source https://api.nuget.org/v3/index.json `
            --skip-duplicate
    }
}

# 8️⃣ Compacta projetos Web
$zipName = "$((Split-Path -Leaf (Get-Location)))-$newVersion.zip"
Compress-Archive artifacts/* $zipName -Force

# 9️⃣ Cria tag
git tag "v$newVersion"
git push
git push --tags

# 🔟 Cria GitHub Release
$files = @($zipName) + (Get-ChildItem artifacts -Filter *.nupkg | ForEach-Object { $_.FullName })

gh release create "v$newVersion" $files `
    --title "v$newVersion"

Write-Host "========== RELEASE CONCLUÍDA =========="
