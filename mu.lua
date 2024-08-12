#!/usr/bin/env lua
-- vim : set ts=2 sw=2 sts=2 et : 
local help=[[
mu.lua: a little data goes a long way
(c) 2024 Tim Menzies, <timm@ieee.org>, BSD-2

USAGE:
  lua litl.lua [-h] [-[bBcst] ARG] 

OPTIONS:
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
  return new(SYM, {n=0, at=at, txt=txt, ,has={}} end

function SYM:add(x) 
  self.n = self.n + 1
  self.seen[x] = (self.seen[x] or 0) + 1 end

function SYM:mid(       most,out) 
  most=-1
  for k,n in pairs(self.has) do if n> most then most,out = n,k end
  return out end

function SYM:div(      e)
  e=0; for _,n in pairs(self.seen) do e=e- n/self.n * math.log(n/self.n,2) end
  return e end

function score(t, goal, Y, N)
  local y,n
  for k,v in pairs(t) do
    if k == goal then y = y + v else n = n + v end end
  y = y/(Y+ 1E-32)
  n = n/(N+ 1E-32)
  return y^2/(y+n) end 

function best(t,...)
  local tmp,score,most,out
  most = - 1
  for k,_ in pairs(t) do
    tmp = score(k,...)
    if tmp > most then most,out=tmp,k end end
  return out,most end

function cdf(x,mu,sd,     z,fun)
  fun = function(z) return 1 - 0.5*math.exp(1)^(-0.717*z - 0.416*z*z) end
  z = (x - mu)/sd
  return z >= 0 and fun(z) or 1 - fun(-z) end
-- ----------------------------------------------------------------------------
function NUM:new(at,txt)
  return new(NUM, {n=0, at=at, txt=txt, lo=1E32, hi=-1E32, mu=0,m2=0,sd=0,
                   goal=tostring(txt):find"-$" and 0 or 1}) end

function NUM:add(x,     d)
  self.n  = self.n + 1
  self.lo = math.min(x,self.lo)
  self.hi = math.max(x,self.hi)
  d       = x - self.mu
  self.mu = self.mu + d/i.n
  self.m2 = self.m2 + d*(x-self.mu)
  self.sd = self.n < 2 and 0 or (self.m2/(self.n - 1))^0.5 end 

-- negaction flip is wrong
function NUM.overlap(i,j)
  if i.mu > j.mu then i.j = j,i end
  a = 1/(2*i.sd^2)        - 1/(2*i.sd^2)
  b = j.mu/(i.sd^2)       - i.mu/(i.sd^2)
  c = i.mu^2 /(2*i.sd^2) - j.mu^2 / (2*i.sd^2) - math.log(i.sd/i.sd)
  x1= (-b - (b^2 - 4*a*c)^.5)/(2*a)
  x2= (-b + (b^2 - 4*a*c)^.5)/(2*a)
  cdf1=cdf(x1,i.mu,i.sd)
  cdf2=cdf(x2,i.mu,i.sd)
  return cdf2 - cdf1, x1,x2 end

function NUM:norm(x)
  return x=="?" and x or (x-self.lo)/ (self.hi - self.lo + 1E-32) end

function NUM:mid() return self.mu end
function NUM:div() return self.sd end

-- ----------------------------------------------------------------------------
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
