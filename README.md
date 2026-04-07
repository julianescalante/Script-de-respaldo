# Script de Respaldo

Este script PowerShell está diseñado para realizar copias de seguridad de las carpetas principales de un equipo con Windows. Permite respaldar los archivos de forma interactiva y elegir entre un servidor remoto o un almacenamiento externo.

## Funcionalidades

- Respaldar automáticamente las carpetas:
  - Documentos
  - Escritorio (obligatorio)
- Preguntar si se desea respaldar las carpetas opcionales:
  - Descargas
  - Música
  - Imágenes
  - Videos
- Detectar y preguntar por discos adicionales disponibles (por ejemplo: D:, E:, F:) para incluirlos en el respaldo.
- Guardar el nombre del equipo en el proceso de respaldo.
- Permitir elegir el destino del backup:
  - Servidor remoto mediante dirección IP
  - Almacenamiento externo (USB, disco duro externo, etc.)

## Uso

1. Abrir PowerShell.
2. Navegar a la carpeta donde se encuentra `script_respaldo.ps1`.
3. Ejecutar el script:

```powershell
.\script_respaldo.ps1
```

4. Responder las preguntas interactivas para seleccionar carpetas adicionales y destino del respaldo.

## Requisitos

- Windows PowerShell.
- Permisos para leer las carpetas del usuario y escribir en la unidad de destino seleccionada.
- Si se elige servidor remoto, debe facilitarse la dirección IP del servidor y tener acceso a la red.

## Notas

- El respaldo de Escritorio es obligatorio y siempre se incluirá.
- El script pregunta al usuario sobre discos adicionales en el equipo antes de continuar.
- Si el usuario elige enviar la copia a un servidor, se solicitará la IP del servidor.
- Si no se desea enviar al servidor, se puede elegir un almacenamiento externo local.

## Archivos

- `script_respaldo.ps1`: Script principal para ejecutar el respaldo.
- `README.md`: Documentación y guía de uso.
