--A lighter version of midiplayer.  Designed for flashing to EEPROMs.
--This program will only read converted .mdp files.
--If you need to convert files, either use the full midiplayer.lua program
--or the lighter midiplayer_convertwrapper.lua program.

local gpu = component.list("gpu")()
local screen = component.list("screen")()
local beepCard = component.list("beep")()

local function sleep(timeout)
  local deadline = computer.uptime() + (timeout or 0)
  repeat
    computer.pullSignal(deadline - computer.uptime())
  until computer.uptime() >= deadline
end

local function unserialize(data)
  local result, reason = load("return " .. data, "=data", _, {math={huge=math.huge}})
  if not result then
    return nil, reason
  end
  local ok, output = pcall(result)
  if not ok then
    return nil, output
  end
  return output
end

local function playfile(filesystem, midiFile)
  local beeperEvents={}
  local timeDelay = 0;
  local timeLine = true
  local file = component.invoke(filesystem, "open", midiFile)
  local data = component.invoke(filesystem, "read", file, 2000)
  
  while data do
    local lineend = string.find(data, "\n")
    if not lineend then break end
    local line = string.sub(data, 1, lineend - 1)
    if timeLine then
      timeDelay = line
      timeLine = false
    else
      table.insert(beeperEvents,{beeps=unserialize(line),delay=tonumber(timeDelay)})
      timeLine = true
    end
    if data:len() < 500 then
      local moreData = component.invoke(filesystem, "read", file, 1500)
      if moreData then
        data = data .. moreData
      end
    end
    data = string.sub(data, lineend + 1, string.len(data))
  end

  component.invoke(gpu, "fill", 1, 1, 16, 8, " ")
  component.invoke(gpu, "set", 1, 2, "  NOW PLAYING:  ")
  component.invoke(gpu, "set", 1, 3, midiFile:sub(1, midiFile:len() - 4))
  for _,beepInfo in ipairs(beeperEvents) do
    component.invoke(beepCard, "beep", beepInfo.beeps)
    sleep(beepInfo.delay)
  end
end

if not gpu then
  return
elseif not screen then
  computer.beep(1000,0.25)
  return
elseif not beepCard then
  computer.beep(1000,0.25)
  computer.beep(1000,0.25)
  return
end

if gpu and screen then
  component.invoke(gpu, "bind", screen)
  component.invoke(gpu, "setResolution", 16, 8)
end

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
  component.invoke(gpu, "fill", 1, 1, 16, 8, " ")
  component.invoke(gpu, "set", 1, 3, "Insert a floppy ") 
  component.invoke(gpu, "set", 1, 4, "with a .mdp file")
  component.invoke(gpu, "set", 1, 5, "to start playing")
  local signalName, address, type = computer.pullSignal()
  if signalName == "component_added" and type == "filesystem" then
    local foundfile = false
    local fileList = component.invoke(address, "list", "")
    for _,file in ipairs(fileList) do
      if file:sub(file:len() - 3) == ".mdp" then
        foundfile = true
        playfile(address, file)
      end
    end
    if not foundfile then
      component.invoke(gpu, "fill", 1, 1, 16, 8, " ")
      component.invoke(gpu, "set", 1, 3, " No .mdp files  ") 
      component.invoke(gpu, "set", 1, 4, " found on disk! ")
      computer.beep(1000,1)
      computer.beep(1000,1)
      computer.beep(1000,1)
    end
  end
end