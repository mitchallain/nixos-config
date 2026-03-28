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
- [ ] Test sway or hyprland
- [ ] Test swaync as a replacement for mako (notification drawer + history)
