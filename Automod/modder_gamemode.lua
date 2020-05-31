--This modder program watches players and changes their gamemode when they change dimensions.
--Specific gamemodes are set in the global variables.
--Also present is a default gamemode.  Use this for new dims or if most gamemodes are this.
--A dynamic lookup is not used to allow the program to be self-contained.
--This is done this way so you can put the program into microcontrollers.

local worldData = component.list("debug")()
local playerDims = {}
local dimGamemodes = {[-1]="0", [0]="2", [1]="0", [2]="1", [3]="1", [4]="0", [5]="0"}
local defaultGamemode = "1"

assert(worldData, "Missing debug card!")
computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
  for _, playerName in ipairs(component.invoke(worldData, "getPlayers")) do
		local playerObj = component.invoke(worldData, "getPlayer", playerName)
		local world = playerObj.getWorld()
		if world then
			local dimID = world.getDimensionId()
			if playerDims[playerName] ~= dimID then
				playerDims[playerName] = dimID
				computer.beep(750, 0.1)
				if dimGamemodes[dimID] then
					component.invoke(worldData, "runCommand", "/gamemode " .. dimGamemodes[dimID] .. " " .. playerName)
				else
					component.invoke(worldData, "runCommand", "/gamemode " .. tostring(defaultGamemode) .. " " .. playerName)
				end
			end
		end
  end
end
