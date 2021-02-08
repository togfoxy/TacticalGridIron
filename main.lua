--require "sstrict.sstrict"	-- this is the sctrict file inside the sstrict folder (folder.file) with no file extension

fltScaleFactor = 6

intNumOfPlayers = 22

fltPersonWidth = 1.5

intMaxRateofLookingChange = 90		-- player can turn 90 deg each second (affected by dt)

fltPi = 3.14159

bolPlayOver = false
bolKeyPressed = false
bolCheerPlayed = false

objects = {}
objects.ball = {}
intBallCarrier = 10		-- this is the player index that holds the ball. 0 means forming up and not yet snapped.

score = {}
score.downs = 1
score.plays = 0
score.yardstogo = 10

-- Stadium constants
intLeftLineX = 15
intRightLineX = intLeftLineX + 53

intTopPostY = 15	-- how many metres to leave at the top of the screen?
intBottomPostY = 135

intScrimmageY = 105
fltCentreLineY = intLeftLineX + (53/2)	-- left line + half of the field

strGameState = "FormingOnLoS"	--LoS = Line of Scrimmage
bolEndGame = false

-- Uniforms
intHomeTeamColourR = 241 
intHomeTeamColourG = 156
intHomeTeamColourB = 187

intVistingTeamColourR = 255
intVistingTeamColourG = 191
intVistingTeamColourB = 0

soundgo = love.audio.newSource("go.wav", "static") -- the "static" tells LÖVE to load the file into memory, good for short sound effects
soundwhistle = love.audio.newSource("whistle.wav", "static") -- the "static" tells LÖVE to load the file into memory, good for short sound effects
soundcheer = love.audio.newSource("cheer.mp3", "static") -- the "static" tells LÖVE to load the file into memory, good for short sound effects
soundcheer:setVolume(0.2)		-- mp3 file is too loud. Will tweak it here.

footballimage = love.graphics.newImage("football.png")

function InstantiatePlayers()

	love.physics.setMeter(1)
	world = love.physics.newWorld(0,0,true)	-- true = can sleep?
	
	for i = 1,intNumOfPlayers
	do
		objects.ball[i] = {}
		if i < 12 then
			objects.ball[i].body = love.physics.newBody(world, SclFactor(love.math.random(15,60)), SclFactor(love.math.random(90,120)), "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
		else
			objects.ball[i].body = love.physics.newBody(world, SclFactor(love.math.random(30,65)), SclFactor(love.math.random(70,110)), "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
		end
		
		objects.ball[i].body:setLinearDamping(0.1)
		objects.ball[i].shape = love.physics.newCircleShape(SclFactor(fltPersonWidth)) --the ball's shape has a radius of 20
		objects.ball[i].fixture = love.physics.newFixture(objects.ball[i].body, objects.ball[i].shape, 1) -- Attach fixture to body and give it a density of 1.
		objects.ball[i].fixture:setRestitution(0.25) --let the ball bounce
		objects.ball[i].fixture:setUserData((i))
		
		-- the physics model tracks actual velx and vely so we don't need to track that.
		-- we do need to track the desired velx and vely
		-- we also need to track direction of looking, remembering we can look one way and desire to travel another way - like running backwards while looking forwards.
		objects.ball[i].looking = 270	-- Direction of looking in degrees. 0 -> 360. NOT radians.  0 deg = right, not up.
		objects.ball[i].desiredvelx = 0	--
		objects.ball[i].desiredvely = 0
		
		-- customise each player/position based on i
		CustomisePlayers(i)
		
		objects.ball[i].previousdistancetotarget = 1000
		
		objects.ball[i].readyfornextstage = false		-- in position and ready or has ended turn and ready.
		objects.ball[i].fallendown = false
		objects.ball[i].velocityfactor = 1			-- a fudge to slow the player down when needed.
		
		-- mode tracks if they are forming up or running or tackling or trying to catch etc
		objects.ball[i].mode = "forming"
		
		table.insert(objects, ball)
	end
	
	SetFormingOnLoSPlayerTargets()		-- this might be a redundant line?

end

function SclFactor(intNumber)
	-- receive a coordinate or distance and adjust it for the scale factor
	return intNumber * fltScaleFactor
end

function DrawStadium()
	--top goal
	local intRed = 153
	local intGreen = 153
	local intBlue = 255	
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	love.graphics.rectangle("fill", SclFactor(intLeftLineX),SclFactor(intTopPostY),SclFactor(53),SclFactor(10),1)
	
	--bottom goal
	local intRed = 255
	local intGreen = 153
	local intBlue = 51	
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)	
	love.graphics.rectangle("fill", SclFactor(intLeftLineX),SclFactor(125), SclFactor(53),SclFactor(10))
	
	--field
	local intRed = 69
	local intGreen = 172
	local intBlue = 79
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)	
	love.graphics.rectangle("fill", SclFactor(intLeftLineX),SclFactor(25),SclFactor(53),SclFactor(100))
	
	--draw yard lines
	local intRed = 255
	local intGreen = 255
	local intBlue = 255
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	for i = 0,12
	do
		love.graphics.line(SclFactor(intLeftLineX),SclFactor(15 +( i*10)),SclFactor(68),SclFactor(15 +( i*10)))
	end
	
	--draw sidelines
	local intRed = 255
	local intGreen = 255
	local intBlue = 255	
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	love.graphics.line(SclFactor(15),SclFactor(15),SclFactor(15),SclFactor(135))
	love.graphics.line(SclFactor(68),SclFactor(15),SclFactor(68),SclFactor(135))
	
	--draw centre line (for debugging)
	--local intRed = 255
	--local intGreen = 255
	--local intBlue = 255
	--love.graphics.setColor(intRed/255, intGreen/255, intBlue/255,0.7)
	--love.graphics.line(SclFactor(41.5),SclFactor(15),SclFactor(41.5), SclFactor(135))
	
	--draw scrimmage
	local intRed = 93
	local intGreen = 138
	local intBlue = 169
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255,1)
	love.graphics.line(SclFactor(15),SclFactor(intScrimmageY),SclFactor(68), SclFactor(intScrimmageY))	
	
	-- draw score
	local intDownsX = 150
	local intDownsY = 50
	local strText = "Downs: " .. score.downs .. " down and " .. score.yardstogo .. ". Plays: " .. score.plays
	love.graphics.setColor(1, 1, 1,1)
	love.graphics.print (strText,intDownsX,intDownsY)
	
	
