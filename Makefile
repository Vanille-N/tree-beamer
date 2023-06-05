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
	sm-core \
	sm-base \
	sm-prot \
	sm-full \
	#

# Blanks (transparent elements to guarantee alignment across pauses)
override FIGURES += \
	sm-baseline-blank \
	sm-prot-blank \
	#

# Step-by-step introduction
override FIGURES += \
	sm-intro-cr \
	sm-intro-cr+cw \
	sm-intro-cr+cw+fr \
	sm-intro-cr+cw+fr+fw \
	#

# Illustrating the need for Reserved
override FIGURES += \
	sm-path-act \
	sm-path-act+frz \
	sm-path-act+frz+ub \
	sm-res-add \
	sm-res-dim \
	sm-res-same \
	sm-res-diff \
	sm-path-res \
	sm-path-res+res \
	sm-path-res+res+act \
	#


# Illustrating the need for Protectors
override FIGURES += \
	sm-path-res+act+frz \
	sm-prot-cp \
	sm-prot-nodis \
	sm-prot-noalias \
	sm-path-pres+pact+ub \
	#

# Optimization: delay write
override FIGURES += \
	sm-path-res+act+Wact \
	sm-path-res+act+dis+ub \
	sm-path-res+act \
	#

# Optimization: speculative read
override FIGURES += \
	sm-path-pfrz+pfrz \
	sm-path-pfrz+pfrz+pfrz \
	sm-path-pfrz+ub \
	#

# Strengthening: speculative write
override FIGURES += \
	sm-strengthening-act \
	sm-path-pres+ub \
	sm-path-pres+pfrz \
	sm-path-pres+pfrz+ub \
	sm-path-st-pact \
	sm-path-st-pact+ub \
	sm-path-st-pact+pact \
	#

# Strengthening: disable on read
override FIGURES += \
	sm-strengthening-dis \
	sm-path-res+act+actfrz \
	sm-path-st-res+act+act \
	sm-path-st-res+act+dis+ub \
	sm-path-res+act+Ract+frz \
	sm-path-res+act+frz+frz \
	sm-path-st-res+act+act+dis \
	sm-path-st-res+act+dis+ub \
	#

# Other interesting visual representations
override FIGURES += \
	sm-idempotent \
	sm-readread \
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
