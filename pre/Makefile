.SILENT:

~/tmp/%.pdf: %.lua  ## make doco: .py ==> .pdf
	mkdir -p ~/tmp
	echo "pdf-ing $@ ... "
	a2ps                 \
		-Br                 \
		--chars-per-line=90 \
		--file-align=fill      \
		--line-numbers=1        \
		--pro=color               \
		--left-title=""            \
		--borders=no             \
		--pretty-print=lua.ssh    \
	    --left-footer="$<  "               \
	    --right-footer="page %s. of %s#"               \
		--columns 3                 \
		-M letter                     \
	  -o	 $@.ps $<
	ps2pdf $@.ps $@; rm $@.ps
	open $@
