{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
with lib;
{
  options.mySystem.ollama = {
    enable = mkEnableOption "Ollama local inference server";
    models = mkOption {
      type = types.listOf types.str;
      default = [ "qwen3.5:9b" ];
      description = "Models to pull on activation via ollama pull";
    };
  };

  config = mkIf config.mySystem.ollama.enable {
    services.ollama = {
      enable = true;
      package = pkgs-unstable.ollama-cuda;
      # Listen on all interfaces; firewall restricts to microvm bridge only
      host = "0.0.0.0";
      port = 11434;
    };

    # Allow Ollama port only from the microvm bridge interface — blocks LAN access
    networking.firewall.interfaces.microvm0.allowedTCPPorts = [ 11434 ];

    # Pull declared models after ollama starts
    systemd.services.ollama-pull-models = {
      description = "Pull Ollama models declared in mySystem.ollama.models";
      after = [ "ollama.service" "network-online.target" ];
      wants = [ "ollama.service" "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "ollama-pull" (
          ''
            set -e
            export HOME=/root
            export OLLAMA_HOST="127.0.0.1:11434"
          ''
          + concatMapStrings (model: ''
            echo "Pulling model: ${model}"
            ${pkgs-unstable.ollama-cuda}/bin/ollama pull "${model}"
          '') config.mySystem.ollama.models
        );
      };
    };
  };
}
