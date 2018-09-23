param
(
 [Parameter(Mandatory=$true)]  [string]   $instanceName,
 [Parameter(Mandatory=$false)] [string]   $rootFolder = "C:\inetpub\wwwroot",
 [Parameter(Mandatory=$false)] [string]   $instanceRoot = "$rootFolder\$instanceName",
 [Parameter(Mandatory=$false)] [switch]   $installSitecore = $true,
 [Parameter(Mandatory=$false)] [switch]   $buildSolution = $true,
 [Parameter(Mandatory=$false)] [switch]   $deploySolution = $true,
 [Parameter(Mandatory=$false)] [switch]   $createArtifacts = $true,
 [Parameter(Mandatory=$false)] [string]   $downloadDirectory = "C:\Downloads",
 [Parameter(Mandatory=$false)] [string]   $cmsPackage = "Sitecore 9.0.2 rev. 180604 (OnPrem)_cm.scwdp.zip",
 [Parameter(Mandatory=$false)] [string]   $LicenseFile = $PSScriptRoot + "\resources\license.xml",
 [Parameter(Mandatory=$false)] [string]   $SqlServer = ".",
 [Parameter(Mandatory=$true)]  [string]   $SqlAdminUser,
 [Parameter(Mandatory=$true)]  [string]   $SqlAdminPassword,
 [Parameter(Mandatory=$true)]  [string]   $adminPassword,
 [Parameter(Mandatory=$false)] [string]   $msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe",
 [Parameter(Mandatory=$false)] [string]   $Configuration = "Release",
 [Parameter(Mandatory=$false)] [string]   $SolrDir = 'C:\solr\',
 [Parameter(Mandatory=$false)] [string]   $SolrVersion = '6.6.2',
 [Parameter(Mandatory=$false)] [string]   $SolrPort = '8983',
 [Parameter(Mandatory=$false)] [string]   $secret
)

$ErrorActionPreference = "Stop"
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
Import-Module $PSScriptRoot\common.psm1 -DisableNameChecking -Force
$websitePath = "$instanceRoot\Website"
$ci = ($Env:APPVEYOR -eq "True")

. "$PSScriptRoot\environment-setup.ps1" -licenseFile $LicenseFile -secret $secret -downloadDirectory $downloadDirectory

cd $PSScriptRoot\..

if ($buildSolution) {
    Write-Host "Restoring Nuget packages" -ForegroundColor Green
    nuget restore "$srcDir\Devops.AppVeyor.sln"

	Write-Host "Building the solution" -ForegroundColor Green
	MyBuild -path Devops.AppVeyor.sln -Configuration $Configuration
}

if ($installSitecore) {
    Write-Host "Installing Sitecore, site name $instanceName, package $cmsPackage" -ForegroundColor Green
    DownloadIfNeeded "https://schreudersbuild.blob.core.windows.net/installs/$cmsPackage" "$downloadDirectory\$cmsPackage"

    $CMPackage = Resolve-Path "$downloadDirectory\$cmsPackage"
    $CMConfig = Resolve-Path "$PSScriptRoot\sitecore-XM1-cm.json"
    $SolrConfig = Resolve-Path "$PSScriptRoot\sitecore-solr.json"
    $SolrServerConfig = Resolve-Path "$PSScriptRoot\SolrServer.json"

    cd $PSScriptRoot

    Write-Host "================= Installing Solr if necessary =================" -foregroundcolor "green"
    Install-SitecoreConfiguration $SolrServerConfig -Skip "Verify Solr is working"

    Write-Host "================= Installing Solr cores =================" -foregroundcolor "green"
    Install-SitecoreConfiguration -Path $SolrConfig `
                              -SolrUrl "https://solr:$SolrPort/solr" `
                              -SolrRoot "$($SolrDir)\Solr-$($SolrVersion)" `
                              -SolrService "Solr-$SolrVersion" `
                              -CorePrefix $instanceName

    Write-Host "================= Installing Content Management =================" -foregroundcolor "green"

    sqlcmd -S $SqlServer -U $SqlAdminUser -P $SqlAdminPassword -h-1 -Q "sp_configure 'contained database authentication', 1; RECONFIGURE;"

    Install-SitecoreConfiguration -Path $CMConfig `
                              -Package $CMPackage `
                              -LicenseFile $LicenseFile `
                              -SqlDbPrefix $instanceName `
                              -SolrCorePrefix $instanceName `
                              -SiteName $instanceName `
                              -SqlServer $SqlServer `
                              -SqlAdminUser $SqlAdminUser `
                              -SqlAdminPassword $SqlAdminPassword `
                              -SolrUrl "https://solr:$SolrPort/solr" `
                              -SitecoreAdminPassword $adminPassword

    cd $PSScriptRoot\..
}

if ($createArtifacts) {
    Write-Host "Now zip it all up" -ForegroundColor Green
    MyZip -arguments "output\Files.zip $srcDir\Devops.AppVeyor\bin\*"
}

if ($deploySolution) {
    Write-Host "Deploying files" -ForegroundColor Green
	#MySync .\output\working.dir\ $websitePath
}

Write-Host "Successfully deployed on $instanceName (time: $($elapsed.Elapsed.ToString()))" -ForegroundColor Green