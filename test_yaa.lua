print "testing yet another auction"

local yaa   = require "yaa"
-- local utils = require "utils" -- included third party print_r

math.randomseed(os.time())

local default_countries = {'ru', 'de', 'uk', 'fr', 'us'}

local function mk_creatives(arg)
  local max_advertisers = arg.advertisers or 20
  local max_creatives   = arg.creatives or 50
  local max_price       = arg.price or 10
  local countries       = arg.countries or default_countries
  local max_countries   = #countries + 1
  local creatives       = {}
  for i = 1, max_creatives do
    local c = math.random(1, max_countries)
    local props = {client = math.random(1, max_advertisers)
                  ,price  = math.random(1, max_price)
                  ,area   = countries[c]}
    if arg.anything then
      creatives["string" .. i] = props
    else
      table.insert(creatives, props)
    end
  end
  return creatives
end

local creatives, max_winners, winners, client1, client2,
      creative1, creative2, limit, border

print "testing creatives should be valid"

creatives = mk_creatives{}
table.insert(creatives, {client = 1
                        ,price  = "highest"})
max_winners = 10

assert(not pcall(yaa.auction, creatives, max_winners))

print "testing win creatives with the highest price"

creatives = mk_creatives{anything = true} -- creatives may be string

client1 = 21
creative1 = {} -- creatives may be table
creatives[creative1] = {client = client1
                       ,price  = 12}
client2 = 22
creative2 = #creatives + 1
creatives[creative2] = {client = client2
                       ,price  = 11}
max_winners = 1
winners = yaa.auction(creatives, max_winners)

assert(winners[creative1].client == client1)

max_winners = 2
winners = yaa.auction(creatives, max_winners)

assert(winners[creative1].client == client1)
assert(winners[creative2].client == client2)

print "testing all winners must have unique advertiser id"

creatives = mk_creatives{}
max_winners = 20
winners = yaa.auction(creatives, max_winners)
local tw = {}
local unique = true

for _,props in pairs(winners) do
  local advertiser = props.client
  if tw[advertiser] then
    unique = false
    break
  else
    tw[advertiser] = true
  end
end

assert(unique)

print "testing if third argument (country) is provided, then only"
print "        creatives without country or creatives with same"
print "        country can be among winners"

creatives = mk_creatives{}
max_winners = 20
local i = math.random(1, #default_countries)  -- country can't be nil
local country = default_countries[i]
winners = yaa.auction(creatives, max_winners, country)
local match = true

for _,props in pairs(winners) do
  local area = props.area
  if area and country ~= area then
    match = false
    break
  end
end

assert(match)

print "testing function should not give preference to any of equal by"
print "        price creatives, but should return such creatives"
print "        equiprobable"

creatives = mk_creatives{}
local client = 21
table.insert(creatives, {client = client
                        ,price  = 11})
table.insert(creatives, {client = client
                        ,price  = 11})
table.insert(creatives, {client = client
                        ,price  = 11})
max_winners = 10

limit = 1000
border = 275
local tb = {}
for i = 1, limit do
  winners = yaa.auction(creatives, max_winners)
  for item,props in pairs(winners) do
    if client == props.client then
      if tb[item] then tb[item] = tb[item] + 1 else tb[item] = 1 end
    end
  end
end

for _,count in pairs(tb) do
  assert(count > border)
end

creatives = mk_creatives{}
client1 = 21
creative1 = #creatives + 1
creatives[creative1] = {client = client1
                       ,price  = 11}
client2 = 22
creative2 = #creatives + 1
creatives[creative2] = {client = client2
                       ,price  = 11}
max_winners = 1

limit = 1000
border = 400
local tc = {}
for i = 1, limit do
  winners = yaa.auction(creatives, max_winners)
  for _,props in pairs(winners) do
    local client = props.client
    if tc[client] then
      tc[client] = tc[client] + 1
    else
      tc[client] = 1
    end
  end
end

for _,count in pairs(tc) do
  assert(count > border)
end

------------------------------------------------------------------------

local noc = 1000
creatives = mk_creatives{creatives = noc}
max_winners = 6

limit = 1000
local x = os.clock()
for i = 1, limit do
  yaa.auction(creatives, max_winners)
end

print(string.format("info %d iterations search %d winners among %d \z
                    creatives took %.2f sec"
                   ,limit
                   ,max_winners
                   ,noc
                   ,os.clock() - x))

------------------------------------------------------------------------

print "OK"
