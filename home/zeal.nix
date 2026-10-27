# home/zeal.nix - Declarative Zeal docset syncing
#
# Instead of pinning Kapeli tarballs as fixed-output derivations (which break
# whenever upstream updates the tarball in-place), this module declares a list
# of docset names and uses a systemd user timer to fetch/update them into the
# standard writable Zeal directory.
#
# Docsets are downloaded to ~/.local/share/Zeal/Zeal/docsets/ where Zeal
# expects them.  The sync script skips docsets that already exist unless
# ZEAL_FORCE_UPDATE=1 is set.
{ pkgs, lib, ... }:

let
  # Add or remove docset feed names here.
  # These correspond to https://kapeli.com/feeds/{name}.tgz
  docsets = [
    "Python"
    "C++"
    "Rust"
  ];

  # Map docset name to URL-safe feed name (only C++ needs encoding)
  feedUrl = name:
    let encoded = builtins.replaceStrings ["+"] ["%2B"] name;
    in "https://kapeli.com/feeds/${encoded}.tgz";

  syncScript = pkgs.writeShellScript "zeal-docset-sync" ''
    set -euo pipefail

    DOCSET_DIR="''${HOME}/.local/share/Zeal/Zeal/docsets"
    mkdir -p "$DOCSET_DIR"

    ${lib.concatMapStringsSep "\n" (name: ''
    (
      name="${name}"
      docset_path="$DOCSET_DIR/$name.docset"
      url="${feedUrl name}"

      if [ -d "$docset_path" ] && [ "''${ZEAL_FORCE_UPDATE:-0}" != "1" ]; then
        echo "skip: $name.docset already exists"
        exit 0
      fi

      echo "fetching: $name from $url"
      tmp=$(mktemp -d)
      trap "rm -rf '$tmp'" EXIT

      if ${pkgs.curl}/bin/curl -fSL --retry 3 --retry-delay 5 -o "$tmp/feed.tgz" "$url"; then
        mkdir -p "$tmp/extract"
        ${pkgs.gnutar}/bin/tar -xzf "$tmp/feed.tgz" -C "$tmp/extract"

        if [ -d "$docset_path" ]; then
          rm -rf "$docset_path"
        fi

        mv "$tmp/extract/$name.docset" "$docset_path"
        echo "installed: $name.docset"
      else
        echo "error: failed to fetch $name" >&2
      fi
    )
    '') docsets}

    echo "zeal-docset-sync: done"
  '';
in

{
  # Sync docsets on a timer (weekly) and on first activation
  systemd.user.services.zeal-docset-sync = {
    Unit = {
      Description = "Sync Zeal docsets from Kapeli feeds";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${syncScript}";
      Environment = "PATH=${lib.makeBinPath [ pkgs.coreutils ]}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.timers.zeal-docset-sync = {
    Unit.Description = "Weekly Zeal docset update";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true; # Run immediately if last run was missed
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
