function sortid(a,key,     memo)
   memo={}
   table.sort(a, function(x,y)
                   if memo[x.id] == nil then memo[x.id] = key(x) end
                   if memo[y.id] == nil then memo[y.id] = key(y) end
                   return memo[x.id] < memo[y.id] end)
   return a end

d={
    {id=1,z=1000}, {id=2,z=200}, {id=3,z=10},
    {id=4,z=1000}, {id=5,z=200}, {id=6,z=10},
    {id=7,z=1000}, {id=8,z=200}, {id=9,z=10},
    {id=10,z=1000}, {id=11,z=200}, {id=12,z=10},
    {id=13,z=1000}, {id=14,z=200}, {id=15,z=10}}

fun = function(z) return math.abs(d[#d].z - z.z) end
for _,x in pairs(sortid(d,fun)) do print(x.id,x.z) end
