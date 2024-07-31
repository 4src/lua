--[[
asdaasads
]]--

    local map,cat,new

    function sort(t,fun) table.sort(t,fun); return t end

    function cat(t)
      u={}; for k,v in pairs(t) do u[1+#u] = fmt(":%s %s",k,v) end; 
      return "{" .. table.concat(sort(u)," ") .. "}"

    function l.new(kl,self) 
      kl.__index=kl; kl.__tostring = cat; setmetatable(self,kl); return self end
