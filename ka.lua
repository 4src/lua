#!/usr/bin/env lua
--  __                            ___                        
-- /\ \                          /\_ \                       
-- \ \ \/'\      __              \//\ \    __  __     __     
--  \ \ , <    /'__`\              \ \ \  /\ \/\ \  /'__`\   
--   \ \ \\`\ /\ \L\.\_      __     \_\ \_\ \ \_\ \/\ \L\.\_ 
--    \ \_\ \_\ \__/.\_\    /\_\    /\____\\ \____/\ \__/.\_\
--     \/_/\/_/\/__/\/_/    \/_/    \/____/ \/___/  \/__/\/_/
                                                          
local l=require"lib"
local the,help=l.settings[[

asd asda

USAGE:
  lua ka.lua

OPTIONS:
  -g --go  start up action = nothing
  -h --help do help = false
  -s --seed random seed = 1234567891
]]
local abs, sqrt = math.abs, math.sqrt
local obj,oo,push = l.obj, l.oo, l.push
local stats = {}
local NUM, SYM, COLS, TBL = obj"NUM", obj"SYM", obj"COLS", obj"TBL"
--------------------------------------------------
--  ._        ._ _  
--  | |  |_|  | | | 

function NUM.init(i,at,txt)
  i.at, i.txt = at or 0, txt or ""
  i.n, i.ok, i._all = 0, true, {} 
  i.heaven = i.txt:find"-$" and 0 or 1 end

function NUM.d2h(i,row) return abs(i.heaven - i:norm(row.cells[i.at])) end
function NUM.div(i) return stats.sd(i:all()) end
function NUM.mid(i) return stats.median(i.all()) end

function NUM.add(i,x)
  if x~="?" then
    i.n = i.n + 1
    i.ok = false
    push(i._all,x) end end

function NUM.all(i)
  if not i.ok then table.sort(i._all) end
  i.ok=true
  return i._all end

function NUM.norm(i,x,    a)
  a = i.has()
  return x=="?" and x or (x-a[1])/(a[#a] - a[1] + 1E-30) end
---------------------------------------------
--   _      ._ _  
--  _>  \/  | | | 
--      /         

function SYM.init(i,at,txt)
  i.at, i.txt = at or 0, txt or ""
  i.counts = {} end

function SYM.mid(i) return stats.mode(i.counts) end
function SYM.div(i) return stats.ent(i.counts) end

function SYM.add(i,x)
  if x~="?" then
    i.n = i.n + 1
    i.has[x] = 1 + (i.has[x] or 0) end end
----------------------------------------------
--  ._   _        
--  |   (_)  \/\/ 
               
function ROW.init(i,t) i.cells=t end
----------------------------------------------
--   _   _   |   _ 
--  (_  (_)  |  _> 

function COLS.init(i,t)
   i.x, i.y, i.all, i.names = {}, {}, {}, t
   for at,txt in pairs(t) do
      col = push(i.all, (txt:find"^[A-Z]" and NUM or SYM)(at,txt))
      if not col.name:find"X$" then
        push(col.name:find"[+-]$" and i.y or i.x, col) end end end 

function COLS.add(i,row)
  for _,cols in pairs{i.x, i.y} do
    for _,col in pairs(cols) do
      col:add(row.cells[col.at]) end end
  return row end
----------------------------------------------
--  _|_  |_   | 
--   |_  |_)  | 

function TBL.init(i  ,src)
  i.rows, i.cols = {},nil
  if   type(src)=="string" then csv(src,function(t) i:add(ROW(t)) end) 
  else for _,row in pairs(src or {}) do             i:add(row) end end end 

function TBL.add(i, row)
  if i.cols then push(i.rows, i.cols:add(row)) else i.cols = COLS(rows.cells) end end 

function TBL.summary(i, cols,want,decs,     tmp)
  tmp= kap(cols or i.cols.y, function(col,    val)
              val=  l.ooo(want=="div" and col.div() or col.mid(), decs or 2) 
              return val,col.name end) 
  tmp["N"] = cols[1].n 
  return tmp end
----------------------------------------------
--   _|  o   _  _|_ 
--  (_|  |  _>   |_ 

function SYM.dist(i,x,y)
  return (x=="?" and y=="?" and 1) or (x==y and 0 or 1) end

function NUM.dist(i,x,y)
  if  x=="?" and y=="?" then return 1 end
  x,y = i:norm(x), i:norm(y)
  if x=="?" then x = y>.5 and 0 or 1 end
  if y=="?" then y = x>.5 and 0 or 1 end
  return abs(x - y) end

function TBL.dist(i,r1,r2,     d)
  d=0; for _,c in pairs(i.cols.x) do d=d + c:dist(r1.cells[c.at],r2.cells[c.at])^the.p end
  return (d/#i.cols.x)^(1/the.p) end

function TBL.far(i,rows,r1)
  return l.sortid(rows, function(a) return i:dist(r1,r2) end)[the.Far*#rows//1] end

function TBL.halve(i,rows,  sort)
  local lefts,rights,some,X,a,b,C = {},{}
  some = #rows > the.Halves and many(rows, the.Halves) or rows
  a    = i.far(some, any(some))
  b    = i.far(some, a)
  C    = i:dist(a,b)
  if sort and i.d2h(b) < i.d2h(a) then a,b = b,a end
  X = function(r) return (i:dist(r,a)^2 + C^2 -i:dist(r,b)^2)/(2*C) end
  for n,r in pairs(l.sortid(rows,X)) do push(n <= #rows / 2 and lefts or rights, r) end
  return a,b,lefts,rights end
----------------------------------------------
--   _  _|_   _.  _|_   _ 
--  _>   |_  (_|   |_  _> 

function stats.adds(x,t) for _,v in pairs(t) do x:add(v) end; return x end 
function stats.median(a)  return per(a,.5) end
function stats.sd(a)      return (per(a,.9) - per(a,.1))/2.56 end

function stats.cuts(t, ordered)
  t= map(t,function(x) if x ~= "?" then return x end) 
  if not ordered then t = sorted(t) end
  local cut,bins,njump,small,n = t[0], {}, #t/(the.bins - 1) // 1
  bins[cut], n, small          = njump,njump, stats.sd(t) * the.cohen
  while n <= #t do
    if n < #t - njump and t[n] ~= x[n+1] and x[n] - cut >= small then
       cut = x[n]
       bins[cut] = njump
       n = n + njump
    else
       bins[cut] = bins[cut] + 1
       n = n + 1 end end
  return bins end

function stats.ent(t,     n,e)
  n=0; for _,v in pairs(t) do if v>0 then n=n+v end end
  e=0; for _,v in pairs(t) do if v>0 then e=e-v/n*math.log(v/n,2) end end
  return e end

function stats.mode(t,    x,n)
  x,n=nil,0; for k,v in pairs(t) do if v>n then x,n = k,v end end
  return x end
---------------------------------------------
--   _    _    _ 
--  (/_  (_|  _> 
--        _|     

local egs={all={"the"}}

function egs.the() oo(the) end
---------------------------------------------
l.go(help,the,egs)
return {NUM=NUM, SYM=SYM, TBL=TBL, stats=stats}
