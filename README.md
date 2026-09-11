# Monedo

Aplicación de finanzas personales desarrollada con Flutter, orientada a la gestión de ingresos, gastos, metas de ahorro y control financiero diario con resumen mensual y semanal. Disponible en Android y Web.

## Descripción
Monedo permite registrar y visualizar movimientos financieros de forma clara e intuitiva, ayudando a tomar mejores decisiones sobre el dinero. Incluye estadísticas visuales, metas de ahorro y una landing page pública que presenta la aplicación a nuevos usuarios. Proximamente, recomendaciones de reducción de gastos con IA y estadística inferencia.


## Tecnologías

- Flutter / Dart
- Firebase Firestore
- Firebase Auth
- Firebase Hosting
- Android Studio

## Funcionalidades

- Cuentas de dinero (efectivo, banco, billeteras) con saldo propio, transferencias entre ellas y resumen "Dónde está tu dinero" en el dashboard
- Registro de ingresos y gastos con cuenta de bolsillo, categoría, fecha y nota opcional
- Categorías personalizadas con selector de ícono, además de las categorías por defecto
- Edición y eliminación de movimientos
- Filtros por tipo: Todos, Ingresos, Gastos y por rango de fechas.
- Balance actual con desglose mensual de ingresos y gastos
- Estadísticas mensuales con selector de mes
- Gráfica de torta de gastos por categoría
- Estadísticas semanales
- Metas de ahorro con progreso visual, descuento automático del balance de la cuenta elegida e historial de aportes por meta
- Exportación de movimientos a Excel y PDF.
- Selector de moneda (USD, COP, EUR, MXN, ARS, CLP, PEN, BRL, GBP) al registrarse, editable luego desde "Acerca de" y aplicado en tiempo real a toda la app



## Paleta de colores


| Token                    | Color     | Uso principal                        |
|--------------------------|-----------|--------------------------------------|
| primary                  | `#001F2D` | Fondos de header, gradientes         |
| primaryContainer         | `#0C3547` | Variante de fondo primario           |
| onPrimaryFixedVariant    | `#264B5E` | Bordes y elementos secundarios       |
| secondary                | `#006C4B` | Botones, accents, indicadores activos|
| secondaryContainer       | `#96F6C8` | Chips, badges, fondos de acento      |
| secondaryFixed           | `#96F6C8` | Texto y elementos sobre fondo oscuro |
| secondaryFixedDim        | `#7AD9AD` | Variante atenuada del acento         |
| background               | `#FCFAF8` | Fondo general de la app              |
| surfaceContainerLowest   | `#FFFFFF` | Tarjetas y modales                   |
| surfaceContainer         | `#F0EDEC` | Fondos de navegación inferior        |
| outlineVariant           | `#C1C7CC` | Bordes y divisores                   |
| errorRed / expense       | `#BA1A1A` | Errores y gastos                     |
| income                   | `#006C4B` | Ingresos (alias de secondary)        |

Tipografía: **Plus Jakarta Sans** (encabezados y cuerpo) / **Be Vietnam Pro** (etiquetas e inputs).

## Instalación

1. Clonar el repositorio
2. Instalar dependencias:
   ```
   flutter pub get
   ```
3. Ejecutar la app:
   ```
   flutter run
   ```

## Descargar APK última versión.

