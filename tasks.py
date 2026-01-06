from invoke import task, context, Exit
import os
import subprocess
import re
from colorama import *
import glob
import shutil
from shutil import copy2, rmtree, copytree
from datetime import datetime
import pathlib
from typing import *
import time
from pathlib import Path

init()


class BuildConfig:
    """Configuration for the build process"""
    def __init__(self):
        self.releases_path = "releases"
        self.output = "bin"
        self.output_folder = ""  # defined at runtime
        self.version = "DEV"
        # Project root directory (where tasks.py is located)
        self.project_root = os.path.dirname(os.path.abspath(__file__))
        self.seven_zip = os.path.join(self.project_root, "7z.exe")

    @property
    def output_folder_path(self):
        return os.path.join(self.releases_path, self.version)


# Global config instance
config = BuildConfig()


delphi_versions = [
    {"version": "10.0", "path": "17.0", "desc": "Delphi 10 Seattle"},
    {"version": "10.1", "path": "18.0", "desc": "Delphi 10.1 Berlin"},
    {"version": "10.2", "path": "19.0", "desc": "Delphi 10.2 Tokyo"},
    {"version": "10.3", "path": "20.0", "desc": "Delphi 10.3 Rio"},
    {"version": "10.4", "path": "21.0", "desc": "Delphi 10.4 Sydney"},
    {"version": "11.0", "path": "22.0", "desc": "Delphi 11 Alexandria"},
    {"version": "11.1", "path": "22.0", "desc": "Delphi 11.1 Alexandria"},
    {"version": "11.2", "path": "22.0", "desc": "Delphi 11.2 Alexandria"},
    {"version": "11.3", "path": "22.0", "desc": "Delphi 11.3 Alexandria"},
    {"version": "12.0", "path": "23.0", "desc": "Delphi 12 Athens"},
    {"version": "13.0", "path": "37.0", "desc": "Delphi 13 Florence"},
]


def get_package_folders():
    """Get list of package folders by scanning the packages directory.
    Returns folders that match the pattern 'd*' (e.g., d100, d110, d130)"""
    packages_dir = "packages"
    if not os.path.isdir(packages_dir):
        return []
    folders = []
    for item in os.listdir(packages_dir):
        item_path = os.path.join(packages_dir, item)
        if os.path.isdir(item_path) and item.startswith("d") and item[1:].isdigit():
            folders.append(item)
    return sorted(folders)


def get_delphi_projects_to_build(which=""):
    """Get list of Delphi projects to build based on type filter"""
    projects = []
    delphi_version, _ = get_best_delphi_version_available()
    dversion = "d" + delphi_version["version"].replace(".", "")

    if not which or which == "core":
        # Build package for the current Delphi version
        projects += glob.glob(rf"packages\{dversion}\*.dproj")

    if not which or which == "tests":
        projects += glob.glob(r"unittests\*.dproj")

    if not which or which == "samples":
        projects += glob.glob(r"samples\**\*.dproj", recursive=True)
        # Exclude Android-only samples from Win32 build
        projects = [p for p in projects if "130_simple_console_appender" not in p]

    return sorted(projects)


def get_best_delphi_version_available() -> tuple[dict, str]:
    global delphi_version
    found = False
    rsvars_path = None
    i = len(delphi_versions)
    while (not found) and (i >= 0):
        i -= 1
        delphi_version = delphi_versions[i]
        version_path = delphi_version["path"]
        rsvars_path = f"C:\\Program Files (x86)\\Embarcadero\\Studio\\{version_path}\\bin\\rsvars.bat"
        if os.path.isfile(rsvars_path):
            found = True
        else:
            rsvars_path = f"D:\\Program Files (x86)\\Embarcadero\\Studio\\{version_path}\\bin\\rsvars.bat"
            if os.path.isfile(rsvars_path):
                found = True
    if found:
        return delphi_version, rsvars_path
    else:
        raise Exception("Cannot find a Delphi compiler")


def build_delphi_project(
    ctx: context.Context, project_filename, config="DEBUG", platform="Win32"
):
    delphi_version, rsvars_path = get_best_delphi_version_available()
    print("\nBUILD WITH: " + delphi_version["desc"])
    cmdline = (
        '"'
        + rsvars_path
        + '"'
        + " & msbuild /t:Build /p:Config="
        + config
        + f' /p:Platform={platform} "'
        + project_filename
        + '"'
    )
    r = ctx.run(cmdline, hide=True, warn=True)
    if r.failed:
        print(r.stdout)
        print(r.stderr)
        raise Exit("Build failed for " + delphi_version["desc"])


def create_zip(ctx, version):
    print("CREATING ZIP")
    archive_name = "..\\" + version + ".zip"
    cmdline = f'"{config.seven_zip}" a {archive_name} *'
    print(cmdline)
    with ctx.cd(config.output_folder):
        result = ctx.run(cmdline, hide=False, warn=True)
        if result.failed:
            print(Fore.RED + "ERROR: Failed to create zip" + Fore.RESET)
            raise Exit("Failed to create zip archive")


