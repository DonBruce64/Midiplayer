--Program for simple tape recording.
--Saves entered tapes to attached filesystems for later use.

--Un-comment if using on OpenOS
--local component=require("component")
--local computer=require("computer")
local gpu = component.list("gpu")()
local screen = component.list("screen")()
local tape = component.list("tape_drive")()
local internet = component.list("internet")()

local function displayScreen(displayLines, pauseAfter, error)
	component.invoke(gpu, "setResolution", 16, 8)
	component.invoke(gpu, "fill", 1, 1, 16, 8, " ")
	for line, text in ipairs(displayLines) do
		component.invoke(gpu, "set", 1, line, text)
	end
	if error then
		computer.beep(1000,1)
		computer.beep(1000,1)
		computer.beep(1000,1)
	end
	if pause then
		while computer.pullSignal() ~= "key_down" do end
	end
end

local function displayIntro()
	displayScreen({"   MAGNATRON®   ", "TAPE  CONVERSION", "& STORAGE SYSTEM", "", " Press any key  ", "   to start.    "}, true, false)
end

local function displaySelectionScreen()
	displayScreen({"   MAGNATRON®   ", "TAPE  CONVERSION", "& STORAGE SYSTEM", "", "1: List songs   ", "2: List -> Tape ", "3: Web  -> Tape ", "4: Rename Tape "}, false, false)
end

local function displaySongSelect()
	displayScreen({"Please enter the", "number of the   ", "song to record. ", "Use option 1 for", "a list of songs.", "", "", "Song #:         "}, false, false)
end

local function displayInsertURL()
	displayScreen({"Please enter the", "url of the song ", "to record by    ", "copying the link", "to the clipboard", "and pressing    ", "the insert key. ", ""}, false, false)
end

local function displayInsertDrive()
	displayScreen({"Please insert a ", "hard drive with ", "a .dfpwm song.  "}, false, false)
end

local function displayBadPath()
	displayScreen({"Could not find  ", "song to write!  ", "Check that the  ", "number or format", "is correct and  ", "try again.      "}, false, true)
end

local function displayNoTape()
	displayScreen({" No tape found! ", " Please insert  ", "   a tape and   ", "   try again.   "}, false, true)
end

local function displayInternetError()
	displayScreen({"Could not       ", "connect to song ", "URL.            ", "Ensure that the ", "URL is valid and", "try again.      "}, false, true)
end

local function displayTapeRename()
	displayScreen({"Please enter the", "new tape name:  "}, false, false)
end

local function displayWebOverflow()
	displayScreen({"The song you are", "trying to write ", "is too long for ", "the tape.       ", "Either the tape ", "is too small or ", "you do not have ", "a direct link.  "}, false, true)
end

local function displayNoSpace()
	displayScreen({"No space left on", "datasystem, or  ", "song is too big ", "please contact  ", "your nearest    ", "system admin.   "}, false, true)
end

local function listFiles()
	component.invoke(gpu, "setResolution", 32, 16)
	component.invoke(gpu, "fill", 1, 1, 32, 16, " ")
	
	local totalFiles = 0
	local currentline = 1
	for filesystem in component.list("filesystem") do
		computer.beep(500,0.01)
		for _,file in ipairs(component.invoke(filesystem, "list", "")) do
			computer.beep(750,0.01)
			if file:sub(file:len() - 5, file:len()) == ".dfpwm" then
			computer.beep(1000,0.01)
				if currentline == 15 then
					component.invoke(gpu, "set", 1, 16, "Press any key to display more...")
					while computer.pullSignal() ~= "key_down" do end
					component.invoke(gpu, "fill", 1, 1, 32, 16, " ")
					currentline = 1
				end
				totalFiles = totalFiles + 1
				component.invoke(gpu, "set", 1, currentline, tostring(totalFiles) .. ": " .. file:sub(1, file:len() - 6))
				currentline = currentline + 1
			end
		end
	end
	component.invoke(gpu, "set", 1, 16, "Press any key to continue...")
	while computer.pullSignal() ~= "key_down" do end
end

local function getSongNumber()
	local songNumber = ""
	local hitEnter = false
	repeat
		local event, _, keypress = computer.pullSignal()
		if event == "key_down" then
			if keypress == 13 then
				hitEnter = true
			elseif keypress >= 48 and keypress <= 57 then
				component.invoke(gpu, "set", 8 + songNumber:len(), 8, tostring(keypress - 48))
				songNumber = songNumber .. tostring(keypress - 48)
			end
		end
	until hitEnter
	return tonumber(songNumber)
