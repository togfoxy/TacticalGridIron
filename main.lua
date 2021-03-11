--require "sstrict.sstrict"

gameversion = "v0.13"

local Slab = require 'Slab'

Camera = require "hump.camera"
fltCameraSmoothRate = 0.025	-- how fast does the camera zoom
fltFinalCameraZoom = 1		-- the needed/required zoom rate
fltCurrentCameraZoom = 1	-- the camera won't tell us it's zoom so we need to track it globally

strGameState = "FormingUp"
strPreviousGameState = strGameState
strMessageBox = "Players getting ready"	
intNumOfPlayers = 22

-- Stadium constants
fltScaleFactor = 6
intLeftLineX = 15	-- how many metres to leave at the leftside of the field?
intTopPostY = 15	-- how many metres to leave at the top of the screen?
intFieldWidth = 53	-- how wide (yards/metres) is the field?
intRightLineX = intLeftLineX + intFieldWidth
intBottomPostY = intTopPostY + 120
fltCentreLineX = intLeftLineX + (intFieldWidth/2)	-- left line + half of the field
intTopGoalY = intTopPostY + 10
intBottomGoalY = intTopPostY + 110

intScrimmageY = intTopPostY + 90
intFirstDownMarker = intScrimmageY - 10		-- yards

-- Uniforms
intHomeTeamColourR = 241 
intHomeTeamColourG = 156
intHomeTeamColourB = 187
intHomeQBColourR = 240
intHomeQBColourG = 101
intHomeQBColourB = 152
intVistingTeamColourR = 255
intVistingTeamColourG = 191
intVistingTeamColourB = 0

score = {}
score.downs = 1	-- default to '1'
score.plays = 0
score.yardstogo = 10

objects = {}
objects.ball = {}

playerroutes = {}
route = {}
coord = {}

football = {}
football.x = nil
football.y = nil
football.targetx = nil
football.targety = nil
football.carriedby = nil
football.airborne = nil

mouseclick = {}
mouseclick.x = nil
mouseclick.y = nil

intThrowSpeed = 40

intBallCarrier = 1		-- this is the player index that holds the ball. 0 means forming up and not yet snapped.
fltPersonWidth = 1.5
bolPlayOver = false
bolEndGame = false
bolMoveChains = false

soundgo = love.audio.newSource("go.wav", "static") -- the "static" tells LÖVE to load the file into memory, good for short sound effects
soundwhistle = love.audio.newSource("whistle.wav", "static") -- the "static" tells LÖVE to load the file into memory, good for short sound effects
soundcheer = love.audio.newSource("cheer.mp3", "static") -- the "static" tells LÖVE to load the file into memory, good for short sound effects
soundwin = love.audio.newSource("29DarkFantasyStudioTreasure.wav", "static")
soundlost = love.audio.newSource("524661aceinetlostphase3.wav", "static")

soundcheer:setVolume(0.3)		-- mp3 file is too loud. Will tweak it here.
soundwin:setVolume(0.2)

-- load images
imgPlayerImages = {}
imgmudimage = {}
mudpair = {0,0}
mudimages = {}

footballimage = love.graphics.newImage("football.png")
imgmudimage[1] = love.graphics.newImage("mudv1.png")

imgPlayerImages[1] = love.graphics.newImage("blueplayer1.png")


-- *******************************************************************************************************************

function InstantiatePlayers()

	love.physics.setMeter(1)
	world = love.physics.newWorld(0,0,false)	-- true = can sleep?
	
	for i = 1,intNumOfPlayers
	do
		objects.ball[i] = {}
		if i < 12 then
			objects.ball[i].body = love.physics.newBody(world, SclFactor(love.math.random(25,60)), SclFactor(love.math.random(105,120)), "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
		else
			objects.ball[i].body = love.physics.newBody(world, SclFactor(love.math.random(30,55)), SclFactor(love.math.random(85,110)), "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
		end
		
		objects.ball[i].body:setLinearDamping(0.7)	-- this applies braking force and removes inertia
		objects.ball[i].shape = love.physics.newCircleShape(SclFactor(fltPersonWidth)) --the ball's shape has a radius of 20
		objects.ball[i].fixture = love.physics.newFixture(objects.ball[i].body, objects.ball[i].shape, 1) -- Attach fixture to body and give it a density of 1.
		objects.ball[i].fixture:setRestitution(0.25) --let the ball bounce
		objects.ball[i].fixture:setSensor(true)	-- start without collisions
		objects.ball[i].fixture:setUserData((i))
		
		objects.ball[i].fallendown = false
		objects.ball[i].balance = 5	-- this is a percentage eg 5% chance of falling down
		objects.ball[i].currentaction = "forming"
		objects.ball[i].catchskill = love.math.random(70,80)				-- % chance of catching ball
		
	end
end

function CustomisePlayers()
	-- change players stats based on field position
	-- this should be run once only
	
	for intCounter = 1,intNumOfPlayers do
		if intCounter == 1 then
			objects.ball[intCounter].positionletters = "QB"
			objects.ball[intCounter].body:setMass(love.math.random(91,110))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 14.8					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(13.3,14.8)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1495							-- maximum force (how much force to apply to make them move)
			objects.ball[intCounter].throwaccuracy = love.math.random(0,10)	-- this distance ball lands from intended target
		elseif intCounter == 2 or intCounter == 3 or intCounter == 4 then
			objects.ball[intCounter].positionletters = "WR"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.3					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.8,16.3)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1467							-- maximum force (how much force to apply to make them move)
			objects.ball[intCounter].catchskill = love.math.random(80,90)			-- % chance of catching ball
			-- if catchskill is changed here then need to update coloured boxes
			
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
			
		-- opposing team
		
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
			objects.ball[intCounter].positionletters = "S"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.1					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.6,16.1)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1449	
		elseif intCounter == 22 then
			objects.ball[intCounter].positionletters = "S"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.1					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.6,16.1)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1449	
		end
	end
		
end

function SclFactor(intNumber)
	-- receive a coordinate or distance and adjust it for the scale factor
	return (intNumber * fltScaleFactor)
end

function DrawStadium()

	--top goal
	local intRed = 153
	local intGreen = 153
	local intBlue = 255	
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	-- rectangles are width and height 
	love.graphics.rectangle("fill", SclFactor(intLeftLineX),SclFactor(intTopPostY),SclFactor(intFieldWidth),SclFactor(10),1)
	
	--bottom goal
	local intRed = 255
	local intGreen = 153
	local intBlue = 51	
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)	
	-- rectangles are width and height 
	love.graphics.rectangle("fill", SclFactor(intLeftLineX),SclFactor(125), SclFactor(intFieldWidth),SclFactor(10))
	
	--field
	local intRed = 69
	local intGreen = 172
	local intBlue = 79
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)	
	-- rectangles are width and height 
	love.graphics.rectangle("fill", SclFactor(intLeftLineX),SclFactor(25),SclFactor(intFieldWidth),SclFactor(100))
	

	--draw yard lines
	local intRed = 255
	local intGreen = 255
	local intBlue = 255
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	for i = 0,20
	do
		love.graphics.line(SclFactor(intLeftLineX),SclFactor(intTopGoalY +( i*5)),SclFactor(intRightLineX),SclFactor(intTopGoalY +( i*5)))
	end

	
	-- draw left and right mini-yard lines
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	for i = 1, 99 do
		-- draw left tick mark
		love.graphics.line(SclFactor(intLeftLineX + 1),SclFactor(intTopGoalY + i),SclFactor(intLeftLineX + 2),SclFactor(intTopGoalY + i))
		
		-- draw left and right hash marks (inbound lines)		
		love.graphics.line(SclFactor(intLeftLineX + 22), SclFactor(intTopGoalY + i), SclFactor(intLeftLineX + 23),SclFactor(intTopGoalY + i))
		love.graphics.line(SclFactor(intRightLineX - 23), SclFactor(intTopGoalY + i), SclFactor(intRightLineX - 22),SclFactor(intTopGoalY + i))
		
		-- draw right tick lines
		love.graphics.line(SclFactor(intRightLineX -2),SclFactor(intTopGoalY + i),SclFactor(intRightLineX - 1),SclFactor(intTopGoalY + i))
	end
	
	--draw sidelines
	local intRed = 255
	local intGreen = 255
	local intBlue = 255	
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	love.graphics.line(SclFactor(15),SclFactor(15),SclFactor(15),SclFactor(135))
	love.graphics.line(SclFactor(intRightLineX),SclFactor(15),SclFactor(intRightLineX),SclFactor(135))
	
	--draw centre line (for debugging)
	--local intRed = 255
	--local intGreen = 255
	--local intBlue = 255
	--love.graphics.setColor(intRed/255, intGreen/255, intBlue/255,0.7)
	--love.graphics.line(SclFactor(41.5),SclFactor(15),SclFactor(41.5), SclFactor(135))
	
	-- draw mud
	love.graphics.setColor(1, 1, 1,0.6)
	for i = 1, #mudimages do
		love.graphics.draw(imgmudimage[1],mudimages[i][1],mudimages[i][2],0, 0.50,0.50, 20,20)
	end
	
	--draw scrimmage
	local intRed = 93
	local intGreen = 138
	local intBlue = 169
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255,1)
	love.graphics.setLineWidth(5)
	love.graphics.line(SclFactor(15),SclFactor(intScrimmageY),SclFactor(intRightLineX), SclFactor(intScrimmageY))	
	love.graphics.setLineWidth(1)	-- return width back to default
	
	-- draw first down marker
	local intRed = 255
	local intGreen = 255
	local intBlue = 51
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255,1)
	love.graphics.setLineWidth(5)
	love.graphics.line(SclFactor(15),SclFactor(intFirstDownMarker),SclFactor(intRightLineX), SclFactor(intFirstDownMarker))	
	love.graphics.setLineWidth(1)	-- return width back to default	

	

	--DrawScores()
	
	-- draw instructions
	--love.graphics.setColor(1, 1, 1,1)	
	-- love.graphics.draw(imgInstructions, SclFactor(intRightLineX + 100),SclFactor(intTopPostY))	
	--love.graphics.draw(imgInstructions, (intRightLineX + 350),(intTopPostY + 300), _, 0.5,0.5)	
end

function DrawScores()
	-- draw the background box
	local intBoxX = SclFactor(0)
	local intBoxY = SclFactor(0)
	local intScreenwidth,intscreenheight, _ = love.window.getMode()
	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.rectangle("fill", intBoxX,intBoxY,intScreenwidth, SclFactor(10)) -- x,y,width,height. Width is left/right. Height is top/down
	

	-- draw score
	local intScoreX = SclFactor(17)
	local intScoreY = SclFactor(2)
	local strText = "Downs: " .. score.downs .. " down and " .. score.yardstogo .. " yards to go. Plays: " .. score.plays
	love.graphics.setColor(1, 1, 1)
	love.graphics.print (strText,intScoreX,intScoreY)
	
	-- draw messagebox
	local intMsgX = SclFactor(25)
	local intMsgY = SclFactor(5)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print (strMessageBox,intMsgX,intMsgY)		
	
end
	
