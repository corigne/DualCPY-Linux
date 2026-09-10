APP_NAME   := DualCPY
BIN_NAME   := DualCPY
PYTHON     ?= python3

PREFIX     ?= /usr
DESTDIR    ?=

BINDIR     := $(DESTDIR)$(PREFIX)/bin
DESKTOPDIR := $(DESTDIR)$(PREFIX)/share/applications
ICONDIR    := $(DESTDIR)$(PREFIX)/share/icons/hicolor/256x256/apps
LICENSEDIR := $(DESTDIR)$(PREFIX)/share/licenses/dualcpy

DIST_BIN     := dist/$(BIN_NAME)
ICON_SRC     := assets/icon.png
LICENSE_SRC  := LICENSE
DESKTOP_FILE := $(DESKTOPDIR)/dualcpy.desktop

SRC_FILES := main.py build.py $(shell find src -name '*.py' 2>/dev/null)

.PHONY: all build install uninstall clean

all: build

# Real file target: only rebuilds when source files are newer than the
# existing binary. This means "sudo make install" won't try to invoke
# PyInstaller (and fail due to root's PATH not having your venv) as long
# as you've already built once as your normal user.
$(DIST_BIN): $(SRC_FILES)
	@if [ ! -f build.py ]; then \
		echo "Error: build.py not found. Run this from the project root."; exit 1; \
	fi
	$(PYTHON) build.py
	@if [ ! -f "$(DIST_BIN)" ]; then \
		echo "Error: build did not produce $(DIST_BIN)."; exit 1; \
	fi

build: $(DIST_BIN)

install: build
	install -d "$(BINDIR)" "$(DESKTOPDIR)" "$(ICONDIR)"
	install -Dm755 "$(DIST_BIN)" "$(BINDIR)/$(BIN_NAME)"
	@if [ -f "$(ICON_SRC)" ]; then \
		install -Dm644 "$(ICON_SRC)" "$(ICONDIR)/dualcpy.png"; \
	fi
	@if [ -f "$(LICENSE_SRC)" ]; then \
		install -Dm644 "$(LICENSE_SRC)" "$(LICENSEDIR)/LICENSE"; \
	fi
	@printf '%s\n' \
		'[Desktop Entry]' \
		'Type=Application' \
		'Name=DualCPY' \
		'Comment=Dual-screen scrcpy docking and control UI' \
		'Exec=$(BIN_NAME)' \
		'Icon=dualcpy' \
		'Terminal=false' \
		'Categories=Utility;' \
		> "$(DESKTOP_FILE)"
	@chmod 644 "$(DESKTOP_FILE)"

uninstall:
	rm -f "$(BINDIR)/$(BIN_NAME)"
	rm -f "$(ICONDIR)/dualcpy.png"
	rm -f "$(DESKTOP_FILE)"

clean:
	rm -rf build dist *.spec