end

local function getSongByNumber(songNumber)
		local currentFile = 0
		for filesystem in component.list("filesystem") do
			for _,file in ipairs(component.invoke(filesystem, "list", "")) do
				if file:sub(file:len() - 5, file:len()) == ".dfpwm" then
					currentFile = currentFile + 1
					if currentFile == songNumber then
						return file, filesystem
					end
				end
			end
		end
end

local function writeToTape(fileName, filesystem)
  if not component.invoke(tape, "isReady") then
    displayNoTape()
    return
  end

  local file = component.invoke(filesystem, "open", fileName, 'rb')
  local fileSize = component.invoke(filesystem, "size", fileName)
  local tapeSize = component.invoke(tape, "getSize")

  component.invoke(gpu, "setResolution", 16, 8)
  component.invoke(gpu, "fill", 1, 1, 16, 8, " ")
  component.invoke(gpu, "set", 1, 1, "WRITING")
  component.invoke(gpu, "set", 1, 2, "Byte:")
  component.invoke(gpu, "set", 1, 3, "Of:  " .. tostring(fileSize))
  if fileSize > tapeSize then
    component.invoke(gpu, "set", 1, 5, "Tape too small! ")
    component.invoke(gpu, "set", 1, 6, "Song will cutoff")
  end
  
  local position = 0
  local data = component.invoke(filesystem, "read", file, 1024)
  repeat
    component.invoke(tape, "write", data)
    position = position + data:len()
    component.invoke(gpu, "set", 6, 2, tostring(position))
		if position + 1024 < tapeSize then
			data = component.invoke(filesystem, "read", file, 1024)
		elseif position < tapeSize then
			data = component.invoke(filesystem, "read", file, tapeSize - position)
		else
			data = nil
		end
  until not data

  component.invoke(tape, "setLabel", fileName:sub(1, fileName:len() - 6))
	component.invoke(gpu, "set", 1, 7, "Press 1 to add ")
	component.invoke(gpu, "set", 1, 8, "song, 0 to end.")
	
	local keypress
  repeat
    local event
    event, _, keypress = computer.pullSignal()
    if event ~= "key_down" then
      keypress = nil
    elseif keypress ~= 48 and keypress ~= 49 then
      keypress = nil
    end
  until keypress
	
	if keypress == 48 then
		component.invoke(tape, "seek", -tapeSize)
		component.invoke(gpu, "set", 1, 7, "Writing Finished")
		component.invoke(gpu, "set", 1, 8, "Press any key...")
		while computer.pullSignal() ~= "key_down" do end
	elseif keypress == 49 then
		displaySongSelect()
    file, filesystem = getSongByNumber(getSongNumber())
    if file then
      writeToTape(file, filesystem, false)
    else
      displayBadPath()
			component.invoke(gpu, "set", 1, 7, "Writing Halted  ")
			component.invoke(gpu, "set", 1, 8, "Press any key...")
    end
	end
end

local function writeFromWeb()
	if not component.invoke(tape, "isReady") then
    displayNoTape()
    return
  end
	local tapeSize = component.invoke(tape, "getSize")
	
	displayInsertURL()
	local songURL
	repeat
		local event, _, data = computer.pullSignal()
		if event == "clipboard" then
			songURL = data
		end
	until songURL
	local connection = component.invoke(internet, "request", songURL)
	if not connection then
		displayBadPath()
		return
	end
	local tries = 0
	repeat
		computer.pullSignal(0.1)
		tries = tries + 1
	until connection.finishConnect() or tries == 10
	if not connection.finishConnect() then
		displayInternetError()
		return
	end
	
	component.invoke(gpu, "setResolution", 16, 8)
  component.invoke(gpu, "fill", 1, 1, 16, 8, " ")
  component.invoke(gpu, "set", 1, 1, "WRITING")
  component.invoke(gpu, "set", 1, 2, "Byte:")
	local position = 0
	local data
	repeat
		data = connection.read(1024)
		if data then
			component.invoke(tape, "write", data)
			position = position + data:len()
			component.invoke(gpu, "set", 6, 2, tostring(position))
			if position > tapeSize then
				displayWebOverflow()
				connection.close()
				return
			end
		end
	until not data
	connection.close()
	
	while songURL:find("/") do
		songURL = songURL:sub(songURL:find("/")+1)
	end
	component.invoke(tape, "setLabel", songURL:sub(1, songURL:len() - 6))
	
	component.invoke(tape, "seek", -tapeSize)
	component.invoke(gpu, "set", 1, 7, "Writing Finished")
	component.invoke(gpu, "set", 1, 8, "Press any key...")
	while computer.pullSignal() ~= "key_down" do end
