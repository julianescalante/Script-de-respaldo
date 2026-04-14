# Sistema de Respaldo Automatizado con PowerShell y Robocopy

## 📌 Descripción
Este script en PowerShell permite realizar respaldos automáticos de las carpetas de usuario hacia destinos **locales (USB/disco externo)** o **remotos (servidor vía IP)**.  
Utiliza **Robocopy** para garantizar transferencias eficientes, maneja errores y genera un **log detallado** de cada ejecución.

---

## 🚀 Características
- Detección automática de carpetas de usuario: Escritorio, Documentos, Descargas, Música, Imágenes y Videos.
- Inclusión obligatoria de **Escritorio** y **Documentos** en el respaldo.
- Inclusión opcional de otras carpetas mediante interacción con el usuario.
- Respaldo hacia:
  - **Dispositivo externo (USB/disco)**.
  - **Servidor remoto vía IP**.
- Reporte final con estado de cada carpeta respaldada.
- Generación automática de **logs** con fecha y nombre del equipo.
- Manejo de errores críticos y mensajes en consola con colores.

---

## 📂 Estructura del Script
1. **Get-UserFolders** → Obtiene rutas de carpetas de usuario.
2. **Get-Answer** → Interacción con el usuario para seleccionar carpetas.
3. **Get-External-Backup** → Copia hacia dispositivos externos.
4. **Get-Remote-Backup** → Copia hacia servidor remoto.
5. **Get-Backup-Summary** → Genera resumen y log de respaldo.
6. **Get-Execution** → Función orquestadora que guía todo el proceso.

---

## 🛠️ Requisitos
- **Windows PowerShell 5.1** o superior.
- **Robocopy** (incluido por defecto en Windows).
- Permisos de escritura en el destino.
- Acceso de red al servidor remoto (si aplica).

---

## ▶️ Uso
1. Ejecuta el script en PowerShell:
   ```powershell
   .\BackupScript.ps1
   ```
2. Selecciona el tipo de respaldo:
    - E → Externo (USB/disco).

    - R → Remoto (Servidor IP).
3. Ingresa la letra de unidad (ejemplo: F:\) o la IP del servidor.
4. El script solicitará confirmación para incluir carpetas opcionales.
5. Al finalizar, se abrirá automáticamente el log en Notepad.

## 📑 Ejemplo de Ejecución
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
Carpeta: Desktop - Status: Éxito (Code: 0)
Carpeta: Documents - Status: Éxito (Code: 0)
Carpeta: Downloads - Status: Éxito (Code: 0)

PROCESO TERMINADO.
El log se abrirá a continuación...
```

## ⚠️ Notas
- Los códigos de salida de Robocopy menores a 8 se consideran éxito.
- El log se guarda en la misma carpeta del script con el formato:
```txt
Backup_Log_<NombrePC>_yyyyMMdd_HHmm.log
```
- En caso de error crítico, se mostrará en consola en color rojo.

## Licencia

© 2026 Plan B Technologies. Todos los derechos reservados. 

No se permite la reproducción, distribución o modificación de este software, ni de ninguna de sus partes, sin el permiso previo y por escrito del propietario.