function DrawAllPlayers()
	-- do two passes - one for the fallen, then repeat for the non-fallen

	for i = 1, intNumOfPlayers do
		if objects.ball[i].fallendown then
	
			local objX = objects.ball[i].body:getX()
			local objY = objects.ball[i].body:getY()
			local objRadius = objects.ball[i].shape:getRadius()
			if i < 12 then
				-- set home team colours
				love.graphics.setColor(intHomeTeamColourR/255, intHomeTeamColourG/255, intHomeTeamColourB/255) --set the drawing color
			else
				love.graphics.setColor(intVistingTeamColourR/255, intVistingTeamColourG/255, intVistingTeamColourB/255) --set the drawing color
			end	
			
			-- after setting team colours, override the QB colour
			if i == 1 then
				love.graphics.setColor(intHomeQBColourR/255, intHomeQBColourG/255, intHomeQBColourB/255) -- QB colour
			end
			
			
			-- draw player
			love.graphics.circle("fill", objX, objY, objRadius)	
			-- draw a cute black outline
			love.graphics.setColor(0, 0, 0,0.25) --set the drawing color
			love.graphics.circle("line", objX, objY, objRadius)
			
			-- draw their number
			-- love.graphics.setColor(0, 0, 0,0.25) ---set the drawing color
			-- love.graphics.print(i,objX-7,objY-7)
			
			-- draw their position
			love.graphics.setColor(0, 0, 0,0.25) ---set the drawing color
			love.graphics.print(objects.ball[i].positionletters,objX-7,objY-7)
			
			-- draw fallen down
			if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
				if objects.ball[i].fallendown then
					local markerradius = objects.ball[i].shape:getRadius()
					markerradius = markerradius/2
					love.graphics.setColor(1, 0, 0,0.50) --set the drawing color
					love.graphics.circle("fill", objX, objY, markerradius)
				end
			end
		end
	end
	
	-- now repeat for the non-fallen
	for i = 1, intNumOfPlayers do
		if not objects.ball[i].fallendown then
	
			local objX = objects.ball[i].body:getX()
			local objY = objects.ball[i].body:getY()
			local objRadius = objects.ball[i].shape:getRadius()
			if i < 12 then
				-- set home team colours
				love.graphics.setColor(intHomeTeamColourR/255, intHomeTeamColourG/255, intHomeTeamColourB/255) --set the drawing color
			else
				love.graphics.setColor(intVistingTeamColourR/255, intVistingTeamColourG/255, intVistingTeamColourB/255) --set the drawing color
			end	
			
			-- after setting team colours, override the QB colour
			if i == 1 then
				love.graphics.setColor(intHomeQBColourR/255, intHomeQBColourG/255, intHomeQBColourB/255) -- QB colour
			end
			
			
			-- draw player
			love.graphics.circle("fill", objX, objY, objRadius)	
			-- draw a cute black outline
			love.graphics.setColor(0, 0, 0,0.5) --set the drawing color
			love.graphics.circle("line", objX, objY, objRadius)
			
			-- draw their number
			-- love.graphics.setColor(0, 0, 0,1) ---set the drawing color
			-- love.graphics.print(i,objX-7,objY-7)
			
			-- draw their position
			love.graphics.setColor(0, 0, 0,1) ---set the drawing color
			love.graphics.print(objects.ball[i].positionletters,objX-7,objY-7)
			
			-- draw fallen down
			if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
				if objects.ball[i].fallendown then
					local markerradius = objects.ball[i].shape:getRadius()
					markerradius = markerradius/2
					love.graphics.setColor(1, 0, 0,1) --set the drawing color
					love.graphics.circle("fill", objX, objY, markerradius)
				end
			end
		end
	end	
	
	--love.graphics.setColor(1, 1, 1,1) --set the drawing color
	--love.graphics.draw(imgPlayerImages[1], objects.ball[1].body:getX(), objects.ball[1].body:getY(),4.7,0.5,0.5,10,10) -- radians, x scale, y scale, offset, offset	
end

function DrawPlayersVelocity()

	for i = 1,intNumOfPlayers do
	
		if intBallCarrier == i then
	
			local playervectorx, playervectory = objects.ball[i].body:getLinearVelocity()	-- velocity		
			local objX = objects.ball[i].body:getX()
			local objY = objects.ball[i].body:getY()
			local objXvel = objects.ball[i].body:getX() + SclFactor(playervectorx)
			local objYvel = objects.ball[i].body:getY() + SclFactor(playervectory)	
		
			love.graphics.setColor(0, 0, 0,1,0.5) --set the drawing color
			love.graphics.line(objX, objY, objXvel ,objYvel)	
	
		end
	end

end

function DrawDottedLine(x1,y1,x2,y2)
	love.graphics.setPointSize(1)
	
	local x,y = x2-x1, y2-y1
	local mylen = math.sqrt(x^2 + y^2)
	local stepx,stepy = x/mylen, y/mylen
	x = x1
	y = y1
	for i = 1, mylen do
		love.graphics.setColor(1, 1, 1) --set the drawing color
		love.graphics.points(x,y)
		x=x+stepx
		y=y+stepy
	end

end

function DrawSidebar()
	local sidebarwidth = 120
	
	local x = love.graphics.getWidth() - sidebarwidth
	local y = 0
	local w = sidebarwidth -- width
	local h = love.graphics.getHeight()
	
	Slab.BeginWindow('sidebar',{AutoSizeWindow=false,NoOutline=true,X=x,Y=y,W=w,H=h})
	
	-- render the score
	Slab.Text("Downs:")
	Slab.SameLine()
	Slab.Text(score.downs)
	Slab.Text("Yards to go:")
	Slab.SameLine()
	Slab.Text(score.yardstogo)	
	Slab.Text("Num of plays:")
	Slab.SameLine()
	Slab.Text(score.plays)

	-- draw the RESET button
	if bolEndGame then
		if Slab.Button("Reset") then
			ResetGame()
		end
	end
	Slab.EndWindow()

end

function DrawMessageBox()
	local msgboxwidth = 400
	local msgboxheight = 25
	-- centre box on screen
	local x = love.graphics.getWidth()/2 - msgboxwidth/2
	local y = 20	-- arbitrary value
	
	Slab.BeginWindow('msgbox',{AutoSizeWindow=false,NoOutline=false,X=x,Y=y,W=msgboxwidth,H=msgboxheight})
	Slab.Textf(strMessageBox,{Align="center"})
	Slab.EndWindow()
end

function DrawCreditsButton()
	local sidebarwidth = 120
	
	local x = love.graphics.getWidth() - sidebarwidth
	local h = love.graphics.getHeight()
	local y = h - 100	-- arbitrary
	local w = sidebarwidth -- width

	
	Slab.BeginWindow('aboutbox',{AutoSizeWindow=false,NoOutline=true,X=x,Y=y,W=w,H=h})

	if Slab.Button("Credits") then
		strPreviousGameState = strGameState
		strGameState = "CreditsBox"
	end
	Slab.EndWindow()
	
end

