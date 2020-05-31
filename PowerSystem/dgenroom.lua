--Program to control refinery biodiesel production and power generation.
--This program is hooked up to two refineries that feed into a centeral tank.
--This tank stores fluid for one or more generators.
--These generators are powered via microcontrollers that get packets to turn on when power is low.
--Power is stored in three HV capacitors, and useage is monitored via a transformer.
--This allows for estimated time-to-empty data, should the system not have biodiesel.
--All functions send packets out on the network to interface with the powersystem.lua program.

local refineryList = component.list("ie_refinery")
local batteryList = component.list("ie_hv_capacitor")
local currentSensor = component.list("ie_current_transformer")()
local modem = component.list("modem")()
local redstone = component.list("redstone")()
local restoneOff = 0
local redstoneOn = 15
local dgenStartupPower = 1000000
local dgenShutoffPower = 7000000

local genPacketPort = 110
local refineryPacketPorts = {[1]=111, [2]=112}
local powerUsagePacketPort = 113
local batteryLevelPacketPorts = {[1]=114, [2]=115, [3]=116}
local timeToEmptyPacketPort = 117
local refineryPackets = {[0]="WORKING", [1]="FULL", [3]="!INPUT!", [4]="!POWER!"}

local function setRedstone(status)
	for i=0,5 do
		component.invoke(redstone, "setOutput", i, status)
	end
end

local function sendGeneratorSignal(active)
	component.invoke(modem, "broadcast", genPacketPort, active)
	if redstone then
		if active then
			setRedstone(restoneOff)
		else
			setRedstone(redstoneOn)
		end
	end
end

local function sendRefineryStatus(refineryNum, status)
	component.invoke(modem, "broadcast", refineryPacketPorts[refineryNum], refineryPackets[status])
end

local function updatePowerSystemStatus()
	local energyFlow = component.invoke(currentSensor, "getAvgEnergy")
	component.invoke(modem, "broadcast", powerUsagePacketPort, tostring(energyFlow))
	
	local totalEnergy = 0
	local battery = 1
	for batt, _ in pairs(batteryList) do
		local battEnergy = component.invoke(batt, "getEnergyStored")
		component.invoke(modem, "broadcast", batteryLevelPacketPorts[battery], tostring(battEnergy))
		totalEnergy = totalEnergy + battEnergy
		battery = battery + 1
	end
	component.invoke(modem, "broadcast", timeToEmptyPacketPort, tostring(math.floor(totalEnergy/(energyFlow*20*60))))
	return totalEnergy
end

local function updateGeneratorSystem(totalEnergy)
	computer.beep(500,0.01)
	if totalEnergy < dgenStartupPower then
		sendGeneratorSignal(true)
	elseif totalEnergy > dgenShutoffPower then
		sendGeneratorSignal(false)
	end
end

local function sendRefineryStatuses()
	local refineryNum = 1
	for ref, _ in pairs(refineryList) do
		computer.beep(750,0.01)
		if component.invoke(ref, "getEnergyStored") == 0 then
			sendRefineryStatus(refineryNum, 4)
		elseif component.invoke(ref, "getOutputTank").amount > component.invoke(ref, "getOutputTank").capacity*0.9 then
			sendRefineryStatus(refineryNum, 1)
		else
			local tankData = component.invoke(ref, "getInputFluidTanks")
			if tankData.input1.amount == 0 or tankData.input2.amount == 0 then
				sendRefineryStatus(refineryNum, 3)
			else
				sendRefineryStatus(refineryNum, 0)
			end
		end
		refineryNum = refineryNum + 1
	end
end

if not refineryList then
	return
elseif not modem then
	computer.beep(1000,0.25)
  return
elseif not batteryList or not currentSensor then
	computer.beep(1000,0.25)
	computer.beep(1000,0.25)
  return
else
	sendGeneratorSignal(false)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat computer.pullSignal(5)
	local totalEnergy = updatePowerSystemStatus()
	updateGeneratorSystem(totalEnergy)
	sendRefineryStatuses()
until false