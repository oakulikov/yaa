local function print_r (t, indent)
  local indent=indent or ''
  for key,value in pairs(t) do
    io.write(indent,'[',tostring(key),']')
    if type(value)=="table" then io.write(':\n') print_r(value,indent..'\t')
    else io.write(' = ',tostring(value),'\n') end
  end
end

local function shuffle(t)
  local j
  for i = #t, 2, -1 do
    j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

return {
  print_r = print_r,
  shuffle = shuffle
}
