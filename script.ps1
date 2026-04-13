<#
.SYNOPSIS
    Script interactivo de respaldo automático para Windows.

.DESCRIPTION
    Respalda las carpetas principales del perfil del usuario (Desktop, Documents)
    con opciones para incluir carpetas adicionales (Downloads, Music, Pictures, Videos)
    
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

# Función para obtener las rutas de las carpetas principales del usuario
function Get-UserFolders {
    $userProfile = [Environment]::GetFolderPath('UserProfile')
    return @{
        Desktop   = Join-Path $userProfile 'Desktop'
        Documents = Join-Path $userProfile 'Documents'
        Downloads = Join-Path $userProfile 'Downloads'
        Music     = Join-Path $userProfile 'Music'
        Pictures  = Join-Path $userProfile 'Pictures'
        Videos    = Join-Path $userProfile 'Videos'
    }
}

function Get-Answer {
    <#
    .SYNOPSIS
        Interacción con el usuario para filtrar carpetas de respaldo.
    .DESCRIPTION
        Recibe un Hashtable con las rutas de usuario y pregunta por cada carpeta adicional 
        si se desea incluir. Retorna un objeto con las rutas confirmadas.
    .INPUTS
        [Hashtable] Un diccionario con las rutas (Desktop, Documents, etc.)
    .OUTPUTS
        [PSCustomObject] Contiene la lista final de rutas a respaldar.
    #>
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Hashtable]$UserFolders
    )

    begin {
        Write-Host "`n--- Configuración de Alcance del Respaldo ---" -ForegroundColor Cyan
        $FinalPaths = @{}
        
        # Las carpetas principales siempre se incluyen por diseño del script
        $Principales = @('Desktop', 'Documents')
        $Adicionales = @('Downloads', 'Music', 'Pictures', 'Videos')
    }

    process {
        # 1. Agregar carpetas obligatorias
        foreach ($p in $Principales) {
            if ($UserFolders.ContainsKey($p)) {
                $FinalPaths[$p] = $UserFolders[$p]
            }
        }

        # 2. Preguntar por las adicionales
        foreach ($a in $Adicionales) {
            if ($UserFolders.ContainsKey($a)) {
                $choice = ""
                while ($choice -notmatch "^[SN]$") {
                    $choice = Read-Host "¿Desea incluir la carpeta de [$a]? (S/N)"
                    $choice = $choice.ToUpper()
                }

                if ($choice -eq 'S') {
                    $FinalPaths[$a] = $UserFolders[$a]
                }
            }
        }
    }

    end {
        Write-Host "Selección finalizada.`n" -ForegroundColor Green
        # Retornamos un objeto limpio para el siguiente eslabón del pipeline
        return [PSCustomObject]@{
            SelectedPaths = $FinalPaths
            TimeStamp     = Get-Date
            Count         = $FinalPaths.Count
        }
    }

    clean {
        # No se requieren limpiezas de recursos para esta interacción por consola
    }
}

