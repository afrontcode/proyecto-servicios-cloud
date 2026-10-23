$ErrorActionPreference = "Stop"

$infraDir = Join-Path $PSScriptRoot "..\infra"
if (-not (Test-Path $infraDir)) {
    Write-Error "ERROR: no se encuentra el directorio infra"
    exit 1
}

Push-Location $infraDir
try {
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error "ERROR: terraform not installed"
        exit 1
    }

    terraform fmt -check -recursive
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    terraform init -backend=false
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    terraform validate
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    terraform plan -input=false -var='enable_network=false' -var='enable_nat=false' -var='enable_compute=false'
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "No apply performed."
}
finally {
    Pop-Location
}
