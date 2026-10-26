#!/usr/bin/env bash
#
# Genera la configuracion de una app Android (TWA) para TU servidor DSH.
#
# QUE HACE
#   Escribe, en la carpeta de salida:
#     twa-manifest.json          manifiesto de Bubblewrap, sin keystore
#     pwa/manifest.webmanifest   manifest web que hay que servir en el sitio
#     pwa/assetlinks.json        plantilla de Digital Asset Links (falta la huella)
#     pwa/nginx-pwa.conf         fragmento de Nginx que publica las rutas
#     pwa/icon-*.png             iconos de la app
#
#   NO compila nada y NO toca ningun servidor: solo escribe archivos.
#
# USO
#   ./configurar.sh --host mi-servidor.example --id com.miempresa.asistente
#   ./configurar.sh --host mi-servidor.example --id com.miempresa.asistente \
#                   --nombre "Mi Asistente" --corto Asistente \
#                   --color "#0B1424" --icono /ruta/a/mi-icono.png \
#                   --salida ./salida
#
#   --host     dominio del servidor DSH (obligatorio, sin https://)
#   --id       applicationId de Android (obligatorio, con al menos un punto)
#   --nombre   nombre de la app (por defecto: "DSH")
#   --corto    nombre bajo el icono (por defecto: el mismo)
#   --color    color de tema, en hexadecimal (por defecto: #0B1424)
#   --icono    PNG cuadrado de al menos 512 px (por defecto: ../icono/icono-512.png)
#   --salida   carpeta donde escribir (por defecto: ./salida)
#
set -euo pipefail

AQUI="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

HOST=""
ID=""
NOMBRE="DSH"
CORTO=""
COLOR="#0B1424"
ORIGEN_ICONO=""
SALIDA="./salida"

USO() {
  sed -n '3,32p' "$AQUI/configurar.sh" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --id) ID="${2:-}"; shift 2 ;;
    --nombre) NOMBRE="${2:-}"; shift 2 ;;
    --corto) CORTO="${2:-}"; shift 2 ;;
    --color) COLOR="${2:-}"; shift 2 ;;
    --icono) ORIGEN_ICONO="${2:-}"; shift 2 ;;
    --salida) SALIDA="${2:-}"; shift 2 ;;
    -h|--help) USO; exit 0 ;;
    *) echo "ERROR: opcion desconocida: $1" >&2; USO >&2; exit 1 ;;
  esac
done

# --- Validaciones -----------------------------------------------------------
if [[ -z "$HOST" || -z "$ID" ]]; then
  echo "ERROR: faltan --host y/o --id." >&2
  echo >&2
  USO >&2
  exit 1
