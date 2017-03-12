$ErrorActionPreference = "Stop"
cd $PSScriptRoot

$rootPath = $Env:SitecoreRootPath

Write-Host "SitecoreRootPath: ${rootPath}" -ForegroundColor Yellow

Copy-Item * "$rootPath\Website" -Recurse -Force