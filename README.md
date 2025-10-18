# Aseprite AppImage Builder

This repository provides a Docker-based build system for compiling [Aseprite](https://github.com/aseprite/aseprite) from source and packaging it as a self-contained AppImage.

Everything builds inside of Docker, and cleans up after itself (Except for the actual Docker Engine).

# Usage

## Requirements
- [Docker](https://docs.docker.com/engine/install/#installation-procedures-for-supported-platforms) (or [Podman](https://podman.io/docs/installation#installing-on-linux), with `--format=docker`)
- Bash-compatible shell

> [!IMPORTANT]
> It may be possible to build this on Windows using WSL, but running it is untested.

## Steps

1. **Clone this repository:**
   ```bash
   git clone https://github.com/realSZ27/aseprite-appimage-builder.git
   cd aseprite-appimage-builder
   ```
2. Run 
   ```bash 
   ./build.sh
   ```

> [!TIP]
> The build script is just a helper, you can also run the commands manually by looking inside the script.

## Flags
> [!NOTE]
> Run `./build.sh --help` to see equivalent information.

- **`--version`**  
The version of Aseprite to build. If this is not specified, it will build the latest stable version.  
   > [!IMPORTANT]
   > You **MUST** prepend `v` to the version. Example: `v1.3.15`

- **`--keep-image`**  
Don't delete the Docker image containing the built AppImage after the build finishes.
   > [!NOTE]
   > Not sure how useful this flag actually is, as Docker still keeps cached layers. The build script only removes the image itself (`docker rmi`), not the cache.

## Legal Disclaimer

> [!IMPORTANT]
> This repository contains MIT-licensed build scripts and a Dockerfile **only**. Aseprite itself is proprietary and is governed by its End-User License Agreement (EULA). By using these scripts to download or build Aseprite, you agree to comply with the [Aseprite EULA](https://github.com/aseprite/aseprite/blob/main/EULA.txt). You may build Aseprite for your personal use, but **you must not redistribute compiled Aseprite binaries (including AppImages) or other proprietary parts** unless you have explicit permission from the Aseprite licensor.
