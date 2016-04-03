$ErrorActionPreference = 'Stop'

#We need 7Zip to compress MSUA to get under 20Mb limit :-(
If (!$env:SevenZip_HOME)
{
	$env:SevenZip_HOME = join-path "$Env:ProgramFiles" "7-Zip"
}

if (!(Test-Path $env:SevenZip_HOME))
{
	Write-Host "** Error: Could not find 7-Zip at $env:SevenZip_HOME. Exiting **"
    Exit 1
}

$sevenZipExe = "7z.exe"
$sevenZipDll = "7z.dll"
$sevenZipLicense = "License.txt"
$sevenZipDirectory = 'UpgradeAdvisorTask\7Z'
if(Test-Path $sevenZipDirectory)
{
	Remove-Item $sevenZipDirectory -recurse
}

New-Item $sevenZipDirectory -itemtype directory
@($sevenZipExe, $sevenZipDll, $sevenZipLicense) | % {
	$target = join-path $sevenZipDirectory $_
	$source = join-path $env:SevenZip_HOME $_
	Copy-Item $source $target
}

If (!$env:MSUA_HOME)
{
	$env:MSUA_HOME = join-path "$Env:ProgramFiles" "Microsoft SQL Server 2016 Upgrade Advisor"
}

if (!(Test-Path $env:MSUA_HOME))
{
	Write-Host "** Error: Could not find Microsoft Upgrade Advisor at $env:MSUA_HOME. Exiting **"
    Exit 1
}

$msuaDirectory = '.\UpgradeAdvisorTask\Microsoft SQL Server 2016 Upgrade Advisor'
$msuaZipFile = '.\UpgradeAdvisorTask\msua.7z'

@($msuaDirectory, $msuaZipFile) | % {
	if (Test-Path $_) {
		Remove-Item $_ -Recurse
	}
}

$sevenZipExePath = join-path $sevenZipDirectory $sevenZipExe
set-alias sz $sevenZipExePath
sz a $msuaZipFile $env:MSUA_HOME