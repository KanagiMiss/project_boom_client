-- create initial static objects
local createWorld = function()
    love.physics.setMeter(32)
    return love.physics.newWorld(0, 0, true)
end

return createWorld
