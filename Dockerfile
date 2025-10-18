FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# -------------------------------------------------------------
# Build dependencies
# -------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    g++ clang cmake ninja-build libx11-dev libxcursor-dev libxi-dev libxrandr-dev \
    libgl1-mesa-dev libfontconfig1-dev wget ca-certificates git curl unzip file \
    && rm -rf /var/lib/apt/lists/* && update-ca-certificates

# -------------------------------------------------------------
# Optional build arg: VERSION
# If not provided, automatically builds latest stable release
# -------------------------------------------------------------
ARG VERSION=latest
WORKDIR /src

RUN git clone --recursive https://github.com/aseprite/aseprite.git
WORKDIR /src/aseprite

RUN if [ "$VERSION" = "latest" ]; then \
      LATEST=$(curl -s https://api.github.com/repos/aseprite/aseprite/releases/latest | grep -Po '"tag_name": "\K.*?(?=")'); \
      git checkout "$LATEST"; \
    else \
      git checkout "$VERSION"; \
    fi

# Build Aseprite
RUN ./build.sh --auto --norun

RUN mkdir -p AppDir/usr/bin AppDir/usr/lib \
    && cp -r build/bin/* AppDir/usr/bin/ \
    && cp -r build/lib/* AppDir/usr/lib/ \
    && chmod +x AppDir/usr/bin/aseprite

# -------------------------------------------------------------
# AppImage tooling
# -------------------------------------------------------------
RUN wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage \
 && wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
 && chmod +x appimagetool-x86_64.AppImage linuxdeploy-x86_64.AppImage

# -------------------------------------------------------------
# Icons and desktop entries
# -------------------------------------------------------------
RUN mkdir -p AppDir/usr/share/icons/hicolor AppDir/usr/share/mime/packages

# Main app icon
RUN cp ./data/icons/ase128.png AppDir/aseprite.png

# Document icons
# This is missing the proper icon for palette files,
# but I can't find them anywhere in the repo.
RUN for s in 16 32 48 64 128 256; do \
      mkdir -p AppDir/usr/share/icons/hicolor/${s}x${s}/mimetypes; \
      cp ./data/icons/doc${s}.png AppDir/usr/share/icons/hicolor/${s}x${s}/mimetypes/application-x-aseprite.png; \
      cp ./data/icons/doc${s}.png AppDir/usr/share/icons/hicolor/${s}x${s}/mimetypes/application-x-ase.png; \
      cp ./data/icons/doc${s}.png AppDir/usr/share/icons/hicolor/${s}x${s}/mimetypes/application-x-aseprite-palette.png; \
      cp ./data/icons/ext${s}.png AppDir/usr/share/icons/hicolor/${s}x${s}/mimetypes/application-x-aseprite-extension.png; \
    done && \
    mkdir -p AppDir/usr/share/icons/hicolor/scalable/mimetypes && \
    cp ./data/icons/doc.ico AppDir/usr/share/icons/hicolor/scalable/mimetypes/application-x-aseprite.ico && \
    cp ./data/icons/ext.ico AppDir/usr/share/icons/hicolor/scalable/mimetypes/application-x-aseprite-extension.ico

# Desktop entry
RUN cat > AppDir/aseprite.desktop <<'EOF'
[Desktop Entry]
Name=Aseprite
GenericName=Pixel Art Editor
Comment=Animated sprite editor & pixel art tool
Exec=aseprite %f
Icon=aseprite
Type=Application
Categories=Graphics;2DGraphics;RasterGraphics;
MimeType=application/x-aseprite;application/x-ase;application/x-aseprite-palette;application/x-aseprite-extension;
EOF

# MIME types
RUN cat > AppDir/usr/share/mime/packages/aseprite-mime.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-aseprite">
    <comment>Aseprite Project</comment>
    <icon name="application-x-aseprite"/>
    <glob pattern="*.aseprite"/>
  </mime-type>
  <mime-type type="application/x-ase">
    <comment>Aseprite Animation</comment>
    <icon name="application-x-ase"/>
    <glob pattern="*.ase"/>
  </mime-type>
  <mime-type type="application/x-aseprite-palette">
    <comment>Aseprite Palette</comment>
    <icon name="application-x-aseprite-palette"/>
    <glob pattern="*.pal"/>
  </mime-type>
  <mime-type type="application/x-aseprite-extension">
    <comment>Aseprite Extension</comment>
    <icon name="application-x-aseprite-extension"/>
    <glob pattern="*.aseprite-extension"/>
  </mime-type>
</mime-info>
EOF

# -------------------------------------------------------------
# Bundle dependencies and create AppImage
# -------------------------------------------------------------
RUN export LD_LIBRARY_PATH=/src/aseprite/AppDir/usr/bin:$LD_LIBRARY_PATH && \
    ./linuxdeploy-x86_64.AppImage --appimage-extract-and-run --appdir AppDir \
      -e AppDir/usr/bin/aseprite \
      -d AppDir/aseprite.desktop \
      -i AppDir/aseprite.png

RUN ./appimagetool-x86_64.AppImage --appimage-extract-and-run /src/aseprite/AppDir Aseprite.AppImage
