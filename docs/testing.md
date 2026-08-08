# Estrategia de pruebas

Stronger combina cuatro niveles de validación:

| Nivel | Objetivo | Ejecución |
|---|---|---|
| Unitarios | Modelos, cálculos, validaciones y formateo seguro | `flutter test` |
| Widgets y flujos | Estados, navegación y operaciones completas con dobles controlados | `flutter test` |
| Reglas | Autorización real de Firestore entre usuarios | Firebase Emulator Suite |
| E2E Android | Ciclo de vida completo con Auth y Firestore reales en emuladores | `integration_test` |

## Cobertura E2E

El escenario de `integration_test/app_test.dart` recorre mediante la interfaz:

1. Registro, cierre de sesión y nuevo inicio de sesión.
2. Creación y edición de un ejercicio personalizado.
3. Uso del ejercicio en un entrenamiento, edición y borrado del entrenamiento.
4. Borrado del ejercicio personalizado.
5. Creación, edición y borrado de una medición corporal.
6. Eliminación de cuenta y verificación de que desaparecen Auth, documentos de
   usuario, entrenamientos, mediciones, fatiga, ejercicios y datos locales.

## Aislamiento y seguridad

Los E2E nunca deben utilizar producción:

- `USE_FIREBASE_EMULATORS=true` obliga a comprobar que Auth y Firestore
  responden localmente antes de iniciar la aplicación.
- App Check y el análisis de fatiga mediante IA no se ejecutan en este modo.
- Firestore desactiva la persistencia local durante la prueba.
- Android usa el paquete separado `com.marwix127.stronger.e2e`, activado con la
  propiedad Gradle `E2E`; no comparte datos con la aplicación personal.
- Auth y Firestore se vacían al empezar; la cuenta y los documentos temporales
  vuelven a eliminarse al final del recorrido.

## Ejecución local en Android

Requisitos: Flutter 3.44 (la versión usada en CI), Java 21, Node.js 24, Android
SDK y un móvil con instalación USB habilitada o un emulador Android iniciado.
Firebase CLI se ejecuta mediante `npx`, por lo que no requiere instalación
global.

### Móvil físico

Conecta los puertos del dispositivo al equipo:

```bash
adb reverse tcp:8080 tcp:8080
adb reverse tcp:9099 tcp:9099
```

PowerShell:

```powershell
$env:ORG_GRADLE_PROJECT_E2E = 'true'
$env:GRADLE_OPTS = '-DE2E=true'
npx --yes firebase-tools@15.17.0 emulators:exec --only auth,firestore --project stronger-f7c9c `
  'flutter test integration_test/app_test.dart -d DEVICE_ID --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.2'
```

Bash:

```bash
export ORG_GRADLE_PROJECT_E2E=true
export GRADLE_OPTS=-DE2E=true
npx --yes firebase-tools@15.17.0 emulators:exec \
  --only auth,firestore --project stronger-f7c9c \
  'flutter test integration_test/app_test.dart -d DEVICE_ID --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.2'
```

En un móvil físico se usa `127.0.0.2` para evitar que el SDK Android transforme
`127.0.0.1` en la dirección especial de los emuladores Android. En teléfonos
Xiaomi/MIUI también puede ser necesario habilitar **Instalar mediante USB** en
las opciones de desarrollador y aceptar el aviso mostrado al instalar.

### Emulador Android

El emulador accede al equipo anfitrión mediante `10.0.2.2`, por lo que no
necesita reglas `adb reverse`. Se utilizan las mismas variables Gradle y el
mismo comando anterior, sustituyendo la definición del host por:

```text
--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

## Integración continua

El workflow `.github/workflows/ci.yml` levanta un Android Emulator aislado,
accede a Firebase Emulator Suite mediante `10.0.2.2` y ejecuta el mismo
escenario. No necesita credenciales ni secretos de Firebase. Si el recorrido
falla, conserva la salida de Flutter y de los emuladores en el artefacto
`android-e2e-diagnostics`.
