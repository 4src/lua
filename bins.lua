the={cohen=0.35, bins=17}

function stats(rows,get,    v,n) 
  u,v = {},{}
  for i,row in pairs(rows) do push(get(row) == "?" and u or v, row) end
  table.sort(v, function(row1,row2) return get(row1) < get(row2) end)
  n = #v // 10
  return {u=u, v=v, lo=get(v[1]), hi=get(v[#v]), 
          mid=get(v[5*n]), sd=(get(v[9*n])-get(v[n]))/2.56} end
 
function main(rows, get, put)
  local cuts, s = {}, stats(rows,get)
  local cut = s.lo
  cuts[cut] = 0
  for i,row in pairs(v) do
    if i < #v - #v/the.bins then
      if cuts[cut] >= #v/the.bins then 
        if get(v[i+1]) - get(row) > (s.hi - s.lo)/100 then
          if get(row) - cut >= s.sd*the.cohen then
            cut = get(row)
            cuts[cut] = 0 end end end end
    cuts[cut] = cuts[cut] + 1 
    put(row,cut) end
  return cuts end
