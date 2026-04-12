#  Monedo

Aplicación de finanzas personales desarrollada con Flutter, enfocada en la gestión de ingresos, gastos y control financiero diario.

##  Descripción

Monedo es una aplicación que permite a los usuarios registrar y visualizar sus movimientos financieros de forma sencilla, ayudando a mejorar el control del dinero y la toma de decisiones.

Este proyecto fue desarrollado como parte de mi proceso de aprendizaje en desarrollo móvil con Flutter y Firebase.

##  Tecnologías

* Flutter
* Dart
* Firebase (base de datos)
* Android Studio

##  Funcionalidades

* Registro de ingresos y gastos
* Visualización de transacciones
* Persistencia de datos en Firebase
* Interfaz intuitiva y responsive
* Estadisticas visuales


## 📲 Instalación

1. Clonar el repositorio
2. Ejecutar:

   ```
   flutter pub get
   ```
3. Ejecutar la app:

   ```
   flutter run
   ```

## 📲 Descargar APK

[Descargar Monedo v1.0](https://github.com/Ericknvp/monedo/releases/tag/v1.0)

##  Aprendizaje

Este proyecto me permitió fortalecer conocimientos en:

* Desarrollo móvil con Flutter
* Manejo de estado
* Integración con Firebase
* Estructuración de aplicaciones móviles

##  Autor

Erick Narváez
Instagram: Ericknvp
Correo: narvaezvegaerick@gmail.com

Paleta original:

static const Color primaryPurple = Color(0xFF7C3AED);     
static const Color darkPurple = Color(0xFF4C1D95);       
static const Color lightPurple = Color(0xFFDDD6FE);       
static const Color accentPurple = Color(0xFFA78BFA);     
static const Color backgroundDark = Color(0xFF0F0F1A);
static const Color cardDark = Color(0xFF1A1A2E);        
static const Color cardMedium = Color(0xFF16213E);      
static const Color income = Color(0xFF10B981);     
static const Color expense = Color(0xFFEF4444);      
static const Color textPrimary = Color(0xFFFFFFFF);       
static const Color textSecondary = Color(0xFF9CA3AF);    


Paleta de colores de borrador:

static const Color primaryPurple  = Color(0xFFD97706);
static const Color darkPurple     = Color(0xFF92400E);
static const Color lightPurple    = Color(0xFFFDE68A);
static const Color accentPurple   = Color(0xFFF59E0B);
static const Color backgroundDark = Color(0xFF0A0A0A);
static const Color cardDark       = Color(0xFF141414);
static const Color cardMedium     = Color(0xFF1C1C1C);
static const Color income         = Color(0xFF10B981);
static const Color expense        = Color(0xFFEF4444);
static const Color textPrimary    = Color(0xFFFFFFFF);
static const Color textSecondary  = Color(0xFF9CA3AF);


Changelog
v1.2.0 — Abril 2026
Nuevas funcionalidades

Metas de ahorro — crea metas con nombre y monto objetivo, registra abonos y el saldo se descuenta automáticamente del balance. Muestra porcentaje de progreso visual.
Formato de moneda — los montos ahora muestran separador de miles con comas (ej: $69,308)
Confirmación al salir — diálogo de confirmación antes de cerrar sesión para evitar salidas accidentales
Confirmación al eliminar movimientos en el dashboard.
Nueva categoría — se agregó "Ocio" a la lista de categorías de gastos

v1.1.0
Correcciones

Corregido error de setState() called after dispose() en el dashboard
Corregido conflicto de nombre entre Transaction de Firestore y el modelo propio, renombrado a TransactionModel
Corregido CardTheme → CardThemeData para compatibilidad con Flutter 3.x
Simplificadas las consultas de Firestore para evitar necesidad de índices compuestos

v1.0.0 — Abril 2026
Lanzamiento inicial

Registro e inicio de sesión con correo y contraseña
Nombres de usuario únicos
Dashboard con balance actual, ingresos y gastos del mes
Registro de ingresos y gastos con categoría, fecha y nota opcional
Edición y eliminación de movimientos
Filtros por Todos, Ingresos y Gastos
Estadísticas mensuales con selector de mes
Gráfica de torta de gastos por categoría
Estadísticas semanales
Pantalla "Acerca de" con info del creador
Diseño responsive — funciona en Android y Web
Base de datos en Firebase Firestore
Autenticación con Firebase Auth
