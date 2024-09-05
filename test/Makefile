src/%.lua : docs/%.md
	cat $< | gawk 'BEGIN{n=0; a[0]=""; a[1]="-- "}  sub(/^```lua/,"") { n=n-1 } sub(/^```/,"") { n=n-1 } {print a[n]$$0}'
