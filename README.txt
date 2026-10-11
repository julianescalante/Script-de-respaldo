# Sistema de Respaldo Automatizado con PowerShell y Robocopy

## Descripción

Este script de PowerShell automatiza la copia de seguridad de las carpetas de usuario hacia destinos locales (unidades USB o discos externos) o de red (servidores vía IP).

Aprovecha la potencia de **Robocopy** como motor de copia multihilo para lograr transferencias eficientes, manejar interrupciones y generar logs detallados de cada ejecución.

---

## Características Principales

* **Detección de carpetas de usuario:** Identifica automáticamente las rutas del sistema para Escritorio, Documentos, Descargas, Música, Imágenes y Videos.
* **Criterios de inclusión:**
* **Obligatorios:** *Escritorio* y *Documentos* se incluyen siempre por defecto.
* **Opcionales:** El script pregunta de forma interactiva si deseas sumar carpetas adicionales.


* **Destinos soportados:**
* Dispositivo externo (unidad USB o disco duro secundario).
* Servidor remoto mediante ruta de red / IP.


* **Tolerancia a fallos e interfaz:** Manejo visual de excepciones en consola mediante códigos de color (éxito, advertencia, error) y validación de permisos.
* **Trazabilidad y auditoría:** Generación automática de logs detallados etiquetados con la fecha y el nombre del equipo.

---

## Arquitectura y Funciones del Script

El script se divide en los siguientes módulos funcionales:

* `Get-UserFolders`: Detecta y extrae las rutas reales de las carpetas del perfil de usuario activo.
* `Get-Answer`: Captura y valida las respuestas del usuario durante el flujo interactivo.
* `Get-External-Backup`: Gestiona la lógica de copia y montaje hacia unidades locales/extraíbles.
* `Get-Remote-Backup`: Maneja la autenticación y transferencia hacia recursos compartidos en red.
* `Get-Backup-Summary`: Procesa los códigos de salida de Robocopy, compila el reporte final y escribe el archivo de log.
* `Get-Execution`: Función orquestadora que controla el ciclo de vida completo de la ejecución.

---

## Requisitos del Sistema

* **SO:** Windows 7/10/11 o Windows Server.
* **Entorno de ejecución:** Windows PowerShell 5.1 o superior.
* **Herramientas de copia:** Robocopy (incluido de forma nativa en el sistema).
* **Permisos:** Privilegios de lectura en el origen y permisos de escritura en la ruta de destino.
* **Conectividad:** Acceso por puerto SMB (445) habilitado si se realiza copia en red.

---

## Guía de Uso

1. **Ejecución del Script**
Abre PowerShell y ejecuta la función principal:
```powershell
.\BackupScript.ps1

```


2. **Selección del Modo de Respaldo**
* Elige `E` para guardar en un almacenamiento local (USB, disco externo).
* Elige `R` para transferir hacia un servidor remoto mediante IP o ruta UNC.


3. **Ingreso de Ruta Destino**
Introduce la letra de la unidad (ej. `F:\`) o la dirección IP/ruta del servidor de destino.
4. **Confirmación Interactiva**
Confirma qué carpetas adicionales deseas incluir además de *Escritorio* y *Documentos*.
5. **Finalización y Apertura de Log**
El proceso mostrará el avance en pantalla y, al terminar, abrirá automáticamente el log resultante en Notepad.

---

## Ejemplo de Flujo en Consola

```txt
==========================================
    SISTEMA DE RESPALDO AUTOMATIZADO
==========================================

¿Tipo de respaldo? (E)xterno USB / (R)emoto Servidor: E
Ingrese letra de unidad (ej: F:\): F:\

[MANDATORIO] Incluyendo Desktop
[MANDATORIO] Incluyendo Documents
¿Desea incluir la carpeta de [Downloads]? (S/N): S

 > Copiando Desktop... [Éxito]
 > Copiando Documents... [Éxito]
 > Copiando Downloads... [Éxito]

=== RESUMEN FINAL ===
Carpeta: Desktop   - Status: Éxito (Code: 0)
Carpeta: Documents - Status: Éxito (Code: 0)
Carpeta: Downloads - Status: Éxito (Code: 0)

PROCESO TERMINADO.
El log se abrirá a continuación...

```

---

## Consideraciones Técnicas

* **Códigos de Salida de Robocopy:** El script interpreta los Return Codes (Exit Codes) nativos de Robocopy. Cualquier valor **menor a 8** indica que la copia se completó correctamente (con o sin archivos omitidos por falta de cambios).
* **Formato del Log:** Los reportes se almacenan en el mismo directorio desde donde se ejecuta el script bajo la convención:
```txt
Backup_Log_<NombrePC>_yyyyMMdd_HHmm.log

```


* **Manejo de Errores Críticos:** Si ocurre un fallo en el acceso a la red o el disco de destino se desconecta, el script aborta la operación de forma segura y despliega el error en consola en color rojo.

---

## Licencia

© 2026 Julián Escalante. Todos los derechos reservados.

Queda estrictamente prohibida la reproducción, distribución o modificación de este software, total o parcialmente, sin la autorización previa y por escrito del titular de los derechos.
