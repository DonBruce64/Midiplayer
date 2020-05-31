--Airlock controller for use in Galacticraft bases.
--Alternates two doors when a redstone signal is received.
--Designed to work in a microcontroller and on EEPROM to not be crazy expensive.

local redstone = component.list("redstone")()
local lights = 2
local input = 3
local inside = 4
local outside = 5
local closed = 0
local open = 15
local outsideOpen = true

if not redstone then
	return
else
	component.invoke(redstone, "setOutput", inside, closed)
	component.invoke(redstone, "setOutput", outside, open)
	component.invoke(redstone, "setOutput", lights, 15)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
	local name, _, side, _, value = computer.pullSignal()
  if name == "redstone_changed" then
		if value == 15 and side == 3 then
			if component.invoke(redstone, "getOutput", outside) == open then
				component.invoke(redstone, "setOutput", outside, closed)
				computer.beep(500, 0.5)
				component.invoke(redstone, "setOutput", inside, open)
			else
				component.invoke(redstone, "setOutput", inside, closed)
				computer.beep(500, 0.5)
				component.invoke(redstone, "setOutput", outside, open)
			end
		end
	end
end