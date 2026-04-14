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
    Unit.Description = "mkdocs notes server";
    Unit.After = [ "network.target" ];
    Service = {
      ExecStart = "${mkdocsEnv}/bin/mkdocs serve --dev-addr 127.0.0.1:7000 -f %h/.config/mkdocs/notes.yml";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
