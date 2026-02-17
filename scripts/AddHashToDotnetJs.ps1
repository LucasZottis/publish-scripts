# (substitua as primeiras linhas do script por este bloco)
Param(
    [Parameter(Mandatory=$false)]
    [string]$PublishDir,

    [int]$HashLength = 8,

    [switch]$DryRun
)

function Write-Log { param($m) Write-Host "[AddHash] $m" }

# Se PublishDir não foi fornecido ou veio corrompido, tenta a variável de ambiente
if (-not $PublishDir -or $PublishDir.Trim() -eq "") {
    if ($env:PUBLISH_DIR) {
        $PublishDir = $env:PUBLISH_DIR
        Write-Log ("Usando PUBLISH_DIR da env: {0}" -f $PublishDir)
    }
}

# Sanitiza e remove aspas, pontos e barras finais
if ($PublishDir) {
    $PublishDir = $PublishDir.Trim('"',' ','\','.')
} else {
    Write-Error "PublishDir não informado (parâmetro e env PUBLISH_DIR vazios)."
    exit 1
}

try {
    $PublishDir = (Resolve-Path $PublishDir).ProviderPath
} catch {
    Write-Error ("PublishDir inválido ou não encontrado: {0}" -f $PublishDir)
    exit 1
}

if (-not (Test-Path $PublishDir)) {
    Write-Error ("PublishDir not found: {0}" -f $PublishDir)
    exit 1
}

$wwwroot = Join-Path $PublishDir 'wwwroot'
$fw = Join-Path $wwwroot '_framework'
if (-not (Test-Path $fw)) {
    Write-Log ("_framework folder not found at {0} - nothing to do." -f $fw)
    exit 0
}

# Patterns to process
$patterns = @('dotnet.runtime*.js','dotnet.native*.js')

# Backup critical files
$critical = @(
    Join-Path $fw 'blazor.boot.json',
    Join-Path $wwwroot 'service-worker-assets.js',
    Join-Path $wwwroot 'service-worker.published.js',
    Join-Path $wwwroot 'index.html'
)
foreach ($c in $critical) {
    if (Test-Path $c) {
        $bak = $c + '.bak'
        if (-not (Test-Path $bak)) {
            Copy-Item -Path $c -Destination $bak -Force
            Write-Log ("Backup created: {0}" -f $bak)
        }
    }
}

$renamed = @()

# Rename files and compressed variants
foreach ($pat in $patterns) {
    $items = Get-ChildItem -Path $fw -Filter $pat -File -ErrorAction SilentlyContinue
    foreach ($file in $items) {
        $oldName = $file.Name
        $baseNoExt = [System.IO.Path]::GetFileNameWithoutExtension($oldName)
        $ext = $file.Extension

        try {
            $hashFull = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
            $hash = $hashFull.Substring(0, [Math]::Min($HashLength, $hashFull.Length)).ToLower()
        } catch {
            $err = $_.Exception.Message
            Write-Log ("Error hashing {0}: {1}" -f $oldName, $err)
            continue
        }

        $newName = $baseNoExt + "." + $hash + $ext
        $oldPath = $file.FullName
        $newPath = Join-Path $fw $newName

        if ($DryRun) {
            Write-Log ("DryRun: rename '{0}' -> '{1}'" -f $oldName, $newName)
        } else {
            if (Test-Path $newPath) { Remove-Item -LiteralPath $newPath -Force }
            Rename-Item -LiteralPath $oldPath -NewName $newName -Force
            Write-Log ("Renamed: {0} -> {1}" -f $oldName, $newName)
        }

        foreach ($cmp in @('.br','.gz')) {
            $oldCmp = Join-Path $fw ($oldName + $cmp)
            if (Test-Path $oldCmp) {
                $newCmpName = $newName + $cmp
                $newCmp = Join-Path $fw $newCmpName
                if ($DryRun) {
                    Write-Log ("DryRun: rename compressed '{0}' -> '{1}'" -f ($oldName + $cmp), $newCmpName)
                } else {
                    if (Test-Path $newCmp) { Remove-Item -LiteralPath $newCmp -Force }
                    Rename-Item -LiteralPath $oldCmp -NewName $newCmpName -Force
                    Write-Log ("Renamed compressed: {0} -> {1}" -f ($oldName + $cmp), $newCmpName)
                }
            }
        }

        $renamed += @{ Old = $oldName; New = $newName }
    }
}

if ($renamed.Count -eq 0) {
    Write-Log "No dotnet.runtime/native files found to rename."
    exit 0
}

# Update blazor.boot.json safely
$bootPath = Join-Path $fw 'blazor.boot.json'
if (Test-Path $bootPath) {
    try {
        $boot = Get-Content $bootPath -Raw | ConvertFrom-Json
    } catch {
        Write-Log ("Failed to parse blazor.boot.json: {0}" -f $_.Exception.Message)
        exit 1
    }

    foreach ($pair in $renamed) {
        $old = $pair.Old
        $new = $pair.New

        if ($boot.PSObject.Properties.Name -contains 'jsModuleRuntime' -and $boot.jsModuleRuntime -and $boot.jsModuleRuntime.PSObject.Properties.Name -contains $old) {
            $boot.jsModuleRuntime | Add-Member -NotePropertyName $new -NotePropertyValue $boot.jsModuleRuntime.$old -Force
            $boot.jsModuleRuntime.PSObject.Properties.Remove($old) | Out-Null
        }
        if ($boot.PSObject.Properties.Name -contains 'jsModuleNative' -and $boot.jsModuleNative -and $boot.jsModuleNative.PSObject.Properties.Name -contains $old) {
            $boot.jsModuleNative | Add-Member -NotePropertyName $new -NotePropertyValue $boot.jsModuleNative.$old -Force
            $boot.jsModuleNative.PSObject.Properties.Remove($old) | Out-Null
        }

        if ($boot.resources) {
            foreach ($prop in $boot.resources.PSObject.Properties.Name) {
                $cat = $boot.resources.$prop
                if ($cat -and $cat.PSObject.Properties.Name -contains $old) {
                    $cat | Add-Member -NotePropertyName $new -NotePropertyValue $cat.$old -Force
                    $cat.PSObject.Properties.Remove($old) | Out-Null
                }
            }
        }
    }

    if ($DryRun) {
        Write-Log "DryRun: blazor.boot.json would be updated."
    } else {
        $boot | ConvertTo-Json -Depth 10 | Set-Content -Path $bootPath -Encoding utf8
        Write-Log "blazor.boot.json updated."
    }
} else {
    Write-Log ("blazor.boot.json not found at {0}" -f $bootPath)
}

# Update textual files under wwwroot
$filesToPatch = Get-ChildItem -Path $wwwroot -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in @('.js','.json','.html','.css') } | Select-Object -ExpandProperty FullName

foreach ($pair in $renamed) {
    $oldEsc = [regex]::Escape($pair.Old)
    foreach ($f in $filesToPatch) {
        try {
            $txt = Get-Content -Path $f -Raw -ErrorAction SilentlyContinue
            if ($null -ne $txt -and $txt -match $oldEsc) {
                if ($DryRun) {
                    Write-Log ("DryRun: file '{0}' contains '{1}' - would replace with '{2}'" -f $f, $pair.Old, $pair.New)
                } else {
                    $updated = $txt -replace $oldEsc, $pair.New
                    Set-Content -Path $f -Value $updated -Encoding utf8
                    Write-Log ("Updated: {0} (replaced {1} with {2})" -f $f, $pair.Old, $pair.New)
                }
            }
        } catch {
            Write-Log ("Error updating {0}: {1}" -f $f, $_.Exception.Message)
        }
    }
}

Write-Log ("Done. Renamed {0} files. Use -DryRun to test." -f $renamed.Count)
exit 0