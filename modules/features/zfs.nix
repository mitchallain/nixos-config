{ config, lib, pkgs, ... }:
with lib;
{
  options.mySystem.zfs = {
    enable = mkEnableOption "ZFS filesystem support";

    autoScrub = mkOption {
      type = types.bool;
      default = true;
      description = "Enable periodic ZFS scrubbing";
    };

    autoSnapshot = mkOption {
      type = types.bool;
      default = false;
      description = "Enable automatic ZFS snapshots";
    };
  };

  config = mkIf config.mySystem.zfs.enable {
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;

    environment.systemPackages = with pkgs; [
      zfs
      zfstools
    ];

    services.zfs.autoScrub.enable = config.mySystem.zfs.autoScrub;
    services.zfs.autoSnapshot.enable = config.mySystem.zfs.autoSnapshot;
  };
}
