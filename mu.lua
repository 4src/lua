#!/usr/bin/env lua
-- vim : set ts=2 sw=2 sts=2 et : 
local go,the,help={},{},[[
mu.lua: a little data goes a long way
(c) 2024 Tim Menzies, <timm@ieee.org>, BSD-2

USAGE:
  lua litl.lua [-h] [-[bBcst] ARG] 

OPTIONS:
  -B Best    float   best size           =  .5
  -c cohen   float   cohen small effect  =  .35
  -h                 show help 
  -s seed    int     random number seed  =  1234567891
  -S Samples int     random number seed  =  512
  -t train   file    csv data file       =  ../../timm/moot/optimize/misc/auto93.csv]]

-- --------------------------------------------------------------------------------------
-- String to thing(s)
local function coerce(s,     fun)
  function fun(s) return s==nil and nil or s=="true" and true or s ~= "false" and s end
  if type(s) ~= "string" then return s end
  return math.tointeger(s) or tonumber(s) or fun(s:match"^%s*(.-)%s*$") end

help:gsub("\n[%s]+[-][%S][%s]+([%S]+)[^\n]+=[%s]+([%S]+)", 
          function(k,v) the[k] = coerce(v) end)

local function csv(sFilename,fun,      src,s,cells)
  function cells(s,    t) 
    t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t]=coerce(s1) end; return t end
  src = io.input(sFilename)
  while true do
    s = io.read()
    if s then fun(cells(s)) else return io.close(src) end end end

