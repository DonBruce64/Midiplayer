--A simple program to run a chunkloader inside a microcontroller.

local chunkloader = component.list("chunkloader")()

if not chunkloader then
  return
else
	component.invoke(chunkloader, "setActive", true)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat
	computer.pullSignal()
until false