---
title: Editing This Documentation
parent: Developer Docs
lang: en
nav_order: 10
description: "How the site is set up (Just the Docs), adding pages, bilingual rules, and deployment."
---

# Editing This Documentation
{: .no_toc }

1. TOC
{:toc}

This manual is a **Jekyll** site using the **Just the Docs** theme, served by
**GitHub Pages** from the `/docs` folder of the `main` branch.

## Structure

```text
docs/
├── _config.yml                 # Jekyll + Just the Docs config (theme, search, mermaid)
├── _sass/
│   ├── color_schemes/therapets-dark.scss   # Dark scheme (black + purple)
│   └── custom/custom.scss                   # Extra style tweaks
├── _includes/
│   ├── nav_footer_custom.html  # Language selector in the sidebar
│   └── mermaid_config.js       # Dark theme for Mermaid diagrams
├── index.md                    # Home (ES)
├── guia-usuario.md             # Parent: Guía del Usuario (ES)
├── desarrollo.md               # Parent: Para Desarrolladores (ES)
├── *.md                        # ES pages
├── Gemfile                     # For local preview only
└── en/                         # English mirror
```

## Local preview

```bash
cd docs
bundle install
bundle exec jekyll serve
# open http://127.0.0.1:4000
```

> GitHub Pages builds the site on its server; the `Gemfile` is only for your
> local preview.
{: .note }

## Adding a page

1. Create `docs/my-page.md` with Just the Docs front matter:

```yaml
---
title: My Page
parent: User Guide     # or "Developer Docs"
lang: en
nav_order: 12          # position in the menu
---
```

2. The sidebar navigation is generated **automatically** from `title`, `parent`, and
   `nav_order`. Parent pages have `has_children: true`.
3. Create the Spanish mirror at `docs/es/my-page.md` with `parent: Guía del Usuario`
   (or `Para Desarrolladores`) and `lang: es`.

## Bilingual rules

- **Spanish** lives in `docs/` (primary language). **English** in `docs/en/`.
- Section parent pages have **unique titles per language**:
  - ES: `Guía del Usuario`, `Para Desarrolladores`
  - EN: `User Guide`, `Developer Docs`
- The 🇪🇸/🇬🇧 selector (at the bottom of the sidebar) jumps between the home page
  of each language (`_includes/nav_footer_custom.html`).

## Useful resources

- **Diagrams:** ` ```mermaid ``` ` code block; rendered with dark theme.
- **Callouts:** `{: .note }`, `{: .tip }`, `{: .warning }`, `{: .danger }` after a
  blockquote.
- **Buttons:** `[Text](url){: .btn .btn-purple }`.
- **Images/screenshots:** save them in `docs/assets/images/screenshots/` and
  link with a relative path.

## Deployment

Every push to `main` that touches `/docs` republishes the site automatically
(GitHub Pages). No extra workflow needed: Pages detects Jekyll and builds it.

> If you change the theme or `_config.yml` and the Pages build fails, check the
> **Actions / Pages** tab of the repo to see the Jekyll log.
{: .warning }
