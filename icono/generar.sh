#!/usr/bin/env bash
#
# Genera los PNG del icono a partir de los SVG de esta carpeta.
#
# QUE HACE
#   icono.svg            -> icono-512.png, icono-192.png
#   icono-maskable.svg   -> icono-maskable-512.png
#
# RENDERIZADORES
#   Prueba varios, en este orden, y usa el primero que funcione:
#     1. rsvg-convert          (librsvg, el mas fiable)
#     2. inkscape
#     3. Chrome/Chromium en modo headless, con --ozone-platform=x11
#     4. ImageMagick (magick o convert)
#
#   El orden no es capricho: en algunas maquinas Inkscape aborta al arrancar
#   (GTK lee claves de GSettings que los esquemas 50 de GNOME ya no traen:
#   'org.gnome.settings-daemon.plugins.xsettings.antialiasing'), y ImageMagick
#   suele delegar el SVG justo en Inkscape, asi que hereda el fallo. Chrome, en
#   cambio, arranca bien con la bandera de X11.
#
# USO
#   ./generar.sh
#
set -euo pipefail

AQUI="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

REDIMENSIONAR() {
  local origen="$1" destino="$2" ancho="$3"
  if command -v magick >/dev/null 2>&1; then
    magick "$origen" -resize "${ancho}x${ancho}" "$destino"
  elif command -v convert >/dev/null 2>&1; then
    convert "$origen" -resize "${ancho}x${ancho}" "$destino"
  else
    cp "$origen" "$destino"
  fi
}

RENDERIZAR() {
  local origen="$1" destino="$2" ancho="$3"
  local navegador temporal

  # 1) librsvg
  if command -v rsvg-convert >/dev/null 2>&1; then
    if rsvg-convert -w "$ancho" -h "$ancho" -o "$destino" "$origen" 2>/dev/null; then
      return 0
    fi
  fi

  # 2) Inkscape (solo si responde: hay versiones que abortan)
  if command -v inkscape >/dev/null 2>&1 && inkscape --version >/dev/null 2>&1; then
    if inkscape "$origen" --export-type=png --export-filename="$destino" \
        --export-width="$ancho" >/dev/null 2>&1 && [[ -f "$destino" ]]; then
      return 0
    fi
  fi

  # 3) Chrome o Chromium en modo headless
  for navegador in google-chrome-stable google-chrome chromium chromium-browser brave-browser; do
    if command -v "$navegador" >/dev/null 2>&1; then
      temporal="$(mktemp /tmp/icono-XXXXXX.png)"
      rm -f "$temporal"
      if "$navegador" --headless=new --disable-gpu --ozone-platform=x11 \
          --default-background-color=00000000 --window-size=512,512 \
          --screenshot="$temporal" "file://$origen" >/dev/null 2>&1 && [[ -f "$temporal" ]]; then
        if [[ "$ancho" -eq 512 ]]; then
          mv "$temporal" "$destino"
        else
          REDIMENSIONAR "$temporal" "$destino" "$ancho"
          rm -f "$temporal"
        fi
        return 0
      fi
      rm -f "$temporal"
    fi
  done

  # 4) ImageMagick
  if command -v magick >/dev/null 2>&1; then
    if magick -background none -density 384 "$origen" -resize "${ancho}x${ancho}" "$destino" 2>/dev/null; then
      return 0
    fi
  fi
  if command -v convert >/dev/null 2>&1; then
    if convert -background none -density 384 "$origen" -resize "${ancho}x${ancho}" "$destino" 2>/dev/null; then
      return 0
    fi
  fi

  echo "ERROR: ningun renderizador de SVG funciono." >&2
  echo "       Instala uno: sudo apt install librsvg2-bin" >&2
  return 1
}

RENDERIZAR "$AQUI/icono.svg" "$AQUI/icono-512.png" 512
RENDERIZAR "$AQUI/icono.svg" "$AQUI/icono-192.png" 192
RENDERIZAR "$AQUI/icono-maskable.svg" "$AQUI/icono-maskable-512.png" 512

echo "Iconos generados en $AQUI:"
ls -l "$AQUI"/icono-*.png | awk '{print "  "$9" ("$5" bytes)"}'
