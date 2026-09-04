Aquí tienes un documento Markdown completo para una aplicación de generación de códigos QR **100% offline**, con el máximo de funcionalidades que no requieren conexión a internet. Está pensado para ser un producto autónomo, privado y totalmente funcional en el dispositivo.

---

# QRfri — Documento de Producto Completo

> Versión: 1.0  
> Fecha: 2026-09-01  
> Enfoque: **Aplicación offline-first** – Todas las funcionalidades principales operan sin conexión a internet.  
> Objetivo: Definir el producto completo para una app móvil que crea, personaliza, gestiona y escanea códigos QR de forma 100% local, sin depender de servidores ni cuentas obligatorias.

---

## 1. Resumen ejecutivo

**QRfri** es una aplicación móvil (iOS y Android) que permite a los usuarios crear códigos QR altamente personalizables y funcionales, **sin necesidad de conexión a internet**. Todos los datos se almacenan localmente en el dispositivo, garantizando privacidad total y funcionamiento en cualquier lugar. Incluye un amplio abanico de tipos de QR, un potente editor visual, biblioteca con organización, escáner integrado, historial y exportación en múltiples formatos. La experiencia se centra en la velocidad, la estética y la escaneabilidad, sin sacrificar la funcionalidad ni la seguridad.

La misión:  
> **Crear QR bonitos y útiles en cualquier momento y lugar, sin depender de la nube.**

---

## 2. Principios del producto

- **Offline total**: ninguna funcionalidad esencial requiere internet. La app funciona perfectamente en modo avión.
- **Privacidad absoluta**: los datos del usuario y los QR generados nunca salen del dispositivo (a menos que el usuario los exporte o comparta explícitamente).
- **Simplicidad y rapidez**: crear un QR en menos de 60 segundos, con flujos guiados e intuitivos.
- **Personalización sin límites**: colores, estilos, logos, marcos y plantillas, siempre garantizando la escaneabilidad.
- **Escaneabilidad garantizada**: validación automática de contraste y tamaño para que el QR funcione en cualquier lector.
- **Sostenibilidad**: sin costes de servidor, sin cuentas, sin dependencia externa. La app es un producto completo en sí misma.

---

## 3. Público objetivo

- **Usuarios individuales** que quieren compartir su contacto, Wi-Fi, enlaces o texto sin complicaciones.
- **Profesionales y freelancers** que necesitan tarjetas de presentación digitales y compartir información de forma rápida.
- **Pequeños negocios y comercios** que quieren mostrar menús, Wi-Fi, ubicación o WhatsApp sin depender de internet.
- **Organizadores de eventos** que necesitan generar entradas o información sin conexión.
- **Personas preocupadas por la privacidad** que no quieren almacenar sus datos en la nube.

---

## 4. Funcionalidades completas (todas offline)

### 4.1 Creación de QR

La app permite crear **todos los tipos de QR estáticos** que se pueden codificar directamente en el dispositivo, sin necesidad de un servidor intermedio. El contenido se incrusta en el propio QR, por lo que al escanearlo se obtiene la información directamente.

#### Tipos de QR soportados

