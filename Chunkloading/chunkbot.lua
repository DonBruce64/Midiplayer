--This program can run on a drone with a chunkloader attached.
--The drone can the be put on a patrol path to keep all chunks loaded.
--Note that with a large enough path, MC may un-load some chunks, so plan accordingly.

local drone = component.list("drone")()
local chunkloader = component.list("chunkloader")()

--How high to fly before zeroing coords.
local patrolHeight = 3
--Coord list for patrol.  Should be area endpoints.
--0,0,0 is the base for the robot where it charges.
local coordList = {}
coordList[1] = {x=0, y=0, z=0}
coordList[2] = {x=-12, y=0, z=0}
coordList[3] = {x=-12, y=1, z=0}
coordList[4] = {x=-30, y=1, z=0}
coordList[5] = {x=-12, y=1, z=0}
coordList[6] = {x=-12, y=0, z=0}

local xPos = 0
local yPos = 0
local zPos = 0

if not chunkloader then
  return
else
	component.invoke(chunkloader, "setActive", true)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)
component.invoke(drone, "move", 0, patrolHeight, 0)

while true do
	for _, coords in ipairs(coordList) do
		local deltaX = coords.x - xPos
		local deltaY = coords.y - yPos
		local deltaZ = coords.z - zPos
		component.invoke(drone, "move", deltaX, deltaY, deltaZ)
		xPos = xPos + deltaX
		yPos = yPos + deltaY
		zPos = zPos + deltaZ
		repeat until component.invoke(drone, "getOffset") < 1 and component.invoke(drone, "getVelocity") < 0.1
		if xPos == 0 and yPos == 0 and zPos==0 and computer.energy() < computer.maxEnergy()*0.25 then
			repeat computer.pullSignal(0.1) until computer.energy() > computer.maxEnergy()*0.95
		end
	end
end