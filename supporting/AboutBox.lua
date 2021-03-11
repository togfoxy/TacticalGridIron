local Slab = require 'Slab'


function love.mousepressed(x,y,button, istouch,presses)
	-- print(x,y)

end

function love.load(args)
    love.graphics.setBackgroundColor(0.4, 0.88, 1.0)
    Slab.Initialize(args)
end

function love.update(dt)
    Slab.Update(dt)
  
    Slab.BeginWindow('Credits', {Title = "About",BgColor = {0.5,0.5,0.5},AutoSizeWindow = true,NoOutline=true,AllowMove = false})
	
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
		love.event.quit()
	end
	
	Slab.EndLayout()
	
    Slab.EndWindow()

end

function love.draw()
    Slab.Draw()
end