| Tipo | Descripción | Prioridad |
|------|-------------|-----------|
| **Contacto / vCard** | Tarjeta de contacto completa (nombre, teléfono, email, empresa, foto, redes, etc.) | ⭐⭐⭐⭐⭐ |
| **URL / Enlace** | Cualquier dirección web. | ⭐⭐⭐⭐⭐ |
| **Wi-Fi** | Configuración de red inalámbrica (SSID, contraseña, seguridad). | ⭐⭐⭐⭐⭐ |
| **WhatsApp** | Chat directo con número y mensaje predefinido. | ⭐⭐⭐⭐⭐ |
| **Texto** | Texto libre, ideal para notas, contraseñas, etc. | ⭐⭐⭐⭐ |
| **Email** | Abre el cliente de correo con destinatario, asunto y cuerpo. | ⭐⭐⭐⭐ |
| **Teléfono** | Llama a un número directamente. | ⭐⭐⭐⭐ |
| **SMS** | Envía un mensaje de texto con número y contenido. | ⭐⭐⭐ |
| **Ubicación** | Coordenadas geográficas o dirección (abre el mapa). | ⭐⭐⭐⭐ |
| **Evento (vCalendar)** | Evento de calendario con fecha, lugar, descripción (compatible con ICS). | ⭐⭐⭐ |
| **Redes Sociales** | Página estática con enlaces a perfiles (se codifica como texto o vCard ampliada). | ⭐⭐⭐ |
| **Negocio** | Ficha de negocio con teléfono, dirección, web, horarios (vCard extendida). | ⭐⭐⭐ |
| **Criptomoneda** | Dirección de wallet (Bitcoin, Ethereum, etc.). | ⭐⭐ |
| **App Store / Play Store** | Enlaces de descarga de apps. | ⭐⭐ |
| **Calendario (ICS)** | Archivo de calendario embebido. | ⭐⭐ |
| **Geolocalización** | Coordenadas exactas para abrir en mapas. | ⭐⭐ |

**Nota:** Los QR dinámicos que requieren redirección a un servidor no están incluidos en esta versión offline, pues dependen de un backend. Sin embargo, la app puede exportar un QR estático que apunte a una URL configurable, dejando la puerta abierta a futuras integraciones opcionales.

#### Pantalla de creación
- Selección de tipo con iconos claros y descripción.
- Formularios dinámicos según el tipo, con validación local (URL, email, teléfono, etc.).
- Vista previa en tiempo real mientras se rellenan los datos.
- Botón de personalización rápida y guardado.

### 4.2 Personalización visual

Esta es una de las características diferenciales de la app. Todo el procesamiento se realiza localmente.

#### Colores
- Selector de color para **primer plano** (módulos) y **fondo**.
- Paletas predefinidas y personalizadas.
- Ajuste de opacidad.
- **Comprobación automática de contraste** basada en algoritmos de legibilidad de QR (relación de contraste mínima recomendada).

#### Estilos de módulos
- **Clásico**: cuadrados tradicionales.
- **Redondeado**: esquinas suaves.
- **Puntos**: módulos circulares.
- **Puntos redondeados**: círculos con bordes suaves.
- **Pixelado**: estilo retro.
- **Moderno**: formas mixtas y geométricas.
- Ajuste de tamaño de módulo y margen (zona de silencio).

#### Logo central
- Subir imagen desde galería o usar iconos predefinidos.
- Ajuste de tamaño con **límite de seguridad automático** (máx. 20-30% del área total).
- Opciones de forma: circular, cuadrado redondeado.
- Fondo blanco o transparente detrás del logo.

#### Marcos y textos
- Texto personalizado debajo o encima del QR (ej. "ESCANÉAME", "GUARDAR CONTACTO").
- Selección de fuente (incluye fuentes del sistema y opcionales descargables), tamaño, color, alineación.
- Marcos decorativos: bordes, esquinas redondeadas, sombras.
- **Plantillas completas** prediseñadas para diferentes usos (contacto, Wi-Fi, menú, etc.) que combinan estilo y texto.

#### Vista previa en tiempo real
- Renderizado inmediato del QR con todos los cambios.
- Posibilidad de simular el escaneo (usando la cámara del dispositivo en un modo de prueba).
- Zoom para verificar detalles.

### 4.3 Biblioteca y gestión de QR

- **Lista de QR creados** con miniaturas, nombre, tipo, fecha de creación.
- **Carpetas** para organizar (crear, renombrar, mover).
- **Etiquetas** personalizadas.
- **Búsqueda** por nombre, tipo o contenido.
- **Filtros** por tipo, fecha, etiqueta.
- **Acciones**: editar, duplicar, compartir, exportar, archivar, eliminar.
- **Favoritos** para acceso rápido.
- **Historial de creación** (últimos QR generados).
- **Modo de visualización**: lista o cuadrícula.
- **Almacenamiento local**: base de datos SQLite o similar, optimizada para rendimiento.

