$ErrorActionPreference = "Stop"
$url = $Env:Url
$ship_url = "${url}/sitecore_ship"

Function DeployTds {
    Param (
        [string]$name,
		[string]$ship_url
    )

    Write-Host "Deploying TDS package: $name" -ForegroundColor Green
    Invoke-WebRequest -Method POST -Body "path=${pwd}\${name}" -Uri "${ship_url}/package/install" -ContentType application/x-www-form-urlencoded -TimeoutSec 600 -UseBasicParsing
	
    if($LastExitCode -ne 0) {
      $host.SetShouldExit($LastExitCode)
    }
}

Function Warmup {
	Param (
		[string]$url
    )
	
	Write-Host "Warming up..." -ForegroundColor Yellow
	$page = Invoke-WebRequest -Uri $url -TimeoutSec 600 -UseBasicParsing
}

Warmup "${ship_url}/about"
DeployTds "Devops.AppVeyor.Update" $ship_url

Write-Host "Testing site..." -ForegroundColor Yellow
Warmup $url