-- Common functions

local tremove = table.remove
local sqrt = math.sqrt

-- Partitioning

local path = (...):match("(.-)[^%.]+$")
local quad = require(path.."quad")
local qinsert = quad.insert
local qremove = quad.remove
local qrange = quad.selectRange
local qselect = quad.select

-- Collisions

local shape = require(path.."shapes")
local screate = shape.create
local sarea = shape.area
local sbounds = shape.bounds
local stranslate = shape.translate
local stest = shape.test

-- Internal data

-- list of shapes
local statics = {}
local dynamics = {}
local kinematics = {}

-- global gravity
local gravityx = 0
local gravityy = 0
-- positional correction
-- treshold between 0.01 and 0.1
--local slop = 0.01
-- correction between 0.2 to 0.8
--local percentage = 0.2

-- maximum velocity limit of moving shapes
local maxVelocity = 1000
-- broad phase partitioning
local partition = false
-- buffer reused in queries
local buffer = {}
-- some stats
local nchecks = 0

-- Internal functionality

-- returns shape index and its list
local function findShape(s)
  local t = s.list
  for i = 1, #t do
    if t[i] == s then
      return i, t
    end
  end
end

-- repartition moved or modified shapes
local function repartition(s)
  if partition then
    -- reinsert in the quadtree
    local x, y, hw, hh = sbounds(s)
    qinsert(s, x, y, hw, hh)
  end
end

