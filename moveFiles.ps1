$ErrorActionPreference = 'Stop'

If (!$env:DLMAS_HOME)
{
    Write-Host '** Error: DLM Automation Suite not installed. Exiting **'
    Exit 1
}

$sqlCiDirectory = join-path "$env:DLMAS_HOME" "SQLCI"
$sqlCompareDirectory = join-path "$env:DLMAS_HOME" "SC"
$sqlDataGeneratorDirectory = join-path "$env:DLMAS_HOME" "SDG"
$targetTheTaskPath = join-path "$PsScriptRoot" "TheTask"
$targetSCPath = join-path "$targetTheTaskPath" "SC"
$targetSqlCiPath = join-path "$targetTheTaskPath" "sqlCI"
$targetSDGPath = join-path "$targetTheTaskPath" "SDG"

@($targetSCPath, $targetSqlCiPath, $targetSDGPath) | % {
    if(Test-Path "$_") {
        Remove-Item "$_" -Recurse
    }
}

Copy-Item "$sqlCiDirectory" "$targetSqlCiPath"  -recurse -force
Copy-Item "$sqlCompareDirectory" "$targetSCPath" -recurse -force
Copy-Item "$sqlDataGeneratorDirectory" "$targetSDGPath" -recurse -force

# To get around bug with VSO Marketplace that you can't have both an .EXT and an .ext 
$DocCommentsFile = join-path "$targetSqlCiPath" "sqlCI.XML"
if (Test-Path $DocCommentsFile) {
	Remove-Item $DocCommentsFile -Recurse
}
