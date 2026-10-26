# dsh-clients

Clientes ligeros para convertir un servidor **[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)**
(DSH) en una app instalable: uno para **Linux** y otro para **Android**.

DSH ya trae una interfaz web, pero una web no es una app: hay barra de
direcciones, pestañas, y el navegador puede cerrarse en cualquier momento. Estos
dos clientes resuelven eso sin recompilar el harness y sin usar un WebView.

> **Proyecto no oficial.** No está hecho por DeepSeek ni cuenta con su respaldo.
> «DeepSeek Harness» es una marca de DeepSeek; aquí solo se usa para describir con
> qué funciona esto.

English: [README.en.md](README.en.md)

## Los dos clientes

| Cliente | Qué es | Qué gana |
|---|---|---|
| [`linux/`](linux/LEEME.md) | Un lanzador `.desktop` que abre el sitio en el *modo aplicación* de Chrome o Brave | Ventana propia, icono propio, sin barra ni pestañas |
| [`android/`](android/LEEME.md) | Una **TWA** (*Trusted Web Activity*) construida con Bubblewrap | APK real, pantalla completa, y **comparte la sesión de Chrome**: no pide credenciales |

Ninguno de los dos lleva código de DSH dentro: los dos abren **tu** servidor. Por
eso la configuración pide tu dominio, y por eso lo que cambies en el servidor se
ve al instante, sin actualizar la app.

## Empezar

### Linux

```bash
./linux/instalar.sh https://mi-servidor.example
```

Deja un icono en el menú de aplicaciones. La primera vez hay que crear la sesión
dentro de su propio almacén (está explicado en [`linux/LEEME.md`](linux/LEEME.md)).

### Android

```bash
cd android
./configurar.sh --host mi-servidor.example --id com.miempresa.asistente
npx @bubblewrap/cli init --manifest salida/twa-manifest.json
cd salida && ./gradlew assembleRelease
```

Antes de compilar hay que publicar `assetlinks.json` con la huella de tu keystore;
sin eso la app abre con barra de direcciones. Los pasos, en orden, en
[`android/LEEME.md`](android/LEEME.md).

## Estructura

```text
dsh-clients/
├── icono/     el icono del proyecto (SVG + generador de PNG)
├── linux/     lanzador de escritorio
└── android/   generador de la TWA y los archivos que hay que servir
```

## El icono

Es propio, dibujado para este proyecto: una ventana de terminal y una burbuja de
conversación. **No** usa el logo de DeepSeek, para no dar a entender que esto es
oficial.

Para regenerar los PNG:

```bash
./icono/generar.sh
```

## Las tres cosas que suelen romper una TWA

Están explicadas a fondo en [`android/LEEME.md`](android/LEEME.md), pero conviene
tenerlas a la vista:

1. **La cookie de sesión tiene que salir como `SameSite=Lax`.** Si el servidor la
   emite `Strict`, Chromium la retiene cuando la navegación la lanza otra app y
   la TWA se queda en 401. Se corrige en Nginx con
   `proxy_cookie_flags ~ samesite=lax;`.
2. **`assetlinks.json` tiene que estar publicado y accesible sin autenticación**,
   con la huella SHA-256 de la clave que firma el APK instalado.
3. **`minSdkVersion` 24**, no 21: `androidbrowserhelper` lo exige.

## Licencia

MIT. Ver [LICENSE](LICENSE) y [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