### 4.4 Compartir y exportar

- **Compartir imagen** (PNG, JPEG) directamente a otras apps (WhatsApp, Telegram, correo, etc.).
- **Exportar en múltiples formatos**:
  - PNG (alta resolución)
  - SVG (vectorial, ideal para impresión)
  - PDF (con o sin marco)
- **Tamaños de exportación**: 512×512, 1024×1024, 2048×2048, 4096×4096 px.
- **Copiar al portapapeles**: como imagen o como contenido (para pegar en otras apps).
- **Guardar en galería**.
- **Impresión directa** (si el dispositivo lo soporta).
- **Compartir contenido** (por ejemplo, la vCard como archivo .vcf, o el texto del Wi-Fi).
- **Exportar base de datos completa** (copia de seguridad en archivo local, opcionalmente a almacenamiento externo).

### 4.5 Escáner QR integrado

- **Escaneo con cámara** en tiempo real.
- **Detección automática** del tipo de contenido (URL, texto, vCard, Wi-Fi, etc.) y acción correspondiente.
- **Linterna** para baja iluminación.
- **Modo galería**: escanear QR desde una imagen guardada.
- **Corrección de errores**: compatible con QR dañados o parcialmente ocultos (niveles L, M, Q, H).
- **Historial de escaneos** (almacenado localmente, con opción de borrar).
- **Vista previa del resultado** y acciones contextuales:
  - Abrir URL (si hay conexión) o copiarla.
  - Agregar contacto (vCard) directamente a la agenda.
  - Conectarse a Wi-Fi (rellenar credenciales o copiarlas).
  - Llamar o enviar SMS.
  - Copiar texto.
  - Abrir ubicación en mapas.

### 4.6 Funciones adicionales

- **QR temporal** (con fecha de caducidad): se añade un texto de expiración al contenido o se marca visualmente (no impide el escaneo, pero informa).
- **QR protegido con contraseña**: se codifica un enlace a un texto cifrado (la contraseña debe compartirse por otro medio; el cifrado se hace localmente con AES).
- **Plantillas personalizadas**: guardar combinaciones de estilo como plantilla reutilizable.
- **Modo oscuro** en la interfaz.
- **Multilingüe**: español, inglés, portugués, francés, etc. (traducciones locales).
- **Accesibilidad**: etiquetas para lectores de pantalla, alto contraste en UI, tamaños de fuente ajustables.
- **Widgets** (Android/iOS): acceso rápido para crear tipos de QR frecuentes.
- **Accesos directos** (3D Touch / Long press): "Crear URL", "Crear contacto", etc.
- **Importar QR**: desde imagen (para editar o guardar) – solo si se puede decodificar el contenido.
- **Generador de contraseñas Wi-Fi** (para crear redes seguras).

### 4.7 Funciones que requieren internet (opcionales y no esenciales)

Aunque la app está diseñada para ser completamente offline, se pueden incluir **funciones opcionales** que solo se activen si el usuario tiene conexión, pero que no son necesarias para el funcionamiento principal:

- **Compartir en redes sociales** directamente (usa las apps instaladas, requiere conexión de datos).
- **Actualizaciones de la app** (a través de la tienda).
- **Soporte técnico** vía correo (requiere conexión).
- **Sincronización opcional con nube** (si el usuario decide activarla, pero no es obligatoria; se haría mediante exportación manual a Drive/iCloud).

---

## 5. Experiencia de usuario (UX)

### 5.1 Flujos principales

#### Flujo de creación (sin conexión)
1. Inicio → "Crear QR".
2. Seleccionar tipo.
3. Rellenar datos (validación local).
4. Ver vista previa y personalizar (color, estilo, logo, texto).
5. Guardar en biblioteca local.
6. Compartir / Exportar.

#### Flujo de escaneo
1. Pestaña "Escanear" → cámara.
2. Detección automática.
3. Mostrar resultado con acciones contextuales.
4. Guardar en historial (opcional).

