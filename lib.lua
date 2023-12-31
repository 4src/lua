#!/usr/bin/env lua
-- <!-- vim : set et sts=2 sw=2 ts=2 : -->
-- In this code, in function argument lists, two spaces denotes "start of
-- optional args" and four spaces denotes "start of local variables". Also:
--
-- | this   |=| reference to that |
-- |-------:|-|-------------------|
-- | `t`    |=| table |
-- | `n`    |=| number |
-- | `s`    |=| string |
-- | `x`    |=| anything |
-- | `k,v`  |=| key,value |
-- | `fun`  |=| function |
-- | `_fun` |=| a local function inside the current function |
-- | `Xs`   |=| list of X  (so `ss` is a list of strings, `ts`` is a list of tables, etc) |
-- | `X1`   |=| an example of X (so `s1` is a string) |
-- | `abc`  |=| (if upper case `ABC` is a constructor), an instance of class `ABC` |

local lib={}

-- ### Linting the code
local b4={}; for k,_ in pairs(_ENV) do b4[k] = k end
function lib.rogues()
  for k,_ in pairs(_ENV) do if not b4[k] then
    io.stderr:write("-- warning: rogue local [",k,"]\n") end end end

-- ### Short-cuts

-- A big number
lib.big = 1E30
-- emulate C's printf
lib.fmt = string.format

-- ### Maths

-- Rounds `n` to `nPlaces` (default=2)
function lib.rnd(n,  nPlaces,     mult)
  mult = 10^(nPlaces or 2)
  return math.floor(n * mult + 0.5) / mult end

-- Generate random numbers.
local Seed = 937162211
-- Returns random integers `nlo` to `nhi`.
function lib.rint(nlo,nhi)
  return math.floor(0.5 + lib.rand(nlo,nhi))  end
-- Returns random floats `nlo` to `nhi` (defaults 0 to 1)
function lib.rand(nlo,nhi)
  nlo,nhi=nlo or 0, nhi or 1
  Seed = (16807 * Seed) % 2147483647
  return nlo + (nhi-nlo) * Seed / 2147483647 end

-- ### Meta

-- Identity
function lib.same(x) return x end

-- Returns a copy of `t` with all items filtered via `fun2` (where `fun2`
-- accepts an item's index _and_ the item). If `fun2` returns two values,
-- use the second as the key for the new list (else just number the items
-- numerically).
function lib.kap(t1,fun2,     t2)
  t2={}; for k,v in pairs(t1 or {}) do v,k=fun2(k,v); t2[k or (1+#t2)]=v; end; return t2 end
-- Returns a copy of `t` with all items filtered via `fun`.
function lib.map(t, fun) return lib.kap(t, function(_,x) return fun(x) end) end

-- ### Lists

-- Return a list with numeric keys.
function lib.list(t)
  return lib.map(t,lib.same) end

-- Sorts `t` using `fun`, returns `t`.
function lib.sorted(t,fun)
  table.sort(t,fun)
  return t end

-- Sorts `t` using the Schwartzian transform.
function lib.keysort(t,fun)
  return lib.map(lib.sorted(lib.map(t, function(x) return {x=x, fun=fun(x)} end), lib.lt"fun"),
                 function(pair) return pair.x end) end

-- Return a function that sorts ascending on slot `x`.
function lib.lt(x) return function(t1,t2) return t1[x] < t2[x] end end

-- Return a function that sorts ascending on slot `x`.
function lib.gt(x) return function(t1,t2) return t1[x] > t2[x] end end

-- Returns the  keys of list `t`, sorted.
function lib.keys(t) return lib.sort(lib.kap(t,function(k,_) return k end)) end
-- Returns `x` after pushing onto `t`
function lib.push(t,x) t[#t+1]=x; return x end

-- Return any item from `t`.
function lib.any(t) return t[lib.rint(1,#t)] end
-- Return `n` items from `t`.
function lib.many(t1,n,    t2)
  t2={}; for _=1,n do lib.push(t2, lib.any(t1)) end; return t2 end

-- Return a portion of `t1`; go,stop,inc defaults to 1,#t1,1.
-- Negative indexes are supported.
function lib.slice(t1, nGo, nStop, nInc,    t2)
  if nGo   and nGo   < 0 then nGo=#t1+nGo+1   end
  if nStop and nStop < 0 then nStop=#t1+nStop end
  t2={}
  for i=(nGo or 1)//1,(nStop or #t1)//1,(nInc or 1)//1 do t2[1+#t2]=t1[i] end
  return t2 end

function lib.per(a,p) return a[p*#a//1] end
-- ### Strings

-- Return a string  showing `t`'s contents (recursively), sorting on the keys.
function lib.o(t,     _fun,pre)
  if type(t) ~= "table" then return tostring(t) end
  _fun = function(k,v) if k ~="^_" then return lib.fmt(":%s %s",k,lib.o(v)) end  end
  t = #t>0 and lib.map(t,lib.o) or lib.sorted(lib.kap(t,_fun))
  return (t.a or "").."{"..table.concat(t," ").."}" end

-- Print `t` (recursively) then return it.
function lib.oo(t) print(lib.o(t)); return t end

function lib.ooo(x,  decs)
  return  type(x)=="function" and  "FUN()" or (
          decs and type(x) =="number" and lib.rnd(x,decs) or x) end

-- Convert `s` into an integer, a float, a bool, or a string (as appropriate). Return the result.
function lib.coerce(s,    _fun)
  function _fun(s1)
    return s1=="true" and true or (s1 ~= "false" and s1) or false end
  return math.tointeger(s) or tonumber(s) or _fun(s:match"^%s*(.-)%s*$") end

-- Split a `s`  on commas.
function lib.cells(s,    t)
  t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t] = lib.coerce(s1) end; return t end

-- Run `fun` for all lines in a csv file `s` (where each line is divided on ",").
function lib.csv(sFilename,fun,      src,s)
  src = io.input(sFilename)
  while true do
    s = io.read(); if s then fun(lib.cells(s)) else return io.close(src) end end end

-- Return `t`, updated from the command-line.  For `k,v` in
-- `t`,if the command line mentions key `k` then change `s` to a new
-- value.  If the old value is a boolean, just flip the old.
function lib.cli(t)
  for k,v in pairs(t) do
    v = tostring(v)
    for n,x in ipairs(arg) do
      if x=="-"..(k:sub(1,1)) or x=="--"..k then
        v = v=="false" and "true" or v=="true" and "false" or arg[n+1] end end
    t[k] = lib.coerce(v) end
  return t end

-- Parse `help` text to extract settings.
function lib.settings(s,       t)
  t={}
  s:gsub("\n[%s]+[-][%S][%s]+[-][-]([%S]+)[^\n]+= ([%S]+)",
         function(k,v) t[k]=lib.coerce(v) end)
  return t,s end

-- ### Klasses

-- Create a klass and a constructor and a print method
local id=0
function lib.obj(s,    t)
  t = {}
  t.__index = t
  return setmetatable(t, {__tostring=lib.o, __call=function(_,...)
    id = id + 1
    local self=setmetatable({a=s,id=id},t);
    return setmetatable(t.init(self,...) or self,t) end}) end

-- ### Test Engine

-- Show the help (if asked to).  Run one test, or if the test is `all`,
-- then run all (printing "FAIL" or "PASS" as you go).  Check for stray i
-- globals.  Return to the operating system the number of failures
-- (so zero means "everything is ok").
function lib.run(settings,egs,     fails,old,report,good,bad,reset)
  fails, old = 0, {}
  for k,v in pairs(settings) do old[k]=v end
  report=  function()       print("🔆 fails=",fails) end
  good=    function(s)      print("✅ PASS ",s) end
  bad=     function(s,msg)  print("❌ FAIL : ",s,msg or "")
                            fails = fails + 1 end
  --missing= function(s)      print("?? unknown ",s) end
  reset=   function()       for k,v in pairs(old) do settings[k]=v end
                            Seed = settings.seed
                            math.randomseed(Seed) end
  for _,s in pairs(egs.all) do
    if settings.go == s or settings.go == "all" then
      reset()
      if egs[s]() ==false then bad(s) else good(s) end end  end
      --local ok,val = pcall(egs[s] or function () missing(s) end)
      --if not ok then bad(s,msg) elseif val==false then bad(s) else good(s) end end end
  if settings.go == "all" then report() end
  lib.rogues()
  os.exit(fails) end

function lib.go(help,the,egs)
  if not pcall(debug.getlocal,5,1) then
     the=lib.cli(the)
     if the.help then print(help)
     else lib.run(the,egs) end end end

return lib
