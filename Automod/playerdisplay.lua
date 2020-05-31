--This program writes a list of players and the dimensions they are in to an attached screen.
--Just like an airport monitor!

local worldData = component.list("debug")()
local gpu = component.list("gpu")()
local screen = component.list("screen")()
local updateFrequency = 5
local rowOffset = 2
local numRows = 12
local numCols = 40
local dimNameColOffset = 20
local gateNumColOffset = 35

local function drawEntry(x, y, entry, totalLength)
	local length = string.len(entry)
	if length > totalLength then
		entry = string.sub(entry, 1, totalLength)
	end
	component.invoke(gpu, "set", x, y, entry)
end

assert(worldData, "Missing debug card!")
assert(gpu, "Missing GPU!")
assert(screen, "Missing screen!")
component.invoke(gpu, "bind", screen)
component.invoke(gpu, "setResolution", numCols, numRows)
component.invoke(gpu, "fill", 1, 1, numCols, numRows, " ")
component.invoke(gpu, "set", 1, 1, "Player Name:        Dimension:    Gate#:")

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
	computer.pullSignal(updateFrequency)
	component.invoke(gpu, "fill", 1, rowOffset, numCols, numRows, " ")
	local lineNum = rowOffset
	for _, playerName in ipairs(component.invoke(worldData, "getPlayers")) do
		drawEntry(1, lineNum, playerName, dimNameColOffset)
		local world = component.invoke(worldData, "getPlayer", playerName).getWorld()
		if world then
			drawEntry(dimNameColOffset + 1, lineNum, world.getDimensionName(), gateNumColOffset - dimNameColOffset)
			if world.getDimensionId() ~= -1 then
				drawEntry(gateNumColOffset, lineNum, tostring(world.getDimensionId() - 1), 5)
			else
				drawEntry(gateNumColOffset, lineNum, "5.5", 5)
			end
		end
		lineNum = lineNum + 1
	end
end