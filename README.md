# ogpreview

A macOS app for previewing how a link unfurls before you share it — the same
idea as [opengraph.dev](https://opengraph.dev), running natively.

Paste a URL and ogpreview fetches the page with a crawler user-agent (no
JavaScript, no cookies — exactly what Facebook, X and Slack see), then renders
the card each platform would build from the tags it finds:

Google · X · Facebook · LinkedIn · Slack · Discord · iMessage · WhatsApp

The inspector alongside the previews shows:

- **Tests** — 26 pass/fail checks over the page: every tag platforms read
  (`og:*`, `twitter:*`, `<title>`, meta description), their lengths against what
  each platform truncates, and the image's real dimensions, aspect ratio and
  weight. Failures list first, passes below, so you can see what was confirmed good.
- **Tags** — every Open Graph, Twitter, standard and link tag, grouped and copyable.
- **Response** — status, redirect chain, content type, size, timing, and the
  actual dimensions and weight of the `og:image` after downloading it.

## Build

Needs the Xcode Command Line Tools; no Xcode project involved.

```sh
swift run                                  # run from source
./scripts/make-app.sh                      # build ogpreview.app
./scripts/make-dmg.sh                      # build ogpreview-macos.dmg
./scripts/make-icon.sh                     # regenerate the icon from Resources/icon.png
open ogpreview.app
```

The released binary is universal (arm64 + x86_64), so it runs on Apple Silicon
and Intel Macs alike. Building universal locally needs full Xcode for SwiftPM's
`--arch`; with only the Command Line Tools the scripts build for this machine's
architecture and say so, while CI still produces a universal DMG.

## Releasing

The app updates itself through [Sparkle](https://sparkle-project.org). To ship a
version, push a `vX.Y` tag and publish a GitHub release for it — the
`Release macOS app` workflow builds the DMG, signs it with the `neetozone`
EdDSA key held in the `SPARKLE_ED_PRIVATE_KEY` repository secret, generates
`appcast.xml`, and attaches both to the release. Installed copies pick the
update up within a day, or immediately via **ogpreview → Check for Updates…**

The binary also takes a URL, so it can open straight onto a page:

```sh
swift run ogpreview https://example.com
```

`OGPREVIEW_PLATFORMS=slack,discord` narrows the column to a few cards (useful for
screenshots). When it is set, the address bar shows a "Filtered" badge — launching
from Finder or `open` never sets it, so the full set of eight always shows.
