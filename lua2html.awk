BEGIN                         { STOP="" }
NR < 3                        { next } 
                              { gsub(/\f/,"") }
comment($0) && !comment(last) { printf STOP }
!comment($0) && comment(last) { print "\n```lua"; STOP="```\n\n" }
END                           { if(!comment(last)) print STOP }
                              { last = $0;
                                sub(/^-- ?/,"")
                                print $0
                              }

function comment(s) { return s ~ /^-- ?/ }


# NR<= 2 { next}
# sub(/--\[\[ ?/,"") { com=1  }
# sub(/]]--/,"")     { com=0  }
# 	                 { b4 = line(b4,$0) }                  
# END                { line(b4) }                           
#
# function code(s) { return s ~ /^    .*/ }     
#
# function line(b4,now) {                      
#   if (com) {
#     print b4
#   } else {
#     print b4
#     if (code(b4) && !code(now))  print "```\n"    
#     if (!code(b4) && code(now))  print "\n```lua"  
#     }                                                
#   return now } 
