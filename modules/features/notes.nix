{ config, lib, ... }:
with lib;
{
  options.mySystem.notes.enable = mkEnableOption "mkdocs notes server with nginx basic auth";

  config = mkIf config.mySystem.notes.enable {
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
          proxyPass = "http://127.0.0.1:7000";
          proxyWebsockets = true;
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 8000 ];
  };
}
