"""Centralized, OS-correct paths for bundled resources and user data."""
import os
import sys
from platformdirs import user_config_dir, user_log_dir

APP_NAME = "DualCPY-Linux"
APP_AUTHOR = "the_swest"

def _bundled_path() -> str:
    """Read-only resources bundled inside the frozen app (e.g. bin/)."""
    if hasattr(sys, "_MEIPASS"):
        return sys._MEIPASS
    return os.path.dirname(os.path.abspath(__file__ + "/.."))

BUNDLED_PATH = _bundled_path()
BIN_DIR = os.path.join(BUNDLED_PATH, "bin")

CONFIG_DIR = user_config_dir(APP_NAME, APP_AUTHOR)
LOG_DIR = user_log_dir(APP_NAME, APP_AUTHOR)

def ensure_user_dirs():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    os.makedirs(LOG_DIR, exist_ok=True)
    bundled_config = os.path.join(BUNDLED_PATH, "config")
    if os.path.isdir(bundled_config) and not os.listdir(CONFIG_DIR):
        import shutil
        shutil.copytree(bundled_config, CONFIG_DIR, dirs_exist_ok=True)
