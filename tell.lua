--[[ # Reasonably Simple Reasoning 

(c) 2024 Tim Menzies, timm@ieee.org
BSD-2 license. Share and enjoy.

Some kinds of AI and very easy to script. Let me show you how.

Since we are showing off simplicity, we will use Lua for the coding.
That language is  easy to learm, is resource light, and compliles
everywhere.  For more on Lua see https://learnxinyminutes.com/docs/lua/.

Since we are doing things to show off things, this code ends lots of
`eg.xxx` functions. Each of these can be called on the command line using

   lua tell.lua 
First, we need some objects for storing data and methods. Our objects
can print themselves (with slots printed in sorted order),  using
the `cat` function. ]]--

    local new,cat

    function new(kl,self) 
      kl.__index=kl; kl.__tostring = cat; setmetatable(self,kl); return self end

    function cat(t,     u)
      u={}; for k,v in pairs(t) do u[1+#u] = string.format(":%s %s",k,v) end; 
      table.sort(u)
      return "{" .. table.concat(u," ") .. "}" end

    local eg={}

    function eg.klass()
      local Cat,Dog={},{}
      function Cat:new(s) return new(Cat,{zzz=0, tag=s}) end
      function Dog:new(s) return new(Dog,{age=0, name=s,friend=Cat:new("ss")}) end
      print(Dog:new("timm")) end

    if arg[1]=="tell" and arg[2] then eg[arg[2]]() end
