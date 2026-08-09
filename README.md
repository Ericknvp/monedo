# Monedo

Aplicación de finanzas personales desarrollada con Flutter, orientada a la gestión de ingresos, gastos, metas de ahorro y control financiero diario. Disponible en Android y Web.

## Descripción

Monedo permite registrar y visualizar movimientos financieros de forma clara e intuitiva, ayudando a tomar mejores decisiones sobre el dinero. Incluye estadísticas visuales, metas de ahorro y una landing page pública que presenta la aplicación a nuevos usuarios. Proximamente, recomendaciones de reducción de gastos con IA y estadística inferencial.

## Tecnologías

- Flutter / Dart
- Firebase Firestore
- Firebase Auth
- Firebase Hosting
- Android Studio

## Funcionalidades

- Registro de ingresos y gastos con categoría, fecha y nota opcional
- Edición y eliminación de movimientos
- Filtros por tipo: Todos, Ingresos, Gastos
- Balance actual con desglose mensual de ingresos y gastos
- Estadísticas mensuales con selector de mes
- Gráfica de torta de gastos por categoría
- Estadísticas semanales
- Metas de ahorro con progreso visual y descuento automático del balance
- Formato de moneda con separador de miles
- Confirmación antes de cerrar sesión y al eliminar movimientos
- Landing page pública con presentación de características y sección "Cómo funciona"
- Redirección automática a landing en web cuando no hay sesión activa
- Pantalla "Acerca de" con información del creador y enlaces externos
- Diseño responsive — funciona en Android y Web
- Soporte PWA con favicon e iconos de aplicación personalizados

## Paleta de colores

La interfaz utiliza Material Design 3 con una paleta azul petróleo / verde esmeralda sobre fondo claro.

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

## Descargar APK

[Descargar Monedo v1.0](https://github.com/Ericknvp/monedo/releases/tag/v1.0)

## Changelog

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
