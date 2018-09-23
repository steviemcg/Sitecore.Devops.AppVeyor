param
(
 [Parameter(Mandatory=$false)] [string]   $downloadDirectory = "C:\Downloads", 
 [Parameter(Mandatory=$false)] [string]   $bfDirectory = "C:\BFResources",
 [Parameter(Mandatory=$false)] [string]   $licensePath = $PSScriptRoot + "\resources\license.xml",
 [Parameter(Mandatory=$false)] [string]   $tdsVersion = "5.6.0.12",
 [Parameter(Mandatory=$false)] [string]   $repositoryUrl,
 [Parameter(Mandatory=$false)] [string]   $secret
)

$ErrorActionPreference = "Stop"
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
Import-Module $PSScriptRoot\common.psm1 -DisableNameChecking -Force
$codeDir = Resolve-Path "$PSScriptRoot\..\code"

if(!$secret) {
	$secret = $Env:my_secret
}

if(!$repositoryUrl) {
	$repositoryUrl = $Env:repositoryUrl
}

Write-Host "Checking license..." -ForegroundColor Green
if (!(Test-Path $licensePath)) {
	$licensePathEnc = "$licensePath.enc"
	Write-Host "$licensePath not found, checking $licensePathEnc" -ForegroundColor Yellow
	
	if (Test-Path $licensePathEnc) {
		if(!$secret) {
			throw "'secret' parameter or environment variable not set"
		}
	
		if (!(Test-Path "$PSScriptRoot\secure-file"))
		{
			nuget install secure-file -ExcludeVersion
		}	
	
		.\secure-file\tools\secure-file.exe -decrypt $licensePathEnc -secret $secret
		
		if (!($LastExitCode -eq "0")) {
			throw "secure-file failed with exit code $LastExitCode"
		}
		
		Write-Host "Successfully decrypted license" -ForegroundColor Yellow
	} else {
		throw "Cannot find encrypted license file"
	}
}

Write-Host "Installing prerequisites..." -ForegroundColor Green
New-Item $downloadDirectory -ItemType "directory" -Force -ErrorAction SilentlyContinue
New-Item $bfDirectory -ItemType "directory" -Force -ErrorAction SilentlyContinue

if ((Get-Command "nuget.exe" -ErrorAction SilentlyContinue) -eq $null) {
    choco install NuGet.CommandLine -y
}

if (!(Test-Path "C:\NSSM"))
{
    nuget install nssm -version 2.24.0 -OutputDirectory "C:\" -ExcludeVersion
}

Write-Host "Downloading packages..." -ForegroundColor Green

$urls = New-Object System.Collections.ArrayList
$urls.Add("/ads/,ps.ads.1.7.270.nupkg,$downloadDirectory")
$urls.Add("/ads/,ps.config.8.2.2.nupkg,$downloadDirectory")
$urls.Add("/nuget/,HedgehogDevelopment.TDS.$tdsVersion.nupkg,$downloadDirectory")
$urls.Add("/installs/,$cmsVersion,$bfDirectory")

foreach($url in $urls) {
	$arr = $url -split ','
	$source = "${repositoryUrl}$($arr[0])$($arr[1])"
	$target = "$($arr[2])\$($arr[1])"

	DownloadIfNeeded $source $target
}

if (!(Test-Path "C:\SitecorePowershell\ps.ads"))
{
    choco install ps.ads -y -Source $downloadDirectory --force
}

if (!(Test-Path "C:\SitecorePowershell\ps.config"))
{
    nuget install ps.config -Source $downloadDirectory -OutputDirectory "C:\SitecorePowershell\" -ExcludeVersion
}

refreshenv
$env:PSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')

nuget install HedgehogDevelopment.TDS -Source $downloadDirectory -OutputDirectory "$codeDir\packages\"

Write-Host "Successfully setup dev environment (time: $($elapsed.Elapsed.ToString()))"