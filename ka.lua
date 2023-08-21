#!/usr/bin/env lua
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
local obj,oo=l.obj,l.oo
local adds
local NUM, SYM = obj"NUM", obj"SYM"
--------------------------------------------------
function NUM.new(i,at,txt)
  i.at, i.txt = at or 0, txt or ""
  i.n, i.ok, i._all = 0, true, {} 
  i.heaven = i.txt:find"-$" and 0 or 1 end

function NUM.mid(i) return per(i:all(),.5)
function NUM.div(i) return (per(i:all(),.9) - per(i:all(),.1))/2.56
function NUM.d2h(i,row) return math.abs(i.heaven - i:norm(row.cells[i.at])) end

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
  return x=="?" and x or (x-a[1])/(a[#a] - a[1] + 1E-30)

function NUM.dist(i,x,y)
  if  x=="?" and y=="?" then return 1 end
  x,y = i:norm(x), i:norm(y)
  if x=="?" then x = y>.5 and 0 or 1 end
  if y=="?" then y = x>.5 and 0 or 1 end
  return math.abs(x - y) end
---------------------------------------------
function SYM.new(i,at,txt)
  i.at, i.txt = at or 0, txt or ""
  i.counts = {} end

function SYM.mid(i) return mode(i.counts) end
function SYM.div(i) return ent(i.counts) end

function SYM.add(i,x)
  if x~="?" then
    i.n = i.n + 1
    i.has[x] = 1 + (i.has[x] or 0)

function SYM.dist(i,x,y)
  return (x=="?" and y=="?" and 1) or (x==y and 0 or 1) end

function adds(x,t) 
  for _,v in pairs(t) do x:add(v) end; return x end

function ent(t,     n,e)
  n=0; for _,v in pairs(t) do if v>0 then n=n+v end end
  e=0; for _,v in pairs(t) do if v>0 then e=e-v/n*math.log(v/n,2) end end
  return e end

function mode(t,    x,n)
  x,n=nil,0; for k,v in pairs(t) do if v>n then x,n = k,v end end
  return x end
----------------------------------------------
function COLS.new(i,t)
   i.x, i.y, i.all, i.names = {}, {}, {}, t
   for at,txt in pairs(t) do
      col = push(i.all, txt:find"^[A-Z]" and NUM(at,txt) or SYM(at,txt))
      if not col.name:find"X$" then
        push(col.name:find"[+-]$" and i.y or i.x, col) end end end 

function COLS.add(i,row)
  for _,cols in pairs{i.x, i.y} do
    for _,col in pairs(cols) do
      col.add(row.cells[col.at]) end end end
----------------------------------------------
function TBL.new(i  ,src)
  if    type(src)=="string" then csv(src,function(row) i:add(row) end) 
  else for _,row in pairs(src or {}) do                i:add(row) end end end 

local egs={all={"the"}}

function egs.the() oo(the) end
---------------------------------------------
l.go(help,the,egs)
return {NUM=NUM}
