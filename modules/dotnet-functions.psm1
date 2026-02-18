Import-Module "$PSScriptRoot\functions.psm1" -Force

function Update-VersionInProjects {
    param(
        [Parameter(Mandatory)]
        [string]$NewVersion,

        # [string]$Path = (Get-Location).Path
        [string]$Path
    )

    if (Test-Path $Path) {
        $projects = Get-ChildItem -Recurse -Filter *.csproj |
            Where-Object { $_.FullName -notmatch '\btest(s)?\b' }
    }
    else {
        $projects = Get-ChildItem -Path $Path -Recurse -Filter *.csproj |
            Where-Object { $_.FullName -notmatch '\btest(s)?\b' }
    }

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

# Executa testes unitários
function Start-UnitTests {

    Write-Host "Executando testes unitários..." -ForegroundColor Green

    dotnet test --configuration Release --verbosity minimal

    if ($LASTEXITCODE -ne 0) {
        throw "Testes unitários falharam. Release abortado."
    }
}

function Start-ApiPublish {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [Parameter(Mandatory)]
        [string]$OutputPath

        # [string]$Configuration = "Release"
    )

    Write-Info "Executando dotnet publish"

    $output = & dotnet publish $ProjectPath -c Release -o $OutputPath -v q 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Falha no publish:"
        Write-Host $output
        exit 1
    }
}

function Start-BlazorPublish {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
    
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    Write-Info "Projeto: $projectPath"
    Write-Info "Saída: $outputPath"
    Write-Info "Executando dotnet publish"

    
    $output = & dotnet publish $ProjectPath -c Release -o $OutputPath -p:PublishTrimmed=true -v q 2>&1


    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Falha no publish:"
        Write-Host $output
        exit 1
    }
}

Export-ModuleMember -Function *