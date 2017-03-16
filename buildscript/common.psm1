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

Function Configure-TDS
(
  [Parameter(Mandatory=$true)]  [string]$instanceName,
  [Parameter(Mandatory=$true)]  [string]$instanceRoot
)
{
  Write-Host "Updating TDS configuration files" -foregroundcolor "green"
  Copy-Item "$PSScriptRoot/resources/TdsGlobal.config.user" "$PSScriptRoot\..\code\TdsGlobal.config.user"
  
  $tdsUserConfigFilePath = Resolve-Path "$PSScriptRoot\..\code\TdsGlobal.config.user"
  Write-Host "Setting values in $tdsUserConfigFilePath" -foregroundcolor "green"
  $xml = New-Object XML
  $xml = [xml](Get-Content $tdsUserConfigFilePath)
  $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
  $ns.AddNamespace("ns", $xml.DocumentElement.NamespaceURI)

  $sitecoreWebUrl = $xml.SelectSingleNode("//ns:PropertyGroup/ns:SitecoreWebUrl", $ns)
  $sitecoreWebUrl.InnerText = "http://$instanceName"

  $sitecoreDeployFolder = $xml.SelectSingleNode("//ns:PropertyGroup/ns:SitecoreDeployFolder", $ns)
  $sitecoreDeployFolder.InnerText = "$instanceRoot\Website"

  $xml.Save($tdsUserConfigFilePath)
}

Function Sitecore-ChangePassword(
	[string]$instanceName, 
	[string]$oldPassword, 
	[string]$newPassword
)
{
	$hostname = "http://$instanceName"
	$login = Invoke-WebRequest "$hostname/sitecore/admin/login.aspx" -SessionVariable session
	$login.Forms[0].Fields.LoginTextBox = "sitecore\admin"
	$login.Forms[0].Fields.PasswordTextBox = $oldPassword

	$postPage = $hostname
	$postPage += $login.Forms[0].Action
	$mainPage = Invoke-WebRequest $postPage -WebSession $session -Body $login -Method Post

	$setPasswordPage = Invoke-WebRequest "$hostname/sitecore/shell/~/xaml/Sitecore.Shell.Applications.Security.SetPassword.aspx?us=sitecore%5CAdmin" -WebSession $session
    
	$parameters = @{'__PARAMETERS'='OK_Click';'__EVENTTARGET'='OK';'__EVENTARGUMENT'='';'__SOURCE'='OK';'__EVENTTYPE'='click';'__CONTEXTMENU'='';'__MODIFIED'='1';'__ISEVENT'='1';'__SHIFTKEY'='';'__CTRLKEY'='';'__ALTKEY'='';'__BUTTON'='0';'__KEYCODE'='0';'__X'='2414';'__Y'='1246';
	'__URL'='http=//$instanceName/sitecore/shell/~/xaml/Sitecore.Shell.Applications.Security.SetPassword.aspx?us=sitecore%5CAdmin';'__CSRFTOKEN'=$setPasswordPage.Forms[0].Fields["__CSRFTOKEN"];'__PAGESTATE'=$setPasswordPage.Forms[0].Fields["__PAGESTATE"];'__VIEWSTATE'='';'__EVENTVALIDATION'=$setPasswordPage.Forms[0].Fields["__EVENTVALIDATION"];'ctl00$ctl00$ctl00$ctl00$ctl05$OldPassword'=$oldPassword;'ctl00$ctl00$ctl00$ctl00$ctl05$NewPassword'=$newPassword;'ctl00$ctl00$ctl00$ctl00$ctl05$ConfirmPassword'=$newPassword;'RandomPassword'='No password has been generated yet.'}

	$out = Invoke-WebRequest "$hostname/sitecore/shell/~/xaml/Sitecore.Shell.Applications.Security.SetPassword.aspx?us=sitecore%5CAdmin" -WebSession $session -Body $parameters -Method Post
}

Function MyBuild {
    Param (
        [Parameter(Mandatory=$true)][string]$path,
        [Parameter(Mandatory=$false)][string]$targetDir,
        [Parameter(Mandatory=$false)][string]$configuration = "Release",
        [Parameter(Mandatory=$false)][switch]$build = $true,
        [Parameter(Mandatory=$false)][switch]$deploy = $true
    )

    $fullPath = "code\$path"
    if ($build) {
        Write-Host "Building $path in $configuration configuration" -ForegroundColor Green
      
        if ($deploy) {
            & "C:\Program Files (x86)\MSBuild\14.0\Bin\msbuild.exe" $fullPath /verbosity:minimal /p:DeployOnBuild=true`;Configuration=$configuration
        } else {
            & "C:\Program Files (x86)\MSBuild\14.0\Bin\msbuild.exe" $fullPath /verbosity:minimal /p:Configuration=$configuration;
        }
        
        if (!($LastExitCode -eq "0")) {
			throw "Build failed with exit code $LastExitCode"
        }
    }

    if ($targetDir) {
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
  Invoke-Expression "buildscript\tools\7z a $arguments"

  if (!($LastExitCode -eq "0")) {
    throw "7z failed with $LastExitCode"
  }
}