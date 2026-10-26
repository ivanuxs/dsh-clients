# dsh-clients

Lightweight clients that turn a **[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)**
(DSH) server into an installable app: one for **Linux**, one for **Android**.

DSH already ships a web UI, but a web page is not an app: address bar, tabs, and
the browser can be closed at any moment. These two clients fix that without
rebuilding the harness and without a WebView.

> **Unofficial project.** Not made by DeepSeek, not endorsed by DeepSeek.
> "DeepSeek Harness" is a DeepSeek trademark; it is used here only to describe
> what this works with.

Español: [README.md](README.md)

## The two clients

| Client | What it is | What you get |
|---|---|---|
| [`linux/`](linux/LEEME.md) | A `.desktop` launcher that opens the site in Chrome's or Brave's *app mode* | Its own window, its own icon, no address bar, no tabs |
| [`android/`](android/LEEME.md) | A **TWA** (*Trusted Web Activity*) built with Bubblewrap | A real APK, full screen, and it **shares Chrome's session**: no credentials prompt |

Neither one bundles DSH code: both open **your** server. That is why setup asks
for your domain, and why server-side changes show up instantly with no app
update.

## Quick start

### Linux

```bash
./linux/instalar.sh https://my-server.example
```

It installs a menu entry. The first run needs the session created inside the
client's own browser profile (see [`linux/LEEME.md`](linux/LEEME.md)).

### Android

```bash
cd android
./configurar.sh --host my-server.example --id com.mycompany.assistant
npx @bubblewrap/cli init --manifest salida/twa-manifest.json
cd salida && ./gradlew assembleRelease
```

Before building you must publish `assetlinks.json` with your keystore
fingerprint; without it the app opens with an address bar. Step by step, in
[`android/LEEME.md`](android/LEEME.md).

## Layout

```text
dsh-clients/
├── icono/     project icon (SVG + PNG generator)
├── linux/     desktop launcher
└── android/   TWA generator and the files your site must serve
```

## The icon

It is original artwork: a terminal window and a chat bubble. It deliberately
does **not** use the DeepSeek logo, so nothing suggests this is official.

Regenerate the PNGs with:

```bash
./icono/generar.sh
```

## The three things that usually break a TWA

Details in [`android/LEEME.md`](android/LEEME.md) (in Spanish), but keep these in
sight:

1. **The session cookie must ship as `SameSite=Lax`.** If the server sends
   `Strict`, Chromium withholds it when the navigation is started by another
   app, and the TWA sits at 401. One Nginx line fixes it:
   `proxy_cookie_flags ~ samesite=lax;`.
2. **`assetlinks.json` must be published and reachable without authentication**,
   carrying the SHA-256 fingerprint of the key that signs the installed APK.
3. **`minSdkVersion` 24**, not 21: `androidbrowserhelper` requires it.

## License

MIT. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