#### Flujo de organización
1. Ir a "Mis QR".
2. Filtrar, buscar, mover a carpetas, etiquetar.
3. Acciones rápidas (editar, duplicar, exportar).

### 5.2 Navegación principal

Barra de navegación inferior con 4 pestañas:

- **Inicio** (crear y accesos rápidos)
- **Mis QR** (biblioteca)
- **Escanear**
- **Ajustes** (preferencias, plantillas, copia de seguridad)

### 5.3 Pantallas clave

#### Inicio
- Saludo y accesos directos a los tipos de QR más usados (URL, Contacto, Wi-Fi, WhatsApp, Texto).
- Últimos QR creados.
- Botón "Crear QR" grande.
- Acceso a plantillas.

#### Editor de QR
- Vista previa grande en la parte superior.
- Pestañas inferiores o superiores: **Datos**, **Diseño**, **Avanzado**.
- Botones flotantes: guardar, compartir, exportar.
- Opción de "vista previa a pantalla completa".

#### Mis QR
- Lista o cuadrícula con miniaturas.
- Barra de búsqueda y filtros.
- Menú contextual (editar, duplicar, eliminar, mover).

#### Escáner
- Cámara con overlay de enfoque.
- Botón de linterna.
- Botón para seleccionar imagen de galería.
- Historial de escaneos recientes debajo.

#### Ajustes
- Preferencias de apariencia (tema, idioma).
- Gestión de plantillas.
- Copia de seguridad (exportar/importar base de datos).
- Acerca de y ayuda.

### 5.4 Principios de diseño visual

- **Minimalismo y modernidad**: interfaz limpia, mucho espacio en blanco.
- **Colores neutros** con un acento configurable.
- **Tipografía**: Inter o similar, legible y elegante.
- **Iconografía clara**: iconos intuitivos para cada tipo de QR.
- **Feedback inmediato**: animaciones sutiles, confirmaciones táctiles.

---

## 6. Arquitectura técnica (100% local)

### 6.1 Plataforma y tecnologías

- **Framework**: Flutter (recomendado) o React Native. Flutter ofrece un excelente rendimiento para UI personalizada y generación de QR.
- **Lenguaje**: Dart (Flutter) o JavaScript/TypeScript (React Native).
- **Base de datos local**:
  - **SQLite** (a través de `sqflite` o `drift` en Flutter) para almacenar QR, carpetas, etiquetas, historial.
  - Alternativa: **Hive** (NoSQL) para datos más simples y rápidos.
- **Almacenamiento de archivos**: sistema de archivos del dispositivo (para imágenes, logos, exportaciones).
- **Generación de QR**:
  - Librerías Flutter: `qr_flutter`, `pretty_qr_code`, `qr` (para personalización avanzada).
  - Para exportación SVG/PDF, usar librerías de renderizado vectorial (`flutter_svg`, `pdf`).
- **Escaneo de QR**:
  - `mobile_scanner` (Flutter) o `google_ml_kit_barcode_scanning` para detección robusta.
- **Cifrado local**: para opción de QR protegido, usar `cryptography` (AES).
- **Sin backend**: no se requiere servidor. Todas las operaciones se realizan en el dispositivo.

### 6.2 Modelo de datos (entidades locales)

```dart
// Modelo QR
class QrCode {
  String id;              // UUID generado localmente
  String name;            // Nombre descriptivo
  QrType type;            // enum: url, contact, wifi, whatsapp, text, email, phone, sms, location, event, social, business, crypto, appstore, calendar
  Map<String, dynamic> content;  // Datos específicos del tipo
  QrStyle style;          // Estilo: colores, tipo de módulo, logo, texto, marco
  DateTime createdAt;
  DateTime updatedAt;
  bool isFavorite;
  String? folderId;       // carpeta opcional
  List<String> tags;      // etiquetas
  bool archived;
}

// Modelo Carpeta
class Folder {
  String id;
  String name;
  String? parentId;
  DateTime createdAt;
}

// Modelo Etiqueta
class Tag {
  String id;
  String name;
  String color;
}

// Modelo Escaneo (historial)
class ScanHistory {
  String id;
  String content;         // Contenido decodificado
  QrType? type;
  DateTime scannedAt;
  bool isFavorite;
}

// Modelo Plantilla
class Template {
  String id;
  String name;
  QrType? type;           // opcional, puede ser genérica
  QrStyle style;
  DateTime createdAt;
}
```

