#!/bin/bash

#
# Script interactivo de respaldo automático para Linux/Mac
#
# Descripción:
#   Respalda las carpetas principales del perfil del usuario (Desktop, Documents)
#   con opciones para incluir carpetas adicionales (Downloads, Music, Pictures, Videos)
#   y puntos de montaje adicionales en el sistema.
#
#   Ofrece dos modos de destino:
#   - Servidor remoto mediante SSH (user@host:/path)
#   - Almacenamiento externo local (/path)
#
#   Genera un sumario detallado al finalizar con logs de éxitos y errores.
#
# Requisitos:
#   - Bash 4.0 o superior
#   - Permisos de lectura en las carpetas a respaldar
#   - Permisos de escritura en el destino del respaldo
#   - Para destinos remotos: acceso SSH al servidor
#   - rsync para copias eficientes
#
# Notas:
#   - El script detiene la ejecución en errores críticos (set -o errexit)
#   - Las carpetas se organizan por nombre de equipo en el destino
#   - Se generan archivos de resumen para auditoría del respaldo
#

set -o errexit
set -o pipefail

# ========================================
# Funciones auxiliares
# ========================================

ask_yes_no() {
    #
    # Solicita una respuesta Sí/No al usuario con validación en bucle.
    #
    # Argumentos:
    #   $1: Mensaje a mostrar al usuario
    #   $2: Opción por defecto ('s' o 'n', por defecto 's')
    #
    # Retorna:
    #   0 para 'S' (sí), 1 para 'N' (no)
    #

    local message="$1"
    local default="${2:-s}"
    local default_text
    local answer

    if [ "$default" = "s" ]; then
        default_text="[S/n]"
    else
        default_text="[s/N]"
    fi

    while true; do
        read -p "$message $default_text: " answer
        answer="${answer:-$default}"
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

        case "$answer" in
            s|si|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            *)
                echo "Respuesta no válida. Responda S o N."
                ;;
        esac
    done
}

get_additional_volumes() {
    #
    # Detecta y retorna puntos de montaje adicionales relevantes
    #
    # Retorna:
    #   Array de rutas de puntos de montaje seleccionados
    #

    local volumes=()
    local selected=()
    local mount_point

    # Obtener puntos de montaje de discos externos (excluyendo raíz y puntos del sistema)
    # Busca en /etc/fstab líneas que no sean comentarios ni de swap
    while IFS= read -r line; do
        # Saltar comentarios y líneas vacías
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Extraer el punto de montaje (segundo campo)
        mount_point=$(echo "$line" | awk '{print $2}')

        # Excluir puntos del sistema: /, /boot, /home, /usr, /var, /tmp
        if [[ ! "$mount_point" =~ ^/(boot|home|usr|var|tmp|sys|proc|dev|run)(/|$) ]] && \
           [ "$mount_point" != "/" ]; then
            # Verificar que el punto de montaje existe y es accesible
            if [ -d "$mount_point" ] && [ -r "$mount_point" ]; then
                volumes+=("$mount_point")
            fi
        fi
    done < /etc/fstab

    # Si se encontraron volúmenes, permitir selección del usuario
    if [ ${#volumes[@]} -gt 0 ]; then
        echo "Puntos de montaje adicionales encontrados:"
        for i in "${!volumes[@]}"; do
            echo "  $((i+1)). ${volumes[$i]}"
        done

        for volume in "${volumes[@]}"; do
            if ask_yes_no "¿Incluir punto de montaje $volume?"; then
                selected+=("$volume")
            fi
        done
    fi

    printf '%s\n' "${selected[@]}"
}

resolve_backup_destination() {
    #
    # Valida y prepara la ruta de destino del respaldo
    #
    # Argumentos:
    #   $1: Ruta de destino (local o remota)
    #
    # Retorna:
    #   Ruta validada del destino
    #

    local destination="$1"

    # Manejar rutas SSH (user@host:/path) y locales de manera diferente
    if [[ "$destination" =~ @ ]]; then
        # Es una ruta SSH: validar acceso básico
        local host="${destination%%:*}"
        local path="${destination##*:}"

        if ! ssh -o ConnectTimeout=5 "$host" "[ -d '$path' ] || mkdir -p '$path'" 2>/dev/null; then
            echo "Error: No se puede acceder o crear el destino remoto: $destination" >&2
            return 1
        fi
    else
        # Es una ruta local: intentar crear si no existe
        if [ -e "$destination" ] && [ ! -d "$destination" ]; then
            echo "Error: $destination existe pero no es un directorio" >&2
            return 1
        fi

        if [ ! -d "$destination" ]; then
            if ! mkdir -p "$destination" 2>/dev/null; then
                echo "Error: No se puede crear o acceder al destino: $destination" >&2
                return 1
            fi
        fi

        # Verificar permisos de escritura
        if ! touch "$destination/.test-write-permission" 2>/dev/null; then
            echo "Error: No se puede escribir en el destino: $destination" >&2
            return 1
        fi
        rm -f "$destination/.test-write-permission"
    fi

    echo "$destination"
    return 0
}

get_backup_destination() {
    #
    # Permite al usuario elegir el destino del respaldo (remoto o local)
    #
    # Retorna:
    #   Ruta validada del destino del respaldo
    #

    echo "Destino del backup:"
    echo "1) Servidor remoto mediante SSH (user@host:/path)"
    echo "2) Almacenamiento externo local (/path)"

    while true; do
        read -p "Elija 1 o 2: " option

        case "$option" in
            1)
                read -p "Ingrese la dirección remota (user@host:/path): " remote_address
                if [ -z "$remote_address" ]; then
                    echo "Se requiere una dirección remota válida."
                    continue
                fi

                if resolve_backup_destination "$remote_address"; then
                    echo "$remote_address"
                    return 0
                fi
                ;;
            2)
                read -p "Ingrese la ruta local de destino (por ejemplo, /mnt/backup): " local_path
                if [ -z "$local_path" ]; then
                    echo "Se requiere una ruta de destino."
                    continue
                fi

                if resolve_backup_destination "$local_path"; then
                    echo "$local_path"
                    return 0
                fi
                ;;
            *)
                echo "Opción no válida. Elija 1 o 2."
                ;;
        esac
    done
}

