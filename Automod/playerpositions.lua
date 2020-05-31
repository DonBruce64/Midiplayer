--Writes player postions to screen.
--This program only updates positions when the computer gets an event (e.g. screen click).
--Useful for tracking players down in worlds via tablets without causing excess server TPS loss.

local gpu = component.list("gpu")()
local screen = component.list("screen")()
local worldData = component.list("debug")()

local function drawEntry(x, y, entry, totalLength)
  local length = string.len(entry)
  if length > totalLength then
    entry = string.sub(entry, 1, totalLength)
  end
  component.invoke(gpu, "set", x, y, entry)
  component.invoke(gpu, "fill", x + length, y, totalLength - length, 1, " ")
end

local function drawScreen()
  component.invoke(gpu, "bind", screen)
  component.invoke(gpu, "setResolution", 80, 25)
  component.invoke(gpu, "fill", 1, 1, 80, 25, " ")
  component.invoke(gpu, "set", 1, 1, "Player Name:        Dimension:     Gate#:        X:         Y:        Z:")
  for num, player in ipairs(component.invoke(worldData, "getPlayers")) do
    local world = component.invoke(worldData, "getPlayer", player).getWorld()
    local x, y, z = component.invoke(worldData, "getPlayer", player).getPosition()
    drawEntry(1, 1 + num, player, 20)
    drawEntry(21, 1 + num, world.getDimensionName(), 15)
    if world.getDimensionId() > 1 then
      drawEntry(36, 1 + num, tostring(world.getDimensionId() - 1), 2)
    end
    drawEntry(51, 1 + num, tostring(x), 7)
    drawEntry(61, 1 + num, tostring(y), 7)
    drawEntry(71, 1 + num, tostring(z), 7)
  end
end

if not gpu then
  return
elseif not screen then
  computer.beep(1000,0.25)
  return
elseif not worldData then
  computer.beep(1000,0.25)
  computer.beep(1000,0.25)
  return
end

drawScreen()
computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
  computer.pullSignal()
  drawScreen()
end