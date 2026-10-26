#!/usr/bin/env bash
#
# Instala un lanzador de escritorio (Linux) para un servidor DSH.
#
# QUE HACE
#   Deja un icono en el menu de aplicaciones que abre tu servidor DSH en una
#   ventana PROPIA, sin barra de direcciones, usando el "modo aplicacion" de
#   Chrome o Brave.
#
# USO
#   ./instalar.sh https://mi-servidor.example
#   ./instalar.sh https://mi-servidor.example brave     (fuerza el navegador)
#   DSH_NOMBRE="Mi Asistente" ./instalar.sh https://...
#
#   La URL es obligatoria: este lanzador no trae ninguna escrita dentro.
#
# POR QUE CON ALMACEN PROPIO
#   El navegador decide la identidad de una ventana (su "clase") POR PROCESO, no
#   por ventana. Si el lanzador cae dentro del Chrome que ya tienes abierto, la
#   ventana nueva hereda la clase de ese proceso y el escritorio le pone el
#   icono de Chrome, por mucho StartupWMClass que pongamos.
#   Con un almacen propio (--user-data-dir) el cliente arranca SU proceso, con
#   SU clase, y el escritorio le pone nuestro icono.
#   Contrapartida: al ser un almacen aparte, la sesion hay que crearla UNA vez
#   dentro de el. Ver la seccion PRIMERA VEZ del final.
#
# POR QUE X11 (XWAYLAND) Y NO WAYLAND
#   En algunas instalaciones con GNOME 50 (Ubuntu 26.04, por ejemplo) Chrome y
#   Electron ABORTAN al arrancar en Wayland. El motivo, del registro:
#     GLib-GIO-ERROR **: Settings schema 'org.gnome.settings-daemon.plugins.xsettings'
#                         does not contain a key named 'antialiasing'
#   Es decir: leen claves de GSettings que los esquemas 50 ya no traen (esa y
#   'font-antialiasing' en org.gnome.desktop.interface). GTK se cae y se lleva
#   la aplicacion por delante, con volcado. Con --ozone-platform=x11 arranca
#   sin un solo error. Si en tu equipo Wayland va bien, puedes quitar la
#   bandera del lanzador que genera este script.
#
# NO usa sudo y no toca nada del sistema: todo va dentro de ~/.local.
# Para quitarlo: ./desinstalar.sh
#
set -euo pipefail

URL="${1:-}"
if [[ -z "$URL" ]]; then
  echo "USO: $0 <URL-del-servidor-DSH> [navegador]" >&2
  echo "     ejemplo: $0 https://mi-servidor.example" >&2
  exit 1
fi
if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "ERROR: la URL tiene que empezar por http:// o https://" >&2
  exit 1
fi
shift

NOMBRE_APP="${DSH_NOMBRE:-DSH}"
NOMBRE_ICONO="dsh-clients"
NOMBRE_LANZADOR="dsh-clients.desktop"
DIR_APLICACIONES="$HOME/.local/share/applications"
DIR_ICONOS="$HOME/.local/share/icons/hicolor/512x512/apps"
DIR_ALMACEN="$HOME/.local/share/dsh-clients"
DIR_PERFIL="$DIR_ALMACEN/perfil"
AQUI="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# --- 1) Elegir navegador ----------------------------------------------------
# Firefox NO sirve: no tiene modo aplicacion (una ventana propia sin barra).
# Solo valen los Chromium: Chrome y Brave.
elegir_navegador() {
  if [[ $# -gt 0 ]]; then
    if [[ -x "$1" ]]; then
      printf '%s\n' "$1"
      return 0
    fi
    local encontrado
    encontrado="$(command -v "$1" 2>/dev/null || true)"
    if [[ -n "$encontrado" ]]; then
      printf '%s\n' "$encontrado"
      return 0
    fi
    echo "ERROR: no encuentro el navegador '$1'." >&2
    return 1
  fi

  local candidato ruta
  for candidato in google-chrome-stable google-chrome brave-browser brave; do
    ruta="$(command -v "$candidato" 2>/dev/null || true)"
    if [[ -n "$ruta" ]]; then
      printf '%s\n' "$ruta"
      return 0
    fi
  done

  echo "ERROR: no encuentro Chrome ni Brave en el PATH." >&2
  echo "       Firefox no vale para esto: no tiene modo aplicacion." >&2
  return 1
}

NAVEGADOR="$(elegir_navegador "$@")"

# --- 2) Localizar el icono ---------------------------------------------------
ORIGEN_ICONO="$AQUI/icono.png"
if [[ ! -f "$ORIGEN_ICONO" ]]; then
  ORIGEN_ICONO="$AQUI/../icono/icono-512.png"
fi
if [[ ! -f "$ORIGEN_ICONO" ]]; then
  echo "ERROR: no encuentro el icono (ni $AQUI/icono.png ni ../icono/icono-512.png)." >&2
  echo "       Genera los PNG con: ../icono/generar.sh" >&2
  exit 1
fi

# --- 3) Instalar icono y lanzador ------------------------------------------
mkdir -p "$DIR_APLICACIONES" "$DIR_ICONOS" "$DIR_PERFIL"
install -m 644 "$ORIGEN_ICONO" "$DIR_ICONOS/$NOMBRE_ICONO.png"

cat > "$DIR_APLICACIONES/$NOMBRE_LANZADOR" <<FIN
[Desktop Entry]
Version=1.0
Type=Application
Name=$NOMBRE_APP
Comment=DSH en una ventana propia, sin barra de direcciones
Exec=$NAVEGADOR --app=$URL --class=$NOMBRE_ICONO --user-data-dir=$DIR_PERFIL --no-first-run --no-default-browser-check --ozone-platform=x11
Icon=$NOMBRE_ICONO
Terminal=false
Categories=Development;
StartupNotify=true
StartupWMClass=$NOMBRE_ICONO
FIN

chmod 644 "$DIR_APLICACIONES/$NOMBRE_LANZADOR"

# --- 4) Avisar al escritorio del cambio ------------------------------------
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DIR_APLICACIONES" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# --- 5) Resumen -------------------------------------------------------------
echo "Lanzador instalado."
echo
echo "  navegador : $NAVEGADOR"
echo "  servidor  : $URL"
echo "  lanzador  : $DIR_APLICACIONES/$NOMBRE_LANZADOR"
echo "  icono     : $DIR_ICONOS/$NOMBRE_ICONO.png"
echo "  almacen   : $DIR_PERFIL"
echo
echo "Ya aparece como \"$NOMBRE_APP\" en el menu de aplicaciones."
echo "En el Dock se fija con el boton derecho: \"Anadir a favoritos\"."
echo
echo "PRIMERA VEZ: el cliente tiene su propio almacen, asi que todavia no tiene"
echo "la sesion. Si al abrirlo ves el aviso en ingles"
echo "  \"dsh web authentication required\""
echo "se arregla abriendo UNA sola vez la direccion con el token CON ESE MISMO"
echo "almacen. OJO: si la abres en tu Chrome de siempre, la cookie se guarda en"
echo "el otro almacen y el cliente sigue fuera."
echo
echo "  $NAVEGADOR --user-data-dir=$DIR_PERFIL \"${URL}?token=<token>\""
echo
echo "El token lo imprime tu servidor DSH al arrancar (o lo da quien lo"
echo "administre); cambia en cada arranque del servicio."
echo
echo "Despues la sesion dura lo que dure la cookie configurada en el servidor."
echo "Para quitar el lanzador: ./desinstalar.sh"
