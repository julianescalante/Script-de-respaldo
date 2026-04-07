#!/usr/bin/env python3

"""
Script interactivo de respaldo automático para Python

Descripción:
    Respalda las carpetas principales del perfil del usuario (Desktop, Documents)
    con opciones para incluir carpetas adicionales (Downloads, Music, Pictures, Videos)
    y puntos de montaje adicionales en el sistema.
    
    Ofrece dos modos de destino:
    - Servidor remoto mediante SSH (user@host:/path)
    - Almacenamiento externo local (/path)
    
    Genera un sumario detallado al finalizar con logs de éxitos y errores.

Requisitos:
    - Python 3.7 o superior
    - Permisos de lectura en las carpetas a respaldar
    - Permisos de escritura en el destino del respaldo
    - Para destinos remotos: acceso SSH al servidor
    - (Sin dependencias externas - solo librerías estándar)

Notas:
    - Solo utiliza librerías estándar de Python
    - Las carpetas se organizan por nombre de equipo en el destino
    - Se generan archivos de resumen para auditoría del respaldo
"""

import os
import sys
import shutil
import socket
import subprocess
from pathlib import Path
from datetime import datetime
from typing import List, Tuple, Optional


# ========================================
# Funciones auxiliares
# ========================================

def ask_yes_no(message: str, default: str = 's') -> bool:
    """
    Solicita una respuesta Sí/No al usuario con validación en bucle.

    Args:
        message: Mensaje a mostrar al usuario
        default: Opción por defecto ('s' o 'n', por defecto 's')

    Returns:
        True para 'S' (sí), False para 'N' (no)
    """
    default_text = '[S/n]' if default.lower() == 's' else '[s/N]'
    valid_yes = {'s', 'si', 'sí', 'yes', 'y'}
    valid_no = {'n', 'no'}

    while True:
        answer = input(f"{message} {default_text}: ").strip().lower()
        
        if not answer:
            return default.lower() == 's'
        
        if answer in valid_yes:
            return True
        elif answer in valid_no:
            return False
        else:
            print("Respuesta no válida. Responda S o N.")


def get_additional_volumes() -> List[str]:
    """
    Detecta y retorna puntos de montaje adicionales relevantes.

    Returns:
        Lista de rutas de puntos de montaje seleccionados
    """
    volumes = []
    selected = []

    # En Windows: obtener letras de unidad
    # En Linux/Mac: obtener puntos de montaje desde /etc/fstab
    if sys.platform == 'win32':
        # Detectar unidades adicionales en Windows
        for drive_letter in 'DEFGHIJKLMNOPQRSTUVWXYZ':
            drive_path = f"{drive_letter}:\\"
            if os.path.exists(drive_path):
                # Excluir unidad C: (sistema)
                if drive_letter != 'C':
                    volumes.append(drive_path)
    else:
        # En Linux/Mac, leer /etc/fstab
        try:
            with open('/etc/fstab', 'r') as f:
                for line in f:
                    # Saltar comentarios y líneas vacías
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    
                    # Extraer punto de montaje (segundo campo)
                    parts = line.split()
                    if len(parts) >= 2:
                        mount_point = parts[1]
                        
                        # Excluir puntos del sistema
                        excluded = ('/', '/boot', '/home', '/usr', '/var', 
                                   '/tmp', '/sys', '/proc', '/dev', '/run')
                        if not any(mount_point.startswith(ex) for ex in excluded):
                            if os.path.isdir(mount_point) and os.access(mount_point, os.R_OK):
                                volumes.append(mount_point)
        except (FileNotFoundError, PermissionError):
            pass

    # Permitir selección del usuario si se encontraron volúmenes
    if volumes:
        print("\nPuntos de montaje adicionales encontrados:")
        for i, volume in enumerate(volumes, 1):
            print(f"  {i}. {volume}")
        
        for volume in volumes:
            if ask_yes_no(f"¿Incluir punto de montaje {volume}?", 'n'):
                selected.append(volume)

    return selected


