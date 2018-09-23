param
(
 [Parameter(Mandatory=$false)] [string]   $downloadDirectory = "C:\Downloads", 
 [Parameter(Mandatory=$false)] [string]   $LicenseFile = $PSScriptRoot + "\resources\license.xml",
 [Parameter(Mandatory=$false)] [string]   $secret
)

$ErrorActionPreference = "Stop"
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
Import-Module $PSScriptRoot\common.psm1 -DisableNameChecking -Force
CheckAdmin

$srcDir = Resolve-Path "$PSScriptRoot\..\src"

if(!$secret) {
	$secret = $Env:my_secret
}

CheckLicense $LicenseFile

Write-Host "Installing prerequisites..." -ForegroundColor Green
New-Item $downloadDirectory -ItemType "directory" -Force -ErrorAction SilentlyContinue

if ((Get-Command "nuget.exe" -ErrorAction SilentlyContinue) -eq $null) {
    choco install NuGet.CommandLine -y
}

Get-PackageProvider -Name Nuget -ForceBootstrap

if(!(Get-PSRepository | Where-Object { ($_.Name -eq "SitecoreGallery") })) {
    Register-PSRepository -Name "SitecoreGallery" `
                          -SourceLocation "https://sitecore.myget.org/F/sc-powershell/api/v2" `
                          -InstallationPolicy Trusted | Out-Null

    Write-Host ("PowerShell repository `"SitecoreGallery`" has been registered.") -ForegroundColor Green
}

$localSqlServerModule = Get-InstalledModule | Where-Object { $_.Name -eq "SqlServer" }
if(!($localSqlServerModule))
{
    Install-module -Name "SqlServer" -Scope AllUsers -Force -SkipPublisherCheck -AllowClobber | Out-Null
    Write-Host ("SqlServer module installed") -ForegroundColor Green
}
else 
{
    $latestSqlServerModule = Find-Module -Name "SqlServer"
    $localSqlServerModuleByVersion = Get-InstalledModule | Where-Object {($_.Name -eq "SqlServer") -and ($_.Version -eq $latestSqlServerModule.Version)}
    if($localSqlServerModuleByVersion -eq $null)
    {
        Install-module -Name "SqlServer" -Scope AllUsers -RequiredVersion $latestSqlServerModule.Version -Force -SkipPublisherCheck -AllowClobber | Out-Null
        Write-Host ("SqlServer module updated") -ForegroundColor Green        
    }
}

if(!(Get-InstalledModule | Where-Object { $_.Name -eq "SitecoreInstallFramework" })) {
    Install-Module -Name "SitecoreInstallFramework" -Repository "SitecoreGallery" -Force -Scope AllUsers -SkipPublisherCheck -AllowClobber | Out-Null
    Write-Host ("Module `"SitecoreInstallFramework`" has been installed.") -ForegroundColor Green
} else {
    [array] $sifModules = Find-Module -Name "SitecoreInstallFramework" -Repository "SitecoreGallery"
    $latestSIFModule = $sifModules[-1]
    $localSIFModuleByVersion = Get-InstalledModule | Where-Object { ($_.Name -eq "SitecoreInstallFramework") -and ($_.Version -eq $latestSIFModule.Version) }
    if($localSIFModuleByVersion -eq $null) {
        Install-module -Name "SitecoreInstallFramework" -Repository "SitecoreGallery" -Scope AllUsers -RequiredVersion $latestSIFModule.Version -Force -SkipPublisherCheck -AllowClobber | Out-Null
        Write-Host ("Module `"SitecoreInstallFramework`" has been updated.") -ForegroundColor Green    
    }
}

Write-Host "Enabling modern security protocols..." -foregroundcolor "green"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 

choco install -y urlrewrite

refreshenv
$env:PSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')

Write-Host "Successfully setup dev environment (time: $($elapsed.Elapsed.ToString()))"