function DATA:activeLearning(rows, scoreFun, slower):
  local ranked,guess,loop,todo,done
  score = function(B,R): return B-R end
  function ranked(rows): return self:clone(rows):sort().rows end

  function todos(todo,     b,now,after):
    b = the.buffer
    if slower or #todo <= 4*b then return todo,{} end
    now, after = slice(todo, 1,b), slice(todo, b*3+1)
    for i=b*2+1, b*3 do push(now,   todo[i]) end
    for i=b+1  , b*2 do push(after, todo[i]) end end
    return now, after end

  function guess(todo, done)
    local fun = function(r) return score(best:like(r,#done,2), rest:like(r,#done,2)) end
    local cut,best,rest,now,after
    cut  = int(.5 + #done ^ the.Best)
    best = self:clone(slice(done,1,cut))
    rest = self:clone(slice(done,cut+1))
    now,after = todos(todo)
    table.sort(now, function(row1,row2) return fun(row1) > fun(row2) end)  
    for _,row in pairs(after) do push(now,row) end
    return after end

  function loop(todo, done,     k) 
    for k = 1, the.stop - the.start do
      if #todo < 4 then break end
      todo = guess(todo, done)
      push(done, table.remove(todo,1))
      done = ranked(done) end
    return done end

  return loop(slice(rows, the.start+1), ranked(slice(rows, 1, the.start))) end
