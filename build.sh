#!/bin/bash
set -euo pipefail

# ============================================================
# Aseprite AppImage Helper Script
# This script isn't strictly nessessary, but it makes everything more convenient.
# ============================================================

IMAGE_NAME="aseprite-appimage"
CONTAINER_NAME="tmp_aseprite_build"
HOST_DEST="./Aseprite.AppImage"
VERSION="latest"
CLEANUP=true

# ------------------------------------------------------------
# Color setup
# ------------------------------------------------------------
BOLD="\033[1m"
RESET="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
GRAY="\033[0;37m"

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------
info()    { echo -e "${CYAN}${1}${RESET}"; }
warn()    { echo -e "${YELLOW}${1}${RESET}"; }
error()   { echo -e "${RED}${1}${RESET}" >&2; }
success() { echo -e "${GREEN}${1}${RESET}"; }

# ------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version)
            VERSION="$2"
            shift 2
        ;;
        -h|--help)
            echo -e "${BOLD}Usage:${RESET} $0 [--version <tag>] [--keep-image]"
            echo ""
            echo "Builds an Aseprite AppImage inside Docker."
            echo "If no version is provided, the latest stable release is built."
            echo ""
            echo -e "${BOLD}Examples:${RESET}"
            echo "  $0                     # build latest stable"
            echo "  $0 --version v1.3.13   # build specific version"
            echo "  $0 --keep-image        # don't delete built image"
            exit 0
        ;;
        --keep-image)
            CLEANUP=false
            shift
        ;;
        *)
            error "Unknown option: $1"
            echo ""
            echo "Run '$0 --help' for more information."
            exit 1
        ;;
    esac
done

# ------------------------------------------------------------
# Cleanup function
# ------------------------------------------------------------
cleanup() {
    echo ""
    info "Cleaning up temporary resources..."
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        docker rmi -f "$IMAGE_NAME" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# ------------------------------------------------------------
# Build Docker image
# ------------------------------------------------------------
echo ""
info "Building Docker image for Aseprite..."
echo -e "   ${GRAY}Image:${RESET}   $IMAGE_NAME"
echo -e "   ${GRAY}Version:${RESET} $VERSION"
echo "---------------------------------------------"

# If you're not using the script, you can omit the VERSION variable to build the latest stable.
docker build \
    --build-arg VERSION="$VERSION" \
    -t "$IMAGE_NAME" \
    .

success "Docker image built successfully."

# ------------------------------------------------------------
#  Create temporary container
# ------------------------------------------------------------
echo ""
info "Creating temporary container..."
CONTAINER_ID=$(docker create --name "$CONTAINER_NAME" "$IMAGE_NAME")

# ------------------------------------------------------------
#  Extract AppImage
# ------------------------------------------------------------
echo ""
info "Extracting AppImage from container..."
docker cp "${CONTAINER_ID}:/src/aseprite/Aseprite.AppImage" "$HOST_DEST" >/dev/null
success "AppImage extracted to: $HOST_DEST"

# ------------------------------------------------------------
#  Cleanup container and image
# ------------------------------------------------------------
echo ""
info "Cleaning up..."
docker rm "$CONTAINER_ID" >/dev/null
if [ "$CLEANUP" = true ]; then
    docker rmi -f "$IMAGE_NAME" >/dev/null || true
else
    warn "Keeping image (--keep-image specified)."
fi

# ------------------------------------------------------------
#  Done!
# ------------------------------------------------------------
echo ""
success "Build complete!"
echo -e "${GRAY}Aseprite AppImage saved to:${RESET} ${BOLD}$HOST_DEST${RESET}"
echo -e "${GRAY}Version built:${RESET} ${BOLD}$VERSION${RESET}"
echo "---------------------------------------------"
info "You can now run it with:"
echo -e "   ${BOLD}./Aseprite.AppImage${RESET}"
echo ""
