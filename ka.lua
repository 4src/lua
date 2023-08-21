l=require"lib"
local oo=l.oo
local the,help=l.settings[[

asd asda

USAGE:
  lua ka.lua

OPTIONS:
  -h --help do help = false
  -s --seed random seed = 1234567891]]
--------------------------------------------------
local NUM, SYM = obj"NUM", obj"SYM"

function NUM.new(i,at,txt)
  i.at = at or 0
  i.txt = txt or ""
  i.n, i.ok, i.has = 0,true,{} end

function NEW.add(i,x)
  if x~="?" then
    i.n = i.n + 1
    i.ok = true
    i.has[1+#i.has] = x end

function NEW.dist(i,x,y)
  return (x=="?" and y=="?" and 1) or (x==y and 0 or 1) end
