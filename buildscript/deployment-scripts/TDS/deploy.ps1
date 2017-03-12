$ErrorActionPreference = "Stop"
$url = $Env:url
$ship_url = "${url}/sitecore_ship"
$branch = $Env:APPVEYOR_REPO_BRANCH

Function DeployTds {
    Param (
        [string]$name
    )

    Write-Host "Deploying TDS package: $name" -ForegroundColor Green
    Invoke-WebRequest -Method POST -Body "path=${pwd}\${name}" -Uri "${ship_url}/package/install" -ContentType application/x-www-form-urlencoded -TimeoutSec 600 -UseBasicParsing
	Warmup

    if($LastExitCode -ne 0) {
      $host.SetShouldExit($LastExitCode)
    }
}

Function Warmup() {
	Write-Host "Warming up..." -ForegroundColor Yellow
	$page = Invoke-WebRequest -Uri ${ship_url}/about -TimeoutSec 600 -UseBasicParsing
}

Warmup
DeployTds -name "API.Update"

Write-Host "Testing site..." -ForegroundColor Yellow
$page = Invoke-WebRequest -Uri ${url} -TimeoutSec 600 -UseBasicParsing