function DrawCreditsBox()
	-- centre box on screen
	local x = love.graphics.getWidth()/2 - 150
	local y = love.graphics.getHeight()/2 - 250	-- arbitrary value

	
	Slab.BeginWindow('creditsbox',{Title ='About',BgColor = {0.5,0.5,0.5},AutoSizeWindow = true,NoOutline=true,AllowMove=false,X=x,Y=y})
	
	Slab.BeginLayout('mylayout', {AlignX = 'center'})	
    Slab.Text("Love Football by Gary Campbell 2021")
	Slab.NewLine()
	Slab.Text("Thanks to beta testers:",{Align = 'center'})
	Slab.Textf("Yuki Yu",{Align = 'right'})
	Slab.NewLine()
	Slab.Text("Thanks to the Love2D community")
	Slab.NewLine()	
	
	fltHyperlinkColorR = 1
	fltHyperlinkColorG = 0.9
	fltHyperlinkColorG = 0.1
	Slab.Text("Acknowledgements:")
	Slab.Text("Love2D", {URL="https://love2d.org",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
	Slab.Text("HUMP for Love2D", {URL="https://github.com/vrld/hump", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})	
	Slab.Text("SLAB for Love2D", {URL="https://github.com/coding-jackalope/Slab", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})	
	Slab.Text("freesound.org", {URL="https://freesound.org/",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
	Slab.Text("Kenney.nl", {URL="https://kenney.nl", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
	Slab.Text("Dark Fantasy Studio", {URL="http://darkfantasystudio.com/", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
	Slab.NewLine()
	
	if Slab.Button("Awesome!") then
		-- return to the previous game state
		strGameState = strPreviousGameState
	end
	
	Slab.EndLayout()
	Slab.EndWindow()
end

function SetPlayerTargets()

	if strGameState == "FormingUp" then
		SetFormingUpTargets()
	end
	
	if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		SetSnappedTargets()
	end
end

function SetFormingUpTargets()
	-- instantiate other game state information
	
	-- player 1 = QB
	objects.ball[1].targetcoordX = SclFactor(fltCentreLineX)	 -- centre line
	objects.ball[1].targetcoordY = SclFactor(intScrimmageY + 8)
	
	-- player 2 = WR (left closest to centre)
	objects.ball[2].targetcoordX = SclFactor(fltCentreLineX - 20)	 -- left 'wing'
	objects.ball[2].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage

	-- player 3 = WR (right)
	objects.ball[3].targetcoordX = SclFactor(fltCentreLineX + 19)	 -- left 'wing'
	objects.ball[3].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage
	
	-- player 4 = WR (left on outside)
	objects.ball[4].targetcoordX = SclFactor(fltCentreLineX - 24)	 -- left 'wing'
	objects.ball[4].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage

	-- player 5 = RB
	objects.ball[5].targetcoordX = SclFactor(fltCentreLineX)	 -- left 'wing'
	objects.ball[5].targetcoordY = SclFactor(intScrimmageY + 14)	-- just behind scrimmage	
	
	-- player 6 = TE (right side)
	objects.ball[6].targetcoordX = SclFactor(fltCentreLineX + 13)	 -- left 'wing'
	objects.ball[6].targetcoordY = SclFactor(intScrimmageY + 5)	-- just behind scrimmage		
	
	-- player 7 = Centre
	objects.ball[7].targetcoordX = SclFactor(fltCentreLineX)	 -- left 'wing'
	objects.ball[7].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage	
	
	-- player 8 = left guard
	objects.ball[8].targetcoordX = SclFactor(fltCentreLineX - 4)	 -- left 'wing'
	objects.ball[8].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage
	
	-- player 9 = right guard 
	objects.ball[9].targetcoordX = SclFactor(fltCentreLineX + 4)	 -- left 'wing'
	objects.ball[9].targetcoordY = SclFactor(intScrimmageY +2)		-- just behind scrimmage	

	-- player 10 = left tackle 
	objects.ball[10].targetcoordX = SclFactor(fltCentreLineX - 8)	 -- left 'wing'
	objects.ball[10].targetcoordY = SclFactor(intScrimmageY +4)		-- just behind scrimmage	

	-- player 11 = right tackle 
	objects.ball[11].targetcoordX = SclFactor(fltCentreLineX + 8)	 -- left 'wing'
	objects.ball[11].targetcoordY = SclFactor(intScrimmageY +4)		-- just behind scrimmage	

-- now for the visitors

	-- player 12 = Left tackle (left side of screen)
	objects.ball[12].targetcoordX = SclFactor(fltCentreLineX -2)	 -- centre line
	objects.ball[12].targetcoordY = SclFactor(intScrimmageY - 2)
	
	-- player 13 = Right tackle
	objects.ball[13].targetcoordX = SclFactor(fltCentreLineX +2)	 -- left 'wing'
	objects.ball[13].targetcoordY = SclFactor(intScrimmageY - 2)		-- just behind scrimmage

	-- player 14 = Left end
	objects.ball[14].targetcoordX = SclFactor(fltCentreLineX -6)	 -- left 'wing'
	objects.ball[14].targetcoordY = SclFactor(intScrimmageY - 2)		-- just behind scrimmage
	
	-- player 15 = Right end
	objects.ball[15].targetcoordX = SclFactor(fltCentreLineX +6)	 -- left 'wing'
	objects.ball[15].targetcoordY = SclFactor(intScrimmageY - 2)		-- just behind scrimmage

	-- player 16 = Inside LB
	objects.ball[16].targetcoordX = SclFactor(fltCentreLineX)	 -- left 'wing'
	objects.ball[16].targetcoordY = SclFactor(intScrimmageY - 11)	-- just behind scrimmage	
	
	-- player 17 = Left Outside LB
	objects.ball[17].targetcoordX = SclFactor(fltCentreLineX - 15)	 -- left 'wing'
	objects.ball[17].targetcoordY = SclFactor(intScrimmageY - 10)	-- just behind scrimmage		
	
	-- player 18 = Right Outside LB
	objects.ball[18].targetcoordX = SclFactor(fltCentreLineX +15)	 -- left 'wing'
	objects.ball[18].targetcoordY = SclFactor(intScrimmageY - 10)		-- just behind scrimmage	
	
	-- player 19 = Left CB
	objects.ball[19].targetcoordX = SclFactor(fltCentreLineX -24)	 -- left 'wing'
	objects.ball[19].targetcoordY = SclFactor(intScrimmageY -18)	 -- just behind scrimmage
	
	-- player 20 = right CB 
	objects.ball[20].targetcoordX = SclFactor(fltCentreLineX + 19)	 -- left 'wing'
	objects.ball[20].targetcoordY = SclFactor(intScrimmageY -18)		-- just behind scrimmage	

	-- player 21 = left safety 
	objects.ball[21].targetcoordX = SclFactor(fltCentreLineX - 4)	 -- left 'wing'
	objects.ball[21].targetcoordY = SclFactor(intScrimmageY - 17)		-- just behind scrimmage	

	-- player 22 = right safety 
	objects.ball[22].targetcoordX = SclFactor(fltCentreLineX + 4)	 -- left 'wing'
	objects.ball[22].targetcoordY = SclFactor(intScrimmageY - 17)		-- just behind scrimmage	

	
	CheckAllTargetsOnField()
end

function DetermineClosestEnemy(playernum, enemytype, bolCheckOwnTeam)
	-- receives the player in question and the target type string (eg "WR") and finds the closest enemy player of that type
	-- enemytype can be an empty string ("") which will search for ANY type
	-- bolCheckOwnTeam = false means scan only the enemy
	-- returns zero, 1000 if none found
	
	local myclosestdist = 1000
	local myclosesttarget = 0
	
	local currentplayerX = objects.ball[playernum].body:getX()
	local currentplayerY = objects.ball[playernum].body:getY()
	
	-- set up loop to scan opposing team or the whole team
	if bolCheckOwnTeam then
		a = 1
		b = 22
	else
		if playernum > 11 then
			a = 1
			b = 11
		else
			a = 12
			b = 22
		end
	end
		
	--print(playernum,a,b)
	for i = a,b do
		if not objects.ball[i].fallendown then
			if objects.ball[i].positionletters == enemytype or enemytype == "" then
				-- determine distance
				local thisdistance = GetDistance(currentplayerX, currentplayerY, objects.ball[i].body:getX(), objects.ball[i].body:getY())
				
				if thisdistance < myclosestdist then
					-- found a closer target. Make that one the focuse
					myclosesttarget = i
					myclosestdist = thisdistance
					--print("Just set closest target for player " .. playernum .. " to " .. i)
				end
			end
		end
	end		-- for loop
	
	return myclosesttarget, myclosestdist
end

function Determine2ndClosestEnemy(playernum, enemytype, bolCheckOwnTeam)
	-- receives the player in question and the target type string (eg "WR") and finds the closest enemy player of that type
	-- enemytype can be an empty string ("") which will search for ANY type
	-- bolCheckOwnTeam = false means scan only the enemy
	-- returns zero, 1000 if none found
	
	local myclosestdist = 1000
	local myclosesttarget = 0
	
	local currentplayerX = objects.ball[playernum].body:getX()
	local currentplayerY = objects.ball[playernum].body:getY()
	
	-- get the closest player and ignore that during the next scan
	p1,_ = DetermineClosestEnemy(playernum, enemytype, bolCheckOwnTeam)
	
	-- set up loop to scan opposing team or the whole team
	if bolCheckOwnTeam then
		a = 1
		b = 22
	else
		if playernum > 11 then
			a = 1
			b = 11
		else
			a = 12
			b = 22
		end
	end
		
	--print(playernum,a,b)
	for i = a,b do
		if not objects.ball[i].fallendown then
			if objects.ball[i].positionletters == enemytype or enemytype == "" then
				-- determine distance
				local thisdistance = GetDistance(currentplayerX, currentplayerY, objects.ball[i].body:getX(), objects.ball[i].body:getY())
				
				if thisdistance < myclosestdist and i ~= p1 then	-- need to ignore p1, which we already know is the closest player
					-- found a closer target. Make that one the focuse
					myclosesttarget = i
					myclosestdist = thisdistance
					--print("Just set closest target for player " .. playernum .. " to " .. i)
				end
			end
		end
	end		-- for loop
	
	return myclosesttarget, myclosestdist
end

function SetPlayerTargetToAnotherPlayer(i,j, intBufferX, intBufferY)
	-- receives player index (the 'current' player) and set their target to player j and intercepts
	-- buffer X and buffer Y specifies if the player is to run in front of or behind or beside etc
	-- note the intBufferX is how much space left or right - you can't specify which side. The player will automatially NOT cross the target.
	-- note that intBufferY +ve/-ve does matter and -ve means in front of target
	-- intbuffery will be scaled so send that in unscaled
	-- set bufferx and buffery to 0,0 if you want a tackle
	-- returns nothing (not a function)
	-- the parent function needs to check if i or j have fallen down
	

	
	objects.ball[i].targetcoordX = objects.ball[j].body:getX()
	objects.ball[i].targetcoordY = objects.ball[j].body:getY()	
	

	-- build in buffer
	-- target is now player j but this causes the player to push or slow down the carrier so need to build
	-- in some space
	-- check what side of the field the player is on and don't cross over or run into the carrier
	-- intBufferX = math.abs(intBufferX)
	if objects.ball[i].body:getX() > objects.ball[j].body:getX() then
		objects.ball[i].targetcoordX = objects.ball[i].targetcoordX + SclFactor(intBufferX)	-- build in some buffer
	else
		objects.ball[i].targetcoordX = objects.ball[i].targetcoordX - SclFactor(intBufferX)
	end		
	
	objects.ball[i].targetcoordY = objects.ball[i].targetcoordY + SclFactor(intBufferY)
	
end

function SetPlayerTargetToGoal(i)
	-- receive a player index and set their pathway to the goal to score
	
	-- Apply a check where the first down marker is really close and runner "goes for it" without any avoidance
	-- print("SetPlayerTargetToGoal with i = " .. i)
	if objects.ball[i].body:getY() - intFirstDownMarker <= SclFactor(3) then
		-- go for it
		-- This is simple run straight ahead behavior because the goal is close
		objects.ball[i].targetcoordX = objects.ball[i].body:getX()
		objects.ball[i].targetcoordY = SclFactor(intTopGoalY)			
	else
		-- Enemy avoidance
		-- Determine vector to goal
		objects.ball[i].targetcoordX = objects.ball[i].body:getX() --/ fltScaleFactor
		objects.ball[i].targetcoordY = SclFactor(intTopGoalY)	

		-- runners vector to goal if uninterupted
		local finalvectorX = objects.ball[i].body:getX() - objects.ball[i].targetcoordX
		local finalvectorY = objects.ball[i].targetcoordY - objects.ball[i].body:getY()		-- this is reversed due to origin being top left
		
		--print("Unadjusted vector to goal is" .. finalvectorX, finalvectorY)
		
		local enemyvectorX = {}
		local enemyvectorY = {}
		local enemyscale = {}
		local totalscalefactor = 0
		
		-- capture all the vectors from the runner to the enemy (only if enemy is in front of runner)
		for j = 12, intNumOfPlayers do
			if not objects.ball[j].fallendown then	-- ignore players that have fallen down
				if objects.ball[j].body:getY() < objects.ball[i].body:getY() then -- ignore if the enemy is behind the runner
					enemyvectorX[j] = objects.ball[j].body:getX() - objects.ball[i].body:getX()
					enemyvectorY[j] = objects.ball[j].body:getY() - objects.ball[i].body:getY()
					-- also capture the inverse distance
					enemyscale[j] = GetInverseSqrtDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), objects.ball[j].body:getX(), objects.ball[j].body:getY())
					totalscalefactor = totalscalefactor + enemyscale[j]
				end
			end		
		end
		
		-- add the sideline as something that also needs avoiding
		-- this becomes the 23rd player or index = 23
		if objects.ball[i].body:getX() < SclFactor(fltCentreLineX) then	-- check if runner is on left or right side of field
			enemyvectorX[intNumOfPlayers+1] = objects.ball[i].body:getX() - SclFactor(intLeftLineX)
		else
			enemyvectorX[intNumOfPlayers+1] = SclFactor(intRightLineX) - objects.ball[i].body:getX()
		end	
		
		enemyvectorY[intNumOfPlayers+1] = objects.ball[i].body:getY()
		
		enemyscale[intNumOfPlayers+1] = GetInverseSqrtDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), enemyvectorX[intNumOfPlayers+1], enemyvectorY[intNumOfPlayers+1])		
		totalscalefactor = totalscalefactor + enemyscale[intNumOfPlayers+1]
		
		-- print("Vector X and Scale of sideline is " .. enemyvectorX[intNumOfPlayers+1], (enemyscale[intNumOfPlayers+1]/totalscalefactor) )
	
		-- scale each vector according to the scale factor - include the vector to the sideline
		for j = 12, intNumOfPlayers+1 do
			if enemyvectorX[j] ~= nil then
				enemyvectorX[j],enemyvectorY[j] = ScaleVector(enemyvectorX[j],enemyvectorY[j],(enemyscale[j]/totalscalefactor))
				
				-- print(j .. ":" .. enemyscale[j]/totalscalefactor)
				
				-- apply that avoidance vector to the runners vector to goal
				finalvectorX,finalvectorY = SubtractVectors(finalvectorX,finalvectorY,enemyvectorX[j],enemyvectorY[j])
			end
		end

		objects.ball[i].targetcoordX = objects.ball[i].body:getX() + finalvectorX
		objects.ball[i].targetcoordY = objects.ball[i].body:getY() + finalvectorY	
		
		--print("Final vector to goal is" .. objects.ball[i].targetcoordX, objects.ball[i].targetcoordY)

		-- Ensure runner doesn't run backwards
		if objects.ball[i].targetcoordY > 0 then
			objects.ball[i].targetcoordY = -10	--! some arbitrary value that should change
		end
	end
end

function SetRouteStacks()
	-- for each player, set a pair of coords and then add that coords to that players stack
	-- insert them in order of execution so that the last coord is inserted last
	-- later on, will read from the front in sequence
	
	-- the pairs are field coordinates - not screen coordinates. Don't scale them up
	
	coord = {}
	playerroutes = {{},{},{},{},{},{},{},{}}		-- need one for each player. Only three WR atm but what the heck.
	
	-- player 2 = WR left inside
	coord[1] = {fltCentreLineX - 18,intScrimmageY - 8}
	coord[2] = {fltCentreLineX + 25,intScrimmageY - 15}
	table.insert(playerroutes[2],coord[1])
	table.insert(playerroutes[2],coord[2])
	
	-- player 3 = WR (right)
	coord[1] = {fltCentreLineX + 18,intScrimmageY -15}
	coord[2] = {fltCentreLineX + 5,intScrimmageY -18}
	table.insert(playerroutes[3],coord[1])
	table.insert(playerroutes[3],coord[2])

	-- player 4 = WR (left on outside)
	coord[1] = {fltCentreLineX - 22,intScrimmageY - 10}
	coord[2] = {fltCentreLineX - 18,intScrimmageY - 5}
	
	table.insert(playerroutes[4],coord[1])
	table.insert(playerroutes[4],coord[2])	
	

	
	--print (playerroutes[2][1][1])	-- player 2 \ coordinate pair 1 \ X value
	--print (playerroutes[2][1][2]) -- player 2 \ coordinate pair 1 \ Y value
	--print()
	--print (playerroutes[2][2][1]) -- player 2 \ coordinate pair 2 \ X value
	--print (playerroutes[2][2][2]) -- player 2 \ coordinate pair 2 \ Y value
end

function SetWRTargets()

	for i = 2,4 do
	
		-- print("Setting target for WR " .. i)

			if strGameState == "Airborne" then	-- run to predicted ball location
				objects.ball[i].targetcoordX = football.targetx
				objects.ball[i].targetcoordY = football.targety
				
			end
			
			if strGameState == "Running" then	-- run in front of runner
				-- target enemy closest to the runner
				local intTarget, _ = DetermineClosestEnemy(intBallCarrier, "", false)	-- find the closest player to the runner
				if intTarget > 0 then
					SetPlayerTargetToAnotherPlayer(i,intTarget, 3,-5)
				else
					--! do this later
				end
			end
			
			if strGameState == "Looking" then
				-- run route and then look for seperation at end of route
				for i = 2,4 do
					if playerroutes[i][1] == nil then
						-- route finished. Old target remains in memory
						--  find some seperation

						if objects.ball[i].body:getY() < SclFactor(intScrimmageY - 25) then
							-- move down the field to somewhere more reasonable
							objects.ball[i].targetcoordX = SclFactor(fltCentreLineX)
							objects.ball[i].targetcoordY = SclFactor(intScrimmageY - 25)
						elseif objects.ball[i].body:getY() > SclFactor(intScrimmageY - 5) then
							objects.ball[i].targetcoordX = SclFactor(fltCentreLineX)
							objects.ball[i].targetcoordY = SclFactor(intScrimmageY - 5)
						else
							-- do some player avoidance

							-- This will fail if too many players fall over
							-- Determine the closest players, including own team
							closePlayer1, closeDistance1 =  DetermineClosestEnemy(i, "", True)
							x1 = objects.ball[closePlayer1].body:getX()
							y1 = objects.ball[closePlayer1].body:getY()
							
							-- closePlayer2, closeDistance2 =  Determine2ndClosestEnemy(i, "", True)
							-- x2 = objects.ball[closePlayer2].body:getX()
							-- y2 = objects.ball[closePlayer2].body:getY()	
							
							-- get some imaginary bounding box
							--  top left
							--x3 = SclFactor(intLeftLineX)
							--y3 = SclFactor(intScrimmageY - 15)
							
							--  top right
							--x4 = SclFactor(intRightLineX)
							--y4 = SclFactor(intScrimmageY - 15)
							
							-- bottom right
							--x5 = SclFactor(intRightLineX)
							--y5 = SclFactor(intScrimmageY + 15)
							
							-- bottom left
							--x6 = SclFactor(intLeftLineX)
							--y6 = SclFactor(intScrimmageY + 15)
							
							Scale1 = GetInverseSqrtDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), x1, y1)	
							-- we have closeDistance1 above. Would be more efficient to use that --!
							
							-- Scale2 = GetInverseSqrtDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), x2, y2)
							--Scale3 = GetInverseSqrtDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), x3, y3)
							--Scale4 = GetInverseSqrtDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), x4, y4)
							--Scale5 = GetInverseSqrtDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), x5, y5)
							--Scale6 = GetInverseSqrtDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), x6, y6)
							
							
							-- Normalise the scales
							TotalScale = Scale1 -- + Scale3 + Scale4 + Scale5 + Scale6
							Scale1 = Scale1/TotalScale
							-- Scale2 = Scale2/TotalScale
							--Scale3 = Scale3/TotalScale
							--Scale4 = Scale4/TotalScale
							--Scale5 = Scale5/TotalScale
							--Scale6 = Scale6/TotalScale
						
							-- apply avoidance vector for closest player
							-- scale the vector before applying it
							X1scaled,Y1scaled = ScaleVector(x1,y1,Scale1)
							--X2scaled,Y2scaled = ScaleVector(x2,y2,Scale2)
							--X3scaled,Y3scaled = ScaleVector(x3,y3,Scale3)
							--X4scaled,Y4scaled = ScaleVector(x4,y4,Scale4)
							--X5scaled,Y5scaled = ScaleVector(x5,y5,Scale5)
							--X6scaled,Y6scaled = ScaleVector(x6,y6,Scale6)
							
							
							-- apply this avoidance vector to the current target
							finalvectorX,finalvectorY = SubtractVectors(objects.ball[i].targetcoordX,objects.ball[i].targetcoordY,X1scaled,Y1scaled)
							
							-- apply avoidance vector for 2nd closest player
							-- scale the vector before applying it
							--X2scaled,Y2scaled = ScaleVector(x2,y2,Scale2)
							--finalvectorX,finalvectorY = SubtractVectors(finalvectorX,finalvectorY,X2scaled,Y2scaled)
												
							-- apply this avoidance vector to the current target
							-- finalvectorX,finalvectorY = SubtractVectors(finalvectorX,finalvectorY,X3scaled,Y3scaled)
							-- finalvectorX,finalvectorY = SubtractVectors(finalvectorX,finalvectorY,X4scaled,Y4scaled)
							-- finalvectorX,finalvectorY = SubtractVectors(finalvectorX,finalvectorY,X5scaled,Y5scaled)
							-- finalvectorX,finalvectorY = SubtractVectors(finalvectorX,finalvectorY,X6scaled,Y6scaled)
							
							-- set target to that vector
							objects.ball[i].targetcoordX = objects.ball[i].body:getX() + finalvectorX
							objects.ball[i].targetcoordY = objects.ball[i].body:getY() + finalvectorY
						end
					else
						-- route 1 is the first route, or current route
						objects.ball[i].targetcoordX = SclFactor(playerroutes[i][1][1])	-- player i, route 1, x value
						objects.ball[i].targetcoordY = SclFactor(playerroutes[i][1][2])	-- player i, route 1, y value						

						-- check if arrived						
						local tempdist = GetDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), objects.ball[i].targetcoordX, objects.ball[i].targetcoordY)
						
						if tempdist < 7 then	-- within 7 units of target
							-- move to next target
							table.remove(playerroutes[i], 1)	-- remove the first coordinate pair in playerroute making all pairs shuffle up
						end
					end
				end
			end
			
			-- THIS MUST GO LAST so it can override the above
			if intBallCarrier == i then
				-- RUN!!
				SetPlayerTargetToGoal(i)
			end			
	end