end

function SetFormingOnLoSPlayerTargets()
	-- instantiate other game state information
	-- player 1 = QB
	objects.ball[1].targetcoordX = SclFactor(fltCentreLineY)	 -- centre line
	objects.ball[1].targetcoordY = SclFactor(intScrimmageY + 8)
	
--print("QB target Y is " .. objects.ball[1].targetcoordY)
	
	-- player 2 = WR (left closest to centre)
	objects.ball[2].targetcoordX = SclFactor(fltCentreLineY - 20)	 -- left 'wing'
	objects.ball[2].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage

	-- player 3 = WR (right)
	objects.ball[3].targetcoordX = SclFactor(fltCentreLineY + 19)	 -- left 'wing'
	objects.ball[3].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage
	
	-- player 4 = WR (left on outside)
	objects.ball[4].targetcoordX = SclFactor(fltCentreLineY - 24)	 -- left 'wing'
	objects.ball[4].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage

	-- player 5 = RB
	objects.ball[5].targetcoordX = SclFactor(fltCentreLineY)	 -- left 'wing'
	objects.ball[5].targetcoordY = SclFactor(intScrimmageY + 14)	-- just behind scrimmage	
	
	-- player 6 = TE (right side)
	objects.ball[6].targetcoordX = SclFactor(fltCentreLineY + 13)	 -- left 'wing'
	objects.ball[6].targetcoordY = SclFactor(intScrimmageY + 5)	-- just behind scrimmage		
	
	-- player 7 = Centre
	objects.ball[7].targetcoordX = SclFactor(fltCentreLineY)	 -- left 'wing'
	objects.ball[7].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage	
	
	-- player 8 = left guard
	objects.ball[8].targetcoordX = SclFactor(fltCentreLineY - 4)	 -- left 'wing'
	objects.ball[8].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage
	
	-- player 9 = right guard 
	objects.ball[9].targetcoordX = SclFactor(fltCentreLineY + 4)	 -- left 'wing'
	objects.ball[9].targetcoordY = SclFactor(intScrimmageY +2)		-- just behind scrimmage	

	-- player 10 = left tackle 
	objects.ball[10].targetcoordX = SclFactor(fltCentreLineY - 8)	 -- left 'wing'
	objects.ball[10].targetcoordY = SclFactor(intScrimmageY +4)		-- just behind scrimmage	

	-- player 11 = right tackle 
	objects.ball[11].targetcoordX = SclFactor(fltCentreLineY + 8)	 -- left 'wing'
	objects.ball[11].targetcoordY = SclFactor(intScrimmageY +4)		-- just behind scrimmage	

-- now for the visitors

	-- player 12 = Left tackle (left side of screen)
	objects.ball[12].targetcoordX = SclFactor(fltCentreLineY -2)	 -- centre line
	objects.ball[12].targetcoordY = SclFactor(intScrimmageY - 2)
	
	-- player 13 = Right tackle
	objects.ball[13].targetcoordX = SclFactor(fltCentreLineY +2)	 -- left 'wing'
	objects.ball[13].targetcoordY = SclFactor(intScrimmageY - 2)		-- just behind scrimmage

	-- player 14 = Left end
	objects.ball[14].targetcoordX = SclFactor(fltCentreLineY -6)	 -- left 'wing'
	objects.ball[14].targetcoordY = SclFactor(intScrimmageY - 2)		-- just behind scrimmage
	
	-- player 15 = Right end
	objects.ball[15].targetcoordX = SclFactor(fltCentreLineY +6)	 -- left 'wing'
	objects.ball[15].targetcoordY = SclFactor(intScrimmageY - 2)		-- just behind scrimmage

	-- player 16 = Inside LB
	objects.ball[16].targetcoordX = SclFactor(fltCentreLineY)	 -- left 'wing'
	objects.ball[16].targetcoordY = SclFactor(intScrimmageY - 11)	-- just behind scrimmage	
	
	-- player 17 = Left Outside LB
	objects.ball[17].targetcoordX = SclFactor(fltCentreLineY - 15)	 -- left 'wing'
	objects.ball[17].targetcoordY = SclFactor(intScrimmageY - 10)	-- just behind scrimmage		
	
	-- player 18 = Right Outside LB
	objects.ball[18].targetcoordX = SclFactor(fltCentreLineY +15)	 -- left 'wing'
	objects.ball[18].targetcoordY = SclFactor(intScrimmageY - 10)		-- just behind scrimmage	
	
	-- player 19 = Left CB
	objects.ball[19].targetcoordX = SclFactor(fltCentreLineY -24)	 -- left 'wing'
	objects.ball[19].targetcoordY = SclFactor(intScrimmageY -18)	 -- just behind scrimmage
	
	-- player 20 = right CB 
	objects.ball[20].targetcoordX = SclFactor(fltCentreLineY + 19)	 -- left 'wing'
	objects.ball[20].targetcoordY = SclFactor(intScrimmageY -18)		-- just behind scrimmage	

	-- player 21 = left safety 
	objects.ball[21].targetcoordX = SclFactor(fltCentreLineY - 4)	 -- left 'wing'
	objects.ball[21].targetcoordY = SclFactor(intScrimmageY - 17)		-- just behind scrimmage	

	-- player 22 = right safety 
	objects.ball[22].targetcoordX = SclFactor(fltCentreLineY + 4)	 -- left 'wing'
	objects.ball[22].targetcoordY = SclFactor(intScrimmageY - 17)		-- just behind scrimmage	
