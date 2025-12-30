#!/usr/bin/env bash
set -euo pipefail

USER="vscode"
USER_HOME="/home/${USER}"
SSH_DIR="${USER_HOME}/.ssh"
AUTH_KEYS="${SSH_DIR}/authorized_keys"

log() { printf "%s %s\n" "$(date --iso-8601=seconds)" "$*"; }

install_keys() {
  local content="$1"
  mkdir -p "${SSH_DIR}"
  # Append so multiple runs don't overwrite unless deliberately replaced by repo file
  printf "%s\n" "${content}" >> "${AUTH_KEYS}"
  chown -R "${USER}:${USER}" "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"
  chmod 600 "${AUTH_KEYS}"
  log "Installed SSH key(s) into ${AUTH_KEYS}."
}

# 1) If SSH_PUBLIC_KEY env var is set (Codespaces repo secret), install that.
if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  log "Adding SSH public key from SSH_PUBLIC_KEY environment variable..."
  install_keys "${SSH_PUBLIC_KEY}"
  # Optionally disable password authentication automatically (commented out by default).
  # sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
  # sudo systemctl reload sshd || true
  exit 0
fi

# 2) If repo contains .devcontainer/authorized_keys, copy it
REPO_AUTH="$(pwd)/.devcontainer/authorized_keys"
if [ -f "${REPO_AUTH}" ]; then
  log "Found .devcontainer/authorized_keys in repo; installing..."
  mkdir -p "${SSH_DIR}"
  cp "${REPO_AUTH}" "${AUTH_KEYS}"
  chown -R "${USER}:${USER}" "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"
  chmod 600 "${AUTH_KEYS}"
  log "Installed authorized_keys from repository file."
  exit 0
fi

log "No SSH public key provided."
log "To inject a key, set the SSH_PUBLIC_KEY repository secret in Codespaces or add .devcontainer/authorized_keys to the repository."
exit 0