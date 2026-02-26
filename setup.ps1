Import-Module ".\modules\WriteFunctions.psm1"

function Set-PathExtPS1 {
    Write-Log "Adicionando extensão .ps1"    
    $newPathext = "$env:PATHEXT;.PS1"
    
    # Persiste
    [Environment]::SetEnvironmentVariable("PATHEXT", $newPathext, "User")
    
    # Atualiza sessão atual
    $env:PATHEXT = $newPathext
    
    Write-Success "PATHEXT atualizado."
}

function Confirm-PathExtPS1 {
    if ($env:PATHEXT -notmatch "\.PS1") {
        Set-PathExtPS1
    }
    else {
        Write-Info ".PS1 já está no PATHEXT."
    }
}

function Confirm-PathExt($PublisherRoot) {
    # Atualiza PATH do usuário
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$PublisherRoot*") {
        return $false
    }

    Write-Info "PATH já contém o diretório do Publicador."
    return $true
}

function Set-PathExt {
    # Pasta onde o script está
    $publisherRoot = Split-Path -Parent $MyInvocation.MyCommand.Path 
    Write-Info "Diretório detectado: $publisherRoot"
    
    if (Confirm-PathExt -PublisherRoot $publisherRoot) {
        return
    }
    
    # Define variável opcional
    [Environment]::SetEnvironmentVariable(
        "Path",
        $publisherRoot,
        "User"
    )

    Write-Info "PATH atualizado com sucesso."
    
    #if ($currentPath -notlike "*$PublicadorRoot*") {
    #
    #    $newPath = "$currentPath;$PublicadorRoot"
   # 
   #     [Environment]::SetEnvironmentVariable(
    #        "Path",
     #       $newPath,
     #      "User"
     #   )
   # 
        
    #}
    #else {
    #}
}

function Start-Setup {
    Write-Log "Buscando extensões permitidas pelo PATH"
    Write-Log "Extensões atuais: $env:PATHEXT"
    
    Confirm-PathExtPS1
    Set-PathExt
    
    Write-Success "Concluído."
    
    Write-Host ""
    Write-Log "Pressione qualquer tecla para fechar..."
    [System.Console]::ReadKey($true) | Out-Null
}
