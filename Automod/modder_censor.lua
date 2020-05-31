--This modder program watches the chat and hurts players who curse.
--Any player who says a defined curse word will be hurt one heart.
--The best part?  This works in creative mode!
--Note that a creative chat box should be used to get all chat messages on the server.
--Or you can use a regular box to patrol specific areas.
--The former is more general, but the latter works in a microcontroller.

local worldData = component.list("debug")()
local chatBox = component.list("chat_box")()
local chatBoxName = "Censor"
local chatBoxHurtText = "Yeah, I'm gonna have to deduct some health for that."
local chatBoxKillText = "Death by cussing.  That's a new one."
local bannedWords = {"fuck", "bastard", "ass", "bitch", "shit", "cunt", "crap", "jackass", "fag", "retard", "dick", "whore"}

assert(worldData, "Missing debug card!")
assert(chatBox, "Missing chat box/module!")
component.invoke(chatBox, "setName", chatBoxName)
computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
	local name, _, player, text = computer.pullSignal()
	if name == "chat_message" then
		local saidBadWord = false
		for _, badWord in pairs(bannedWords) do
			if string.find(text, badWord) then
				saidBadWord = true
				break
			end
		end
		if saidBadWord then
			local playerObj = component.invoke(worldData, "getPlayer", player)
			local currentHealth = playerObj.getHealth()
			playerObj.setHealth(currentHealth - 2)
			if currentHealth - 2 > 0 then
				component.invoke(chatBox, "say", chatBoxHurtText)
			else
				component.invoke(chatBox, "say", chatBoxKillText)
			end
		end
  end
end
