# Auditoría de localización de QRfri

## Sistema base

- `lib/localization.dart` contiene las claves estables para español, inglés, portugués, francés, chino simplificado, alemán, japonés, coreano, italiano y ruso.
- `QrFriLocalizations.delegate` se registra junto a los delegados Material, Widgets y Cupertino.
- `LocalStore.languageCode` persiste el idioma en `SharedPreferences`.
- `Ajustes > Idioma` cambia el locale global sin reiniciar la aplicación y muestra una bandera emoji por idioma.
- Las claves del catálogo actual tienen traducciones para los diez idiomas soportados; las ayudas nuevas sin entrada usan un mensaje contextual en el idioma activo.
- `QrFriLocalizations.t()` admite fallback explícito para incorporar nuevos idiomas de forma gradual.
- Auditoría estática: todas las claves usadas por `main.dart`, `design_system.dart` y el tutorial existen en el catálogo; no hay claves visibles sin traducción para los diez idiomas soportados.
- Wi-Fi, WhatsApp y SMS incluyen etiquetas de tipo, campos, ayuda, acciones del lector y mensajes de resultado en cada idioma. Wi-Fi y SMS usan términos locales cuando corresponde (por ejemplo, `Беспроводная сеть`, `СМС`, `无线网络`, `無線LAN` y `와이파이`); WhatsApp usa nombres adaptados en chino, japonés, coreano y ruso, sin alterar la marca del contenido técnico. Los prefijos (`WIFI:`, `https://wa.me`, `SMS:`/`SMSTO:`) se conservan para mantener la compatibilidad entre lectores.

## Componentes revisados

| Área | Estado | Cobertura |
| --- | --- | --- |
| Navegación inferior | Migrada | Inicio, Mis QR, Escanear y Ajustes |
| Inicio | Migrada | Encabezados, acción principal, accesos rápidos y estado vacío |
| Mis QR | Migrada | Vista lista/cuadrícula, búsqueda, filtros, contador y etiquetas de tipo |
| Accesos rápidos | Migrada | Título, descripción, guardar, quitar, añadir y tipos |
| Escáner | Migrada | Título, importar imagen, linterna, permiso, resultados y errores |
| Ajustes | Migrada | Tema, idioma, tutorial, copia de seguridad y restauración |
| Ayuda de creación | Migrada | Título, introducción, campos y ayuda específica por tipo |
| Editor de QR | Migrada | Campos, etiquetas y mensajes específicos por tipo |
| Diseño avanzado | Migrada | Colores, formas, logo, plantillas y exportación |
| Lectura en pantalla | Migrada | Estados, acciones y mensajes específicos |
| Detalle y exportación | Migrada | Acciones, formato, confirmaciones y errores específicos |

## Regla para nuevos textos

1. Añadir una clave semántica a `_values` en `localization.dart`.
2. Usar `context.qrL10n.t('clave')` desde widgets con `BuildContext`.
3. Para nombres de tipos usar `context.qrL10n.typeLabel(type)`.
4. No introducir nuevos textos visibles como literales si tienen una traducción configurable.
5. Mantener el texto recibido del usuario, el contenido del QR y nombres guardados sin traducir.

La auditoría cubre los textos visibles de las pantallas y componentes principales. Los valores introducidos por el usuario, el contenido del QR, nombres guardados y formatos de archivo se conservan sin traducir. La tabla admite nuevos idiomas sin modificar almacenamiento, generación QR ni navegación.
