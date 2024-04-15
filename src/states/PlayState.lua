--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.powerups = {}
    self.level = params.level
    self.powersActive = params.powersActive

    self.recoverPoints = 5000

    -- give the balls random starting velocities
    for k, ball in pairs(self.balls) do
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end

end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end

    for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
    end

    for k, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for j, ball in pairs(self.balls) do
        for k, brick in pairs(self.bricks) do
            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                if not brick.isLocked then
                    -- add to score
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)

                    -- decrement recoverPoints if we aren't at max paddle size or health
                    if self.paddle.size < 4 or self.health < 3 then
                        self.recoverPoints = self.recoverPoints - (brick.tier * 200 + brick.color * 25)
                    end

                    -- trigger the brick's hit function, which removes it from play
                    brick:hit()

                    -- if we have enough points, recover a point of health
                    if self.score > self.recoverPoints then
                        -- can't go above 3 health
                        self.health = math.min(3, self.health + 1)

                        -- multiply recover points by 2
                        self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                        -- play recover sound effect
                        gSounds['recover']:play()

                        if self.paddle.size < 4 then
                            self.paddle:grow()
                        end
                    end

                    -- go to our victory screen if there are no more bricks left
                    if self:checkVictory() then
                        gSounds['victory']:play()

                        self.paddle.size = 2

                        gStateMachine:change('victory', {
                            level = self.level,
                            paddle = self.paddle,
                            health = self.health,
                            score = self.score,
                            highScores = self.highScores,
                            balls = self.balls,
                            recoverPoints = self.recoverPoints
                        })
                    end

                -- handle locked brick collision if we have the unlock powerup
                elseif brick.isLocked and self.powersActive['unlock'] then
                    brick.isLocked = false
                    self.score = self.score + 2500
                    self.powersActive['unlock'] = false
                    gSounds['brick-hit-2']:play()

                -- handle ball collision /w locked brick without powerup
                else
                    gSounds['brick-hit-2']:play()
                end


                -- spawn a powerup
                if math.random(10) == 1 and self.powerups['multiball'] == nil and self.powersActive['multiball'] == false then
                    self.powerups['multiball'] = Powerup(ball.x, ball.y, MULTIBALL)
                        
                elseif math.random(10) == 1 and self.powerups['unlock'] == nil and self.powersActive['unlock'] == false then
                    self.powerups['unlock'] = Powerup(ball.x, ball.y, UNLOCK)
                end

                -- bounce the ball off of the brick
                ball:collidesWithBrick(brick)

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end


    -- collision
    for k, powerup in pairs(self.powerups) do
        if powerup:collides(self.paddle) then

            gSounds['confirm']:play()
            -- set flag that the power is active, remove collectable
            self.powersActive[powerup:getKey()] = true

            -- if the powerup is multiball, spawn some new ones rn
            if powerup.key == MULTIBALL then
                for i = 2, 3, 1 do
                    self.balls[i] = Ball(self.balls[1].x, self.balls[1].y)
                    self.balls[i].dx = math.random(-200, 200)
                    self.balls[i].dy = math.random(-50, -60)
                end
            end
            self.powerups[powerup:getKey()] = nil
        end
    end

    -- Flag to track if we missed all the balls
    local allBallsBelowHeight = true

    -- Check if a ball is still above bounds
    for k, ball in pairs(self.balls) do
        if ball.y < VIRTUAL_HEIGHT then
            allBallsBelowHeight = false
            break
        end
    end

    -- If all balls go below bounds, update health and paddle size
    if allBallsBelowHeight then
        self.health = self.health - 1
        self.paddle:shrink()
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                powersActive = {
                    multiball = false,
                    unlock = false
                }
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for k, ball in pairs(self.balls) do
        ball:render()
    end

    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    renderScore(self.score)
    renderHealth(self.health)


    if self.powersActive['unlock'] then
        renderUnlockPowerup()
    end

    if self.powersActive['multiball'] then
        renderMultiballPowerup()
    end

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end