copy_backup_folder() {
    #
    # Copia una carpeta usando rsync (más eficiente que cp)
    #
    # Argumentos:
    #   $1: Ruta de origen a respaldar
    #   $2: Ruta raíz donde se creará la carpeta de destino
    #
    # Retorna:
    #   0 si la copia fue exitosa, 1 en caso de error
    #

    local source_path="$1"
    local backup_root="$2"
    local target_name
    local destination

    # Validar que el origen existe
    if [ ! -d "$source_path" ]; then
        echo "Error: No se encontró la ruta de origen: $source_path" >&2
        return 1
    fi

    # Obtener el nombre de la carpeta
    target_name=$(basename "$source_path")

    # Crear la carpeta de destino
    destination="$backup_root/$target_name"
    mkdir -p "$destination" 2>/dev/null || true

    # Copiar recursivamente usando rsync
    # --archive: preservar permisos, propietarios, etc.
    # --verbose: mostrar progreso
    # --delete: eliminar archivos en destino que no están en origen
    # --exclude: excluir archivos del sistema innecesarios
    if rsync -a --verbose \
        --exclude='pagefile.sys' \
        --exclude='hiberfil.sys' \
        --exclude='swapfile.sys' \
        --exclude='*.swp' \
        "$source_path/" "$destination/" 2>/dev/null; then
        return 0
    else
        echo "Error copiando '$source_path' a '$destination'" >&2
        return 1
    fi
}

write_backup_summary() {
    #
    # Escribe el resumen del respaldo en un archivo de texto UTF-8
    #
    # Argumentos:
    #   $1: Ruta completa del archivo de resumen
    #   @: Líneas a escribir
    #

    local summary_path="$1"
    shift
    local lines=("$@")

    # Escribir líneas en el archivo
    {
        for line in "${lines[@]}"; do
            echo "$line"
        done
    } > "$summary_path"
}

# ========================================
# Sección: CONFIGURACIÓN E INICIALIZACIÓN
# ========================================

# Obtener información del equipo y usuario actual
COMPUTER_NAME=$(hostname)
USER_PROFILE="$HOME"

# Definir carpetas REQUERIDAS obligatorias para el respaldo
# (Escritorio y Documentos se incluyen siempre)
declare -a BACKUP_ITEMS
BACKUP_ITEMS+=("Escritorio:$USER_PROFILE/Desktop:true")
BACKUP_ITEMS+=("Documentos:$USER_PROFILE/Documents:true")

# Definir carpetas OPCIONALES que se ofrecerán al usuario
declare -a OPTIONAL_FOLDERS
OPTIONAL_FOLDERS+=("Descargas:$USER_PROFILE/Downloads")
OPTIONAL_FOLDERS+=("Música:$USER_PROFILE/Music")
OPTIONAL_FOLDERS+=("Imágenes:$USER_PROFILE/Pictures")
OPTIONAL_FOLDERS+=("Videos:$USER_PROFILE/Videos")