def copy_sources():
    """Copy source files to output folder"""
    os.makedirs(config.output_folder, exist_ok=True)

    # Copy main source files
    print("Copying LoggerPro Sources...")
    src_files = glob.glob("*.pas") + glob.glob("*.inc")
    for file in src_files:
        if os.path.isfile(file):
            print(f"Copying {file} to {config.output_folder}")
            copy2(file, config.output_folder)

    # Copy packages
    folders = get_package_folders()
    if not folders:
        raise Exit("No package folders found in packages directory")

    for folder in folders:
        print(f"Copying LoggerPro packages {folder}...")
        src_folder = os.path.join("packages", folder)
        dest_folder = os.path.join(config.output_folder, "packages", folder)
        os.makedirs(dest_folder, exist_ok=True)

        for ext in ["*.dpk", "*.dproj"]:
            for file in glob.glob(os.path.join(src_folder, ext)):
                print(f"Copying {file}")
                copy2(file, dest_folder)

    # Copy samples
    print("Copying samples...")
    samples_dest = os.path.join(config.output_folder, "samples")
    ignore_patterns = shutil.ignore_patterns(
        "*.identcache", "*.dcu", "*.exe", "*.res", "*.stat",
        "*.local", "*.log", "__history", "__recovery", "Win32", "Win64",
        "nul"  # Windows reserved filename
    )
    copytree("samples", samples_dest, ignore=ignore_patterns)


def ensure_dir_exists(path, description=""):
    """Validate that a directory exists, raise Exit if not"""
    if not os.path.isdir(path):
        desc = f" ({description})" if description else ""
        raise Exit(f"Source directory not found{desc}: {path}")


def printkv(key, value):
    print(Fore.RESET + key + ": " + Fore.GREEN + value.rjust(60) + Fore.RESET)


def show_version():
    """Display current version at build start"""
    version = get_version_from_file()
    print()
    print(Fore.CYAN + "=" * 80 + Fore.RESET)
    print(Fore.CYAN + f" LOGGERPRO VERSION: {version}" + Fore.RESET)
    print(Fore.CYAN + "=" * 80 + Fore.RESET)
    print()
    return version


def init_build(version, clean_releases=False):
    """Required by all tasks"""
    config.version = version
    config.output_folder = config.releases_path + "\\" + config.version
    print()
    print(Fore.RESET + Fore.RED + "*" * 80)
    print(Fore.RESET + Fore.RED + " BUILD VERSION: " + config.version + Fore.RESET)
    print(Fore.RESET + Fore.RED + " OUTPUT PATH  : " + config.output_folder + Fore.RESET)
    print(Fore.RESET + Fore.RED + "*" * 80)

    if clean_releases:
        print("Cleaning releases folder...")
        rmtree(config.releases_path, True)
    else:
        rmtree(config.output_folder, True)
    os.makedirs(config.output_folder, exist_ok=True)
    f = open(config.output_folder + "\\version.txt", "w")
    f.write("VERSION " + config.version + "\n")
    f.write("BUILD DATETIME " + datetime.now().isoformat() + "\n")
    f.close()
    copy2("README.md", config.output_folder)
    copy2("License.txt", config.output_folder)


def build_delphi_project_list(ctx, projects, build_config="DEBUG", filter=""):
    ret = True
    for delphi_project in projects:
        if filter and (filter not in delphi_project):
            print(f"Skipped {os.path.basename(delphi_project)}")
            continue
        msg = f"Building: {os.path.basename(delphi_project)}  ({build_config})"
        print(Fore.RESET + msg.ljust(90, "."), end="")
        try:
            build_delphi_project(ctx, delphi_project, build_config)
            print(Fore.GREEN + "OK" + Fore.RESET)
        except Exception as e:
            print(Fore.RED + "\n\nBUILD ERROR")
            print(Fore.RESET)
            print(e)
            ret = False

    return ret


