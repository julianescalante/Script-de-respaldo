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

# Función para obtener las rutas de las carpetas principales del usuario
function Get-UserFolders {
    $userProfile = [Environment]::GetFolderPath('UserProfile')
    return @{
        Desktop   = Join-Path $userProfile 'Desktop'
        Documents = Join-Path $userProfile 'Documents'
        Downloads = Join-Path $userProfile 'Downloads'
        Music     = Join-Path $userProfile 'Music'
        Pictures   = Join-Path $userProfile 'Pictures'
        Videos    = Join-Path $userProfile 'Videos'
    }
}

# Esta función es para saber si el usuario desea incluir las carpetas adicionales (Downloads, Music, Pictures, Videos) en el respaldo. Deberá implementar la lógica de interacción con el usuario para obtener esta información.
function Get-Answer {
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
    param (
       
    )

    begin {
        #BeginCodeHere
    }

    process {
        
    }

    end {
        #EndCodeHere
    }

    clean {
        #CleanCodeHere - Added in 7.3 for more information see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods?view=powershell-7.5#clean
    }
}

# Esta función es un placeholder para la lógica de respaldo a un dispositivo de almacenamiento externo (Disco Duro, USB, etc etc). Deberá implementar la detección de unidades externas, manejo de rutas y la transferencia de archivos.
function Get-External-Backup {
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

    param (
    
    )

    begin {
        #BeginCodeHere
    }

    process {
        
    }

    end {
        #EndCodeHere
    }

    clean {
        #CleanCodeHere - Added in 7.3 for more information see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods?view=powershell-7.5#clean
    }
}
#EsTa función es un placeholder para la lógica de respaldo a un destino remoto. Deberá implementar la conexión al servidor via IP, manejo de rutas UNC y la transferencia de archivos. En caso de que la carpeta del servidor pida autenticación, el servidor pedirá credenciales.
function Get-Remote-Backup {
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
    
    param (
    
    )

    begin {
        #BeginCodeHere
    }

    process {
        
    }

    end {
        #EndCodeHere
    }

    clean {
        #CleanCodeHere - Added in 7.3 for more information see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods?view=powershell-7.5#clean
    }
}

# Esta función es un placeholder para la generación del resumen detallado al finalizar el proceso de respaldo. Deberá implementar la recopilación de información sobre los archivos respaldados, errores encontrados y generar un reporte legible para el usuario.
function Get-Backup-Summary {
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
    param (
       
    )

    begin {
        #BeginCodeHere
    }

    process {
       
    }

    end {
        #EndCodeHere
    }

    clean {
        #CleanCodeHere - Added in 7.3 for more information see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods?view=powershell-7.5#clean
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

# Función principal para ejecutar el proceso de respaldo
function Get-Execution {
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

    process {
        
    }

    end {
        #EndCodeHere
    }

    clean {
        #CleanCodeHere - Added in 7.3 for more information see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods?view=powershell-7.5#clean
    }
}