param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("major","minor","patch")]
    [string]$Bump
)

Write-Host "========== RELEASE =========="

# 1️⃣ Verifica se repo está limpo
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

# 4️⃣ Atualiza todos os csproj (exceto testes)
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

# 6️⃣ Pack (gera nupkg)
if (Test-Path artifacts) { Remove-Item artifacts -Recurse -Force }
dotnet pack -c Release -o artifacts

# 7️⃣ Publica no NuGet
$apiKey = $env:NUGET_API_KEY
if (-not $apiKey) {
    Write-Host "Variável NUGET_API_KEY não encontrada."
    exit 1
}

Get-ChildItem artifacts -Filter *.nupkg | ForEach-Object {
    dotnet nuget push $_.FullName `
        --api-key $apiKey `
        --source https://api.nuget.org/v3/index.json `
        --skip-duplicate
}

# 8️⃣ Cria tag e push
git tag "v$newVersion"
git push
git push --tags

# 9️⃣ Cria GitHub Release e anexa pacotes
$packages = Get-ChildItem artifacts -Filter *.nupkg | ForEach-Object { $_.FullName }

gh release create "v$newVersion" $packages `
    --title "v$newVersion"

Write-Host "========== RELEASE CONCLUÍDA =========="