[Descargar Monedo v2.4.2](https://github.com/Ericknvp/monedo/releases/tag/v2.4.2)

## Changelog

### v2.4.2 — Septiembre 2026

- Corregido: no se podía crear una cuenta con correo y contraseña (fallaba silenciosamente por un problema de permisos en Firestore); el registro con Google no se veía afectado

### v2.4.1 — Septiembre 2026

- Filtro Mensual / Semana / Hoy en la gráfica de torta de gastos por categoría, con animación deslizante fluida entre los tres rangos
- Botones "Cancelar" y "Agregar/Guardar movimiento" flotantes con sombra propia en el diálogo de escritorio, en vez de una barra sólida fija
- Corregido: el logo "Monedo" en el encabezado de Android estaba pegado al borde izquierdo; ahora respeta el mismo margen que el resto del contenido

### v2.2.0 — Septiembre 2026

- **Cuentas**: nuevo sistema de cuentas de dinero (efectivo, banco, billeteras) con saldo propio; cada movimiento se registra desde una cuenta específica y se puede transferir entre bolsillos
- Migración automática del saldo histórico al crear la primera cuenta, para que el dinero registrado antes de esta función no desaparezca
- Advertencia de fondos insuficientes al registrar un gasto que dejaría una cuenta en negativo
- Resumen "Dónde está tu dinero" en el dashboard, con acceso directo para agregar o editar cuentas
- Categorías personalizadas con selector de ícono propio
- Exportación de movimientos a Excel y PDF con la marca Monedo
- Historial de aportes por meta: al tocar una meta se ve la fecha y el monto de cada abono, con el nombre de la meta en el encabezado
- Onboarding reordenado: bienvenida y tour explicativo antes de crear la cuenta de usuario; selección de moneda y primeras cuentas de dinero justo después del registro
- Usuarios existentes sin moneda o cuentas configuradas reciben el mismo flujo de configuración una sola vez, al iniciar sesión
- Todas las notificaciones de la app (errores, validaciones, confirmaciones) migradas al sistema de toasts, reemplazando los SnackBar
- "Mis cuentas", "Mis categorías" y "Exportar datos" ahora se abren como ventana modal centrada en escritorio, en vez de pantalla completa
- Corregida la alineación entre los campos de Categoría y Fecha en Nuevo/Editar movimiento
- Corregido un desbordamiento visual en las tarjetas de cuentas del dashboard
- Ícono de Android con fondo blanco para que el logo resalte (antes se veía como un círculo verde sólido)
- Ícono de iPhone (acceso directo desde Safari) con el mismo tratamiento de fondo blanco; el favicon y los íconos de Android/Chrome conservan el diseño original
- Landing page: nuevas secciones de características (Cuentas y Transferencias, Multi-moneda, Exportar tus datos) y nuevos pasos en "Cómo funciona"
- Corregido texto que se salía del contenedor en la sección "Sobre Monedo" en pantallas angostas de Android

### v2.1.0 — Septiembre 2026

- Selector de moneda al registrarse (USD, COP, EUR, MXN, ARS, CLP, PEN, BRL, GBP); editable luego desde "Acerca de" y aplicado en tiempo real a toda la app, incluidas las pestañas ya abiertas
- Cuentas creadas antes de esta función eligen su moneda una única vez al iniciar sesión
- Onboarding con slides explicativos de cada sección (Dashboard, Transacciones, Estadísticas, Metas), con pasos numerados; se muestra una vez por dispositivo y siempre después de un registro nuevo
- Rediseño de Login y Register en móvil: héroe con blobs decorativos y logo, tarjeta inferior con campos rellenos y redondeados (antes solo un fondo verde con líneas)
- Ícono de Android adaptativo (fondo + logo), reemplazando el ícono cuadrado anterior
- Notificaciones tipo toast con animación de entrada/salida, arriba a la derecha en escritorio y arriba centradas en móvil
- Formato de miles en vivo en los campos de monto de Transacciones y Metas
- Sección "Próximamente" en la landing anunciando recomendaciones de optimización financiera con IA
- Corregido: el inicio de sesión ahora respeta el chequeo de moneda para cuentas existentes (antes solo se validaba al abrir la app por primera vez, no al iniciar sesión manualmente)
- Actualización de Gradle a 9.1.0 para compatibilidad con JDK 25

### v1.3.0 — Mayo 2026

- Landing page publica con secciones de características, paso a paso y footer con enlaces
- Redirección automática a landing en web cuando el usuario no tiene sesión activa
- Botones de edición y eliminación siempre visibles en TransactionTile en móvil
- Header del dashboard móvil actualizado con nombre de la app y tab activa más destacada
- Nuevo logo e iconos PWA / iOS actualizados
- Enlace a Ko-fi agregado en el footer de la landing

### v1.2.0 — Abril 2026

- Metas de ahorro — crea metas con nombre y monto objetivo, registra abonos y el saldo se descuenta automáticamente del balance, con porcentaje de progreso visual
- Formato de moneda con separador de miles (ejemplo: $69,308)
- Confirmación al cerrar sesión y al eliminar movimientos desde el dashboard
- Nueva categoría "Ocio" en la lista de gastos

### v1.1.0

- Corregido error de `setState()` called after dispose en el dashboard
- Resuelto conflicto de nombre entre Transaction de Firestore y el modelo propio, renombrado a TransactionModel
- Corregido CardTheme a CardThemeData para compatibilidad con Flutter 3.x
- Simplificadas las consultas de Firestore para evitar índices compuestos

### v1.0.0 — Abril 2026

- Dashboard con balance actual, ingresos y gastos del mes
- Registro de ingresos y gastos con categoría, fecha y nota opcional
- Edición y eliminación de movimientos
- Filtros por Todos, Ingresos y Gastos
- Estadísticas mensuales con selector de mes
- Gráfica de torta de gastos por categoría
- Estadísticas semanales
- Diseño responsive en Android y Web
- Autenticación y base de datos con Firebase

## Autor

Ericknvp  
Portafolio: [ericknvp-dev.vercel.app](https://ericknvp-dev.vercel.app)  
GitHub: [github.com/Ericknvp](https://github.com/Ericknvp)
