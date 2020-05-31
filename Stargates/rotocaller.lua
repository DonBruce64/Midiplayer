--Graphical program used to dial stargates like a phone.
--Much like phone, it will sound a busy signal if the stargate dialed is already connected.
--Entering an invalid stargate will cause an invalid number sequence to be played.
--If the stargate doesn't have enough energy, a bad line tone is played.
--Note that this program will only dial numbers that the sgdatasystem.lua program has
--in its database.  This prevents it from dialing gates that should be normally off-limits.

local gpu = component.list("gpu")()
local screen = component.list("screen")()
local stargate = component.list("stargate")()
local doorLock = component.list("redstone")()
local beeper = component.list("beep")()
local modem = component.list("modem")()

local awaitingNumbers = false
local timeoutTime = 0
local numberToDial = ""
local numberTones = {[0]={[941]=0.5, [1336]=0.5}, [1]={[697]=0.5, [1209]=0.5}, [2]={[697]=0.5, [1336]=0.5}, [3]={[697]=0.5, [1477]=0.5}, [4]={[770]=0.5, [1209]=0.5}, [5]={[770]=0.5, [1336]=0.5}, [6]={[770]=0.5, [1477]=0.5}, [7]={[852]=0.5, [1209]=0.5}, [8]={[852]=0.5, [1336]=0.5}, [9]={[852]=0.5, [1477]=0.5}}

local function waitForSignal()
	if awaitingNumbers and numberToDial:len() == 0 then
		component.invoke(beeper, "beep", {[480]=1, [620]=1})
		return computer.pullSignal(1)
	elseif component.invoke(stargate, "stargateState") == "Dialling" then
		component.invoke(beeper, "beep", {[440]=0.5, [480]=0.5})
		return computer.pullSignal()
	elseif component.invoke(stargate, "stargateState") == "Connected" then
		return computer.pullSignal(timeoutTime - computer.uptime())
	else
		return computer.pullSignal()
	end
end

local function setDoorLock(locked)
	for i=0,5 do
		if locked then
			component.invoke(doorLock, "setOutput", i, 15)
		else
			component.invoke(doorLock, "setOutput", i, 0)
		end
	end
end

local function addNumber(number)
	if numberToDial:len() < 10 then
		numberToDial = numberToDial .. tostring(number)
		component.invoke(beeper, "beep", numberTones[number])
	end
end

local function getNumberFromCoords(row, col)
	if col >= 20 and col <= 26 then
		if row >= 2 and row <= 4 then
			addNumber(1)
		elseif row >= 6 and row <= 8 then
			addNumber(4)
		elseif row >= 10 and row <= 12 then
			addNumber(7)
		end
	elseif col >= 30 and col <= 36 then
		if row >= 2 and row <= 4 then
			addNumber(2)
		elseif row >= 6 and row <= 8 then
			addNumber(5)
		elseif row >= 10 and row <= 12 then
			addNumber(8)
		elseif row >= 13 and row <= 15 then
			addNumber(0)
		end
	elseif col >= 40 and col <= 46 then
		if row >= 2 and row <= 4 then
			addNumber(3)
		elseif row >= 6 and row <= 8 then
			addNumber(6)
		elseif row >= 10 and row <= 12 then
			addNumber(9)
		end
	end
end

local function performDial(stargateToDial)
	local result, text = component.invoke(stargate, "dial", stargateToDial)
	if not result then
		if text:find("busy") then
			for i=1,5 do
				component.invoke(beeper, "beep", {[480]=0.5, [620]=0.5})
				computer.pullSignal(1)
			end
		elseif component.invoke(stargate, "energyToDial", stargateToDial) > component.invoke(stargate, "energyAvailable") then
			for i=1,10 do
				component.invoke(beeper, "beep", {[480]=0.25, [620]=0.25})
				computer.pullSignal(0.5)
			end
		end
	else
		timeoutTime = computer.uptime() + 35
	end
end

