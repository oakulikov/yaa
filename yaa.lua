local utils = require "utils" -- included third party shuffle

--[[
yet another auction, author Oleg Kulikov oakulikov@yandex.ru

module implements a function auction, receiving
   - array of creatives
   - number of winners
   - country name (optional)
and returning winner creatives, obeying the following rules:

1) all winners must have unique advertiser id
2) if third argument (country) is provided, then only creatives without
   country or creatives with same country can be among winners
3*) function should not give preference to any of equal by price
    creatives, but should return such creatives equiprobable.

* function calls with same input, output results may be different.
--]]

local function new(item, props)
  local items = {}
  items[props.client] = {item}
  return {price   = props.price
         ,clients = {props.client}
         ,items   = items}
end

local function insert(head, item, props)
  if not head then return new(item, props) end
  local client = props.client
  local price  = props.price
  if price > head.price then
    local new_head = new(item, props)
    new_head.next = head
    return new_head -- highest price always ahead
  elseif price == head.price then
    local items = head.items[client]
    if items then
      items[#items+1] = item
    else
      local i = #head.clients + 1
      head.clients[i] = client
      head.items[client] = {item}
    end
    return head
  end
  if head.next then
    if price > head.next.price then
      local new_next = new(item, props)
      new_next.next = head.next
      head.next = new_next
    else
      insert(head.next, item, props)
    end
  else
    head.next = new(item, props)
  end
  return head
end

local function choose(head, amount)
  local chosen = {}
  local tc = {}
  while head do
    local clients = {}
    for _,client in pairs(head.clients) do
      if not tc[client] then
        clients[#clients+1] = client
        tc[client] = true
      end
    end
    if #chosen + #clients > amount then utils.shuffle(clients) end
    for _,client in ipairs(clients) do
      local items = head.items[client]
      local i = 1
      if #items > 1 then
        i = math.random(1, #items)
      end
      chosen[#chosen+1] = items[i]
      if #chosen >= amount then return chosen end
    end
    head = head.next
  end
  return chosen
end

--[[
Function auction receiving array* of creatives and returning winner
creatives

items  - creatives
amount - number of winners
area   - country name (optional)

Example
creatives = {{client = 1, price = 10}
            ,{client = 5, price = 17}
            ,{client = 4, price = 9}}
call:
auction(creatives, 1)
output:
{[2] = {client = 5, price = 17}}

Usually when you run a program that uses auction,
you need to call math.randomseed

* The array can be a hash, with arbitrary unique keys within the array
--]]
local function auction(items, amount, area)
  if amount <= 0 or type(items) ~= "table" then
    return {}
  end
  area = area or nil
  local head = nil
  local tc = {}
  for item,props in pairs(items) do
    if not area or not props.area or area == props.area then
      local client = props.client
      if not tc[client] or props.price >= tc[client] then
        tc[client] = props.price
        head = insert(head, item, props)
      end
    end
  end
  local choosen = choose(head, amount)
  local winners = {}
  for _,winner in pairs(choosen) do
    winners[winner] = items[winner]
  end
  return winners
end

return {
  auction = auction
}
