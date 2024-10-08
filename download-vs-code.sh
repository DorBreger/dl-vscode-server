#!/bin/sh

# Copyright 2024 Dor Breger
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

set -e
usage="
This script downloads a tar of VS Code Server/CLI, then extracts it to a
location expected by tunnels made by VS Code clients.

download-vs-code.sh [options] <PLATFORM> [<ARCH>]

Example:
  download-vs-code.sh \"linux\" \"x64\" --alpine

Options

--insider
    Switches to the pre-released version of the binary chosen (server or
    CLI).

--dump-sha
    Will print the latest commit sha for VS Code (server and CLI are current
    synced and always the same).

--cli
    Switches the binary download VS Code CLI.

--version
    The version of vscode server to match againt. Incompatible with --commit.

--tar
    Allows to specify the tarball path to use for the installation. This allows building dev containers as part of a CI process in an isolated or air-gapped environment.

--commit
    The commit to use for the download, instead of fetching the latest. Incompatible with --version

--alpine
    Only works when downloading VS Code Server, it will force PLATFORM=linux and
    ARCH=alpine, as the developers deviated from the standard format used for
    all others.
--extensions
    specify which extensions to install. expects a string of full extension names seperated by commas,
    e.g ms-vscode.PowerShell,redhat.ansible,ms-python.vscode-pylance

-h, --help
    Print this usage info.
"
# Get the latest VS Code commit sha.
get_latest_release() {
    platform=${1}
    arch=${2}
    bin_type="${3}"

    # Grab the first commit SHA since as this script assumes it will be the
    # latest.
    commit_id=$(curl --silent "https://update.code.visualstudio.com/api/commits/${bin_type}/${platform}-${arch}" | sed s'/^\["\([^"]*\).*$/\1/')

    # These work:
    # https://update.code.visualstudio.com/api/commits/stable/win32-x64
    # https://update.code.visualstudio.com/api/commits/stable/linux-x64
    # https://update.code.visualstudio.com/api/commits/insider/linux-x64

    # these do not work:
    # https://update.code.visualstudio.com/api/commits/stable/darwin-x64
    # https://update.code.visualstudio.com/api/commits/stable/linux-alpine
    printf "%s" "${commit_id}"
}

# You can test the code binary is installed in the correct location by
# making a tunnel to vscode.dev with:
# ~/.vscode-server/code tunnel --accept-server-license-terms
install_cli() {
    echo "setup directories:"
    # Make the directories where the VS Code will search. There may be others not
    # listed here.
    # NOTE: VS Code will runas the logged in user, so ensure they have
    #       read/write to the following directories
    mkdir -vp ~/.vscode-server
    echo "done"

    # Extract the tarball to the right location.
    printf "%s" "extracting ${archive}..."
    tar -xz -C ~/.vscode-server --no-same-owner -f "/tmp/${archive}"
    echo "done"

    # Add symlinks
    printf "%s" "setup symlinks..."
    ln -s ~/.vscode-server/code ~/.vscode-server/code-"${commit_sha}"
    ln -s "${HOME}"/.vscode-server/code ~/code
    echo "done"
}

install_server() {
    echo "setup directories:"
    # Make the directories where the VS Code will search. There may be others not
    # listed here.
    # NOTE: VS Code will runas the logged in user, so ensure they have
    #       read/write to the following directories
    mkdir -vp ~/.vscode-server/bin/"${commit_sha}"
    # VSCode Requirements for pre-installing extensions
    mkdir -vp ~/.vscode-server/extensions
    # found this in the VSCode remote extension output when connecting to an existing container
    mkdir -vp ~/.vscode-server/extensionsCache
    # This should handle installs for https://vscode.dev/
    mkdir -vp ~/.vscode/cli/servers/Stable-"${commit_sha}"
    mkdir -vp ~/.vscode-server/cli/servers/Stable-"${commit_sha}"
    echo "done"

    # Extract the tarball to the right location.
    printf "%s" "extracting ${archive}..."
    tar -xz -C ~/.vscode-server/bin/"${commit_sha}" --strip-components=1 --no-same-owner -f "/tmp/${archive}"
    echo "done"

    # Add symlinks
    printf "%s" "setup symlinks..."
    ln -s ~/.vscode-server/bin/"${commit_sha}" ~/.vscode-server/bin/default_version
    ln -s ~/.vscode-server/bin/"${commit_sha}" ~/.vscode/cli/servers/Stable-"${commit_sha}"/server
    ln -s ~/.vscode-server/bin/"${commit_sha}" ~/.vscode-server/cli/servers/Stable-"${commit_sha}"/server
    ln -s ~/.vscode-server/bin/"${commit_sha}"/bin/code-server ~/code-server
    echo "done"
}

PLATFORM=""
ARCH=""
BUILD="stable"
BIN_TYPE="server"
DUMP_COMMIT_SHA=""
IS_ALPINE=0

