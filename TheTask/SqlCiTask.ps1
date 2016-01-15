param(
    [string]$operation,

    # Build arguments

    [string]$dbFolder, 
    [string]$subFolderPath, 
    [string]$packageName,

    # Test arguments
    
    [string]$packageId, 
    [string]$tempServerType, 
    [string]$tempServerName,
    [string]$tempDatabaseName,
    [string]$authMethod,
    [string]$username,
    [string]$password,
    [string]$useSqlDataGenerator,
    [string]$autoSqlDataGenerator,
    [string]$sqlDataGeneratorFile,
    [string]$runOnly,
    
    # Publish arguments
    
    [string]$packageIdPublish, 
    [string]$nugetFeedUrl, 
    [string]$nugetFeedApiKey,

    # Sync arguments
    
    [string]$packageIdSync, 
    [string]$targetServerName, 
    [string]$targetDatabaseName,
    [string]$authMethodSync,
    [string]$usernameSync,
    [string]$passwordSync,

    # Shared arguments
    [string]$additionalParams,
    [string]$nugetPackageVersion,
    [string]$nugetPackageVersionUseBuildNumber
)

function RunSqlCi($sqlCiArgs){
	$installedLocation = "$env:DLMAS_HOME\sqlci\sqlci.exe"
	if (Test-Path $installedLocation) {
		$sqlCiExePath = $installedLocation
	} else {
		$sqlCiExeFile = Get-ChildItem -Path .\ -Filter sqlCI.exe -Recurse
    
		if(!($sqlCiExeFile)) {
			Throw [System.IO.FileNotFoundException] "SQL CI executable not found at $sqlCiExePath"
		}

		[string]$sqlCiExePath = $sqlCiExeFile.FullName
	}
	
	$env:REDGATE_SEND_FUR = $true
	if ($env:AGENT_NAME -eq "Hosted Agent") {
		$env:REDGATE_FUR_ENVIRONMENT = "VNext Hosted"
	} else {
		$env:REDGATE_FUR_ENVIRONMENT = "VNext Local"
	}

    Write-Debug "Using SQL CI arguments $sqlCiArgs"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $sqlCiExePath
    $psi.Arguments = $sqlCiArgs
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $isNewProcessStarted = $process.Start()

    while(!$process.HasExited)
    {
        start-sleep -seconds 1
        Write-Host $process.StandardOutput.ReadToEnd()
        Write-Host $process.StandardError.ReadToEnd()
    }
    
    Write-Host $process.StandardOutput.ReadToEnd()
    Write-Host $process.StandardError.ReadToEnd()
}


Write-Host "Entering script SqlCiTask.ps1"

# Build arguments
Write-Debug "dbFolder = $dbFolder"
Write-Debug "subFolderPath = $subFolderPath" 
Write-Debug "packageName = $packageName"

# Test arguments 
Write-Debug "packageId =$packageId"
Write-Debug "tempServerType = $tempServerType" 
Write-Debug "tempServerName = $tempServerName"
Write-Debug "tempDatabaseName = $tempDatabaseName"
Write-Debug "authMethod = $authMethod"
Write-Debug "username = $username"
Write-Debug "password = $password"
Write-Debug "useSqlDataGenerator = $useSqlDataGenerator"
Write-Debug "autoSqlDataGenerator = $autoSqlDataGenerator"
Write-Debug "runOnly = $runOnly"

# Publish arguments
Write-Debug "packageIdPublish = $packageIdPublish" 
Write-Debug "nugetFeedUrl = $nugetFeedUrl" 
Write-Debug "nugetFeedApiKey = $nugetFeedApiKey"

# Sync arguments
Write-Debug "packageIdSync = $packageIdSync" 
Write-Debug "targetServerName = $targetServerName" 
Write-Debug "targetDatabaseName = $targetDatabaseName"
Write-Debug "authMethodSync = $authMethodSync"
Write-Debug "usernameSync = $usernameSync"
Write-Debug "passwordSync = $passwordSync"

# Shared arguments
Write-Debug "additionalParams = $additionalParams"
Write-Debug "nugetPackageVersion = $nugetPackageVersion"
Write-Debug "nugetPackageVersionUseBuildNumber = $nugetPackageVersionUseBuildNumber"


# This will be empty if it's a Release.
$buildSourcesDirectory = Get-TaskVariable -Context $distributedTaskContext -Name "Build.SourcesDirectory"

# Build version number

$nugetFullVersion = $nugetPackageVersion.Trim()
if($nugetPackageVersionUseBuildNumber -eq 'true')
{
    $nugetFullVersion += "."
    $nugetFullVersion += $Env:BUILD_BUILDNUMBER
}


