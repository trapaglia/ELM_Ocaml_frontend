# Aplicación de Gestión de Tickets

Esta aplicación permite gestionar tickets financieros con una interfaz web moderna. Está construida con un frontend en Elm y un backend en OCaml.

## Características

- Visualización de tickets en una tabla ordenada
- Edición de tickets existentes
- Creación de nuevos tickets
- Interfaz de usuario intuitiva y responsiva
- Comunicación en tiempo real con la base de datos

## Estructura del Proyecto

```
ELM_frontend/
├── backend/                # Servidor OCaml
│   ├── bin/                # Código fuente del backend
│   │   └── main.ml         # Punto de entrada del servidor
│   ├── public/             # Archivos estáticos
│   │   ├── index.html      # Página principal
│   │   └── elm.js          # JavaScript compilado desde Elm
│   ├── db_frontend.opam    # Configuración de dependencias OCaml
│   ├── dune-project        # Configuración del proyecto Dune
│   └── iol.db              # Base de datos SQLite
├── frontend/               # Aplicación Elm
│   └── src/                # Código fuente del frontend
│       └── Main.elm        # Código principal de Elm
├── package.json            # Dependencias de Node.js
└── README.md               # Este archivo
```

## Guía de Instalación

A continuación se detallan los pasos para instalar y ejecutar la aplicación desde cero en un sistema Linux.

### Requisitos Previos

Instala las siguientes herramientas:

```bash
# Actualizar repositorios
sudo apt update

# Instalar herramientas básicas
sudo apt install -y git curl build-essential pkg-config m4 sqlite3

# Instalar Node.js y npm
sudo apt install -y nodejs npm
```

### Instalar OCaml y OPAM

```bash
# Instalar OPAM (gestor de paquetes de OCaml)
sudo apt install -y opam

# Inicializar OPAM
opam init --auto-setup

# Actualizar shell environment
eval $(opam env)

# Instalar OCaml 4.13.1 (o la versión que prefieras)
opam switch create 5.1.0 #4.13.1
eval $(opam env)
```

### Instalar Elm

```bash
# Instalar Elm a través de npm
sudo npm install -g elm

# Verificar la instalación
elm --version
```

### Clonar el Repositorio

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/ELM_frontend.git
cd ELM_frontend
```

### Instalar Dependencias del Backend

```bash
# Instalar dependencias de OCaml
cd backend
opam install . --deps-only
opam install dune dream yojson sqlite3

# Configurar correctamente el proyecto Dune
# Crear el archivo dune-project en el directorio backend:
echo '(lang dune 2.9)
(name db_frontend)' > dune-project

# Crear el archivo dune en el directorio bin:
mkdir -p bin
echo '(executable
 (name main)
 (libraries dream yojson sqlite3))' > bin/dune

# Volver al directorio principal
cd ..
```

### Instalar Dependencias del Frontend

```bash
# Instalar dependencias de Node.js
npm install

# Compilar el frontend Elm
cd frontend
elm make src/Main.elm --output=../backend/public/elm.js
cd ..
```

### Ejecutar la Aplicación

```bash
# Iniciar el servidor backend
cd backend
dune exec bin/main.exe

