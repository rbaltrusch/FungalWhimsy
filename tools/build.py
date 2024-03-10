"""Builds the game"""

import os
import zipfile
import pathlib
import shutil
from datetime import datetime

LOVE_DIR = pathlib.Path(os.environ.get("LOVE_DIR", "C:\\program files\\love"))
GAME = "FungalWhimsy"


def add_single_file(path: pathlib.Path, zip_file: zipfile.ZipFile):
    """Adds a single file to the specified zip file"""
    zip_file.write(
        path,
        os.path.relpath(path),
    )


def add_directory(path: pathlib.Path, zip_file: zipfile.ZipFile):
    """Recurses through whole directory and adds it to the specified zip file"""
    for root, _, files in os.walk(path):
        for file in files:
            add_single_file(os.path.join(root, file), zip_file)


def main():
    """Main function"""
    with zipfile.ZipFile(f"{GAME}.love", "w", zipfile.ZIP_DEFLATED) as file:
        add_directory("assets", file)
        add_directory("src", file)
        add_single_file("main.lua", file)
        add_single_file("conf.lua", file)
    build_dir = pathlib.Path(datetime.now().strftime("version%Y%m%d"))
    os.makedirs(build_dir, exist_ok=True)
    with open(os.path.join(build_dir, f"{GAME}.exe"), "wb") as file:
        with open(os.path.join(LOVE_DIR, "love.exe"), "rb") as file_:
            file.write(file_.read())
        with open(f"{GAME}.love", "rb") as file_:
            file.write(file_.read())
    for filename in os.listdir(LOVE_DIR):
        if filename.endswith(".dll") or filename.startswith("license"):
            shutil.copyfile(LOVE_DIR / filename, build_dir / filename)
    shutil.make_archive(str(build_dir), "zip", build_dir)


if __name__ == "__main__":
    main()
