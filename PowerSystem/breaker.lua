--Simple microcontroller program for redstone switching.
--This will poll the power from some sorce that is being input to the controller via comparator.
--Should the source get low enough, it will fire its output redstone signal.
--This program is used to isolate power lines via capacitor banks, as IE's routing logic is laggy.
--By monitoring the capacitor, you can disconnect the lines when not in-use to reduce lag.

local redstone = component.list("redstone")()
local powerBank = 4
local relay = 1
local status = 3
local closed = 0
local open = 15
local on = 0
local off = 15

if not redstone then
	return
else
	component.invoke(redstone, "setOutput", relay, open)
	component.invoke(redstone, "setOutput", status, off)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

repeat computer.pullSignal(5)
	local powerBankLevel = component.invoke(redstone, "getComparatorInput", powerBank)
	if powerBankLevel <= 1 and component.invoke(redstone, "getOutput", relay) == open then
		component.invoke(redstone, "setOutput", relay, closed)
		component.invoke(redstone, "setOutput", status, on)
		computer.beep(750, 0.5)
	elseif powerBankLevel >= 14 and component.invoke(redstone, "getOutput", relay) == closed then
		component.invoke(redstone, "setOutput", relay, open)
		component.invoke(redstone, "setOutput", status, off)
		computer.beep(500, 0.5)
	end
until false