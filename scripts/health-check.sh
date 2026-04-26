#!/usr/bin/env bash
# System health check — fractal
# Sections: ZFS (pool omega), Immich
# Exit 0 = all checks pass; exit 1 = one or more failures
# Warnings do not affect exit code.
set -uo pipefail

POOL="omega"
IMMICH_PORT="2283"
IMMICH_PING="http://localhost:${IMMICH_PORT}/api/server/ping"
BACKUP_DIR="/mnt/omega/99-postgres-backup"
SCRUB_WARN_DAYS=35
BACKUP_FAIL_DAYS=8

result=0

header() { printf '\n[%s]\n' "$1"; }
ok()     { printf '  %-20s OK (%s)\n'   "$1:" "$2"; }
warn()   { printf '  %-20s WARN (%s)\n' "$1:" "$2"; }
fail()   { printf '  %-20s FAIL (%s)\n' "$1:" "$2"; result=1; }

printf '=== Health Check: %s — %s ===\n' "${HOSTNAME}" "$(date '+%Y-%m-%d %H:%M')"

# ── ZFS ───────────────────────────────────────────────────────────────────────
header "ZFS"

# Pool health
state=$(sudo zpool status "${POOL}" 2>/dev/null | awk '/^\s*state:/{print $2}') || state=""
if [[ "$state" == "ONLINE" ]]; then
  ok "Pool ${POOL}" "$state"
else
  fail "Pool ${POOL}" "${state:-unavailable}"
fi

# Capacity
cap_raw=$(sudo zpool list -Hp -o cap "${POOL}" 2>/dev/null) || cap_raw=""
cap="${cap_raw//[^0-9]/}"
if [[ -z "$cap" ]]; then
  fail "Capacity" "could not read capacity"
elif (( cap >= 90 )); then
  fail "Capacity" "${cap}% used"
elif (( cap >= 80 )); then
  warn "Capacity" "${cap}% used"
else
  ok "Capacity" "${cap}% used"
fi

# Scrub results
scrub_line=$(sudo zpool status "${POOL}" 2>/dev/null | grep '^\s*scan:') || scrub_line=""
if echo "$scrub_line" | grep -q "scrub repaired"; then
  errors=$(echo "$scrub_line" | grep -oP 'with \K\d+(?= errors)') || errors="0"
  scrub_date=$(echo "$scrub_line" | grep -oP 'on \K\w+ \w+ +\d+ [\d:]+ \d+$') || scrub_date=""
  scrub_epoch=$(date -d "$scrub_date" +%s 2>/dev/null) || scrub_epoch=0
  now_epoch=$(date +%s)
  age_days=$(( (now_epoch - scrub_epoch) / 86400 ))
  if [[ "${errors}" != "0" ]]; then
    fail "Last scrub" "${errors} errors on ${scrub_date}"
  elif (( age_days > SCRUB_WARN_DAYS )); then
    warn "Last scrub" "${age_days} days ago (>${SCRUB_WARN_DAYS}d threshold)"
  else
    ok "Last scrub" "${age_days} days ago, 0 errors"
  fi
elif echo "$scrub_line" | grep -q "scrub in progress"; then
  ok "Last scrub" "in progress"
else
  warn "Last scrub" "no completed scrub found"
fi

# ── Immich ────────────────────────────────────────────────────────────────────
header "Immich"

# Service status
svc=$(systemctl is-active immich-server 2>/dev/null) || svc="unknown"
if [[ "$svc" == "active" ]]; then
  ok "Service" "active"
else
  fail "Service" "$svc"
fi

# HTTP liveness
http_code=$(curl -sf -o /dev/null -w "%{http_code}" "${IMMICH_PING}" 2>/dev/null) || http_code="000"
if [[ "$http_code" == "200" ]]; then
  ok "HTTP ping" "200"
else
  fail "HTTP ping" "got ${http_code}"
fi

# Postgres backup recency
if [[ ! -d "$BACKUP_DIR" ]]; then
  fail "DB backup" "directory not found: ${BACKUP_DIR}"
else
  newest=$(find "$BACKUP_DIR" -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1)
  if [[ -z "$newest" ]]; then
    fail "DB backup" "no backup files found in ${BACKUP_DIR}"
  else
    now_epoch=$(date +%s)
    age_days=$(( (now_epoch - ${newest%.*}) / 86400 ))
    if (( age_days <= BACKUP_FAIL_DAYS )); then
      ok "DB backup age" "${age_days} days ago"
    else
      fail "DB backup age" "${age_days} days ago (expected <=${BACKUP_FAIL_DAYS})"
    fi
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo
if (( result == 0 )); then
  echo "=== RESULT: PASS ==="
else
  echo "=== RESULT: FAIL ==="
fi

exit $result
