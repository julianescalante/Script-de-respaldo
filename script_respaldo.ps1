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

function Ask-YesNo {
    <#
    .SYNOPSIS
        Solicita una respuesta Sí/No al usuario con validación en bucle.
    .PARAMETER Message
        Mensaje a mostrar al usuario en el prompt.
    .PARAMETER Default
        Opción por defecto si el usuario presiona ENTER sin escribir ('S' o 'N').
    .OUTPUTS
        Boolean: $true para 'S', $false para 'N'
    .NOTES
        Los caracteres en minúsculas y mayúsculas se tratan como equivalentes.
        El usuario debe responder hasta que ingrese una opción válida.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet('S', 'N')]
        [string]$Default = 'S'
    )

    while ($true) {
        # Construir texto de opción por defecto para mostrar al usuario
        $defaultText = if ($Default -eq 'S') { '[S/n]' } else { '[s/N]' }
        $answer = Read-Host "$Message $defaultText"

        # Si el usuario presiona ENTER sin escribir, usar el valor por defecto
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $Default -eq 'S'
        }

        # Validar y convertir respuesta a booleano
        switch ($answer.Trim().ToLower()) {
            's' { return $true }
            'n' { return $false }
            default { Write-Host 'Respuesta no válida. Responda S o N.' -ForegroundColor Yellow }
        }
    }
}