local function dialGate()
	component.invoke(modem, "broadcast", 102, numberToDial)
	local stargateToDial
	timeoutTime = computer.uptime() + 3
	repeat 
		local signalName, _, _, _, _, hostGate, remoteGate = computer.pullSignal(timeoutTime - computer.uptime())
		if signalName == "modem_message" then
			if numberToDial == hostGate then
				stargateToDial = remoteGate
			end
		end
	until stargateToDial or computer.uptime() >= timeoutTime
	
	if not stargateToDial then
		component.invoke(beeper, "beep", {[950]=0.330})
		computer.pullSignal(0.36)
		component.invoke(beeper, "beep", {[1400]=0.330})
		computer.pullSignal(0.36)
		component.invoke(beeper, "beep", {[1800]=0.330})
	else
		performDial(stargateToDial)
	end
end

local function disconnectGate()
	component.invoke(stargate, "disconnect")
	numberToDial = ""
	timeoutTime = 0
	awaitingNumbers = false
end

local function drawLine(row, col, text)
	component.invoke(gpu, "set", col, row, text)
end

local function drawPaddedLine(row, col, text, minSize)
	while text:len() < minSize do
		text = text .. " "
	end
	drawLine(row, col, text)
end

local function drawBackground()
	component.invoke(gpu, "fill", 1, 1, 50, 16, " ")
	drawLine(01, 1, "╔═══════════════╤══ROTO-CALLER®══════════════════╗")
	drawLine(02, 1, "║ ┌──NUMBER──┐  │  ┌──1──┐   ┌──2──┐   ┌──3──┐   ║")
	drawLine(03, 1, "║ │          │  │  │     │   │ ABC │   │ DEF │   ║")
	drawLine(04, 1, "║ └──────────┘  │  └─────┘   └─────┘   └─────┘   ║")
	drawLine(05, 1, "║               │                                ║")
	drawLine(06, 1, "║               │  ┌──4──┐   ┌──5──┐   ┌──6──┐   ║")
	drawLine(07, 1, "║ ┌──────────┐  │  │ GHI │   │ JKL │   │ MNO │   ║")
	drawLine(08, 1, "║ │  ENTER # │  │  └─────┘   └─────┘   └─────┘   ║")
	drawLine(09, 1, "║ └──────────┘  │                                ║")
	drawLine(10, 1, "║ ┌──────────┐  │  ┌──7──┐   ┌──8──┐   ┌──9──┐   ║")
	drawLine(11, 1, "║ │  DIAL  # │  │  │ PQRS│   │ TUV │   │ WXYZ│   ║")
	drawLine(12, 1, "║ └──────────┘  │  └─────┘   └─────┘   └─────┘   ║")
	drawLine(13, 1, "║ ┌──────────┐  │            ┌──0──┐             ║")
	drawLine(14, 1, "║ │ HANG  UP │  │            │     │             ║")
	drawLine(15, 1, "║ └──────────┘  │            └─────┘             ║")
	drawLine(16, 1, "╚═══════COMPUTER-CONTROLLED DIALING SYSTEM═══════╝")
end

if not gpu or not screen then
  return
elseif not doorLock then
  computer.beep(1000,0.25)
  return
elseif not modem or not beeper then
	computer.beep(1000,0.25)
	computer.beep(1000,0.25)
  return
elseif not stargate then
	computer.beep(1000,0.25)
	computer.beep(1000,0.25)
	computer.beep(1000,0.25)
  return
else
	component.invoke(modem, "open", 103)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)
drawBackground()

while true do
	local signalName, addr, col, row, _, hostGate, remoteGate = waitForSignal()
	if signalName == "touch" then
		if col >= 3 and col <= 14 then
			if row >= 7 and row <= 9 then
				awaitingNumbers = true
			elseif row >= 10 and row <= 12 then
				if component.invoke(stargate, "stargateState") == "Idle" and numberToDial:len() > 0 then
					dialGate()
				end
			elseif row >= 13 and row <= 15 then
				disconnectGate()
			end
		elseif awaitingNumbers then
			local numberToAdd = getNumberFromCoords(row, col)
			if numberToAdd then
				addNumber(numberToAdd)
			end
		end
	elseif signalName == "sgStargateStateChange" then
		setDoorLock(component.invoke(stargate, "stargateState") ~= "Idle")
	elseif signalName == "modem_message" then
		if tonumber(hostGate) then
			performDial(remoteGate)
		end
	elseif timeoutTime > 0 then
		if computer.uptime() >= timeoutTime then
			disconnectGate()
		end
	end
	drawPaddedLine(3, 4, numberToDial, 10)
end