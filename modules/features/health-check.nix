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
    environment.systemPackages = [ healthCheck ];

    systemd.services.health-check = {
      description = "System health check";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
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
