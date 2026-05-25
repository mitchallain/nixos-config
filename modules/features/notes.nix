{ config, lib, ... }:
with lib;
{
  options.mySystem.notes = {
    enable = mkEnableOption "mkdocs notes server with nginx basic auth";
    staticSiteDir = mkOption {
      type = types.str;
      default = "/var/lib/mkdocs-notes/site";
      description = "Path to the pre-built static MkDocs site directory";
    };
  };

  config = mkIf config.mySystem.notes.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/mkdocs-notes      0755 mallain users -"
      "d /var/lib/mkdocs-notes/site 0755 mallain users -"
    ];

    sops.secrets.notes_htpasswd = {
      owner = "nginx";
      mode = "0440";
    };

    services.nginx = {
      enable = true;
      virtualHosts."notes" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = 8000;
            ssl = false;
          }
        ];
        basicAuthFile = config.sops.secrets.notes_htpasswd.path;
        locations."/" = {
          root = config.mySystem.notes.staticSiteDir;
          index = "index.html";
          tryFiles = "$uri $uri/ $uri.html =404";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 8000 ];
  };
}