end

local function renameTape()
	local tapeName = ""
	local hitEnter = false
	displayTapeRename()
	repeat
		local event, _, keypress = computer.pullSignal()
		if event == "key_down" then
			if keypress == 13 then
				hitEnter = true
			elseif keypress >= 32 and keypress <= 126 then
				component.invoke(gpu, "set", 1 + tapeName:len(), 3, string.char(keypress))
				tapeName = tapeName .. string.char(keypress)
			end
		end
	until hitEnter
	component.invoke(tape, "setLabel", tapeName)
	component.invoke(gpu, "set", 1, 7, "Label set!      ")
	component.invoke(gpu, "set", 1, 8, "Press any key...")
	while computer.pullSignal() ~= "key_down" do end
end

local function readFromDrive()
	displayInsertDrive()
	local driveAddress
	local timeout = computer.uptime() + 10
	repeat 
		local signalName, address, type = computer.pullSignal(timeout - computer.uptime())
		if signalName == "component_added" and type == "filesystem" then
			driveAddress = address
		end
	until driveAddress or computer.uptime() > timeout
	if driveAddress then
		local driveFileList = component.invoke(driveAddress, "list", "")
		for _,file in ipairs(driveFileList) do
			if file:sub(file:len() - 5, file:len()) == ".dfpwm" then
				local songSize = component.invoke(driveAddress, "size", file)
				for raidBlock in component.list("filesystem") do
					if raidBlock ~= driveAddress then
						if component.invoke(raidBlock, "spaceTotal") - component.invoke(raidBlock, "spaceUsed") > songSize then
							component.invoke(gpu, "setResolution", 16, 8)
							component.invoke(gpu, "fill", 1, 1, 16, 8, " ")
							component.invoke(gpu, "set", 1, 1, "UPLOADING")
							component.invoke(gpu, "set", 1, 2, "Byte:")
							component.invoke(gpu, "set", 1, 3, "Of:  " .. tostring(songSize))
								
							local position = 0
							local srcFile = component.invoke(driveAddress, "open", file, 'r')
							local destFile = component.invoke(raidBlock, "open", file, 'w')
							local data = component.invoke(driveAddress, "read", srcFile, 1024)
							repeat
								component.invoke(raidBlock, "write", destFile, data)
								position = position + data:len()
								component.invoke(gpu, "set", 6, 2, tostring(position))
								data = component.invoke(driveAddress, "read", srcFile, 1024)
							until not data
							component.invoke(gpu, "set", 1, 7, "Upload  Finished")
							component.invoke(gpu, "set", 1, 8, "Press any key...")
							while computer.pullSignal() ~= "key_down" do end
							return
						end
					end
				end
				displayNoSpace()
				return
			end
		end
	end
	displayBadPath()
end

if not gpu then
  return
elseif not screen then
  computer.beep(1000,0.25)
  return
elseif not tape then
  computer.beep(1000,0.25) 
	computer.beep(1000,0.25)
	return
else
  component.invoke(gpu, "bind", screen)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

displayIntro()
while true do
	displaySelectionScreen()

	local keypress
	repeat
		local event
		event, _, keypress = computer.pullSignal()
		if event ~= "key_down" then
			keypress = nil
		end
	until keypress
	
	if keypress == 49 then
		listFiles()
	elseif keypress == 50 then
		displaySongSelect()
		file, filesystem = getSongByNumber(getSongNumber())
		if file then
			if not component.invoke(tape, "isReady") then
				displayNoTape()
			else
				writeToTape(file, filesystem, false)
			end
		else
			displayBadPath()
		end
	elseif keypress == 51 then
		writeFromWeb()
	elseif keypress == 52 then
		renameTape()
	elseif keypress == 53 then
		readFromDrive()
	end
end