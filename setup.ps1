# Força UTF-8 mesmo no PowerShell 5
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Configurando variáveis do Publicador..."

$env:PATHEXT += ";.PS1"

# Pasta onde o script está
$ScriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

# Sobe um nível (onde está o Publicador.cmd)
$PublicadorRoot = Split-Path -Parent $ScriptFolder

Write-Host "Diretório detectado: $PublicadorRoot"

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

    Write-Host "PATH atualizado com sucesso."
}
else {
    Write-Host "PATH já contém o diretório do Publicador."
}

Write-Host "Concluído."

Write-Host ""
Write-Host "Pressione qualquer tecla para fechar..."
[System.Console]::ReadKey($true) | Out-Null