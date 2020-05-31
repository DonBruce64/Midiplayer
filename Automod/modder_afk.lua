--This modder program watches player positions and kicks players who are AFK.
--In order to reduce server load, this program is run on a set frequency.
--Shorter frequencies make the AFK kick time more accurate, but cause more server load.
--Adjust to your liking.  All times are in seconds.

local worldData = component.list("debug")()
local lastPlayerPos = {}
local playerIdleTime = {}
local givenWarning = {}
local posCheckFreq = 10
local warningTime = 540
local kickTime = 600
local lastUptime = 0
local warnMessage = "! Get to stepping or I'll get to kicking!"
local kickMessage = " was kicked for being AFK for over 10 minutes."
local kickPlayerMessage = " You were kicked for being AFK for over 10 minutes."

assert(worldData, "Missing debug card!")
computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
	local currentUptime = computer.uptime()
	computer.pullSignal(1)
	if currentUptime - lastUptime >= posCheckFreq then
		for _, playerName in ipairs(component.invoke(worldData, "getPlayers")) do
			local playerObj = component.invoke(worldData, "getPlayer", player)
			local currentPos = playerObj.getPosition()			
			if not lastPlayerPos[playerName] then
				lastPlayerPos[playerName] = {currentPos}
			else
				if lastPlayerPos[playerName][0] == currentPos[0] and lastPlayerPos[playerName][1] == currentPos[1] and lastPlayerPos[playerName][2] == currentPos[2] then
					playerIdleTime[playerName] = playerIdleTime[playerName] + posCheckFreq
					if playerIdleTime[playerName] > warningTime and not givenWarning[playerName] then
						component.invoke(worldData, "runCommand", "/say " .. playerName .. warnMessage)
						givenWarning[playerName] = true
					elseif playerIdleTime[playerName] > kickTime then
						component.invoke(worldData, "runCommand", "/say " .. playerName .. kickMessage)
						component.invoke(worldData, "runCommand", "/kick " .. playerName .. kickPlayerMessage)
						playerIdleTime[playerName] = 0
						givenWarning[playerName] = false
					end
				else
					playerIdleTime[playerName] = 0
					givenWarning[playerName] = false
				end
			end
		end
	end
	lastUptime = currentUptime
end
