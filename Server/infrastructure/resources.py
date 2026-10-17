import os
import sys


def get_resource_path(relative_path):
    """
    Get the absolute path to a resource.
    Works for development and for PyInstaller bundle.
    """
    if getattr(sys, "frozen", False):
        base_path = sys._MEIPASS
    else:
        base_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base_path, relative_path)
