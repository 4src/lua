#!/usr/bin/env lua
-- vim : set ts=2 sw=2 sts=2 et : 
-- --[ todo
hooking up now toe enxt and net.loast back tos elf if non nil next fshoul dbe a connect method

predict should be a general method since sym will need it too. as doe sthe find max rotine

o bins should return first cut and best cut

 erge bns if the prediction of the merge same asnthe prediction of the part
   o
   get rid of the next/last pointers. merge makes a new list. simpler
--]]
local help=[[
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

local cells, is, csv, fmt, new, o, oo, push, sort
local the,go = {},{}
local DATA,BIN,COLS,ROW,SYM,NUM = {},{},{},{},{},{}
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
function is(s,     fun)
  function fun(s) return s==nil and nil or 
                         s=="true" and true or 
                         s ~= "false" and s
                         or false end
  return math.tointeger(s) or tonumber(s) or fun(s:match"^%s*(.-)%s*$") end

function csv(sFilename,fun,      src,s,cells)
  function cells(s,    t) 
    t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t]=is(s1) end; return t end
  src = io.input(sFilename)
  while true do
    s = io.read()
    if s then fun(cells(s)) else return io.close(src) end end end

function settings(t,s)
  s:gsub("\n[%s]+[-][%S][%s]+([%S]+)[^\n]+=[%s]+([%S]+)",function(k,v) t[k]=is(v) end) end

settings(the, help)
-- ----------------------------------------------------------------------------
function SYM:new(at,txt)
  return new(SYM, {n=0, at=at, txt=txt, bins={},
                   seen={}, most=0, mode=nil}) end

function SYM:add(x) 
  if x~="?" then 
    self.n = self.n + 1
    self.seen[x] = (self.seen[x] or 0) + 1
    if self.seen[x] > self.most then
      self.most, self.mode = self.seen[x], x end end 
  return x end

function SYM:mid() return self.mode end
function SYM:div(      e)
  e=0; for _,n in pairs(self.seen) do e=e- n/self.n * math.log(n/self.n,2) end
  return e end
-- ----------------------------------------------------------------------------
function NUM:new(at,txt)
  return new(NUM, {n=0, at=at, txt=txt, bins={},
                   lo=1E32, hi=-1E32, 
                   goal=tostring(txt):find"-$" and 0 or 1,
                   _seen={}, ok=false}) end

function NUM:add(x,     pos)
  if x ~="?" then 
    self.n  = self.n + 1
    self.lo = math.min(x,self.lo)
    self.hi = math.max(x,self.hi)
    if #self._seen < the.Samples then pos = 1 + (#self._seen) 
    elseif math.random() < the.Samples/self.n then pos=math.random(#self._seen) end
    if pos then 
      self.ok = false 
      self._seen[pos] = v end end 
  return x end

function NUM:norm(x)
  if  x=="?" then return x end
  return (x-self.lo)/ (self.hi - self.lo + 1E-32) end

function NUM:has()
  if not self.ok then table.sort(self._seen); self.ok=true end
  return self._seen end

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

function NUM:contrast(klasses,     x,b)
  for i=1,the.bins do 
    self.bins[i]=BIN:new(self,false, bins[i-1]) end
  for klass,rows in pairs(klass) do
    for _,row in pairs(rows) do
      x = row[self.at]
      if x ~= "?" then
        b = (.5 + (x - self.lo) / s(elf.hi - self.lo)) // 1
        self.bins[b]:add(x, klass, 1/#rows)  end end end
  return bins[1]:merged(i:div()*the.cohen, i.n/the.bins) end
  
-- ----------------------------------------------------------------------------
function BIN:new(col,b4)
  self = new(BIN,{n=0, at=col.at, txt=col.txt, lo=1E32, seen={},
                  symp=getmetatable(col)==SYM })
  if b4 then
    self.last = b4
    b4.next = self end
  return self end

function BIN:add(x,y,n)
  self.lo      = math.min(x, self.lo)
  self.seen[y] = (self.seen[y] or 0) + n 
  self.n       = self.n + 1 end

function BIN:predict(    out,most,n,tmp)
  most = -1
  for k1,y in pairs(self.seen) do
    n   = 0
    for k2,n2 in pairs(self.seen) do if k2 ~= k1 then n = n + n2 end
    tmp = y^2 / (y+n)
    if tmp > most then most,out = tmp,k1 end end
  return out,most end

function BIN:merge(smallEffect, frequent)
  if self.next then
    if self.n < frequent then return true end
    if self.next.lo - self.lo < smallEffect then return true end
    if self:predict() == self.next:predict() then return true end end end

function BIN:merged(...)
  if self:merge(...)
  then 
    self.n = self.n + self.next.n
    for k,n in pairs(self.next.seen) do
      self.seen[k] = (self.seen[k] or 0) + n end
    self.next      = self.next.next
    if self.next then self.next.last = self end
    self:merged(...) 
  end
  return self end

function BIN:selects(row,      x)
  x = row[self.at]
  if x == "?"         then return true end
  if self.symp        then return x==self.lo end 
  if self.next == nil then return self.lo <= x end
  if self.last == nil then return x < self.next.lo end 
  return self.lo <= x < self.next.lo end

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
  if go[s:sub(2)] then go[s:sub(2)](is(arg[j+1] or "")) end end 
