{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.healthCheck;

  runtimeDeps = with pkgs; [
    zfs
    curl
    findutils
    coreutils
    gnugrep
    gawk
    sudo
    systemd
  ];

  healthCheck = pkgs.writeShellScriptBin "health-check" ''
    export PATH="${makeBinPath runtimeDeps}:$PATH"
    exec ${pkgs.bash}/bin/bash ${../../scripts/health-check.sh} "$@"
  '';
in
{
  options.mySystem.healthCheck = {
    enable = mkEnableOption "daily system health check";

    schedule = mkOption {
      type = types.str;
      default = "daily";
      description = "Systemd OnCalendar expression for the health check timer";
    };
  };

  config = mkIf cfg.enable {
    users.users.health-check = {
      isSystemUser = true;
      group = "health-check";
      description = "Health check service user";
    };
    users.groups.health-check = { };

    security.sudo.extraRules = [
      {
        users = [ "health-check" ];
        commands = [
          {
            command = "${pkgs.zfs}/bin/zpool";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    environment.systemPackages = [ healthCheck ];

    systemd.services.health-check = {
      description = "System health check";
      serviceConfig = {
        Type = "oneshot";
        User = "health-check";
        ExecStart = "${healthCheck}/bin/health-check";
      };
    };

    systemd.timers.health-check = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
    };
  };
}
