#!/usr/bin/env bash
#
# Deja un lanzador PROPIO de Chrome con la bandera de X11, para que arranque.
#
# POR QUE
#   En algunas instalaciones con GNOME 50 (Ubuntu 26.04, por ejemplo) Chrome
#   aborta al arrancar en Wayland. Del registro:
#     GLib-GIO-ERROR **: Settings schema 'org.gnome.settings-daemon.plugins.xsettings'
#                         does not contain a key named 'antialiasing'
#   Los esquemas 50 de GNOME ya no traen esa clave (ni 'font-antialiasing' en
#   org.gnome.desktop.interface). Chrome las lee, GTK se cae y aborta el proceso
#   con volcado. Con --ozone-platform=x11 arranca sin un solo error. Electron
#   sufre el mismo fallo, y actualizar Chrome NO lo arregla: es un descuadre
#   entre libgtk-3-0t64 y gsettings-desktop-schemas.
#
#   Ojo: el lanzador de dsh-clients (instalar.sh) ya lleva la bandera, asi que
#   este script solo hace falta si quieres arreglar TAMBIEN tu Chrome normal.
#
# COMO
#   Copia el lanzador del sistema a ~/.local/share/applications/ y le anade la
#   bandera a TODAS sus lineas Exec. El del sistema NO se toca y el del usuario
#   tiene prioridad. No usa sudo.
#
#   Ojo: mientras siga vivo un Chrome abierto en Wayland, el lanzador se une a
#   ESE proceso y la bandera no surte efecto. Hay que cerrar Chrome del todo una
#   vez para que el arreglo entre.
#
# PARA DESHACERLO
#   rm ~/.local/share/applications/google-chrome.desktop
#
# USO
#   ./arreglar-chrome-wayland.sh
#
set -euo pipefail

BANDERA="--ozone-platform=x11"
ORIGEN="/usr/share/applications/google-chrome.desktop"
DESTINO="$HOME/.local/share/applications/google-chrome.desktop"

if [[ ! -f "$ORIGEN" ]]; then
  echo "ERROR: no encuentro $ORIGEN" >&2
  echo "       Este script es solo para Google Chrome de paquete .deb." >&2
  exit 1
fi

mkdir -p "$(dirname "$DESTINO")"

# Se anade la bandera a cada linea Exec que arranque Chrome, sin duplicarla.
sed -E "s#^Exec=(/usr/bin/google-chrome-stable)( |\$)#Exec=\1 ${BANDERA}\2#g" "$ORIGEN" > "$DESTINO"
chmod 644 "$DESTINO"

# Comprobacion: ninguna linea Exec debe quedarse sin la bandera.
total="$(grep -c '^Exec=/usr/bin/google-chrome-stable' "$DESTINO" || true)"
conBandera="$(grep -c "^Exec=/usr/bin/google-chrome-stable ${BANDERA}" "$DESTINO" || true)"

echo "Lanzador propio de Chrome instalado."
echo "  origen  : $ORIGEN (intacto)"
echo "  destino : $DESTINO"
echo "  lineas Exec con la bandera: $conBandera de $total"

if [[ "$conBandera" != "$total" ]]; then
  echo "AVISO: alguna linea Exec se quedo sin la bandera; revisalo." >&2
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

echo
echo "Ya puedes abrir Chrome desde el menu o la barra: arrancara por X11."
echo "Para deshacerlo: rm $DESTINO"
