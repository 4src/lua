#!/usr/bin/env lua
--  __                __                   ___                        
-- /\ \              /\ \                 /\_ \                       
-- \ \ \/'\      __  \ \ \___             \//\ \    __  __     __     
--  \ \ , <    /'__`\ \ \  _ `\             \ \ \  /\ \/\ \  /'__`\   
--   \ \ \\`\ /\ \L\.\_\ \ \ \ \      __     \_\ \_\ \ \_\ \/\ \L\.\_ 
--    \ \_\ \_\ \__/.\_\\ \_\ \_\    /\_\    /\____\\ \____/\ \__/.\_\
--     \/_/\/_/\/__/\/_/ \/_/\/_/    \/_/    \/____/ \/___/  \/__/\/_/
                                                                   
local l=require"lib"
local the,help=l.settings[[

kah.lua: knowledge acquisition helper
(c) Tim Menzies <timm@ieee.org> 2023, BSD-2

USAGE:
  ./kah.lua [OPTIONS] -g [ACTIONS]

OPTIONS:
  -f --file file locaation = ../data/auto93.csv
  -F --Far  distance to other pole = .9
  -g --go  start up action = nothing
  -h --help do help = false
  -H --Halves how many to search = 256
  -m --min  min size = .5
  -p --p    distance coeffecient = 2
  -s --seed random seed = 1234567891
  -S --Some how many nums to keep = 1024

ACTIONS:
  the     show settings
  some    does SOME sample across whole space?
  many    can we sample n numbers?
  norm    can we generate random numbers?
  num     can we sample numbers?
  sym     can we sample symbols?
  cols     can we make column headers?
  tbl     can we load rows into cols and rows?
  dist    can we computer distances?
  far     can we find far values?
  tree    can we recursively bi-cluster?]]

