# Cord Themes

Nine themes for [Cord](https://github.com/cord-note/cord), each based on a well-loved open colour palette. Every theme has a dark and a light version and follows your Light/Dark/System setting.

| Theme | Dark | Light | Palette |
|---|---|---|---|
| Catppuccin | Mocha | Latte | [Catppuccin](https://github.com/catppuccin/catppuccin) |
| Nord | Polar Night | Snow Storm | [Nord](https://www.nordtheme.com) |
| Gruvbox | Dark | Light | [Gruvbox](https://github.com/morhetz/gruvbox) |
| Rosé Pine | Main | Dawn | [Rosé Pine](https://rosepinetheme.com) |
| Tokyo Night | Night | Day | [Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme) |
| Everforest | Dark | Light | [Everforest](https://github.com/sainnhe/everforest) |
| Solarized | Dark | Light | [Solarized](https://ethanschoonover.com/solarized/) |
| Dracula | Dracula | Alucard | [Dracula](https://draculatheme.com) |
| Kanagawa | Wave | Lotus | [Kanagawa](https://github.com/rebelot/kanagawa.nvim) |

## Install

In Cord, open **Settings → Appearance → Theme**, choose **Import → From Git repo…** and paste this repository's link. All nine themes appear in the gallery under **Library**.

To install just one theme, link to its folder, for example `.../tree/main/nord`.

You can also download the repository as a zip and use **Import → From zip…**, or copy a theme folder into your theme folder yourself.

To update later, right-click a theme in the gallery and choose **Update from source**.

## Making your own

Each theme is a folder with:

- `theme.css`: colour tokens for the dark scheme, and for `[data-scheme="light"]`
- `theme.json`: name, description and author shown in the gallery

The tokens and rules a theme may use are documented in Cord's theming guide (`docs/theming/public-api.md`), with a starter template in `docs/theming/template-theme.css`.

## Credits

The colour palettes belong to their authors and are used under their MIT licences; see the links above. A few light-scheme text colours were darkened slightly so body text meets a 4.5:1 contrast ratio. The theme files in this repository are MIT licensed.
