# flutter_recursos_notificaciones

Proyecto: flutter_recursos_notificaciones

Descripción
-
Aplicación de ejemplo en Flutter centrada en el manejo eficiente de recursos y la integración de notificaciones push. Este README detalla buenas prácticas para la gestión de recursos (imágenes, assets, memoria) y una guía profesional sobre notificaciones push usando Firebase Cloud Messaging (FCM) y herramientas nativas.

Tabla de contenidos
-
- Utilización de los recursos de la aplicación de forma adecuada
- Notificaciones push (configuración y buenas prácticas)
- Requisitos previos
- Recursos y enlaces útiles

## Requisitos previos
-
- Flutter instalado y configurado (stable channel recomendado)
- SDKs de Android / Xcode instalados y configurados para desarrollo nativo
- Cuenta de Firebase para configurar FCM si se quieren notificaciones push

## 1) Utilización de los recursos de la aplicación de forma adecuada
-
Objetivo: reducir consumo de memoria, mejorar tiempos de carga y evitar subir recursos innecesarios al repositorio.

- Organización y carga de assets
	- Coloca los recursos (imágenes, íconos, JSONs, fuentes) en `assets/` o en subcarpetas organizadas por funcionalidad.
	- Registra los assets en `pubspec.yaml` de forma granular para evitar empaquetar recursos no usados.
	- Usa SVG para iconografía cuando sea posible (`flutter_svg`) para reducir tamaño y mantener escalabilidad.

- Optimización de imágenes
	- Genera varias resoluciones (`1x`, `2x`, `3x`) para evitar reescalados costosos en tiempo de ejecución.
	- Comprime las imágenes (WebP para Android y JPEG/PNG optimizados) manteniendo la calidad visual.
	- Evita usar imágenes de gran resolución si no se mostrarán tan grandes en pantalla.

- Gestión de memoria y caché
	- Utiliza `Image.memory`/`Image.asset` con `cacheWidth`/`cacheHeight` cuando sea necesario para limitar el uso de memoria.
	- Considera paquetes como `cached_network_image` para descargas y cache de imágenes remotas.
	- Llama a `precacheImage` estratégicamente para evitar parpadeos y lecturas de disco en vistas frecuentes.

- Evita incluir ficheros pesados en el repo
	- No agregues vídeos o grandes binarios si no son necesarios; usa almacenamiento externo o descargas bajo demanda.

- Acceso a recursos remotos
	- Evita descargar grandes payloads en la apertura de la app; implementa paginación o carga bajo demanda.
	- Conviene comprimir peticiones si manejas datos voluminosos y habilitar cache HTTP (ETags/Cache-Control).

- Pruebas y monitorización
	- Perfila la app en dispositivos reales con `DevTools` y/o `flutter run --profile`.
	- Mide consumo de memoria y tiempos de carga de recursos.

## 2) Notificaciones push
-
Esta sección se centra en la integración con Firebase Cloud Messaging (FCM) y prácticas recomendadas para Android e iOS.

### 2.1 Resumen
-
Las notificaciones push permiten al servidor enviar mensajes a usuarios cuando la app no está activa. Para avanzar con FCM:

- Registra tu proyecto en Firebase.
- Agrega apps Android/iOS y descarga `google-services.json` y `GoogleService-Info.plist`.
- Añade las dependencias de `firebase_core` y `firebase_messaging` y configura las plataformas nativas.

### 2.2 Pasos de integración (resumen rápido)
-
1. Firebase
	 - Crea un proyecto Firebase.
	 - Añade la aplicación Android (package name) y la aplicación iOS (Bundle ID).
	 - Descarga y coloca `google-services.json` en `/android/app/`.
	 - Descarga y coloca `GoogleService-Info.plist` en `/ios/Runner/`.

2. Dependencias Flutter
	 - pubspec.yaml:
		 ```yaml
		 dependencies:
			 firebase_core: ^2.x
			 firebase_messaging: ^14.x
			 flutter_local_notifications: ^13.x # opcional para más control en local
		 ```

3. Configuración Android
	 - Asegúrate de tener `apply plugin: 'com.google.gms.google-services'` (Gradle) y el plugin de google-services en el `build.gradle` de nivel de app.
	 - Configura canales de notificación (Android 8+) para controlar importancia y comportamiento.

4. Configuración iOS
	 - Pide permisos de notificación al usuario (`UNUserNotificationCenter`) y agrega claves necesarias en `Info.plist`.
	 - Implementa el `AppDelegate` para manejar la conexión con APNs si usas FCM con APNs.

5. Inicialización en Flutter
	 - Inicializa Firebase en `main()` con `WidgetsFlutterBinding.ensureInitialized()` y `Firebase.initializeApp()`.
	 - Configura los handlers:
		 - `FirebaseMessaging.onMessage` (mensaje recibidos en foreground)
		 - `FirebaseMessaging.onMessageOpenedApp` (cuando el usuario abre desde la notificación)
		 - `FirebaseMessaging.onBackgroundMessage` (manejo en segundo plano - requiere top-level function)

6. Envío de notificaciones
	 - Desde servidor, usa los tokens de dispositivo o topics de Firebase para enviar mensajes (Admin SDK o REST API).
	 - Usa `data messages` cuando quieras manejar lógica arbitraria; usa `notification messages` para mostrar notificaciones directas.

### 2.3 Buenas prácticas y consideraciones
-
- Solicita permisos con contexto: explica por qué necesitas notificaciones y ofrece una experiencia de opt-in clara.
- Minimiza el uso de notificaciones para no molestar al usuario; segmenta y personaliza cuando sea relevante.
- Utiliza `notification channels` en Android para permitir una gestión granular de notificaciones por parte del usuario.
- Protege la clave del servidor (no exponer server key en clientes); envía desde tu backend con SMTP o Admin SDK.
- Administra tokens: renueva y registra los tokens en tu backend; borra los tokens inválidos cuando el envío falle.
- Considera usar topics o grupos para notificaciones de broadcast; controla el coste y la entrega eficiente.

### 2.4 Manejo de notificaciones en background y cold start
-
- Implementa `onBackgroundMessage` como función top-level en Dart para asegurar que la app procese mensajes en background.
- Registra lógica mínima en background (no ejecutes tareas largas sin usar isolates o trabajo nativo).

### 2.5 Pruebas y debugging
-
- Usa Firebase Console para enviar notificaciones de prueba.
- Revisa logs nativos y usa `adb logcat` en Android para ver la recepción y el comportamiento de notificaciones.
- Asegura que APNs y certificados de iOS estén configurados correctamente para producción.

## 3) Recursos y enlaces útiles
-
- Firebase Cloud Messaging (FCM): https://firebase.google.com/docs/cloud-messaging
- FlutterFire docs (firebase_messaging): https://firebase.flutter.dev/docs/messaging/overview
- flutter_local_notifications: https://pub.dev/packages/flutter_local_notifications
- Guía de optimización de imágenes: https://flutter.dev/docs/development/ui/assets-and-images

## 4) Notas finales
-
Mantén este README actualizado con los pasos de configuración específicos del proyecto (IDs de paquete, tokens de entorno, claves de API en CI) y evita subir archivos sensibles como `key.properties` o keystores al repositorio. Para preguntas específicas sobre la integración, crea issues y documenta la configuración de CI/CD si envías notificaciones desde backend.
