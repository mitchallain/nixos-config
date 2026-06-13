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
      font:
        text: EB Garamond
        code: Courier Prime
      features:
        - navigation.prune
    extra_css:
      - stylesheets/brand.css
    use_directory_urls: false
    plugins:
      - search
      - ezlinks
    markdown_extensions:
      - pymdownx.tasklist:
          custom_checkbox: true
  '';

  home.file."Google Drive/05 Notes/stylesheets/brand.css".text = ''
    @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;1,400&display=swap');

    :root {
      --md-primary-fg-color:        #6e8c8a;
      --md-primary-fg-color--light: #8aa8a6;
      --md-primary-fg-color--dark:  #5a7472;
      --md-accent-fg-color:         #c4783a;
      --md-default-bg-color:        #f0ebe0;
      --md-default-fg-color:        #2c2416;
      --md-default-fg-color--light: #8a7055;
      --md-code-bg-color:           #e4ddd0;
      --md-code-fg-color:           #2c2416;
      --md-footer-bg-color:         #2c2416;
      --md-footer-bg-color--dark:   #1a1008;
      --md-footer-fg-color:         #f0ebe0;
      --md-footer-fg-color--light:  #d4c9b0;
      --md-footer-fg-color--lighter: #8a7055;
    }

    .md-typeset h1,
    .md-typeset h2,
    .md-typeset h3,
    .md-typeset h4,
    .md-typeset h5,
    .md-typeset h6 {
      font-family: 'Cormorant Garamond', Georgia, serif;
      font-weight: 600;
    }

    .md-typeset a,
    .md-typeset a:visited {
      color: #3d5453;
    }

    .md-typeset a:hover {
      color: #c4783a;
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
