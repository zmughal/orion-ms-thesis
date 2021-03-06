## Config global
LATEXMK = latexmk $(LATEXMKRC_FLAGS) -f -pdf -silent -diagnostics
XELATEX_OPT := -e '$$pdflatex=q/xelatex -synctex=1 %O %S/'

## Config project
GFX_OUT_DIR := gfx-out
GFX_DIR := gfx

THESIS_CHAPTERS := \
	01_introduction/introduction.tex \
	02_analysis/analysis.tex \
	03_design/design.tex \
	04_implementation/implementation.tex \
	05_testing/testing.tex \
	06_conclusion/conclusion.tex \
	appendix/appendix.tex
THESIS_META := meta/title.tex meta/committee.tex
THESIS_DEP := 00_front-matter/abstract.tex 00_front-matter/acknowledgements.tex 00_front-matter/notation.tex \
	preamble/helper.tex thesis.bib \
	$(THESIS_META) $(THESIS_CHAPTERS)
PRESENT_DEP := preamble/present-helper.tex meta/defense.tex

GFX_DEP := \
	$(GFX_OUT_DIR)/matlab-call-graph/segmentation.tex \
	$(GFX_OUT_DIR)/matlab-call-graph/registration.tex \
	$(GFX_OUT_DIR)/matlab-call-graph/tracing.tex \
	$(GFX_DIR)/sdlc.tex \
	$(GFX_DIR)/algorithm/*.tex

## Rules

MINIMAL_TARGETS := thesis.pdf present.pdf
NOTES_TARGETS := note/experimental.pdf note/biblio.pdf note/algorithm.pdf note/test.pdf
PRESENT_EXTRA_TARGETS := present-note.pdf present-article.pdf present-handout-2x3.pdf

ALL_TARGETS := $(MINIMAL_TARGETS) $(PRESENT_EXTRA_TARGETS) $(NOTES_TARGETS)

all:  $(ALL_TARGETS) tags

minimal: $(MINIMAL_TARGETS)

notes: $(NOTES_TARGETS)

thesis.pdf: thesis.tex $(THESIS_DEP) $(GFX_DEP)

algorithm.pdf: algorithm.tex $(THESIS_DEP)

note/test.pdf: LATEXMKRC_FLAGS += $(XELATEX_OPT)

# this will fail unless the presentation uses \note{...}
present-note.pdf: LATEXMKRC_FLAGS += -jobname=present-note $(XELATEX_OPT)
present-note.pdf: present.tex $(PRESENT_DEP)
	-$(LATEXMK) '\def\printpresentnote{} \input $<'

present-article.pdf: LATEXMKRC_FLAGS += -jobname=present-article $(XELATEX_OPT)
present-article.pdf: present.tex $(PRESENT_DEP)
	-$(LATEXMK) '\def\printpresentarticle{} \input $<'

present-handout.pdf: LATEXMKRC_FLAGS += -jobname=present-handout $(XELATEX_OPT)
present-handout.pdf: present.tex $(PRESENT_DEP)
	-$(LATEXMK) '\def\printpresenthandout{} \input $<'

present.pdf: LATEXMKRC_FLAGS +=  $(XELATEX_OPT)
present.pdf: present.tex $(PRESENT_DEP)

present-handout-2x3.pdf: present-handout.pdf
	pdfjam-slides6up --suffix '2x3' --batch $<


note/%.pdf: note/%.tex
	-$(LATEXMK) --outdir=note $<

%.pdf: %.tex
	-$(LATEXMK) $<

%.tex: %.md
	pandoc -t latex $< -o $@

$(GFX_OUT_DIR):
	mkdir -p $(GFX_OUT_DIR)

$(GFX_OUT_DIR)/%.tex : gfx/%.dot
	mkdir -p `dirname $@`
	dot2tex --format tikz --figonly < $< > $@

tags:
	ctags -R .

include ~/sw_projects/zmughal/scraps/scraps/build/latex/clean.mk

wc-pdf: thesis.pdf
	pdftotext thesis.pdf - | wc -w
wc-tex:
	find -name '*.tex' | xargs wc -w

cleanall::
	rm -Rf $(ALL_TARGETS)
	rm -Rf $(GFX_OUT_DIR)
	rm -Rf tags

check:
	@echo "Check for references that are not resolved"
	@echo "==="
	-@pdftotext thesis.pdf  - | grep --colour=auto -C1 '??'
	-@fgrep "I didn't find a database entry" *.blg
	@echo "==="
	lacheck thesis.tex
	@echo "==="
	chktex thesis.tex


latexdiff-thesis:
	if [ -z "$(LAST_VERSION)" ]; then \
		LTX_COMP=`git tag | tail -1`; \
		echo "Using last tag: $$LTX_COMP"; \
	else \
		LTX_COMP=$(LAST_VERSION); \
	fi; \
	git latexdiff -v --output diff.pdf --ignore-latex-errors --main thesis.tex $$LTX_COMP master

dep-debian:
	sudo apt-get install --no-install-recommends $$( sed 's/#.*$$//g' < debian-packages )

.PHONY: all minimal notes wc-pdf wc-tex check latexdiff-thesis dep-debian
