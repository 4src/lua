#!/usr/bin/env lua
-- <!-- vim : set et sts=2 sw=2 ts=2 : -->

--[[ 
&copy; 2024 Tim Menzies, timm@ieee.org    
BSD-2 license. Share and enjoy.  

----------------------------------

Some kinds of AI and very easy to script. Let me show you how.

Here
we code up an explanation system for semi-supervised
multi-objective optimization. Internally, this is coded via
sequential model optimization and
membership query synthesis. 

Sounds complicated, right?  But it ain't. In fact, as shown below,
all the above is just a hundred lines of code (caveat: provided  you are using
the right  underlying object model). 

Which raised the question: what
else is similarly  simple? How many of our complex problems... aren't?
My challenge to you is this: please go and find out. That is, take  a working system,
see what you can throw away (while the reaming system is still useful and fast).
Let me know happens  so I can add your fantastic new, and simple,
idea to this code (and add you to the author list).

For
access to this file (ez.lua), see [github.com/4src/lua](http://github.com/4src/lua).

Since this code are showing off simplicity, we will use Lua for the
implementation.  Lua is  easy to learm, is resource light, and
compiles everywhere (for more on Lua see
https://learnxinyminutes.com/docs/lua/).  The best way to learn
this code is port it to Python, Julia, Java whatever is you favorite
language.

Since this code is meant to show off things, this code has lots of
`em.xxx` functions. Each of these can be called on the command line
using (e.g.)

    lua ez.lua -e klass      # calls the eg.klass() function

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

<i class="fa fa-lightbulb  good"></i>
_Config params should not be  buried. Best to store them in config object. _  ]]--


    local the,cli,as
    the = {eg    = "the",      -- start-up action
           p     = 2,          -- coeffecient on distance function
           seed  = 1234567891, -- random number seed
           train = "data/misc/auto93.csv", -- where to read data
           verbose = false
          }

--[[ 
<i class="fa fa-lightbulb  good"></i>
_To  simplifies experimentation and optimization, best to allow for config modification from the command line._ ]]--

These options can be updated from the command-line using the
`cli` function.  For each slot such as `seed`, the values can be updated
on the command line by flag `-s arg` or `--seed arg`. `cli` expects a aergument for
everyhing except for boolean slots. For such booleans, if this function sees (e.g.) `--verbose`
the it just flips the default value (which, in this case would set `the.verbose=true`),
for each flag--.  except for the flags of boolean values.  If `cli`
sees those flags, it just flips the default values. :one:  ]]--

    function cli(d) --> d
      for k,v in pairs(d) do
        v = tostring(v)
        for n,x in ipairs(arg) do
          if x=="-"..(k:sub(1,1)) or x=="--"..k then
            d[k] = atom(v=="false" and "true" or v=="true" and "false" or arg[n+1]) end end 
        if k=="seed" then math.randomseed(t[k]) end end end 
      return d

--[[ Note the reference to `seed` in the last line of `cli`.  For
debugging purposes, it is  useful to be replay anything choosen
stochastically.  So computers use random number generators that are
based  on  some seed.  By resetting the seed, a so-called "random" sequence
will repeat. This is why we reset the seed whenever that flag is
seen. 

<i class="fa fa-skull-crossbones  bad"></i>  _Do not lose track of your
random number seeds. 
With any experimental result, store the seed that generated it.
Reset the seed to some known value before calling important code._


One small details: `cli` needs to convert strings to simple values
(true, false, float or integer). This is handled by the `atom` function.
]]--

    function atom(s,    fun) --> atom
      fun = function(s) return s=="true" and true or (s ~= "false" and s) or false end
      return math.tointeger(s) or tonumber(s) or fun(s:match"^%s*(.-)%s*$") end

--[[ ## Types Hints
In this code, function arguments use a shorthand to specify type hints.


- My classes have constructor functions (e..g NUM) and any lowever case version
of that is a instance of that type (e.g. `num` is a NUM).
- As to other types, 
`s`, `i`, `n`, `a`, `d` are strings, integers, numbers, arrays and dictionaries
(and dictionaries have  symbolic keys),
- Also `fun` denotes a function, `atom` denotes any atomic thing,
and `any` denotes any thing at all. 

For example, the 
function `atom` (shown above) accepts a string and a function, a returns something
of type atom.

A suffix `s` denotes an array of things. E.g. `is` is an array of integers and 
`nums` is an array of NUMs.

As to other things, in a function argument list, two spaces denotes the start of optional
arguments while four spaces denotes start of local variables.

## Classes 
Before defining classes,   we need some place to store data and methods. Our objects
can print themselves (with slots printed in sorted order),  using
the `cat` function.  ]]--

    local new,cat
    function new(kl,self) 
      kl.__index=kl; kl.__tostring = cat; setmetatable(self,kl); return self end
    
    function cat(t,     u)
      u={}; for k,v in pairs(t) do u[1+#u] = string.format(":%s %s",k,v) end
      table.sort(u)
      return "{" .. table.concat(u," ") .. "}" end

--[[ Now we can define classes. These classes hold the raw data
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

]]--

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

--[[ sdasas  ]]--

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

as asd asdads
