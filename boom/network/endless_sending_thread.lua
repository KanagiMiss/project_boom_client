--local netLib = require "library"
local netLib = require "libtcp"
local json = require "libs.json"
--[[load some tool modules
log = require("libs.log")
--require("alien")
log.newfreshlog("logfile_receive.txt")
log.logswitch(true)  --关闭log开关]]
local c = love.thread.getChannel("network_send")
local data = {}
local type = 0
while true do
  type = c:demand()
  string_data = c:demand()
  local result = netLib.Lua_send(type, string_data)
  --log.debug(data)
  --合并data
  --c:supply(data)
  --查看有没有关闭消息
  local msg = c:peek()
  if msg and msg == "stop" then
    break
  end
end
