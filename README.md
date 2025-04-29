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
opam switch create 4.13.1
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

## Solución de Problemas

### El servidor no inicia

Verifica que el puerto 8080 no esté en uso:
```bash
sudo lsof -i :8080
```

Si hay algún proceso usando ese puerto, puedes terminarlo:
```bash
sudo kill -9 [PID]
```

### Errores de compilación en Elm

Si encuentras errores al compilar el frontend, verifica:
1. Que todas las dependencias de Elm estén instaladas
2. Que la sintaxis del código sea correcta
3. Ejecuta `elm make src/Main.elm --debug` para obtener información detallada

### Errores en el backend

Si encuentras errores en el backend, verifica:
1. Que todas las dependencias de OCaml estén instaladas
2. Que la base de datos SQLite exista y tenga los permisos correctos
3. Revisa los logs del servidor para identificar el problema específico

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo LICENSE para más detalles.
