# TODO

- [x] Add `home.file` entries using `config.lib.file.mkOutOfStoreSymlink` in `home/base.nix` to replace dotbot symlinks
- [ ] Wire up private dotfiles symlinks (currently skipped — requires `anduril-private-dotfiles` and `private` submodules):
  - `~/.aliases/bastian_aliases.sh`, `~/.andurilrc`, `~/.bastianrc`
  - `~/.machines`, `~/.projects`, `~/.tmuxp`
  - `~/.ssh/config`
  - `~/.claude`, `~/.claude.json`
- [ ] Wire up `~/.config/systemd/user/nixseparatedebuginfod.service` once nixseparatedebuginfod is configured
- [ ] Deduplicate packages between `modules/common/base.nix` (system-wide) and `home/base.nix` (home-manager)
- [x] Migrate immich server from ubuntu machine
- [ ] Setup sops
- [ ] Evaluate adding a GitHub personal access token to the Anduril SOPS secrets file and generating a runtime Nix config section (`access-tokens = github.com=...`) to avoid unauthenticated API rate limits during flake updates; keep the decrypted token out of Git and the Nix store
- [ ] Test sway or hyprland
- [ ] Switch fractal from blueman to overskride for bluetooth management
- [ ] Test swaync as a replacement for mako (notification drawer + history)
- [ ] Document `--use-remote-sudo` / `--sudo` build method for configs with private flake inputs (e.g. `sops-secrets`); check with colleagues whether this is standard practice
- [ ] Re-test flameshot multi-monitor after niri update — niri#117 fix (merged ~2026-09-18) should make flameshot's grim adapter capture all outputs
- [ ] Experiment with mako clickable notifications — use `on-button-left` with `exec` to focus a tmux pane for claude-queue notifications
- [ ] Waybar styling pass — menu bar feels clunky, revisit spacing/sizing/layout
