param(
    [string]$operation,

    # Build arguments

    [string]$dbFolder, 
    [string]$subFolderPath, 
    [string]$packageName,
    [string]$tempServerTypeBuild, 
    [string]$tempServerNameBuild,
    [string]$tempDatabaseNameBuild,
    [string]$authMethodBuild,
    [string]$usernameBuild,
    [string]$passwordBuild,

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
			Throw [System.IO.FileNotFoundException] "SQL CI executable not found at $sqlCiExePath" }

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

    $exitcode = $process.ExitCode

    if ($exitcode -ne 0) {
        Throw "SQL CI exitcode was $exitcode. See console output for details."
    }
}

function AppendArgument($arg, $name, $value){
    $escapedValue = $value -replace '"','\"'
    return "$arg /$name=`"$escapedValue`""
}


Write-Host "Entering script SqlCiTask.ps1"

# Build arguments
Write-Debug "dbFolder = $dbFolder"
Write-Debug "subFolderPath = $subFolderPath" 
Write-Debug "packageName = $packageName"
Write-Debug "tempServerTypeBuild = $tempServerTypeBuild" 
Write-Debug "tempServerNameBuild = $tempServerNameBuild"
Write-Debug "tempDatabaseNameBuild = $tempDatabaseNameBuild"
Write-Debug "authMethodBuild = $authMethodBuild"
Write-Debug "usernameBuild = $usernameBuild"
Write-Debug "passwordBuild = *********"

# Test arguments 
Write-Debug "packageId =$packageId"
Write-Debug "tempServerType = $tempServerType" 
Write-Debug "tempServerName = $tempServerName"
Write-Debug "tempDatabaseName = $tempDatabaseName"
Write-Debug "authMethod = $authMethod"
Write-Debug "username = $username"
Write-Debug "password = *********"
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
Write-Debug "passwordSync = *********"

# Shared arguments
Write-Debug "additionalParams = $additionalParams"
Write-Debug "nugetPackageVersion = $nugetPackageVersion"
Write-Debug "nugetPackageVersionUseBuildNumber = $nugetPackageVersionUseBuildNumber"


# This will be empty if it's a Release.
$buildSourcesDirectory = "C:\Temp" #$env:BUILD_SOURCESDIRECTORY

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
        $params = AppendArgument $params 'scriptsFolder' $subFolderPath
    }
    else{
        $params = AppendArgument $params 'scriptsFolder' '.\'
    }

    $params = AppendArgument $params 'packageId' $packageName
    $params = AppendArgument $params 'packageVersion' $nugetFullVersion
    $params = AppendArgument $params 'outputFolder' $buildSourcesDirectory
    
    if($tempServerTypeBuild -eq "sqlServer") 
    {
        $params = AppendArgument $params 'temporaryDatabaseServer' $tempServerNameBuild

        if($tempDatabaseNameBuild)
        {
            $params = AppendArgument $params 'temporaryDatabaseName' $tempDatabaseNameBuild
        }

        if($authMethodBuild -eq "sqlServerAuth") 
        {
            $params = AppendArgument $params 'temporaryDatabaseUserName' $usernameBuild
            $params = AppendArgument $params 'temporaryDatabasePassword' $passwordBuild
        }
    }

    if($additionalParams) {
       $params = AppendArgument $params 'additionalCompareArgs' $additionalParams
    }
  }
  "Test"{
    [string]$params = 'TEST'

    # If this is a a VSO Build Definition, we get the package from the buildsourcesdirctory 
    if ($Env:AGENT_JOBNAME -eq 'Build')     {
        $params = AppendArgument $params 'outputFolder' $buildSourcesDirectory
        $params = AppendArgument $params 'package' "$buildSourcesDirectory\$packageId.$nugetFullVersion.nupkg"
    }
    elseif ($Env:AGENT_JOBNAME -eq 'Release') {
        # We're in a VSO Release definition. So feed it from the packageFile directly, and output tests to SYSTEM_DEFAULTWORKINGDIRECTORY
        $params = AppendArgument $params 'outputFolder' $Env:SYSTEM_DEFAULTWORKINGDIRECTORY
        $params = AppendArgument $params 'package' $packageId
    }
    else {
        Write-Error "Unrecognized AGENT_JOBNAME: $Env:AGENT_JOBNAME"
    }

    if($tempServerType -eq "sqlServer") 
    {
        $params = AppendArgument $params 'temporaryDatabaseServer' $tempServerName

        if($tempDatabaseName)
        {
            $params = AppendArgument $params 'temporaryDatabaseName' $tempDatabaseName
        }

        if($authMethod -eq "sqlServerAuth") 
        {
            $params = AppendArgument $params 'temporaryDatabaseUserName' $username
            $params = AppendArgument $params 'temporaryDatabasePassword' $password
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
            $params = AppendArgument $params 'sqlDataGenerator' ""
        }
        else
        {
            $params = AppendArgument $params 'sqlDataGenerator' $sqlDataGeneratorFile
        }
    }

    if($runOnly) 
    {
        $params = AppendArgument $params 'runOnly' $runOnly
    }
  }
  "Sync"{
    [string]$params = 'SYNC'
    
    if($Env:AGENT_JOBNAME -eq 'Build')     {   # This is a a VSO Build Definition, we get the package from the buildsourcesdirctory 
        $params = AppendArgument $params 'package' "$buildSourcesDirectory\$packageIdSync.$nugetFullVersion.nupkg"
    }
    elseif($Env:AGENT_JOBNAME -eq 'Release') {
        # We're in a VSO Release definition. So feed it from the packageFile directly.
        $params = AppendArgument $params 'package' $packageIdSync
    }
    else    {
        Write-Error "Unrecognized AGENT_JOBNAME: $Env:AGENT_JOBNAME"
    }

    $params = AppendArgument $params 'databaseServer' $targetServerName
    $params = AppendArgument $params 'databaseName' $targetDatabaseName

    if($authMethod -eq "sqlServerAuth") 
    {
        $params = AppendArgument $params 'databaseUserName' $usernameSync
        $params = AppendArgument $params 'databasePassword' $passwordSync
    }

    if($additionalParams) {
        $params = AppendArgument $params 'additionalCompareArgs' $additionalParams
    }
        
  }
  "Publish"{
    [string]$params = 'Publish'
    
    if($Env:AGENT_JOBNAME -eq 'Build')     {   # This is a a VSO Build Definition, we get the package from the buildsourcesdirctory 
        $params = AppendArgument $params 'package' "$buildSourcesDirectory\$packageIdPublish.$nugetFullVersion.nupkg"
    }
    elseif($Env:AGENT_JOBNAME -eq 'Release') {
        # We're in a VSO Release definition. So feed it from the packageFile directly.
        $params = AppendArgument $params 'package' $packageIdPublish
    }
    else  {
        Write-Error "Unrecognized AGENT_JOBNAME: $Env:AGENT_JOBNAME"
    }
    
    $params = AppendArgument $params 'nugetFeedUrl=$nugetFeedUrl'

    if($nugetFeedApiKey)
    {
        $params = AppendArgument $params 'nugetFeedApiKey' $nugetFeedApiKey
    }
  }
  default:{
    Write-Error "Unrecognized SQL CI operation: $operation"
  }
}


RunSqlCi $params

Write-Host "Leaving script SqlCiTask.ps1"