# Website

The public landing page lives in `site/` and is published to GitHub Pages at https://sanusanal.github.io/YouPipe-Music/ by `.github/workflows/pages.yml` whenever `site/**` changes on `main` (or by running the workflow by hand).

- **One-time setup:** repo Settings → Pages → Build and deployment → Source: **GitHub Actions**.
- **Plain static files, no build step:** `index.html` has all its CSS and JS inline; `logo.svg` is a copy of `assets/branding/logo.svg` and `og.png` of `assets/branding/logo_1024.png` (the link preview image). Update the copies if the logo changes.
- **Download buttons are live:** on load, the page reads `api.github.com/repos/SanuSanal/YouPipe-Music/releases/latest` and points the buttons at that release's APKs, with the version and size. It relies on the same asset naming as the in-app updater (`…-<abi>.apk`; see [updates.md](updates.md)). Without the API (offline, rate-limited) the buttons fall back to the Releases page.
- **Which APK:** arm64 by default. On an Android browser that reports a 32-bit ARM or x86 CPU (User-Agent Client Hints), it offers that APK instead. It never guesses from a desktop browser, since people often download on a PC for their phone.
- **Design:** porcelain background (dark variant via `prefers-color-scheme`), brand red, Unbounded for headings, Instrument Sans for text, JetBrains Mono for versions and ABIs. The signature is the red band with the logo's white pipe, which features scroll along into the bore; the motion stops under `prefers-reduced-motion`. The phone shows a made-up song, not real artwork, and there are no YouTube logos.
- **Screenshots** ("Take a look", `#screenshots`): real captures from the app, on a rail that scrolls sideways. Make them with `python tool/screenshots.py <dir of raw PNGs>` from 1080×2400 `adb exec-out screencap -p` captures. It swaps the real status bar for a clean one: the time from `TIME` (2:10, to match the lock screen capture's clock), signal, Wi-Fi and a battery, with no notifications or percentage. It writes:
  - `site/screenshots/<name>.webp`: the bare screen, which the site puts in its CSS frame;
  - `assets/screenshots/<name>.webp`: the same screen already framed (transparent WebP), for the README.

  They show real album artwork, unlike the hero mockup. **Never** capture the Lyrics tab: song lyrics are copyrighted.
- **Phone frame:** one style everywhere, flat sides with thin even bezels, a punch-hole camera and two side keys on the right (a Galaxy S25-like shape, with no brand marks). On the site it's the `.device` class (hero mockup and gallery); for the README it's drawn by `tool/screenshots.py` with the same proportions.
- **Everything else is vector** (inline SVG and CSS). Above 1800 px wide the root font size grows, so the layout scales up on 4K screens instead of floating small in the middle.
- **Preview locally:** `python -m http.server 8123 --directory site` (opening the file directly breaks the relative logo path in some viewers).
