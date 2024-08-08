the={cohen=0.35, bins=17}

fction stats(rows,f,    v,n) 
  q = function(x) return x=="?" and -1E32 or x end
  table.sort(rows, function(row1,row2) return q(f(row1)) < q(f(row2)) end)
  u,v = {},{}
  for i,row in pairs(rows) do
    if f(row) == "?" then push(u,row) else push(v,row) end end
  n = #v // 10
  return u, v, f(v[5*n]), (f(v[9*n])-f(v[n]))/2.56 end
 
function main(rows, col, x)
  local cut,cuts,njump,trivial,n,epsilon
  local f = function(row) return row[col] end
  u, v,mid,sd           = stats(rows,f)
  epsilon               = (v[#v] - v[1]) / 100
  cut, cuts, njump      = v[1], {}, #v/(the.bins - 1) // 1
  cuts[cut], n, trivial = njump,njump, sd * the.cohen
  while n <= #v do
    if f(v[n+1])  - f(v[n]) > epsilon and f(v[n]) - cut >= trivial then
      cut = f(v[n])
      cuts[cut] = 0
    else
      cuts[cut] = cuts[cut] + 1 
      row[col]  = cut
    end
    n = n + 1 end 
  return cuts end
