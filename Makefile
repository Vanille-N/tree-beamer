all: rfmig.pdf

rfmig.pdf: main.pdf
	cp $< $@

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

override IMGDIR = img
override IMG = \
	#

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
