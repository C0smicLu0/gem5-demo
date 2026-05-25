#!/usr/bin/env bash
#
# Print official Docker download/install guidance for this workspace.

set -euo pipefail

readonly WINDOWS_INSTALL_DOC='https://docs.docker.com/desktop/setup/install/windows-install/'
readonly UBUNTU_ENGINE_DOC='https://docs.docker.com/engine/install/ubuntu/'
readonly UBUNTU_DESKTOP_DOC='https://docs.docker.com/desktop/setup/install/linux/ubuntu/'

TARGET="auto"

usage()
{
    cat <<EOF
Usage:
  $(basename "$0") [windows|ubuntu-engine|ubuntu-desktop]

Targets:
  windows         Docker Desktop on Windows with WSL 2 backend.
  ubuntu-engine   Docker Engine on Ubuntu.
  ubuntu-desktop  Docker Desktop on Ubuntu.

Notes:
  - With this gem5 workspace under WSL, Docker Desktop on Windows is usually
    the simplest choice.
  - This script prints the official install pages and a couple of suggested
    next commands. It does not modify the system automatically.
EOF
}

print_windows()
{
    cat <<EOF
Docker Desktop for Windows
Official install page:
  $WINDOWS_INSTALL_DOC

Suggested next steps:
  1. Install Docker Desktop with the WSL 2 backend.
  2. Start Docker Desktop once from Windows.
  3. In WSL, verify:
     docker version
     docker ps
EOF
}

print_ubuntu_engine()
{
    cat <<EOF
Docker Engine on Ubuntu
Official install page:
  $UBUNTU_ENGINE_DOC

Suggested next steps:
  1. Follow the apt repository install flow from the official page.
  2. After install, verify:
     sudo systemctl status docker
     docker version
     docker ps
EOF
}

print_ubuntu_desktop()
{
    cat <<EOF
Docker Desktop on Ubuntu
Official install page:
  $UBUNTU_DESKTOP_DOC

Suggested next steps:
  1. Download the latest .deb package from the official page.
  2. Install it with apt as documented there.
  3. After install, verify:
     docker version
     docker ps
EOF
}

detect_default_target()
{
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "windows"
    else
        echo "ubuntu-engine"
    fi
}

while (($#)); do
    case "$1" in
        windows|ubuntu-engine|ubuntu-desktop)
            TARGET="$1"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'error: unknown target: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [[ "$TARGET" == "auto" ]]; then
    TARGET="$(detect_default_target)"
fi

case "$TARGET" in
    windows)
        print_windows
        ;;
    ubuntu-engine)
        print_ubuntu_engine
        ;;
    ubuntu-desktop)
        print_ubuntu_desktop
        ;;
esac
