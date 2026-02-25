function Update-VersionInProjects {
    param(
        [Parameter(Mandatory)]
        [string]$NewVersion,
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

    foreach ($project in $projects) {

        # Write-Host "Atualizando versão em $($proj.Name)..."
        Write-Info "Atualizando versão de ""$($project.Name)"""
        [xml]$xml = Get-Content $project.FullName

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

        $xml.Save($project.FullName)
    }
}

# Executa testes unitários
function Start-UnitTests {
    $output = dotnet test --configuration Release --verbosity minimal

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Falha no teste"
        Write-Host $output
        throw "Testes unitários falharam. Release abortado."
    }
}

function Start-Publish {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        $Arguments
    )

    Write-Info "Executando dotnet publish"
    $output = & dotnet publish $ProjectPath -c Release -o $OutputPath @arguments

    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Falha no publish:" 
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