local function addShapeType(list, t, ...)
  local func = screate[t]
  assert(func, "invalid shape type")
  local s = func(...)
  s.list = list
  list[#list + 1] = s
  if partition then
    repartition(s)
  end
  return s
end

-- changes the position of a shape
local function changePosition(a, dx, dy)
  stranslate(a, dx, dy)
  if partition then
    repartition(a)
  end
end

-- resolves collisions
local function solveCollision(a, b, nx, ny, pen)
  -- shape a must be dynamic
  --assert(a.list == dynamics, "collision pair error")
  -- relative velocity
  local avx = a.xv
  local avy = a.yv
  local bvx = b.xv or 0
  local bvy = b.yv or 0
  local vx = avx - bvx
  local vy = avy - bvy

  -- penetration component
  -- dot product of the velocity and collision normal
  local ps = vx*nx + vy*ny
  -- objects moving apart?
  if ps > 0 then
    return
  end
  -- restitution [1-2]
  -- r = max(r1, r2)
  local r = a.bounce
  local r2 = b.bounce
  if r2 and r2 > r then
    r = r2
  end
  ps = ps*(r + 1)

  -- tangent component
  local ts = vx*ny - vy*nx
  -- friction [0-1]
  -- r = r/(1/mass1 + 1/mass2)
  local f = a.friction
  local f2 = b.friction
  if f2 and f2 < f then
    f = f2
  end
  ts = ts*f
  
  -- coulomb's law (optional)
  -- clamps the tangent component so that
  -- it doesn't exceed the separation component
  if ts < 0 then
    if ts < ps then
      ts = ps
    end
  elseif -ts < ps then
    ts = -ps
  end

  -- integration
  local jx = nx*ps + ny*ts
  local jy = ny*ps - nx*ts
  -- impulse
  local ma = a.imass
  local mb = b.imass or 0
  local mc = ma + mb
  jx = jx/mc
  jy = jy/mc

  -- adjust the velocity of shape a
  a.xv = avx - jx*ma
  a.yv = avy - jy*ma
  if b.list == dynamics then
    -- adjust the velocity of shape b
    b.xv = bvx + jx*mb
    b.yv = bvy + jy*mb
--[[
    -- positional correction (wip)
    if pen > slop then
      local pc = (pen - slop)/mc*percentage
      local pcA = pc*ma
      local pcB = pc*mb
      local sx, sy = -nx*pcB, -ny*pcB
      -- store the separation for shape b
      b.sx = b.sx + sx
      b.sy = b.sy + sy
      changePosition(b, sx, sy)
      --pen = pen*pcA
      pen = pcA
    end
    ]]
  end

  -- separation
  local sx, sy = nx*pen, ny*pen
  -- store the separation for shape a
  a.sx = a.sx + sx
  a.sy = a.sy + sy
  -- separate the pair by moving shape a
  changePosition(a, sx, sy)
end

-- check and report collisions
local function collision(a, b, dt)
  -- track the number of collision checks (optional)
  nchecks = nchecks + 1
  local nx, ny, pen = stest(a, b, dt)
  if pen == nil then
    return
  end
  --assert(pen > 0, "collision depth error")
  -- collision callbacks
  -- ignores collision if either callback returned false
  local func1 = a.onCollide
  if func1 then
    if func1(a, b, nx, ny, pen) == false then
      return
    end
  end
  local func2 = b.onCollide
  if func2 then
    if func2(b, a, -nx, -ny, pen) == false then
      return
    end
  end
  solveCollision(a, b, nx, ny, pen)
end

-- Public functionality

local fizz = {}

-- updates the simulation
function fizz.update(dt, it)
  it = it or 1
  -- track the number of collision checks (optional)
  nchecks = 0

  -- update velocity vectors
  local xg = gravityx*dt
  local yg = gravityy*dt
  local mv2 = maxVelocity*maxVelocity
  for i = 1, #dynamics do
    local d = dynamics[i]
    -- damping
    local c = 1 + d.damping*dt
    local xv = d.xv/c
    local yv = d.yv/c
    -- gravity
    local g = d.gravity or 1
    xv = xv + xg*g
    yv = yv + yg*g
    -- threshold
    local v2 = xv*xv + yv*yv
    if v2 > mv2 then
      local n = maxVelocity/sqrt(v2)
      xv = xv*n
      yv = yv*n
    end
    d.xv = xv
    d.yv = yv
    -- reset separation
    d.sx = 0
    d.sy = 0
  end
  
  -- iterations
  dt = dt/it
  for j = 1, it do
    -- move kinematic shapes
    for i = 1, #kinematics do
      local k = kinematics[i]
      changePosition(k, k.xv*dt, k.yv*dt)
    end
    -- move dynamic shapes
    if partition then
      -- quadtree partitioning
      for i = 1, #dynamics do
        local d = dynamics[i]
        -- move to new position
        changePosition(d, d.xv*dt, d.yv*dt)
        -- check and resolve collisions
        -- query for potentially colliding shapes
        --local x, y, hw, hh = sbounds(d)
        --qrange(x, y, hw, hh, buffer)
        qselect(d, buffer)
        -- todo: we check/solve each collision pair twice
        for j = #buffer, 1, -1 do
          local d2 = buffer[j]
          if d2 ~= d then
            collision(d, d2, dt)
          end
          -- clear the buffer during iteration
          buffer[j] = nil
        end
      end
      --quad.prune()
    else
      -- brute force
      for i = 1, #dynamics do
        local d = dynamics[i]
        -- move to new position
        changePosition(d, d.xv*dt, d.yv*dt)
        -- check and resolve collisions
        for j = 1, #statics do
          collision(d, statics[j], dt)
        end
        for j = 1, #kinematics do
          collision(d, kinematics[j], dt)
        end
        -- note: we check each collision pair only once
        for j = i + 1, #dynamics do
          collision(d, dynamics[j], dt)
        end
      end
    end
  end
end

-- gets the global gravity
function fizz.getGravity()
  return gravityx, gravityy
end

-- sets the global gravity
function fizz.setGravity(x, y)
  gravityx, gravityy = x, y
end

-- static shapes do not move or respond to collisions
function fizz.addStatic(shape, ...)
  return addShapeType(statics, shape, ...)
end

-- kinematic shapes move only when assigned a velocity
function fizz.addKinematic(shape, ...)
  local s = addShapeType(kinematics, shape, ...)
  s.xv, s.yv = 0, 0
  return s
end

-- dynamic shapes are affected by gravity and collisions
function fizz.addDynamic(shape, ...)
  local s = addShapeType(dynamics, shape, ...)
  s.friction = 1
  s.bounce = 0
  s.damping = 0
  s.gravity = 1
  s.xv, s.yv = 0, 0
  s.sx, s.sy = 0, 0
  fizz.setMass(s, 1)
  return s
end

-- adjusts mass
function fizz.setDensity(s, d)
  local m = sarea(s)*d
  fizz.setMass(s, m)
end

function fizz.setMass(s, m)
  s.mass = m
  local im = 0
  if m > 0 then
    im = 1/m
  end
  s.imass = im
end

-- removes shape from its list
function fizz.removeShape(s)
  local i, t = findShape(s)
  if i then
    s.list = nil
    tremove(t, i)
    qremove(s)
  end
end

-- gets the position of a shape (starting point for line shapes)
function fizz.getPosition(a)
  return a.x, a.y
end

-- sets the position of a shape
function fizz.setPosition(a, x, y)
  changePosition(a, x - a.x, y - a.y)
end

-- gets the velocity of a shape
function fizz.getVelocity(a)
  return a.xv or 0, a.yv or 0
end

-- sets the velocity of a shape
function fizz.setVelocity(a, xv, yv)
  a.xv = xv
  a.yv = yv
end

-- gets the separation of a shape for the last frame
function fizz.getDisplacement(a)
  return a.sx or 0, a.sy or 0
end

-- sets the partitioning method
function fizz.setPartition(p)
  assert(p == true or p == false, "invalid partitioning method")
  partition = p
end

-- gets the partitioning method
function fizz.getPartition()
  return partition
end

-- estimate the number of collision checks
function fizz.getCollisionCount()
  return nchecks
end

-- Public access to some tables

fizz.repartition = repartition
fizz.statics = statics
fizz.dynamics = dynamics
fizz.kinematics = kinematics

return fizz