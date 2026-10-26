# Cliente de escritorio (Linux)

Un lanzador que abre tu servidor DSH en una **ventana propia**, sin barra de
direcciones ni pestañas, usando el *modo aplicación* de Chrome o Brave.

No es una app con motor propio: es Chrome con la interfaz web. La ventaja es que
no hay nada que compilar ni actualizar; lo que cambie en el servidor se ve al
instante.

## Requisitos

- Linux con escritorio que respete los `.desktop` y `StartupWMClass` (GNOME,
  KDE, XFCE, Cinnamon…).
- **Chrome o Brave** en el `PATH`. **Firefox no sirve**: no tiene modo
  aplicación.
- `bash`. Nada de `sudo`: todo se instala dentro de `~/.local`.

## Instalar

```bash
./instalar.sh https://mi-servidor.example
```

La URL es obligatoria. Opciones:

```bash
./instalar.sh https://mi-servidor.example brave     # forzar navegador
DSH_NOMBRE="Mi Asistente" ./instalar.sh https://... # nombre en el menú
```

El icono sale de `../icono/icono-512.png`. Si no existe, genéralo primero:

```bash
../icono/generar.sh
```

## La primera vez: crear la sesión

El cliente tiene su **propio almacén de navegador**, así que empieza sin sesión.
Si al abrirlo aparece el aviso en inglés:

```text
dsh web authentication required
```

se arregla abriendo **una sola vez** la dirección con el token, **con ese mismo
almacén**:

```bash
google-chrome-stable --user-data-dir="$HOME/.local/share/dsh-clients/perfil" \
  "https://mi-servidor.example?token=<token>"
```

El token lo imprime tu servidor al arrancar (o te lo da quien lo administre) y
cambia en cada arranque del servicio. Después, la sesión dura lo que dure la
cookie configurada en el servidor.

> Si abres esa URL en tu Chrome de siempre, la cookie se guarda en el **otro**
> almacén y el lanzador sigue fuera.

## Por qué tiene almacén propio

El navegador decide la identidad de una ventana (su `WM_CLASS`) **por proceso**,
no por ventana. Si el lanzador cae dentro de un Chrome que ya está abierto, la
ventana nueva hereda la clase de ese proceso y el escritorio pone el icono de
Chrome, por mucho `StartupWMClass` que declares. Con `--user-data-dir` el
cliente arranca su propio proceso, con su clase, y el icono correcto.

Se comprueba así (solo funciona si la ventana es de X11):

```bash
xprop -id <id-de-la-ventana> WM_CLASS
```

## Por qué arranca por X11

El lanzador lleva `--ozone-platform=x11`. En algunas instalaciones con GNOME 50
(Ubuntu 26.04) Chrome y Electron **abortan** en Wayland:

```text
GLib-GIO-ERROR **: Settings schema 'org.gnome.settings-daemon.plugins.xsettings'
does not contain a key named 'antialiasing'
```

Los esquemas 50 de GNOME ya no traen esa clave, GTK se cae y el proceso muere
con volcado. Actualizar Chrome no lo arregla. Si en tu equipo Wayland funciona
bien, puedes quitar esa bandera del `.desktop` generado.

`arreglar-chrome-wayland.sh` aplica el mismo remedio a tu **Chrome normal**
(hace una copia del lanzador del sistema en `~/.local`, sin `sudo`). El lanzador
de `dsh-clients` ya lleva la bandera, así que este script es opcional.

## Desinstalar

```bash
./desinstalar.sh
```

Quita el lanzador y el icono, y **conserva** el almacén con la sesión. Si quieres
borrarlo también (perderás la sesión):

```bash
rm -rf ~/.local/share/dsh-clients
```

## Archivos que deja

| Ruta | Qué es |
|---|---|
| `~/.local/share/applications/dsh-clients.desktop` | el lanzador |
| `~/.local/share/icons/hicolor/512x512/apps/dsh-clients.png` | el icono |
| `~/.local/share/dsh-clients/perfil/` | el almacén del navegador, con la sesión |
