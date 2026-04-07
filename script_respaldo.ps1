<#
.SYNOPSIS
    Script interactivo de respaldo para Windows.
.DESCRIPTION
    Respaldar las carpetas principales del usuario, opciones adicionales y discos adicionales.
    Permite elegir entre un destino local o un servidor remoto por IP.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ask-YesNo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet('S', 'N')]
        [string]$Default = 'S'
    )

    while ($true) {
        $defaultText = if ($Default -eq 'S') { '[S/n]' } else { '[s/N]' }
        $answer = Read-Host "$Message $defaultText"

        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $Default -eq 'S'
        }

        switch ($answer.Trim().ToLower()) {
            's' { return $true }
            'n' { return $false }
            default { Write-Host 'Respuesta no válida. Responda S o N.' -ForegroundColor Yellow }
        }
    }
}

function Get-AdditionalVolumes {
    $volumes = Get-CimInstance -ClassName Win32_LogicalDisk |
        Where-Object {
            $_.DeviceID -ne 'C:' -and ($_.DriveType -in 2, 3)
        }

    $selected = @()
    foreach ($volume in $volumes) {
        $displayName = "$($volume.DeviceID) - $($volume.VolumeName)"
        if (Ask-YesNo "¿Incluir el disco adicional $displayName?" 'N') {
            $selected += $volume.DeviceID + '\'
        }
    }

    return $selected
}

function Resolve-BackupDestination {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -Path $DestinationPath)) {
        try {
            New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
        } catch {
            throw "No se puede crear o acceder al destino: $DestinationPath. Detalle: $($_.Exception.Message)"
        }
    }

    return (Get-Item -Path $DestinationPath).FullName
}

function Get-BackupDestination {
    Write-Host "Destino del backup:" -ForegroundColor Cyan
    Write-Host "1) Servidor remoto mediante dirección IP"
    Write-Host "2) Almacenamiento externo local"

    while ($true) {
        $option = Read-Host 'Elija 1 o 2'
        switch ($option.Trim()) {
            '1' {
                $serverIp = Read-Host 'Ingrese la IP del servidor remoto'
                if ([string]::IsNullOrWhiteSpace($serverIp)) {
                    Write-Host 'Se requiere una IP válida.' -ForegroundColor Yellow
                    continue
                }

                $shareName = Read-Host 'Ingrese el nombre de la carpeta compartida en el servidor (por defecto Backup)'
                if ([string]::IsNullOrWhiteSpace($shareName)) {
                    $shareName = 'Backup'
                }

                $remotePath = "\\$serverIp\$shareName"
                return Resolve-BackupDestination -DestinationPath $remotePath
            }
            '2' {
                $localPath = Read-Host 'Ingrese la ruta local de destino (por ejemplo, E:\Backups)'
                if ([string]::IsNullOrWhiteSpace($localPath)) {
                    Write-Host 'Se requiere una ruta de destino.' -ForegroundColor Yellow
                    continue
                }

                return Resolve-BackupDestination -DestinationPath $localPath
            }
            default {
                Write-Host 'Opción no válida. Elija 1 o 2.' -ForegroundColor Yellow
            }
        }
    }
}

function Copy-BackupFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )

    try {
        $resolvedSource = (Resolve-Path -Path $SourcePath).ProviderPath
    } catch {
        Write-Warning "No se encontró la ruta de origen: $SourcePath"
        return $false
    }

    if ($resolvedSource -match '^[A-Za-z]:\\$') {
        $targetName = $resolvedSource.Substring(0, 1)
        $copySource = Join-Path -Path $resolvedSource -ChildPath '*'
    } else {
        $targetName = Split-Path -Path $resolvedSource -Leaf
        $copySource = $resolvedSource
    }

    $destination = Join-Path -Path $BackupRoot -ChildPath $targetName
    New-Item -Path $destination -ItemType Directory -Force | Out-Null

    try {
        Copy-Item -Path $copySource -Destination $destination -Recurse -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Warning "Error copiando '$resolvedSource' a '$destination': $($_.Exception.Message)"
        return $false
    }
}

