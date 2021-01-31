Person = Object.extend(Object)

function Person.new(self)
	self.x = 20
	self.y = 20
	self.radius = 2
	self.speed = 5
	self.tacklestrength = 100
	self.facing = 0	-- radians
	self.rolecode = ""
	self.roletext = ""
	--self.uniform	 = 					-- an image
	self.teamname = ""
	self.fallendown = false
	self.injured = false
	self.acceleration = 0
	self.balance = 1
	--self.intendeddirection = 0
	self.targetcoordx = 250
	self.targetcoordy = 100
end

function Person.update(self,dt)
	--self
	angle = math.atan2(self.targetcoordy - self.y, self.targetcoordx - self.x)
	cos = math.cos(angle)
    sin = math.sin(angle)

    self.x = self.x + self.speed * cos * dt
    self.y = self.y + self.speed * sin * dt	
	
	
end

function Person.draw(self)
	love.graphics.circle("fill", self.x, self.y, self.radius)

end


