{ pkgs, ... }:
let
  mkdocsEnv = pkgs.python3.withPackages (ps: [
    ps.mkdocs
    ps.mkdocs-material
    ps.mkdocs-ezlinks-plugin
  ]);
in
{
  home.file.".config/mkdocs/notes.yml".text = ''
    site_name: Notes
    docs_dir: /home/mallain/Google Drive/05 Notes
    theme:
      name: material
      font: false
      features:
        - navigation.indexes
        - navigation.instant
        - navigation.instant.progress
        - navigation.top
        - toc.follow
        - search.suggest
        - search.highlight
        - content.code.copy
    extra_css:
      - stylesheets/brand.css
    favicon: stylesheets/favicon.svg
    not_in_nav: |
      **/_*.md
      **/*-index.md
    use_directory_urls: false
    plugins:
      - search
      - ezlinks
    markdown_extensions:
      - pymdownx.tasklist:
          custom_checkbox: true
      - admonition
      - pymdownx.details
      - footnotes
      - pymdownx.highlight:
          anchor_linenums: true
      - pymdownx.superfences
      - pymdownx.inlinehilite
      - pymdownx.mark
  '';

  home.file."Google Drive/05 Notes/stylesheets/favicon.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
      <rect width="32" height="32" rx="5" fill="#f0ebe0"/>
      <text x="16" y="25" font-family="Palatino, 'Palatino Linotype', Georgia, serif"
            font-size="23" font-weight="normal" text-anchor="middle" fill="#b5945b">A</text>
    </svg>
  '';

  home.file."Google Drive/05 Notes/stylesheets/brand.css".text = ''
    :root {
      --serif: et-book, Palatino, "Palatino Linotype", Georgia, serif;

      /* sepia palette */
      --md-default-bg-color:          #f0ebe0;
      --md-default-fg-color:          #111111;
      --md-default-fg-color--light:   #555555;
      --md-default-fg-color--lighter: #999999;

      /* header matches body background — no colored bar */
      --md-primary-fg-color:          #f0ebe0;
      --md-primary-fg-color--light:   #f5f1e8;
      --md-primary-fg-color--dark:    #e4ddd0;
      --md-primary-bg-color:          #111111;
      --md-primary-bg-color--light:   #555555;

      /* gold accent */
      --md-accent-fg-color:           #b5945b;
      --md-accent-fg-color--transparent: rgba(181, 148, 91, 0.1);
      --md-typeset-a-color:           #b5945b;

      /* code */
      --md-code-bg-color:             #e8e2d6;
      --md-code-fg-color:             #111111;

      /* footer: light sepia, not dark */
      --md-footer-bg-color:           #e4ddd0;
      --md-footer-bg-color--dark:     #d8d1c4;
      --md-footer-fg-color:           #555555;
      --md-footer-fg-color--light:    #888888;
      --md-footer-fg-color--lighter:  #aaaaaa;
    }

    /* header: hairline rule instead of shadow */
    .md-header {
      box-shadow: none;
      border-bottom: 1px solid #e0d8cc;
    }

    /* typography: et-book stack throughout */
    body,
    .md-typeset,
    .md-nav__item,
    .md-search__input {
      font-family: var(--serif);
    }

    .md-typeset h1,
    .md-typeset h2,
    .md-typeset h3,
    .md-typeset h4,
    .md-typeset h5,
    .md-typeset h6 {
      font-family: var(--serif);
      font-weight: normal;
      letter-spacing: 0.01em;
    }

    .md-typeset a,
    .md-typeset a:visited {
      color: #b5945b;
    }

    .md-typeset a:hover {
      color: #8a6e3a;
    }

    /* ==mark== highlight: warm gold wash */
    .md-typeset mark {
      background-color: rgba(181, 148, 91, 0.25);
      color: inherit;
      border-radius: 2px;
    }

    /* admonitions: sepia base, muted colored borders */
    .md-typeset .admonition,
    .md-typeset details {
      background-color: #ebe5d8;
      box-shadow: none;
      border-radius: 2px;
    }

    .md-typeset .admonition-title,
    .md-typeset summary {
      background-color: rgba(0, 0, 0, 0.04);
      font-family: var(--serif);
      font-weight: bold;
    }

    /* note / info / abstract — slate blue */
    .md-typeset .admonition.note,   .md-typeset details.note,
    .md-typeset .admonition.info,   .md-typeset details.info,
    .md-typeset .admonition.abstract, .md-typeset details.abstract { border-color: #6b8cae; }
    .md-typeset .note > .admonition-title,     .md-typeset .note > summary,
    .md-typeset .info > .admonition-title,     .md-typeset .info > summary,
    .md-typeset .abstract > .admonition-title, .md-typeset .abstract > summary { background-color: rgba(107, 140, 174, 0.1); }
    .md-typeset .note > .admonition-title::before,     .md-typeset .note > summary::before,
    .md-typeset .info > .admonition-title::before,     .md-typeset .info > summary::before,
    .md-typeset .abstract > .admonition-title::before, .md-typeset .abstract > summary::before { background-color: #6b8cae; }

    /* tip / success / question — sage green */
    .md-typeset .admonition.tip,      .md-typeset details.tip,
    .md-typeset .admonition.success,  .md-typeset details.success,
    .md-typeset .admonition.question, .md-typeset details.question { border-color: #7a9e7e; }
    .md-typeset .tip > .admonition-title,      .md-typeset .tip > summary,
    .md-typeset .success > .admonition-title,  .md-typeset .success > summary,
    .md-typeset .question > .admonition-title, .md-typeset .question > summary { background-color: rgba(122, 158, 126, 0.1); }
    .md-typeset .tip > .admonition-title::before,      .md-typeset .tip > summary::before,
    .md-typeset .success > .admonition-title::before,  .md-typeset .success > summary::before,
    .md-typeset .question > .admonition-title::before, .md-typeset .question > summary::before { background-color: #7a9e7e; }

    /* warning — amber */
    .md-typeset .admonition.warning, .md-typeset details.warning { border-color: #c4923a; }
    .md-typeset .warning > .admonition-title, .md-typeset .warning > summary { background-color: rgba(196, 146, 58, 0.1); }
    .md-typeset .warning > .admonition-title::before, .md-typeset .warning > summary::before { background-color: #c4923a; }

    /* failure / danger / bug — terracotta */
    .md-typeset .admonition.failure, .md-typeset details.failure,
    .md-typeset .admonition.danger,  .md-typeset details.danger,
    .md-typeset .admonition.bug,     .md-typeset details.bug { border-color: #b5605a; }
    .md-typeset .failure > .admonition-title, .md-typeset .failure > summary,
    .md-typeset .danger > .admonition-title,  .md-typeset .danger > summary,
    .md-typeset .bug > .admonition-title,     .md-typeset .bug > summary { background-color: rgba(181, 96, 90, 0.1); }
    .md-typeset .failure > .admonition-title::before, .md-typeset .failure > summary::before,
    .md-typeset .danger > .admonition-title::before,  .md-typeset .danger > summary::before,
    .md-typeset .bug > .admonition-title::before,     .md-typeset .bug > summary::before { background-color: #b5605a; }

    /* example — mauve */
    .md-typeset .admonition.example, .md-typeset details.example { border-color: #9b85b0; }
    .md-typeset .example > .admonition-title, .md-typeset .example > summary { background-color: rgba(155, 133, 176, 0.1); }
    .md-typeset .example > .admonition-title::before, .md-typeset .example > summary::before { background-color: #9b85b0; }

    /* quote — warm brown-grey */
    .md-typeset .admonition.quote, .md-typeset details.quote { border-color: #8a8070; }
    .md-typeset .quote > .admonition-title, .md-typeset .quote > summary { background-color: rgba(138, 128, 112, 0.1); }
    .md-typeset .quote > .admonition-title::before, .md-typeset .quote > summary::before { background-color: #8a8070; }

    /* section title links: disable navigation, let label toggle the section instead */
    .md-nav__item--section > label.md-nav__link a {
      pointer-events: none;
      cursor: default;
    }

    /* active nav item: match Material's more specific selector */
    .md-nav__item .md-nav__link--active,
    .md-nav__item .md-nav__link--active code {
      color: #b5945b;
      font-weight: bold;
    }
  '';

  systemd.user.services.mkdocs-notes-build = {
    Unit.Description = "mkdocs notes static site build";
    Service = {
      Type = "oneshot";
      ExecStart = "${mkdocsEnv}/bin/mkdocs build -f %h/.config/mkdocs/notes.yml -d /var/lib/mkdocs-notes/site";
    };
  };

  systemd.user.timers.mkdocs-notes-build = {
    Unit.Description = "Rebuild mkdocs notes static site periodically";
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
