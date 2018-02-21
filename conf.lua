function love.conf(t)
	t.title = "Wyx"
	t.author = "SCx Games"
	t.identity = "wyx"
	t.release = true
	t.version = "0.8.0"
	t.screen.width = 1024
	t.screen.height = 768
	t.screen.fullscreen = false
	t.screen.vsync = false
	t.screen.fsaa = 0
	t.modules.joystick = false
	t.modules.audio = true
	t.modules.keyboard = true
	t.modules.event = true
	t.modules.image = true
	t.modules.graphics = true
	t.modules.timer = true
	t.modules.mouse = true
	t.modules.sound = true
	t.modules.physics = false
end