while [ ${#} -gt 0 ]; do
    op="${1}"
    shift
    case ${op} in
        --insider)
            BUILD="insider"
            ;;
        --dump-sha)
            DUMP_COMMIT_SHA="yes"
            ;;
        --cli)
            BIN_TYPE="cli"
            ;;
        --alpine)
            IS_ALPINE=1
            ;;
        -h|--help)
            echo "${usage}"
            exit 0
            ;;
        --version)
            if [ -n "$1" ] && [ "$1" = "${1#-}" ]; then
                BUILD="stable"
                VERSION="$1"
                shift
            else
                echo "Error: --version requires a parameter"
                exit 1
            fi
            ;;
        --commit)
            if [ -n "$1" ] && [ "$1" = "${1#-}" ]; then
                BUILD="stable"
                commit_sha="$1"
                shift
            else
                echo "Error: --commit requires a parameter"
                exit 1
            fi
            ;;
        --tar)
            if [ -n "$1" ] && [ "$1" = "${1#-}" ]; then
                tarball="$1"
                shift
            else
                echo "Error: --tar requires a parameter"
                exit 2
            fi
            ;;
        --extensions)
            if [ -n "$1" ] && [ "$1" = "${1#-}" ]; then
                EXTENSIONS="$1"
                shift
            else
                echo "Error: --extensions requires a parameter"
                exit 1
            fi
            ;;
        -*|--*)
            echo "Unknown option ${op}"
            exit 1
            ;;
        *)
            if [ -n "${op}" ]; then
                case ${op} in
                    # We can't put Alpine here because the server download required PLATFORM=linux and ARCH=alpine.
                    alpine|darwin|linux|win32)
                      PLATFORM="${op}"
                      ;;
                    arm64|armhf|x64)
                      ARCH="${op}"
                      ;;
                    *)
                      echo "Unknown option ${op}"
                      exit 1
                      ;;
                esac
            fi
            ;;
    esac
done

# Platform is required.
if [ -z "${PLATFORM}" ]; then
    echo "please specify which platform version of VS Code to install\nacceptable values are win32, linux, darwin, or alpine"
    exit 1
fi

# When non specified, then pull from the OS.
if [ -z "${ARCH}" ]; then
    U_NAME=$(uname -m)

    if [ "${U_NAME}" = "aarch64" ]; then
        ARCH="arm64"
    elif [ "${U_NAME}" = "x86_64" ]; then
        ARCH="x64"
    elif [ "${U_NAME}" = "armv7l" ]; then
        ARCH="armhf"
    fi
fi

# Patch things when downloading VS Code Server for Alpine.
if [ "${BIN_TYPE}" = "server" -a ${IS_ALPINE} -eq 1 ]; then
    echo "we need to hard set PLATFORM and ARCH for Alpine Musl"
    PLATFORM="linux"
    ARCH="alpine" # Alpine is NOT an Arch but a flavor of Linux, oh well.
fi

if [ -n "${commit_sha}" ] && [ -n "${VERSION}" ]; then
    echo "Error: --version and --commit are incompatible"
    exit 2
elif [ -n "${VERSION}" ]; then
    commit_sha=$(curl -I --silent "https://update.code.visualstudio.com/${VERSION}/${BIN_TYPE}-${PLATFORM}-${ARCH}/stable" | grep -oP "/stable/\K[^/]+")
elif [ -z "${commit_sha}" ]; then
    # We hard-code this because all but a few options returns a 404.
    commit_sha=$(get_latest_release "win32" "x64" "${BUILD}")
fi

if [ -z "${commit_sha}" ]; then
    echo "could not get the VS Code latest commit sha, exiting"
    exit 1
fi

if [ "${DUMP_COMMIT_SHA}" = "yes" ]; then
    echo "${commit_sha}"
    exit 0
fi


options="${BIN_TYPE}-${PLATFORM}-${ARCH}"
archive="vscode-${options}.tar.gz"

# Download VS Code tarball to the current directory.
if [ -z "${tarball}" ]; then
    echo "attempting to download and pre-install VS Code ${BIN_TYPE} version '${commit_sha}'"
    url="https://update.code.visualstudio.com/commit:${commit_sha}/${options}/${BUILD}"
    printf "%s" "downloading ${url} to ${archive} "
    curl -s --fail -L "${url}" -o "/tmp/${archive}"
    echo "done"
else 
    echo "using provided tarball for installation"
    cp "${tarball}" "/tmp/${archive}"
    echo "calculating commit sha from provided tarball"
    commit_sha=$(tar -O -xzf "/tmp/${archive}" "vscode-${options}/product.json" | grep commit | grep -o '[a-f0-9]\{40\}')
fi

# Based on the binary type chosen, perform the installation.
if [ "${BIN_TYPE}" = "cli" ]; then
    install_cli
else
    install_server
fi

echo "VS Code server pre-install completed"
echo "downloading extensions..."

if [ -z "$EXTENSIONS" ]; then
    echo "no extensions to install"
    exit 0
fi

echo "$EXTENSIONS" | tr ',' '\n' | while IFS= read -r ext; do
    ~/code-server --install-extension "$ext"
done
echo "extensions installation complete"
