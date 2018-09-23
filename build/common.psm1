Function DownloadIfNeeded
(
    [Parameter(Mandatory=$true)] [string]$source,
    [Parameter(Mandatory=$true)] [string]$target
)
{
	if (!(Test-Path $target))
	{
		(New-Object System.Net.WebClient).DownloadFile($source, $target)
	}   
}

Function CheckAdmin() {
	$elevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
	if ($elevated -eq $false)
	{
		throw "Please run this script as an administrator"
	}
}

Function CheckLicense(
    [Parameter(Mandatory=$true)] [string]$LicenseFile
) {
	Write-Host "Checking license..." -ForegroundColor Green
	if (Test-Path $LicenseFile) {
		return
	}

	$LicenseFileEnc = "$LicenseFile.enc"
	Write-Host "$LicenseFile not found, checking $LicenseFileEnc" -ForegroundColor Yellow
	
	if (!(Test-Path $LicenseFileEnc)) {
		throw "Cannot find encrypted license file"
	}

	if(!$Global:secret) {
		throw "'secret' parameter or environment variable not set"
	}
	
	if (!(Test-Path "$PSScriptRoot\secure-file"))
	{
		nuget install secure-file -ExcludeVersion
	}	
	
	.\secure-file\tools\secure-file.exe -decrypt $LicenseFileEnc -secret $Global:secret
		
	if (!($LastExitCode -eq "0")) {
		throw "secure-file failed with exit code $LastExitCode"
	}
		
	Write-Host "Successfully decrypted license" -ForegroundColor Yellow
}

Function MyBuild {
    Param (
        [Parameter(Mandatory=$true)][string]$path,
        [Parameter(Mandatory=$false)][string]$targetDir,
        [Parameter(Mandatory=$false)][string]$configuration = "Release",
        [Parameter(Mandatory=$false)][switch]$build = $true,
        [Parameter(Mandatory=$false)][switch]$deploy = $false,
        [Parameter(Mandatory=$false)][string]$msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe"
    )

    $fullPath = "src\$path"
    if ($build) {
        Write-Host "Building $path in $configuration configuration" -ForegroundColor Green

        if ($deploy) {
            & $msbuild $fullPath /verbosity:minimal /p:DeployOnBuild=true`;Configuration=$configuration
        } else {
            & $msbuild $fullPath /verbosity:minimal /p:Configuration=$configuration;
        }

        if (!($LastExitCode -eq "0")) {
            throw "Build failed with exit code $LastExitCode"
        }
    }

    if ($deploy -and $targetDir) {
        $rootDir = Split-Path $fullPath

        MySync "$rootDir\obj\$configuration\Package\PackageTmp\" $targetDir
        MySync "$rootDir\bin\" "${targetDir}bin/"
    }
}

Function MySync {
  Param (
    [Parameter(Mandatory=$true)][string]$source,
    [Parameter(Mandatory=$true)][string]$target
  )
    
  if (Test-Path -Path $source) {
    $source = Resolve-Path $source
 
	robocopy /e /nfl $source $target
  }
}

Function MyZip {
  Param (
    [Parameter(Mandatory=$true)][string]$arguments
  )

  Write-Host "Writing zip with arguments: $arguments" -ForegroundColor Yellow
  Invoke-Expression "build\tools\7z a $arguments"

  if (!($LastExitCode -eq "0")) {
    throw "7z failed with $LastExitCode"
  }
}