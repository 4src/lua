-- ## Lib
local lib={}
-- ### String to thing(s)
--
-- Simple coerce (assumes booleans, nil, ints, floats or strings)
local function _trim(s)    return s:match"^%s*(.-)%s*$" end
local function _coerce(s) return s=="true" and true or s ~= "false" and s end
function lib.coerce(s)  return math.tointeger(s) or tonumber(s) or _coerce(_trim(s)) end  

-- Read csv, coerce cells, call `fun` on each rows.
function lib.csv(sFilename,fun,      src,s,cells)
  function cells(s,    t) 
    t={}; for s1 in s:gmatch"([^,]+)" do t[1+#t] = lib.coerce(s1) end; return t end  
  src = io.input(sFilename)
  while true do
    s = io.read()
    if s then fun(cells(s)) else return io.close(src) end end end

-- ### Lists
--
-- push to list
function lib.push(t,x) t[1+#t] = x; return x end

function lib.map(t,fun,      u)
  u={}; for k,v in pairs(t) do u[1+#u] = fun(v) end; return u end

-- Rearrange, in place
function lib.shuffle(t,    j)
  for i = #t, 2, -1 do j = math.random(i); t[i], t[j] = t[j], t[i] end
  return t end

-- Sort a list, in-place
function lib.sort(t,fun) table.sort(t,fun); return t end

function lib.slice(t, go, stop, inc,       u)
  if go   and go   < 0 then go   = #t+go end
  if stop and stop < 0 then stop = #t+stop end
  go   = math.max(1,  (go   or 1)//1)
  stop = math.min(#t, (stop or #t)//1)
  u={}; for j=go, stop, (inc or 1)//1 do u[1+#u]=t[j] end
  return u end

function lib.lt(x) return function(a,b) return a[x] < b[x] end end 
function lib.gt(x) return function(a,b) return a[x] > b[x] end end 

-- Sorts `t` using the Schwartzian transform.
function lib.keysort(t,fun)
  return lib.map(lib.sort(lib.map(t, function(x) return {x=x, fun=fun(x)} end), 
                          lib.lt"fun"),
                 function(pair) return pair.x end) end 

-- ### Math
--
-- Sample from a Gaussian. 
function lib.normal(mu,sd,      x1,x2,w)
  while true do
    x1 = 2.0 * math.random() - 1
    x2 = 2.0 * math.random() - 1
    w  = x1*x1 + x2*x2
    if w < 1 then
      return mu + sd * x1 * ((-2*math.log(w))/w)^0.5 end end end

-- ### Thing to string
--
-- Emulate printf.
lib.fmt = string.format

-- Maybe not print

-- Nested thing to string. For things with keys,
-- do not show private slots (i.e. those starting with "_").
function lib.o(x,    u)
  if type(x) == "number" then return lib.fmt("%g",x) end
  if type(x) ~= "table"  then return tostring(x) end
  u={}
  if   #x > 0 
  then for k,v in pairs(x) do u[1+#u] = lib.o(v) end
  else for k,v in pairs(x) do 
         if lib.o(k):sub(1,1) ~= "_" then 
            u[1+#u] = lib.fmt("%s=%s", k, lib.o(v)) end end end
  return "{" .. table.concat(#x==0 and lib.sort(u) or u,", ") .. "}" end 

-- ### Objects
--
-- OO in two lines (sans inheritance)? Coolib.
function lib.new(klass,obj) 
  klass.__index=klass; klass.__tostring=lib.o; return setmetatable(obj,klass) end 

return lib