# Esta función es un placeholder para la lógica de respaldo a un dispositivo de almacenamiento externo (Disco Duro, USB, etc etc). Deberá implementar la detección de unidades externas, manejo de rutas y la transferencia de archivos.
function Get-External-Backup {
    <#
    .SYNOPSIS
    EsTa función es un placeholder para la lógica de respaldo a un dispositivo de almacenamiento externo (Disco Duro, USB, etc etc). Deberá implementar la detección de unidades externas, manejo de rutas y la transferencia de archivos.
    .DESCRIPTION
    La funcion solo sirve para respaldar a un dispositivo de almacenamiento externo.
    Deberá implementar la detección de unidades externas, manejo de rutas y la transferencia de archivos.
    En caso de que el dispositivo externo no esté disponible o presente errores, la función deberá manejar estas situaciones y reportarlas adecuadamente.
    Se recomienda implementar una lógica para verificar el espacio disponible en el dispositivo antes de iniciar el respaldo.
    La función también puede incluir opciones para formatear el dispositivo si es necesario antes de realizar el respaldo.
    Es importante que la función maneje correctamente los permisos de escritura en el dispositivo externo para evitar fallos durante el proceso de respaldo.
    Se sugiere implementar un sistema de logs para registrar las acciones realizadas durante el respaldo a dispositivos externos, incluyendo errores y éxitos.
    La función debe ser capaz de manejar diferentes tipos de dispositivos externos, como discos duros, unidades USB, etc., y adaptarse a sus características específicas.
    En resumen, esta función es crucial para garantizar que los respaldos se realicen correctamente a dispositivos externos, proporcionando una solución confiable y eficiente para los usuarios que prefieren esta opción de almacenamiento.
    .INPUTS
    Rutas de las carpetas a respaldar y la información del dispositivo externo seleccionado. E:, F:, etc.
    (si se requiere información adicional para la conexión o autenticación, también se incluiría aquí)
    .OUTPUTS
    Resultados del proceso de respaldo, incluyendo información sobre los archivos respaldados, errores encontrados y estado final del proceso.
    Backup exitoso o fallido.
    Detalles específicos sobre el dispositivo externo utilizado para el respaldo, como su nombre, capacidad, espacio disponible, etc.
    Logs detallados de las acciones realizadas durante el proceso de respaldo a dispositivos externos, incluyendo cualquier error o éxito registrado.
    Información sobre la fecha y hora del respaldo realizado a dispositivos externos para fines de auditoría y seguimiento.
    En caso de errores, se podrían generar reportes específicos que detallen los problemas encontrados durante el proceso de respaldo a dispositivos externos, facilitando la resolución de problemas.
    Resumen final del proceso de respaldo a dispositivos externos, que incluya una visión general de los resultados obtenidos y cualquier recomendación para futuras ejecuciones.
    En caso de que se implementen opciones adicionales como formateo del dispositivo externo, también se podrían incluir detalles sobre estas acciones en los resultados y logs generados por la función.
    En resumen, los outputs de esta función deben proporcionar una visión completa y detallada del proceso de respaldo a dispositivos externos, permitiendo a los usuarios entender claramente los resultados obtenidos y cualquier acción adicional que pueda ser necesaria.
    .NOTES
    No maneja conexión a servidores remotos, solo dispositivos de almacenamiento externos.
    .COMPONENT
    El componente encargado de gestionar los respaldos a dispositivos externos dentro del script.
    .ROLE
    Respaldo a dispositivos externos.
    .FUNCTIONALITY
    Función encargada de realizar respaldos a dispositivos de almacenamiento externos, manejando la detección de unidades, transferencia de archivos, manejo de errores y generación de logs detallados sobre el proceso.
    #>

    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$BackupConfig,
        
        [Parameter(Mandatory = $true)] # Agregué Mandatory para asegurar que el script no falle sin ruta
        [string]$DevicePath
    )

    begin {
        $Resultados = @()
        Write-Host "Preparando respaldo a dispositivo externo [$DevicePath]..." -ForegroundColor Cyan
    }

    process {
        $Rutas = $BackupConfig.SelectedPaths
        $Cantidad = $BackupConfig.Count
        
        Write-Host "Iniciando respaldo a $DevicePath con $Cantidad carpetas seleccionadas..." -ForegroundColor Yellow
        
        if (-not [string]::IsNullOrWhiteSpace($DevicePath)) {
            
            # EL CAMBIO CLAVE: Robocopy debe ejecutarse PARA CADA carpeta seleccionada
            foreach ($Folder in $Rutas.Keys) {
                $Origen = $Rutas[$Folder]
                # Creamos el destino específico para esa carpeta (ej. E:\Backup_PC\Documents)
                $DestinoFinal = Join-Path $DevicePath "Backup_$($env:COMPUTERNAME)\$Folder"

                Write-Host "Copiando: $Folder..." -ForegroundColor Gray

                # Definimos los parámetros específicos para este par Origen/Destino
                $Params = @($Origen, $DestinoFinal, "/E", "/Z", "/R:3", "/W:5", "/MT:8", "/XJD", "/XJF")
                # Glosario de parámetros:
                # /E: Copia subdirectorios, incluyendo vacíos.
                # /Z: Modo reiniciable, permite reanudar la copia en caso de interrupciones.
                # /R:3: Reintenta 3 veces en caso de error.
                # /W:5: Espera 5 segundos entre reintentos.
                # /MT:8: Utiliza 8 hilos para la copia.
                # /XJD: Omite directorios junction.
                # /XJF: Omite archivos junction.
                # Ejecutamos robocopy
                & robocopy @Params

                # Capturamos el resultado de esta carpeta específica
                $LastExit = $LASTEXITCODE
                $Resultados += [PSCustomObject]@{
                    Carpeta  = $Folder
                    Ruta     = $Origen
                    ExitCode = $LastExit
                    Status   = if ($LastExit -le 8) { "Éxito" } else { "Error Crítico" }
                }
            }
                
        }
        else {
            Write-Host "No se ha especificado un dispositivo externo válido. Respaldo cancelado." -ForegroundColor Red
        }
    }

    end {
        Write-Host "`nRespaldo a dispositivo externo [$DevicePath] finalizado." -ForegroundColor Green
        return $Resultados
    }

    clean {
        # Nota: En Clean, $Resultados y $BackupConfig siguen disponibles.
        Write-Host "Sesión de respaldo cerrada." -ForegroundColor Cyan
        # Una pequeña validación para evitar errores si el backup no inició
        if ($Resultados) {
            Write-Host "Se procesaron $($Resultados.Count) de $Cantidad carpetas seleccionadas." -ForegroundColor Green
        }
    }
}
#EsTa función es un placeholder para la lógica de respaldo a un destino remoto. Deberá implementar la conexión al servidor via IP, manejo de rutas UNC y la transferencia de archivos. En caso de que la carpeta del servidor pida autenticación, el servidor pedirá credenciales.
function Get-Remote-Backup {
    <#
    .SYNOPSIS
    Esta función es un placeholder para la lógica de respaldo a un destino remoto. Deberá implementar la conexión al servidor via IP, manejo de rutas UNC y la transferencia de archivos. En caso de que la carpeta del servidor pida autenticación, el servidor pedirá credenciales.       
    .DESCRIPTION
    Función que recibe una dirección IP del servidor remoto y las rutas de las carpetas a respaldar. Implementa la lógica para establecer una conexión con el servidor, manejar rutas UNC y transferir los archivos seleccionados. En caso de que el servidor requiera autenticación, la función solicitará las credenciales necesarias para acceder al destino remoto. Además, se recomienda implementar una lógica para verificar la disponibilidad del servidor antes de iniciar el proceso de respaldo y manejar adecuadamente cualquier error que pueda surgir durante la conexión o transferencia de archivos.
    .INPUTS
    Dirección IP del servidor remoto y las rutas de las carpetas a respaldar. (si se requiere información adicional para la conexión o autenticación, también se incluiría aquí)
    .OUTPUTS
    Resultados del proceso de respaldo, incluyendo información sobre los archivos respaldados, errores encontrados y estado final del proceso.
    Backup exitoso o fallido.
    .NOTES
    No maneja respaldos a dispositivos externos, solo destinos remotos hacia un servidor por medio de una IP.
    .COMPONENT
    El componente encargado de gestionar los respaldos a destinos remotos dentro del script.
    .ROLE
    Respaldo a destinos remotos por IP.
    .FUNCTIONALITY
    Función encargada de realizar respaldos a destinos remotos por IP, manejando la conexión al servidor, transferencia de archivos, manejo de errores y generación de logs detallados sobre el proceso.
    #>
    
   param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$BackupConfig,
            
        [Parameter(Mandatory = $true)]
        [string]$ServerIP
    )

    begin {
        $Resultados = @()
        Write-Host "--- Iniciando Validación de Red ---" -ForegroundColor Cyan
        
        # Verificar si el servidor responde al ping
        if (-not (Test-Connection -ComputerName $ServerIP -Count 1 -Quiet)) {
            Write-Error "El servidor remoto [$ServerIP] no responde. Abortando proceso remoto." -ForegroundColor Red
            return # Detiene la ejecución en este pipeline
        }
        Write-Host "Servidor [$ServerIP] en línea. Preparando transferencia con $Cantidad carpetas..." -ForegroundColor Green
    }

    process {
        $Rutas = $BackupConfig.SelectedPaths
        $Cantidad = $BackupConfig.Count

        # Definimos la ruta base UNC. 
        # Nota: Usamos el recurso compartido 'C$' por defecto, o podrías pedir una carpeta compartida específica.
        $RemoteRoot = "\\$ServerIP\C$\Backups_Remote\$($env:COMPUTERNAME)"

        foreach ($Folder in $Rutas.Keys) {
            $Origen = $Rutas[$Folder]
            $DestinoRemoto = Join-Path $RemoteRoot $Folder

            Write-Host "Transfiriendo [$Folder] a destino remoto..." -ForegroundColor Yellow

            # Parámetros óptimos para red:
            # /IPG:5 : Inter-Packet Gap (opcional, ayuda en redes muy lentas para no saturar)
            # /NP    : No Progress (oculta el porcentaje, acelera un poco el proceso en red)
            $Params = @($Origen, $DestinoRemoto, "/E", "/Z", "/R:5", "/W:10", "/MT:16", "/NP", "/XJD", "/XJF", "/IPG:5")
            
            & robocopy @Params

            $LastExit = $LASTEXITCODE
            $Resultados += [PSCustomObject]@{
                Carpeta     = $Folder
                Servidor    = $ServerIP
                RutaUNC     = $DestinoRemoto
                ExitCode    = $LastExit
                Status      = if ($LastExit -le 8) { "Éxito" } else { "Error de Red/Permisos" }
            }
        }
    }

    end {
        Write-Host "Respaldo remoto a [$ServerIP] finalizado." -ForegroundColor Green
        return $Resultados
    }

    clean {
        Write-Host "Conexión con [$ServerIP] cerrada." -ForegroundColor Cyan
    }
}

