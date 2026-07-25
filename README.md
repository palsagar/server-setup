# server-setup

Ansible runbook that reproduces my full CLI environment (zsh + Oh My Zsh +
Powerlevel10k, fzf, eza, fd, bat, zoxide, yazi, lazygit, btop, tmux + plugins,
neovim + my LazyVim config, uv, thefuck, docker-ce) on fresh Debian/Ubuntu VPS
servers. Design decisions and per-tool install map: [SPEC.md](SPEC.md).

Push-style: the playbook runs from my Mac against the VPS over SSH as root. The
VPS needs nothing preinstalled except sshd. No extra user accounts are created —
everything is installed for root.

## One-time Mac setup

```sh
make setup          # installs ansible-core via `uv tool`
```

Requires: [uv](https://docs.astral.sh/uv/), Docker Desktop (for local tests),
GNU make (ships with macOS).

## Setting up a new VPS

1. **Create the VPS** (Debian 12/13 or Ubuntu 22.04/24.04), log in as root, and
   set up key-based SSH — generate a keypair on this Mac and install the public
   half on the VPS (provider panel or `ssh-copy-id`):

   ```sh
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519-vps
   ssh-copy-id -i ~/.ssh/id_ed25519-vps.pub root@<vps-ip>
   ssh -i ~/.ssh/id_ed25519-vps root@<vps-ip>   # confirm key login works
   ```

2. **Provision**, pointing `KEY` at the private half of that keypair:

   ```sh
   make provision HOST=<vps-ip> KEY=~/.ssh/id_ed25519-vps
   ```

   This installs everything for root and sets root's login shell to zsh.

3. **Log in:**

   ```sh
   ssh -i ~/.ssh/id_ed25519-vps root@<vps-ip>
   ```

4. **Optional:** add machine-specific secrets (API keys etc.) to
   `~/.zshrc.local` on the server — the deployed `.zshrc` sources it if present.
   Never commit secrets here; this repo is **public**.

## Re-running / updating an existing server

```sh
make provision HOST=<vps-ip> KEY=~/.ssh/id_ed25519-vps                 # full run (idempotent)
make converge HOST=<vps-ip> KEY=~/.ssh/id_ed25519-vps TAGS=tools       # re-run one role only
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
