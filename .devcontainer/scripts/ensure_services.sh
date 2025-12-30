#!/usr/bin/env bash
set -euo pipefail

# This script is intended to run as the 'vscode' user inside the Codespace (postStartCommand).
# It ensures ssh and xrdp services are running and listening on their expected ports.

SSH_PORT=2222
RDP_PORT=3389
MAX_ATTEMPTS=6
SLEEP_BETWEEN=2

log() { printf "%s %s\n" "$(date --iso-8601=seconds)" "$*"; }

# Check whether a TCP port is listening (IPv4/IPv6)
is_listening() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "( sport = :$port )" >/dev/null 2>&1 && return 0 || return 1
  elif command -v netstat >/dev/null 2>&1; then
    netstat -ltn | grep -q ":$port" && return 0 || return 1
  else
    # fallback: try /proc/net/tcp (hex port)
    grep -q ":$(printf '%04X' "$port")" /proc/net/tcp 2>/dev/null && return 0 || return 1
  fi
}

start_service_if_needed() {
  local svc="$1"
  local svc_alt="$2"
  if pgrep -x "$svc" >/dev/null 2>&1 || ( [ -n "$svc_alt" ] && pgrep -x "$svc_alt" >/dev/null 2>&1 ); then
    log "$svc already running."
    return 0
  fi

  log "Attempting to start $svc via service scripts..."
  if sudo service "$svc" start >/dev/null 2>&1 || ( [ -n "$svc_alt" ] && sudo service "$svc_alt" start >/dev/null 2>&1 ); then
    log "service start command for $svc returned successfully."
    return 0
  fi

  # last-resort: try the binary directly (non-blocking)
  if [ "$svc" = "ssh" ] || [ "$svc" = "sshd" ]; then
    if [ -x /usr/sbin/sshd ]; then
      log "Starting /usr/sbin/sshd (background)..."
      sudo /usr/sbin/sshd || true
      return 0
    fi
  fi

  if [ "$svc" = "xrdp" ] || [ "$svc" = "xrdp-sesman" ]; then
    if [ -x /usr/sbin/xrdp-sesman ]; then
      log "Starting /usr/sbin/xrdp-sesman (background)..."
      sudo /usr/sbin/xrdp-sesman || true
    fi
    if [ -x /usr/sbin/xrdp ]; then
      log "Starting /usr/sbin/xrdp (background)..."
      sudo /usr/sbin/xrdp || true
    fi
  fi

  return 1
}

ensure_listening() {
  local port="$1"
  local svc="$2"
  local svc_alt="${3:-}"
  local attempt=1

  while [ $attempt -le $MAX_ATTEMPTS ]; do
    if is_listening "$port"; then
      log "$svc is listening on port $port."
      return 0
    fi

    log "$svc is not listening on port $port (attempt $attempt/$MAX_ATTEMPTS). Starting service..."
    start_service_if_needed "$svc" "$svc_alt" || true

    sleep $SLEEP_BETWEEN
    attempt=$((attempt + 1))
  done

  if is_listening "$port"; then
    log "$svc started and is listening on port $port."
    return 0
  fi

  log "WARNING: $svc did not start or is not listening on port $port after $MAX_ATTEMPTS attempts."
  return 1
}

main() {
  log "ensure_services.sh: Ensuring ssh and xrdp are running."

  # Ensure SSH (service name 'ssh' on Debian/Ubuntu; legacy 'sshd' also checked)
  ensure_listening "$SSH_PORT" "ssh" "sshd" || log "ssh check failed."

  # Ensure xrdp and sesman (try starting them explicitly)
  start_service_if_needed "xrdp-sesman" ""
  start_service_if_needed "xrdp" ""
  ensure_listening "$RDP_PORT" "xrdp" || log "xrdp check failed."

  log "ensure_services.sh: Done."
}

main