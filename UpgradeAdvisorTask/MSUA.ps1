param(
    [string]$server, 
    [string]$database,
    [string]$authMethod,
    [string]$username,
    [string]$password
)

#Unzip
Write-host "Extracting MSUA"
$msuaZipFile = '.\msua.7z'
$sevenZipExe = join-path '.\7Z' "7z.exe"
Write-host $sevenZipExe
set-alias sz $sevenZipExe
sz x $msuaZipFile | Out-Null
$msuaDirectory = '.\Microsoft SQL Server 2016 Upgrade Advisor'
Write-host "Completed extracting MSUA"

#Run
$msuaExe = join-path $msuaDirectory "SqlAdvisorCmd.exe"
set-alias msua $msuaExe
if($authMethod -eq "sqlServerAuth")
{
	$connectionString = "Data Source=$server;Initial Catalog=$database;User Id=$username;Password=$password;Connect Timeout=15;Encrypt=False;TrustServerCertificate=False"
}
else
{
	$connectionString = "Data Source=$server;Initial Catalog=$database;Integrated Security=SSPI;Connect Timeout=15;Encrypt=False;TrustServerCertificate=False"
}
Write-host "Running MSUA with connection string = $connectionString"
Write-host "Testing 'upgrade' scenario"
msua /FolderPath:"$Env:SYSTEM_DEFAULTWORKINGDIRECTORY" /Scenario:Upgrade /ConnectionStrings:"$connectionString"
Write-host "Testing 'stretch DB' scenario"
msua /FolderPath:"$Env:SYSTEM_DEFAULTWORKINGDIRECTORY" /Scenario:StretchDB /ConnectionStrings:"$connectionString"