end

function SetOffensiveRow()
	-- sets the five front-rowers
	-- #10, #8, #7, #9, #11
	
	local intNumofActivePlayers = 0		-- track how many front rowers are on their feet
	
	if strGameState == "Looking" then
		-- get num active players
		for i = 7,11 do
			if objects.ball[i].fallendown == false then
				intNumofActivePlayers = intNumofActivePlayers + 1
			end
		end

		-- formula for X placement: x coord = zone offset * (i-1) + zonesize
		-- this means space the players 'zonesize' apart, but then place them in the middle of that zone (offset)
		
		fltWholeZoneSize = 20
		fltZoneSize = fltWholeZoneSize / intNumofActivePlayers	-- 17 yards of front row shared between all active front row players
		fltZoneSizeOffset = fltZoneSize / 2			-- this positions the player in the middle of the zone
		
		local intZoneNumber = 1		-- track the next zone
		local intStartofFront = fltCentreLineX - (fltWholeZoneSize/2)	-- front zone is x yards wide so start half the distance from the centre
		
		for i = 1,5 do
		
			if i == 1 then pnum = 10 end	-- sadly, we can't cycle through 7 ->11. It needs to be left side then centre then right side
			if i == 2 then pnum = 8 end
			if i == 3 then pnum = 7 end
			if i == 4 then pnum = 9 end
			if i == 5 then pnum = 11 end
		
			if objects.ball[pnum].fallendown == false then
				objects.ball[pnum].targetcoordX = SclFactor(intStartofFront + fltZoneSizeOffset + (fltZoneSize * (intZoneNumber - 1 )))
				objects.ball[pnum].targetcoordY = objects.ball[1].body:getY() - SclFactor(10)
				intZoneNumber = intZoneNumber + 1
				
				--if pnum == 7 then
					--print(fltZoneSize, fltZoneSizeOffset, intStartofFront, objects.ball[pnum].targetcoordX)
				--end
			end
		end

	end
	
	if strGameState == "Running" then
		for i = 7,11 do
			if intBallCarrier == i then
				-- player is now the runner
				-- run!!
				SetPlayerTargetToGoal(i)
			else
				-- run 10 yards in front of carrier
				SetPlayerTargetToAnotherPlayer(i,intBallCarrier, 0, -10)
			end
		end
	end

end

function SetCentreTargets()

	-- Centre is #7
	if strGameState == "Looking" then
		-- move to LoS - 10 yards
		objects.ball[7].targetcoordX = SclFactor(fltCentreLineX)	 
		objects.ball[7].targetcoordY = SclFactor(intScrimmageY - 10)	
	end
	
	if strGameState == "Airborne" then	-- run to predicted ball location
		objects.ball[7].targetcoordX = football.targetx
		objects.ball[7].targetcoordY = football.targety
		
	end
	
	if strGameState == "Running" then
		if intBallCarrier == 7 then
			-- player is now the runner
			-- run!!
			SetPlayerTargetToGoal(7)
		else
			-- run 10 yards in front of carrier
			SetPlayerTargetToAnotherPlayer(7,intBallCarrier, 0, -10)
		end
	end

end