switch($operation)
{
  "Build"{
    [string]$params = 'BUILD'

    if($dbFolder -eq 'SubFolder') {
        $params += " --scriptsFolder=$subFolderPath"
    }
    else{
        $params += " --scriptsFolder=.\"
    }

    $params += " --packageId=$packageName"
    $params += " --packageVersion=$nugetFullVersion"
    $params += " --outputFolder=$buildSourcesDirectory"

    if($additionalParams) {
       $params += " --additionalCompareArgs=$additionalParams"
    }
  }
  "Test"{
    [string]$params = 'TEST'

    # If this is a a VSO Build Definition, we get the package from the buildsourcesdirctory 
    if ($Env:AGENT_JOBNAME -eq 'Build')     {
        $params += " --outputFolder=$buildSourcesDirectory --package=$buildSourcesDirectory\$packageId" + ".$nugetFullVersion.nupkg"
    }
    elseif ($Env:AGENT_JOBNAME -eq 'Release') {
        # We're in a VSO Release definition. So feed it from the packageFile directly, and output tests to SYSTEM_DEFAULTWORKINGDIRECTORY
        $params += " --outputFolder=$Env:SYSTEM_DEFAULTWORKINGDIRECTORY --package=$packageId"
    }
    else {
        Write-Error "Unrecognized AGENT_JOBNAME: $Env:AGENT_JOBNAME"
    }

    if($tempServerType -eq "sqlServer") 
    {
        $params += " --temporaryDatabaseServer=$tempServerName"

        if($tempDatabaseName)
        {
            $params += " --temporaryDatabaseName=$tempDatabaseName"
        }

        if($authMethod -eq "sqlServerAuth") 
        {
            $params += " --temporaryDatabaseUserName=$username"
            $params += " --temporaryDatabasePassword=$password"
        }
    }

    if($useSqlDataGenerator -eq 'true') 
    {
        if($env:AGENT_NAME -eq "Hosted Agent")
        {
            Write-Error "SQL Data Generator cannot be used on Hosted Agents. If you want to use SQL Data Generator, run this on an on-site build agent where the Redgate DLM Automation Suite is installed."
        }

        if($autoSqlDataGenerator -eq 'true') 
        {
            $params += " --sqlDataGenerator="
        }
        else
        {
            $params += " --sqlDataGenerator=$sqlDataGeneratorFile"
        }
    }

    if($runOnly) 
    {
        $params += " --runOnly=$runOnly"
    }
  }
  "Sync"{
    [string]$params = 'SYNC'
    
    if($Env:AGENT_JOBNAME -eq 'Build')     {   # This is a a VSO Build Definition, we get the package from the buildsourcesdirctory 
        $params += " --package=$buildSourcesDirectory\$packageIdSync" + ".$nugetFullVersion.nupkg"
    }
    elseif($Env:AGENT_JOBNAME -eq 'Release') {
        # We're in a VSO Release definition. So feed it from the packageFile directly.
        $params += " --package=$packageIdSync"
    }
    else    {
        Write-Error "Unrecognized AGENT_JOBNAME: $Env:AGENT_JOBNAME"
    }

    $params += " --databaseServer=$targetServerName"
    $params += " --databaseName=$targetDatabaseName"

    if($authMethod -eq "sqlServerAuth") 
    {
        $params += " --databaseUserName=$usernameSync"
        $params += " --databasePassword=$passwordSync"
    }

    if($additionalParams) {
        $params += " --additionalCompareArgs=$additionalParams"
    }
        
  }
  "Publish"{
    [string]$params = 'Publish'
    
    if($Env:AGENT_JOBNAME -eq 'Build')     {   # This is a a VSO Build Definition, we get the package from the buildsourcesdirctory 
        $params += " --package=$buildSourcesDirectory\$packageIdPublish" + ".$nugetFullVersion.nupkg"
    }
    elseif($Env:AGENT_JOBNAME -eq 'Release') {
        # We're in a VSO Release definition. So feed it from the packageFile directly.
        $params += " --package=$packageIdPublish"
    }
    else  {
        Write-Error "Unrecognized AGENT_JOBNAME: $Env:AGENT_JOBNAME"
    }
    
    $params += " --nugetFeedUrl=$nugetFeedUrl"

    if($nugetFeedApiKey)
    {
        $params += " --nugetFeedApiKey=$nugetFeedApiKey"
    }
  }
  default:{
    Write-Error "Unrecognized SQL CI operation: $operation"
  }
}


RunSqlCi $params

Write-Host "Leaving script SqlCiTask.ps1"