end

function SetSnappingPlayerTargets()
	-- instantiate other game state information
	-- player 1 = QB
	-- objects.ball[1].targetcoordX = SclFactor(fltCentreLineY - 2)	 
	-- objects.ball[1].targetcoordY = SclFactor(intScrimmageY + 10)
	
	-- player 2 = WR (left closest to centre)
	objects.ball[2].targetcoordX = SclFactor(fltCentreLineY - 17)	 
	objects.ball[2].targetcoordY = SclFactor(intScrimmageY -38)		

	-- player 3 = WR (right)
	objects.ball[3].targetcoordX = SclFactor(fltCentreLineY + 23)	 
	objects.ball[3].targetcoordY = SclFactor(intScrimmageY -20)	
	--print("Player 3 coords is " .. objects.ball[3].body:getX() .. "," .. objects.ball[20].body:getY() )
	
	-- player 4 = WR (left on outside)
	objects.ball[4].targetcoordX = SclFactor(fltCentreLineY - 22)	 
	objects.ball[4].targetcoordY = SclFactor(intScrimmageY - 15)		

	-- player 5 = RB
	objects.ball[5].targetcoordX = SclFactor(fltCentreLineY + 5)	 
	objects.ball[5].targetcoordY = SclFactor(intScrimmageY + 5)		
	
	-- player 6 = TE (right side)
	objects.ball[6].targetcoordX = SclFactor(fltCentreLineY + 5)	 
	objects.ball[6].targetcoordY = SclFactor(intScrimmageY - 20)			
	
	-- player 7 = Centre
	objects.ball[7].targetcoordX = SclFactor(fltCentreLineY)	 
	objects.ball[7].targetcoordY = SclFactor(intScrimmageY - 20)			
	
	-- player 8 = left guard offense
	objects.ball[8].targetcoordX = SclFactor(fltCentreLineY - 4)	 
	objects.ball[8].targetcoordY = SclFactor(intScrimmageY -20)		
	
	-- player 9 = right guard offense
	objects.ball[9].targetcoordX = SclFactor(fltCentreLineY + 4)	 
	objects.ball[9].targetcoordY = SclFactor(intScrimmageY -20)			

	-- player 10 = left tackle 
	objects.ball[10].targetcoordX = SclFactor(fltCentreLineY - 8)	 
	objects.ball[10].targetcoordY = SclFactor(intScrimmageY -20)			

	-- player 11 = right tackle 
	objects.ball[11].targetcoordX = SclFactor(fltCentreLineY -2)	 
	objects.ball[11].targetcoordY = SclFactor(intScrimmageY -20)			

-- now for the visitors

	-- player 12 = Left tackle (left side of screen)
	objects.ball[12].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- chase QB	 
	objects.ball[12].targetcoordY = (objects.ball[intBallCarrier].body:getY())
	
	-- player 13 = Right tackle
	objects.ball[13].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- chase qb 
	objects.ball[13].targetcoordY = (objects.ball[intBallCarrier].body:getY())		

	-- player 14 = Left end
	objects.ball[14].targetcoordX = (objects.ball[intBallCarrier].body:getX())	 -- chase qb
	objects.ball[14].targetcoordY = (objects.ball[intBallCarrier].body:getY())		
	
	-- player 15 = Right end
	objects.ball[15].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- chase qb	 
	objects.ball[15].targetcoordY = (objects.ball[intBallCarrier].body:getY())		

	if not objects.ball[5].fallendown then	-- if RB has not fallen then target the RB
		objects.ball[16].targetcoordX = (objects.ball[5].body:getX())	-- chases running back
		objects.ball[16].targetcoordY = (objects.ball[5].body:getY())	
	else
		objects.ball[12].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- chase QB	 
		objects.ball[12].targetcoordY = (objects.ball[intBallCarrier].body:getY())	
	end
		
	-- Left outside LB
	objects.ball[17].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- line up with the QB
	if (objects.ball[1].body:getY() - objects.ball[17].body:getY()) then	-- check distance to QB
		objects.ball[17].targetcoordY = SclFactor(intScrimmageY - 10)
	else
		objects.ball[17].targetcoordY = (objects.ball[intBallCarrier].body:getY())	-- close in on QB if opportunity presents
	end

	-- player 18 = Right Outside LB
	objects.ball[18].targetcoordX = (objects.ball[5].body:getX())	-- line up with the RB	 
	objects.ball[18].targetcoordY = SclFactor(intScrimmageY - 10)				
		
	-- player 19 = Left CB
	if not objects.ball[4].fallendown then
		objects.ball[19].targetcoordX = (objects.ball[4].body:getX())	-- target WR (left on outside)	 
		objects.ball[19].targetcoordY = (objects.ball[4].body:getY())
	else
		objects.ball[19].targetcoordX = (objects.ball[intBallCarrier].body:getX())	 -- chase qb
		objects.ball[19].targetcoordY = (objects.ball[intBallCarrier].body:getY())		
	end
	
	
	-- player 20 = right CB 
	objects.ball[20].targetcoordX = (objects.ball[3].body:getX())	-- chase right WR	 
	objects.ball[20].targetcoordY = (objects.ball[3].body:getY())		

	-- player 21 = left safety 
	objects.ball[21].targetcoordX = (objects.ball[2].body:getX())	 -- line up with inside left wide receiver
	objects.ball[21].targetcoordY = SclFactor(intScrimmageY - 17)	


	-- player 22 = right safety 
	objects.ball[22].targetcoordX = (objects.ball[3].body:getX())	-- line up with right WR 
	objects.ball[22].targetcoordY = SclFactor(intScrimmageY - 17)				
		
end

