# Script de Respaldo Automático

Scripts interactivos para realizar copias de seguridad de las carpetas principales del usuario. Disponibles en tres versiones: **PowerShell** (Windows), **Bash** (Linux/macOS) y **Python** (multiplataforma).

## Funcionalidades Generales

- Respaldar automáticamente las carpetas:
  - Documentos
  - Escritorio (obligatorio)
- Preguntar si se desea respaldar las carpetas opcionales:
  - Descargas
  - Música
  - Imágenes
  - Videos
- Detectar y preguntar por discos/volúmenes adicionales disponibles para incluirlos en el respaldo.
- Guardar el nombre del equipo en el proceso de respaldo.
- Permitir elegir el destino del backup:
  - Servidor remoto (vía IP en PowerShell, vía SSH en Bash/Python)
  - Almacenamiento externo local (USB, disco duro externo, etc.)
- Generar resumen detallado del respaldo con estadísticas de éxitos/errores.

---

## 1. Script PowerShell (Windows)

### Uso

```powershell
.\script_respaldo.ps1
```

### Requisitos

- Windows PowerShell 5.0 o superior
- Permisos de lectura en las carpetas del usuario
- Permisos de escritura en el destino del respaldo
- Para servidor remoto: acceso de red a la dirección IP y carpeta compartida

### Destino del Respaldo

- **Opción 1**: Servidor remoto mediante dirección IP (ruta UNC: `\\IP\nombreCompartida`)
- **Opción 2**: Almacenamiento externo local (ruta local: `E:\Backups`)

### Notas

- El respaldo de Escritorio es obligatorio y siempre se incluirá.
- Detección automática de discos adicionales (D:, E:, F:, etc.)
- Crea estructura de carpetas organizada por nombre de equipo

---

## 2. Script Bash (Linux/macOS)

### Uso

```bash
chmod +x script_respaldo.sh
./script_respaldo.sh
```

### Requisitos

- Bash 4.0 o superior
- `rsync` instalado (para copias eficientes)
- Permisos de lectura en las carpetas del usuario
- Permisos de escritura en el destino del respaldo
- Para servidor remoto: acceso SSH configurado

### Destino del Respaldo

- **Opción 1**: Servidor remoto mediante SSH (`user@host:/path`)
- **Opción 2**: Almacenamiento externo local (`/mnt/backup`)

### Instalación de rsync (si no está disponible)

```bash
# Ubuntu/Debian
sudo apt-get install rsync

# macOS (con Homebrew)
brew install rsync
```

### Notas

- Detección automática de puntos de montaje desde `/etc/fstab`
- Usa `rsync` para copias incremental y eficiente
- Preserva permisos y propietarios de archivos

---

## 3. Script Python (Multiplataforma)

### Uso

```bash
python3 script_respaldo.py
```

### Requisitos

- Python 3.7 o superior
- Permisos de lectura en las carpetas del usuario
- Permisos de escritura en el destino del respaldo
- Para servidor remoto: acceso SSH configurado

### Destino del Respaldo

- **Opción 1**: Servidor remoto mediante SSH (`user@host:/path`)
- **Opción 2**: Almacenamiento externo local (`/path/to/backup`)

### Características

- **Sin dependencias externas**: Solo usa librerías estándar de Python
- **Multiplataforma**: Funciona en Windows, Linux y macOS
- Detección automática de volúmenes según el SO
  - **Windows**: Detecta letras de unidad (D:, E:, etc.)
  - **Linux/macOS**: Lee puntos de montaje desde `/etc/fstab`

### Notas

- Copia recursiva con exclusión de archivos del sistema
- Genera resumen detallado del proceso

---

## Flujo de Ejecución (Todas las versiones)

1. Se pregunta por carpetas opcionales (Descargas, Música, Imágenes, Videos)
2. Se detectan volúmenes/discos adicionales y se pregunta si incluirlos
3. Se solicita elegir destino: servidor remoto o almacenamiento local
4. Se valida acceso y permisos en el destino
5. Se inicia el respaldo de cada carpeta seleccionada
6. Se genera resumen con:
   - Fecha y hora del respaldo
   - Nombre del equipo
   - Usuario que ejecutó el respaldo
   - Carpetas copiadas exitosamente
   - Errores encontrados

---

## Archivos Generados

En el destino del respaldo se crean:

```
[destino]/
└── [nombre_equipo]/
    ├── BackupSummary.txt      # Resumen detallado del respaldo
    ├── ComputerName.txt       # Información del equipo
    ├── Escritorio/            # Carpeta respalda
    ├── Documentos/            # Carpeta respalda
    └── ...                    # Otras carpetas según selección
```

---

## Archivos Disponibles

- `script_respaldo.ps1`: Script para Windows (PowerShell)
- `script_respaldo.sh`: Script para Linux/macOS (Bash)
- `script_respaldo.py`: Script multiplataforma (Python)
- `README.md`: Este archivo de documentación

---

## Ejemplos de Uso

### PowerShell - Respaldo a servidor remoto

```powershell
.\script_respaldo.ps1
# Seleccionar: 1 (Servidor remoto)
# Ingresar IP: 192.168.1.100
# Ingresar compartida: Backup
```

### Bash - Respaldo a almacenamiento local

```bash
./script_respaldo.sh
# Seleccionar: 2 (Almacenamiento local)
# Ingresar ruta: /mnt/external_drive/backup
```

### Python - Respaldo a SSH

```bash
python3 script_respaldo.py
# Seleccionar: 1 (Servidor remoto SSH)
# Ingresar dirección: usuario@servidor.com:/backups
```

---

## Resolución de Problemas

### PowerShell: "No se puede ejecutar scripts"

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Bash/Python: "Permiso denegado"

```bash
chmod +x script_respaldo.sh
chmod +x script_respaldo.py
```

### SSH: "Connection refused"

Verificar que el servidor SSH está disponible y las credenciales son correctas.

### rsync: "Comando no encontrado"

Instalar rsync según tu sistema operativo (ver sección Bash - Instalación de rsync).
