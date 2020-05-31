--Lighter version of midiplayer.lua.
--This program is designed to run on EEPROMs, and will only convert midi
--files to .mdp files.  These files may be played with midiplayer.lua
--or the similarly light player program midiplayer_light.lua.

local component=require("component")
local computer=require("computer")
local os=require("os")
local shell=require("shell")
local event=require("event")
local term=require("term")
local gpu=component.getPrimary("gpu")

while true do
	term.clear()
	gpu.setResolution(16, 8)
	gpu.set(1, 3, "Insert a floppy ") 
	gpu.set(1, 4, "with a .mid file")
	gpu.set(1, 5, "   to convert   ")
	local signalName, address, type = event.pull("component_added")
	local foundfile = false
	local fileList = component.invoke(address, "list", "")
	for _,file in ipairs(fileList) do
		if file:sub(file:len() - 3) == ".mid" then
			foundfile = true
			term.clear()
			gpu.setResolution(48, 16)
			local fileName = "/mnt/" .. address:sub(1,3) .. "/" .. file
			os.sleep(1) --need to wait for FS to initialize
			print("Converting:" .. fileName)
			shell.execute("midiplayer -d " .. fileName)
			print("Conversion finished.  Press any key to continue...")
			while computer.pullSignal() ~= "key_down" do end
		end
	end
	if not foundfile then
		term.clear()
		gpu.set(1, 3, " No .mid files  ") 
		gpu.set(1, 4, " found on disk! ")
		computer.beep(1000,1)
		computer.beep(1000,1)
		computer.beep(1000,1)
  end
end