fi
if [[ "$HOST" == http*://* ]]; then
  echo "ERROR: --host va SIN esquema: 'mi-servidor.example', no 'https://...'." >&2
  exit 1
fi
if [[ ! "$HOST" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]]; then
  echo "ERROR: --host no parece un dominio valido: $HOST" >&2
  exit 1
fi
if [[ ! "$ID" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]; then
  echo "ERROR: --id no parece un applicationId valido: $ID" >&2
  echo "       Tiene que ir en minusculas y con al menos un punto." >&2
  echo "       OJO: Bubblewrap anade '.twa' por su cuenta si no lo escribes tu," >&2
  echo "       y entonces no coincide con el assetlinks.json publicado." >&2
  exit 1
fi
if [[ ! "$COLOR" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  echo "ERROR: --color tiene que ser hexadecimal de 6 digitos, como #0B1424." >&2
  exit 1
fi
if [[ -z "$CORTO" ]]; then
  CORTO="$NOMBRE"
fi

# --- Iconos -----------------------------------------------------------------
mkdir -p "$SALIDA/pwa"

if [[ -n "$ORIGEN_ICONO" ]]; then
  if [[ ! -f "$ORIGEN_ICONO" ]]; then
    echo "ERROR: no existe el icono $ORIGEN_ICONO" >&2
    exit 1
  fi
  if command -v magick >/dev/null 2>&1; then
    REDIM=magick
  elif command -v convert >/dev/null 2>&1; then
    REDIM=convert
  else
    echo "ERROR: para usar --icono hace falta ImageMagick (magick o convert)." >&2
    exit 1
  fi
  "$REDIM" "$ORIGEN_ICONO" -resize 512x512 "$SALIDA/pwa/icon-512.png"
  "$REDIM" "$ORIGEN_ICONO" -resize 192x192 "$SALIDA/pwa/icon-192.png"
  "$REDIM" "$ORIGEN_ICONO" -resize 512x512 "$SALIDA/pwa/icon-maskable-512.png"
else
  BASE="$AQUI/../icono"
  for par in "icono-512.png:icon-512.png" "icono-192.png:icon-192.png" "icono-maskable-512.png:icon-maskable-512.png"; do
    origen="$BASE/${par%%:*}"
    destino="$SALIDA/pwa/${par##*:}"
    if [[ ! -f "$origen" ]]; then
      echo "ERROR: falta $origen" >&2
      echo "       Genera los PNG con: ../icono/generar.sh" >&2
      exit 1
    fi
    cp "$origen" "$destino"
  done
fi

# --- twa-manifest.json ------------------------------------------------------
# NO lleva "signingKey": el keystore y su contrasena no se publican. Bubblewrap
# lo pide (o lo crea) al ejecutar 'init --manifest'.
cat > "$SALIDA/twa-manifest.json" <<JSON
{
  "packageId": "$ID",
  "host": "$HOST",
  "name": "$NOMBRE",
  "launcherName": "$CORTO",
  "display": "standalone",
  "themeColor": "$COLOR",
  "themeColorDark": "$COLOR",
  "navigationColor": "$COLOR",
  "navigationColorDark": "$COLOR",
  "navigationDividerColor": "$COLOR",
  "navigationDividerColorDark": "$COLOR",
  "backgroundColor": "$COLOR",
  "enableNotifications": true,
  "startUrl": "/",
  "iconUrl": "https://$HOST/pwa/icon-512.png",
  "maskableIconUrl": "https://$HOST/pwa/icon-maskable-512.png",
  "splashScreenFadeOutDuration": 300,
  "appVersionName": "1",
  "appVersionCode": 1,
  "shortcuts": [],
  "generatorApp": "bubblewrap-cli",
  "webManifestUrl": "https://$HOST/manifest.webmanifest",
  "fallbackType": "customtabs",
  "features": {},
  "alphaDependencies": {
    "enabled": false
  },
  "enableSiteSettingsShortcut": true,
  "isChromeOSOnly": false,
  "isMetaQuest": false,
  "fullScopeUrl": "https://$HOST/",
  "minSdkVersion": 24,
  "orientation": "any",
  "fingerprints": [],
  "additionalTrustedOrigins": [],
  "retainedBundles": [],
  "protocolHandlers": [],
  "fileHandlers": [],
  "launchHandlerClientMode": "",
  "displayOverride": [],
  "appVersion": "1"
}
JSON

# --- manifest web -----------------------------------------------------------
cat > "$SALIDA/pwa/manifest.webmanifest" <<JSON
{
  "name": "$NOMBRE",
  "short_name": "$CORTO",
  "id": "/",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "background_color": "$COLOR",
  "theme_color": "$COLOR",
  "icons": [
    { "src": "/pwa/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
    { "src": "/pwa/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any" },
    { "src": "/pwa/icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
JSON

# --- assetlinks.json (falta la huella) --------------------------------------
cat > "$SALIDA/pwa/assetlinks.json" <<JSON
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "$ID",
      "sha256_cert_fingerprints": [
        "REEMPLAZA_ESTO_POR_LA_HUELLA_SHA256_DEL_APK"
      ]
    }
  }
]
JSON

# --- fragmento de Nginx -----------------------------------------------------
cat > "$SALIDA/pwa/nginx-pwa.conf" <<'NGINX'
# Publica las tres rutas que el verificador de Android pide SIN autenticacion.
# Se incluye desde el bloque `server` del sitio, NO se copia dentro de la
# carpeta publica: quedaria descargable por cualquiera.
#
# Ajusta /var/www/dsh/pwa a donde dejes los archivos de la carpeta pwa/.

location = /manifest.webmanifest {
    alias /var/www/dsh/pwa/manifest.webmanifest;
    default_type application/manifest+json;
}
location /pwa/ {
    alias /var/www/dsh/pwa/;
}
location = /.well-known/assetlinks.json {
    alias /var/www/dsh/pwa/assetlinks.json;
    default_type application/json;
}
NGINX

# --- Resumen ----------------------------------------------------------------
echo "Configuracion generada en $(cd "$SALIDA" && pwd):"
echo
echo "  twa-manifest.json          paquete $ID, host $HOST"
echo "  pwa/manifest.webmanifest"
echo "  pwa/assetlinks.json        (FALTA la huella SHA-256)"
echo "  pwa/nginx-pwa.conf"
echo "  pwa/icon-192.png, icon-512.png, icon-maskable-512.png"
echo
echo "SIGUIENTE:"
echo "  1. Copia pwa/ al servidor y publica las rutas con el fragmento de Nginx."
echo "  2. Crea el keystore (una sola vez, guardalo bien):"
echo "       keytool -genkeypair -v -keystore mi.keystore -alias dsh \\"
echo "               -keyalg RSA -keysize 2048 -validity 10000"
echo "  3. Saca la huella que hay que publicar:"
echo "       keytool -list -v -keystore mi.keystore -alias dsh | grep SHA256"
echo "     (en español anade -J-Duser.language=en, o keytool revienta al imprimir)"
echo "  4. Ponla en pwa/assetlinks.json, sube el archivo y comprueba que responde:"
echo "       curl -s https://$HOST/.well-known/assetlinks.json"
echo "  5. Genera el proyecto y compila:"
echo "       npx @bubblewrap/cli init --manifest $SALIDA/twa-manifest.json"
echo "       cd $SALIDA && ./gradlew assembleRelease"
