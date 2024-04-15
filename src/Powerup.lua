--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Najlae Abarghache

    Represents a powerup that can spawn randomly, and gradually descend toward the player. 
    Once collided with the Paddle, two more Balls should spawn and behave identically to 
    the original, including all collision and scoring points for the player. Once the player 
    wins and proceeds to the VictoryState for their current level, the Balls should reset so 
    that there is only one active again.
]]

Powerup = Class{}

--[[
    Our Powerup will initialize at the different spots randomly.
]]
function Powerup:init(x, y, key)
    -- the powerup dropping slowly
    self.dx = 0
    self.dy = math.random(20, 30)
	self.x = x
	self.y = y
	self.dx = 0

    -- dimensions
    self.width = 16
    self.height = 16

    -- used to determine whether this powerup should be rendered
    self.inPlay = true

	self.key = key
end

--[[
    Expects an argument with a bounding box, be that a paddle,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
	-- check if the left edge of either obect is farther to the right 
	-- than the right edge of the other
	if self.x > target.x + target.width or target.x > self.x + self.width then
		return false
	end

	-- check if the bottom edge of either object is higher than the  
	-- top edge of the other
	if self.y > target.y + target.height or target.y > self.y + self.height then
		return false
	end

	-- if neither of the above are true, then the objects are overlapping
	return true
end

function Powerup:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    self.dx = 0
	self.dy = self.dy + 20 * dt
end

function Powerup:render()
	love.graphics.draw(gTextures['main'], gFrames['powerups'][self.key], self.x, self.y)
end

function Powerup:getKey()
	if self.key == MULTIBALL then
		return 'multiball'
		
	elseif self.key == UNLOCK then
		return 'unlock'
	else
		return false
	end
end