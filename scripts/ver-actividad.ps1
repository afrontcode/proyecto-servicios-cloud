param(
    [string]$Perfil = "finops-demo",
    [string]$Region = "us-east-2",
    [string]$AppInstanceId = "",
    [string]$DataInstanceId = ""
)

function aws_cmd {
    param([string[]]$cmdArgs)
    & aws --profile $Perfil --region $Region @cmdArgs
}

function en_instancia {
    param(
        [string]$InstanciaId,
        [string]$Comando
    )

    if (-not $InstanciaId) {
        Write-Host "  Instancia no disponible."
        return
    }

    $escapedCmd = $Comando.Replace('"', '\"')
    $cmdId = (aws_cmd ssm send-command `
        --document-name "AWS-RunShellScript" `
        --instance-ids $InstanciaId `
        --parameters "commands=[`"$escapedCmd`"]" `
        --query "Command.CommandId" `
        --output text 2>&1).ToString().Trim()

    if ($cmdId -like "*error*" -or $cmdId -like "*denied*" -or [string]::IsNullOrWhiteSpace($cmdId)) {
        Write-Host "  ERROR: $cmdId"
        return
    }

    $estado = ""
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Seconds 2
        $estado = (aws_cmd ssm get-command-invocation `
            --command-id $cmdId `
            --instance-id $InstanciaId `
            --query "Status" `
            --output text 2>$null).ToString().Trim()

        if ($estado -eq "Success" -or $estado -eq "Failed") {
            break
        }
    }

    $salida = aws_cmd ssm get-command-invocation `
        --command-id $cmdId `
        --instance-id $InstanciaId `
        --query "StandardOutputContent" `
        --output text 2>&1

    if ($salida) {
        $salida -split "`n" | ForEach-Object { Write-Host "  $_" }
    }
}

Write-Host "=============== CONTENEDORES LOCALES ==============="
try {
    $compose = docker compose ps --format '  {{.Name}}\t{{.Status}}' 2>&1
    if ($LASTEXITCODE -eq 0 -and $compose) {
        $compose | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "  (stack local apagado)"
    }
} catch {
    Write-Host "  (stack local apagado)"
}

Write-Host ""
Write-Host "=============== INSTANCIAS EN AWS ==============="
$salida = aws_cmd ec2 describe-instances `
    --filters "Name=tag:Project,Values=finops-demo" "Name=instance-state-name,Values=running" `
    --query 'Reservations[].Instances[].{Nombre:Tags[?Key==`Name`]|[0].Value,Id:InstanceId,IPprivada:PrivateIpAddress,IPpublica:PublicIpAddress}' `
    --output table 2>&1
Write-Host $salida

if (-not $AppInstanceId) {
    $AppInstanceId = (aws_cmd ec2 describe-instances `
        --filters "Name=tag:Project,Values=finops-demo" "Name=tag:Name,Values=finops-app" "Name=instance-state-name,Values=running" `
        --query "Reservations[0].Instances[0].InstanceId" --output text 2>$null).ToString().Trim()
    if (-not $AppInstanceId -or $AppInstanceId -eq "None") {
        $AppInstanceId = "i-0983b8d7cd0be04ef"
    }
}

if (-not $DataInstanceId) {
    $DataInstanceId = (aws_cmd ec2 describe-instances `
        --filters "Name=tag:Project,Values=finops-demo" "Name=tag:Name,Values=finops-data" "Name=instance-state-name,Values=running" `
        --query "Reservations[0].Instances[0].InstanceId" --output text 2>$null).ToString().Trim()
    if (-not $DataInstanceId -or $DataInstanceId -eq "None") {
        $DataInstanceId = "i-0ce92594563e7e299"
    }
}

Write-Host "=============== APP EN AWS: ultimas lineas ==============="
en_instancia -InstanciaId $AppInstanceId -Comando "docker logs --tail 6 finops-app"

Write-Host ""
Write-Host "=============== DATOS EN POSTGRESQL (AWS) ==============="
en_instancia -InstanciaId $DataInstanceId -Comando "docker exec finops-postgres psql -U finops -d finops -c 'SELECT id, nota, creado FROM prueba_persistencia;'"

Write-Host ""
Write-Host "Grafana local: http://localhost:3000  (admin/admin)"
