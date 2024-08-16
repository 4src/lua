#!/usr/bin/env lua
-- <!-- vim : set ts=2 sw=2 sts=2 et : --> 

-- ## Settings
local the,help={},[[
mu.lua: a little data goes a long way
(c) 2024 Tim Menzies, <timm@ieee.org>, BSD-2

USAGE:
  lua mu.lua [-h] [-[bBcqst] ARG] 

OPTIONS:
  -z stop     max labels            = 20
  -a start    initial labels        = 4
  -b buffer   half the sort buffer  = 50
  -B Best     best size             = .5
	-f features max features          = 4
  -c cohen    cohen small effect    = .35
  -h          show help 
  -k k        nb class low freq     = 1
  -m m        nb attribute low freq = 2
  -q quiet    hide details          = false 
  -s seed     random number seed    = 1234567891
  -t train    csv data file         = ../../timm/moot/optimize/misc/auto93.csv]]

-- ## Lib
-- ### String to thing(s)
--
-- Simple coerce (assumes booleans, nil, ints, floats or strings)
local function trim(s)    return s:match"^%s*(.-)%s*$" end
local function _coerce(s) return s=="true" and true or s ~= "false" and s end
local function coerce(s)  return math.tointeger(s) or tonumber(s) or _coerce(trim(s)) end  

-- Parse settings from `help` into `the`.
help:gsub("\n[%s]+[-][%S][%s]+([%S]+)[^\n]+=[%s]+([%S]+)",  
          function(k,v) the[k] = coerce(v) end)

