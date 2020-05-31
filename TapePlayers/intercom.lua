--A graphical tape-playing system.
--Displays tape name and position, and has various controls for tape opration.
--Can also be set to loop, which allows for the tape to function as
--a background music system.  It's like a modern Seeburg!

local gpu = component.list("gpu")()
local screen = component.list("screen")()
local tape = component.list("tape_drive")()

local tapeInserted = false
local songDuration = 0
local tapePos = 0
local volume = 1.0
local speed = 1.0

local function setTapeDuration()
	component.invoke(gpu, "fill", 1, 1, 32, 16, " ")
	component.invoke(gpu, "set", 1, 1, "Please enter the song duration  ")
	component.invoke(gpu, "set", 1, 2, "in seconds.  This is how long   ")
	component.invoke(gpu, "set", 1, 3, "the tape should play before     ")
	component.invoke(gpu, "set", 1, 4, "rewinding to start:             ")

	local inputString = ""
	local hitEnter = false
	repeat
		local event, _, keypress = computer.pullSignal()
		if event == "key_down" then
			if keypress == 13 then
				hitEnter = true
			elseif keypress >= 48 and keypress <= 57 then
				component.invoke(gpu, "set", 20 + inputString:len(), 4, tostring(keypress - 48))
				inputString = inputString .. tostring(keypress - 48)
			end
		end
	until hitEnter
	songDuration = tonumber(inputString)
end

local function drawLine(row, col, text)
	component.invoke(gpu, "set", col, row, text)
end

local function drawGUI()
	component.invoke(gpu, "fill", 1, 1, 32, 16, " ")
	drawLine(01, 1, "╔════MAGNATRON® TAPE SYSTEMS═══╗")
	drawLine(02, 1, "║ STATUS:                      ║")
	drawLine(03, 1, "║ NAME:                        ║")
	drawLine(04, 1, "║ LENGTH:                      ║")
	drawLine(05, 1, "║ TIME:                        ║")
	drawLine(06, 1, "║          ┌──────────┐        ║")
	drawLine(07, 1, "║VOLUME 0% │          │ 100%   ║")
	drawLine(08, 1, "║          └──────────┘        ║")
	drawLine(09, 1, "║          ┌──────────┐        ║")
	drawLine(10, 1, "║SPEED 0.5 │          │ 2.0    ║")
	drawLine(11, 1, "║          └──────────┘        ║")
	drawLine(12, 1, "║1=Play, 2=Stop, 3=Set Duration║")
	drawLine(13, 1, "║4=Volume down,  5=Volume up,  ║")
	drawLine(14, 1, "║6=Speed down,   7=Speed up    ║")
	drawLine(15, 1, "║8=Seek back,    9=Seek forward║")
	drawLine(16, 1, "╚═══MAGNATRON® TAPE SYSTEMS════╝")
	
	if component.invoke(tape, "isReady") then
		tapeInserted = true
		drawLine(02, 11, component.invoke(tape, "getState"))
		local tapeName = component.invoke(tape, "getLabel")
		if tapeName:len() > 20 then
			drawLine(03, 11, tapeName:sub(1, 20))
		else
			drawLine(03, 11, tapeName)
		end
	else
		tapeInserted = false
		drawLine(02, 11, "NO TAPE INSERTED")
	end
	drawLine(04, 11, tostring(songDuration))
	--05 Time is updated in main loop.
	for i=0,volume*10 do
		drawLine(06, 13 + i, "▄")
		drawLine(07, 13 + i, "█")
		drawLine(08, 13 + i, "▀")
	end
	for i=0,(speed- 0.5)*10 do
		drawLine(09, 13 + i, "▄")
		drawLine(10, 13 + i, "█")
		drawLine(11, 13 + i, "▀")
	end
end

local function startTape()
	component.invoke(tape, "stop")
	component.invoke(tape, "seek", -component.invoke(tape, "getSize"))
	component.invoke(tape, "play")
	tapePos = 0
	drawGUI()
end

if not gpu then
  return
elseif not screen then
  computer.beep(1000,0.25)
  return
elseif not tape then
  computer.beep(1000,0.25) 
  computer.beep(1000,0.25)
  return
else
  component.invoke(gpu, "bind", screen)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

component.invoke(gpu, "setResolution", 32, 16)
setTapeDuration()
component.invoke(tape, "setVolume", volume)
component.invoke(tape, "setSpeed", speed)
drawGUI()

while true do
	if component.invoke(tape, "isReady") then
		if not tapeInserted then
			drawGUI()
		end
		if component.invoke(tape, "getState") == "PLAYING" then
			tapePos = tapePos + speed
		end
	else
		if tapeInserted then
			drawGUI()
		end
	end
	drawLine(05, 11, tostring(tapePos))
	
	local event, _, keypress = computer.pullSignal(1)
	if event == "key_down" then
		if keypress == 49 then
			startTape()
		elseif keypress == 50 then
			component.invoke(tape, "stop")
		elseif keypress == 51 then
			setTapeDuration()
		elseif keypress == 52 then
			if volume > 0.0 then
				volume = volume - 0.1
				component.invoke(tape, "setVolume", volume)
			end
		elseif keypress == 53 then
			if volume < 1.0 then
				volume = volume + 0.1
				component.invoke(tape, "setVolume", volume)
			end
		elseif keypress == 54 then
			if speed > 0.5 then
				speed = speed - 0.1
				component.invoke(tape, "setSpeed", speed)
			end
		elseif keypress == 55 then
			if speed < 2.0 then
				speed = speed + 0.1
				component.invoke(tape, "setSpeed", speed)
			end
		elseif keypress == 56 then
			component.invoke(tape, "seek", -4096*10)
			tapePos = tapePos + 10
		elseif keypress == 57 then
			component.invoke(tape, "seek", 4096*10)
			tapePos = tapePos - 10
		end
		drawGUI()
	else
		if tapePos >= songDuration then
			startTape()
		end
	end
end