function SetOffensiveGuardTargets()
	-- players #8,9

	for i = 8,9 do
		if strGameState == "Looking" then
			intCentre, intDist = DetermineClosestEnemy(i,"C", true)		-- search own team for active centre player
			if intCentre > 0 then
				-- stay close to CENTRE to maintain a wall
				if i == 8 then
					SetPlayerTargetToAnotherPlayer(i,7, 4, 0)	-- Move to the left side and level to the centre (Player #7)
				else
					SetPlayerTargetToAnotherPlayer(i,7, 4, 0)	-- Move to the right side and level to the centre (Player #7)
				end
			else
				--print("Centre down!")
				-- no CENTRE. Need to compensate
				
				-- see if other guard is still active
				if i == 8 then
					intGrd,intDist = DetermineClosestEnemy(i, "RG", true)
				else
					intGrd,intDist = DetermineClosestEnemy(i, "LG", true)
				end
				
				if intGrd > 0 then
					--print("Moving to cover centre")
					-- other guard is still active
					-- Move over to fill the gap that Centre left
					if i == 8 then
						--print("Left aligning with right")
						-- this is a +5 yards because the SetPlayer function will reverse the sign depending on side of field
						SetPlayerTargetToAnotherPlayer(i,9, 5, 0)	-- move beside guard #9 and to the left
					else
						SetPlayerTargetToAnotherPlayer(i,8, 5, 0)		-- move beside guard #8 and to the right
					end
					
					--print(i, objects.ball[i].targetcoordX,objects.ball[i].targetcoordY)
				else
					-- we're on our own - dominate the LoS!!
					objects.ball[i].targetcoordX = SclFactor(fltCentreLineX)	 
					objects.ball[i].targetcoordY = SclFactor(intScrimmageY - 10)
		
				end
			
			end
		end
		
		--! airborne?
		--! running?
	
	end
	
	

end

function SetCornerBackTargets()
	-- assumes game state is not 'forming'		--! I could make this
	local intTarget
	for i = 19,20 do	-- CB's are number 19 and 20
		if objects.ball[i].positionletters == "CB" then		-- unnecessary if statement but put here for safety
	
			if strGameState == "Looking" then		-- QB is looking --! need to set this currentaction value on the snap event
				intWR, WRdist = DetermineClosestEnemy(i, "WR", false)
				intTE, TEdist = DetermineClosestEnemy(i, "TE", false)
				
				if intWR > 0 or intTE > 0 then
					if WRdist < TEdist and intWR > 0 then
						intTarget = intWR
					end
					if TEdist <= WRdist and intTE > 0 then
						intTarget = intTE
					end		

					if intTarget > 0 then
						SetPlayerTargetToAnotherPlayer(i,intTarget, 5,5)
					else
						--! do this later
						-- this should never happen
					end
				else
					-- see if there are any Safeties active
					intSS, SSdist = DetermineClosestEnemy(i, "S", true)	-- !this searches for closest Safety which isn't strictly necessary. Any S will do.
					intQBY = objects.ball[1].body:getY()
					if intSS > 0 then
						-- position CB between the safety and the QB
						intSSY = objects.ball[intSS].body:getY()
										
						local intCBY = ((intQBY - intSSY) /  2) + intSSY
						objects.ball[i].targetcoordY = intCBY		--! noting this does NOT update X and maybe it should
					else
						-- position CB between the goal and the QB
						intGoalY = intTopGoalY
						local intCBY = ((intQBY - intGoalY) /  2) + intGoalY
					end
					
					if i == 19 then
						-- set X
					else
						-- set Y
					
					end
					
				end
			end
			
			if strGameState == "Running" then	-- the ball carrier is running for the LoS
				--set target to the runner
				SetPlayerTargetToAnotherPlayer(i,intBallCarrier, 0,0)
			end
			
			if strGameState == "Airborne" then	-- ball is thrown and still in the air
				-- run to where the ball will land
				objects.ball[i].targetcoordX = football.targetx		-- need to set this on a mouse click
				objects.ball[i].targetcoordY = football.targety					
			end
		end
	end
end

function SetOutsideLineBackersTargets()

	for i = 17,18 do
		if strGameState == "Looking" then
			if i == 17 then	-- the leftmost OLB
				intWR, WRdist = DetermineClosestEnemy(i, "WR", false)
				if intWR > 0 then
					SetPlayerTargetToAnotherPlayer(i,intWR, 5,5)
				else
					-- target anyone
					intTarget, intTargetdist = DetermineClosestEnemy(i, "", false)
					if intTarget > 0 then
						-- move to 10 yards in front of that target
						SetPlayerTargetToAnotherPlayer(i,intTarget, 5,5)
					else
						--! will only happen if ALL enemies is down
					end
				
				end
			else	-- right side OLB
				if i == 18 then
					intTE, TEdist = DetermineClosestEnemy(i, "TE", false)
					if intTE > 0 then	-- look for a TE
						SetPlayerTargetToAnotherPlayer(i,intTE, 5,5)
					else
						intWR, WRdist = DetermineClosestEnemy(i, "WR", false)
						if intWR > 0 then
							SetPlayerTargetToAnotherPlayer(i,intWR, 5,5)
						else
							-- locate any  target
							intTarget, intTargetdist = DetermineClosestEnemy(i, "", false)
							if intTarget > 0 then
								-- move to 10 yards in front of that target
								objects.ball[i].targetcoordX = objects.ball[1].body:getX()
								objects.ball[i].targetcoordY = objects.ball[1].body:getY()	- SclFactor(10)
							else
								--! will only happen if ALL enemies is down
							end
						end					
					end
				else
					--! ERROR - should never happend

				end
			end
		end

		if strGameState == "Airborne" then	-- ball is thrown and still in the air
			-- run to where the ball will land
			objects.ball[i].targetcoordX = football.targetx		-- need to set this on a mouse click
			objects.ball[i].targetcoordY = football.targety					
		end
		
		if strGameState == "Running" then	-- the ball carrier is running for the LoS
			--set target to the runner
			SetPlayerTargetToAnotherPlayer(i,intBallCarrier, 0,0)
		end
	end
end

function SetInsdeLineBackersTargets()
	
	-- ILB is #16
	if strGameState == "Looking" then
		intRB, intRBdist = DetermineClosestEnemy(16, "RB", false)
		if intRB > 0 then
			SetPlayerTargetToAnotherPlayer(16,intRB, 0, -15)	-- position in front of RB
		else
			SetPlayerTargetToAnotherPlayer(16,1, 0, -15)	-- position in front of QB
		end
	end
	
	if strGameState == "Airborne" then	-- ball is thrown and still in the air
		-- run to where the ball will land
		objects.ball[16].targetcoordX = football.targetx		-- need to set this on a mouse click
		objects.ball[16].targetcoordY = football.targety					
	end
	
	if strGameState == "Running" then	-- the ball carrier is running for the LoS
		--set target to the runner
		SetPlayerTargetToAnotherPlayer(16,intBallCarrier, 0,0)
	end
	


end

function SetRunningBackTargets()
	-- RB is player 5

	if strGameState == "Looking" then
		-- target nearest enemy
		local intClosestEnemy = DetermineClosestEnemy(5, "", false)
		if intClosestEnemy > 0 then
			SetPlayerTargetToAnotherPlayer(5,intClosestEnemy, 0,0)
		else
			--! do this later
		end
	end
	
	if strGameState == "Running" then
		local intTarget = DetermineClosestEnemy(intBallCarrier, "", false)	-- 
		if intTarget > 0 then
			SetPlayerTargetToAnotherPlayer(5,intTarget, 5,-5)
		else
			--! do this later
		
		end
	end
	
	if strGameState == "Airborne" then	-- run to predicted ball location
		objects.ball[5].targetcoordX = football.targetx
		objects.ball[5].targetcoordY = football.targety
	end

		-- THIS MUST GO LAST so it can override the above
	if intBallCarrier == 5 then
		-- RUN!!
		SetPlayerTargetToGoal(5)
	end	

end

function SetTETargets()
	-- TE is player 6
	
	if strGameState == "Looking" then
		objects.ball[6].targetcoordX = SclFactor(fltCentreLineX + 5)	 
		objects.ball[6].targetcoordY = SclFactor(intScrimmageY - 20)	
		
		
	end
	
	if strGameState == "Running" then
	-- run with/infront of runner
		SetPlayerTargetToAnotherPlayer(6,intBallCarrier, 5, 7)		
	end
	
	if strGameState == "Airborne" then
	-- run to predicted ball location
		objects.ball[6].targetcoordX = football.targetx
		objects.ball[6].targetcoordY = football.targety	
	end
	
	if intBallCarrier == 6 then
		-- RUN!!
		SetPlayerTargetToGoal(6)
	end		
	
end

function SetSafetyTargets()
	-- safety are #21 and #22
	for i = 21,22 do
		if strGameState == "Looking" then
			-- look for a WR
			intWR, WRdist = DetermineClosestEnemy(i, "WR", false)
			if intWR > 0 then
				-- set target to 10 yards in front of WR
				objects.ball[i].targetcoordX = objects.ball[intWR].body:getX()
				objects.ball[i].targetcoordY = objects.ball[intWR].body:getY() - SclFactor(10)
			else
				intTE, TEdist = DetermineClosestEnemy(i, "TE", false)
				if intTE > 0 then
					-- set target to 10 yards in front of TE
					objects.ball[i].targetcoordX = objects.ball[intTE].body:getX()
					objects.ball[i].targetcoordY = objects.ball[intTE].body:getY() - SclFactor(10)	
				else
					-- just set target to whoever is closest
					local intClosestEnemy = DetermineClosestEnemy(i, "", false)
					if intTarget > 0 then
						SetPlayerTargetToAnotherPlayer(i,intTarget, 0,0)
					else
						--! do this later
					end					
				end
			end
		end
		
	
		if strGameState == "Airborne" then	-- ball is thrown and still in the air
			-- run to where the ball will land
			objects.ball[i].targetcoordX = football.targetx		
			objects.ball[i].targetcoordY = football.targety					
			
			-- position between the ball target and the goal line
			if football.targety > SclFactor(intTopGoalY) then	-- if ball target is in goal zone then the default rush it behaviour is correct, otherwise, do this next bit
			
				--print(football.targety,intTopGoalY,SclFactor(intTopGoalY))
				objects.ball[i].targetcoordX = football.targetx		
				objects.ball[i].targetcoordY = (football.targety - SclFactor(intTopGoalY)) / 2 + SclFactor(intTopGoalY)
			end
		end	

		if strGameState == "Running" then
			
			-- get the vector from runner to the goal line
			x1 = objects.ball[intBallCarrier].body:getX()
			y1 = objects.ball[intBallCarrier].body:getY()
			
			x2 = x1
			y2 = SclFactor(intTopGoalY)
			
			-- get the distance from the runner to the goal
			mydist1 = GetDistance(x1, y1, x2, y2)
			
			-- get the distance from safety to the runner
			mydist2 = GetDistance(objects.ball[i].body:getX(), objects.ball[i].body:getY(), x1, y1)
			
			-- get the ratio of distance from player to runner and runner to goal
			myratio = mydist2/mydist1
			
			-- progress along runners vector by that same distance
			-- x3/y3 is the vector created between x1/y1,x2/y2
			x3 = x2-x1
			y3 = y2-y1
			
			-- scale this vector
			x3scaled, y3scaled = ScaleVector(x3,y3,myratio)
			
			-- set target to that new spot along the vector
			-- add the scaled vector to the runners position
			objects.ball[i].targetcoordX =	x1 + x3scaled
			objects.ball[i].targetcoordY = 	y1 + y3scaled
			
			-- make sure the target is not beyond the goal
			if (objects.ball[i].targetcoordY / fltScaleFactor) < intTopGoalY then
				objects.ball[i].targetcoordY = SclFactor(intTopGoalY)
			end
			
			--[[
			if i == 22 then
				print(x1, y1)
				print(x2,y2)
				print(mydist1)
				print(mydist2)
				print(myratio)
				print(x3,y3)
				print(x3scaled,y3scaled)
				print("=====================")
			end	
			]]--

		end			
		
	end

end

function SetSnappedTargets()
	-- instantiate other game state information
	-- player 1 = QB
	
	-- this moves the QB towards a thrown ball or runner simply to save forming up time
	if strGameState == "Airborne"  then
		objects.ball[1].targetcoordX = SclFactor(fltCentreLineX)
		objects.ball[1].targetcoordY = football.targety	
	end
	-- if we have a runner and it is not the QB then chase that runner
	if strGameState == "Running" and intBallCarrier ~= 1 then
		SetPlayerTargetToAnotherPlayer(1,intBallCarrier, 0,0)
		objects.ball[1].targetcoordX = SclFactor(fltCentreLineX)	-- set the X to the centre line so can be ready for next snap
	end
	
	-- player 2 = WR (left closest to centre)
	-- player 3 = WR (right)
	-- player 4 = WR (left on outside)
	SetWRTargets()	-- Let the WR routes set and then overright them here

	-- player 5 = RB
	SetRunningBackTargets()
	
	-- player 6 = TE (right side)
	SetTETargets()
	
	-- player 7 = Centre
	-- player 8 = left guard offense
	-- player 9 = right guard offense
	-- player 10 = left tackle 
	-- player 11 = right tackle 
	SetOffensiveRow()
		
	-- SetCentreTargets()
	--SetOffensiveGuardTargets()
		

-- now for the visitors

	-- player 12 = Left tackle (left side of screen)
	if strGameState ~= "Airborne" then
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


	end
	
	-- player 16 = inside linebacker
	SetInsdeLineBackersTargets()
	
	 -- player 17 = Left outside LB
	 -- player 18 = Right Outside LB
	SetOutsideLineBackersTargets()
	
	-- player 19 = Left CB
	-- player 20 = Right CB
	SetCornerBackTargets()	-- apply behavior tree		

	-- #21 & #22
	SetSafetyTargets()
	
	CheckAllTargetsOnField()	-- makes sure all targets are on the field and not beyond the goal zones
end

function CheckAllTargetsOnField()	
	-- makes sure all targets are on the field and not beyond the goal zones
	for i = 1,intNumOfPlayers do
		if objects.ball[i].targetcoordY < SclFactor(intTopPostY) then
			objects.ball[i].targetcoordY = SclFactor(intTopPostY)
		end
		if objects.ball[i].targetcoordY > SclFactor(intBottomPostY) then
			objects.ball[i].targetcoordY = SclFactor(intBottomPostY)
		end
		
		-- check that targets are not outside the x values either
		
		if objects.ball[i].targetcoordX < SclFactor(intLeftLineX) then
			objects.ball[i].targetcoordX = SclFactor(intLeftLineX + 2)
		end
		if objects.ball[i].targetcoordX > SclFactor(intRightLineX) then
			objects.ball[i].targetcoordX = SclFactor(intRightLineX - 2)
		end		

	end
end

function GetDistance(x1, y1, x2, y2)
	-- this is real distance in pixels
	-- receives two coordinate pairs (not vectors)
	-- returns a single number
	
	if (x1 == nil) or (y1 == nil) or (x2 == nil) or (y2 == nil) then return 0 end
	
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2
    --Both of these work
    local a = horizontal_distance * horizontal_distance
    local b = vertical_distance ^2

    local c = a + b
    local distance = math.sqrt(c)
    return distance
end

function ScaleVector(x,y,fctor)
	-- Receive a vector (0,0, -> x,y) and scale/multiply it by factor
	-- returns a new vector (assuming origin)
	return x * fctor, y * fctor
end

function SubtractVectors(x1,y1,x2,y2)
	-- subtracts vector2 from vector1 i.e. v1 - v2
	-- returns a vector (an x/y pair)
	return (x1-x2),(y1-y2)
end

function AddVectors(x1,y1,x2,y2)
	return (x1+x2),(y1+y2)

end

function dotVectors(x1,y1,x2,y2)
	-- receives two vectors (deltas) and assumes same origin
	-- eg: guard is looking in direction x1/y1. His looking vector is 1,1
	-- thief vector from guard is 2,-1  (he's on the right side of the guard)
	-- dot product is 1. This is positive so thief is infront of guard (assuming 180 deg viewing angle)
	return (x1*x2)+(y1*y2)
end

function MoveAllPlayers(dtime)

	for i = 1,intNumOfPlayers do
	
		objX = objects.ball[i].body:getX()
		objY = objects.ball[i].body:getY()
		
		-- determine distance to target
		-- this is measured in screen coords
		playerdistancetotarget = GetDistance(objX,objY,objects.ball[i].targetcoordX,objects.ball[i].targetcoordY)
	
		-- has player arrived?
		if playerdistancetotarget < 3 then
			-- player has arrived
			if strGameState == "FormingUp" then
				objects.ball[i].mode = "readyforsnap"
			end
			if strGameState == "Airborne" then
				-- Wait, i guess!
			end
		end
		
		if playerdistancetotarget >= 3 then
			-- player has not arrived
			if strGameState == "FormingUp" then
				objects.ball[i].mode = "forming"
			end
			
			-- determine actual velocity vs intended velocity based on target
			-- determine which way the player is moving
			local playervelx, playervely = objects.ball[i].body:getLinearVelocity()		-- this is the players velocity vector			
		
			-- determine vector to target
			local vectorxtotarget = objects.ball[i].targetcoordX - objX
			local vectorytotarget = objects.ball[i].targetcoordY - objY
			
			-- determine the aceleration vector that needs to be applied to the velocity vector to reach the target.
			-- target vector - player velocity vector
			local acelxvector,acelyvector = SubtractVectors(vectorxtotarget, vectorytotarget,playervelx,playervely)
			
			-- so we now have mass and aceleration. Time to determine Force.
			-- F = m * a
			-- Fx = m * Xa
			-- Fy = m * Ya
			local intendedxforce = objects.ball[i].body:getMass() * acelxvector
			local intendedyforce = objects.ball[i].body:getMass() * acelyvector
			
			-- if target is in front of player and at maxV then discontinue the application of force
			-- can't cut aceleration because that is the braking force and we don't want to disallow that
			if dotVectors(playervelx, playervely,vectorxtotarget,vectorytotarget) > 0 then	-- > 0 means target is in front of player
				-- if player is exceeding maxV then cancel force
				if (playervelx > objects.ball[i].maxV) or (playervelx < (objects.ball[i].maxV * -1)) then
					-- don't apply any force until vel drops down
					intendedxforce = 0
				end
				if (playervely > objects.ball[i].maxV) or (playervely < (objects.ball[i].maxV * -1)) then
					-- don't apply any force
					intendedyforce = 0
				end	
			end

			-- if player intended force is great than the limits for that player then dial that intended force back
			if intendedxforce > objects.ball[i].maxF then
				intendedxforce = objects.ball[i].maxF
			end
			if intendedyforce > objects.ball[i].maxF then
				intendedyforce = objects.ball[i].maxF
			end
			
			-- if fallen down then no force
			if (strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" ) and objects.ball[i].fallendown then
				intendedxforce = 0
				intendedyforce = 0
			end
			
			-- the safeties move at half speed if the ball is airborne
			-- this lets them move to a defensive position without overshooting the eventual runner
			if strGameState == "Airborne" and (i == 21 or i == 22) then
				--if i == 21 then print("ForceX was " .. intendedxforce .. " but is now " .. intendedxforce/2) end
				intendedxforce = intendedxforce/2	-- move across the field at half speed while maintaining vertical speed
				--intendedyforce = intendedyforce/2
			end

			-- now apply dtime to intended force and then apply a random game speed factor
			--intendedxforce = intendedxforce * dtime * 20		-- pointless scaling up as long as maxF and maxV throttle this.
			--intendedyforce = intendedyforce * dtime * 20
	
			-- now we can apply force
			objects.ball[i].body:applyForce(intendedxforce,intendedyforce)	

			-- !!! need to NOT slow down if player is snapped and approaching target
		end

	end
end

function bolAllPlayersFormed()
	-- see if everyone is ready
	-- default bol to true and then set to false if someone is out of place
	local bolReady = true
	for i = 1,intNumOfPlayers do
		if objects.ball[i].mode ~= "readyforsnap" then
			bolReady = false
		end
	end
	return bolReady
end

function SetPlayersSensors(bolNewSetting, playernumber)
	-- will set the sensor of just one player or all 22 players
	-- if playernumber = 0 then do all players
	
	if playernumber == 0 then	-- set all players
		for i = 1,intNumOfPlayers do
			objects.ball[i].fixture:setSensor(not bolNewSetting)
		end
	end
	if playernumber > 0 and playernumber < 23 then	-- this is a safety check
		objects.ball[playernumber].fixture:setSensor(not bolNewSetting)
	end
end

function ProcessKeyInput()

--print("Proccessing keys")

	local targetadjustmentamountX = 2	-- just one place to adjust this
	local targetadjustmentamountY = 2	-- affects the speed of movement. I reckon dt should play a part here
	
	local bolMoveDown =false
	local bolMoveUp = false
	local bolMoveLeft = false
	local bolMoveRight = false
	local bolMoveWait = false
	
	local bolAnyKeyPressed = false

	-- check game state - really only care if looking or if QB is the runner
	if (strGameState == "Snapped" or strGameState == "Looking") or (strGameState == "Running" and intBallCarrier == 1) then	-- or strGameState == "Airborne" or strGameState == "Running" 
		if love.keyboard.isDown("kp2") or love.keyboard.isDown('x') or love.keyboard.isDown('down') then
			bolMoveDown = true
			bolAnyKeyPressed = true
		end
		if love.keyboard.isDown("kp8") or love.keyboard.isDown('w') or love.keyboard.isDown('up') then
			bolMoveUp = true
			bolAnyKeyPressed = true
		end
		if love.keyboard.isDown("kp4") or love.keyboard.isDown('a') or love.keyboard.isDown('left') then
			bolMoveLeft = true
			bolAnyKeyPressed = true
		end
		if love.keyboard.isDown("kp6") or love.keyboard.isDown('d') or love.keyboard.isDown('right') then
			bolMoveRight = true
			bolAnyKeyPressed = true
		end	
		if love.keyboard.isDown("kp5") or love.keyboard.isDown('s') or love.keyboard.isDown('space') then
			bolMoveWait = true
			bolAnyKeyPressed = true
		end
		
		-- set new targets for the QB based on his current position
		-- important to process diagonals first
		
		if bolMoveup and bolMoveLeft then
			objects.ball[1].targetcoordX = (objects.ball[1].body:getX() - 35)	 
			objects.ball[1].targetcoordY = (objects.ball[1].body:getY() - 35)
			-- reset these keys so they don't get processed twice
			bolMoveUp = false
			bolMoveLeft = false
			--print("alpha")
		end
		if bolMoveup and bolMoveRight then
			objects.ball[1].targetcoordX = (objects.ball[1].body:getX() + 35)	 
			objects.ball[1].targetcoordY = (objects.ball[1].body:getY() - 35)
			-- reset these keys so they don't get processed twice
			bolMoveUp = false
			bolMoveRight = false
			--print("beta")
		end	
		if bolMoveDown and bolMoveRight then
			objects.ball[1].targetcoordX = (objects.ball[1].body:getX() + 35)	 
			objects.ball[1].targetcoordY = (objects.ball[1].body:getY() + 35)
			-- reset these keys so they don't get processed twice
			bolMoveDown = false
			bolMoveRight = false
			--print("charlie")
		end				
		if bolMoveDown and bolMoveLeft then
			objects.ball[1].targetcoordX = (objects.ball[1].body:getX() - 35)	 
			objects.ball[1].targetcoordY = (objects.ball[1].body:getY() + 35)
			-- reset these keys so they don't get processed twice
			bolMoveDown = false
			bolMoveLeft = false
			--print("delta")
		end			
		if bolMoveUp then
			objects.ball[1].targetcoordY = (objects.ball[1].body:getY() - 35)
			bolMoveUp = false
			--print("echo")
		end			
		if bolMoveRight then
			objects.ball[1].targetcoordX = (objects.ball[1].body:getX() + 35)
			bolMoveRight = false
			--print("foxtrot")
		end	
		if bolMoveDown then
			objects.ball[1].targetcoordY = (objects.ball[1].body:getY() + 35)
			bolMoveDown = false
			--print("golf")
		end	
		if bolMoveLeft then
			objects.ball[1].targetcoordX = (objects.ball[1].body:getX() - 35)
			bolMoveLeft = false
			--print("hotel")
		end	
		
		if bolAnyKeyPressed == false then
			-- stop moving
			objects.ball[1].targetcoordX = (objects.ball[1].body:getX())	 
			objects.ball[1].targetcoordY = (objects.ball[1].body:getY())
		end
			
		
		-- ensure qb target stays on the field
		if objects.ball[1].targetcoordX < SclFactor(intLeftLineX) then objects.ball[1].targetcoordX = SclFactor(intLeftLineX) end
		if objects.ball[1].targetcoordX > SclFactor(intRightLineX) then objects.ball[1].targetcoordX = SclFactor(intRightLineX) end
		if objects.ball[1].targetcoordY < SclFactor(intTopPostY) then objects.ball[1].targetcoordY = SclFactor(intTopPostY) end
		if objects.ball[1].targetcoordY > SclFactor(intBottomPostY) then objects.ball[1].targetcoordY = SclFactor(intBottomPostY) end
	end

	if bolAnyKeyPressed == true then
		bolKeyPressed = true
	else
		bolKeyPressed = false
	end
end

function bolCarrierOutOfBounds()

	-- check if ball carrier is out of bounds
	if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Running" then
		ballX = objects.ball[intBallCarrier].body:getX()
		if ballX < SclFactor(intLeftLineX) or ballX > SclFactor(intRightLineX) then
			-- oops - ball out of bounds
			-- print (ballX)
			return true
		else
			return false
		end
	else
		return false	-- this should never trigger!
	end		
end

function round(num, idp)
	--Input: number to round; decimal places required
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	

function GetInverseSqrtDistance(x1, y1, x2, y2)
	return 1/math.sqrt(((x2-x1)^2)+((y2-y1)^2))
end

function SetPlayersFallen(bolNewSetting)

	for i = 1,intNumOfPlayers do
		objects.ball[i].fallendown = bolNewSetting
	end
end

function getAngle(currentx, currenty, targetx, targety)
	-- receives two vectors and returns the angle (in rads??)
	return math.atan2(targety - currenty, targetx - currentx)
end

function getDistance(x1, y1, x2, y2)
	-- this is real distance in pixels
	-- coorindate. Not vectors
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2
    --Both of these work
    local a = horizontal_distance * horizontal_distance
    local b = vertical_distance ^2

    local c = a + b
    local distance = math.sqrt(c)
    return distance
end

function UpdateBallPosition(dtime)
	-- assumes a throwning speed of 45 mph = 20 metres/second
	-- given current position x/y and a target positiong targetx/targety, move the football along that vector
	--! will need to factor dt at some point
	
	-- determine angle to target
	-- assume hypothenuse (20 * dt)
	-- determine new x and new y

	-- understand the vector for ball to target.
	if football.targetx == nil or football.targety == nil then
		vectorx = 0
		vectorx = 0
	else
		vectorx = football.targetx - football.x
		vectory = football.targety - football.y
	end
	
	-- see how long this vector is
	local disttotarget = getDistance(0, 0, vectorx, vectory)
	-- print("Dist to target: " .. disttotarget)
	
	if disttotarget < (intThrowSpeed * dtime) then
		-- the ball is on target so move it there.
		football.x = football.targetx
		football.y = football.targety
		
		-- need to check if ball is out of bounds
		if football.x < SclFactor(intLeftLineX) or football.x > SclFactor(intRightLineX) or football.y < SclFactor(intTopPostY) or football.y > SclFactor(intBottomPostY) then 
			-- oops - end play
			bolPlayOver = true
			strMessageBox = "Ball was thrown out of bounds. Incomplete."
			bolMoveChains = false
		else
			--! will need to determine if ball is caught
			
			--strGameState = ""	 --
			football.targetx = nil
			football.targety = nil
			football.carriedby = 0
			football.airborne = false	
			intBallCarrier = 0
			
			-- see if anyone caught it
			-- Determine who is closest to this position
			local closestdistance = 1000
			local closestplayer = 0
			
			for i = 2,22 do	-- Loop is 2,22 because the QB is not a valid receiver
				-- check distance between this player and the ball
				-- ignore anyone fallen down
				if not objects.ball[i].fallendown then
					mydistance = GetDistance(football.x,football.y, objects.ball[i].body:getX(),objects.ball[i].body:getY())
					if mydistance < closestdistance then
						-- we have a new candidate
						closestdistance = mydistance
						closestplayer = i
					end
				end
			end
			
			intBallCarrier = closestplayer
			football.carriedby = closestplayer
			
			if closestdistance > closestdistance / fltScaleFactor then
				strMessageBox = "No receivers."
			else
				strMessageBox = "The ball was caught by " .. objects.ball[intBallCarrier].positionletters
			end
			
		
			--! for now, we'll just give the ball to that person

			
			if closestplayer > 11 then
				-- oops - end play
				bolPlayOver = true
				--print("Knocked down.")
				strMessageBox = "Ball was knocked down by other team. Incomplete."
				bolMoveChains = false
			else
				-- someone on the offense team caught the ball so that's okay. Check if they fumble it
				--! might want to build in proximity modifiers at some point
				
				if love.math.random(1,100) < objects.ball[closestplayer].catchskill then
					-- ball caught
					strMessageBox = objects.ball[intBallCarrier].positionletters .. " is running with the ball"
				else
					-- ball dropped
					bolPlayOver = true
					strMessageBox = "Ball was fumbled and dropped. Incomplete."		
					bolMoveChains = false					
				end
			end	

			strGameState = "Running"
							
			
		end
	else
		-- ball is not at the target yet
		strMessageBox = "The ball is in the air ..."
		
		local ratio = disttotarget / (intThrowSpeed * dtime)
		-- print("Dist/ ratio: " .. ratio .. " so going to mulitply the vector by " .. 1/ratio)

		scaledx,scaledy = ScaleVector(vectorx,vectory,(1/ratio))
		football.x = football.x + scaledx
		football.y = football.y + scaledy		

	end
	
end

function ResetGame()
	if bolEndGame then
		strGameState = "FormingUp"
		strMessageBox = "Players getting ready"	
		intScrimmageY = 105
		intFirstDownMarker = intScrimmageY - 10		-- yards
		SetPlayersSensors(false,0)	-- turn off collisions
		SetPlayersFallen(false)		-- everyone stands up
		score.downs = 1
		score.plays = 0
		score.yardstogo = 10
		football.x = nil
		football.y = nil
		football.targetx = nil
		football.targety = nil
		football.carriedby = nil
		football.airborne = nil
		intBallCarrier = 0		-- this is the player index that holds the ball. 0 means forming up and not yet snapped.
		bolCheerPlayed = false
		bolPlayOver = false
		bolEndGame = false
		bolMoveChains = true
		soundwin:stop()
		soundlost:stop()
		SetRouteStacks()

	end
end

function DrawRoutes()
	-- for each WR, draw the route they will run
	
local previousX2
local previousY2
			
	for i = 2,4 do	-- for each WR
		for j = 1,9 do	-- for each coordinate in route (9 is an arbitrarily high number)
			-- draw a line
			
			if playerroutes[i][j] == nil then break end	-- run out of pairs. This loop is done.
			
			
			-- determining the end of the line is easier
			X2 = playerroutes[i][j][1]	-- player i \ route j \ X coordinate
			Y2 = playerroutes[i][j][2]
			
			-- now determine the start of this line
			if j == 1 then
				-- starting point is player's position
				
				X1 = objects.ball[i].body:getX() / fltScaleFactor -- need to return this to field coords
				Y1 = objects.ball[i].body:getY() / fltScaleFactor
			else
				-- starting point is the end of the previous line
				
				X1 = previousX2
				Y1 = previousY2
	
			end
			
			--print(X1 .. " " .. Y1 .. " " .. x2 .. " " .. y2 )
		
			-- now draw the line
			love.graphics.setColor(1, 1, 1,1) --set the drawing color
			love.graphics.line(SclFactor(X1),SclFactor(Y1),SclFactor(X2),SclFactor(Y2))
			
			previousX2 = X2
			previousY2 = Y2
		end
	end
end

function AdjustCameraZoom(cam)
	-- Receives a hump.Camera object, checks what the intended zoom is, what the real zoom is and then apply a new zoom with smoothing.
	
	if fltCurrentCameraZoom == fltFinalCameraZoom then
		-- nothing to do
	else
		if fltCurrentCameraZoom < fltFinalCameraZoom then
			fltCurrentCameraZoom = fltCurrentCameraZoom + fltCameraSmoothRate
			if fltCurrentCameraZoom > fltFinalCameraZoom then	-- this bit checks to see if we actually zoomed past the target zoom
				fltCurrentCameraZoom = fltFinalCameraZoom
			end
		end
		if fltCurrentCameraZoom > fltFinalCameraZoom then
			fltCurrentCameraZoom = fltCurrentCameraZoom - fltCameraSmoothRate
			if fltCurrentCameraZoom < fltFinalCameraZoom then	-- this bit checks to see if we actually zoomed past the target zoom
				fltCurrentCameraZoom = fltFinalCameraZoom
			end
		end
	end
	
	camera:zoomTo(fltCurrentCameraZoom)	
end

function SetCameraView()

	if strGameState == "FormingUp" then
		camera:lookAt(SclFactor(fltCentreLineX),SclFactor(70)) 	-- centre of the field
		fltFinalCameraZoom = 1
	end
	
	if strGameState == "Snapped" or strGameState == "Looking" then
		camera:lookAt(SclFactor(fltCentreLineX),SclFactor(intScrimmageY)) 
		fltFinalCameraZoom = 1.25	
	end
	
	if strGameState == "Airborne" then
		camera:lookAt((football.x),(football.y)) 
		fltFinalCameraZoom = 1.5
	end
	
	if strGameState == "Running" then
		camera:lookAt(objects.ball[intBallCarrier].body:getX(),objects.ball[intBallCarrier].body:getY())
		fltFinalCameraZoom = 1.5
	end	
	
	if bolEndGame then 
		-- reset the camera to something sensible
		fltFinalCameraZoom = 1 
		camera:lookAt(SclFactor(fltCentreLineX), SclFactor(80))
	end
	
	AdjustCameraZoom(camera)
end

function DrawPlayerStats(i, intPanelNum)
	-- Draw a player panel for player #1 in panel position intPanelNum

	local intPanelHeight = SclFactor(4)
	local intPanelWidth = SclFactor(5)
	local intPanelX = SclFactor(intRightLineX + 5)
	local intPanelY = SclFactor((intTopPostY - (intPanelHeight / fltScaleFactor)) + (intPanelHeight / fltScaleFactor) * intPanelNum)	-- top post + panel height * panel number. The - bit is to get alignment with top post
		
	-- ****************************
	-- printing order is important!
	-- ****************************

-- 1st column	
	-- draw background
	love.graphics.setColor(128/255, 128/255, 128/255)
	love.graphics.rectangle("fill",intPanelX,intPanelY,intPanelWidth, intPanelHeight)
	
	-- draw border
	love.graphics.setColor(96/255, 96/255, 96/255)
	love.graphics.rectangle("line",intPanelX,intPanelY,intPanelWidth, intPanelHeight)
		
	-- draw the position letters
	love.graphics.setColor(1, 1, 1)
	love.graphics.print (objects.ball[i].positionletters,intPanelX  + SclFactor(1) ,intPanelY  + SclFactor(1))	

-- 2nd column
	-- intPanelWidth = SclFactor(10)
	intPanelX = intPanelX + intPanelWidth
	
	--love.graphics.setColor(128/255, 128/255, 128/255)
	--love.graphics.rectangle("fill",intPanelX,intPanelY,intPanelWidth, intPanelHeight)	

	-- draw border
	love.graphics.setColor(96/255, 96/255, 96/255)
	love.graphics.rectangle("line",intPanelX,intPanelY,intPanelWidth, intPanelHeight)	
	
	-- draw text
	if i == 1 then	-- QB
	
		-- this works on 0 -> 10 with 0 being best
		local myValue = objects.ball[i].throwaccuracy
		intRedValue = myValue * 51
		if intRedValue > 255 then intRedValue = 255 end
		intGreenValue = (10 - myValue) * 51

		--print(intRedValue,intGreenValue)
		love.graphics.setColor(intRedValue/255, intGreenValue/255, 0)
		love.graphics.rectangle("fill",intPanelX,intPanelY,intPanelWidth, intPanelHeight)

		love.graphics.setColor(0, 0, 0)
		love.graphics.print ("THR", intPanelX  + SclFactor(1) ,intPanelY  + SclFactor(1))
	end
	if i == 2 or i == 3 or i== 4 then	-- WR
		local myValue = objects.ball[i].catchskill
		myValue = myValue - 80
	
		intGreenValue = myValue * 51
		intRedValue = (10 - myValue) * 51
		
		love.graphics.setColor(intRedValue/255, intGreenValue/255, 0)
		love.graphics.rectangle("fill",intPanelX,intPanelY,intPanelWidth, intPanelHeight)	
		
		love.graphics.setColor(0, 0, 0)
		love.graphics.print ("CTH", intPanelX  + SclFactor(1) ,intPanelY  + SclFactor(1))
	
	end

	
	
end

function love.mousereleased(x, y, button)

	-- this overrides the screen x/y with the world x/y noting that the camera messes things up.
	local x,y = camera:worldCoords(love.mouse.getPosition())
	
	-- capture the click because the ball target is different
	mouseclick.x = x
	mouseclick.y = y

	-- a mouse click means the ball might be thrown
	if intBallCarrier == 1 then		-- only the QB gets to throw
		if strGameState == "Snapped" or strGameState == "Looking" then
			if button == 1 then	-- main mouse button
				-- check if the mouse click is on-field and not out of bounds
				if x > SclFactor(intLeftLineX) and x < SclFactor(intRightLineX) then
					if y > SclFactor(intTopPostY) and y < SclFactor(intBottomPostY) then
						strGameState = "Airborne"
						football.x = objects.ball[1].body:getX()
						football.y = objects.ball[intBallCarrier].body:getY()				
						football.targetx = x
						football.targety = y
						football.carriedby = 0
						football.airborne = true	
						intBallCarrier = 0
						
						-- determine random ball accuracy
						-- this is a random vector and random direction
						local intplayerinaccuracy = objects.ball[1].throwaccuracy 
						-- print("Throw inaccuracy = " .. intplayerinaccuracy .. "%")
						
						-- add some inaccuracy based on distance between thrower and intended click
						-- if throw > 15 then add some randomness	-- 20 is arbitrary value
						local mydistance = getDistance(objects.ball[1].body:getX(), objects.ball[1].body:getY(), x, y)
						if mydistance > 20 then
							-- take the distance over 20 yards, divide by 15, then add that to inaccuracy
							myinacc = round((love.math.random(0, (mydistance - 20) / 15)),0)
							
							intplayerinaccuracy = intplayerinaccuracy + myinacc
							--print("Adding distance factor of " .. myinacc)
							--print("Inacc is now " .. intplayerinaccuracy)
							--print("=========")
						end
						
						
						local randomXvector = love.math.random(intplayerinaccuracy * -1, intplayerinaccuracy)
						local randomYvector = love.math.random(intplayerinaccuracy * -1, intplayerinaccuracy)
						football.targetx = football.targetx + SclFactor(randomXvector)
						football.targety = football.targety + SclFactor(randomYvector)
						
					end
					
				end
			end
		end
	end
end

function beginContact(a, b, coll)
	-- Gets called when two fixtures begin to overlap
	aindex = a:getUserData()	-- this gets the number of the player in contact
	bindex = b:getUserData()
	
	if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
	
		-- don't do ANY contact for same team
		if (aindex < 12 and bindex < 12) or (aindex > 11 and bindex > 11) then
			-- same team. Do nothing!
		else
			if objects.ball[aindex].fallendown or objects.ball[bindex].fallendown then	-- if either player has fallen down then do nothing
				-- do nothing
			else
				local chanceoffalling = objects.ball[aindex].balance
				if intBallCarrier == aindex then chanceoffalling = 85 end -- huge penalty if you hold the ball
				
				-- RB's have a reduced chance of falling
				if objects.ball[aindex].positionletters == "RB" then 
					chanceoffalling = chanceoffalling / 2
				end
				
				-- check if player A falls down
				if love.math.random(1,100) < chanceoffalling then
					-- oops - fell down!
					objects.ball[aindex].fallendown = true
					SetPlayersSensors(false, aindex)
				end
				
				-- check if player B falls down
				local chanceoffalling = objects.ball[bindex].balance
				if intBallCarrier == bindex then chanceoffalling = 85 end -- huge penalty if you hold the ball
				
				-- RB's have a reduced chance of falling
				if objects.ball[aindex].positionletters == "RB" then
					chanceoffalling = chanceoffalling / 2
				end
				
				if love.math.random(1,100) < chanceoffalling then
					-- oops - fell down!
					objects.ball[bindex].fallendown = true
					SetPlayersSensors(false, bindex)
				end	
			end			
		end
	end

end

function love.load()


	fltScaleFactor = 6	-- this is the ScaleFactor if window is 1920 / 1080
	
	local scrnWidth,scrnHeight = love.window.getDesktopDimensions(1)
	local applyRatio = 1080 /scrnHeight
	
	fltScaleFactor = fltScaleFactor / applyRatio	-- Scale the app to fit in the window
	
	--set window
	love.graphics.setBackgroundColor(0, 102/255, 0)
	void = love.window.setMode(SclFactor(120), SclFactor(150))
	love.window.setTitle("Love football " .. gameversion)
	
	InstantiatePlayers()
	
	CustomisePlayers()
	
	SetRouteStacks()
	
	camera = Camera(objects.ball[1].body:getX(), objects.ball[1].body:getY())
	camera.smoother = Camera.smooth.linear(100)
	
	Slab.Initialize(args)
	
	strGameState = "FormingUp"	-- this is not necessary here but just making sure

end

function love.update(dt)
	
	-- print(strGameState)
	
	Slab.Update(dt)
	
	DrawSidebar()
	DrawMessageBox()
	if strGameState ~= "CreditsBox" then
		DrawCreditsButton()
	end
	
	if strGameState == "CreditsBox" then
		DrawCreditsBox()
	end


	SetCameraView()
	
	SetPlayerTargets()
	
	ProcessKeyInput() -- this must be in the main loop as it sets key press global values
	if strGameState == "Looking" and not bolKeyPressed then
		-- do nothing
	elseif strGameState == "CreditsBox" then
		-- do nothing
	else
		MoveAllPlayers(dt)		
	end

	
	if strGameState == "Airborne" then
		-- Update ball position i nthe air
		UpdateBallPosition(dt)
	end	
	
	-- ***************************************************
	-- check for various triggers
	-- ***************************************************
	
	-- ball carrier is tackled	or out of bounds
	if intBallCarrier > 0 then
		if objects.ball[intBallCarrier].fallendown == true then
			bolPlayOver = true
			bolMoveChains = true
			--print("Ball carrier is tackled.")
			strMessageBox = "The ball carrier was tackled."
			
			mudpair = {objects.ball[intBallCarrier].body:getX(),objects.ball[intBallCarrier].body:getY()}
			table.insert(mudimages,mudpair)
		end	
	end
	
	-- Check if runner is out of bounds
	if intBallCarrier > 0 then	
		if bolCarrierOutOfBounds() then
			bolPlayOver = true
			--print("Ball carrier is out of bounds.")
			strMessageBox = "Ball is out of bounds."
		end
	end
	
-- state changes
	if strGameState == "FormingUp" then
		if bolAllPlayersFormed() then
			--print("Ready to snap")
			strGameState = ("Snapped")
			intBallCarrier = 1		-- QB gets the ball
			football.carriedby = 1
			SetPlayersSensors(true,0)	-- make players sense collisions
			soundgo:play()
			strMessageBox = "Ball snapped"		
		end	
	end

	if strGameState == "Snapped" then
		-- snapped and looking are almost the same thing. As soon as the snap - the QB starts looking
		strGameState = "Looking"
		strMessageBox = "The quarterback is looking for an opening"	
	end	
		
		
	if strGameState == "Looking" then
		-- need to see if QB has moved enough to actually be running
		if objects.ball[1].body:getY() < SclFactor(intScrimmageY + 3) then
			-- QB is close to scrimmage - declare him a runner
			strGameState = "Running"
			strMessageBox = "Player is running with the ball"		
		end
	end

	-- Do end-of-play things
	if bolPlayOver then
		soundwhistle:play()
		bolPlayOver = false
		strGameState = "FormingUp"
		
		SetPlayersSensors(false,0)	-- turn off collisions
		SetPlayersFallen(false)		-- everyone stands up
		
		-- SetTargets				-- no need to set targets here - it will be done in the forming stage

		score.downs = score.downs + 1
		score.plays = score.plays + 1
		
		--adjust line of scrimmage
		if bolMoveChains then	-- this defaults to TRUE and changed to FALSE if thrown out of bounds, fumbled or knocked down.
			if intBallCarrier > 0 and intBallCarrier < 12 then
				intScrimmageY = (objects.ball[intBallCarrier].body:getY() / fltScaleFactor ) 
			end
		end

		-- check if 1st down
		if intScrimmageY < intFirstDownMarker then
			-- print("LoS =" .. intScrimmageY .. " FDM = " .. intFirstDownMarker)
			score.downs = 1
		
			intFirstDownMarker = intScrimmageY - 10
			if intFirstDownMarker < intTopGoalY then intFirstDownMarker = intTopGoalY end
		end		
		
		-- update yards to go
		score.yardstogo = round((intScrimmageY - intFirstDownMarker),0) 

		-- check for end game
		if score.downs > 4 then
			--print("Turnover on downs.")
			strMessageBox = "Turnover on downs. Game over."	
			bolEndGame = true
			soundlost:play()
			fltFinalCameraZoom = 1
		end
		
		-- check for touchback
		if intBallCarrier > 0 and intBallCarrier < 12 then
			--print(objects.ball[intBallCarrier].body:getY() / fltScaleFactor ,SclFactor(intTopGoalY) )
			if (objects.ball[intBallCarrier].body:getY() / fltScaleFactor) > (intBottomGoalY) then
				-- touch back
				--print("Touch back.")
				strMessageBox = "Touch back. Game over."	
				bolEndGame = true
				soundlost:play()
				fltFinalCameraZoom = 1
			end
		end
		
		-- reset the routes
		SetRouteStacks()
	end	
	
	-- check for end of game things
	if intBallCarrier > 0 and intBallCarrier < 12 then
		if objects.ball[intBallCarrier].body:getY() < SclFactor(intTopGoalY) then
			-- touchdown
			if not bolCheerPlayed then
				soundcheer:play()
				bolCheerPlayed = true
				--print("Touchdown!")
				soundwin:play()
				score.plays = score.plays + 1
			end
			bolEndGame = true
			fltFinalCameraZoom = 1
			strMessageBox = "Touchdown!!! You win!"
		end
	end	
	
	-- do update world things
	if bolEndGame then
		-- do nothing
		--world:update(dt) --this puts the world into motion
		fltFinalCameraZoom = 1
		SetCameraView()
		--world:update(dt) --this puts the world into motion
	else
		if strGameState == "FormingUp" then
			-- update world with no collisions
			world:update(dt) --this puts the world into motion
					
		elseif (strGameState == "Looking" and not bolKeyPressed) or (strGameState == "Running" and intBallCarrier == 1 and not bolKeyPressed)  then	--! might take out "running later on"
			-- don't update world
		elseif (strGameState == "CreditsBox") then
			-- don't update world
		else
			-- update world and check for collisions
			world:update(dt) --this puts the world into motion
			world:setCallbacks(beginContact, endContact, preSolve, postSolve)		
		end
	end
end

function love.draw()

	camera:attach()	

	-- draw stadium
	if strGameState == "FormingUp" or strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		DrawStadium()
	end		
	
	-- draw players
	if strGameState == "FormingUp" or strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		DrawAllPlayers()
		-- DrawPlayersVelocity()
	end
	
	-- draw player stats
	if strGameState == "FormingUp" or strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		for i = 1,11 do
			--! DrawPlayerStats (i,i)
		end
	end	


	-- draw football
	if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		-- draw football on ball carier
		if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Running" then
			-- draw football on top of carrier
			love.graphics.setColor(1, 1, 1,1) --set the drawing color
			love.graphics.draw(footballimage, objects.ball[intBallCarrier].body:getX(), objects.ball[intBallCarrier].body:getY(),0,0.33,0.33,5,25)	
		end
		
		-- draw football in air
		if strGameState == "Airborne" then
			love.graphics.setColor(1, 1, 1,1) --set the drawing color
			love.graphics.draw(footballimage, football.x, football.y,0,0.33,0.33,5,25)			
		end
			

		-- draw ball target
		if football.airborne == true then
			love.graphics.setColor(0, 0, 1,1) --set the drawing color
			-- love.graphics.circle("line", football.targetx, football.targety, SclFactor(fltPersonWidth))	
			love.graphics.circle("line", mouseclick.x, mouseclick.y, SclFactor(fltPersonWidth))	
		end

	end
	
	-- draw routes
	if strGameState == "FormingUp" then
		DrawRoutes()
	end
	
	-- draw ball in flight
	if strGameState == "Airborne" then
		DrawDottedLine(football.x +15,football.y + 5,football.targetx,football.targety)
	
	end
	

	camera:detach()
	Slab.Draw()	

	--DrawScores()	
end



























