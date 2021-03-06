local particle_canvas = {}

function particle_canvas:getCanvas()
  if particle_canvas.canvas == nil then
    particle_canvas.canvas = love.graphics.newCanvas()
  end
  return particle_canvas.canvas
end

function particle_canvas:draw()
  if self.canvas then
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setColor(255,255,255,255)
    local bm = love.graphics.getBlendMode()
    love.graphics.setBlendMode("add")
    love.graphics.draw(self.canvas)
    love.graphics.setBlendMode(bm)
    love.graphics.pop()
    -- clear canvas
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    love.graphics.setCanvas()
  end
end

return particle_canvas
