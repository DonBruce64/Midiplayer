--Sends out dimensional data when a message is received.
--Also sends out dial requests based on gate data sent to it.
--Pulls from a local hard drive or floppy.
--Filenames for gate data should correspond to stargate addresses
--With each line being a line of text to display.
--Stargate links should be pairs of addresses on a line for gates.
--Each line MUST end with a newline charachter!
--Drive may hot-swapped for easy changing of data.
--Linked card (tunnel) is used for inter-dimensional dialing requests.
--Port 100 is for receiving gate info requests
--Port 101 is for sending gate info
--Port 102 is for receiving dialing requests
--Port 103 is for sending dialing requests

local modem = component.list("modem")()
local tunnel = component.list("tunnel")()

local function getFileData(filename)
	for filesystem, _ in component.list("filesystem") do
		if component.invoke(filesystem, "exists", filename) then
			computer.beep(1500,1)
			local file = component.invoke(filesystem, "open", filename)
			local filesize = component.invoke(filesystem, "size", filename)
			local data = component.invoke(filesystem, "read", file, filesize)
			component.invoke(filesystem, "close", file)
			return data
		end
	end
end

local function sendGateData(stargateAddress)
	local stargateData = getFileData(stargateAddress)
	if stargateData then
		component.invoke(modem, "broadcast", 101, stargateAddress, stargateData)
	end
end

local function sendDialRequest(stargateAddress)
	local linkData = getFileData("LINKS")
	if linkData then
		local homeGate
		local targetGate
		while linkData do
			local lineend = string.find(linkData, "\n")
			if lineend then
				homeGate = linkData:sub(1, 9)
				targetGate = linkData:sub(lineend - 9, lineend - 1)
				linkData = linkData:sub(lineend + 1)
			else
				linkData = nil
			end
			if stargateAddress == homeGate or stargateAddress == targetGate then
				component.invoke(modem, "broadcast", 103, homeGate, targetGate)
				return
			end
		end
	end
end

if not modem or not tunnel then
  return
else
	component.invoke(modem, "open", 100)
	component.invoke(modem, "open", 102)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat
	local signalName, _, _, port, _, stargateAddress = computer.pullSignal()
	if signalName == "modem_message" then
		if port == 100 then
			sendGateData(stargateAddress)
		elseif port == 102 or port == 0 then
			sendDialRequest(stargateAddress)
		end
	end
until false