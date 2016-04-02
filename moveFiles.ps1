$ErrorActionPreference = 'Stop'

If (!$env:DLMAS_HOME)
{
    Write-Host '** Error: DLM Automation Suite not installed. Exiting **'
    Exit 1
}

$sqlCiDirectory            = $env:DLMAS_HOME + 'SQLCI\'
$sqlCompareDirectory       = $env:DLMAS_HOME + 'SC\'

@('.\TheTask\SC', '.\TheTask\SDG', '.\TheTask\sqlCI') | % {
	if (Test-Path $_) {
		Remove-Item $_ -Recurse
	}
}

Copy-Item $sqlCiDirectory            .\TheTask\sqlCI  -recurse -force
Copy-Item $sqlCompareDirectory       .\TheTask\SC     -recurse -force

# To get around bug with VSO Marketplace that you can't have both an .EXT and an .ext 
$DocCommentsFile = '.\TheTask\sqlCI\sqlCI.XML'
if (Test-Path $DocCommentsFile) {
	Remove-Item $DocCommentsFile -Recurse
}
