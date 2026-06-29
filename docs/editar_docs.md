---
title: Editar esta Documentación
parent: Para Desarrolladores
lang: es
nav_order: 10
description: "Cómo está montado el sitio (Just the Docs), añadir páginas, reglas bilingües y despliegue."
---

# Editar esta Documentación
{: .no_toc }

1. TOC
{:toc}

Este manual es un sitio **Jekyll** con el tema **Just the Docs**, servido por
**GitHub Pages** desde la carpeta `/docs` de la rama `main`.

## Estructura

```text
docs/
├── _config.yml                 # Config Jekyll + Just the Docs (tema, búsqueda, mermaid)
├── _sass/
│   ├── color_schemes/therapets-dark.scss   # Esquema oscuro (negro + morado)
│   └── custom/custom.scss                   # Ajustes de estilo extra
├── _includes/
│   ├── nav_footer_custom.html  # Selector de idioma en la barra lateral
│   └── mermaid_config.js       # Tema oscuro para los diagramas Mermaid
├── index.md                    # Inicio (ES)
├── guia-usuario.md             # Padre: Guía del Usuario (ES)
├── desarrollo.md               # Padre: Para Desarrolladores (ES)
├── *.md                        # Páginas ES
├── Gemfile                     # Solo para previsualizar en local
└── en/                         # Espejo en inglés
```

## Previsualizar en local

```bash
cd docs
bundle install
bundle exec jekyll serve
# abre http://127.0.0.1:4000
```

> GitHub Pages compila el sitio en su servidor; el `Gemfile` es solo para tu
> previsualización local.
{: .note }

## Añadir una página

1. Crea `docs/mi-pagina.md` con *front matter* de Just the Docs:

```yaml
---
title: Mi Página
parent: Guía del Usuario     # o "Para Desarrolladores"
lang: es
nav_order: 12                # posición en el menú
---
```

2. La navegación lateral se genera **sola** a partir de `title`, `parent` y
   `nav_order`. Los padres tienen `has_children: true`.
3. Crea el espejo en inglés en `docs/en/mi-pagina.md` con `parent: User Guide` (o
   `Developer Docs`) y `lang: en`.

## Reglas bilingües

- **Español** vive en `docs/` (idioma primario). **Inglés** en `docs/en/`.
- Los padres de sección tienen títulos **únicos** por idioma:
  - ES: `Guía del Usuario`, `Para Desarrolladores`
  - EN: `User Guide`, `Developer Docs`
- El selector 🇪🇸/🇬🇧 (abajo en la barra lateral) salta entre las portadas de cada
  idioma (`_includes/nav_footer_custom.html`).

## Recursos útiles

- **Diagramas:** bloque de código ```` ```mermaid ````; se renderiza con tema
  oscuro.
- **Callouts:** `{: .note }`, `{: .tip }`, `{: .warning }`, `{: .danger }` tras un
  blockquote.
- **Botones:** `[Texto](url){: .btn .btn-purple }`.
- **Imágenes/capturas:** guárdalas en `docs/assets/images/screenshots/` y
  enlázalas con ruta relativa.

## Despliegue

Cada push a `main` que toque `/docs` republica el sitio automáticamente (GitHub
Pages). No hay workflow extra: Pages detecta Jekyll y compila.

> Si cambias el tema o `_config.yml` y el build de Pages falla, revisa la pestaña
> **Actions / Pages** del repo para ver el log de Jekyll.
{: .warning }
