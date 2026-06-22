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
    hostname = mkOption {
      type = types.str;
      default = "notes.home";
      description = "Nginx virtual host name";
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
      virtualHosts.${config.mySystem.notes.hostname} = {
        basicAuthFile = config.sops.secrets.notes_htpasswd.path;
        locations."/" = {
          root = config.mySystem.notes.staticSiteDir;
          index = "index.html";
          tryFiles = "$uri $uri/ $uri.html =404";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
