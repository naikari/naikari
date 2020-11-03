![Nightly Release](https://github.com/naikari/naikari/workflows/Nightly%20Release/badge.svg) ![CI](https://github.com/naikari/naikari/workflows/CI/badge.svg)
# NAIKARI README

Naikari is a 2D space trading and combat game, taking inspiration from the Escape
Velocity series, among others.

You pilot a space ship from a top-down perspective, and are more or less free
to do what you want. As the genre name implies, you’re able to trade and engage
in combat at will. Beyond that, there’s an ever-growing number of storyline
missions, equipment, and ships; Even the galaxy itself grows larger with each
release. For the literarily-inclined, there are large amounts of lore
accompanying everything from planets to equipment.

## DEPENDENCIES

Naikari's dependencies are intended to be relatively common. In addition to
an OpenGL-capable graphics card and driver, Naikari requires the following:
* SDL 2
* libxml2
* freetype2
* libpng
* OpenAL
* libvorbis (>= 1.2.1 necessary for Replaygain)
* binutils
* intltool

Note that several distributions ship outdated versions of libvorbis, and
thus libvorbisfile is statically linked into the release binary.

Compiling your own binary on many distributions will result in Replaygain
being disabled.

### Ubuntu

Install compile-time dependencies on Ubuntu 16.04 (and hopefully later) with:

```bash
apt-get install build-essential libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev \
libgl1-mesa-dev libxml2-dev libfreetype6-dev libpng-dev libopenal-dev \
libvorbis-dev binutils-dev libiberty-dev autopoint intltool libfontconfig-dev \
python3-pip
pip3 install meson ninja
```

### Other Linux

See https://github.com/naikari/naikari/wiki/Compiling-on-Linux for
package lists for several distributions.

## COMPILING

Run:

```
meson setup builddir .
cd build
meson compile
```

If you need special settings you can run `meson configure` in your build
directory to see a list of all available options.

## INSTALLATION

Naikari currently supports `meson install` which will install everything that
is needed.

If you wish to create a .desktop for your desktop environment, logos
from 16x16 to 256x256 can be found in `extras/logos/`.

## WINDOWS

See https://github.com/naikari/naikari/wiki/Compiling-on-Windows for how to compile on windows.

## UPDATING PO FILES

If you are a developer, you may need to update translation files as
text is modified. You can update all translation files with the
following commands:

```
meson compile potfiles # only necessary if files have been added or removed
meson compile naikari-pot
meson compile naikari-update-po
```

Again, you will only ever need to do this if you are a developer.

## CRASHES & PROBLEMS

Please take a look at the FAQ (linked below) before submitting a new
bug report, as it covers a number of common gameplay questions and
common issues.

If Naikari is crashing during gameplay, please file a bug report.

