# Open Graph card for neetoEngage changelogs

neetoKB serves a generated card for every help article, for example
`https://help.neetocal.com/opengraph_images/articles/<slug>`: a green top bar,
the site name, and the article title. neetoEngage changelog entries instead
share one static NeetoEngage logo, so a shared link says nothing about the entry.

This folder holds a template that reproduces the neetoKB card, calibrated
against the real neetoCal image, and a rendering of it for
`https://neetocrmhelp.neetoengage.com/changelogs/support-related-fields-in-filters`.

| File | What it is |
|---|---|
| `template.html` | The card, 1200x630, with `KICKER`, `TITLE` and size placeholders |
| `render.sh` | Fills the template and screenshots it with headless Chrome |
| `neetocrm-changelog-og.png` | The rendered card for the changelog entry above |
| `reference-neetocal-og.png` | The neetoKB card the template was matched to |
| `comparison.png` | Reference card stacked over the rendered one |

```bash
docs/og-cards/neetoengage-changelog/render.sh "NeetoCRM Help" "Related fields support in filters" out.png
```

## Measurements taken from the neetoKB card

| Element | Value |
|---|---|
| Canvas | 1200x630, background `#FAFCFB` |
| Top bar | 20px, `#5BCC5A` |
| Site name | Inter 500, 39px, `#343C37` |
| Title | Inter 600, 66px, tracking -0.03em, line height 1.14, `#111814` |
| Margins | 86px left and right, text block centred vertically below the bar |

## Tags the changelog page should carry

```html
<meta property="og:type" content="article">
<meta property="og:title" content="Related fields support in filters">
<meta property="og:image" content="https://neetocrmhelp.neetoengage.com/opengraph_images/changelogs/support-related-fields-in-filters">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image" content="https://neetocrmhelp.neetoengage.com/opengraph_images/changelogs/support-related-fields-in-filters">
```

Serve the image from the neetoEngage host rather than the workspace's custom
domain, so each entry has one image URL. Facebook and Slack cache by image URL.
The `og:description` is currently the generic "Get notified of new features and
improvements."; the entry's first sentence would serve better.
