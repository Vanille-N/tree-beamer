all: main.pdf

# All .tex source files
override SRC = $(wildcard src/*.tex)
override CP = $(SRC:src/%=build/%) build/literature.bib build/rustlistings.sty

# LatexMK options
override TEX_BASE_OPT = -pdf -interaction=nonstopmode -halt-on-error
override TEXC = latexmk $(TEX_BASE_OPT)

# There's a little too much text when pdflatex builds,
# so we filter out some of the useless warnings/infos
define TEX_FILTER_PATS
/Package hyperref Warning/,+2d   # Useless warnings
/texmf-dist/d                    # List of loaded files is not useful
/\.code\.tex/d                   # Catches some instances of the previous rule that span multiple lines
/^[^(]*)/d                       # Handles the rest of the previous rule
/Underfull/d                     # "Underfull hbox badness" is basically spam
/^\s*$$/d                        # Too much whitespace
endef
export TEX_FILTER_PATS
override FILTER = sed "$$TEX_FILTER_PATS"

# Copy once it's built
%.pdf: build/%.pdf
	cp $< $@

# Aux build directory to not clutter the working directory
build:
	mkdir -p $@
build/%: |build

# Easy copies
build/%: src/% |build
	cp $< $@
build/literature.bib: literature.bib |build
	cp $< $@

# These need to be built before the main document
override FIGURES = \
	#

# Baselines
override FIGURES += \
	mod.core \
	mod.base \
	mod.prot \
	mod.full \
	#

# Blanks (transparent elements to guarantee alignment across pauses)
override FIGURES += \
	blank.base \
	blank.prot \
	#

# Step-by-step introduction
override FIGURES += \
	steps.core.cr \
	steps.core.cr+cw \
	steps.core.cr+cw+fr \
	steps.core.cr+cw+fr+fw \
	#

# Illustrating the need for Reserved
override FIGURES += \
	path.core.mut \
	path.core.mut+fr \
	path.core.mut+fr+cw \
	steps.base \
	steps.base.diff \
	path.base.mut \
	path.base.mut+fr \
	path.base.mut+fr+cw \
	#


# Illustrating the need for Protectors
override FIGURES += \
	path.base.mut+cw+fr \
	steps.prot.cp \
	steps.prot.nodis \
	steps.prot.noalias \
	path.prot.mut+cw+fr \
	#

# Optimization: delay write
override FIGURES += \
	path.base.mut+cw+cw \
	path.base.mut+cw+fw+cw \
	path.base.mut+cw \
	#

# Optimization: speculative read
override FIGURES += \
	path.prot.shr+cr \
	path.prot.shr+cr+fr \
	path.prot.shr+fw \
	#

# Strengthening: speculative write
override FIGURES += \
	path.prot.mut+fw \
	path.prot.mut+fr \
	path.prot.mut+fr+cw \
	steps.prot+w \
	path.prot+w.mut \
	path.prot+w.mut+cw \
	path.prot+w.mut+fr-fw \
	#

# Strengthening: disable on read
override FIGURES += \
	steps.base+d \
	path.base.mut+cw+cr+fr \
	path.base.mut+cw+fr-o+cr \
	path.base.mut+cw+fr+cr \
	path.base+d.mut+cw+cr \
	path.base+d.mut+cw+fr+cr \
	path.base+d.mut+cw+cr+fr \
	#

# Other interesting visual representations
override FIGURES += \
	#intuition.idempotent \
	#intuition.readread \
	#

override IMGDIR = img
override IMG = \
	#

build/%.pdf: $(IMGDIR)/%.raw src/raw.head src/raw.foot
	cat src/raw.head $< src/raw.foot > $@
	cd build && \
		$(TEXC) $$(basename $@) \
		| $(FILTER)

build/main.pdf: $(FIGURES:%=build/%.pdf) $(IMG:%=build/%)

build/%: $(IMGDIR)/%
	cp $< $@

# Drop the difficult work on latexmk
build/%.pdf: build/%.tex $(CP) |build
	cd build && \
		$(TEXC) $$(basename $<) \
		| $(FILTER)

# Easy clean thanks to the separate build directory
clean:
	rm -rf build
reset:
	make clean
	rm -f *.pdf
force:
	make reset && make

.PHONY: clean all
