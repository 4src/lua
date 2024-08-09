#!/usr/bin/env lua
local l=require"lib"
local data=require"data"
local the,help=l.settings[[

pre.lua pre-comptuers
(c) 2024 Tim Menzies <timm@ieee.org> BSD-2

USAGE:
  lua pre.lua [-h] [[-bcst] ARG]

OPTIONS:
  -b bins   int    max number of bins  = 16
  -c cohen  float  cohen small effect  = 0.35   
  -h        show   help                = false
  -s seed   int    random number seed  = 1234567891
  -t train  file   training set        = ../../data/auto93.csv]]

local NUM,SYM,DATA,COLS = data.NUM, data.SYM, data.DATA, data.COLS
local new,o,oo = l.new, l.o, l.oo

local function _rows2stats(rows,get,    u,v,n)
  u,v = {},{}
  for i,row in pairs(rows) do l.push(get(row) == "?" and u or v, row) end
  table.sort(v, function(row1,row2) return get(row1) < get(row2) end)
  n = #v // 10
  return {u=u, v=v, lo=get(v[1]), hi=get(v[#v]), 
          mid=get(v[5*n]), sd=(get(v[9*n])-get(v[n]))/2.56} end
 
function DATA.bins(i)
  for _,col in pairs(i.cols.x) do col:bins(i.rows) end end

function SYM.bins(i,rows)
  return end

function NUM.bins(i,rows)
  local cuts,cut,get,put,s
  get = function(row) return row.cells[i.at] end
  put = function(row,x) row.cooked[i.at]=x end
  cuts, s = {}, _rows2stats(rows,get)
  cut = s.lo
  cuts[cut] = 0
  for j,row in pairs(s.v) do
    if j < #s.v - #s.v/the.bins and cuts[cut] >= #s.v/the.bins then 
      if get(s.v[j+1]) - get(row) > (s.hi - s.lo)/100 then
        if get(row) - cut >= s.sd*the.cohen then
          cut = get(row)
          cuts[cut] = 0  end end end 
    cuts[cut] = cuts[cut] + 1 
    put(row,cut) end 
  return cuts end
              --      class col    val                 
local function put(t,x,    y,     z,    a,b)
  a = t[x]; if a==nil then a={}; t[x] = a end
  b = a[y]; if b==nil then b={}; a[y] = b end
  b[z] = (b[z] or 0) + 1 end

-- -----------------------------------------------------------------------------
local go={}

go.b    = function(x) the.bins= x end
go.c    = function(x) the.cohen= x end
go.h    = function(x) print(help) end
go.s    = function(x) the.seed= x; l.Seed=x; end
go.t    = function(x) the.train= x end

go.the  = function(_) oo(the) end
go.csv  = function(_) csv(the.train, l.oo) end
go.data = function(_) l.map(DATA:new():read(the.train).rows, oo) end

go.rand = function(_)
  for i=1,10 do print(l.rint(100)) end end

go.demo = function(_,     data) 
  DATA:new():read(the.train):bins() end

 -- ----------------------------------------------------------------------------
for i,s in pairs(arg) do
  local f = s:sub(2) 
  if go[f] then go[f](l.coerce(arg[i+1] or "")) end end

l.rogues()