# Esta función es un placeholder para la generación del resumen detallado al finalizar el proceso de respaldo. Deberá implementar la recopilación de información sobre los archivos respaldados, errores encontrados y generar un reporte legible para el usuario.
function Get-Backup-Summary {
    <#
    .SYNOPSIS
    Esta función es un placeholder para la generación del resumen detallado al finalizar el proceso de respaldo. Deberá implementar la recopilación de información sobre los archivos respaldados, errores encontrados y generar un reporte legible para el usuario.
    .DESCRIPTION
    Función encargada de recopilar toda la información relevante al proceso de respaldo, incluyendo detalles sobre los archivos respaldados, errores encontrados y el estado final del proceso. Esta función debe generar un reporte legible para el usuario, que resuma de manera clara y concisa los resultados del respaldo, permitiendo a los usuarios entender fácilmente qué se respaldó, qué errores ocurrieron (si los hubo) y cuál fue el resultado final del proceso.
    .INPUTS
    Placeholder de las funciones de backup remoto y externo
    .OUTPUTS
    Archivo .log o .txt con el resumen detallado del proceso de respaldo, incluyendo información sobre los archivos respaldados, errores encontrados y estado final del proceso. Resumen legible para el usuario que permita entender claramente los resultados del respaldo.
    .NOTES
    Esta función es crucial para proporcionar a los usuarios una visión clara y detallada de los resultados del proceso de respaldo, facilitando la comprensión de lo que se respaldó, los errores encontrados y el estado final del proceso.
    .COMPONENT
    El componente encargado de generar el resumen detallado al finalizar el proceso de respaldo dentro del script.
    .ROLE
    Generación de resumen detallado del proceso de respaldo.
    .FUNCTIONALITY
    Función encargada de recopilar información sobre los archivos respaldados, errores encontrados y generar un reporte legible para el usuario al finalizar el proceso de respaldo, proporcionando una visión clara y detallada de los resultados obtenidos.
    #>
   param (
        # Recibe los objetos [PSCustomObject] creados en las funciones de respaldo
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject[]]$ResultadosDetallados
   )

    begin {
        Write-Host "`n--- Generando Resumen del Respaldo ---" -ForegroundColor Cyan
        $LogPath = ".\Backup_Summary_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        
        # Iniciamos el registro de todo lo que salga en consola hacia el archivo
        Start-Transcript -Path $LogPath -NoClobber
        
        Write-Host "================================================"
        Write-Host "RESUMEN DE RESPALDO - EQUIPO: $($env:COMPUTERNAME)"
        Write-Host "FECHA: $(Get-Date)"
        Write-Host "================================================"
    }

    process {
        # Como los resultados vienen del pipeline, los procesamos
        foreach ($Item in $ResultadosDetallados) {
            $Color = if ($Item.Status -eq "Éxito") { "Green" } else { "Red" }
            
            Write-Host "Carpeta: $($Item.Carpeta)" -ForegroundColor Yellow
            Write-Host " > Estado: $($Item.Status)" -ForegroundColor $Color
            Write-Host " > Código de Salida (Robocopy): $($Item.ExitCode)"
            Write-Host "------------------------------------------------"
        }
    }

    end {
        # Cálculo de estadísticas finales
        $Total = $ResultadosDetallados.Count
        $Exitos = ($ResultadosDetallados | Where-Object { $_.Status -eq "Éxito" }).Count
        $Errores = $Total - $Exitos

        Write-Host "`nESTADO FINAL DEL PROCESO:" -ForegroundColor Cyan
        Write-Host "Total procesado: $Total"
        Write-Host "Exitosos: $Exitos" -ForegroundColor Green
        Write-Host "Errores: $Errores" -ForegroundColor Red
        
        if ($Errores -gt 0) {
            Write-Host "AVISO: Se detectaron problemas en algunas carpetas. Revise los códigos de salida." -ForegroundColor Magenta
        }

        Stop-Transcript
        Write-Host "`nReporte guardado en: $LogPath" -ForegroundColor Gray
        if (Test-Path $LogPath) {
            return Get-Item $LogPath
        }
    }

    clean {
        # El bloque clean es ideal para asegurar que el transcript se detenga si algo falla
        if ($null -ne (Get-Transcript)) { Stop-Transcript }
    }
}

