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

# ~/tmp/%.md : %.lua
# 	echo 1
# 	gawk -f lua2html.awk $^ > $@
#
# ~/tmp/%.html : ~/tmp/%.md 
# 	echo 2
# 	cp arent.png ~/tmp
# 	cp style2.css ~/tmp
# 	pandoc --toc -c style2.css \
# 	       --metadata title="Easeir AI"  \
#           -s --highlight-style tango  -o $@  $^
#
# ~/tmp/%.html : %.lua
# 	gawk 'NR>2 {sub(/--\[\[ ?/,""); sub(/]]--/,"") ; print $0} ' ez.lua > ez.md
# 	pandoc --metadata title="Easeir AI" --listings \
# 		 -s --mathml \
#          --highlight-style tango \

~/tmp/%.html : %.lua 
	cp style2.css ~/tmp
	gawk -f lua2html.awk $< \
	| pandoc -s -f markdown --number-sections --toc --toc-depth 5 -c style2.css \
				--mathjax \
	       --metadata title="$<" \
         --highlight-style tango  -o $@  

#          -V lang=lua -o $@  ez.md


watch:
	echo mu.lua | entr make check

check:
	clear; figlet -W -f mini  $$RANDOM ; luac -p mu.lua