function CustomisePlayers(intCounter)
	-- change players stats based on field position
		if intCounter == 1 then
			objects.ball[intCounter].positionletters = "QB"
			objects.ball[intCounter].body:setMass(love.math.random(91,110))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 14.8					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(13.3,14.8)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1495							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 2 or intCounter == 3 or intCounter == 4 then
			objects.ball[intCounter].positionletters = "WR"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.3					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.8,16.3)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1467							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 5 then
			objects.ball[intCounter].positionletters = "RB"
			objects.ball[intCounter].body:setMass(love.math.random(86,106))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.3					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.8,16.3)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1565							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 6 then
			objects.ball[intCounter].positionletters = "TE"
			objects.ball[intCounter].body:setMass(love.math.random(104,124))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.4					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(15.9,15.4)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1756							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 7 then
			objects.ball[intCounter].positionletters = "C"
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.8					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.3,13.8)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1946							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 8 then
			objects.ball[intCounter].positionletters = "LG"					-- left guard offense
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.6					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.1,13.6)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1918							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 9 then
			objects.ball[intCounter].positionletters = "RG"					-- right guard offense
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.6					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.1,13.6)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1918							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 10 then
			objects.ball[intCounter].positionletters = "LT"					-- left tackle offense
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.7					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.2,13.7)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1932							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 11 then
			objects.ball[intCounter].positionletters = "RT"					-- left tackle offense
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.7					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.2,13.7)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1932							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 12 or intCounter == 13 then
			objects.ball[intCounter].positionletters = "DT"
			objects.ball[intCounter].body:setMass(love.math.random(129,149))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 14.5					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(13.0,14.5)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 2016							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 14 then
			objects.ball[intCounter].positionletters = "LE"
			objects.ball[intCounter].body:setMass(love.math.random(116,136))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.2					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(13.7,15.2)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1915							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 15 then
			objects.ball[intCounter].positionletters = "RE"
			objects.ball[intCounter].body:setMass(love.math.random(116,136))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.2					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(13.7,15.2)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1915							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 16 then
			objects.ball[intCounter].positionletters = "ILB"
			objects.ball[intCounter].body:setMass(love.math.random(100,120))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.6					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.1,15.6)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1716							-- maximum force (how much force to apply to make them move)
		
				
		elseif intCounter == 17 or intCounter == 18 then
			objects.ball[intCounter].positionletters = "OLB"
			objects.ball[intCounter].body:setMass(love.math.random(100,120))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.7					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.2,15.7)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1727							-- maximum force (how much force to apply to make them move)

	
		elseif intCounter == 19 or intCounter == 20 then
			objects.ball[intCounter].positionletters = "CB"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.3					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.8,16.3)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1467							-- maximum force (how much force to apply to make them move)
			
	
	
		elseif intCounter == 21 then
			objects.ball[intCounter].positionletters = "SS"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.1					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.6,16.1)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1449	
	
		
			
			
		elseif intCounter == 22 then
			objects.ball[intCounter].positionletters = "FS"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.1					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.6,16.1)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1449	
	

		end
		
end

function GetDistance(x1, y1, x2, y2)
	-- this is real distance in pixels
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2
    --Both of these work
    local a = horizontal_distance * horizontal_distance
    local b = vertical_distance ^2

    local c = a + b
    local distance = math.sqrt(c)
    return distance
end

function CheckBounds(intCounter)
	screenwidth = love.graphics.getWidth()
	screenheight = love.graphics.getHeight()

	if objects.ball[intCounter].body:getX() < 0 then 
		objects.ball[intCounter].body:setX(0)		
	end
	if objects.ball[intCounter].body:getX() > (screenwidth) then
		objects.ball[intCounter].body:setX(screenwidth)
	end
	if objects.ball[intCounter].body:getY() < 0 then
		objects.ball[intCounter].body:setY(0)

	end
	if objects.ball[intCounter].body:getY() > screenheight then
		objects.ball[intCounter].body:setY(screenheight)
	end	

end

function NegateVector(x,y)
	-- return a vector that negates the input vector
	return x*-1, y*-1
end

function ProcessKeyInput()

	-- make sure these are > than maxV 
	local targetadjustmentamountX = 2	-- just one place to adjust this
	local targetadjustmentamountY = 2
	
	bolMoveDown =false
	bolMoveUp = false
	bolMoveLeft = false
	bolMoveRight = false
	bolMoveWait = false
	
	bolAnyKeyPressed = false

	if strGameState == "FormingOnLoS" then
		if love.keyboard.isDown("t") then
			--tilt!
			ExecuteTilt()
		end
	end

	if strGameState == "SnappingBall" then		
		if love.keyboard.isDown("kp2")then
			bolMoveDown = true
			bolAnyKeyPressed = true
		end
		if love.keyboard.isDown("kp8") then
			bolMoveUp = true
			bolAnyKeyPressed = true
		end
		if love.keyboard.isDown("kp4") then
			bolMoveLeft = true
			bolAnyKeyPressed = true
		end
		if love.keyboard.isDown("kp6") then
			bolMoveRight = true
			bolAnyKeyPressed = true
		end	
		if love.keyboard.isDown("kp5") then
			bolMoveWait = true
			bolAnyKeyPressed = true
		end
		
		-- set new targets for the QB based on his current position
		-- important to process diagonals first
		

		if bolMoveup and bolMoveLeft then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX - targetadjustmentamountX)	 
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY - targetadjustmentamountY)
			-- reset these keys so they don't get processed twice
			bolMoveUp = false
			bolMoveLeft = false
			--print("alpha")
		end
		if bolMoveup and bolMoveRight then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX + targetadjustmentamountX)	 
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY - targetadjustmentamountY)
			-- reset these keys so they don't get processed twice
			bolMoveUp = false
			bolMoveRight = false
			--print("beta")
		end	
		if bolMoveDown and bolMoveRight then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX + targetadjustmentamountX)	 
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY + targetadjustmentamountY)
			-- reset these keys so they don't get processed twice
			bolMoveDown = false
			bolMoveRight = false
			--print("charlie")
		end				
		if bolMoveDown and bolMoveLeft then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX - targetadjustmentamountX)	 
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY + targetadjustmentamountY)
			-- reset these keys so they don't get processed twice
			bolMoveDown = false
			bolMoveLeft = false
			--print("delta")
		end			
		if bolMoveUp then
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY - targetadjustmentamountY)
			bolMoveUp = false
			--print("echo")
		end			
		if bolMoveRight then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX + targetadjustmentamountX)
			bolMoveRight = false
			--print("foxtrot")
		end	
		if bolMoveDown then
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY + targetadjustmentamountY)
			bolMoveDown = false
			--print("golf")
		end	
		if bolMoveLeft then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX - targetadjustmentamountX)
			bolMoveLeft = false
			--print("hotel")
		end	
		
		if objects.ball[1].targetcoordX < SclFactor(intLeftLineX) then objects.ball[1].targetcoordX = SclFactor(intLeftLineX) end
		if objects.ball[1].targetcoordX > SclFactor(intRightLineX) then objects.ball[1].targetcoordX = SclFactor(intRightLineX) end
		if objects.ball[1].targetcoordY < SclFactor(intTopPostY) then objects.ball[1].targetcoordY = SclFactor(intTopPostY) end
		if objects.ball[1].targetcoordY > SclFactor(intBottomPostY) then objects.ball[1].targetcoordY = SclFactor(intBottomPostY) end
	end
	
	
	
	if bolAnyKeyPressed == true then
		return true
	else
		return false
	end
