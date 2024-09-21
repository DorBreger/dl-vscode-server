# Offline dev containers
## Background
When selecting a container image to use as a dev container, vscode will attempt to download the necassery executables to a container instance of that image. This will obviously fail in an environment without an internet connection like an airplane.

## Motivation
This tool allows the necassery executables to be pre-installed on the **image**.

## Use cases

The tool allows flexible usage. It is possible to bring the tarball that vscode will typically download yourself, To always use the latest version, or a specific vscode version.
Therefore it is possible to build devcontainer images as part of a CI pipeline, on an internet enabled computer to later be transferred to an isolated network with a specific version of vscode, or even before a flight to allow work to be done when internet is unavailable.

## A note on versions
A version comptability between the executables downloaded onto the container and vscode is necassery. That means that this script won't work with an image built using `--version 1.92.1` when vscode 1.92.2 is used, because it will attempt to install the executables matching version 1.92.2. You **must** ensure version comptability. When ran without `--verion` or `--commit`, the script will use the latest version available, and thus the latest version of vscode available during the image build will need to be used. 


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