-- Lists
local function push(t,x) t[1+#t] = x; return x end

local function shuffle(t,    j)
  for i = #t, 2, -1 do j = math.random(i); t[i], t[j] = t[j], t[i] end
  return t end

-- Mathis
function normal(mu,sd)
  while true do
    x1 = 2.0 * math.random() - 1
    x2 = 2.0 * math.random() - 1
    w  = x1*x1 + x2*x2
    if w < 1 then
      return mu + sd * x1 * ((-2*math.log(w))/w)^0.5 end end end

-- Thing to string
local fmt = string.format

local function o(x,    u)
  if type(x) == "number" then return fmt("%g",x) end
  if type(x) ~= "table"  then return tostring(x) end
  u={}
  if   #x > 0 
  then for k,v in pairs(x) do u[1+#u] = o(v) end
  else for k,v in pairs(x) do 
         if o(k):sub(1,1) ~= "_" then u[1+#u] = fmt("%s=%s", k, o(v)) end end
       table.sort(u) end
  return "{" .. table.concat(u,", ") .. "}" end 

local function oo(x) print(o(x)) end

-- Objects
local function new(klass,obj) 
  klass.__index=klass; klass.__tostring=o; return setmetatable(obj,klass) end

-- --------------------------------------------------------------------------------------
local DATA,BIN,COLS,ROW,SYM,NUM = {},{},{},{},{},{}

function SYM:new(at,txt) return new(SYM,{n=0,at=at,txt=txt,has={},most=0,mode=nil}) end

function SYM:add(x) 
  self.n = self.n + 1
  self.has[x] = (self.has[x] or 0) + 1 
  if self.has[x] > self.most then 
    self.most, self.mode = self.has[x], x end end

function SYM.contrast(i,j,      y,n,most,x)
  most = 0
  for k,v in pairs(t) do
    y = v/i.n
    n = (j.has[k] or 0)/j.n
    if y > n and y > most then most,x = y,k end end
  return {score=most, lo=x, hi=x} end

function SYM:div(      e)
  e=0; for _,n in pairs(self.has) do e=e- n/self.n * math.log(n/self.n,2) end
  return e end

function SYM:mid() return self.mode end

-- --------------------------------------------------------------------------------------
function NUM:new(at,txt)
  return new(NUM, {n=0, at=at, txt=txt, lo=1E32, hi=-1E32, mu=0, m2=0, sd=0,
                   goal=tostring(txt):find"-$" and 0 or 1}) end

function NUM:add(x,     d)
  self.n  = self.n + 1
  self.lo = math.min(x,self.lo)  
  self.hi = math.max(x,self.hi) 
  d       = x - self.mu
  self.mu = self.mu + d/self.n
  self.m2 = self.m2 + d*(x-self.mu)
  self.sd = self.n < 2 and 0 or (self.m2/(self.n - 1))^0.5 end   

function NUM:cdf(x,     z,fun)
  fun = function(z) return 1 - 0.5*math.exp(-0.717*z - 0.416*z*z) end
  z = (x - i.mu)/i.sd
  return z >=  0 and fun(z) or 1 - fun(-z) end

function NUM.contrast(i,j)
  a = 1/(2*i.sd^2)  - 1/(2*i.sd^2)  
  b = j.mu/(i.sd^2) - i.mu/(i.sd^2)
  c = i.mu^2 /(2*i.sd^2) - j.mu^2 / (2*i.sd^2) - math.log(i.sd/i.sd)  
  x1= (-b - (b^2 - 4*a*c)^.5)/(2*a)
  x2= (-b + (b^2 - 4*a*c)^.5)/(2*a)
  return {score= i:cdf(x2) - i:cdf(x1), lo=x1, hi=x2} end

function NUM:div() return self.sd end


function NUM:mid() return self.mu end

function NUM:norm(x)
  return x=="?" and x or (x-self.lo)/ (self.hi - self.lo + 1E-32) end

-- --------------------------------------------------------------------------------------
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

-- --------------------------------------------------------------------------------------
function DATA:new() return new(DATA, {cols=nil, rows={}}) end

function DATA:add(row)
  if   self.cols
  then push(self.rows, self.cols:add(row)) 
  else self.cols = COLS:new(row) end end

function DATA:clone(rows)
  return DATA:new():add(self.cols.names):load(rows or {}) end

function DATA:load(lst) 
  for _,row in pairs(lst or {}) do self:add(row) end 
  return self end

function DATA:read(file) 
  csv(file, function(row) self:add(row) end) 
  return self end

function DATA:sort(f,n)
  f = function(row) return self.cols:chebyshev(row) end
  table.sort(self.rows, function(a,b) return f(a) < f(b) end)
  n = (#self.rows)^the.Best // 1 
  return self, f( self.rows[n] ) end

-- -------------------------------------------------------------------------------------
go.h    = function(_) print("\n" .. help .. "\n") end
go.c    = function(x) the.cohen = coerce(x) end
go.b    = function(x) the.bins  = coerce(x) end
go.B    = function(x) the.Best  = coerce(x) end
go.s    = function(x) the.seed  = coerce(x); math.randomseed(the.seed) end
go.t    = function(x) the.train = x end
go.the  = function(_) oo(the) end
go.csv  = function(_) csv(the.train, oo) end

go.num  = function(_, n)
            n=NUM:new(); for i=1,100 do n:add(math.random()^.5) end 
            assert(0.71 < n:mid() and n:mid() < 0.72)
            assert(0.22 < n:div() and n:div() < 0.23) end

go.normal  =function(_, n)
              t={}; for i=1,1000 do x=normal(10,2) // 1; t[x]=(t[x] or 0) + 1 end
              for i = 4,16 do
                n = t[i] or 0
                print(i,n,("*"):rep(n//10)) end end

go.sym  = function(_, s)
            s=SYM:new(); for _,x in pairs{"a","a","a","a","b","b","c"} do s:add(x) end
            assert(1.37 <= s:div() and s:div() <= 1.38) end

go.data = function(_,d) 
            d = DATA:new():read(the.train)
            c=0; for _,row in pairs(d.rows) do c=c+#row end
            assert(c==3184 and #d.cols.x==4 and  #d.cols.y==3) end 

go.sort = function(_,   last,c) 
            d = DATA:new():read(the.train):sort()
            last=-1
            for i,row in pairs(d.rows) do
              c=d.cols:chebyshev(row)
              assert(c >= last)  
              last=c end end 

-- --------------------------------------------------------------------------------------
math.randomseed(the.seed)
if   pcall(debug.getlocal,4,1) 
then return {the=the, DATA=DATA, COLS=COLS, ROW=ROW, SYM=SYM, NUM=NUM}
else for j,s in pairs(arg) do
       if go[s:sub(2)] then go[s:sub(2)](arg[j+1]) end end end 
