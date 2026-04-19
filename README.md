# Script de Automatización para Servicios SSH


# 🔐 SSH Automation Pro v1.2

**Desarrollado por:** Kaleth Corcho  
**Lenguaje:** Bash (.sh)  
**Propósito:** Auditoría y prueba de vulnerabilidades en servicios SSH
<img width="1920" height="1080" alt="Captura de pantalla_2026-04-19_09-30-59" src="https://github.com/user-attachments/assets/c9b48b85-1a14-4cc0-9271-6840f2cf657c" />
<img width="1920" height="1080" alt="Captura de pantalla_2026-04-19_09-30-14" src="https://github.com/user-attachments/assets/204ff396-2c4b-42cb-b688-6cc8c6f1c7d6" />

---

## 📋 Descripción

Script de automatización modular diseñado para realizar auditorías de seguridad en servicios SSH. Implementa escaneo de redes, detección de hosts con SSH abierto y pruebas de fuerza bruta con soporte para diccionarios externos.

### ✨ Características Principales

- **Estructura Modular:** Funciones bien organizadas (`test_credentials`, `scan_ssh_services`, `brute_force_ssh`)
- **Paralelismo Real:** Ejecución simultánea de hasta 5 hilos para optimizar velocidad
- **Gestión de Archivos:** Directorio timestamped por ejecución para no sobrescribir datos
- **Interfaz Amigable:** Colores y mensajes claros en terminal
- **Diccionarios Externos:** Carga usuarios y contraseñas desde archivos `.txt`
- **Manejo de Interrupciones:** Trap para salida limpia con Ctrl+C
- **Extracción Robusta de IPs:** Uso de formato grepeable de nmap (`-oG`)

---

## 🚀 Instalación

### Dependencias Requeridas

```bash
sudo apt-get install nmap sshpass
```

### Descarga del Script

```bash
git clone <repositorio>
cd ssh-automation
chmod +x script.sh
```

---

## 📖 Uso

### Ejecución Básica (Red por defecto: 192.168.1.0/24)

```bash
./script.sh
```

### Especificar Red Objetivo

```bash
./script.sh 10.0.0.0/24
```

### Con Diccionarios Personalizados

```bash
# Crear archivos de diccionario
echo -e "root\nadmin\nuser\ntest" > users.txt
echo -e "password\n123456\nadmin\nroot" > passwords.txt

# Ejecutar script
./script.sh 192.168.100.0/24
```

---

## 📁 Estructura de Archivos

```
.
├── script.sh                 # Script principal
├── users.txt                 # Diccionario de usuarios (auto-generado)
├── passwords.txt             # Diccionario de contraseñas (auto-generado)
└── ssh_audit_YYYYMMDD_HHMMSS/  # Directorio de resultados
    ├── scan.gnmap           # Resultados del escaneo nmap
    ├── ssh_hosts.txt        # Hosts con SSH detectado
    └── valid_credentials.txt # Credenciales válidas encontradas
```

---

## ⚙️ Configuración

Edita las siguientes variables en el script según tus necesidades:

```bash
THREADS=5          # Número de hilos paralelos (aumenta para más velocidad)
TIMEOUT=5          # Timeout en segundos para conexiones SSH
USER_FILE="users.txt"       # Archivo con nombres de usuario
PASS_FILE="passwords.txt"   # Archivo con contraseñas
```

---

## 🔧 Funciones Principales

### `scan_ssh_services(network)`
Escanea una red en busca de puertos SSH abiertos usando nmap.

```bash
scan_ssh_services "192.168.1.0/24"
```

### `test_credentials(host, user, pass, port)`
Intenta autenticarse en un host SSH con credenciales específicas.

```bash
test_credentials "192.168.1.100" "admin" "password123" 22
```

### `brute_force_ssh(host, port)`
Ejecuta pruebas de fuerza bruta contra un host usando diccionarios externos.

```bash
brute_force_ssh "192.168.1.100" 22
```

### `check_dictionaries()`
Verifica o crea diccionarios por defecto si no existen.

---

## 📊 Ejemplo de Salida

```
[*] Escaneando red: 192.168.1.0/24...
[*] Se encontraron 5 hosts con SSH abierto.

[*] Atacando: 192.168.1.100
[+] ¡ÉXITO! 192.168.1.100 -> admin:123456
[+] ¡ÉXITO! 192.168.1.100 -> root:password

[*] Atacando: 192.168.1.101
[-] Sin credenciales válidas encontradas

--- Proceso completado. Resultados en ssh_audit_20240115_143022 ---
```

---

## 🛡️ Mejoras Implementadas (v1.2)

| Mejora | Descripción |
|--------|------------|
| **Paralelismo** | Implementación de `wait` y control de hilos para ejecución simultánea |
| **Diccionarios Externos** | Carga de usuarios/contraseñas desde archivos `.txt` |
| **Extracción de IPs** | Uso de formato grepeable nmap (`-oG`) para mayor estabilidad |
| **Manejo de Señales** | `trap` para salida limpia ante Ctrl+C |
| **Auto-generación** | Creación automática de diccionarios por defecto |
| **Validación SSH** | Opción `PubkeyAuthentication=no` para forzar autenticación por contraseña |

---

## ⚠️ Advertencias Legales

**IMPORTANTE:** Este script está diseñado **únicamente para auditorías autorizadas** en sistemas propios o con permiso explícito del propietario.

- ❌ **NO usar contra sistemas sin autorización**
- ❌ **NO violar leyes de ciberseguridad locales**
- ✅ **Usar solo en entornos de prueba controlados**

---

## 🐛 Solución de Problemas

### Error: "Falta nmap"
```bash
sudo apt-get install nmap
```

### Error: "Falta sshpass"
```bash
sudo apt-get install sshpass
```

### El script es muy lento
Aumenta el valor de `THREADS`:
```bash
THREADS=10  # Más hilos = más velocidad (pero más carga del sistema)
```

### Los diccionarios no se crean
Verifica permisos:
```bash
chmod 755 script.sh
```

---

## 📝 Formato de Diccionarios

### users.txt
```
root
admin
user
test
```

### passwords.txt
```
password
123456
admin
root
qwerty
```

---

## 🔄 Flujo de Ejecución

```
1. Validar dependencias (nmap, sshpass)
2. Verificar/crear diccionarios
3. Escanear red objetivo
4. Extraer hosts con SSH abierto
5. Para cada host:
   - Para cada usuario en users.txt:
     - Para cada contraseña en passwords.txt:
       - Intentar conexión SSH (paralelo)
6. Guardar resultados en directorio timestamped
7. Mostrar credenciales válidas encontradas
```

---

## 📞 Soporte
3505416339

---

## 📜 Licencia

MIT License - Uso libre con atribución

---

**Última actualización:** Enero 2026 
**Versión:** 1.2
```

---

Este README.md proporciona documentación completa, profesional y fácil de seguir para el script SSH. Incluye instalación, uso, configuración, ejemplos y advertencias legales. 🚀