-- Read csv, coerce cells, call `fun` on each rows.
local function csv(sFilename,fun,      src,s,cells)
  function cells(s,    t) 
    t={}; for s1 in s:gmatch"([^,]+)" do t[1+#t] = coerce(s1) end; return t end  
  src = io.input(sFilename)
  while true do
    s = io.read()
    if s then fun(cells(s)) else return io.close(src) end end end

-- ### Lists
--
-- Push to list
local function push(t,x) t[1+#t] = x; return x end

local function map(t,fun,      u)
  u={}; for k,v in pairs(t) do u[1+#u] = fun(v) end; return u end

-- Rearrange, in place
local function shuffle(t,    j)
  for i = #t, 2, -1 do j = math.random(i); t[i], t[j] = t[j], t[i] end
  return t end

-- Sort a list, in-place
local function sort(t,fun) table.sort(t,fun); return t end

local function slice(t, go, stop, inc,       u)
  if go   and go   < 0 then go   = #t+go end
  if stop and stop < 0 then stop = #t+stop end
  go   = math.max(1,  (go   or 1)//1)
  stop = math.min(#t, (stop or #t)//1)
  u={}; for j=go, stop, (inc or 1)//1 do u[1+#u]=t[j] end
  return u end

local function lt(x) return function(a,b) return a[x] < b[x] end end 
local function gt(x) return function(a,b) return a[x] > b[x] end end 

-- Sorts `t` using the Schwartzian transform.
local function keysort(t,fun)
  return map(sort(map(t, function(x) return {x=x, fun=fun(x)} end), lt"fun"),
             function(pair) return pair.x end) end 

-- ### Math
--
-- Sample from a Gaussian. 
local function normal(mu,sd,      x1,x2,w)
  while true do
    x1 = 2.0 * math.random() - 1
    x2 = 2.0 * math.random() - 1
    w  = x1*x1 + x2*x2
    if w < 1 then
      return mu + sd * x1 * ((-2*math.log(w))/w)^0.5 end end end

-- ### Thing to string
--
-- Emulate printf.
local fmt = string.format

-- Maybe not print
local function say(...) if not the.quiet then print(...) end end

-- Nested thing to string. For things with keys,
-- do not show private slots (i.e. those starting with "_").
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

-- Print nested things.
local function oo(x) say(o(x)) end

-- ### Objects
--
-- OO in two lines (sans inheritance)? Cool.
local function new(klass,obj) 
  klass.__index=klass; klass.__tostring=o; return setmetatable(obj,klass) end 

-- ## Classes
local DATA,COLS,SOME,ROW,SYM,NUM = {},{},{},{},{},{}

-- ### SYM
--
-- Summarize a stream of symbols
function SYM:new(at,txt) return new(SYM,{n=0,at=at,txt=txt,has={},most=0,mode=nil}) end

-- Update
function SYM:add(x) 
  self.n = self.n + 1
  self.has[x] = (self.has[x] or 0) + 1 
  if self.has[x] > self.most then 
    self.most, self.mode = self.has[x], x end end

-- Return symbol that most selects for the receiver.
function SYM.contrast(i,j,      y,n,r,most,x)
  most = 0
  for k,v in pairs(i.has) do
    y = v/i.n
    n = (j.has[k] or 0)/j.n
    r = y - n
    if r > most then most,x = r,k end end
  return {score=most, mid=x, lo=x, hi=x, col=i} end

-- Return tendency to _not_ be the middle value.
function SYM:div(      e)
  e=0; for _,n in pairs(self.has) do e=e- n/self.n * math.log(n/self.n,2) end
  return e end

function SYM:like(x, prior) 
  return ((self.has[x] or 0) + the.m*prior)/(self.n +the.m) end

-- Return middle value.
function SYM:mid() return self.mode end

-- ### NUM
-- 
-- Summarize a stream of numbers.
function NUM:new(at,txt)
  return new(NUM, {n=0, at=at, txt=txt, lo=1E32, hi=-1E32, mu=0, m2=0, sd=0,
                   goal=tostring(txt):find"-$" and 0 or 1}) end

-- Incremental ally update `lo,hi,mu,sd` (using 
-- [Welford's algorithm](https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Welford's_online_algorithm)).
function NUM:add(x,     d)
  self.n  = self.n + 1
  self.lo = math.min(x,self.lo)  
  self.hi = math.max(x,self.hi) 
  d       = x - self.mu
  self.mu = self.mu + d/self.n
  self.m2 = self.m2 + d*(x-self.mu)
  self.sd = self.n < 2 and 0 or (self.m2/(self.n - 1))^0.5 end   

-- Cumulative distribution (area under the pdf up to x).
function NUM:cdf(x,     z,fun)
  fun = function(z) return 1 - 0.5*math.exp(-0.717*z - 0.416*z*z) end
  z = (x - self.mu)/self.sd
  return z >=  0 and fun(z) or 1 - fun(-z) end

-- Return value of favoring `i.mu` From
-- [stackoverflow](https://stackoverflow.com/questions/22579434/python-finding-the-intersection-point-of-two-gaussian-curves).
function NUM.contrast(i,j,    a,b,c, y,n,x1,x2)
  a  = 1/(2*i.sd^2)  - 1/(2*j.sd^2)  
  b  = j.mu/(j.sd^2) - i.mu/(i.sd^2)
  c  = i.mu^2 /(2*i.sd^2) - j.mu^2 / (2*j.sd^2) - math.log(j.sd/(i.sd + 1E-32))  
  x1 = (-b - (b^2 - 4*a*c)^.5)/(2*a + 1E-32)
  x2 = (-b + (b^2 - 4*a*c)^.5)/(2*a + 1E-32)
  if x1 > x2 then x1,x2=x2,x1 end
  y  = i:cdf(x2) - i:cdf(x1)
  n  = j:cdf(x2) - j:cdf(x1)
  return {score=y - n, mid=i.mu, lo=x1, hi=x2, col=i} end

-- Return tendency to _not_ be the middle value.
function NUM:div() return self.sd end

function NUM:like(x,...)
  local sd, mu = self:div(), self:mid()
  if sd==0 then return x==mu and 1 or 1E-32 end
  return math.exp(-.5*((x - mu)/sd)^2) / (sd*((2*math.pi)^0.5)) end

-- Return middle value.
function NUM:mid() return self.mu end

-- Normalize x 0..1
function NUM:norm(x)
  return x=="?" and x or (x-self.lo)/ (self.hi - self.lo + 1E-32) end

-- ### SOME
function SOME:new(max) return new(SOME,{n=0,_has={},ok=false,max=max or 512}) end

function SOME:add(x,      pos)
  if x ~= "?" then
	  self.n = self.n + 1
		if   #(self._has) < self.max then pos= #self._has else
		  if math.random() < self.max/self.n then pos= math.floor(math.random(#self._has)) end end 
    if pos then
		   self.ok = false
		   self._has[1+pos] = x end end end 

function SOME:has()
  if not self.ok then table.sort(self._has); self.ok = true end
	return self._has end

function SOME:div(    a) a=self:has(); return (a[(#a * .9)//1] - a[(#a * .1)//1])/2.56 end
function SOME:hi(     a) a=self:has(); return a[#a] end
function SOME:lo(     a) a=self:has(); return a[1] end
function SOME:mid(    a) a=self:has(); return a[(#a)//2] end

-- ### COLS
-- Factory that makes and stores and updates NUMs and SYMs.
-- 
-- Initialize from column header names. NUM f upper case, else SYM.
-- Ending in plus or minus means "goal".  Ending in "X"  means ignore.
-- Place all cols in `all`. Also, place goals in `y` and others in `x.
function COLS:new(names,     col)
  self = new(COLS,{names=names, x={}, y={}, all={}})
  for c,s in pairs(self.names) do
    col = push(self.all, (s:find"^[A-Z]" and NUM or SYM):new(c,s))
    if not s:find"X$" then
      push(s:find"[+-]$" and self.y or self.x, col) end end
  return self end

-- Update column summarizes from `row`.
function COLS:add(row,   v)
  for _,cols in pairs{self.x,self.y} do
    for _,col in pairs(cols) do
      v = row[col.at]
      if v ~= "?" then col:add(v) end end end 
  return row end

-- Return max distance of any goal to best possible value.
function COLS:chebyshev(row,    d)
  for _,col in pairs(self.y) do
    d = math.max(d or 0, math.abs(col:norm(row[col.at]) - col.goal)) end 
  return d end 

-- ### DATA
-- Store `rows`, summarized in `cols`.
-- 
-- Create.
function DATA:new() return new(DATA, {cols=nil, rows={}}) end

-- Add to rows, summarize in `cols`.  Initialize `cols` from first row.
function DATA:add(row)
  if   self.cols
  then push(self.rows, self.cols:add(row)) 
  else self.cols = COLS:new(row) end 
  return self end

-- Copy the column structure; maybe add in some rows.
function DATA:clone(rows)
  return DATA:new():add(self.cols.names):load(rows) end

function DATA:features(      tmp,best,rest)
  tmp, out = {},{}
	_,n = self:sort()
	best, rest = self:clone(slice(d.rows,1,n)), self:clone(slice(d.rows,n+1))
  for i,col in pairs(best.cols.x) do 
	  push(tmp, col:contrast(rest.cols.x[i])) end
	for rank,contrast in pairs( slice( sort(tmp, gt"score"), 1, the.features )) do
	  contrast.rank = rank
	  out[contrast.col.at] = contrast end 
	return out, best, rest end

function DATA:like(row, n, nClasses,  col,       prior,out,v,inc) 
  prior = (#self.rows + the.k) / (n + the.k * nClasses)
  out   = math.log(prior)
  for _,col in pairs(cols or self.cols.x) do
    v = row[col.at]
    if v ~= "?" then
      inc = col:like(v,prior)
      if inc > 0 then out = out + math.log(inc) end end end
  return out end

-- Load in a list of rows. Return self.
function DATA:load(rows) 
  for _,row in pairs(rows or {}) do self:add(row) end
  return self end

-- Read in a csc file full of rows. Return self.
function DATA:read(file) 
  csv(file, function(row) self:add(row) end) 
  return self end

-- Sort rows.  Return (1) self and (2) the break between best rows and rest.
function DATA:sort(f,n)
  f = function(row) return self.cols:chebyshev(row) end
  table.sort(self.rows, function(a,b) return f(a) < f(b) end)
  n = (#self.rows)^the.Best // 1 
  return self, n end

-- ## Active Learning
function DATA:activeLearning(rows, scoreFun, slower)
  scoreFun = scoreFun or function(B,R) return B-R end
  local ranked,guess,todos,todo,done,k
  function ranked(rows) return self:clone(rows):sort().rows end

  function todos(todo,     b,now,after)
    b = the.buffer
    if slower or #todo <= 4*b then return todo,{} end
    now, after = slice(todo, 1,b), slice(todo, b*3+1)
    for i=b+1, 3*b do -- rotate early items to back of list
      push(i >= b*2 and now or after,   todo[i]) end
    return now, after end 

  function guess(todo, done)
    local cut,best,rest,now,after
    local score = function(r) 
                    return scoreFun(best:like(r,#done,2), rest:like(r,#done,2)) end
    cut       = ((#done) ^ the.Best) // 1
    best      = self:clone(slice(done,1,cut))
    rest      = self:clone(slice(done,cut+1))
    now,after = todos(todo)
    table.sort(now, function(row1,row2) return score(row1) > score(row2) end)  
    for _,row in pairs(after) do push(now,row) end
    return now end

  todo, done = slice(rows, the.start+1), ranked(slice(rows, 1, the.start))
  for k = 1, the.stop - the.start do
    if #todo < 4 then break end
    todo = guess(todo, done)
    push(done, table.remove(todo,1))
    done = ranked(done) end
  return done end 

-- ## Place to store demos
local go={}
-- ### Support code
-- Return all the commands.
local function goes(     t)
  t={}; for k,_ in pairs(go) do if  #k > 1 then t[1+#t] = k end end
  return sort(t) end

-- ### Insert demos here
go.h   = function(_) 
            say("\n" .. help .. "\n") 
            say("COMMANDS:\n  lua mu.lua [-"
                  ..table.concat(goes(),',-').."]\n") end

go.all = function(_,            fails,pass,err) 
            fails = 0
            for _,k in pairs(goes()) do 
              if k ~= "all" then 
                math.randomseed(the.seed)
                io.stderr:write(k,"\n")
                pass,err=pcall(go[k])
                if   not pass 
                then io.stderr:write("\tFAIL : ",err,"\n")
                     fails=fails+1 end end end
            os.exit(fails) end

go.c   = function(x) the.cohen = x end
go.b   = function(x) the.buffer  = x end
go.B   = function(x) the.Best  = x end
go.q   = function(x) the.quiet = not the.quiet end
go.s   = function(x) the.seed  = x; math.randomseed(x) end
go.t   = function(x) the.train = x end

go.the = function(_) oo(the) end

go.csv = function(_,        n) 
            n=0
            csv(the.train, function(row)
                             n=n+1
                             if n>10 then return end 
                             oo(row) end ) end

go.num = function(_, n)  
            n=NUM:new(); for i=1,100 do n:add(math.random()^.5) end   
            assert(0.71 < n:mid() and n:mid() < 0.72,"bad mid")
            assert(0.22 < n:div() and n:div() < 0.23,"bad div") end

go.normal = function(_,          t,n,x)
              t={}; for i=1,1000 do x=normal(10,2) // 1; t[x]=(t[x] or 0) + 1 end
              for i = 4,16 do
                n = t[i] or 0
                say(i,n,("*"):rep(n//10)) end end

go.sym = function(_, s)
            s=SYM:new(); for _,x in pairs{"a","a","a","a","b","b","c"} do s:add(x) end
            assert(1.37 <= s:div() and s:div() <= 1.38,"bad div") end

go.data = function(_,         c,d) 
            d = DATA:new():read(the.train)
            c=0; for _,row in pairs(d.rows) do c=c+#row end
            assert(c==3184 and #d.cols.x==4 and  #d.cols.y==3,"bad load") end 

go.sort = function(_,   last,c,d) 
            d = DATA:new():read(the.train):sort()
            last = -1
            for i,row in pairs(d.rows) do
              c = d.cols:chebyshev(row)
              assert(c >= last,"bad sort")  
              last = c end end 

go.contrast = function(_,  left,right)
                left  = NUM:new(); for i=1,1000 do  left:add(normal(2.5, 3)) end
                right = NUM:new(); for i=1,1000 do  right:add(normal(5, 1) ) end 
                oo(left:contrast(right)) 
                left  = NUM:new(); for i=1,1000 do  left:add(normal(2.5, 1)) end
                right = NUM:new(); for i=1,1000 do  right:add(normal(5, 1) ) end 
                oo(left:contrast(right)) end

go.contrasts = function(_,  left,right,d,n,best,rest)
                 d,n = DATA:new():read(the.train):sort()
                 best,rest = d:clone(), d:clone()
                 for i,row in pairs(d.rows) do
                   (i <= n and best or rest):add(row) end
                 print(#best.rows,#rest.rows)
                 for i,col in pairs(best.cols.x) do
                    print(col.txt, o(col:contrast(rest.cols.x[i]))) end end 

go.alearn = function(repeats,     fun,d,top,rand,start,asIs,toBe,r,rows)
              repeats = repeats or 20
							asIs,toBe,rand = SOME:new(), SOME:new(), SOME:new()
              d = DATA:new():read(the.train)
							for _,row in pairs(d.rows) do
							  asIs:add(d.cols:chebyshev(row)) end
							r = asIs:div()*the.cohen
							fun = function(x) return (x//r + 0.5)*r end
							start = os.clock()
						  for i=1,repeats do
			          io.stderr:write("."); io.stderr:flush()
                rows = shuffle(d.rows)
								rand:add(fun(d.cols:chebyshev(
							 	                d:clone(slice(rows,1,the.stop)):sort().rows[1])))
							  top=d:activeLearning(d.rows)[1] 
								toBe:add(fun(d.cols:chebyshev(top))) end 
							print("")
							oo{rows=#d.rows, xcols=#d.cols.x,msecs= 1000*(os.clock() - start)/repeats//1}
							print("asIs",o{Mid=asIs:mid(), div=asIs:div(),small=r,lo=asIs:lo()})
							print("toBe",o{Mid=toBe:mid(), div=toBe:div()})
							print("rand",o{Mid=rand:mid(), div=rand:div()})
							end
              
-- ## Start-up
--
-- If loaded inside another Lua file, just return the classes. Else
-- run any  command line entries that are also `go` functions.
math.randomseed(the.seed)
if   pcall(debug.getlocal,4,1) 
then return {the=the, DATA=DATA, COLS=COLS, ROW=ROW, SYM=SYM, NUM=NUM}
else for j,s in pairs(arg) do
       if go[s:sub(2)] then go[s:sub(2)]( coerce(arg[j+1] or "") ) end end end 
