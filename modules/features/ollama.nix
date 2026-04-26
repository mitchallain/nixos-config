{
  config,
  lib,
  pkgs,
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
      acceleration = "cuda";
      # Bind only to the microvm bridge interface — not exposed on LAN
      host = "10.0.0.1";
      port = 11434;
    };

    # Pull declared models after ollama starts
    systemd.services.ollama-pull-models = {
      description = "Pull Ollama models declared in mySystem.ollama.models";
      after = [ "ollama.service" ];
      wants = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart =
          let
            pullScript = pkgs.writeShellScript "ollama-pull" ''
              set -e
              export OLLAMA_HOST="http://10.0.0.1:11434"
              ${concatMapStringsSep "\n" (model: ''
                echo "Pulling model: ${model}"
                ${pkgs.ollama}/bin/ollama pull ${model}
              '') config.mySystem.ollama.models}
            '';
          in
          "${pullScript}";
      };
    };
  };
}
