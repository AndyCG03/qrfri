# QRfri

QRfri es una aplicación Flutter para crear, personalizar, guardar y escanear códigos QR sin depender de una cuenta ni de un servidor. El contenido y la biblioteca se mantienen localmente en el dispositivo.

## Funcionalidades

- Creación de QR para enlaces, texto, Wi-Fi, contacto, WhatsApp, email, teléfono, SMS, ubicación, eventos, redes sociales, negocios, criptomonedas y tiendas de aplicaciones.
- Vista previa inmediata mientras se editan los datos.
- Personalización de módulos cuadrados o circulares.
- Personalización de los ojos del QR con forma cuadrada o circular y color independiente.
- Colores de módulos y fondo mediante paleta o código hexadecimal.
- Degradados, zona tranquila, corrección de errores y fondo transparente.
- Logo central opcional con tamaño, máscara, fondo y borde configurables.
- Biblioteca local con búsqueda, favoritos, filtros, ordenación y vista de lista o cuadrícula.
- La vista elegida en `Mis QR` (lista o cuadrícula) se guarda y se restaura al volver a abrir la aplicación.
- Escáner QR integrado.
- Copia de seguridad y restauración mediante archivos JSON locales.
- Tema claro y oscuro.
- Idioma configurable mediante una capa de localización extensible.

## Comportamiento visual del QR

El renderizado usa `qr_flutter`. Los módulos se configuran mediante `QrDataModuleStyle` y los ojos mediante `QrEyeStyle`. No se utiliza `foregroundColor`, porque ese parámetro puede sobrescribir el color independiente de los ojos.

Los textos situados encima o debajo del QR fueron retirados del editor y del renderizado. Los campos antiguos se conservan en el modelo y en los datos serializados únicamente para mantener compatibilidad con QR creados anteriormente; no se muestran ni se dibujan.

## Estructura del proyecto

```text
lib/
  main.dart             Pantallas, modelos, almacenamiento local y renderizado QR
  design_system.dart    Tema, colores y componentes visuales compartidos
  localization.dart     Claves, traducciones y delegado de idiomas
LOCALIZATION_AUDIT.md   Inventario de pantallas y estado de migración de textos
assets/                 Imágenes y animaciones de la aplicación
screen_tutorial_flutter/ Tutorial inicial incluido como dependencia local
test/                   Pruebas de widgets
android/                Proyecto Android generado por Flutter
```

## Requisitos

- Flutter compatible con Dart SDK `^3.10.7`.
- Android Studio y un SDK de Android para compilar en Android.
- Xcode para compilar en iOS o macOS.
- Visual Studio con las herramientas de escritorio para Windows.

## Uso local

Instala las dependencias con Flutter y abre el proyecto en Android Studio, VS Code o IntelliJ. Selecciona un dispositivo o emulador y ejecuta la aplicación desde el IDE.

Para una compilación de distribución, usa el comando de Flutter correspondiente a la plataforma objetivo, por ejemplo Android APK, Android App Bundle, iOS, macOS o Windows.

## Datos y privacidad

QRfri no necesita una cuenta ni un backend. La biblioteca se guarda con `SharedPreferences` y las copias de seguridad se generan como archivos JSON en el almacenamiento de documentos de la aplicación. El usuario decide cuándo exportar o compartir un contenido.

Los permisos de cámara y acceso a archivos solo son necesarios para escanear códigos o seleccionar logos y copias de seguridad.

Las copias de seguridad se validan completas antes de reemplazar la biblioteca. Si el JSON está dañado o no contiene una lista válida de QR, la operación se cancela sin borrar los datos existentes.

## Pruebas y calidad

La prueba existente valida la pantalla inicial y el acceso principal para crear un QR. Antes de publicar una versión, conviene ejecutar el análisis estático y las pruebas de Flutter desde un entorno de desarrollo configurado.

## Publicación en Git

El archivo `.gitignore` excluye artefactos generados, cachés, configuraciones locales, archivos de IDE, logs y credenciales de firma. Se deben subir el código fuente, `pubspec.yaml`, `pubspec.lock`, los assets, las carpetas de plataforma necesarias y las pruebas. No se deben subir claves, contraseñas, archivos `.env` reales ni respaldos con datos personales.

## Licencia

No se ha definido una licencia de distribución en este proyecto. Añade una licencia antes de publicar el repositorio o distribuir la aplicación fuera de tu equipo.

## Prueba de lectura y acciones

La opción **Probar lectura** analiza una captura del QR que está en pantalla; no abre la cámara. Después de leerlo muestra el tipo detectado y el texto completo. El botón contextual permite abrir enlaces, WhatsApp, email, teléfono, SMS, ubicaciones y criptomonedas mediante la aplicación del sistema. Los contactos (`vCard`) y eventos (`VEVENT`) se comparten como archivos para que el usuario elija la aplicación que los importará. Wi-Fi y texto se pueden copiar directamente.

## Avisos y confirmaciones

Todos los SnackBar usan el componente `showQrToast`, con estados de información, éxito, advertencia y error, contraste para tema claro y oscuro, icono, duración y posición consistentes. Las confirmaciones destructivas usan `showQrConfirmation` y el color rojo solo para eliminar. Las operaciones asíncronas muestran éxito únicamente después de completarse; los fallos muestran un aviso de error.

## Edicion de codigos existentes

Al editar un QR guardado, QRfri interpreta el contenido serializado y vuelve a llenar los campos del formulario. Se soportan URL, contactos vCard y MECARD, Wi-Fi, WhatsApp, email, teléfono, SMS, ubicación, eventos, redes sociales, negocios, criptomonedas, tiendas y texto. Al guardar se genera una sola representación normalizada para evitar repetir líneas o valores.

## Exportacion

Desde el detalle de cualquier QR, el botón `Exportar` permite seleccionar corrección, calidad (512, 1024, 2048 o 4096 px) y formato PNG, JPG o PDF. El archivo se genera desde la vista personalizada actual y se comparte después de escribirse correctamente. PNG conserva transparencia; JPG y PDF usan fondo blanco para evitar zonas negras.

## Ayuda al crear

En la pantalla `Crear QR` o `Editar QR`, el icono de ayuda de la barra superior explica qué dato corresponde a cada campo del tipo seleccionado. Las indicaciones cubren enlaces, contactos, Wi-Fi, mensajería, ubicaciones, eventos, redes sociales, negocios, criptomonedas, tiendas y texto.

## Idiomas

La clase `QrFriLocalizations` centraliza las claves traducibles y el delegado de Flutter. QRfri permite seleccionar Español, English, Português, Français, 中文 (chino simplificado), Deutsch, 日本語, 한국어, Italiano y Русский. Las pantallas, controles, tipos de QR, mensajes, ayuda de campos y tutorial tienen traducciones nativas para estos idiomas. El idioma se guarda en las preferencias locales (`languageCode`) y se puede cambiar desde `Ajustes > Idioma`; si el sistema usa un idioma no compatible, se selecciona English. Para añadir otro idioma se agrega una entrada a la tabla de claves y a `supported` sin modificar la lógica de almacenamiento o navegación.

La auditoría cubre la navegación inferior, inicio, biblioteca, accesos rápidos, ajustes, permisos del escáner, etiquetas de tipos de QR, ayuda contextual, tutorial y mensajes de copias de seguridad. Las claves nuevas pueden usar un fallback explícito mientras se incorporan al catálogo, sin afectar a los idiomas ya disponibles.