end

function GetMultiplyVectors(x1,y1,x2,y2)		-- might rename this
	-- multiply two vectors (dot product)
	-- a positive result means vectors are heading in the same direction (+1 = exactly same direction)
	-- a negative result means vectors are heading in opposite direction (-1 = exactly opposite direction)
	-- zero means vectors are perpendicular (90 degrees)
	return (x1 * x2 ) + (y1 * y2)
end

function GetAngle(x1,y1,x2,y2)	-- returns radians
	-- receives two vectors (delta x, delta y). assuming the same point of origin. It does NOT receive cartesian coordinates
	-- note 2 * pi radians () = full circle (6.28 radians = 1 circle)
	
	-- So if we have two vectors v1=(v1_x, v1_y) and v2=(v2_x, v2_y) we simply do this:
	-- angle=atan2(v2_y, v2_x) - atan2(v1_y, v2_x) 
	-- returns radians. Negative value = vector needs to turn clockwise to 'see' y vector
	
	-- returns a radian value
	return (math.atan2(y2,x2) - math.atan2(y1,x1)) * -1	-- I applied -ve 1 so that positive numbers means turn clockwise. I hope
	
end

function UpdateLooking(oindex)
	-- update player looking value so they turn towards target
	-- might need to change this because sometimes they don't want to look at target
	-- needs to respect the max turn rate for looking

	-- assuming player is at the origin, the hypotenus length = 1 (normalised), then calculate the x and y (delta) based on facing
	-- need to test this for looking at all four quadrants
	-- these next two formulas is a vector - not coords
	-- https://jvm-gaming.org/t/how-do-we-calculate-the-angle-between-two-vectors/29498/11
	-- x = distance * cos(angle)
	-- y = distance * sin(angle)	

	--This is for debugging
	--objects.ball[i].looking = 270		--0 = 'right' so that delta y = 0
	--lookingrads = math.rad(objects.ball[i].looking)
	--local randomx = love.math.random(-15, 15)
	--local randomy = love.math.random(-15, 15)
	--objects.ball[i].body:setLinearVelocity(randomx,randomy)
	--objects.ball[i].vel = 1	-- for debugging
	

	-- determine which way the player is looking
	playerlookingx = 1 * math.cos(math.rad(objects.ball[oindex].looking))	-- this is the delta x. Need to convert the looking to rads
	playerlookingy = 1 * math.sin(math.rad(objects.ball[oindex].looking)) * -1	-- this is the delta y. These are not coords. *-1 because origin not bottom left
	
	--print("player looking = " .. lookingrads .. " rads and " .. "x vector = " .. playerlookingx .. " and y vector = " .. playerlookingy)
	
	-- target vector (from player) is easier: player is origin so target x - player x & target y - player Y
	-- will this need to be normalised? Maybe not
	-- these lines give a (x,y) vector (not coords)
	vectorxtotarget = objects.ball[oindex].targetcoordX - objects.ball[oindex].body:getX()
	vectorytotarget = objects.ball[oindex].targetcoordY - objects.ball[oindex].body:getY()
	vectorytotarget = vectorytotarget * -1	-- need to reverse the sign on the Y vector because screen origin is top left corner (not bottom left corner)
	-- print("target x vector = " .. vectorxtotarget .. " and target y vector = " .. vectorytotarget)
	
	-- turn to target (changing looking) (apply turn rate /dt)
	-- have two vectors so can now determine angle between them
	-- this assumes 0 deg looking is actually 0 deg (to the right!)
	angletotarget = (GetAngle(playerlookingx,playerlookingy,vectorxtotarget,vectorytotarget))	-- these are vectors (delta's) - they are not co-ordinates
	angletotarget = math.deg(angletotarget)	-- convert rads to degrees
	--print("GetAngle = " .. angletotarget .. " rads which is " .. angletotarget .. " degrees of change.")
	
	-- seesms these never fire. Oh well.
	if angletotarget < -180 then 
		angletotarget = angletotarget + 360 
		--print("alpha")
	end	-- convert angles > 180 to something smaller
	if angletotarget > 180 then 
		angletotarget = angletotarget - 360	
		--print("beta")
	end	-- remove silly angles.
	
	-- these two lines should be redundant
	if angletotarget > 359 then angletotarget = angletotarget - 360 end
	if angletotarget < -359 then angletotarget = angletotarget + 360 end
	
	--print("Looking is " .. objects.ball[oindex].looking .. " degrees (from x axis) and will need to turn " .. angletotarget .. " degrees.") 
	
	-- angle to target = +ve if need to turn clockwise
	if angletotarget > 0 then	-- need to turn clockwise
		if angletotarget > intMaxRateofLookingChange then	-- turn as much as possible clockwise
			objects.ball[oindex].looking = objects.ball[oindex].looking + intMaxRateofLookingChange
		else	-- only turn the needed amount clockwise
			objects.ball[oindex].looking = objects.ball[oindex].looking + angletotarget
		end
	else	-- need to turn anti-clockwise
		if angletotarget < (intMaxRateofLookingChange * -1) then	-- turn as much as possible anti-clockwise remembering these are -ve values
			objects.ball[oindex].looking = objects.ball[oindex].looking - intMaxRateofLookingChange
		else	-- only turn the needed amount clockwise
			objects.ball[oindex].looking = objects.ball[oindex].looking + angletotarget	-- this is adding a negative number
		end				
	end
	--print("Looking is now " .. objects.ball[oindex].looking .. " degrees (from x axis).")


end

function SubtractVectors(x1,y1,x2,y2)
	-- subtracts vector2 from vector1 i.e. v1 - v2
	-- returns a vector (an x/y pair)
	return (x1-x2),(y1-y2)
end

function dotVectors(x1,y1,x2,y2)
	-- receives two vectors and assumes same origin
	-- eg: guard is looking in direction x1/y1. His looking vector is 1,1
	-- thief vector from guard is 2,-1  (he's on the right side of the guard)
	-- dot product is 1. This is positive so thief is infront of guard (assuming 180 deg viewing angle)
	return (x1*x2)+(y1*y2)
end

function AddVectors(x1,y1,x2,y2)
	return (x1+x2),(y1+y2)
end

function NormaliseVector(x1,y1)
	-- given a vector, return the same vector with a length of 1 (normalised)
	-- returns a vector
	
	-- calculate the length of the vector
	local dist = GetDistance(0,0,x1,y1)	-- 0,0 is the origin or starting point for a vector of this type (it's all relative!)
	
	-- divide each x/y pair by that length
	return (x1/dist), (y1/dist)
	
end

function MoveEachPlayer(dtime)
-- returns TRUE if every player reached their target.
-- print("New QB target is " .. objects.ball[1].targetcoordX .. " / " .. objects.ball[1].targetcoordY)
		
	local intReadyForNextStage = 0	-- Count how many are ready for next stage
	local intendedvector = {}
	
	for i = 1,intNumOfPlayers do
		
		objects.ball[i].body:setActive(true)
		
		if strGameState == "FormingOnLoS" then
			-- stand up
			objects.ball[i].fallendown = false
			bolPlayOver = false
			objects.ball[i].fixture:setSensor(false)
		end
		
		if objects.ball[i].fallendown then
			-- don't move
			print("beta")
			objects.ball[i].fixture:setSensor(false)
		else
		
			print("charlie")
			objects.ball[i].fixture:setSensor(true)
			
			-- this is measured in screen coords
			playerdistancetotarget = GetDistance(objects.ball[i].body:getX(),objects.ball[i].body:getY(),objects.ball[i].targetcoordX,objects.ball[i].targetcoordY)
			--print("Distance to target = " .. playerdistancetotarget)
		
			-- if on target then
			if playerdistancetotarget < 3 then
				-- turn to match targets velocity
				-- match target's speed
				if strGameState == "FormingOnLoS" then
					objects.ball[i].mode = "readyforsnap"
				end
			else
			
				print("Delta")
				-- not reached target
				if strGameState == "FormingOnLoS" then
					objects.ball[i].mode = "forming"		-- don't think this is actually used.
				end
			
				UpdateLooking(i)
				
				-- determine actual velocity vs intended velocity based on target
				-- determine which way the player is moving
				local playervelx
				local playervely
				playervelx, playervely = objects.ball[i].body:getLinearVelocity()		-- this is the players velocity vector
				
				if i == 1 then
					-- print("Vector x = " .. playervelx .. " and vector y = " .. playervely)
				end

				-- determine vector to target
				local vectorxtotarget
				local vectorytotarget
				vectorxtotarget = objects.ball[i].targetcoordX - objects.ball[i].body:getX()
				vectorytotarget = objects.ball[i].targetcoordY - objects.ball[i].body:getY()				
				
				-- determine the aceleration vector that needs to be applied to the velocity vector to reach the target.
				-- target vector - player velocity vector
				local acelxvector,acelyvector = SubtractVectors(vectorxtotarget, vectorytotarget,playervelx,playervely)
			
				-- so we now have mass and aceleration. Time to determine Force.
				-- F = m * a
				-- Fx = m * Xa
				-- Fy = m * Ya
				local intendedxforce = 0
				local intendedyforce = 0
				intendedxforce = objects.ball[i].body:getMass() * acelxvector
				intendedyforce = objects.ball[i].body:getMass() * acelyvector		-- this might need to be  * -1
				
				-- if target is in front and at max v, then cut the force to apply
				if dotVectors(playervelx, playervely,vectorxtotarget,vectorytotarget) > 0 then
					if (playervelx > objects.ball[i].maxV) or (playervelx < (objects.ball[i].maxV * -1)) then
						-- don't apply any force
						intendedxforce = 0
					end

					if (playervely > objects.ball[i].maxV) or (playervely < (objects.ball[i].maxV * -1)) then
						-- don't apply any force
						intendedyforce = 0
					end
				end
			
				-- need to limit force to human limitations
				if intendedxforce > objects.ball[i].maxF then
					intendedxforce = objects.ball[i].maxF
				end
				if intendedyforce > objects.ball[i].maxF then
					intendedyforce = objects.ball[i].maxF
				end
				
				if i == 1 then
					print("intended x force = " .. intendedxforce .. " and intended y force is " .. intendedyforce)
				end
				
				print("foxtrot. Gamestate = " .. strGameState .. " " .. dtime)
				objects.ball[i].body:applyForce(intendedxforce,intendedyforce)
			end
			
			-- check for next gamestage
			if objects.ball[i].mode == "readyforsnap" then		-- this will need to be set somewhere at some point
				intReadyForNextStage = intReadyForNextStage + 1
				if intReadyForNextStage > 21 then
					strGameState = "SnappingBall"
					return true
				end
			end
		end
		
		-- check if ball carrier is out of bounds
		if strGameState == "SnappingBall" then
			print("echo")
			ballX = objects.ball[intBallCarrier].body:getX()
			ballY = objects.ball[intBallCarrier].body:getY()
			if ballX < SclFactor(intLeftLineX) or ballX > SclFactor(intRightLineX) then
				-- oops - ball out of bounds
				bolPlayOver = true
				print("Out of bounds")
			end
		end		
		
		
	end	
		

end

function ExecuteFormingOnLoS(dtime)

	SetFormingOnLoSPlayerTargets(dtime)
	
	bolKeyPressed = ProcessKeyInput()	

	local bolAllPlayersReachTarget = MoveEachPlayer(dtime)
	-- print(bolAllPlayersReachTarget)
	
	if bolAllPlayersReachTarget then
		strGameState = "SnappingBall"
		
		soundgo:play()
		score.plays = score.plays + 1
	end

end

function ExecuteSnappingBall(dtime)
	-- set new targets
	
	if intBallCarrier == 0 then intBallCarrier = 1 end	-- QB gets the ball
	
	SetSnappingPlayerTargets()
	
	bolKeyPressed = ProcessKeyInput()
	
print("Keypress = " .. tostring(bolKeyPressed))

	if bolKeyPressed then	-- only move players if a key is pressed
		print("alpha")
		local bolAllPlayersReachTarget = MoveEachPlayer(dtime)
		-- print(bolAllPlayersReachTarget)
	
		if bolAllPlayersReachTarget then
			strGameState = "FormingonLoS"
			intBallCarrier = 0
		end
	end	
	
end

function ExecuteTilt()
	-- someone is stuck. Bump the table!
	
	local intTiltStrength = 3000
	
	for i = 1,intNumOfPlayers do
		objects.ball[i].body:applyForce(love.math.random(-1 * intTiltStrength,intTiltStrength) , love.math.random(-1 * intTiltStrength,intTiltStrength))
	end
	
	print("Tilt!")

end

function beginContact(a, b, coll)
	-- Gets called when two fixtures begin to overlap.
	aindex = a:getUserData()
	bindex = b:getUserData()	
	local intJiggleForce = 100
	
	if strGameState == "FormingOnLoS" then		-- only jostle if forming up
		local tmpforceamount = 2000

		--apply a momentary negative impulse
		currentlinvelx, currentlinvely = objects.ball[aindex].body:getLinearVelocity()
		--if currentlinvelx > 0 then
			tempforcex = intJiggleForce * tmpforceamount
		--else
			tempforcex = tmpforceamount
		--end
		
		--if currentlinvely > 0 then
			tempforcey = intJiggleForce * tmpforceamount
		--else
			tempforcey = intJiggleForce --* tmpforceamount
		--end
		
		objects.ball[aindex].body:applyForce(tempforcex * love.math.random(0.5,1.5) , tempforcey *love.math.random(0.5,1.5))
		objects.ball[bindex].body:applyForce(tempforcex * love.math.random(0.5,1.5) , tempforcey *love.math.random(0.5,1.5))
		--objects.ball[bindex].body:applyForce(tempforcex * -1 , tempforcey * -1)
		
		--print("Applied force " .. tempforcex .. ", " .. tempforcey .. " to players " .. aindex .. " and " .. bindex)
	end
	
	if strGameState == "SnappingBall" then
		local negxvector,negyvector
		
		-- if already fallen down then don't calculate anything
		if (objects.ball[aindex].fallendown) then
			negxvector,negyvector = NegateVector(objects.ball[aindex].body:getX(),objects.ball[aindex].body:getY())
			objects.ball[aindex].body:applyForce(negxvector,negyvector)
			objects.ball[aindex].body:setLinearVelocity(0,0)
			objects.ball[aindex].fixture:setSensor(false)
			--print(aindex .. " has fallen down and contacted")
		end
		
		if (objects.ball[bindex].fallendown) then
			negxvector,negyvector = NegateVector(objects.ball[bindex].body:getX(),objects.ball[bindex].body:getY())
			objects.ball[bindex].body:applyForce(negxvector,negyvector)
			objects.ball[bindex].fixture:setSensor(false)
			--print(bindex .. " has fallen down and contacted")
		end
		
		if (objects.ball[aindex].fallendown == false) and (objects.ball[bindex].fallendown == false) then
			-- don't let a person on same team knock player down
			if (aindex < 12 and bindex < 12) or (aindex > 11 and bindex > 11) then
				-- same team. do nothing
			else
				-- see if first object falls down
				bolFallsDown = (love.math.random(1,20) == 1)
				if bolFallsDown and strGameState == "SnappingBall" then
					objects.ball[aindex].fixture:setSensor(false)
					objects.ball[aindex].fallendown = true
					objects.ball[aindex].body:setLinearVelocity(0,0)
					negxvector,negyvector = NegateVector(objects.ball[aindex].body:getX(),objects.ball[aindex].body:getY())
					objects.ball[aindex].body:applyForce(negxvector,negyvector)				
				end
				
				-- see if 2nd object fallse down
				bolFallsDown = (love.math.random(1,20) == 1)
				if bolFallsDown and strGameState == "SnappingBall" then
					objects.ball[bindex].fixture:setSensor(false)
					objects.ball[bindex].fallendown = true
					objects.ball[bindex].body:setLinearVelocity(0,0)
					negxvector,negyvector = NegateVector(objects.ball[bindex].body:getX(),objects.ball[bindex].body:getY())
					objects.ball[bindex].body:applyForce(negxvector,negyvector)					
				end	
				
				-- check for end game
				if objects.ball[1].fallendown == true then
					bolPlayOver = true
					print("QB is sacked.")
				end
			end
		end
	end

end
 
function endContact(a, b, coll)
	-- Gets called when two fixtures cease to overlap. This will also be called outside of a world update, when colliding objects are destroyed.
 
end
 
function preSolve(a, b, coll)
	-- Gets called before a collision gets resolved.
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
  -- Gets called after the collision has been resolved.
end

function round(num, idp)
	--Input: number to round; decimal places required
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	

function love.load()

	--set window
	void = love.window.setMode(SclFactor(83), SclFactor(150))
	love.window.setTitle("Love football")

	InstantiatePlayers()
	
end

function love.update(dt)

	if strGameState == "FormingOnLoS" then
		ExecuteFormingOnLoS(dt)
	end
	if strGameState == "SnappingBall" then
		-- print("Snap")
		ExecuteSnappingBall(dt)
	end
	
	
	if bolPlayOver == true then
		soundwhistle:play()
		strGameState = "FormingOnLoS"
		
		bolPlayOver = false
		score.downs = score.downs + 1
		
--print(objects.ball[1].body:getY() .. "  "  .. intScrimmageY   )

		if objects.ball[1].body:getY() <= SclFactor(intScrimmageY - 10) then
			-- reset downs
			score.downs = 1
			score.yardstogo = 10
		else
			-- recalc yards to go
			score.yardstogo = round(((objects.ball[1].body:getY() - SclFactor(intScrimmageY - 10)) / fltScaleFactor),0)
		end
		
		intScrimmageY = (objects.ball[1].body:getY() / fltScaleFactor )
		
		-- check for end game
		if score.downs > 4 then
			print("Turnover on downs.")
			bolEndGame = true
		end
	end	
	
	if objects.ball[1].body:getY() < SclFactor(25) then
		-- touchdown
		if not bolCheerPlayed then
			soundcheer:play()
			bolCheerPlayed = true
		end
		
		print("Touchdown!")
		bolEndGame = true
	end

--print(bolKeyPressed)
	
	if strGameState == "SnappingBall" and bolKeyPressed == false then
		-- dont update sim
	elseif bolEndGame then
		-- don't update sim
	else
		world:update(dt) --this puts the world into motion
		world:setCallbacks(beginContact, endContact, preSolve, postSolve)
	end
end

function love.draw()

	DrawStadium()

	--if not bolEndGame then
	for i = 1,intNumOfPlayers do
	
		local playervectorx
		local playervectory		
		playervectorx, playervectory = objects.ball[i].body:getLinearVelocity()	-- velocity
		local x1 = objects.ball[i].body:getX()
		local y1 = objects.ball[i].body:getY()
		local x2 = objects.ball[i].body:getX() + SclFactor(playervectorx)
		local y2 = objects.ball[i].body:getY() + SclFactor(playervectory)		
	
	--for i = 1,1 do
		if i < 12 then
			-- set home team colours
			love.graphics.setColor(intHomeTeamColourR/255, intHomeTeamColourG/255, intHomeTeamColourB/255) --set the drawing color
		else
			love.graphics.setColor(intVistingTeamColourR/255, intVistingTeamColourG/255, intVistingTeamColourB/255) --set the drawing color
		end
		
		-- the QB is special
		if i == 1 then
			love.graphics.setColor(240/255, 101/255, 152/255) --set the drawing color
		
		end
	
		-- draw player
		love.graphics.circle("fill", objects.ball[i].body:getX(), objects.ball[i].body:getY(), objects.ball[i].shape:getRadius())
		
		-- draw looking
		local lookinglength = fltPersonWidth / 2	-- radius of one player
		playerlookingx = lookinglength * math.cos(math.rad(objects.ball[i].looking))	-- this is the delta x. Need to convert the facing to rads
		playerlookingy = lookinglength * math.sin(math.rad(objects.ball[i].looking))
		--print("Player is facing " .. objects.ball[i].facing .. " degrees. Vector X/Y = " .. playerlookingx, " : " .. playerlookingy)
		love.graphics.setColor(0, 0, 0,1) --set the drawing color
		love.graphics.line(objects.ball[i].body:getX(), objects.ball[i].body:getY(), objects.ball[i].body:getX() + SclFactor(playerlookingx) ,objects.ball[i].body:getY() + SclFactor(playerlookingy))
		
		-- draw velocity

		love.graphics.setColor(0, 0, 0,1,0.5) --set the drawing color
		love.graphics.line(x1, y1, x2 ,y2 )
		
		
		-- draw a fallen down marker
		if objects.ball[i].fallendown == true then
			markerradius = objects.ball[i].shape:getRadius()
			markerradius = markerradius/2
			love.graphics.setColor(1, 0, 0,1) --set the drawing color
			love.graphics.circle("fill", objects.ball[i].body:getX(), objects.ball[i].body:getY(), markerradius)
		end
	end
	
	-- draw QB target if there is one.
	if strGameState == "SnappingBall" then
		love.graphics.setColor(1, 0, 0,1) --set the drawing color
		love.graphics.circle("line", objects.ball[1].targetcoordX, objects.ball[1].targetcoordY, objects.ball[1].shape:getRadius())		
	end
	
	-- draw football
	if strGameState == "SnappingBall" then
		love.graphics.setColor(1, 1, 1,1) --set the drawing color
		love.graphics.draw(footballimage, objects.ball[1].body:getX(), objects.ball[1].body:getY(),0,0.33,0.33,5,25)
	end
	

end














