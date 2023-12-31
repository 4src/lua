-include ../config/do.mk

DO_what=      some lua tricks
DO_copyright= Copyright (c) 2023 Tim Menzies, BSD-2.
DO_repos=     .   

html:
	docco -o $(HOME)/tmp lib.lua
	awk '/<h1>/{ print $$0; print "<p>"f"</p>";next} 1' f="`cat top.html`" ~/tmp/lib.html > tmp1
	mv tmp1 ~/tmp/lib.html
	cp ../config/docco.css $(HOME)/tmp
	open $(HOME)/tmp/lib.html
