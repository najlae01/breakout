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
function Powerup:init(skin)
    -- the powerup dropping slowly
    self.dx = 0
    self.dy = 20

    -- dimensions
    self.width = 16
    self.height = 16

    self.skin = skin

    -- used to determine whether this powerup should be rendered
    self.inPlay = true
end

--[[
    Expects an argument with a bounding box, be that a paddle,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(other)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > other.x + other.width or other.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > other.y + other.height or other.y > self.y + self.height then
        return false
    end

    -- if the above aren't true, they're overlapping
    return true
end

function Powerup:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function Powerup:render()
    -- gTexture is our global texture for all blocks
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin],
        self.x, self.y)
end