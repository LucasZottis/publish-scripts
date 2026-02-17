function Update-VersionInProjects {
    param(
        [Parameter(Mandatory)]
        [string]$NewVersion
    )

    $projects = Get-ChildItem -Recurse -Filter *.csproj |
                Where-Object { $_.FullName -notmatch '\btest(s)?\b' }

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
function Run-UnitTests {

    Write-Host "Executando testes unitários..."

    dotnet test --configuration Release --verbosity minimal

    if ($LASTEXITCODE -ne 0) {
        throw "Testes unitários falharam. Release abortado."
    }
}

function Run-ApiPublish {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [string]$Configuration = "Release"
    )

    Write-Host "→ Executando dotnet publish"

    & dotnet publish $ProjectPath -c $Configuration -o $OutputPath

    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao publicar projeto API."
    }
}

function Run-BlazorPublish {
    params(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    Write-Host "→ Executando dotnet publish"
    & dotnet publish $ProjectPath `
        -c $Configuration `
        -o $OutputPath `
        -p:PublishTrimmed=true

    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao publicar projeto"
    }
}

Export-ModuleMember -Function *
