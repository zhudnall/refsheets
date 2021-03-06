TEX     := pdflatex
# shell escape is needed for minted latex package
TEX_OPTS    := --halt-on-error -shell-escape
PANDOC_OPTS := -s -f markdown+grid_tables+pipe_tables \
	--self-contained --css pandoc.css \
	-H header.html \
	--mathjax=https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS-MML_HTMLorMML
TEX_SOURCES := $(wildcard *.tex)
MD_SOURCES  := $(filter-out index.md README.md, $(wildcard *.md))
OUTPUTS     := \
	$(MD_SOURCES:%.md=%.md.html) \
	$(MD_SOURCES:%.md=%.md.pdf)  \
	$(TEX_SOURCES:%.tex=%.pdf)   \
	index.html
.SHELL=bash

all: $(OUTPUTS) 

clean:
	rm  -f *.pdf
	rm  -f *.md.html
	rm -rf .latex
	mkdir -p .latex

%.pdf: %.tex
	mkdir -p .latex
	# cp into folder so all the latex garbage goes there
	# on some systems, we must build in the same folder as the
	# .tex document for minted to work
	cp $< .latex/
	cd .latex/ && $(TEX) $(TEX_OPTS) $<
	# this compresses the output pdf file
	gs -sDEVICE=pdfwrite \
		-dCompatibilityLevel=1.4 \
		-dNOPAUSE \
		-dQUIET \
		-dBATCH \
		-sOutputFile=$@ .latex/$@
	# cp .latex/$@ $@

%.md.html: %.md pandoc.css header.html
	pandoc $(PANDOC_OPTS) $< -o $@

%.md.pdf: %.md
	pandoc $< -o $@

csce314_reference_sheet.pdf: csce314_reference_sheet.tex
	# special case to use xelatex for custom fonts
	mkdir -p .latex
	cp $< .latex/
	cd .latex/ && xelatex $(TEX_OPTS) $<
	gs -sDEVICE=pdfwrite \
		-dCompatibilityLevel=1.4 \
		-dNOPAUSE \
		-dQUIET \
		-dBATCH \
		-sOutputFile=$@ .latex/$@

index.html: $(wildcard *.pdf) $(wildcard *.md) pandoc.css header.html
	cat README.md > index.md
	echo >> index.md
	echo '# Links' >> index.md
	for f in $(filter-out index.md.html index.html header.html, $(wildcard *.pdf *.html)); do echo "* [$$f]($$f)" >> index.md; done
	pandoc $(PANDOC_OPTS) index.md -o $@
	rm index.md