function Get-AdditionalVolumes {
    <#
    .SYNOPSIS
        Detecta y retorna discos adicionales (excluyendo C:) con la opción de selección del usuario.
    .DESCRIPTION
        Obtiene todos los discos lógicos que no sean la unidad del sistema (C:)
        y permite al usuario elegir cuáles desea incluir en el respaldo.
    .OUTPUTS
        String[]: Array de rutas de discos seleccionados (ej: 'D:\', 'E:\')
    .NOTES
        Solo incluye unidades de tipo local (DriveType 2) y de red (DriveType 3).
        Se solicita confirmación para cada disco encontrado.
    #>
    # Obtener todos los discos lógicos excepto C: (unidad de sistema)
    $volumes = Get-CimInstance -ClassName Win32_LogicalDisk |
        Where-Object {
            $_.DeviceID -ne 'C:' -and ($_.DriveType -in 2, 3)
        }

    $selected = @()
    # Iterar discos y permitir al usuario elegir cuáles respaldar
    foreach ($volume in $volumes) {
        $displayName = "$($volume.DeviceID) - $($volume.VolumeName)"
        if (Ask-YesNo "¿Incluir el disco adicional $displayName?" 'N') {
            $selected += $volume.DeviceID + '\'
        }
    }

    return $selected
}

function Resolve-BackupDestination {
    <#
    .SYNOPSIS
        Valida y prepara la ruta de destino del respaldo.
    .DESCRIPTION
        Verifica que la ruta de destino exista, intenta crearla si no existe,
        y retorna la ruta completa normalizada.
    .PARAMETER DestinationPath
        Ruta local o red del destino del respaldo (ej: 'E:\Backups' o '\\servidor\compartida').
    .OUTPUTS
        String: Ruta completa normalizada del destino.
    .THROWS
        Excepción si no se puede acceder a la ruta ni crearla.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    # Manejar rutas UNC (red) y locales de manera diferente
    if ($DestinationPath -like '\\*') {
        # Para rutas de red, verificar acceso sin intentar crear el recurso compartido
        if (-not (Test-Path -Path $DestinationPath)) {
            throw "No se puede acceder al destino de red: $DestinationPath. Verifique que el recurso compartido exista y sea accesible."
        }
    } else {
        # Para rutas locales, intentar crear si no existe
        if (-not (Test-Path -Path $DestinationPath)) {
            try {
                New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
            } catch {
                throw "No se puede crear o acceder al destino: $DestinationPath. Detalle: $($_.Exception.Message)"
            }
        }
    }

    # Verificar permisos de escritura creando un archivo de prueba
    try {
        $testFile = Join-Path -Path $DestinationPath -ChildPath 'test.tmp'
        New-Item -Path $testFile -ItemType File -Force | Out-Null
        Remove-Item -Path $testFile -Force
    } catch {
        throw "No se puede escribir en el destino: $DestinationPath. Detalle: $($_.Exception.Message)"
    }

    # Retornar la ruta normalizada y completa del sistema de archivos
    return (Get-Item -Path $DestinationPath).FullName
}

function Get-BackupDestination {
    <#
    .SYNOPSIS
        Permite al usuario elegir el destino del respaldo (remoto o local).
    .DESCRIPTION
        Presenta un menú interactivo para que el usuario seleccione entre:
        1) Servidor remoto por dirección IP (ruta UNC)
        2) Almacenamiento externo local (ruta local)
        Valida la entrada y retorna la ruta preparada.
    .OUTPUTS
        String: Ruta validada y normalizada del destino del respaldo.
    #>
    Write-Host "Destino del backup:" -ForegroundColor Cyan
    Write-Host "1) Servidor remoto mediante dirección IP"
    Write-Host "2) Almacenamiento externo local"

    while ($true) {
        $option = Read-Host 'Elija 1 o 2'
        switch ($option.Trim()) {
            '1' {
                # Opción 1: Destino remoto mediante IP
                $serverIp = Read-Host 'Ingrese la IP del servidor remoto'
                if ([string]::IsNullOrWhiteSpace($serverIp)) {
                    Write-Host 'Se requiere una IP válida.' -ForegroundColor Yellow
                    continue
                }

                # Validar formato de IP
                if (-not [System.Net.IPAddress]::TryParse($serverIp, [ref]$null)) {
                    Write-Host 'La dirección IP no es válida. Intente nuevamente.' -ForegroundColor Yellow
                    continue
                }

                # Nombre de carpeta compartida en el servidor (respaldo por defecto)
                $shareName = Read-Host 'Ingrese el nombre de la carpeta compartida en el servidor (por defecto Backup)'
                if ([string]::IsNullOrWhiteSpace($shareName)) {
                    $shareName = 'Backup'
                }

                # Construir ruta UNC (\\servidor\compartida)
                $remotePath = "\\$serverIp\$shareName"
                return Resolve-BackupDestination -DestinationPath $remotePath
            }
            '2' {
                # Opción 2: Destino local
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
    <#
    .SYNOPSIS
        Copia una carpeta o disco completo a la carpeta de respaldo.
    .DESCRIPTION
        Resuelve la ruta de origen, determina el nombre de destino y copia recursivamente
        el contenido. Maneja tanto carpetas individuales como discos completos.
    .PARAMETER SourcePath
        Ruta de origen a respaldar (carpeta o disco).
    .PARAMETER BackupRoot
        Ruta raíz donde se creará la carpeta de destino.
    .OUTPUTS
        Boolean: $true si la copia fue exitosa, $false en caso de error.
    .NOTES
        - Para discos completos (ej: 'D:\'), copia todo el contenido bajo la letra del disco.
        - Para carpetas, usa el nombre final de la carpeta como destino.
        - Los errores se capturan y advierten sin detener el proceso general.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )

    try {
        # Resolver la ruta de origen a su forma completa
        $resolvedSource = (Resolve-Path -Path $SourcePath).ProviderPath
    } catch {
        Write-Warning "No se encontró la ruta de origen: $SourcePath"
        return $false
    }

    # Lógica especial para discos completos: detectar si la ruta es 'X:\'
    if ($resolvedSource -match '^[A-Za-z]:\\$') {
        # Es un disco completo: usar la letra del disco como nombre destino
        $targetName = $resolvedSource.Substring(0, 1)
        $copySource = Join-Path -Path $resolvedSource -ChildPath '*'
    } else {
        # Es una carpeta regular: usar el nombre final de la carpeta
        $targetName = Split-Path -Path $resolvedSource -Leaf
        $copySource = $resolvedSource
    }

    # Crear la carpeta de destino dentro de la raíz de respaldo
    $destination = Join-Path -Path $BackupRoot -ChildPath $targetName
    New-Item -Path $destination -ItemType Directory -Force | Out-Null

    try {
        # Copiar recursivamente: -Force sobrescribe si existe, -Recurse para subdirectorios
        # Excluir archivos del sistema comunes para evitar copias innecesarias
        $excludeFiles = @('pagefile.sys', 'hiberfil.sys', 'swapfile.sys', 'DumpStack.log.tmp')
        Copy-Item -Path $copySource -Destination $destination -Recurse -Force -Exclude $excludeFiles -ErrorAction Stop
        return $true
    } catch {
        # Registrar error pero no detener el script completo
        Write-Warning "Error copiando '$resolvedSource' a '$destination': $($_.Exception.Message)"
        return $false
    }
}

function Write-BackupSummary {
    <#
    .SYNOPSIS
        Escribe el resumen del respaldo en un archivo de texto UTF-8.
    .DESCRIPTION
        Guardar un archivo de resumen permite auditar qué se respaldeó, cuándo,
        y qué errores ocurrieron. Útil para validación y recuperación posterior.
    .PARAMETER SummaryPath
        Ruta completa donde se guardará el archivo de resumen.
    .PARAMETER Lines
        Array de strings, cada uno será una línea en el archivo de resumen.
    .NOTES
        Se usa codificación UTF-8 para compatibilidad internacional de caracteres.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SummaryPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    # Escribir líneas en el archivo con codificación UTF-8
    $Lines | Set-Content -Path $SummaryPath -Encoding UTF8
}

# ========================================
# Sección: CONFIGURACIÓN E INICIALIZACIÓN
# ========================================
# Este bloque prepara el entorno y define los elementos a respaldar

# Obtener información del equipo y usuario actual
$computerName = $env:COMPUTERNAME
$userProfile = [Environment]::GetFolderPath('UserProfile')

# Definir carpetas REQUERIDAS obligatorias para el respaldo
# (Escritorio y Documentos se incluyen siempre)
$backupItems = @(
    [PSCustomObject]@{ Name = 'Escritorio'; Path = Join-Path $userProfile 'Desktop'; Required = $true },
    [PSCustomObject]@{ Name = 'Documentos'; Path = Join-Path $userProfile 'Documents'; Required = $true }
)

# Definir carpetas OPCIONALES que se ofrecerán al usuario
# Solo se agregan si existen en el sistema y el usuario las selecciona
$optionalFolders = @(
    [PSCustomObject]@{ Name = 'Descargas'; Path = Join-Path $userProfile 'Downloads' },
    [PSCustomObject]@{ Name = 'Música'; Path = Join-Path $userProfile 'Music' },
    [PSCustomObject]@{ Name = 'Imágenes'; Path = Join-Path $userProfile 'Pictures' },
    [PSCustomObject]@{ Name = 'Videos'; Path = Join-Path $userProfile 'Videos' }
)

# Permitir al usuario seleccionar carpetas opcionales que existan
foreach ($folder in $optionalFolders) {
    if (Test-Path -Path $folder.Path -PathType Container) {
        if (Ask-YesNo "¿Desea respaldar '$($folder.Name)'?" 'N') {
            $backupItems += [PSCustomObject]@{ Name = $folder.Name; Path = $folder.Path; Required = $false }
        }
    }
}

# Detectar discos adicionales (si existen) y permitir selección
$extraVolumes = Get-AdditionalVolumes

# ========================================
# Sección: SELECCIÓN DE DESTINO
# ========================================
Write-Host "\nSeleccionando destino del respaldo..." -ForegroundColor Cyan
$backupDestination = Get-BackupDestination

# Crear estructura de carpetas: raíz del respaldo / nombre del equipo
# Esto permite organizar respaldos de múltiples equipos en el mismo servidor
$backupRoot = Join-Path -Path $backupDestination -ChildPath $computerName
New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null

# Definir rutas de archivos informativos del respaldo
$summaryPath = Join-Path -Path $backupRoot -ChildPath 'BackupSummary.txt'
$logPath = Join-Path -Path $backupRoot -ChildPath 'ComputerName.txt'

# Crear archivo con información del equipo y usuario que ejecutó el respaldo
# Útil para auditoría y validación posterior
Write-BackupSummary -SummaryPath $logPath -Lines @(
    "Equipo: $computerName",
    "Usuario: $env:USERNAME",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
)

# Inicializar array de resumen con encabezados y información general
$summaryLines = @(
    "Resumen de respaldo",
    "===================",
    "Equipo: $computerName",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Destino: $backupRoot",
    ''
)

# ========================================
# Sección: EJECUCIÓN DEL RESPALDO
# ========================================
Write-Host "\nIniciando respaldo en: $backupRoot" -ForegroundColor Green

# Contadores para tracking de éxitos y errores
$completed = 0
$failed = 0

# Procesar todas las carpetas de usuario seleccionadas
foreach ($item in $backupItems) {
    if (-not (Test-Path -Path $item.Path -PathType Container)) {
        # Advertencia si la carpeta no existe (puede ocurrir en algunos sistemas)
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

# Procesar discos adicionales (si el usuario los seleccionó)
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

# ========================================
# Sección: GENERACIÓN DE REPORTE FINAL
# ========================================
# Agregar estadísticas de resultado al resumen
$summaryLines += ''
$summaryLines += "Carpetas copiadas: $completed"
$summaryLines += "Errores: $failed"

# Guardar el resumen del respaldo para auditoría
Write-BackupSummary -SummaryPath $summaryPath -Lines $summaryLines

Write-Host "\nRespaldo finalizado." -ForegroundColor Green
Write-Host "Resumen guardado en: $summaryPath"
if ($failed -gt 0) {
    # Alertar al usuario si hubo errores durante el respaldo
    Write-Host "Algunas carpetas no se pudieron copiar. Revise el archivo de resumen." -ForegroundColor Yellow
} else {
    # Confirmación de éxito si todo se copió sin problemas
    Write-Host "Copia completada sin errores." -ForegroundColor Green
}

# Mantener la ventana abierta para que el usuario vea el resultado final
Read-Host -Prompt 'Presione ENTER para finalizar'