### 6.3 Estructura del proyecto (Flutter)

```
lib/
├── main.dart
├── core/
│   ├── theme/
│   ├── utils/
│   ├── widgets/
│   └── constants/
├── features/
│   ├── qr_creation/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   ├── qr_library/
│   ├── qr_scanner/
│   ├── settings/
│   └── backup/
└── local_database/
    ├── database_helper.dart
    └── migrations/
```

### 6.4 Persistencia y copia de seguridad

- Toda la información se guarda en SQLite local.
- El usuario puede **exportar una copia de seguridad** en un archivo `.json` o `.db` que incluye todos los QR, carpetas, plantillas, historial, etc.
- Puede **importar** esa copia en otro dispositivo o después de reinstalar.
- Opcionalmente, el usuario puede guardar la copia en almacenamiento externo (Google Drive, iCloud) manualmente, pero no es automático.

### 6.5 Rendimiento

- La generación de QR se realiza en un hilo separado para no bloquear la UI (usar `compute` en Flutter).
- La base de datos está indexada para búsquedas rápidas.
- Las imágenes de logos se redimensionan y comprimen antes de incrustarse.
- El escáner utiliza el procesamiento de imágenes del dispositivo con optimización de batería.

---

## 7. Roadmap

### Versión 1.0 – MVP Offline
- Creación de QR: URL, Contacto, Wi-Fi, WhatsApp, Texto, Email, Teléfono, Ubicación.
- Personalización básica: colores, estilo redondeado/clásico, logo, texto inferior.
- Biblioteca local con carpetas.
- Escáner integrado.
- Exportación PNG y compartir.

### Versión 1.1 – Mejoras de personalización
- Más estilos de módulos (puntos, pixelado, etc.).
- Marcos decorativos y plantillas.
- Importar/exportar base de datos.
- Widgets y accesos directos.

### Versión 1.5 – Funciones avanzadas
- Eventos (vCalendar), Redes Sociales, Negocio.
- QR protegido con contraseña.
- Modo oscuro.
- Multilingüe completo.

### Versión 2.0 – Pulido y extras
- Edición avanzada de SVG.
- Soporte para impresión directa.
- Integración con calendario y contactos del sistema.
- Posible módulo opcional de sincronización (solo bajo demanda, nunca automático).

---

## 8. Métricas de éxito (sin analítica en servidor)

Como la app es offline, las métricas se basan en el uso local y encuestas opcionales:

- **Tiempo promedio de creación de un QR** (medido localmente y reportado de forma anónima si el usuario lo permite).
- **Número de QR creados por usuario**.
- **Porcentaje de usuarios que usan personalización**.
- **Retención** (a través de la tienda de aplicaciones).
- **Valoraciones en la tienda**.
- **Comentarios de usuarios**.

El criterio de éxito: que un usuario pueda crear, personalizar y compartir un QR en menos de 60 segundos sin conexión, y que la app sea recomendada por su facilidad y privacidad.

---

## 9. Conclusión

**QRfri** es una aplicación completa, privada y autónoma que cubre todas las necesidades de generación y escaneo de códigos QR sin depender de internet. Su enfoque en la personalización, la velocidad y la escaneabilidad la convierte en una herramienta imprescindible para cualquier usuario que valore el control total de sus datos y la disponibilidad en cualquier situación.

Al eliminar la dependencia de servidores, se reducen costes, se mejora la privacidad y se garantiza un funcionamiento eterno. Es el producto ideal para quienes buscan una solución QR robusta, bonita y 100% offline.