local abs, cos,log, pi,sqrt = math.abs, math.cos, math.log, math.pi, math.sqrt
local obj,oo,push = l.obj, l.oo, l.push
local stats,tree = {},{}
local NUM,SYM,ROW,COLS,TBL = obj"NUM",obj"SYM",obj"ROW",obj"COLS",obj"TBL"
local SOME=obj"SOME"
--------------------------------------------------
--  _ _ ._ _  _
-- _>(_)| | |(/_
function SOME.init(i) i._all, i.ok, i.n = {}, true, 0 end

function SOME.add(i,x)
  i.n = i.n + 1
  if     #i._all  < the.Some     then i.ok=false; i._all[#i._all + 1] = x
  elseif l.rand() < the.Some/i.n then i.ok=false; i._all[l.rint(1,#i._all)] = x end end

function SOME.all(i)
  if not i.ok then table.sort(i._all); i.ok=true end
  return i._all end
--------------------------------------------------
--  ._        ._ _
--  | |  |_|  | | |

function NUM.init(i,  at,txt)
  i.n,i.has,i.at,i.txt = 0,SOME(),at or 0,txt or ""
  i.heaven = i.txt:find"-$" and 0 or 1 end

function NUM.all(i)     return i.has:all() end
function NUM.d2h(i,row) return abs(i.heaven - i:norm(row.cells[i.at])) end
function NUM.div(i)     return stats.sd(i.has:all()) end
function NUM.mid(i)     return stats.median(i.has:all()) end

function NUM.add(i,x)
  if x~="?" then
    i.n = i.n + 1; i.has:add(x) end end

function NUM.norm(i,x,    a)
  a = i.has:all()
  return x=="?" and x or (x-a[1])/(a[#a] - a[1] + 1E-30) end
---------------------------------------------
--   _      ._ _
--  _>  \/  | | |
--      /

function SYM.init(i,  at,txt)
  i.n,i.has,i.at,i.txt = 0,{},at or 0,txt or "" end

function SYM.mid(i) return stats.mode(i.has) end
function SYM.div(i) return stats.ent(i.has) end

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

function COLS.init(i,t,    col)
   i.x, i.y, i.all, i.names = {}, {}, {}, t
   for at,txt in pairs(t) do
      col = push(i.all, (txt:find"^[A-Z]" and NUM or SYM)(at,txt))
      if not col.txt:find"X$" then
        push(col.txt:find"[+-]$" and i.y or i.x, col) end end end

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
  if type(src)=="string" then
    l.csv(src,function(t) i:add(ROW(t)) end)
  else
    for _,row in pairs(src or {}) do
      print(2)
      i:add(row) end end end

function TBL.add(i, row)
  if i.cols then
    push(i.rows, i.cols:add(row))
  else
    i.cols = COLS(row.cells) end end

function TBL.clone(i, rows)
  return stats.adds(TBL{i.cols.names},rows or {}) end

function TBL.summary(i, cols,want,decs,     aux,out)
  cols = cols or i.cols.y
  aux = function(_,col,     x)
          x = want=="div" and col:div() or col:mid()
          return l.ooo(x, decs or 2),col.txt end
  out= l.kap(cols, aux)
  out["N"] = cols[1].n
  return out end
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
  d=0; for _,c in pairs(i.cols.x) do  d=d + c:dist(r1.cells[c.at],r2.cells[c.at])^the.p end
  return (d/#i.cols.x)^(1/the.p) end 

function TBL.far(i,rows,r1,     fun)
  fun = function(r2) return i:dist(r1,r2) end
  return l.keysort(rows,fun)[the.Far*#rows//1] end

function TBL.halves(i,rows,  sort,    lefts,rights,some,X,a,b,C)
  lefts,rights = {},{}
  some = #rows > the.Halves and l.many(rows, the.Halves) or rows
  a    = i.far(some, l.any(some))
  b    = i.far(some, a)
  C    = i:dist(a,b)
  if sort and i.d2h(b) < i.d2h(a) then a,b = b,a end
  X = function(r) return (i:dist(r,a)^2 + C^2 -i:dist(r,b)^2)/(2*C) end
  for n,r in pairs(l.keysort(rows,X)) do push(n <= #rows / 2 and lefts or rights, r) end
  return a,b,lefts,rights end
----------------------------------------------
-- _|_.__  _
--  |_|(/_(/_

function tree.grow(tbl1)
  function grow(tbl2,stop)
    local here,_,lefts,rights
    here ={node=tbl2}
    if #(tbl2.rows) > 2*stop then
      _,_,lefts,rights = tbl1:halves(tbl2.rows)
      here.lefts  = grow(tbl1:clone(lefts),stop)
      here.rights = grow(tbl1:clone(rights),stop) end
    return here end
  return grow(tbl1, (#tbl1.rows)^the.min) end
----------------------------------------------
--   _  _|_   _.  _|_   _
--  _>   |_  (_|   |_  _>

function stats.adds(x,t) for _,v in pairs(t) do x:add(v) end; return x end
function stats.median(a)  return l.per(a,.5) end
function stats.sd(a)      return (l.per(a,.9) - l.per(a,.1))/2.56 end

function stats.cuts(t, ordered)
  local cut,bins,njump,small,n
  t= l.map(t,function(x) if x ~= "?" then return x end end)
  if not ordered then t = l.sorted(t) end
  cut,bins,njump = t[0], {}, #t/(the.bins - 1) // 1
  bins[cut], n, small = njump,njump, stats.sd(t) * the.cohen
  while n <= #t do
    if n < #t - njump and t[n] ~= t[n+1] and t[n] - cut >= small then
       cut = t[n]
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

function stats.normal(mu,sd)
   return (mu or 0) +(sd or 1)*sqrt(-2*log(l.rand())) * cos(2*pi*l.rand()) end
---------------------------------------------
--   _    _    _
--  (/_  (_|  _>
--        _|

local egs ={all={}}

help:gsub("\n[%s]+([%S]+)",function(x) push(egs.all,x) end)

function egs.the() oo(the) end

function egs.some(    s)
  s=SOME()
  the.Some=64
  for i=1,100 do s:add(i//10) end
  l.oo(s:all())end

function egs.many(      t)
  t={}; for i=1,100 do t[i]=i end
  for _,k in pairs(l.many(t,10)) do print(k) end end

function egs.norm(   t)
  t={}
  for i = 1,1000 do t[i] = stats.normal(10,1) end
  table.sort(t)
  for i = 1,1000,50 do print(i,t[i]) end end

function egs.num(    n,mu,sd)
  n=NUM()
  for _ = 1,1000 do n:add(stats.normal(10,1)) end
  mu,sd = n:mid(), n:div()
  return 9.99 <mu and mu<10.01 and 0.99< sd and sd < 1.01 end

function egs.sym(    s)
  s=SYM()
  for _,c in pairs{'a', 'a','a','a','b','b','c'} do s:add(c) end
  return 'a' == s:mid() and 1.37 < s:div() and s:div() < 1.38  end

function egs.cols()
  for _,c in pairs(COLS({"Age","Weight","nationality","seX","Marriages-"}).all) do
    oo(c) end end

function egs.tbl()
  oo(TBL(the.file):summary()) end

function egs.dist(     tbl)
  tbl=  TBL(the.file)
  for i = 1,#tbl.rows,20 do
    print(i, tbl:dist(tbl.rows[1], tbl.rows[i])) end end

function egs.far(     tbl,far,rows,r1)
  tbl=  TBL(the.file)
  rows= tbl.rows
  for i = 1,#tbl.rows,20 do
     r1 = rows[i]
     far = tbl:far(rows, r1)
     print(tbl:dist(far, r1)) end end

function egs.tree()
  local tbl,tr
  tbl =  TBL(the.file)
  tr = tree.grow(tbl)
  print(tr)
  end
---------------------------------------------
l.go(help,the,egs)
return {NUM=NUM, SYM=SYM, TBL=TBL, stats=stats}
