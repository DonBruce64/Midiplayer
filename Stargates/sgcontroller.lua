--Activates a stargate when a packet is received whose gate address matches the connected gate.
--This signal comes over the modem via packet from a computer running sgdatasystem.lua.
--The sending computer will get the signal either from this program, or a computer running sgsignal.lua.
--For both cases, the signal is sent by detecting a redstone state change via card or block.

--If a screen is present, dimension data obtained from sgdatasystem.lua (port 100) is displayed.
--This generic setup allows the same program to be used on any stargate, as the sgdatasystem.lua
--program queries data via stargate address, not the program running the stargate.

--Gates MUST have 7 chevrons to connect.
--Remember this when you're setting up gates!
local modem = component.list("modem")()
local stargate = component.list("stargate")()
local gpu = component.list("gpu")()
local screen = component.list("screen")()
local redstone = component.list("redstone")()

local function parseStargateData(data)
  local currentline = 1
  while data do
    computer.beep(1000,0.05)
    local lineend = string.find(data, "\n")
    if lineend then
      component.invoke(gpu, "set", 1, currentline, string.sub(data, 1, lineend - 1))
      data = string.sub(data, lineend + 1, string.len(data))
    else
      component.invoke(gpu, "set", 1, currentline, data)
      data = nil
    end
    currentline = currentline + 1
  end
end

if not stargate then
  return
elseif not modem then
  computer.beep(1000,0.25)
  return
else
  component.invoke(modem, "open", 101)
	component.invoke(modem, "open", 103)
end

if gpu and screen then
  hasDisplay = true
  component.invoke(gpu, "bind", screen)
  component.invoke(gpu, "setResolution", 32, 16)
  component.invoke(gpu, "fill", 1, 1, 32, 16, " ")
  component.invoke(modem, "broadcast", 100, component.invoke(stargate, "localAddress"))
end

component.invoke(stargate, "closeIris")
computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat
  local signalName, _, sgState, port, redstoneValue, hostGate, remoteGate = computer.pullSignal()
	if signalName == "modem_message" then
		if component.invoke(stargate, "localAddress") == hostGate then
			if port == 101 then
        parseStargateData(remoteGate)         
			elseif port == 103 then
				if component.invoke(stargate, "stargateState") == "Idle" then
					if component.invoke(stargate, "energyAvailable") > component.invoke(stargate, "energyToDial", remoteGate) then
						component.invoke(stargate, "dial", remoteGate)
						component.invoke(stargate, "openIris")
					end
				else
					component.invoke(stargate, "disconnect")
				end
			end
		end
	elseif signalName == "redstone_changed" then
		if redstoneValue == 15 then
			component.invoke(modem, "broadcast", 102, component.invoke(stargate, "localAddress"))
			computer.beep(500,1)
		end
	elseif signalName == "sgStargateStateChange" then
		if sgState == "Closing" or sgState == "Idle" then
			component.invoke(stargate, "closeIris")
		end
	end
until false