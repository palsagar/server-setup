# server-setup

Ansible runbook that reproduces my full CLI environment (zsh + Oh My Zsh +
Powerlevel10k, fzf, eza, fd, bat, zoxide, yazi, lazygit, btop, tmux + plugins,
neovim + my LazyVim config, uv, thefuck, docker-ce) on fresh Debian/Ubuntu VPS
servers. Design decisions and per-tool install map: [SPEC.md](SPEC.md).

Push-style: the playbook runs from my Mac against the VPS over SSH. The VPS
needs nothing preinstalled except sshd.

## One-time Mac setup

```sh
make setup          # installs ansible-core via `uv tool`
```

Requires: [uv](https://docs.astral.sh/uv/), Docker Desktop (for local tests),
GNU make (ships with macOS).

## Setting up a new VPS

1. **Create the VPS** (Debian 12/13 or Ubuntu 22.04/24.04) and make sure you can
   SSH in as root with a key:

   ```sh
   ssh root@<vps-ip>      # add your key in the provider panel first if needed
   ```

2. **Check your GitHub keys.** The playbook creates user `sagar` and seeds its
   `authorized_keys` from <https://github.com/palsagar.keys>. The public key
   whose private half you use daily must be listed there — otherwise you'll
   provision a user you can't log in as. (Extra keys can go in
   `roles/user/files/keys/*.pub`.)

3. **Provision:**

   ```sh
   make provision HOST=<vps-ip>
   ```

   This installs everything and sets `sagar`'s shell to zsh.

4. **Log in:**

   ```sh
   ssh sagar@<vps-ip>
   ```

5. **Optional:** add machine-specific secrets (API keys etc.) to
   `~/.zshrc.local` on the server — the deployed `.zshrc` sources it if present.
   Never commit secrets here; this repo is **public**.

## Re-running / updating an existing server

```sh
make provision HOST=<vps-ip>                 # full run (idempotent)
make converge HOST=<vps-ip> TAGS=tools       # re-run one role only
```

Bump tool versions in `group_vars/all.yml`, then re-provision.

## Testing locally (no VPS needed)

Spins up sshd-enabled containers for debian:12, debian:13, ubuntu:22.04,
ubuntu:24.04, runs the playbook over real SSH, asserts every tool works, and
verifies a second run makes zero changes:

```sh
make test          # amd64 matrix
make test-arm      # arm64 matrix via QEMU (slow)
```

## Syncing dotfiles from my Mac into this repo

```sh
bin/vendor-dotfiles.sh
```

Copies `~/.zshrc` (pruning macOS-only lines and secrets per the prune list in
SPEC.md), `~/.p10k.zsh`, `~/.tmux.conf`, and `~/.config/nvim` into the repo.
Review the diff before committing.
