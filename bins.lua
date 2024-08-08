the={cohen=0.35}

function stats(rows,fun,    val,n) 
  val = function(x) return x=="?" and -1E32 or x end
  table.sort(rows, function(row1,row2) return val(fun(row1)) < val(fun(row2)) end)
  for i,row in pairs(rows) do
    if i ~= "?" then
      n = (#t - i) // 10
      return i, rows, fun(rows[i]), funs(rows[#rows]), \
                fun(rows[i+5*n]),  (fun(rows[i+9*n]) - fun(row[i+n])) / 2.56 end
 
function stats.cuts(rows, x)
    local cut,bins,njump,trivial,n,epsilon
    n,rows,lo,hi,mid,sd  = stats(rows)
    epsilon = (hi - lo) / 100
    cut,bins,njump =  t[n], {}, (#t -n)/(the.bins - 1) // 1
    bins[cut], n, trivial = njump,njump, stats.sd(t) * the.cohen
    while n <= #t  - numb do
      if  t[n+1]  - t[n] > epsilon and t[n] - cut >= trivial then
         cut = t[n]
         bins[cut] = njump
         n = n + njump
      else
         bins[cut] = bins[cut] + 1
         n = n + 1 end end
    return bins end
