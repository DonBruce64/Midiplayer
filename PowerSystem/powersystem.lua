--Main display screen for power system.
--Does not directly control any sytstems, as centeral control can fail
--due to chunk loading issues.  Instead, it gets packets from sub-control
--systems and displays their status on the attached screen.
--See melonroom.lua and dgenroom.lua for details.

local gpu = component.list("gpu")()
local screen = component.list("screen")()
local modem = component.list("modem")()

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
	drawLine(01, 1, "╔═══════════════╤══COMPTROLLER®══╤═══════════════╗")
	drawLine(02, 1, "║  D-GEN ROOM   │  MELON ROOM    │  POWER BANK   ║")
	drawLine(03, 1, "║               │                │               ║")
	drawLine(04, 1, "║GENERATOR #1   │PLANT OIL GEN   │SYSTEM LOAD    ║")
	drawLine(05, 1, "║STATUS:        │STATUS:         │RF/T:          ║")
	drawLine(06, 1, "║               │SILO FEED:      │               ║")
	drawLine(07, 1, "║GENERATOR #2   │                │BATT BANK #1   ║")
	drawLine(08, 1, "║STATUS:        │ETHANOL GEN     │RF:            ║")
	drawLine(09, 1, "║               │STATUS:         │               ║")
	drawLine(10, 1, "║REFINERY #1    │SILO FEED:      │BATT BANK #2   ║")
	drawLine(11, 1, "║STATUS:        │                │RF:            ║")
	drawLine(12, 1, "║               │                │               ║")
	drawLine(13, 1, "║REFINERY #2    │                │TIME TO EMPTY  ║")
	drawLine(14, 1, "║STATUS:        │                │MINUTES:       ║")
	drawLine(15, 1, "║               │                │               ║")
	drawLine(16, 1, "╚════════COMPUTER-CONTROLLED POWER SYSTEM════════╝")
end

if not gpu or not screen then
	return
elseif not modem then
	computer.beep(1000,0.25)
  return
else
  component.invoke(gpu, "bind", screen)
	component.invoke(gpu, "setResolution", 50, 16)
	for i=110,120 do
		component.invoke(modem, "open", i)
	end
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

drawBackground()
repeat
	local signalName, _, _, port, _, data = computer.pullSignal()
	if signalName == "modem_message" then
		if port == 110 then
			if data then
				drawPaddedLine(5, 9, "ON", 7)
				drawPaddedLine(8, 9, "ON", 7)
			else
				drawPaddedLine(5, 9, "OFF", 7)
				drawPaddedLine(8, 9, "OFF", 7)
			end
		elseif port == 111 then
			drawPaddedLine(11, 9, data, 7)
		elseif port == 112 then
			drawPaddedLine(14, 9, data, 7)
		elseif port == 113 then
			drawPaddedLine(5, 41, data, 8)
		elseif port == 114 then
			drawPaddedLine(8, 39, data, 7)
		elseif port == 115 then
			drawPaddedLine(11, 39, data, 7)
		elseif port == 117 then
			drawPaddedLine(14, 44, data, 6)
		elseif port == 118 then		
			drawPaddedLine(5, 25, data, 7)
			if data == "WORKING" then
				drawPaddedLine(6, 28, "ON", 5)
			elseif data == "!INPUT!" then
				drawPaddedLine(6, 28, "EMPTY",5)
			else
				drawPaddedLine(6, 28, "OFF", 5)
			end
		elseif port == 119 then
			drawPaddedLine(9, 25, data, 7)
			if data == "WORKING" then
				drawPaddedLine(10, 28, "ON", 5)
			elseif data == "!INPUT!" then
				drawPaddedLine(10, 28, "EMPTY",5)
			else
				drawPaddedLine(10, 28, "OFF", 5)
			end
		end
	end
until false