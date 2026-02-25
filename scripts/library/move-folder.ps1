param(
    [Parameter(Mandatory = $true)]
    [string]$SourceFolder,

    [Parameter(Mandatory = $true)]
    [string]$DestinationFolder
)

$output = robocopy $SourceFolder $DestinationFolder /MIR /MT:16 /R:2 /W:2
# robocopy $SourceFolder $DestinationFolder /MIR /MT:16 /R:2 /W:2

if ($LASTEXITCODE -ge 8) {
    Write-Host $output
    throw "❌ Erro no robocopy"
}

$global:LASTEXITCODE = 0
exit 0