param
(
  [Parameter(Mandatory=$true)][string]$instanceName,
  [Parameter(Mandatory=$false)][string]$rootDir = "C:\inetpub\wwwroot\$instanceName",
  [Parameter(Mandatory=$false)][string]$websiteDir = "$rootDir\Website"
)

Write-Host "Removing Include files" -ForegroundColor Green
Remove-Item -Recurse $websiteDir\App_Config\Include\Foundation -Force
Remove-Item -Recurse $websiteDir\App_Config\Include\Feature -Force
Remove-Item -Recurse $websiteDir\App_Config\Include\Project -Force

Write-Host "Removing bin files" -ForegroundColor Green
Remove-Item $websiteDir\bin\Foundation.*
Remove-Item $websiteDir\bin\Feature.*
Remove-Item $websiteDir\bin\Project.*

Write-Host "Removing Views" -ForegroundColor Green
Remove-Item -Recurse $websiteDir\Views\Foundation -Force
Remove-Item -Recurse $websiteDir\Views\Feature -Force
Remove-Item -Recurse $websiteDir\Views\Project -Force

Write-Host "Removing assets" -ForegroundColor Green
Remove-Item -Recurse $websiteDir\assets -Force

Write-Host "Resetting Global.asax" -ForegroundColor Green
Set-Content -Path $websiteDir\Global.asax "<%@Application Language='C#' Inherits=""Sitecore.Web.Application"" %>"