# La aplicación estará disponible en http://localhost:8080
```

### Ejecutar el Servidor en una IP Pública

Para hacer que la aplicación sea accesible desde Internet, necesitas configurar el servidor para que escuche en una IP pública en lugar de solo localhost:

1. **Modificar el código del servidor**

   Edita el archivo `backend/bin/main.ml` para cambiar la configuración de la interfaz:

   ```bash
   # Abrir el archivo para edición
   nano backend/bin/main.ml
   ```

   Busca la sección donde se inicia el servidor Dream (cerca del final del archivo):

   ```ocaml
   let ()
     Dream.run
     ~interface:"0.0.0.0"  # Esto ya está configurado para escuchar en todas las interfaces
     ~port:8080
     (Dream.logger
     @@ Dream.router [
       (* API *)
       ...
     ])
   ```

   Si la interfaz ya está configurada como `"0.0.0.0"`, el servidor ya está listo para escuchar conexiones externas.

2. **Configurar el Firewall**

   Asegúrate de que el puerto 8080 esté abierto en el firewall:

   ```bash
   # Para sistemas con UFW (Ubuntu)
   sudo ufw allow 8080/tcp
   
   # Para sistemas con firewalld (Fedora, CentOS)
   sudo firewall-cmd --permanent --add-port=8080/tcp
   sudo firewall-cmd --reload
   ```

3. **Obtener tu IP Pública**

   ```bash
   # Método 1: Usando curl
   curl ifconfig.me
   
   # Método 2: Usando un servicio DNS
   dig +short myip.opendns.com @resolver1.opendns.com
   ```

4. **Iniciar el Servidor**

   ```bash
   cd backend
   dune exec bin/main.exe
   ```

5. **Acceder a la Aplicación**

   Ahora puedes acceder a la aplicación desde cualquier dispositivo usando:
   
   ```
   http://TU_IP_PUBLICA:8080
   ```

6. **Consideraciones de Seguridad**

   - Esta configuración básica no incluye HTTPS, lo que significa que el tráfico no está cifrado
   - Considera configurar un proxy inverso como Nginx con certificados SSL para producción
   - Limita el acceso al servidor con reglas de firewall adecuadas

7. **Verificación Exhaustiva de Accesibilidad Externa**

   Si aún no puedes acceder a la aplicación desde el exterior, verifica estos puntos:

   a. **Confirmar que el servidor está escuchando en todas las interfaces**:
   ```bash
   # Mientras el servidor está en ejecución, verifica los puertos abiertos
   sudo netstat -tulpn | grep 8080
   # Deberías ver algo como: tcp 0 0 0.0.0.0:8080 0.0.0.0:* LISTEN
   ```

   b. **Verificar si hay un firewall en la nube** (si estás usando un VPS):
   - AWS: Verifica los grupos de seguridad
   - DigitalOcean/Linode: Verifica los firewalls de la nube
   - Google Cloud: Verifica las reglas de firewall

   c. **Probar la conectividad localmente primero**:
   ```bash
   # Desde el servidor
   curl http://localhost:8080
   # Luego prueba con la IP interna
   curl http://IP_INTERNA:8080
   ```

   d. **Verificar si hay un NAT o router** entre tu servidor e Internet:
   - Configura el reenvío de puertos en tu router (puerto 8080 → IP interna:8080)
   - Contacta a tu ISP para verificar si bloquean el puerto 8080

   e. **Probar con un puerto diferente** (algunos ISP bloquean puertos comunes):
   ```ocaml
   # En backend/bin/main.ml, cambia:
   ~port:8080
   # Por un puerto menos común, como:
   ~port:9876
   ```
   Luego recompila y reinicia el servidor.

8. **Uso de un Proxy Inverso (Recomendado)**

   Un proxy inverso como Nginx o Apache puede resolver muchos problemas de accesibilidad y añadir funcionalidades importantes:

   a. **Instalar Nginx**:
   ```bash
   sudo apt update
   sudo apt install nginx
   ```

   b. **Configurar Nginx como proxy inverso**:
   ```bash
   sudo nano /etc/nginx/sites-available/elm-tickets
   ```

   Añade esta configuración:
   ```
   server {
       listen 80;
       server_name tu-dominio.com;  # O tu IP pública

       location / {
           proxy_pass http://localhost:8080;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

   c. **Activar la configuración**:
   ```bash
   sudo ln -s /etc/nginx/sites-available/elm-tickets /etc/nginx/sites-enabled/
   sudo nginx -t  # Verificar la configuración
   sudo systemctl restart nginx
   ```

   d. **Abrir el puerto 80 en el firewall**:
   ```bash
   sudo ufw allow 80/tcp
   ```

   Ahora podrás acceder a tu aplicación a través del puerto 80 (HTTP estándar):
   ```
   http://TU_IP_PUBLICA
   ```

9. **Añadir HTTPS con Certbot (Opcional pero recomendado)**

   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d tu-dominio.com
   ```

   Sigue las instrucciones para configurar HTTPS automáticamente.

10. **Configuración para Entorno de Producción**

   Para un entorno de producción, se recomienda:
   
   - Configurar un servicio systemd para mantener el servidor en ejecución
   - Usar un proxy inverso (Nginx/Apache) para gestionar SSL y caché
   - Configurar un nombre de dominio en lugar de usar la IP directamente

   Ejemplo de configuración de servicio systemd (`/etc/systemd/system/elm-tickets.service`):

   ```
   [Unit]
   Description=Elm Tickets Application
   After=network.target

   [Service]
   User=your_username
   WorkingDirectory=/ruta/a/ELM_frontend/backend
   ExecStart=/usr/bin/dune exec bin/main.exe
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

   Activar el servicio:
   
   ```bash
   sudo systemctl enable elm-tickets
   sudo systemctl start elm-tickets
   ```

## Solución de Problemas Comunes

### Error: "I cannot find the root of the current workspace/project"

Si sigues viendo este error después de seguir los pasos anteriores:

1. Asegúrate de estar en el directorio correcto (backend)
2. Verifica que los archivos dune-project y bin/dune se hayan creado correctamente
3. Si el problema persiste, intenta una solución alternativa:
   ```bash
   cd ..  # Volver al directorio raíz
   dune init project ELM_Ocaml_frontend
   cp -r backend/bin/* ELM_Ocaml_frontend/bin/
   cp -r backend/public/* ELM_Ocaml_frontend/
   cp backend/iol.db ELM_Ocaml_frontend/
   cd ELM_Ocaml_frontend
   dune exec bin/main.exe
   ```

### El servidor no inicia

Verifica que el puerto 8080 no esté en uso:
```bash
sudo lsof -i :8080
```

Si hay algún proceso usando ese puerto, puedes terminarlo:
```bash
sudo kill -9 [PID]
```

## Uso de la Aplicación

1. **Ver tickets**: Al abrir la aplicación, verás una tabla con todos los tickets existentes.

2. **Editar un ticket**: 
   - Haz clic en el botón "Editar" junto al ticket que deseas modificar
   - Realiza los cambios necesarios en el formulario
   - Haz clic en "Guardar" para confirmar los cambios o "Cancelar" para descartarlos

3. **Crear un nuevo ticket**:
   - Haz clic en el botón "Crear Nuevo Ticket" en la parte superior de la tabla
   - Completa todos los campos requeridos en el formulario
   - Haz clic en "Crear Ticket" para añadir el nuevo ticket a la base de datos

## Desarrollo

### Estructura de la Base de Datos

La aplicación utiliza SQLite con una tabla principal `tickets` que contiene los siguientes campos:

- `ticket_name`: Nombre del ticket (clave primaria)
- `estado`: Estado actual del ticket
- `compra1`, `compra2`: Valores de compra
- `venta1`, `venta2`: Valores de venta
- `take_profit`: Valor de toma de ganancias
- `stop_loss`: Valor de parada de pérdidas
- `punta_compra`, `punta_venta`: Valores de punta
- `last_update`: Fecha de última actualización

### Endpoints de la API

- `GET /api/tickets`: Obtiene todos los tickets
- `PUT /api/tickets`: Actualiza un ticket existente
- `POST /api/tickets`: Crea un nuevo ticket

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo LICENSE para más detalles.
