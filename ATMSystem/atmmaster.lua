--Program that functions as a bank, where players can deposit and withdraw money.
--Players can deposit or withdraw from any ATM (atminterface.lua).
--Since this saves player money info in a text file on the local file system, it can be
--accessed from multiple computers with the same filesystem handle.  Even on different servers!
--Upon startup, the filesystem must be inserted to tell the program where to look.
--Uses a tunnel and sgdatasystem.lua for inter-dimensional transmission, though this could be removed.

local tunnel = component.list("tunnel")()
local dataSystem

local function getPlayerBalance(playerName)
	if component.invoke(dataSystem, "exists", playerName) then
		local file = component.invoke(dataSystem, "open", playerName, 'r')
		local filesize = component.invoke(dataSystem, "size", playerName)
		local data = component.invoke(dataSystem, "read", file, filesize)
		component.invoke(dataSystem, "close", file)
		return tonumber(data)
	else
		return 0
	end
end

local function setPlayerBalance(playerName, balance)
	if component.invoke(dataSystem, "exists", playerName) then
		component.invoke(dataSystem, "remove", playerName)
	end
	local file = component.invoke(dataSystem, "open", playerName, 'w')
	component.invoke(dataSystem, "write", file, tostring(balance))
	component.invoke(dataSystem, "close", file)
end

if not tunnel then
  return
end

computer.beep(500,0.25)
computer.beep(750,0.25)
repeat 
	local signalName, address, type = computer.pullSignal()
	if signalName == "component_added" and type == "filesystem" then
		dataSystem = address
	end
until dataSystem
computer.beep(1000,0.25)

while true do
	local signalName, _, _, _, _, transactionType, playerName, optData = computer.pullSignal()
	if transactionType == "ATMRequestBalance" then
		component.invoke(tunnel, "send", "BankSendBalance", playerName, tostring(getPlayerBalance(playerName)))
	elseif transactionType == "ATMRequestDeposit" then
		local playerBalance = getPlayerBalance(playerName)
		setPlayerBalance(playerName, playerBalance + tonumber(optData))
		component.invoke(tunnel, "send", "BankConfirmDeposit", playerName, optData)
	elseif transactionType == "ATMRequestWithdraw" then
		if tonumber(optData) <= getPlayerBalance(playerName) then
			local playerBalance = getPlayerBalance(playerName)
			setPlayerBalance(playerName, playerBalance - tonumber(optData))
			component.invoke(tunnel, "send", "BankConfirmWithdraw", playerName, optData)
		else
			component.invoke(tunnel, "send", "BankDenyWithdraw", playerName)
		end
	end
end