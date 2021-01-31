function love.load()
    Object = require "classic"
    --require "rectangle"
	require "person"
	
    --r1 = Rectangle()
    --r2 = Rectangle()
	
	p1 = Person()
	p2 = Person()
end

function love.update(dt)
    --r1.update(r1, dt)
	p1.update(p1,dt)
end

function love.draw()
    --r1.draw(r1)
	p1.draw(p1)
end