# Permitir al usuario seleccionar carpetas opcionales que existan
for folder_info in "${OPTIONAL_FOLDERS[@]}"; do
    IFS=':' read -r folder_name folder_path <<< "$folder_info"
    if [ -d "$folder_path" ]; then
        if ask_yes_no "¿Desea respaldar '$folder_name'?" n; then
            BACKUP_ITEMS+=("$folder_name:$folder_path:false")
        fi
    fi
done

# Detectar puntos de montaje adicionales (si existen) y permitir selección
EXTRA_VOLUMES=($(get_additional_volumes || true))

# ========================================
# Sección: SELECCIÓN DE DESTINO
# ========================================

echo -e "\nSeleccionando destino del respaldo..."
BACKUP_DESTINATION=$(get_backup_destination)

# Crear estructura de carpetas: raíz del respaldo / nombre del equipo
# Esto permite organizar respaldos de múltiples equipos en el mismo servidor
BACKUP_ROOT="$BACKUP_DESTINATION/$COMPUTER_NAME"
mkdir -p "$BACKUP_ROOT" 2>/dev/null || true

# Definir rutas de archivos informativos del respaldo
SUMMARY_PATH="$BACKUP_ROOT/BackupSummary.txt"
LOG_PATH="$BACKUP_ROOT/ComputerName.txt"

# Crear archivo con información del equipo y usuario que ejecutó el respaldo
# Útil para auditoría y validación posterior
write_backup_summary "$LOG_PATH" \
    "Equipo: $COMPUTER_NAME" \
    "Usuario: $USER" \
    "Fecha: $(date +%Y-%m-%d' '%H:%M:%S)"

# Inicializar array de resumen con encabezados y información general
declare -a SUMMARY_LINES
SUMMARY_LINES+=("Resumen de respaldo")
SUMMARY_LINES+=("===================")
SUMMARY_LINES+=("Equipo: $COMPUTER_NAME")
SUMMARY_LINES+=("Fecha: $(date +%Y-%m-%d' '%H:%M:%S)")
SUMMARY_LINES+=("Destino: $BACKUP_ROOT")
SUMMARY_LINES+=("")

# ========================================
# Sección: EJECUCIÓN DEL RESPALDO
# ========================================

echo -e "\nIniciando respaldo en: $BACKUP_ROOT"

# Contadores para tracking de éxitos y errores
COMPLETED=0
FAILED=0

# Procesar todas las carpetas de usuario seleccionadas
for item_info in "${BACKUP_ITEMS[@]}"; do
    IFS=':' read -r item_name item_path item_required <<< "$item_info"

    if [ ! -d "$item_path" ]; then
        # Advertencia si la carpeta no existe (puede ocurrir en algunos sistemas)
        echo "Advertencia: La ruta no existe: $item_path" >&2
        SUMMARY_LINES+=("[Omitido] $item_name - Ruta no encontrada: $item_path")
        continue
    fi

    echo "Copiando $item_name..."
    if copy_backup_folder "$item_path" "$BACKUP_ROOT"; then
        ((COMPLETED++))
        SUMMARY_LINES+=("[OK] $item_name -> $item_path")
    else
        ((FAILED++))
        SUMMARY_LINES+=("[Error] $item_name -> $item_path")
    fi
done

# Procesar puntos de montaje adicionales (si el usuario los seleccionó)
for volume in "${EXTRA_VOLUMES[@]}"; do
    echo "Copiando punto de montaje $volume..."
    if copy_backup_folder "$volume" "$BACKUP_ROOT"; then
        ((COMPLETED++))
        SUMMARY_LINES+=("[OK] Punto de montaje $volume")
    else
        ((FAILED++))
        SUMMARY_LINES+=("[Error] Punto de montaje $volume")
    fi
done

# ========================================
# Sección: GENERACIÓN DE REPORTE FINAL
# ========================================

# Agregar estadísticas de resultado al resumen
SUMMARY_LINES+=("")
SUMMARY_LINES+=("Carpetas copiadas: $COMPLETED")
SUMMARY_LINES+=("Errores: $FAILED")

# Guardar el resumen del respaldo para auditoría
write_backup_summary "$SUMMARY_PATH" "${SUMMARY_LINES[@]}"

echo -e "\nRespaldo finalizado."
echo "Resumen guardado en: $SUMMARY_PATH"

if [ "$FAILED" -gt 0 ]; then
    # Alertar al usuario si hubo errores durante el respaldo
    echo "Algunas carpetas no se pudieron copiar. Revise el archivo de resumen." >&2
    exit 1
else
    # Confirmación de éxito si todo se copió sin problemas
    echo "Copia completada sin errores."
    exit 0
fi
