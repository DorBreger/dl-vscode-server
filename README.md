# DL VS Code Server

This script downloads a tar of VS Code Server/CLI, then extracts it to a
location expected by tunnels made by VS Code clients.

The intention of this script is to pre-install the VS Code binary during
container image build. This helps ensure, in certain scenarios, that the binary
is there when internet is not; while still allowing your VS Code client to
tunnel to the container. Vscode will attempt to look for a server installtion of the
same version (marked by a commit hash) as it. If there is a mismatch between the vscode server
installed in the container and vscode, vscode will attempt to install it again, which will fail 
without internet. Therefore it is possible to specify a client `--version`, or provide the server tarball
yourself (you can get it through something like `curl -L https://update.code.visualstudio.com/1.92.1/server-linux-x64/stable`) 
with --tar

## Background

The original reason was and still is to prevent the constant download and
install of VS Code server when the container is removed then run again later.
With the server being embedded in the image, it should also reduce time for the
dev container to be ready.

It originally started as a Gist; which you can review previous versions of the
script at [b01/download-vs-code-server.sh]

## How To Install

### Shell
```shell
curl -L https://raw.githubusercontent.com/DorBreger/dl-vscode-server/main/download-vs-code.sh| bash -s -- "linux"
```

### Docker

```dockerfile
ADD --chmod=777 \
    https://raw.githubusercontent.com/DorBreger/dl-vscode-server/main/download-vs-code.sh \
    .

# Install VS Code Server and Requirements For VS code 1.92.1
RUN ./download-vs-code.sh "linux" "x64" --alpine --extensions dbaeumer.vscode-eslint --version 1.92.1
```

## How To Use

`download-vs-code.sh [options] <PLATFORM> [<ARCH>]`

### Example:

download-vs-code.sh \"linux\" \"x64\" --alpine

### Options

`--insider`
Switches to the pre-released version of the binary chosen (server or
CLI).

`--dump-sha`
Will print the latest commit sha for VS Code (server and CLI are current
synced and always the same)

`--tar`
    Allows to specify the tarball path to use for the installation. This allows building dev containers as part of a CI process in an isolated or air-gapped environment.

`--cli`
Switches the binary download VS Code CLI.

`--version`
    The version of vscode server to match againt. Incompatible with --commit.

`--commit`
    The commit hash to use for the download, instead of fetching the latest. Incompatible with --version


`--alpine`
Only works when downloading VS Code Server, it will force PLATFORM=linux and
ARCH=alpine, as the developers deviated from the standard format used for all
others.

`-h, --help`
Print this usage info

`--extensions`
    specify which extensions to install. expects a string of full extension names seperated by commas,
    e.g ms-vscode.PowerShell,redhat.ansible,ms-python.vscode-pylance


---

[b01/download-vs-code-server.sh]: https://gist.github.com/b01/0a16b6645ab7921b0910603dfb85e4fb
