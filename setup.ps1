Import-Module ".\modules\functions.psm1"

Write-Info "Buscando extensões permitidas pelo PATH"
Write-Info "Extensões atuais: $env:PATHEXT"

if ($env:PATHEXT -notmatch "\.PS1") {
    Write-Info "Adicionando extensão .ps1"    
    $newPathext = "$env:PATHEXT;.PS1"
    
    # Persiste
    [Environment]::SetEnvironmentVariable("PATHEXT", $newPathext, "User")
    # Atualiza sessão atual
    $env:PATHEXT = $newPathext
    
    Write-Success "PATHEXT atualizado."
}
else {
    Write-Info ".PS1 já está no PATHEXT."
}

# Pasta onde o script está
$ScriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

# Sobe um nível (onde está o Publicador.cmd)
$PublicadorRoot = Split-Path -Parent $ScriptFolder

Write-Info "Diretório detectado: $PublicadorRoot"

# Define variável opcional
[Environment]::SetEnvironmentVariable(
    "PUBLICADOR_ROOT",
    $PublicadorRoot,
    "User"
)

# Atualiza PATH do usuário
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -notlike "*$PublicadorRoot*") {

    $newPath = "$currentPath;$PublicadorRoot"

    [Environment]::SetEnvironmentVariable(
        "Path",
        $newPath,
        "User"
    )

    Write-Info "PATH atualizado com sucesso."
}
else {
    Write-Info "PATH já contém o diretório do Publicador."
}

Write-Info "Concluído."

Write-Host ""
Write-Info "Pressione qualquer tecla para fechar..."
[System.Console]::ReadKey($true) | Out-Null
