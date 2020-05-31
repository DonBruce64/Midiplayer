--Program used to control production of melon-based products for use in biodiesel.
--Connects to two silos that are fed by robots running melonbot.lua.
--which are connected via conveyors to a plant oil and ethanol liquifier.
--One silo holds melons, the other holds seeds.  These products are fed into liqifiers.
--The liquifiers are then fed into refineries to power generators.
--Status is sent over the network to a computer running powersystem.lua.

local plantOilGenerator = component.list("ie_squeezer")()
local ethanolGenerator = component.list("ie_fermenter")()
local redstone = component.list("redstone")()
local modem = component.list("modem")()

local plantOilPacketPort = 118
local ethanolPacketPort = 119
local melonSide = 5
local seedSide = 4
local restoneOff = 0
local redstoneOn = 15
local liquifierPackets = {[0]="WORKING", [1]="FULL", [2]="CHOKED", [3]="!INPUT!", [4]="!POWER!"}

local function getLiquiferStatus(liquifier)
	if component.invoke(liquifier, "getEnergyStored") == 0 then
		return 4
	elseif next(component.invoke(liquifier, "getFluid")) then
		local amount = component.invoke(liquifier, "getFluid").amount
		if amount then
			if amount > 2000 then
				return 1
			end
		end
	else
		local stacks = 0
		for i=1,9 do
			if component.invoke(liquifier, "getInputStack", i) then
				stacks = stacks + 1
			end
		end
		if stacks == 0 then
			return 3
		elseif stacks >= 8 then
			return 2
		end
	end
	return 0
end

local function setSiloStatus(siloSide, statusCode)
	if statusCode == 0 or statusCode == 3 then
		component.invoke(redstone, "setOutput", siloSide, redstoneOn)
	else
		component.invoke(redstone, "setOutput", siloSide, restoneOff)
	end
end

local function sendStatusPacket(packetType, statusCode)
	component.invoke(modem, "broadcast", packetType, liquifierPackets[statusCode])
end

if not redstone then
	return
elseif not modem then
	computer.beep(1000,0.25)
  return
elseif not plantOilGenerator or not ethanolGenerator then
	computer.beep(1000,0.25)
	computer.beep(1000,0.25)
  return
else
	component.invoke(redstone, "setOutput", melonSide, restoneOff)
	component.invoke(redstone, "setOutput", seedSide, restoneOff)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat computer.pullSignal(5)
	local plantGenStatus = getLiquiferStatus(plantOilGenerator)
	local ethanolGenStatus = getLiquiferStatus(ethanolGenerator)
	for i=0,plantGenStatus do computer.beep(500,0.01) end
	for i=0,ethanolGenStatus do computer.beep(750,0.01) end
	setSiloStatus(seedSide, plantGenStatus)
	setSiloStatus(melonSide, ethanolGenStatus)
	sendStatusPacket(plantOilPacketPort, plantGenStatus)
	sendStatusPacket(ethanolPacketPort, ethanolGenStatus)
until false