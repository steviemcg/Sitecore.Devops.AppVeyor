param
(
 [Parameter(Mandatory=$true)]  [string]   $instanceName,
 [Parameter(Mandatory=$false)] [string]   $rootFolder = "C:\inetpub\wwwroot",
 [Parameter(Mandatory=$false)] [string]   $instanceRoot = "$rootFolder\$instanceName",
 [Parameter(Mandatory=$false)] [switch]   $installSitecore = $true,
 [Parameter(Mandatory=$false)] [switch]   $buildSolution = $true,
 [Parameter(Mandatory=$false)] [switch]   $deploySolution = $true,
 [Parameter(Mandatory=$false)] [switch]   $createArtifacts = $false,
 [Parameter(Mandatory=$false)] [string]   $downloadDirectory = "C:\Downloads", 
 [Parameter(Mandatory=$false)] [string]   $bfDirectory = "C:\BFResources",
 [Parameter(Mandatory=$false)] [string]   $cmsVersion = "Sitecore 8.2 rev. 161221.zip",
 [Parameter(Mandatory=$false)] [string]   $cmsPackage = "$bfDirectory\$cmsVersion",
 [Parameter(Mandatory=$false)] [string]   $licensePath = $PSScriptRoot + "\resources\license.xml",
 [Parameter(Mandatory=$false)] [string]   $dbServer = ".",
 [Parameter(Mandatory=$true)]  [string]   $dbUser,
 [Parameter(Mandatory=$true)]  [string]   $dbPass,
 [Parameter(Mandatory=$true)]  [string]   $adminPassword,
 [Parameter(Mandatory=$false)] [string]   $msbuild = "C:\Program Files (x86)\MSBuild\14.0\Bin\msbuild.exe",
 [Parameter(Mandatory=$false)] [string]   $Configuration = "Debug",
 [Parameter(Mandatory=$false)] [string]   $ConfigConfiguration = "Local",
 [Parameter(Mandatory=$false)] [string]   $solrVersion = "5.1.0",
 [Parameter(Mandatory=$false)] [string]   $tdsVersion = "5.6.0.12",
 [Parameter(Mandatory=$false)] [string]   $secret,
 [Parameter(Mandatory=$false)] [string]   $repositoryUrl 
)

$ErrorActionPreference = "Stop"
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
Import-Module $PSScriptRoot\common.psm1 -DisableNameChecking -Force
$websitePath = "$instanceRoot\Website"
$ci = ($Env:APPVEYOR -eq "True")

. "$PSScriptRoot\environment-setup.ps1" -licensePath $licensePath -secret $secret -repositoryUrl $repositoryUrl -downloadDirectory $downloadDirectory -bfDirectory $bfDirectory -tdsVersion $tdsVersion

cd $PSScriptRoot\..

if ($buildSolution) {
    Write-Host "Restoring Nuget packages" -ForegroundColor Green

    nuget restore "$codeDir\Devops.AppVeyor.sln"
}

if ($installSitecore) {
    Import-Module SOLR
    Import-Module SitecoreConfig    
    
    Write-Host "Cleaning instance $instanceName" -ForegroundColor Green
    Clean-Instance -InstanceName $instanceName -SqlServerName $dbServer

    Write-Host "Deploying Solr" -ForegroundColor Green
    $solrZipTarget = "$downloadDirectory\solr-$solrVersion.zip"
    DownloadIfNeeded "https://archive.apache.org/dist/lucene/solr/$solrVersion/solr-$solrVersion.zip" $solrZipTarget
    Deploy-Solr -InstanceName $instanceName -SolrZip $solrZipTarget -SolrVersion $solrVersion

    Write-Host "Installing Sitecore, site name $instanceName, package $cmsPackage" -ForegroundColor Green
    Deploy-All -InstanceName $instanceName -LicenseFile $licensePath -cmsPackage $cmsPackage -DatabaseUser $dbUser -DatabasePassword $dbPass -SuppressOutput -SqlServerName $dbServer -SitecorePath $instanceRoot
	
    Write-Host "Switching Lucene to Solr" -ForegroundColor Green
    Config-Sitecore -InstanceName $instanceName -WebsitePath $rootFolder -SolrSearchProvider:$true -SolrHost localhost -SolrPort 8984 -SolrInstName $instanceName -LuceneSearchProvider:$false  
    Config-Modules -InstanceName $instanceName -WebsitePath $rootFolder -Solr:$true -SolrInstName $instanceName -Lucene:$false
        
    Check-SiteStatus $instanceName

    Write-Host "Changing default admin password" -ForegroundColor Green
    Sitecore-ChangePassword $instanceName "b" $adminPassword
}

