{ config, lib, ... }:
with lib;
let
  cfg = config.mySystem.localDns;
in
{
  options.mySystem.localDns = {
    enable = mkEnableOption "local DNS server";

    listenAddress = mkOption {
      type = types.str;
      description = "LAN IP address dnsmasq binds to (should be a static lease)";
    };

    upstreamServers = mkOption {
      type = types.listOf types.str;
      default = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      description = "Upstream DNS servers for non-local queries";
    };

    hosts = mkOption {
      type = types.attrsOf types.str;
      default = { };
      # address= records take precedence over upstream for these FQDNs only;
      # all other queries for the same domain resolve normally upstream.
      description = "FQDN → IP mappings served locally";
      example = literalExpression ''
        {
          "immich.mitchellallain.com" = "192.168.50.154";
          "notes.mitchellallain.com"  = "192.168.50.154";
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;
      resolveLocalQueries = true;
      settings = {
        address = mapAttrsToList (fqdn: ip: "/${fqdn}/${ip}") cfg.hosts;
        listen-address = [
          "127.0.0.1"
          cfg.listenAddress
        ];
        bind-interfaces = true;
        no-resolv = true;
        server = cfg.upstreamServers;
        domain-needed = true;
        bogus-priv = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];
  };
}
