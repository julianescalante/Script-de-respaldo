<#
.SYNOPSIS
    Script de respaldo automático mediante Robocopy.
.DESCRIPTION
    Orquesta el respaldo de carpetas de usuario hacia destinos locales o remotos,
    generando reportes detallados y manejando errores de transferencia.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- 1. OBTENCIÓN DE RUTAS ---
function Get-UserFolders {
    return @{
        Desktop   = [Environment]::GetFolderPath('Desktop')
        Documents = [Environment]::GetFolderPath('MyDocuments')
        Downloads = Join-Path $HOME "Downloads"
        Music     = [Environment]::GetFolderPath('MyMusic')
        Pictures  = [Environment]::GetFolderPath('MyPictures')
        Videos    = [Environment]::GetFolderPath('MyVideos')
    }
}

# --- 2. INTERACCIÓN Y FILTRADO ---
function Get-Answer {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Hashtable]$UserFolders
    )

    begin {
        Write-Host "`n--- Configuración de Alcance del Respaldo ---" -ForegroundColor Cyan
        $FinalPaths = @{}
        
        $Obligatorios = @('Desktop', 'Documents')
        $Opcionales   = @('Downloads', 'Music', 'Pictures', 'Videos')
    }

    process {
        foreach ($key in $Obligatorios) {
            if ($UserFolders.ContainsKey($key)) {
                if (Test-Path $UserFolders[$key]) {
                    $FinalPaths[$key] = $UserFolders[$key]
                    Write-Host "[MANDATORIO] Incluyendo $key" -ForegroundColor Gray
                }
            }
        }

        foreach ($key in $Opcionales) {
            if ($UserFolders.ContainsKey($key) -and (Test-Path $UserFolders[$key])) {
                $choice = ""
                while ($choice -notmatch "^[SN]$") {
                    $choice = (Read-Host "¿Desea incluir la carpeta de [$key]? (S/N)").ToUpper().Trim()
                }

                if ($choice -eq 'S') {
                    $FinalPaths[$key] = $UserFolders[$key]
                }
            }
        }
    }

    end {
        if ($FinalPaths.Count -eq 0) {
            Write-Warning "No se seleccionaron carpetas válidas."
        }

        return [PSCustomObject]@{
            SelectedPaths = $FinalPaths
            TimeStamp     = Get-Date
            Count         = $FinalPaths.Count
            ComputerName  = $env:COMPUTERNAME
        }
    }
}

# --- 3. RESPALDO EXTERNO (USB/DISCO) ---
function Get-External-Backup {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$BackupConfig,
        [Parameter(Mandatory = $true)]
        [string]$DevicePath
    )
    begin {
        $Resultados = @()
        if (-not (Test-Path $DevicePath)) { throw "Dispositivo no encontrado en $DevicePath" }
    }
    process {
        $Rutas = $BackupConfig.SelectedPaths
        foreach ($Folder in $Rutas.Keys) {
            $Destino = Join-Path $DevicePath "Backup_$($env:COMPUTERNAME)\$Folder"
            if (-not (Test-Path $Destino)) { New-Item -ItemType Directory -Force -Path $Destino | Out-Null }

            Write-Host " > Copiando $Folder..." -NoNewline
            $ExitCode = & robocopy $Rutas[$Folder] $Destino /E /Z /R:2 /W:2 /MT:8 /XJD /XJF
            $Status   = if ($ExitCode -lt 8) { "Éxito" } else { "Error" }
            $Color    = if ($Status -eq "Éxito") { "Green" } else { "Red" }
            Write-Host " [$Status]" -ForegroundColor $Color
            
            $Resultados += [PSCustomObject]@{ Carpeta = $Folder; ExitCode = $ExitCode; Status = $Status }
        }
    }
    end { return $Resultados }
}

# --- 4. RESPALDO REMOTO (IP) ---
function Get-Remote-Backup {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$BackupConfig,
        [Parameter(Mandatory = $true)]
        [string]$ServerIP
    )
    begin {
        $Resultados = @()
        if (-not (Test-Connection -ComputerName $ServerIP -Count 1 -Quiet)) { throw "Servidor $ServerIP no responde." }
    }
    process {
        $Rutas = $BackupConfig.SelectedPaths
        $RemoteRoot = "\\$ServerIP\C$\Backups_Remote\$($env:COMPUTERNAME)"
        foreach ($Folder in $Rutas.Keys) {
            $Destino = Join-Path $RemoteRoot $Folder
            if (-not (Test-Path $Destino)) { New-Item -ItemType Directory -Force -Path $Destino | Out-Null }

            Write-Host " > Enviando $Folder..." -NoNewline
            $ExitCode = & robocopy $Rutas[$Folder] $Destino /E /Z /R:5 /W:10 /MT:16 /NP /XJD /XJF
            $Status   = if ($ExitCode -lt 8) { "Éxito" } else { "Error" }
            $Color    = if ($Status -eq "Éxito") { "Green" } else { "Red" }
            Write-Host " [$Status]" -ForegroundColor $Color
            
            $Resultados += [PSCustomObject]@{ Carpeta = $Folder; ExitCode = $ExitCode; Status = $Status }
        }
    }
    end { return $Resultados }
}

# --- 5. RESUMEN Y LOG ---
function Get-Backup-Summary {
    param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)][PSCustomObject[]]$ResultadosDetallados)
    begin {
        $LogPath = Join-Path $PSScriptRoot "Backup_Log_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmm').log"
        Start-Transcript -Path $LogPath -NoClobber
        Write-Host "`n=== RESUMEN FINAL ===" -ForegroundColor Cyan
        $Acumulado = @()
    }
    process { $Acumulado += $ResultadosDetallados }
    end {
        $Acumulado | ForEach-Object {
            Write-Host "Carpeta: $($_.Carpeta) - Status: $($_.Status) (Code: $($_.ExitCode))"
        }
        Stop-Transcript
        return Get-Item $LogPath
    }
}

# --- 6. FUNCIÓN ORQUESTADORA (EJECUCIÓN) ---
function Get-Execution {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "   SISTEMA DE RESPALDO AUTOMATIZADO" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    
    try {
        $Modo = ""
        while ($Modo -notmatch "^[ER]$") {
            $Modo = (Read-Host "¿Tipo de respaldo? (E)xterno USB / (R)emoto Servidor").ToUpper()
        }

        if ($Modo -eq 'E') {
            $Drive = Read-Host "Ingrese letra de unidad (ej: F:\)"
            $Log = Get-UserFolders | Get-Answer | Get-External-Backup -DevicePath $Drive | Get-Backup-Summary
        } else {
            $IP = Read-Host "Ingrese IP del servidor"
            $Log = Get-UserFolders | Get-Answer | Get-Remote-Backup -ServerIP $IP | Get-Backup-Summary
        }

        Write-Host "`nPROCESO TERMINADO." -ForegroundColor Green
        Write-Host "El log se abrirá a continuación..."
        Start-Process notepad.exe -ArgumentList $Log.FullName
    } 
    catch {
        Write-Host "`nERROR CRÍTICO: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# LANZAMIENTO
Get-Execution
