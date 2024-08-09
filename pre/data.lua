local l=require"lib"

local NUM,SYM,DATA,COLS,ROW = {},{},{},{},{}
local new,o,oo = l.new, l.o, l.oo

local _id=0
function ROW:new(t)
  _id = _id + 1
  return new(ROW,{cells=t, cooked=l.copy(t)}) end

function SYM:new(at,s) 
  return new(SYM,{at=at or 0, txt=s or " ", n=0, mode=None, most=0, has={}}) end

function NUM:new(at,s) 
  return new(NUM,{at=at or 0, txt=s or " ", n=0, mu=0, m2=0, sd=0,
                  lo=1E32, hi=-1E32, goal= (s or ""):find"-$" and 0 or 1}) end

function COLS:new(names,     x,y,all,col)
  x,y,all = {},{},{}
  for at,txt in pairs(names) do
    col = l.push(all, (txt:find"^[A-Z]" and NUM or SYM):new(at,txt)) 
    if not txt:find"X$" then
      l.push(txt:find"[+-]" and y or x, col) end end
  return new(COLS, {all=all, x=x, y=y, names=names}) end

function DATA:new()
  return new(DATA, {rows={}, cols=None}) end

function DATA.clone(i, rows)
  return DATA():load({i.cols.name}):load(rows or {}) end

-- ----------------------------------------------------------------------------
function DATA.read(i,file) 
  l.csv(file, function(t) i:add(ROW:new(t)) end) 
  return i end

function DATA.load(i,a) 
  for _,row in pairs(a) do i:add(row) end 
  return i end

-- ----------------------------------------------------------------------------
function DATA.add(i,row)
  if i.cols then l.push(i.rows,i.cols:add(row)) else i.cols=COLS:new(row.cells) end end

function NUM.add(i,x,    d)
  if x == "?" then return end
  i.n  = i.n + 1
  i.lo = math.min(x, i.lo)
  i.hi = math.max(x, i.hi)
  d    = x - i.mu
  i.mu = i.mu + d/i.n
  i.m2 = i.m2 + d*(x - i.mu) 
  i.sd = i.n < 2 and 0 or (i.m2/(i.n - 1))^0.5 end 

function SYM.add(i,x)
  if x == "?" then return end
  i.n = i.n + 1
  i.has[x] = 1 + (i.has[x] or 0)
  if i.has[x] > i.most then 
    i.mode,i.most = x,i.has[x] end end 

function COLS.add(i,row)
  for _,cols in pairs{i.x, i.y} do
    for _,col in pairs(cols) do
      col:add(row.cells[col.at]) end end
  return row end

-- ----------------------------------------------------------------------------
return {NUM=NUM, SYM=SYM, DATA=DATA, COLS=COLS}
