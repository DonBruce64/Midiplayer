--Basic robot harvesting program.
--Runs two different routes, selectable by placing items in primary slot during boot.
--Designed to harvest melons as they can be used in ethanol, and their seeds can be
--auto-crafted and turned into plant oil.  These can be turned into biodiesel.

local robot = component.list("robot")()
local redstone = component.list("redstone")()
local rightRoom = component.invoke(robot, "count") > 0

local function forward(numberMoves)
	repeat
		if component.invoke(robot, "move", 3) then
			numberMoves = numberMoves - 1
			computer.beep(1000,0.25)
		end
	until numberMoves==0
end

local function goToHarvestStart()
	forward(4)
	component.invoke(robot, "move", 1)
	forward(1)
	component.invoke(robot, "turn", false)
	if rightRoom then
		forward(4)
	else
		forward(2)
	end
	component.invoke(robot, "turn", true)
	--Clear out any extra redstone events.
	repeat until not computer.pullSignal(1)
end

local function harvestLine()
	for i=1,12 do
		component.invoke(robot, "swing", 0)
		forward(1)
	end
	component.invoke(robot, "swing", 0)
end

local function lineTurn(rearOfRoom)
	component.invoke(robot, "turn", rearOfRoom)
	forward(2)
	component.invoke(robot, "turn", rearOfRoom)
end

local function goBackToBase()
	component.invoke(robot, "turn", true)
	if rightRoom then
		forward(2)
	else
		forward(4)
	end
	component.invoke(robot, "turn", false)
	forward(1)
	component.invoke(robot, "move", 0)
	forward(4)
end

local function dropMelons()
	for i=1,16 do
		component.invoke(robot, "select", i)
		component.invoke(robot, "drop", 3)
	end
end

if not redstone then
	return
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat
	if computer.pullSignal() == "redstone_changed" then
		goToHarvestStart()
		harvestLine()
		lineTurn(true)
		harvestLine()
		lineTurn(false)
		harvestLine()
		lineTurn(true)
		harvestLine()
		goBackToBase()
		dropMelons()
		component.invoke(robot, "turn", true)
		component.invoke(robot, "turn", true)
	end
until false