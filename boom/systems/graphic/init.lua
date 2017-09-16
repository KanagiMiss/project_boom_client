local PolygonDraw = require "boom.systems.graphic.PolygonDraw"
local PlayerDraw = require "boom.systems.graphic.PlayerDraw"
local ShaderPolygonSync = require "boom.systems.graphic.ShaderPolygonSync"
local ShaderCircleSync = require "boom.systems.graphic.ShaderCircleSync"
local LightPhysicSync = require "boom.systems.graphic.LightPhysicSync"
local STIObjectSync = require "boom.systems.graphic.STIObjectSync"

local graphic = {
  PolygonDraw = PolygonDraw(),
  PlayerDraw = PlayerDraw(),
  ShaderPolygonSync = ShaderPolygonSync(),
  ShaderCircleSync = ShaderCircleSync(),
  LightPhysicSync = LightPhysicSync(),
  STIObjectSync = STIObjectSync()
}

return graphic
