import Foundation
import AwakeCore

/// Installs the root helper and its sudoers rule behind one administrator password prompt.
///
/// The script is embedded and passed to `osascript` as an argument, so nothing user-writable
/// (the app bundle, a temp file) is ever executed as root, and no path is spliced into AppleScript source.
enum HelperInstaller {
    /// Installs `/Library/PrivilegedHelperTools/...pmset`, which can only run
    /// `pmset -a disablesleep 0|1`, plus `/etc/sudoers.d/awake-pmset`. Arguments: `<user> [0|1]`.
    static let script = #"""
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
    """#

    private static let appleScript = [
        "on run argv",
        "set uname to item 2 of argv",
        "set flag to item 3 of argv",
        "do shell script \"/bin/bash -c \" & quoted form of (item 1 of argv) & \" awake-installer \" & quoted form of uname & \" \" & quoted form of flag with administrator privileges",
        "end run"
    ]

    /// Runs the installer as admin and applies `flag` in the same step.
    static func install(flag: String, user: String = NSUserName()) async throws {
        var arguments = appleScript.flatMap { ["-e", $0] }
        arguments += [script, user, flag]
        let result = try await ProcessRunner.run("/usr/bin/osascript", arguments)
        guard result.status == 0 else {
            throw result.output.contains("-128") ? SystemSleepLockError.installCancelled : .commandFailed
        }
    }
}
