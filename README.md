# SaludApp

Aplicación móvil para gestión de citas médicas (Flutter + Dart + PostgreSQL). Consume el backend en [`SaludApp`](../SaludApp). Ver `spec/constitution/` para la constitución completa del proyecto (misión, stack, integración con la API) y `spec/features/` para cada feature con su spec/plan/tasks.

## Cómo correr todo en local

Asume que clonaste `SaludApp` (backend) y `saludapp-mobile` (frontend) como carpetas hermanas, dentro de un mismo directorio padre.

### Backend (`SaludApp`)

```bash
cd ../SaludApp

# PostgreSQL — debe estar corriendo como servicio nativo
# Verificar que PostgreSQL está activo:
psql -U postgres -c "SELECT version();"

# Crear base de datos (si no existe)
psql -U postgres -c "CREATE DATABASE saludapp;"

# Conectar a la base y ejecutar el script SQL
psql -U postgres -d saludapp -f saludapp.sql

# Instalar dependencias y ejecutar
dart pub get
dart run lib/main.dart          # http://localhost:8080
Postgres corre como servicio nativo del sistema, no necesita comando — ya está siempre disponible.

Si alguna vez cambias algo en saludapp.sql (tablas, relaciones, datos de prueba), la base de datos no lo relee solo — hay que recrear las tablas:

bash
psql -U postgres -d saludapp -f saludapp.sql
Frontend — modo navegador
bash
# Configurar URL del backend en lib/utils/constants.dart
# Para navegador/Windows:
# static const String baseUrl = 'http://localhost:8080';

flutter pub get
flutter run -d chrome           # http://localhost:xxxx
Ábrelo en cualquier navegador normal; el login envía credenciales directamente al backend.

Frontend — Android (emulador)
bash
# Si el emulador no está corriendo:
flutter emulators --launch Pixel_4

# Ejecutar la app
flutter run                      # Seleccionar el emulador Android

# — o, para ejecutar directo en el emulador:
flutter run -d emulator-5554
Usuario de prueba: test@test.com / 123456.

⚠️ Antes de correr en Android, cambia lib/utils/constants.dart — hoy apunta a localhost (navegador), pero el emulador Android necesita 10.0.2.2 (alias del emulador hacia tu máquina):

bash
# En saludapp-mobile/lib/utils/constants.dart, cambia:
// static const String baseUrl = 'http://localhost:8080';
static const String baseUrl = 'http://10.0.2.2:8080';
(y flutter pub get de nuevo antes de flutter run).

Frontend — Windows
bash
flutter run -d windows
Verificar que todo esté arriba
bash
curl -s -o /dev/null -w "backend: %{http_code}\n" http://localhost:8080/api/especialidades
curl -s -o /dev/null -w "frontend dev: %{http_code}\n" http://localhost:51391/
flutter devices
¿Por qué hace falta PostgreSQL sí o sí?
No hay forma de tener datos reales (usuarios, citas, doctores) sin PostgreSQL corriendo — es donde vive toda la información de la aplicación. El backend valida credenciales, genera tokens JWT y gestiona las citas; los datos persisten en la base de datos. Sin PostgreSQL, la app no puede registrar usuarios, crear citas ni mostrar información real.

¿Por qué es importante 10.0.2.2?
En el emulador Android, 10.0.2.2 es la IP especial que conecta el emulador con el localhost de tu máquina host. Sin esto, la app no podría comunicarse con el backend cuando corre en el emulador.