# Esta función se encarga de respaldar archivos y carpetas que han sido modificadas o su fecha de modificación es posterior a la fecha del último respaldo. Deberá implementar la lógica para comparar fechas de modificación y realizar el respaldo incremental.
function Get-Incremental-Backup {
    <#
    .SYNOPSIS
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .INPUTS
    Inputs to this cmdlet (if any)
    .OUTPUTS
    Output from this cmdlet (if any)
    .NOTES
    General notes
    .COMPONENT
    The component this cmdlet belongs to
    .ROLE
    The role this cmdlet belongs to
    .FUNCTIONALITY
    The functionality that best describes this cmdlet
    #>
    param ()

    begin {
        #BeginCodeHere
    }

    process { }

    end {
        #EndCodeHere
    }

    clean {
        #CleanCodeHere - Added in 7.3 for more information see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods?view=powershell-7.5#clean
    } 
}

# Función principal para ejecutar el proceso de respaldo, es el Main Funtion
function Get-Execution {
    <#
    .SYNOPSIS
    Function principal para ejecutar el proceso de respaldo
    .DESCRIPTION
    Esta función orquesta el proceso completo de respaldo, desde la selección de carpetas, elección del destino, ejecución del respaldo y generación del resumen final.
    .INPUTS
    Función sin parámetros de entrada, se basa en la interacción con el usuario y la lógica interna para determinar las rutas y destinos.
    .OUTPUTS
    Resumen detallado del proceso de respaldo, incluyendo información sobre los archivos respaldados, errores encontrados y estado final del proceso.
    Backup exitoso o fallido.
    .NOTES
    Esta función es el punto de entrada para el proceso de respaldo. Se recomienda ejecutar esta función para iniciar el proceso completo.
    .COMPONENT
    El componente principal del script de respaldo automático.
    .ROLE
    Orquestador del proceso de respaldo.
    .FUNCTIONALITY
    Función principal para ejecutar el proceso de respaldo, incluyendo selección de carpetas, elección de destino, ejecución del respaldo y generación de resumen.
    #>

    begin {
        #BeginCodeHere
    }

    process {
        
    }

    end {
        #EndCodeHere
    }

    clean {
    }
}