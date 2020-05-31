--Sends a dial signal when redstone is pressed anywhere on the device.
--You can use either a redstone IO block for remote signals, 
--or a redstone card for redstone that touches the computer.
--This program requires the stargate to have enough power to run and
--does not interface with any other stargate programs.

local stargate = component.list("stargate")()
local redstone = component.list("redstone")()
--Change remote gate address here.
local remoteGate = "123456789"

assert(stargate, "No stargate found!  Check your connections and try again!")
assert(redstone, "No redstone IO or card found!  Check your setup and try again!")

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat
  local name, _, _, _, value = computer.pullSignal()
  if name == "redstone_changed" then
		if value == 15 then
			if component.invoke(stargate, "stargateState") == "Idle" then
				computer.beep(500,1)
				if component.invoke(stargate, "energyAvailable") > component.invoke(stargate, "energyToDial", remoteGate) then
					component.invoke(stargate, "dial", remoteGate)
					component.invoke(stargate, "openIris")
				else
					computer.beep(750,0.25)
					computer.beep(750,0.25)
				end
			else
				component.invoke(stargate, "disconnect")
			end
		end
  end
until false