@task
def clean(ctx, folder=None):
    """Clean build artifacts"""
    if folder is None:
        folder = "."
    if not os.path.isdir(folder):
        print(f"Folder does not exist, nothing to clean: {folder}")
        return
    print(f"Cleaning folder {folder}")

    to_delete = []
    to_delete += glob.glob(folder + r"\**\*.exe", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.dcu", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.stat", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.res", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.map", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.~*", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.rsm", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.drc", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.log", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.local", recursive=True)
    to_delete += glob.glob(folder + r"\**\*.identcache", recursive=True)

    for f in to_delete:
        print(f"Deleting {f}")
        try:
            os.remove(f)
        except Exception as e:
            print(f"Warning: could not delete {f}: {e}")

    # Clean __history and __recovery folders
    for pattern in [r"**\__history", r"**\__recovery"]:
        for d in glob.glob(folder + "\\" + pattern, recursive=True):
            print(f"Removing directory {d}")
            rmtree(d, True)


@task()
def tests(ctx):
    """Builds and execute the unit tests"""
    show_version()
    testclient = r"unittests\UnitTests.dproj"

    print("\nBuilding Unit Tests")
    build_delphi_project(ctx, testclient, config="CI")

    print("\nExecuting tests...")
    r = subprocess.run([r"unittests\Win32\CI\UnitTests.exe"])
    if r.returncode != 0:
        raise Exit("Cannot run unit tests: \n" + str(r.stdout))
    if r.returncode > 0:
        print(r)
        print("Unit Tests Failed")
        raise Exit("Unit tests failed")


def get_version_from_file():
    with open(r".\loggerprobuildconsts.inc") as f:
        lines = f.readlines()
    # Find line with LOGGERPRO_VERSION or DMVCFRAMEWORK_VERSION
    res = [x for x in lines if "_VERSION" in x and "=" in x]
    if len(res) != 1:
        raise Exception("Cannot find version constant in loggerprobuildconsts.inc")
    version_line = res[0].strip(" ;\t\n")
    pieces = version_line.split("=")
    if len(pieces) != 2:
        raise Exception("Version line in wrong format: " + version_line)
    version = pieces[1].strip("' ")

    if not "loggerpro" in version.lower():
        version = "loggerpro-" + version

    print(Fore.RESET + Fore.GREEN + "BUILDING VERSION: " + version + Fore.RESET)
    return version


def inc_version():
    """Increment patch version number in loggerprobuildconsts.inc"""
    global config
    home = Path(__file__).parent
    inc_file = home.joinpath("loggerprobuildconsts.inc")

    with open(inc_file, "r") as f:
        content = f.read()

    # Find current version
    match = re.search(r"_VERSION\s*=\s*'([^']+)'", content)
    if not match:
        raise Exception("Cannot find version in loggerprobuildconsts.inc")

    v = match.group(1)
    # Remove "loggerpro-" prefix if present for parsing
    v_clean = v.replace("loggerpro-", "")
    pieces = v_clean.split(".")
    if len(pieces) != 2:
        # Try with 3 parts
        if len(pieces) != 3:
            raise Exception(f"Invalid version format: {v}")

    if len(pieces) == 2:
        new_version = pieces[0] + "." + str(int(pieces[1]) + 1)
    else:
        new_version = ".".join(pieces[:-1]) + "." + str(int(pieces[2]) + 1)

    config.version = new_version

    print(f"INC VERSION [{v}] => [{new_version}]")

    # Replace version in file
    new_content = re.sub(r"(_VERSION\s*=\s*')[^']+(')", rf"\g<1>{new_version}\g<2>", content)
    with open(inc_file, "w") as f:
        f.write(new_content)

    return new_version


@task()
def release(ctx, skip_build=False, skip_tests=False):
    """Builds all the projects, executes tests and prepares the release"""

    version = show_version()
    init_build(version, clean_releases=False)  # Only clean current version folder

    if not skip_tests:
        tests(ctx)

    if not skip_build:
        delphi_projects = get_delphi_projects_to_build("")
        if not _build_projects(ctx, delphi_projects, "DEBUG", ""):
            return False

    print(Fore.RESET)
    copy_sources()
    clean(ctx, config.output_folder)
    create_zip(ctx, version)
    return True


def _build_projects(ctx, delphi_projects, version, filter):
    return build_delphi_project_list(ctx, delphi_projects, version, filter)


@task
def build_samples(ctx, version="DEBUG", filter=""):
    """Builds samples"""
    show_version()
    init_build(version)
    delphi_projects = get_delphi_projects_to_build("samples")
    return _build_projects(ctx, delphi_projects, version, filter)


@task
def build_core(ctx, version="DEBUG"):
    """Builds core package"""
    show_version()
    init_build(version)
    delphi_projects = get_delphi_projects_to_build("core")
    if not _build_projects(ctx, delphi_projects, version, ""):
        raise Exit("Build failed")


@task(post=[tests])
def build(ctx, version="DEBUG"):
    """Builds LoggerPro and runs tests"""
    show_version()
    delphi_projects = get_delphi_projects_to_build("")
    ret = build_delphi_project_list(ctx, delphi_projects, version)
    if not ret:
        raise Exit("Build failed")


@task()
def tag_release(ctx):
    """Creates a git tag for the current version and pushes it"""
    version = get_version_from_file()
    tag_name = "v" + version.replace("loggerpro-", "").replace(" ", "_")

    print("Creating Git tag " + tag_name)

    result = ctx.run("git add -u", warn=True)
    if result.failed:
        raise Exception("Cannot add files to git")

    result = ctx.run(f"git tag {tag_name}", warn=True)
    if result.failed:
        raise Exception("Cannot create git tag")

    result = ctx.run(f'git commit -m "Release {tag_name}"', warn=True)
    if result.failed:
        raise Exception("Cannot commit on git")

    result = ctx.run("git push origin", warn=True)
    if result.failed:
        raise Exception("Cannot push")

    result = ctx.run(f"git push origin {tag_name}", warn=True)
    if result.failed:
        raise Exception("Cannot push tag")

    print(Fore.GREEN + f"Successfully created and pushed tag {tag_name}" + Fore.RESET)


@task()
def bump_version(ctx):
    """Increments the patch version number"""
    inc_version()
