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
    use_directory_urls: false
    plugins:
      - search
      - ezlinks
    markdown_extensions:
      - pymdownx.tasklist:
          custom_checkbox: true
  '';

  systemd.user.services.mkdocs-notes = {
    Unit.Description = "mkdocs notes live-reload server (localhost only)";
    Unit.After = [ "network.target" ];
    Service = {
      ExecStart = "${mkdocsEnv}/bin/mkdocs serve --dev-addr 127.0.0.1:7000 -f %h/.config/mkdocs/notes.yml";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

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
