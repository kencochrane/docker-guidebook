SHELL = /bin/sh

RSTOOL = rst2html.py
RSTOPS = --stylesheet=html4css1.css,tutorial.css
DSTDIR = htmlfiles
PYTHON = python

HTMLFILES = $(patsubst %.rst,$(DSTDIR)/%.html,$(wildcard *.rst))
CSSFILES = $(wildcard *.css)

.PHONY : clean all html utils dstdir

all: check html

$(DSTDIR)/%.html : %.rst  $(CSSFILES)
	$(RSTOOL) $(RSTOPS) $< $@

html: dstdir $(HTMLFILES)
	@cp *.png $(DSTDIR)
	@echo Output is in $(DSTDIR)

check:
	@if [ '' = "`which $(RSTOOL)`" ]; \
	    then echo "No docutils found. make utils."; exit 1; fi

clean:
	@rm -r $(DSTDIR)

utils:
	@pip install docutils

dstdir:
	@mkdir -p $(DSTDIR)

server: html
	@cd $(DSTDIR); $(PYTHON) -m SimpleHTTPServer 8000 
