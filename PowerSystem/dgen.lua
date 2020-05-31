--Simple redstone microcontroller pogram to turn on and off generators by packet.
--Packets are sent from dgenroom.lua.
--This may be adapted to work with other machines for remote-redstone signalling.

local redstone = component.list("redstone")()
local modem = component.list("modem")()

local genratorPacketPort = 110
local restoneOff = 0
local redstoneOn = 15

local function setRedstone(status)
	for i=0,5 do
		component.invoke(redstone, "setOutput", i, status)
	end
end

if not redstone then
	return
elseif not modem then
	computer.beep(1000,0.25)
  return
else
	component.invoke(modem, "open", genratorPacketPort)
	setRedstone(redstoneOn)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat
	local signalName, _, _, _, _, activation = computer.pullSignal()
  if signalName == "modem_message" then
		if activation then
			setRedstone(restoneOff)
		else
			setRedstone(redstoneOn)
		end
	end
until false