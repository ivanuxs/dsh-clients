# Cliente Android (TWA)

Genera un APK real para tu servidor DSH usando una **TWA** (*Trusted Web
Activity*) construida con [Bubblewrap](https://github.com/GoogleChromeLabs/bubblewrap).

Una TWA no es un WebView: usa el motor de **Chrome** y **comparte su
almacenamiento**, así que hereda la sesión del navegador. Bien configurada, la
app abre tu DSH a pantalla completa, **sin barra de direcciones y sin pedir
credenciales**.

## Requisitos

| Pieza | Detalle |
|---|---|
| Node | 18 o superior; Bubblewrap se usa con `npx`, sin instalar global |
| JDK | **17** (el 25 no sirve para el Gradle/AGP que usa Bubblewrap) |
| Android SDK | Con `build-tools`, `platforms;android-35` o superior, `platform-tools` |
| `ANDROID_HOME` | Exportado, o Bubblewrap te preguntará la ruta |

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
npx @bubblewrap/cli doctor     # tiene que decir que las rutas son válidas
```

## 1. Generar la configuración

```bash
./configurar.sh --host mi-servidor.example --id com.miempresa.asistente
```

Escribe en `./salida/` el `twa-manifest.json` (sin keystore), el
`manifest.webmanifest`, la plantilla de `assetlinks.json`, el fragmento de Nginx
y los iconos. Añade `--nombre`, `--corto`, `--color` y `--icono` si quieres
cambiar el texto, el color o el icono.

## 2. Crear el keystore (una sola vez)

```bash
keytool -genkeypair -v -keystore mi.keystore -alias dsh \
        -keyalg RSA -keysize 2048 -validity 10000
```

**Guárdalo bien y no lo publiques.** Si lo pierdes, no podrás actualizar la app
en Google Play nunca más. La contraseña, en un archivo aparte con permisos
`600`, nunca en el repositorio.

## 3. Publicar la huella en el sitio

```bash
keytool -list -v -keystore mi.keystore -alias dsh -J-Duser.language=en | grep SHA256
```

Copia la huella (en mayúsculas, con `:`; también vale en minúsculas y sin `:`)
en `salida/pwa/assetlinks.json`, sustituyendo el texto de relleno. Sube la
carpeta `pwa/` al servidor, publica las rutas con el fragmento de Nginx y
comprueba que responde **sin autenticación**:

```bash
curl -s https://mi-servidor.example/.well-known/assetlinks.json
```

Son tres rutas públicas: `/.well-known/assetlinks.json`,
`/manifest.webmanifest` y `/pwa/`. Si el verificador no las alcanza, la app abre
**con barra de direcciones**.

## 4. Compilar

```bash
npx @bubblewrap/cli init --manifest salida/twa-manifest.json
cd salida
./gradlew assembleRelease      # APK firmado, para instalar a mano
./gradlew bundleRelease        # AAB, para Google Play
```

Bubblewrap pedirá la contraseña del keystore al firmar.

## 5. La condición que casi nadie documenta: la cookie de sesión

Para que la app arranque **sin pedir credenciales**, la cookie de sesión de DSH
tiene que llegar al navegador como `SameSite=Lax`.

DSH la emite como `SameSite=Strict`, y Chromium **retiene las cookies `Strict`
cuando la navegación la lanza otra aplicación**, que es justo lo que hace la TWA
al abrirse: la app pide `/` y el servidor responde 401. En Nginx se corrige con
una línea, dentro del `server` de 443:

```nginx
proxy_cookie_flags ~ samesite=lax;
```

Se elige `Lax` y **no** `None` a propósito: con `Lax` la cookie solo viaja en
navegaciones de nivel superior (GET), así que otro sitio no puede lanzar
peticiones contra la API.

Lo mismo ocurre si abres la URL con token desde `adb` o desde un QR: sin esa
línea, 401 aunque todo lo demás esté bien.

## Trampas que ya nos costaron tiempo

- **`minSdkVersion`**: la plantilla de Bubblewrap 1.27 genera `21`, pero
  `androidbrowserhelper:2.7.4` exige **24**. Súbelo en `twa-manifest.json` **y**
  en `app/build.gradle` (el valor está literal en los dos sitios).
- **El `applicationId` por defecto añade `.twa`.** Escríbelo a mano; si no,
  no coincide con el `assetlinks.json` publicado y el vínculo no se verifica.
- **`manifest-checksum.txt`**: si editas el `twa-manifest.json`, hay que
  **regenerarlo** (es un SHA-1 de su contenido) o el siguiente `build` se queda
  preguntando si aplicar los cambios:
  ```bash
  node -e "const c=require('crypto'),fs=require('fs');fs.writeFileSync('manifest-checksum.txt',c.createHash('sha1').update(fs.readFileSync('twa-manifest.json')).digest('hex'))"
  ```
- **Nunca lances un comando interactivo con `| tail`**: esconde las preguntas y
  el proceso parece colgado para siempre. Usa `comando > /tmp/log 2>&1` y lee el
  registro aparte.
- **`keytool` en español revienta** al imprimir certificados
  (`MissingFormatArgumentException`): añade `-J-Duser.language=en`.
- **Si algún día publicas en Play**: se sube el **AAB**, y Google firma con su
  propia clave (*Play App Signing*). Entonces hay que añadir **su** huella SHA-256
  a `assetlinks.json`, en la **misma** entrada que la actual, con las dos
  huellas en la lista. Si pones solo una, una de las dos versiones abre con barra
  de direcciones.

## Comprobar que el vínculo está verificado

```bash
adb shell pm get-app-links com.miempresa.asistente
```

Debe aparecer `verified` con la huella de tu keystore.
