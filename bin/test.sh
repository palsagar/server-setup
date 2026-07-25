#!/usr/bin/env bash
# Build per-distro sshd test images, provision them via playbook.yml over real
# SSH, run tests/verify.yml, then re-run the playbook to prove idempotency.
set -euo pipefail

cd "$(dirname "$0")/.."

# macOS: python forks using SSL crash without this (url lookup → github .keys)
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

DISTROS="debian12 debian13 ubuntu2204 ubuntu2404"
PLATFORM="${PLATFORM:-linux/amd64}"
KEY=tests/keys/id_ed25519
INV=tests/inventory.ini

port_for() {
  case "$1" in
    debian12)   echo 2221 ;;
    debian13)   echo 2222 ;;
    ubuntu2204) echo 2223 ;;
    ubuntu2404) echo 2224 ;;
  esac
}

cleanup() {
  for d in $DISTROS; do
    docker rm -f "sst-$d" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

# 1. throwaway test keypair
[ -f "$KEY" ] || ssh-keygen -t ed25519 -f "$KEY" -N '' -q

# 2. build + run all containers
for d in $DISTROS; do
  docker rm -f "sst-$d" >/dev/null 2>&1 || true
  echo "== build $d ($PLATFORM)"
  docker build --platform "$PLATFORM" -q -f "tests/Dockerfile.$d" -t "server-setup-test-$d" tests/ >/dev/null
  docker run -d --platform "$PLATFORM" -p "127.0.0.1:$(port_for "$d"):22" --name "sst-$d" "server-setup-test-$d" >/dev/null
done

# 3. ephemeral inventory
: > "$INV"
for d in $DISTROS; do
  echo "sst-$d ansible_host=127.0.0.1 ansible_port=$(port_for "$d") ansible_user=root ansible_ssh_private_key_file=$KEY" >> "$INV"
done

# 4. wait for sshd
for d in $DISTROS; do
  printf '== waiting for sst-%s sshd...' "$d"
  for _ in $(seq 1 60); do
    nc -z 127.0.0.1 "$(port_for "$d")" >/dev/null 2>&1 && break
    sleep 1
  done
  nc -z 127.0.0.1 "$(port_for "$d")" >/dev/null 2>&1 || { echo " TIMEOUT"; exit 1; }
  echo " up"
done

# 5. provision (production path)
echo "== provisioning all distros"
prov_log=$(mktemp)
if ! ansible-playbook -i "$INV" -c ssh playbook.yml | tee "$prov_log"; then
  echo "PROVISION FAILED"; exit 1
fi

# 6. verify
echo "== verifying"
ver_log=$(mktemp)
if ! ansible-playbook -i "$INV" -e @group_vars/all.yml tests/verify.yml | tee "$ver_log"; then
  echo "VERIFY FAILED"; exit 1
fi

# 7. idempotency re-run
echo "== idempotency re-run"
idem_log=$(mktemp)
ansible-playbook -i "$INV" -c ssh playbook.yml | tee "$idem_log"

# 8. per-distro PASS/FAIL
status=0
for d in $DISTROS; do
  prov=$(grep -E "^sst-$d\s*:" "$prov_log" | tail -1 || true)
  ver=$(grep -E "^sst-$d\s*:" "$ver_log" | tail -1 || true)
  idem=$(grep -E "^sst-$d\s*:" "$idem_log" | tail -1 || true)
  ok=yes
  echo "$prov$ver$idem" | grep -qE 'failed=[1-9]|unreachable=[1-9]' && ok=no
  echo "$idem" | grep -qE 'changed=[1-9]' && ok=no
  [ -n "$prov" ] && [ -n "$ver" ] && [ -n "$idem" ] || ok=no
  if [ "$ok" = yes ]; then
    echo "PASS $d"
  else
    echo "FAIL $d"
    status=1
  fi
done

exit "$status"
