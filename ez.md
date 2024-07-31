
# Easier AI

&copy; 2024 Tim Menzies, timm@ieee.org    
BSD-2 license. Share and enjoy.

Some kinds of AI and very easy to script. Let me show you how.  For
access to this file (ez.lua), see http://github.com/4src/lua.

Since this code are showing off simplicity, we will use Lua for the
implementation.  Lua is  easy to learm, is resource light, and
compliles everywhere (for more on Lua see
https://learnxinyminutes.com/docs/lua/).  The best way to learn
this code is port it to Python, Julia, Java whatever is you favorite
language.

Since this code is meant to show off things, this code has lots of
`eg.xxx` functions. Each of these can be called on the command line
using (e.g.)

    lua ez.lua -e klass      # calls the eg.klass() function

Also, just to show that something cool is happenning here, this
code does some standard things, and then some very unstandanrd,
novel and exciting things. For example, using membership query
synthesis, this code implements explanation and active learning for
multi-objective reasoning (where just a few dozen labels are enough
to reason over 10,000s of examples). $y=2^x$

## About the code

The code divides into several chapters. 

First, there is some preambles stuff that is required before anything
else (config options, some cli stuffs);

Chapter two defines the data structures used in this code.  

Chapter three is all about loading disk information into a DATA object.
This code holds that information in the DATA.rows list.

In Chapter four, we ..

## Chapter 1: Preamble 

This code is controlled by the following options. 
These options can be updated from the command-line using the
`cli` function.  eFor each slot `xxx`, the values can be updated
on by a flag `-x` or `--xxx`. `cli` expects a command-line value
for each flag--.  except for the flags of boolean values.  If `cli`
sees those flags, it just flips the default values. 

    local the,cli,as

    the = {eg    = "the",      -- start-up action
           p     = 2,          -- coeffecient on distance function
           seed  = 1234567891, -- random number seed
           train = "data/misc/auto93.csv" -- where to read data
          }

    function cli(t)
      for k,v in pairs(t) do
        v = tostring(v)
        for n,x in ipairs(arg) do
          if x=="-"..(k:sub(1,1)) or x=="--"..k then
            t[k] = as(v=="false" and "true" or v=="true" and "false" or arg[n+1]) end end 
        if k=="seed" then math.randomseed(t[k]) end end end 

Note the reference to `seed` in the last line of `cli`.  For
debugging purposes, it is  useful to be replay anything choosen
stochastically.  So computers use random number generators that are
based  on  some seed.  By resetting the seed, a random sequence
will repeat. This is why we reset the seed whenever that flag is
seen.

One small details: `cli` needs to convert strings to simple values
(true, false, float or integer). This is handled by the `as` function.


    function as(s,    fun)
      fun = function(s) return s=="true" and true or (s ~= "false" and s) or false end
      return math.tointeger(s) or tonumber(s) or fun(s:match"^%s*(.-)%s*$") end

## Classes 
Before defining classes,   we need some place to store data and methods. Our objects
can print themselves (with slots printed in sorted order),  using
the `cat` function.  

    local new,cat

    function new(kl,self) 
      kl.__index=kl; kl.__tostring = cat; setmetatable(self,kl); return self end

    function cat(t,     u)
      u={}; for k,v in pairs(t) do u[1+#u] = string.format(":%s %s",k,v) end
      table.sort(u)
      return "{" .. table.concat(u," ") .. "}" end

Now we can define classes. These classes hold the raw data
as well as summaries of that information.

When we read data from disk, row1 defines the role of each column.
For example:

Rows of data are held in a DATA
object which summarize the data in NUM and SYM columns (those
columns are stored in the DATA.cols.all list).

Also, there is a COLS klass that is a factory for converting list of
column names into the appropriate NUMs and SYMs. Our column names
define various 

    Clndrs  ,Volume  ,HpX  ,Model  ,origin  ,Lbs-  ,Acc+  ,Mpg+
    4       ,90      ,48   ,80     ,2       ,2335  ,23.7  ,40
    4       ,97      ,52   ,82     ,2       ,2130  ,24.6  ,40
    4       ,90      ,48   ,80     ,2       ,2085  ,21.7  ,40
    4       ,91      ,67   ,80     ,3       ,1850  ,13.8  ,40
    ...     ...      ...    ...    ...       ...    ...    ...
    8       ,304     ,193  ,70     ,1       ,4732  ,18.5  ,10
    8       ,360     ,215  ,70     ,1       ,4615  ,14    ,10
    8       ,307     ,200  ,70     ,1       ,4376  ,15    ,10
    8       ,318     ,210  ,70     ,1       ,4382  ,13.5  ,10



    local DATA, COLS, NUM, SYM = {},{},{},{}

    function NUM:new(at,txt) 
      return new(NUM, {n=0, -- number of items seen in this column
                       at=at or 0,txt=txt or " ", 
                       mu=0, m2=0, sd=0}) end

    function csv(fileName,fun,      src,s,cells)
      cells = function(s,    t)
        t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t] = as(s1) end; return t end
      src = io.input(fileName)
      while true do
        s = io.read(); if s then fun(cells(s)) else return io.close(src) end end end

sdasas  

    local eg={}

    function eg.klass()
      local CAT,DOG={},{}
      function CAT:new(s) return new(CAT,{zzz=0, tag=s}) end
      function DOG:new(s) return new(DOG,{age=0, name=s,friend=Cat:new("ss")}) end
      print(DOG:new("timm")) end

    math.randomseed(the.seed)
    if arg[1]=="--eg" then
      cli(the)
      if eg[seed.eg] then eg[seed.eg]() end end

    return {the=the, eg=eg, cli=cli, DATA=DATA, NUM=NUM, SYM=SYM}