def resolve_backup_destination(destination: str) -> Optional[str]:
    """
    Valida y prepara la ruta de destino del respaldo.

    Args:
        destination: Ruta de destino (local o remota SSH)

    Returns:
        Ruta validada del destino, o None si hay error
    """
    # Manejar rutas SSH (user@host:/path) y locales
    if '@' in destination:
        # Es una ruta SSH
        try:
            host, path = destination.split(':', 1)
            if not path:
                print(f"Error: Ruta remota inválida")
                return None
            
            # Intentar crear el directorio remoto
            cmd = f"ssh -o ConnectTimeout=5 {host} \"[ -d '{path}' ] || mkdir -p '{path}'\""
            result = subprocess.run(cmd, shell=True, capture_output=True, timeout=10)
            
            if result.returncode != 0:
                print(f"Error: No se puede acceder o crear el destino remoto: {destination}")
                return None
        except (subprocess.TimeoutExpired, Exception) as e:
            print(f"Error al conectar con servidor remoto: {e}")
            return None
    else:
        # Es una ruta local
        dest_path = Path(destination)
        
        if dest_path.exists() and not dest_path.is_dir():
            print(f"Error: {destination} existe pero no es un directorio")
            return None
        
        try:
            dest_path.mkdir(parents=True, exist_ok=True)
            
            # Verificar permisos de escritura
            test_file = dest_path / '.test-write-permission'
            test_file.touch()
            test_file.unlink()
        except (OSError, PermissionError) as e:
            print(f"Error: No se puede crear o escribir en el destino: {destination}")
            return None

    return destination


def get_backup_destination() -> str:
    """
    Permite al usuario elegir el destino del respaldo (remoto o local).

    Returns:
        Ruta validada del destino del respaldo
    """
    print("\nDestino del backup:")
    print("1) Servidor remoto mediante SSH (user@host:/path)")
    print("2) Almacenamiento externo local (/path)")

    while True:
        option = input("Elija 1 o 2: ").strip()

        if option == '1':
            remote_address = input("Ingrese la dirección remota (user@host:/path): ").strip()
            if not remote_address:
                print("Se requiere una dirección remota válida.")
                continue
            
            if resolve_backup_destination(remote_address):
                return remote_address
        
        elif option == '2':
            local_path = input("Ingrese la ruta local de destino (por ejemplo, /mnt/backup): ").strip()
            if not local_path:
                print("Se requiere una ruta de destino.")
                continue
            
            if resolve_backup_destination(local_path):
                return local_path
        
        else:
            print("Opción no válida. Elija 1 o 2.")


def copy_backup_folder(source_path: str, backup_root: str) -> bool:
    """
    Copia una carpeta recursivamente.

    Args:
        source_path: Ruta de origen a respaldar
        backup_root: Ruta raíz donde se creará la carpeta de destino

    Returns:
        True si la copia fue exitosa, False en caso de error
    """
    source = Path(source_path)
    
    if not source.is_dir():
        print(f"Error: No se encontró la ruta de origen: {source_path}", file=sys.stderr)
        return False
    
    # Obtener el nombre de la carpeta
    target_name = source.name
    destination = Path(backup_root) / target_name
    
    try:
        destination.mkdir(parents=True, exist_ok=True)
        
        # Archivos a excluir
        exclude_files = {
            'pagefile.sys', 'hiberfil.sys', 'swapfile.sys', '.DS_Store'
        }
        
        # Copiar recursivamente
        _copy_tree(source, destination, exclude_files)
        return True
    
    except (OSError, shutil.Error) as e:
        print(f"Error copiando '{source_path}' a '{destination}': {e}", file=sys.stderr)
        return False


def _copy_tree(src: Path, dst: Path, exclude: set) -> None:
    """
    Copia un árbol de directorios de forma recursiva, excluyendo ciertos archivos.

    Args:
        src: Ruta de origen
        dst: Ruta de destino
        exclude: Conjunto de nombres de archivo a excluir
    """
    dst.mkdir(parents=True, exist_ok=True)
    
    for item in src.iterdir():
        if item.name in exclude or item.name.startswith('.'):
            continue
        
        src_item = src / item.name
        dst_item = dst / item.name
        
        if src_item.is_dir():
            _copy_tree(src_item, dst_item, exclude)
        else:
            try:
                shutil.copy2(src_item, dst_item)
            except (OSError, shutil.Error) as e:
                print(f"Advertencia al copiar {src_item}: {e}", file=sys.stderr)


def write_backup_summary(summary_path: str, lines: List[str]) -> None:
    """
    Escribe el resumen del respaldo en un archivo de texto UTF-8.

    Args:
        summary_path: Ruta completa donde se guardará el archivo de resumen
        lines: Lista de líneas a escribir
    """
    with open(summary_path, 'w', encoding='utf-8') as f:
        for line in lines:
            f.write(line + '\n')


