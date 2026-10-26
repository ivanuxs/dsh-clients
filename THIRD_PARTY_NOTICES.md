# Avisos de terceros

Este repositorio no incluye código de DeepSeek Harness: los dos clientes abren un
servidor DSH por HTTP. Aun así, se documenta de qué depende y bajo qué licencia,
porque parte del contenido se inspira en él y porque quien compile con estas
instrucciones usará sus herramientas.

## DeepSeek Harness

- Proyecto: <https://github.com/deepseek-ai/deepseek-harness>
- Licencia: **MIT**, *Copyright (c) 2026 DeepSeek*
- Uso aquí: se citan sus rutas (`/.well-known/assetlinks.json`,
  `/manifest.webmanifest`) y se documenta su comportamiento (cookie de sesión,
  nombre de los servicios). La estructura del `manifest.webmanifest` y del
  `assetlinks.json` sigue el formato que su interfaz web publica.

```text
MIT License

Copyright (c) 2026 DeepSeek

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Bubblewrap

- Proyecto: <https://github.com/GoogleChromeLabs/bubblewrap>
- Licencia: **Apache License 2.0**
- Uso aquí: **no se distribuye**. `android/configurar.sh` genera un manifiesto y
  documenta cómo ejecutarlo con `npx @bubblewrap/cli`, que cada usuario descarga
  por su cuenta.

El proyecto Android que Bubblewrap genera incluye
[`androidbrowserhelper`](https://github.com/GoogleChrome/android-browser-helper)
(Apache 2.0) y el resto de dependencias de AndroidX, cada una con su licencia, en
los archivos que el propio generador crea.

## Marca

«DeepSeek Harness» es una marca registrada de DeepSeek. En este repositorio el
nombre se usa únicamente de forma descriptiva («funciona con DeepSeek Harness»),
nunca como nombre del proyecto, y el icono es original: no se usa material de
marca de DeepSeek. Este proyecto no está afiliado a DeepSeek ni cuenta con su
respaldo.
