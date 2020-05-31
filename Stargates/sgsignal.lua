--Sends a dial signal when redstone is pressed on the front of the device
--Dial signal is sent to sgdatasystem.lua via tunnel.  This signal is then
--broadcasted on the local network to cause a computer running sgcontroller.lua
--to dial the stargate to complete the connection.
--This setup allows for dialing of stargates from the "other end".  In essence,
--you can send the dial request to a main HUB and have it power and dial all gates.
--This prevents the need for large power systems on all gate destinations.

local tunnel = component.list("tunnel")()
local stargate = component.list("stargate")()
local redstone = component.list("redstone")()

if not stargate then
  return
elseif not tunnel then
  computer.beep(1000,0.25)
  return
elseif not redstone then
  computer.beep(1000,0.25)
	computer.beep(1000,0.25)
  return
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat
  local name, _, side, _, value = computer.pullSignal()
  if name == "redstone_changed" then
		if value == 15 and side == 3 then
			component.invoke(tunnel, "send", component.invoke(stargate, "localAddress"))
			computer.beep(500,1)
		end
  end
until false