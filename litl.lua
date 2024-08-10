#!/usr/bin/env lua
-- vim : set ts=2 sw=2 sts=2 et : 
local the,help={},[[
litl.lua: a little data goes a long way
(c) 2024 Tim Menzies, <timm@ieee.org>, BSD-2

USAGE:
  lua litl.lua [-h] [-[bBcst] ARG] 

OPTIONS:
  -b bins    int     max number of bins =  10
  -B Best    float   threshold for best =  .5
  -c cohen   float   cohen small effect =  .35
  -h                 show help 
  -s seed    int     random number seed =  1234567891
  -S Samples int     random number seed =  512
  -t train   file    csv data file      =  ../../timm/moot/optimize/misc/auto93.csv]]

local DATA,BIN,COLS,ROW,SYM,NUM,go = {},{},{},{},{},{},{}
local cells, coerce, csv, fmt, new, o, oo, push, sort
-- ----------------------------------------------------------------------------
-- Objects
function new(klass,obj) klass.__index=klass; return setmetatable(obj,klass) end

-- Lists
function push(t,x) t[1+#t] = x; return x end

function sort(t,fun) table.sort(t,fun); return t end

-- Thing to string
fmt = string.format

function oo(x) print(o(x)) end

function o(x,    u)
  if type(x) == "number" then return fmt("%g",x) end
  if type(x) ~= "table"  then return tostring(x) end
  u={}
  if   #x > 0 
  then for k,v in pairs(x) do u[1+#u] = o(v) end 
  else for k,v in pairs(x) do 
         if o(k):sub(1,1) ~= "_" then u[1+#u] = fmt("%s=%s", k, o(v)) end end
       table.sort(u) end
  return "{" .. table.concat(u,", ") .. "}" end 

-- String to thing(s)
function coerce(s,    fun)
  function fun(s) return s=="true" and true or (s ~= "false" and s) or false end
  return math.tointeger(s) or tonumber(s) or fun(s:match"^%s*(.-)%s*$") end

function csv(sFilename,fun,      src,s,cells)
  function cells(s,    t) 
    t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t]=coerce(s1) end; return t end
  src = io.input(sFilename)
  while true do
    s = io.read()
    if s then fun(cells(s)) else return io.close(src) end end end

function settings(t,s)
  s:gsub("\n[%s]+[-][%S][%s]+([%S]+)[^\n]+=[%s]+([%S]+)",
         function(k,v) t[k]=coerce(v) end) end

settings(the, help)
-- ----------------------------------------------------------------------------
function SYM:new(at,txt)
  return new(SYM,{n=0,at=at,txt=txt,has={},most=0,mode=nil}) end

function SYM:add(x) 
  if x~="?" then 
    self.n = self.n + 1
    self.has[x] = (self.has[x] or 0) + 1
    if self.has[x] > self.most then
      self.most, self.mode = self.has[x], x end end 
  return x end

function SYM:mid() return self.mode end
function SYM:div(      e)
  e=0; for _,n in pairs(self.has) do e=e- n/self.n * math.log(n/self.n,2) end
  return e end
-- ----------------------------------------------------------------------------
function NUM:new(at,txt)
  return new(NUM, {n=0, at=at, txt=txt, lo=1E32, hi=-1E32, 
                   goal=tostring(txt):find"-$" and 0 or 1,
                   _has={}, ok=false}) end

function NUM:add(x,     pos)
  if x ~="?" then 
    self.n  = self.n + 1
    self.lo = math.min(x,self.lo)
    self.hi = math.max(x,self.hi)
    if #self._has < the.Samples then pos = 1 + (#self._has) 
    elseif math.random() < the.Samples/self.n then pos=math.random(#self._has) end
    if pos then 
      self.ok = false 
      self._has[pos] = v end end 
  return x end

function NUM:norm(x)
  if  x=="?" then return x end
  return (x-self.lo)/ (self.hi - self.lo + 1E-32) end

function NUM:has()
  if not self.ok then table.sort(self._has); self.ok=true end
  return self._has end

function NUM:mid() return self:per(.5) end
function NUM:div() return (self:per(.9) - self:per(.1)) / 2.56 end

function NUM:per(p,    a) 
  a=self:has()
  return a[math.min(#a, math.max(1, (p*#a) // 1))] end

function COLS:new(names)
  self = new(COLS,{names=names, x={}, y={}, all={}})
  for c,s in pairs(self.names) do
    col = push(self.all, (s:find"^[A-Z]" and NUM or SYM):new(c,s))
    if not s:find"X$" then
      push(s:find"[+-]$" and self.y or self.x, col) end end
  return self end

function COLS:add(row)
  for _,cols in pairs{self.x,self.y} do
    for _,col in pairs(cols) do
      col:add(row[col.at]) end end 
  return row end
   
function COLS:chebyshev(row,    d)
  for _,col in pairs(self.y) do
    d = math.max(d or 0, math.abs(col:norm(row[col.at]) - col.goal)) end 
  return d end 
-- ----------------------------------------------------------------------------
function DATA:new() return new(DATA, {cols=nil, rows={}}) end

function DATA:load(lst) 
  for _,row in pairs(lst or {}) do self:add(row) end 
  return self end

function DATA:read(file) 
  csv(file, function(row) self:add(row) end) 
  return self end

function DATA:add(row)
  if   self.cols
  then push(self.rows, self.cols:add(row)) 
  else self.cols = COLS:new(row) end end

function DATA:sort(f,n)
  f = function(row) return self.cols:chebyshev(row) end
  self.rows = sort(self.rows, function(a,b) return f(a) < f(b) end) 
  n = (#self.rows)^the.Best // 1 
  return self, f( self.rows[n] ) end 

function DATA:allBins(      x,border)
  f= function(row) return self.cols:chebyshev(row) end
  _,border = self:sort()
	for _,n in pairs{0.1,0.2,0.3,0.4,0.5,0.7,0.9} do
	  print(n, f( self.rows[ (n*#self.rows)//1   ])) end
	
  for c,_ in pairs(self.cols.x) do
    x =  self:bins(self.rows, function(row) return row[c] end,
		               function(row) return self.cols:chebyshev(row) < border end)
		print("")
		for _,y in pairs(x) do print(c, y.lo,y.n,  o(y.seen)) end
									 end end

function DATA:bins(rows,xfun,yfun,     my,bins)
  my, rows = self:my(self:sortedRows(rows,xfun), xfun, yfun)
  bins = { BIN:new(xfun(rows[1])) }
  for r,row in pairs(rows) do
    if r >= my.start 
    then self:theCurrentBin(my,r,xfun(row),rows,bins,xfun)
             :add( yfun(row), my.seen) end end
  return bins end

function DATA:theCurrentBin(my,r,x,rows,bins,xfun)
  if r < #rows - my.gap then
    if x ~= xfun( rows[r+1] )  then
      if bins[#bins].n >= my.gap then  
        if x - bins[#bins].lo >= my.sd*the.cohen then 
          push(bins, BIN:new(x,bins[#bins])) end end end end
  return bins[#bins] end

function DATA:sortedRows(rows,xfun,       q)
  q = function(row) return xfun(row)=="?" and -1E32 or xfun(row)  end
  return sort(rows, function(row1,row2) return q(row1) < q(row2) end) end

function DATA:my(rows,xfun,yfun,      seen,x,y,n,start) 
  seen={}
  for r,row in pairs(rows) do
    x,y = xfun(row), yfun(row)
    if x ~= "?" then 
      start = start or r
      seen[y] = 1 + (seen[y] or 0) end end 
	print("start",start)
  n = #rows - start 
  ninety = xfun(rows[(start+ .9*n)//1]) 
	ten    = xfun(rows[(start+ .1*n)//1])   
  return {start= start, 
          seen = seen,
          gap  = (n / the.bins) //1,
          sd   = (ninety - ten)/2.56
         }, rows end  
-- ----------------------------------------------------------------------------
function BIN:new(x,b4)
  self = new(BIN,{n=0, lo=x, seen={}})
  if b4 then
    self.last = b4
    b4.next = self end
  return self end

function BIN:add(y,ys)
  self.seen[y] = (self.seen[y] or 0) + 1/ys[y]
  self.n = self.n + 1 end
-- ----------------------------------------------------------------------------
go.h   = function(_) print("\n" .. help) end
go.c   = function(x) the.cohen = x end
go.b   = function(x) the.bins  = x end
go.B   = function(x) the.Best  = x end
go.s   = function(x) the.seed  = x; math.randomseed(x) end
go.t   = function(x) the.train = x end
go.the = function(_) oo(the) end
go.csv = function(_) csv(the.train, oo) end
go.sort= function(_) 
           d = DATA:new():read(the.train):sort()
           oo{lo=d.cols.lo}; oo{ hi=d.cols.hi} end
go.data= function(_) 
           d = DATA:new():read(the.train)
           for k,v in pairs(d.cols.lo) do
             print(k,d.cols.names[k],v, d.cols.hi[k]) end end
go.bins= function(_) 
           d = DATA:new():read(the.train)
           d:allBins() end

for j,s in pairs(arg) do
  math.randomseed(the.seed)
  if go[s:sub(2)] then go[s:sub(2)](coerce(arg[j+1] or "")) end end 
