--Interface program for the atmmaster.lua program.
--Uses a transposer to get money from connected chest for depoist and withdraw operations.
--Sends operations over tunnel network to allow for inter-dimension transmission.

local gpu = component.list("gpu")()
local screen = component.list("screen")()
local tunnel = component.list("tunnel")()
local transposer = component.list("transposer")()
local debug = component.list("debug")()
local debugWorld
local chestX
local chestY
local chestZ

local interactingPlayer

local function displayScreen(displayLines, timeout, error)
	component.invoke(gpu, "fill", 1, 2, 16, 8, " ")
	for line, text in ipairs(displayLines) do
		component.invoke(gpu, "set", 1, line + 2, text)
	end
	if error then
		computer.beep(1000,1)
		computer.beep(1000,1)
		computer.beep(1000,1)
	end

	if timeout > 0 then
		computer.pullSignal(timeout)
	end
end

local function displayIntro()
	displayScreen({"Select an Option", "1: Get Balance  ", "2: Deposit      ", "3: Withdraw   "}, 0)
end

local function getInput()
	local inputString = ""
	local keypress
	repeat
		local event, _, keypress = computer.pullSignal()
		if event == "key_down" then
			if keypress >= 48 and keypress <= 57 then
				component.invoke(gpu, "set", 8 + inputString:len(), 4, tostring(keypress - 48))
				inputString = inputString .. tostring(keypress - 48)
			end
		end
	until keypress == 13
	return inputString
end

local function addMoneyToChest(moneyToAdd)
	repeat
		if moneyToAdd > 64 then
			debugWorld.insertItem("customnpcs:npcMoney", 64, 0, "", chestX, chestY, chestZ, 1)
			moneyToAdd = moneyToAdd - 64
		else
			debugWorld.insertItem("customnpcs:npcMoney", moneyToAdd, 0, "", chestX, chestY, chestZ, 1)
			moneyToAdd = 0
		end
	until moneyToAdd == 0
end

local function removeMoneyFromChest(moneyToRemove)
	local moneyInChest = 0
	for slot=1,27 do
		local slotStack = component.invoke(transposer, "getStackInSlot", 1, slot)
		if slotStack then
			if slotStack.name == "customnpcs:npcMoney" then
				moneyInChest = moneyInChest + slotStack.size
			end
		end
	end
	if moneyInChest >= moneyToRemove then
		computer.beep(750,0.1)
		for slot=1,27 do
			local slotStack = component.invoke(transposer, "getStackInSlot", 1, slot)
			if slotStack then
				if slotStack.name == "customnpcs:npcMoney" then
					if slotStack.size <= moneyToRemove then
						moneyToRemove = moneyToRemove - slotStack.size
						debugWorld.removeItem(chestX, chestY, chestZ, slot, slotStack.size)
					else
						debugWorld.removeItem(chestX, chestY, chestZ, slot, moneyToRemove)
						moneyToRemove = 0
					end
				end
			end
		end
	end
	if moneyToRemove == 0 then
		return true
	else
		return false
	end
end

if not (gpu and screen) then
  return
elseif not tunnel then
  computer.beep(1000,0.25)
  return
elseif not (transposer and debug) then
	computer.beep(1000,0.25) 
	computer.beep(1000,0.25)
	return
else
  component.invoke(gpu, "bind", screen)
	component.invoke(gpu, "setResolution", 16, 8)
	component.invoke(gpu, "set", 1, 1, "  MONEYMASTER®  ")
	debugWorld = component.invoke(debug, "getWorld")
	
	local debugX = component.invoke(debug, "getX")
	local debugY = component.invoke(debug, "getY")
	local debugZ = component.invoke(debug, "getZ")
	
	for i=-1,1 do
		for k=-1,1 do
			local xCorrection = 0
			local zCorrection = 0
				if debugX + i < 0 then
					xCorrection = -1
				end
				if debugZ + k < 0 then
					zCorrection = -1
				end
			if debugWorld.getBlockId(debugX + i + xCorrection, debugY, debugZ + k + zCorrection) == 54 then
				computer.beep(1000,0.1)
				chestX = debugX + i
				chestY = debugY
				chestZ = debugZ + k
			end
		end
	end
	if not chestY then
		computer.beep(1000,0.25)
		computer.beep(1000,0.25) 
		computer.beep(1000,0.25)
		return
	end
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
	if not interactingPlayer then
		displayIntro()
	end
	local signalName, _, keypressed, _, playerPressed, messageType, messagePlayer, messageArgs = computer.pullSignal()
	if signalName == "key_down" then
		computer.beep(750,0.1)
		interactingPlayer = playerPressed
		if keypressed == 49 then
			component.invoke(tunnel, "send", "ATMRequestBalance", interactingPlayer)
		elseif keypressed == 50 then
			displayScreen({"Enter Deposit  ", "Amount:"}, 0)
			local deposit = getInput()
			if deposit ~= "" then
				if removeMoneyFromChest(tonumber(deposit)) then
					component.invoke(tunnel, "send", "ATMRequestDeposit", interactingPlayer, deposit)
				else
					displayScreen({"CANNOT COMPLETE", "  TRANSACTION", "", "  INSUFFICENT", "     FUNDS"}, 0, true)
					interactingPlayer = nil
				end
			else
				interactingPlayer = nil
			end
		elseif keypressed == 51 then
			displayScreen({"Enter Withdraw ", "Amount:"}, 0)
			local withdraw = getInput()
			if withdraw ~= "" then
				component.invoke(tunnel, "send", "ATMRequestWithdraw", interactingPlayer, withdraw)
			else
				interactingPlayer = nil
			end
		end
	elseif signalName == "modem_message" then
		if messagePlayer == interactingPlayer then
			if messageType == "BankSendBalance" then
				displayScreen({"Your balance is:", messageArgs}, 3)
			elseif messageType == "BankConfirmDeposit" then
				computer.beep(750,0.1)
				displayScreen({"Deposited:", messageArgs}, 3)
			elseif messageType == "BankConfirmWithdraw" then
				addMoneyToChest(tonumber(messageArgs))
				computer.beep(750,0.1)
				displayScreen({"Withdrew:", messageArgs}, 3)
			elseif messageType == "BankDenyWithdraw" then
				displayScreen({"CANNOT COMPLETE", "  TRANSACTION", "", "  INSUFFICENT", "     FUNDS"}, 0, true)
			end
			interactingPlayer = nil
		end
	end	
end