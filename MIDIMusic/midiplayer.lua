--This program parses and plays midi files.
--Files may either be played directly after parsing, or can be saved
--to specialized .mdp files for direct playback on machines running midiplayer_light.lua.
--This prevents the need to have fast (expensive) computers to play back music.
--Should you not want to use OpenOS, this program has two stand-alone companion programs.
--midiplayer_convertwrapper.lua can run on EEPROMs and will convert songs to .mdp files.
--midiplayer_light can also run on EEPROMs, and will read .mdp files.

local component=require('component')
local computer=require('computer')
local shell=require('shell')
local serialization=require('serialization')
local currentTime=os.clock()
local speed=1

print(string.format("Current free memory is %dk (%d%%) ",computer.freeMemory()/1024, computer.freeMemory()/computer.totalMemory()*100))
local args,options=shell.parse(...)
if #args>1 then speed=tonumber(args[2]) end
if #args==0 or speed==nil then
  print("Usage: midiplayer [-i] [-d] [-r] <filename> [speed] [track1[track2[...]]]")
  print("Speed is an optional multiplier, usually needed for really simple or complex songs; default=1")
  print("Track is a list of the specific tracks to play; speed multiplier must be given in this case")
  print(" -i: Print track info and exit")
  print(" -d: Dump track info to file (beep cards only).")
  print(" -r: Read dump file instead of MIDI file.")
  return
end

local midiFile, errors=io.open(shell.resolve(args[1]),'rb')
if not midiFile then
  print(errors)
  return
end
local fileSize=midiFile:seek('end'); midiFile:seek('set')

if options.r then --reading a beep file
  local beeperEvents={}
  local timeDelay = 0;
  local timeLine = true
  for line in midiFile:lines() do
    if timeLine then
      timeDelay = line
      timeLine = false
    else
      table.insert(beeperEvents,{beeps=serialization.unserialize(line),delay=tonumber(timeDelay)})
      timeLine = true
    end
  end
  local beeper=component.getPrimary('beep')
  for _,beepInfo in ipairs(beeperEvents) do
    beeper.beep(beepInfo.beeps)
    os.sleep(beepInfo.delay)
  end
  return
end

--set instruments and values we need
local instruments=0
local playListArgs={['instrument']=false,['note']=false,['volume']=false,['frequency']=false,['duration']=false}
if options.d then
  print("Dumping mode selected.")
  playListArgs={['frequency']=true,['duration']=true}
  instruments=-1
elseif component.isAvailable('iron_noteblock') then
  print("Found iron noteblock")
  playListArgs={['instrument']=true,['note']=true,['volume']=true}
  instruments=1
elseif component.isAvailable('note_block') then
  print("Found note block")
  playListArgs={['note']=true}
  for block in computer.list('note_block') do
    instrumnets=instruments+1
    instrument[call..instrument.n]=component.proxy(block)
  end
elseif component.isAvailable('beep') then
  print("Found beep card")
  playListArgs={['frequency']=true,['duration']=true}
  instruments=-1
else
  print("No sound items found, defaulting to PC speaker in single-track mode")
  playListArgs={['frequency']=true,['duration']=true}
end

--helper functions  
local function hexToDec(bytes)
  local total=0
  for i=1, bytes:len() do
    total=bit32.lshift(total,8)+bytes:byte(i)
  end
  return total
end

local fileHeader=midiFile:read(4)
local headerSize=hexToDec(midiFile:read(4))
local fileFormat=hexToDec(midiFile:read(2))
local numTracks=hexToDec(midiFile:read(2))
local timeDivision=hexToDec(midiFile:read(2))
if fileHeader ~= 'MThd' or headerSize ~= 6 then
  print("Error in parsing header data.  File is likely corrupt")
  return
elseif fileFormat < 0 or fileFormat > 2 then
  print("Unsupported file format.  MIDI may be corrupt")
  return
elseif fileFormat==2 then
  print("Asynchronous file format not suppported")
  return
elseif fileFormat==1 then
  print(string.format("Synchronous file format found with %d tracks.", numTracks))
else
  print("Single track found.")
end

local tickLength=0
local spb=0.5
local tpb=0
if bit32.rshift(timeDivision,15)==0 then
  tpb=bit32.band(timeDivision,0x7FFF)
  tickLength=(spb / tpb)
else
  local fps=math.floor(bit32.extract(timeDivision,1,7))
  local tpf=bit32.rshift(timeDivision,8)
  tickLength=1/(tpf*fps); spb=nil
end

