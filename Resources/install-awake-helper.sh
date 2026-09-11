#!/bin/bash
# Installs a root helper that may only run: pmset -a disablesleep 0|1
# Usage: install-awake-helper.sh <console-user> [0|1]
set -euo pipefail

USER_NAME="${1:?}"
FLAG="${2:-}"
HELPER="/Library/PrivilegedHelperTools/com.mariocodarin.Awake.pmset"
SUDOERS="/etc/sudoers.d/awake-pmset"

case "$USER_NAME" in
  *[!A-Za-z0-9._-]*|"") echo "invalid user" >&2; exit 2 ;;
esac
if [[ -n "$FLAG" && "$FLAG" != "0" && "$FLAG" != "1" ]]; then
  echo "flag must be 0 or 1" >&2
  exit 2
fi

mkdir -p /Library/PrivilegedHelperTools
cat > "$HELPER" << 'EOS'
#!/bin/sh
set -e
case "$1" in
  0|1) exec /usr/bin/pmset -a disablesleep "$1" ;;
  *) echo "Awake helper: pass 0 or 1" >&2; exit 2 ;;
esac
EOS
chown root:wheel "$HELPER"
chmod 755 "$HELPER"

printf '%s ALL=(root) NOPASSWD: %s 0, %s 1\n' "$USER_NAME" "$HELPER" "$HELPER" > "$SUDOERS"
chown root:wheel "$SUDOERS"
chmod 440 "$SUDOERS"
/usr/sbin/visudo -cf "$SUDOERS" >/dev/null

if [[ "$FLAG" == "0" || "$FLAG" == "1" ]]; then
  /usr/bin/pmset -a disablesleep "$FLAG"
fi