Configure-TDS $instanceName $instanceRoot

if ($buildSolution) {
    New-Item output -ItemType "directory" -Force -ErrorAction SilentlyContinue

	Write-Host "Building the solution" -ForegroundColor Green
	MyBuild -path Devops.AppVeyor.sln -Configuration $ConfigConfiguration

    Write-Host "Configuration files" -ForegroundColor Green
    MyBuild -path Devops.AppVeyor.Configuration\Devops.AppVeyor.Configuration.csproj -Configuration Local
	MyBuild -path Devops.AppVeyor.Configuration\Devops.AppVeyor.Configuration.csproj -Configuration Dev
	MyBuild -path Devops.AppVeyor.Configuration\Devops.AppVeyor.Configuration.csproj -Configuration Test
	MyBuild -path Devops.AppVeyor.Configuration\Devops.AppVeyor.Configuration.csproj -Configuration Production

	Write-Host "Copying to output directory" -ForegroundColor Green
	MyBuild -path Devops.AppVeyor\Devops.AppVeyor.csproj -Configuration $Configuration -targetDir output/working.dir/ -build:$false
	MyBuild -path Devops.AppVeyor.Configuration\Devops.AppVeyor.Configuration.csproj -Configuration $ConfigConfiguration -targetDir output/working.dir/ -build:$false
	Remove-Item .\output\working.dir\bin\Devops.AppVeyor.Configuration.*

    if ($createArtifacts) {
        Write-Host "Now zip it all up" -ForegroundColor Green
        MyZip -arguments "output\Files.zip .\buildscript\deployment-scripts\Files\deploy.ps1 .\output\working.dir\*"
        MyZip -arguments "output\config-local.zip .\buildscript\deployment-scripts\Files\deploy.ps1 .\code\Devops.AppVeyor.Configuration\obj\Local\Package\PackageTmp\*"
        MyZip -arguments "output\config-dev.zip .\buildscript\deployment-scripts\Files\deploy.ps1 .\code\Devops.AppVeyor.Configuration\obj\Dev\Package\PackageTmp\*"
        MyZip -arguments "output\config-test.zip .\buildscript\deployment-scripts\Files\deploy.ps1 .\code\Devops.AppVeyor.Configuration\obj\Test\Package\PackageTmp\*"
        MyZip -arguments "output\config-production.zip .\buildscript\deployment-scripts\Files\deploy.ps1 .\code\Devops.AppVeyor.Configuration\obj\Production\Package\PackageTmp\*"

        if ($Configuration -eq "Release") {
            MyZip -arguments "output\TDS.zip .\buildscript\deployment-scripts\TDS\deploy.ps1 .\code\Devops.AppVeyor.TDS.Master\bin\Package_Release\Devops.AppVeyor.Update"
        }
    }
}

if ($deploySolution) {
    Write-Host "Deploying files" -ForegroundColor Green
	MySync .\output\working.dir\ $websitePath
    MySync .\code\Devops.AppVeyor.ConfigurationFiles\obj\$ConfigConfiguration\Package\PackageTmp\ $websitePath

    Check-SiteStatus $instanceName
    
    Write-Host "Rebuilding indexes" -ForegroundColor Green
    Rebuild-Indexes $instanceName

    Check-SiteStatus $instanceName
}

Write-Host "Successfully deployed on $instanceName (time: $($elapsed.Elapsed.ToString()))" -ForegroundColor Green