--Get track offsets
local tracks={}
for i=1,numTracks do
  local trackInfo={instrument='Unknown',instrumentID=0,ID=i}
  if midiFile:read(4)~="MTrk" then
    print("Invalid track found, attempting to skip")
    midiFile:seek('cur', hexToDec(midiFile:read(4)))
  else
    trackInfo.size=hexToDec(midiFile:read(4))
    trackInfo.offset=midiFile:seek()
  end
  if #args<=2 then
    trackInfo.play=true
  else
    if instruments==0 and i==tostring(args[3]) then
      trackInfo.play=true
    else
      for _,v in pairs(args) do
        if tostring(i)==v then trackInfo.play=true break end
      end
    end
  end
  tracks[i]=trackInfo
  midiFile:seek('set',trackInfo.offset+trackInfo.size)
end
midiFile:seek('set',tracks[1].offset)


--Parse ALL the things (that we need)
local fireTicks={}
for i=1,numTracks do
  local onNotes={}
  local currentTick=0
  local moreData=true
  local previousEventType=''
  local constPassEvent={[0xA]=2,[0xB]=2,[0xD]=1,[0xE]=2,[0xF1]=1,[0xF2]=2,[0xF3]=1,[0xF6]=0,[0xF8]=0,[0xFA]=0,[0xFB]=0,[0xFC]=0,[0xFE]=0,[0x00]=2,[0x20]=2,[0x21]=2,[0x54]=6,[0x59]=3}
  local varPassEvent={[0x01]=true,[0x05]=true,[0x06]=true,[0x07]=true,[0x7F]=true}
   
  local function calculateDuration(midiFile,tickLength,fireTicks,onNotes,eventID)
    --Issue with notes occurs if there's multiple on events in a row for the same note.
    --Fixed for now, but it shortens the duration a bit.
    if not onNotes[eventID] then
      print('Off note with no corresponding on note found at byte:',midiFile:seek())
    elseif not fireTicks[onNotes[eventID]] then
      print('Off note with no corresponding tick found at byte:',midiFile:seek())
    else
      for _,firingNotes in pairs(fireTicks[onNotes[eventID]]) do
        if firingNotes.duration==eventID then
          firingNotes.duration=(currentTick-onNotes[eventID])*tickLength
          onNotes[eventID]=nil
          return
        end
      end
    end
  end
  
  if tracks[i].play then
    while moreData do
      local test
      local eventType
      local eventTime=0
      
      repeat
        test=midiFile:read(1):byte()
        eventTime=bit32.lshift(eventTime,7)+bit32.extract(test,0,7)
      until bit32.extract(test,7)==0
    
      currentTick=currentTick+eventTime
      eventType=midiFile:read(1)
      if bit32.extract(eventType:byte(),7)==0 then
        eventType=previousEventType
        midiFile:seek('cur',-1)
      else
        eventType=eventType:byte()
      end
      if bit32.rshift(eventType,4)==8 then --Note off
        if playListArgs.duration then
          calculateDuration(midiFile,tickLength,fireTicks,onNotes,bit32.extract(eventType,0,4)..(2^((midiFile:read(1):byte()-69)/12)*440))
          midiFile:seek('cur',1)
        else
          midiFile:seek('cur',2)
        end
      elseif bit32.rshift(eventType,4)==9 then --Note on
        local noteInfo={}
        local note=midiFile:read(1):byte()
        local volume=midiFile:read(1):byte()/127
        local frequency=(2^((note - 69) / 12) * 440)
        if volume==0 then --Really a note off command
          if playListArgs.duration then
            calculateDuration(midiFile,tickLength,fireTicks,onNotes,bit32.extract(eventType,0,4)..frequency)
          end
        else
          if playListArgs.note then noteInfo.note=((note-60+6)%24+1) end
          if playListArgs.volume then noteInfo.volume=volume end
          if playListArgs.frequency then --Implies duration
            noteInfo.frequency=(2^((note - 69) / 12) * 440)
            noteInfo.duration=bit32.extract(eventType,0,4)..noteInfo.frequency
            onNotes[bit32.extract(eventType,0,4)..noteInfo.frequency]=currentTick
          end
          if not fireTicks[currentTick] then fireTicks[currentTick]={} end
          table.insert(fireTicks[currentTick],noteInfo)
        end
      elseif bit32.rshift(eventType,4)==0xC then --Instrument setting
        test=midiFile:read(1):byte()
        if bit32.lshift(eventType,4)==0x9 then
          tracks[i].instrumentID=2
        elseif test>=0x18 and test<0x38 then
          tracks[i].instrumentID=4
        else
          tracks[i].instrumentID=5
        end
      elseif eventType==0xF0 then  --Sysex message (variable length)
        repeat test=string.byte(midiFile:read(1)) until bit32.extract(test,7)~='1'
      elseif eventType==0xFF then --Meta message
        local metaType=midiFile:read(1):byte()
        if metaType==0x02 then --Copyright notice
          print(midiFile:read(midiFile:read(1):byte()))
        elseif metaType==0x03 then --Track name
          tracks[i].name=midiFile:read(midiFile:read(1):byte())
        elseif metaType==0x04 then --Instrument name
          tracks[i].instrument=midiFile:read(midiFile:read(1):byte())
        elseif metaType==0x2F then--EOT
          midiFile:seek('cur',9); moreData=false
        elseif metaType==0x51 then --Set tempo
          spb=hexToDec(midiFile:read(midiFile:read(1):byte()))/1000000
          tickLength=spb/tpb
          print(string.format("Tick length set to %f seconds by metadata in file", tickLength))
        elseif metaType==0x58 then --Time signature
          midiFile:seek('cur',1)
          local num=midiFile:read(1):byte()
          local den=2^midiFile:read(1):byte()
          tracks[i].timesignature=tostring(num) .. '/' .. tostring(den)
          midiFile:seek('cur',2)
        elseif varPassEvent[metaType] then
          midiFile:seek('cur',midiFile:read(1):byte())
        elseif constPassEvent[metaType] then
          midiFile:seek('cur',constPassEvent[metaType])
        else
          print(string.format("Unknown meta event type %02X encountered at byte %d.", eventType, midiFile:seek()))
        end
      elseif constPassEvent[bit32.rshift(eventType,4)] then
        midiFile:seek('cur',constPassEvent[bit32.rshift(eventType,4)])
      elseif constPassEvent[eventType] then
        midiFile:seek('cur',constPassEvent[eventType])
      else
          print(string.format("Unknown regular event type %02X encountered at byte %d.", eventType, midiFile:seek()))
      end
      previousEventType=eventType
    end
  else
    midiFile:seek('cur',tracks[i].size+8)
  end