function Write-BackupSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SummaryPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    $Lines | Set-Content -Path $SummaryPath -Encoding UTF8
}

# -----------------------------
# Inicio del proceso de respaldo
# -----------------------------

$computerName = $env:COMPUTERNAME
$userProfile = [Environment]::GetFolderPath('UserProfile')

$backupItems = @(
    [PSCustomObject]@{ Name = 'Escritorio'; Path = Join-Path $userProfile 'Desktop'; Required = $true },
    [PSCustomObject]@{ Name = 'Documentos'; Path = Join-Path $userProfile 'Documents'; Required = $true }
)

$optionalFolders = @(
    [PSCustomObject]@{ Name = 'Descargas'; Path = Join-Path $userProfile 'Downloads' },
    [PSCustomObject]@{ Name = 'Música'; Path = Join-Path $userProfile 'Music' },
    [PSCustomObject]@{ Name = 'Imágenes'; Path = Join-Path $userProfile 'Pictures' },
    [PSCustomObject]@{ Name = 'Videos'; Path = Join-Path $userProfile 'Videos' }
)

foreach ($folder in $optionalFolders) {
    if (Test-Path -Path $folder.Path -PathType Container) {
        if (Ask-YesNo "¿Desea respaldar '$($folder.Name)'?" 'N') {
            $backupItems += [PSCustomObject]@{ Name = $folder.Name; Path = $folder.Path; Required = $false }
        }
    }
}

$extraVolumes = Get-AdditionalVolumes

Write-Host "\nSeleccionando destino del respaldo..." -ForegroundColor Cyan
$backupDestination = Get-BackupDestination
$backupRoot = Join-Path -Path $backupDestination -ChildPath $computerName
New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null

$summaryPath = Join-Path -Path $backupRoot -ChildPath 'BackupSummary.txt'
$logPath = Join-Path -Path $backupRoot -ChildPath 'ComputerName.txt'

Write-BackupSummary -SummaryPath $logPath -Lines @(
    "Equipo: $computerName",
    "Usuario: $env:USERNAME",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
)

$summaryLines = @(
    "Resumen de respaldo",
    "===================",
    "Equipo: $computerName",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Destino: $backupRoot",
    ''
)

Write-Host "\nIniciando respaldo en: $backupRoot" -ForegroundColor Green

$completed = 0
$failed = 0

foreach ($item in $backupItems) {
    if (-not (Test-Path -Path $item.Path -PathType Container)) {
        Write-Warning "La ruta no existe: $($item.Path)"
        $summaryLines += "[Omitido] $($item.Name) - Ruta no encontrada: $($item.Path)"
        continue
    }

    Write-Host "Copiando $($item.Name)..." -ForegroundColor Cyan
    if (Copy-BackupFolder -SourcePath $item.Path -BackupRoot $backupRoot) {
        $completed++
        $summaryLines += "[OK] $($item.Name) -> $($item.Path)"
    } else {
        $failed++
        $summaryLines += "[Error] $($item.Name) -> $($item.Path)"
    }
}

foreach ($volume in $extraVolumes) {
    Write-Host "Copiando disco adicional $volume..." -ForegroundColor Cyan
    if (Copy-BackupFolder -SourcePath $volume -BackupRoot $backupRoot) {
        $completed++
        $summaryLines += "[OK] Disco adicional $volume"
    } else {
        $failed++
        $summaryLines += "[Error] Disco adicional $volume"
    }
}

$summaryLines += ''
$summaryLines += "Carpetas copiadas: $completed"
$summaryLines += "Errores: $failed"

Write-BackupSummary -SummaryPath $summaryPath -Lines $summaryLines

Write-Host "\nRespaldo finalizado." -ForegroundColor Green
Write-Host "Resumen guardado en: $summaryPath"
if ($failed -gt 0) {
    Write-Host "Algunas carpetas no se pudieron copiar. Revise el archivo de resumen." -ForegroundColor Yellow
} else {
    Write-Host "Copia completada sin errores." -ForegroundColor Green
}

Read-Host -Prompt 'Presione ENTER para finalizar'
