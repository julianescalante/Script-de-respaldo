<#
.SYNOPSIS
    Script interactivo de respaldo automático para Windows.

.DESCRIPTION
    Respalda las carpetas principales del perfil del usuario (Desktop, Documents)
    con opciones para incluir carpetas adicionales (Downloads, Music, Pictures, Videos)
    y discos adicionales en el sistema.
    
    Ofrece dos modos de destino:
    - Servidor remoto mediante dirección IP (ruta UNC)
    - Almacenamiento local externo
    
    Genera un sumario detallado al finalizar con logs de éxitos y errores.

.REQUIREMENTS
    - Windows PowerShell 5.0 o superior
    - Permisos de lectura en las carpetas a respaldar
    - Permisos de escritura en el destino del respaldo
    - Para destinos remotos: acceso de red al servidor

.NOTES
    - El script detiene la ejecución en errores críticos (modo StrictMode)
    - Las carpetas se organizan por nombre de equipo en el destino
    - Se generan archivos de resumen para auditoría del respaldo
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- CONFIGURACIÓN DE CARPETAS OBLIGATORIAS ---
$Origen1 = "C:\Users\Public\Documents"
$Origen2 = "C:\Users\Public\Desktop"


$Logs = "C:\Scripts\Logs_Backup.txt"


# --- 2. CREAR CARPETA CON FECHA ---
$FechaActual = Get-Date -Format "yyyy-MM-dd"
$RutaDestinoFinal = Join-Path $DestinoDisco $FechaActual

if (-not (Test-Path $RutaDestinoFinal)) {
    New-Item -ItemType Directory -Path $RutaDestinoFinal
}

# --- EJECUTAR COPIAS ---
function Realizar-Backup-almacenamiento-externo {
    param (
        [string]$RutaOrigen,
        [string]$DiscoDestino
    )

    try(Test-Path $DestinoDisco) {
        Copy-Item -Path $RutaOrigen -Destination $RutaDestino -Recurse -ErrorAction Stop
        Add-Content $Logs "$(Get-Date): ÉXITO - Respaldo de $RutaOrigen a $RutaDestino completado."
    }
    catch {
        Add-Content $Logs "$(Get-Date): ERROR - Fallo al respaldar $RutaOrigen a $RutaDestino. Detalles: $_"
        exit
    }

    try {
        Copy-Item -Path $RutaOrigen -Destination $RutaDestino -Recurse -ErrorAction Stop
        Add-Content $Logs "$(Get-Date): ÉXITO - Respaldo de $RutaOrigen a $RutaDestino completado."
    }
    catch {
        Add-Content $Logs "$(Get-Date): ERROR - Fallo al respaldar $RutaOrigen a $RutaDestino. Detalles: $_"
    }
}

function Realizar-Backup-servidor-remoto {
    param (
        [string]$RutaOrigen,
        [string]$ServidorDestino
    )

    $RutaDestinoRemota = Join-Path "\\$ServidorDestino\Backups" (Split-Path $RutaOrigen -Leaf)

    try {
        Copy-Item -Path $RutaOrigen -Destination $RutaDestinoRemota -Recurse -ErrorAction Stop
        Add-Content $Logs "$(Get-Date): ÉXITO - Respaldo de $RutaOrigen a $RutaDestinoRemota completado."
    }
    catch {
        Add-Content $Logs "$(Get-Date): ERROR - Fallo al respaldar $RutaOrigen a $RutaDestinoRemota. Detalles: $_"
        exit
    }
}