--A simple program that will make a player hologram display when triggered.
--Can be hooked up to two doors to lock players into a "scanning room" for screening.

local redstone = component.list("redstone")()
local hologram = component.list("hologram")()
local chat_box = component.list("chat_box")()

local function sleep(timeout)
  local deadline = computer.uptime() + timeout
  repeat
    computer.pullSignal(timeout)
  until computer.uptime() >= deadline
end

if not redstone then
  return
elseif not hologram then
  computer.beep(1000,0.25)
  return
elseif not chat_box then
  computer.beep(1500,0.25)
  computer.beep(1500,0.25)
  return
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)
--5 is entry, 4 is exit
component.invoke(redstone, "setOutput", 5, 0)
component.invoke(redstone, "setOutput", 4, 15)
component.invoke(chat_box, "setName", "Scanner System")
component.invoke(chat_box, "setDistance", 5)
component.invoke(hologram, "setScale", 0.33)
component.invoke(hologram, "clear", 0.33)
component.invoke(hologram, "setRotationSpeed", 45, 0, 45, 0)
component.invoke(hologram, "setPaletteColor", 1, 65280)

while true do
  local name, _, side, _, value = computer.pullSignal()
  if name == "redstone_changed" then
		if side == 1 and value == 15 then
			component.invoke(redstone, "setOutput", 5, 15)
			component.invoke(redstone, "setOutput", 4, 15)
			component.invoke(chat_box, "say", "SCANNING")
			for i=1,12 do
				for j=20,28 do
					for k=22,26 do
						component.invoke(hologram, "set", j, i, k, true)
					end
					sleep(0.000001)
				end
			end
			for i=13,24 do
				for j=16,32 do
					for k=22,26 do
						component.invoke(hologram, "set", j, i, k, true)
					end
					sleep(0.001)
				end
			end
			for i=25,33 do
				for j=20,28 do
					for k=20,28 do
						component.invoke(hologram, "set", j, i, k, true)
					end
					sleep(0.001)
				end
			end
			component.invoke(chat_box, "say", "SCANNING COMPLETE: NO THREATS FOUND")
			component.invoke(redstone, "setOutput", 5, 0)
			component.invoke(redstone, "setOutput", 4, 0)
			component.invoke(hologram, "clear")
		end
  end
end