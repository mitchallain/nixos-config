{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.mySystem.immich = {
    enable = mkEnableOption "Immich photo management server";
    hostname = mkOption {
      type = types.str;
      default = "immich.home";
      description = "Nginx virtual host name";
    };
  };

  config = mkIf config.mySystem.immich.enable {
    services.immich = {
      enable = true;
      host = "0.0.0.0";
      port = 2283;
      openFirewall = true;

      # Matches UPLOAD_LOCATION from Ubuntu docker config
      # WARNING: changing this after first start requires a database reset
      mediaLocation = "/mnt/omega/02 Pictures and Videos/06 Immich Library";

      # GPU acceleration via Nvidia
      accelerationDevices = null;
    };

    services.nginx = {
      enable = true;
      virtualHosts.${config.mySystem.immich.hostname} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.immich.port}";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 50000m;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
          '';
        };
      };
    };

    # Required for GPU acceleration
    users.users.immich.extraGroups = [
      "video"
      "render"
    ];

    # Weekly postgres backup to omega
    services.postgresqlBackup = {
      enable = true;
      databases = [ "immich" ];
      location = "/mnt/omega/99-postgres-backup";
      startAt = "weekly";
    };
  };
}
