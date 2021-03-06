local network = require("boom.network")
local timer = require("libs.hump.timer")
local Ping = class("Ping", System)

local elapsed = 0.0
local every = 1.000

function Ping:update(dt)
    elapsed = elapsed + dt
    if elapsed > every then
      elapsed = 0.0
      network:instance():ping()
    end
end

function Ping:requires()
    return {"Nothing"}
end

return Ping
