function love.conf(t)
	t.identity = "PROJBOOM"
	t.title = "PROJBOOM"
	t.console = false
	t.window.msaa = 2
	t.window.vsync = true
	t.window.height = 600
	t.window.width = 800
	t.window.fullscreen = false
  t.modules.image = true
  t.modules.timer = true
end