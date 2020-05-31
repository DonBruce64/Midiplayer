--Demo program for the colorful_lamp block.

local light = component.list("colorful_lamp")()
local colors = {0, 31, 992, 1023, 31744, 31775, 32736, 32767}
local currentColor = 1;

if not light then
  return
end

while true do
  component.invoke(light, "setLampColor", colors[currentColor])
  computer.pullSignal(1)
  if currentColor ~= 8 then
    currentColor = currentColor + 1
  else
    currentColor = 1
  end
end