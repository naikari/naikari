![Nightly Release](https://github.com/naikari/naikari/workflows/Nightly%20Release/badge.svg) ![CI](https://github.com/naikari/naikari/workflows/CI/badge.svg)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md) 
# NAIKARI README

![Naikari](https://naikari.github.io/images/logo.png)

Naikari: Eye of Chaos is a 2-D freeform space mystery game featuring
exploration, trading, and combat mechanics similar to games like Endless Sky
and Starsector, and a branching mystery storyline written in a manner
inspired by works like Star Control 2 (The Ur-Quan Masters) and The Expanse.

You assume control of a space ship and are free to advance thru the game
however you want. Uncover the cause of the mysterious Incident, discover the
source of the pirate scourge, or make your own way in the galaxy. In the eye of
the storm that is chaos, there is great opportunity.

## DEPENDENCIES

Naikari's dependencies are intended to be relatively common. In addition to an
OpenGL-capable graphics card and driver with support for at least OpenGL 3.1,
Naikari requires the following:
* SDL 2
* SDL2_image
* libxml2
* freetype2
* libpng
* libwebp
* OpenAL
* libvorbis >= 1.2.2
* intltool
* python3
* ninja
* libunibreak (included)
* SuiteSparse (included)

If you're cross-compiling for Windows, you must install this soft dependency:
* [physfs](https://icculus.org/physfs/), example package name mingw-w64-physfs


### Debian/Ubuntu

Install compile-time dependencies on Debian 10 or later, or Ubuntu 18.04
or later, with:

```sh
sudo apt install build-essential ninja-build autopoint intltool \
    python3-pip \
    libsdl2-dev libsdl2-image-dev libgl1-mesa-dev libxml2-dev \
    libfreetype6-dev libpng-dev libwebp-dev libopenal-dev libvorbis-dev \
    libfontconfig-dev  libluajit-5.1-dev libphysfs-dev \
    libunibreak-dev libsuitesparse-dev
sudo pip3 install meson
```

### macOS

Warning: this procedure is inadequate if you want to build a Naikari.app that you can share with users of older macOS versions than your own.

Dependencies may be installed using [Homebrew](https://brew.sh):
```
brew install freetype gettext intltool libpng libvorbis luajit meson openal-soft physfs pkg-config sdl2_image suite-sparse
```
Building the latest available code in git is recommended, but to build version 0.8 you can add `sdl2_mixer` (and `autoconf-archive` and `automake` if using Autotools to build).

Meson needs an extra argument to find Homebrew's `openal-soft` package: `--pkg-config-path=/usr/local/opt/openal-soft/lib/pkgconfig`.
If build may fail if `suite-sparse` is installed via Homebrew, citing an undefined reference to `_cs_di_spfree`. A workaround is to pass `--force-fallback-for=SuiteSparse`.
(These arguments may be passed to the initial `meson setup` or applied later using `meson configure`. In the later case, make sure to run `meson configure --clearcache` to work around bugs in Meson. For 0.8/Autotools, set the `PKG_CONFIG_PATH` environment variable before running `./configure`.)

### Other Linux

See https://github.com/naikari/naikari/wiki/Compiling-on-Linux for
package lists for several distributions.

## COMPILING

### CLONING AND SUBMODULES

Naikari requires the artwork submodule to run from git. You can check out the
submodules from the cloned repository with:

```sh
git submodule init
git submodule update
```

Note that `git submodule update` has to be run every time you `git pull` to stay
up to date. This can also be done automatically by setting the following
configuration:

```sh
git config submodule.recurse true
```

### COMPILATION

After checking out submodules (see above), run:

```sh
meson setup build .
cd build
meson compile
./naikari.sh
```

If you need special settings you can run `meson configure` in your build
directory to see a list of all available options.

**For installation**, try: `meson configure --buildtype=release -Db_lto=true`

**For Windows packaging**, try adding: `--bindir=bin -Dndata_path=bin`

**For macOS**, try adding: `--prefix="$(pwd)"/build/dist/Naikari.app --bindir=Contents/MacOS -Dndata_path=Contents/Resources`

**For normal development**, try adding: `--buildtype=debug -Db_sanitize=address` (adding `-Db_lundef=false` if compiling with Clang, substituting `-Ddebug_arrays=true` for `-Db_sanitize=...` on Windows if you can't use Clang).

**For faster debug builds** (but harder to trace with gdb/lldb), try `--buildtype=debugoptimized -Db_lto=true -Db_lto_mode=thin` in place of the corresponding values above.

## INSTALLATION

Naikari currently supports `meson install` which will install everything that
is needed.

If you wish to create a .desktop for your desktop environment, logos
from 16x16 to 256x256 can be found in `extras/logos/`.

## WINDOWS

See https://github.com/naikari/naikari/wiki/Compiling-on-Windows for how to compile on windows.

## UPDATING ART ASSETS

Art assets are partially stored in the naikari-artwork-production repository
and sometimes are updated. For that reason, it is recommended to periodically
update the submodules with the following command.

```sh
git submodule update
```

You can also set this to be done automatically on git pull with the following
command:

```sh
git config submodule.recurse true
```

Afterwards, every time you perform a `git pull`, it will also update the
artwork submodule.

## TRANSLATION

If you are a developer, you may need to update translation files as
text is modified. You can update all translation files with the
following commands:

```sh
meson compile potfiles           # necessary if files have been added or removed
meson compile naikari-pot        # necessary if translatable strings changed
meson compile naikari-update-po  # necessary if translatable strings changed
```

This will allow you to edit the translation files in `po/` manually to modify
translations.

If you like, you can set up commit hooks to handle the `potfiles` step. For instance:
```bash
# .git/hooks/pre-commit
#!/bin/bash
. utils/update-po.sh

# .git/hooks/post-commit
#!/bin/sh
git diff --exit-code po/POTFILES.in || exec git commit --amend -C HEAD po/POTFILES.in
```

## CRASHES & PROBLEMS

Please take a look at the [FAQ](https://github.com/naikari/naikari/wiki/FAQ)
before submitting a new bug report, as it covers a number of common gameplay
questions and common issues.

If Naikari is crashing during gameplay, please file a bug report.

