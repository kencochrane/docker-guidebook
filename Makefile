SHELL = /bin/sh

RSTOOL= rst2html.py
OPS= --toc-top-backlinks
DSTDIR = htmlfiles/

HTMLFILES = $(patsubst %.rst,%.html,$(wildcard *.rst))

.PHONY : clean all html utils dstdir

all: check html

%.html : %.rst
	$(RSTOOL) $(OPS) $< $(addprefix $(DSTDIR), $@)

html: dstdir $(HTMLFILES) 
	cp *.png $(DSTDIR)
	@echo Output is in $(DSTDIR)

check:
	@if [ '' = "`which $(RSTOOL)`" ]; \
	    then echo "No docutils found. make utils."; exit 1; fi

clean:
	@rm -r $(DSTDIR)

utils:
	pip install docutils

dstdir:
	@mkdir -p $(DSTDIR)
