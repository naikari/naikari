ACLOCAL_AMFLAGS = --install -I m4

SUBDIRS = lib src
DIST_SUBDIRS = lib src

if HAVE_UTILS
SUBDIRS += utils
endif # HAVE_NLS
if HAVE_NLS
SUBDIRS += po
DIST_SUBDIRS += po
endif # HAVE_NLS

appicondir = $(datadir)/pixmaps
appicon_DATA = extras/logos/naikari.png
Graphicsdir = $(datadir)/applications
Graphics_DATA = naikari.desktop
appdatadir = $(datadir)/appdata
appdata_DATA = naikari.appdata.xml

dist_man6_MANS = naikari.6
dist_doc_DATA = AUTHORS Readme.md LICENSE
nobase_dist_pkgdata_DATA = dat/* po/*

if HAVE_UTILS
MKSPR      = utils/mkspr/mkspr$(EXEEXT)
endif
NAIKARI	     = $(PACKAGE)$(EXEEXT)

VERSIONFILE = VERSION
LANGUAGEFILE = $(top_srcdir)/dat/LANGUAGES

EXTRA_DIST = build/config.rpath LICENSE extras naikari.desktop naikari.appdata.xml
CLEANFILES = $(NAIKARI) $(VERSIONFILE) $(LANGUAGEFILE)

if HAVE_NLS
XMLBASE     = $(wildcard dat/*.xml)
XMLOUTFITS  = $(wildcard dat/outfits/*/*.xml)
XMLSHIPS    = $(wildcard dat/ships/*.xml)
XMLFILES    = $(XMLBASE) $(XMLSHIPS) $(XMLOUTFITS)
TRANSLATIONITS = $(top_srcdir)/po/translation.its
XMLPOT      = $(top_srcdir)/po/xml.pot
CLEANFILES += $(XMLPOT)
endif # HAVE_NLS

.PHONY: pot docs utils help install-ndata soundtrack

all-local: $(NAIKARI) pot $(VERSIONFILE)

if HAVE_NLS
$(XMLPOT): $(XMLFILES) $(TRANSLATIONITS)
	$(ITSTOOL) -i $(TRANSLATIONITS) $(XMLFILES) > $@
	@echo "ITSTOOL $@"

if HAVE_DATA
pot: $(LANGUAGEFILE) $(XMLPOT) $(NAIKARI)
	$(MAKE) -C po $(PACKAGE).pot

$(LANGUAGEFILE): po/LINGUAS
	tail -n +2 $< > $@
else # HAVE_DATA
pot:
endif # HAVE_DATA

else # HAVE_NLS
pot: $(XMLPOT) $(NAIKARI)
	@echo "***"
	@echo "*** You must have NLS enabled to compile translation files"
	@echo "***"
endif # HAVE_NLS

$(NAIKARI):
	@echo "  LN    $(NAIKARI)"
	$(LN_S) "src/$(NAIKARI)" "$(NAIKARI)"

$(VERSIONFILE): src/config.h
	echo $(VERSION) > $@

if HAVE_UTILS
utils: $(MKSPR)

$(MKSPR):
	$(MAKE) -C utils/mkspr
else # HAVE_UTILS
utils:
endif # HAVE_UTILS

uninstall-hook:
	echo " rm -rf '$(DESTDIR)$(pkgdatadir)'"; \
	echo " rm -rf '$(docdir)'"; \
	rm -rf "$(DESTDIR)$(pkgdatadir)"
	rm -rf "$(docdir)"

docs:
	$(MAKE) -C docs

soundtrack: naikari-$(VERSION)-soundtrack.zip

naikari-$(VERSION)-soundtrack.zip: utils/soundtrack.py dat/snd/soundtrack.yaml
	./utils/soundtrack.py

help:
	@echo "Possible targets are:"
	@echo "        all - builds everything"
	@echo "  ndata.zip - creates the ndata file"
	@echo "       docs - creates the doxygen documentation"
	@echo " soundtrack - creates the soundtrack zip file"
	@echo "      clean - removes binaries and object files"
	@echo "    install - installs Naikari"
	@echo "  uninstall - removes previously installed files"
	@echo "  dist-gzip - creates a source tarball with gzip compression"
	@echo " dist-bzip2 - creates a source tarball with bzip2 compression"
	@echo "  distcheck - checks if the created tarball works properly"
	@echo "  distclean - does clean and removes files created by configure"