# ========================================
# Sección: CONFIGURACIÓN E INICIALIZACIÓN
# ========================================

def main():
    """Función principal del script de respaldo."""
    
    # Obtener información del equipo y usuario actual
    computer_name = socket.gethostname()
    user_profile = Path.home()

    # Definir carpetas REQUERIDAS obligatorias para el respaldo
    backup_items = [
        ('Escritorio', user_profile / 'Desktop', True),
        ('Documentos', user_profile / 'Documents', True),
    ]

    # Definir carpetas OPCIONALES que se ofrecerán al usuario
    optional_folders = [
        ('Descargas', user_profile / 'Downloads'),
        ('Música', user_profile / 'Music'),
        ('Imágenes', user_profile / 'Pictures'),
        ('Videos', user_profile / 'Videos'),
    ]

    # Permitir al usuario seleccionar carpetas opcionales que existan
    for folder_name, folder_path in optional_folders:
        if folder_path.is_dir():
            if ask_yes_no(f"¿Desea respaldar '{folder_name}'?", 'n'):
                backup_items.append((folder_name, folder_path, False))

    # Detectar puntos de montaje adicionales (si existen) y permitir selección
    extra_volumes = get_additional_volumes()

    # ========================================
    # Sección: SELECCIÓN DE DESTINO
    # ========================================

    print("\nSeleccionando destino del respaldo...")
    backup_destination = get_backup_destination()

    # Crear estructura de carpetas: raíz del respaldo / nombre del equipo
    backup_root = f"{backup_destination}/{computer_name}"
    Path(backup_root).mkdir(parents=True, exist_ok=True)

    # Definir rutas de archivos informativos del respaldo
    summary_path = Path(backup_root) / 'BackupSummary.txt'
    log_path = Path(backup_root) / 'ComputerName.txt'

    # Crear archivo con información del equipo y usuario
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    write_backup_summary(
        str(log_path),
        [
            f"Equipo: {computer_name}",
            f"Usuario: {os.getenv('USERNAME', os.getenv('USER', 'Unknown'))}",
            f"Fecha: {now}"
        ]
    )

    # Inicializar array de resumen con encabezados e información general
    summary_lines = [
        "Resumen de respaldo",
        "===================",
        f"Equipo: {computer_name}",
        f"Fecha: {now}",
        f"Destino: {backup_root}",
        ""
    ]

    # ========================================
    # Sección: EJECUCIÓN DEL RESPALDO
    # ========================================

    print(f"\nIniciando respaldo en: {backup_root}")

    # Contadores para tracking de éxitos y errores
    completed = 0
    failed = 0

    # Procesar todas las carpetas de usuario seleccionadas
    for item_name, item_path, is_required in backup_items:
        if not item_path.is_dir():
            print(f"Advertencia: La ruta no existe: {item_path}", file=sys.stderr)
            summary_lines.append(f"[Omitido] {item_name} - Ruta no encontrada: {item_path}")
            continue

        print(f"Copiando {item_name}...")
        if copy_backup_folder(str(item_path), backup_root):
            completed += 1
            summary_lines.append(f"[OK] {item_name} -> {item_path}")
        else:
            failed += 1
            summary_lines.append(f"[Error] {item_name} -> {item_path}")

    # Procesar puntos de montaje adicionales (si el usuario los seleccionó)
    for volume in extra_volumes:
        print(f"Copiando punto de montaje {volume}...")
        if copy_backup_folder(volume, backup_root):
            completed += 1
            summary_lines.append(f"[OK] Punto de montaje {volume}")
        else:
            failed += 1
            summary_lines.append(f"[Error] Punto de montaje {volume}")

    # ========================================
    # Sección: GENERACIÓN DE REPORTE FINAL
    # ========================================

    summary_lines.append("")
    summary_lines.append(f"Carpetas copiadas: {completed}")
    summary_lines.append(f"Errores: {failed}")

    # Guardar el resumen del respaldo para auditoría
    write_backup_summary(str(summary_path), summary_lines)

    print("\nRespaldo finalizado.")
    print(f"Resumen guardado en: {summary_path}")

    if failed > 0:
        print("Algunas carpetas no se pudieron copiar. Revise el archivo de resumen.", 
              file=sys.stderr)
        sys.exit(1)
    else:
        print("Copia completada sin errores.")
        sys.exit(0)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nRespaldo cancelado por el usuario.", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"\nError fatal: {e}", file=sys.stderr)
        sys.exit(1)
