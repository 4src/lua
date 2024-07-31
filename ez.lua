#!/usr/bin/env lua
-- <!-- vim : set et sts=2 sw=2 ts=2 : -->

--[[ # Easier AI

(c) 2024 Tim Menzies, timm@ieee.org    
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
to reason over 10,000s of examples.

## Configuration

This code is controlled by the following options.  These options
can be updated from the command-line using the `cli` function.  For
each slot `xxx`, the values can be updated on by a flag `-x` or
`--xxx`. ]]--

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

--[[ The `cli` function expect a command-line value for each flag.
The exception are the flags for boolean values: if `cli` sees those
flags, it just flips the default values.

`cli` needs to convert strings to simple values (true, false, float
or integer). This is handled by the `as` function. ]]--

    function as(s,    fun)
      fun = function(s) return s=="true" and true or (s ~= "false" and s) or false end
      return math.tointeger(s) or tonumber(s) or fun(s:match"^%s*(.-)%s*$") end

--[[ ]]--

    function csv(fileName,fun,      src,s,cells)
      cells = function(s,    t)
        t={}; for s1 in s:gmatch("([^,]+)") do t[1+#t] = as(s1) end; return t end
      src = io.input(fileName)
      while true do
        s = io.read(); if s then fun(cells(s)) else return io.close(src) end end end
    
--[[ First, we need some objects for storing data and methods. Our objects
can print themselves (with slots printed in sorted order),  using
the `cat` function.  ]]--

    local new,cat

    function new(kl,self) 
      kl.__index=kl; kl.__tostring = cat; setmetatable(self,kl); return self end

    function cat(t,     u)
      u={}; for k,v in pairs(t) do u[1+#u] = string.format(":%s %s",k,v) end
      table.sort(u)
      return "{" .. table.concat(u," ") .. "}" end

    local eg={}

    function eg.klass()
      local Cat,Dog={},{}
      function Cat:new(s) return new(Cat,{zzz=0, tag=s}) end
      function Dog:new(s) return new(Dog,{age=0, name=s,friend=Cat:new("ss")}) end
      print(Dog:new("timm")) end

    
    math.randomseed(the.seed)
    if arg[1]=="--eg" then
      cli(the)
      if arg[2] then eg[arg[2]]() end end
