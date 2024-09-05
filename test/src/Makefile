src/%.lua : docs/%.md
	cat $< | gawk 'BEGIN{n=0; a[0]=""; a[1]="-- "}  sub(/^```lua/,"") { n=1-n } sub(/^```/,"") { n=1-n } {print 1,a[n] $$0}' > $@
