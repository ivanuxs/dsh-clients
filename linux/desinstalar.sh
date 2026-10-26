#!/usr/bin/env bash
#
# Quita el lanzador de escritorio (Linux) instalado por instalar.sh.
#
# No usa sudo. NO toca la sesion del cliente: si vuelves a instalarlo,
# seguiras dentro sin que te pida nada.
#
set -euo pipefail

NOMBRE_ICONO="dsh-clients"
NOMBRE_LANZADOR="dsh-clients.desktop"
DIR_APLICACIONES="$HOME/.local/share/applications"
DIR_ICONOS="$HOME/.local/share/icons/hicolor/512x512/apps"
DIR_ALMACEN="$HOME/.local/share/dsh-clients"
DIR_PERFIL="$DIR_ALMACEN/perfil"

rm -f "$DIR_APLICACIONES/$NOMBRE_LANZADOR"
rm -f "$DIR_ICONOS/$NOMBRE_ICONO.png"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DIR_APLICACIONES" 2>/dev/null || true
fi

echo "Lanzador quitado."
echo "  (La sesion no se toca: si lo vuelves a instalar, seguiras dentro.)"
echo
echo "Se conserva el almacen propio del cliente, con su sesion guardada:"
echo "  $DIR_PERFIL"
echo "Si algun dia quieres borrarlo (perderas la sesion y habra que repetir"
echo "la entrada con el token):"
echo "  rm -rf $DIR_ALMACEN"
