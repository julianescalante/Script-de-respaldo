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