end
midiFile:close()

print("Track","Name","Instrument")
for i=1,numTracks do
  if tracks[i].play then print(tracks[i].ID,tracks[i].name,tracks[i].Instrument) end
end
print('Notes ready in', os.clock()-currentTime)
print(string.format("Current free memory is %dk (%d%%) ",computer.freeMemory()/1024, computer.freeMemory()/computer.totalMemory()*100))
if options.i then return end
if not options.d then
  print('Press any key to play.')
  io.read()
end

local fireEvents={}
local numEvents=0
for key,_ in pairs(fireTicks) do
  table.insert(fireEvents,key)
  numEvents=numEvents+1
end
table.sort(fireEvents)
fireEvents[numEvents+1]=fireEvents[numEvents]

if instruments==-1 or options.d then
  local beeperEvents={}
  for i=1,numEvents do
    local beeps={}
    for _,noteInfo in pairs(fireTicks[fireEvents[i]]) do
      if tonumber(noteInfo.duration) < 200 then
        beeps[math.max(math.min(noteInfo.frequency,2000),20)]=tonumber(noteInfo.duration)
      end
    end
    table.insert(beeperEvents,{beeps=beeps,delay=(fireEvents[i+1]-fireEvents[i])*tickLength-0.081*speed}) --0.081 is an emperical constant
    fireTicks[fireEvents[i]]=nil
  end
  if options.d then
    local dumpFile = io.open(shell.resolve(args[1]):sub(1,shell.resolve(args[1]):len()-4) .. ".mdp",'w')
    for _,beepInfo in ipairs(beeperEvents) do
      dumpFile:write(tostring(beepInfo.delay) .. "\n")
      dumpFile:write(serialization.serialize(beepInfo.beeps)  .. "\n")
    end
    dumpFile:flush()
    dumpFile:close()
    return
  else
    local beeper=component.getPrimary('beep')
    for _,beepInfo in ipairs(beeperEvents) do
      beeper.beep(beepInfo.beeps)
      os.sleep(beepInfo.delay)
    end
  end
  
elseif instruments==1 then
  local instrument=component.getPrimary('iron_noteblock')
  for i=1,numEvents do
    for _,noteInfo in pairs(fireTicks[fireEvents[i]]) do
      instrument.playNote(noteInfo.instrument,noteInfo.note,noteInfo.volume)
    end
    os.sleep((fireEvents[i+1]-fireEvents[i])*tickLength-0.05)
  end
  
elseif instruments==0 then
  for i=1,numEvents do
    computer.beep(fireTicks[fireEvents[i]][1].frequency,fireTicks[fireEvents[i]][1].duration)
    os.sleep((fireEvents[i+1]-fireEvents[i])*tickLength-fireTicks[fireEvents[i]][1].duration-0.05)
  end
end