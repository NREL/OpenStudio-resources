import os
from pathlib import Path

print(f"os.getcwd()={os.getcwd()}")
print(f"Path.cwd()={Path.cwd()}")

from lib.baseline_model import BaselineModel
