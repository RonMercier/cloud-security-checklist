#!/bin/bash
# cloud-security-checklist — scripts/audit.sh
# Automated check of several checklist items on Linux systems.
# Covers: firewall, SSH, auto-updates, open ports, exposed credential paths.
# Usage: chmod +x scripts/audit.sh && sudo ./scripts/audit.sh

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PASS=0; WARN=0; FAIL=0

pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; ((PASS++)); }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; ((WARN++)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; ((FAIL++)); }
sec()  { echo -e "\n${CYAN}── $1 ────────────────────────────────${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo ./scripts/audit.sh"; exit 1; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SecureByDefault — Security Checklist Audit"
echo "  github.com/RonMercier/cloud-security-checklist"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── FIREWALL ──────────────────────────────────────────────────
sec "Firewall"
if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
    pass "UFW firewall is active"
elif command -v firewalld &>/dev/null && firewall-cmd --state &>/dev/null; then
    pass "firewalld is active"
else
    fail "No active firewall detected (UFW or firewalld)"
fi

sec "Open Ports"
echo "  Listening ports (external interfaces):"
ss -tlnp | grep LISTEN | awk '{print "    "$4}' | grep -v "127.0.0"
OPEN=$(ss -tlnp | grep LISTEN | awk '{print $4}' | grep -v "127.0.0" | wc -l)
if [ "$OPEN" -le 4 ]; then
    pass "$OPEN public-facing ports open (low)"
elif [ "$OPEN" -le 8 ]; then
    warn "$OPEN public-facing ports open — review the list above"
else
    fail "$OPEN public-facing ports open — reduce attack surface"
fi

# ── SSH ───────────────────────────────────────────────────────
sec "SSH Hardening"
if [ -f /etc/ssh/sshd_config ]; then
    if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
        pass "Root SSH login disabled"
    else
        fail "Root SSH login NOT disabled — set PermitRootLogin no"
    fi
    if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
        pass "SSH password auth disabled (key-only)"
    else
        warn "SSH password auth may be enabled — verify PasswordAuthentication no"
    fi
    if grep -q "^MaxAuthTries" /etc/ssh/sshd_config; then
        TRIES=$(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')
        [ "$TRIES" -le 3 ] && pass "MaxAuthTries set to $TRIES" || warn "MaxAuthTries is $TRIES — recommend 3 or lower"
    else
        warn "MaxAuthTries not set — recommend MaxAuthTries 3"
    fi
else
    warn "sshd_config not found — SSH hardening not verifiable"
fi

# ── AUTOMATIC UPDATES ─────────────────────────────────────────
sec "Automatic Updates"
if systemctl is-active --quiet unattended-upgrades 2>/dev/null; then
    pass "Unattended upgrades service running"
elif [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
    pass "Auto-upgrades config present"
else
    fail "Automatic security updates not configured"
fi

# ── EXPOSED PATHS ─────────────────────────────────────────────
sec "Credential File Exposure Check"
if command -v nginx &>/dev/null; then
    if nginx -T 2>/dev/null | grep -q "\.env\|aws\|credentials"; then
        pass "Nginx config contains rules blocking credential paths"
    else
        warn "No credential-blocking rules found in Nginx — apply securebydefault-server-hardening configs"
    fi
    if nginx -T 2>/dev/null | grep -q "server_tokens off"; then
        pass "server_tokens off (version not disclosed)"
    else
        warn "server_tokens not off — consider adding to Nginx config"
    fi
else
    warn "Nginx not detected — skip if using a different web server"
fi

# ── WEB-ACCESSIBLE FILES CHECK ───────────────────────────────
sec "Common Web Root Exposures"
WEB_ROOTS=("/var/www/html" "/var/www" "/srv/www")
DANGEROUS=(".env" ".aws" "credentials.json" "secrets.json" "config.json" "wp-config.php.bak")

for root in "${WEB_ROOTS[@]}"; do
    if [ -d "$root" ]; then
        for file in "${DANGEROUS[@]}"; do
            if find "$root" -name "$file" 2>/dev/null | grep -q .; then
                fail "Potentially dangerous file found in web root: $file (check $root)"
            fi
        done
        pass "No obvious credential files found in $root"
        break
    fi
done

# ── DISK ENCRYPTION ───────────────────────────────────────────
sec "Disk Encryption"
if command -v lsblk &>/dev/null && lsblk -o name,type | grep -q "crypt"; then
    pass "Encrypted volumes detected (LUKS)"
else
    warn "No encrypted volumes detected — verify disk encryption is configured for sensitive data"
fi

# ── FAILED LOGINS ─────────────────────────────────────────────
sec "Recent Failed Logins (last 20)"
if [ -f /var/log/auth.log ]; then
    FAILS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)
    RECENT=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5)
    if [ "$FAILS" -gt 100 ]; then
        warn "$FAILS failed login attempts in auth.log — review Fail2Ban config"
        echo "  Last 5 failures:"
        echo "$RECENT" | while IFS= read -r line; do echo "    $line"; done
    elif [ "$FAILS" -gt 0 ]; then
        pass "$FAILS failed login attempts (normal level)"
    else
        pass "No failed logins in auth.log"
    fi
fi

# ── SUMMARY ───────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Results: ${GREEN}$PASS passed${NC}  ${YELLOW}$WARN warnings${NC}  ${RED}$FAIL failed${NC}"
if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}Address FAIL items before exposing to production.${NC}"
elif [ "$WARN" -gt 0 ]; then
    echo -e "  ${YELLOW}Review WARN items — may indicate incomplete hardening.${NC}"
else
    echo -e "  ${GREEN}All automated checks passed. Review checklist manually too.${NC}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  This script covers automated checks only."
echo "  Complete the full checklist manually at:"
echo "  github.com/RonMercier/cloud-security-checklist"
echo ""
