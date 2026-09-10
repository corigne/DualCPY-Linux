# Makefile for DualCPY-Linux
#
# PREFIX defaults to /usr (Arch packaging standard). DESTDIR is honored
# for staged installs (e.g. by a PKGBUILD's package()).
#
# Usage:
#   make install          # builds unprivileged, prompts for sudo only to copy files
#   sudo make install     # also works on a fresh checkout -- build step
#                          # automatically drops to $SUDO_USER, never runs
#                          # pip/venv/PyInstaller as root
#   make build            # build only, no install
#   sudo make uninstall / make uninstall
#   make clean

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

VENV_DIR     := venv
VENV_PYTHON  := $(VENV_DIR)/bin/python
REQ_FILE     := requirements.txt

SRC_FILES := main.py build.py $(shell find src -name '*.py' 2>/dev/null)

.PHONY: all build venv install uninstall clean _install_files

all: build

# Create (or reuse) a build venv with all Python deps needed to run
# PyInstaller. Always runs as an unprivileged user -- if invoked while
# root (e.g. as a dependency chain from `sudo make install`), it drops
# to $SUDO_USER first rather than ever installing packages as root.
venv:
	@if [ "$$(id -u)" = "0" ]; then \
		if [ -z "$$SUDO_USER" ]; then \
			echo "Error: running as root with no SUDO_USER set."; \
			echo "Run 'make venv' as your normal user first, or invoke"; \
			echo "this via sudo from a normal login shell."; \
			exit 1; \
		fi; \
		sudo -u "$$SUDO_USER" -H $(MAKE) venv PYTHON=$(PYTHON); \
	else \
		if [ ! -x "$(VENV_PYTHON)" ]; then \
			echo "==> Creating build venv..."; \
			$(PYTHON) -m venv "$(VENV_DIR)"; \
		fi; \
		echo "==> Installing Python dependencies..."; \
		"$(VENV_PYTHON)" -m pip install --upgrade pip; \
		"$(VENV_PYTHON)" -m pip install -r "$(REQ_FILE)" pyinstaller; \
	fi

# Build the onefile binary. Only rebuilds when source files are newer
# than the existing binary. Like `venv`, this drops root privileges
# before touching pip/PyInstaller if invoked while running as root.
$(DIST_BIN): $(SRC_FILES)
	@if [ "$$(id -u)" = "0" ]; then \
		if [ -z "$$SUDO_USER" ]; then \
			echo "Error: running as root with no SUDO_USER set."; \
			echo "Run 'make build' as your normal user first, or invoke"; \
			echo "this via sudo from a normal login shell."; \
			exit 1; \
		fi; \
		sudo -u "$$SUDO_USER" -H $(MAKE) build; \
	else \
		$(MAKE) venv; \
		if [ ! -f build.py ]; then \
			echo "Error: build.py not found. Run this from the project root."; \
			exit 1; \
		fi; \
		"$(VENV_PYTHON)" build.py; \
		if [ ! -f "$(DIST_BIN)" ]; then \
			echo "Error: build did not produce $(DIST_BIN)."; \
			exit 1; \
		fi; \
	fi

build: $(DIST_BIN)

# Public entry point. Works correctly whether invoked as:
#   make install        -- builds unprivileged, then escalates via sudo
#                           only for the final file copy into PREFIX
#   sudo make install   -- build step internally drops to $SUDO_USER;
#                           install then proceeds already-elevated
install: build
	@if [ "$$(id -u)" = "0" ]; then \
		$(MAKE) _install_files PREFIX=$(PREFIX) DESTDIR=$(DESTDIR); \
	else \
		echo "==> Installing to $(PREFIX) (requires elevated privileges)..."; \
		sudo $(MAKE) _install_files PREFIX=$(PREFIX) DESTDIR=$(DESTDIR); \
	fi

# Actual file-copy step. Assumed to already be running as root by the
# time it's invoked (see `install` above) -- never call this directly.
_install_files:
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
	@echo "==> Installed."

uninstall:
	@if [ "$$(id -u)" = "0" ]; then \
		rm -f "$(BINDIR)/$(BIN_NAME)"; \
		rm -f "$(ICONDIR)/dualcpy.png"; \
		rm -f "$(DESKTOP_FILE)"; \
		echo "==> Uninstalled."; \
	else \
		sudo $(MAKE) uninstall; \
	fi

# Never leaves root-owned artifacts in the project directory: if run
# while root (e.g. `sudo make clean`), drops to $SUDO_USER first.
clean:
	@if [ "$$(id -u)" = "0" ] && [ -n "$$SUDO_USER" ]; then \
		sudo -u "$$SUDO_USER" $(MAKE) clean; \
	else \
		rm -rf $(VENV_DIR) build dist *.spec; \
	fi
