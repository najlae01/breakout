--[[
    GD50
    Breakout Remake

    -- ServeState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The state in which we are waiting to serve the ball; here, we are
    basically just moving the paddle left and right with the ball until we
    press Enter, though everything in the actual game now should render in
    preparation for the serve, including our current health and score, as
    well as the level we're on.
]]

ServeState = Class{__includes = BaseState}

function ServeState:enter(params)
    -- grab game state from params
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.level = params.level
    self.recoverPoints = params.recoverPoints

    -- init new ball (random color for fun)
    self.powersActive = params.powersActive

    -- init new ball (random color for fun)
    self.balls = {}

    if self.powersActive['multiball'] then
        --  spawn 3 balls when during multiball mode
        for i = 2, 3, 1 do
            self.balls[i] = Ball(self.paddle.x + (self.paddle.width / 2) - 4, self.paddle.y - 8)
        end
    else
        self.balls[1] = Ball(self.paddle.x + (self.paddle.width / 2) - 4, self.paddle.y - 8)
    end
end

function ServeState:update(dt)
    -- have the ball track the player
    self.paddle:update(dt)
    for k, ball in pairs(self.balls) do
        ball.x = self.paddle.x + (self.paddle.width / 2) - 4
        ball.y = self.paddle.y - 8
    end

    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        -- pass in all important state info to the PlayState
        gStateMachine:change('play', {
            paddle = self.paddle,
            bricks = self.bricks,
            health = self.health,
            score = self.score,
            highScores = self.highScores,
            balls = self.balls,
            level = self.level,
            recoverPoints = self.recoverPoints,
            powersActive = self.powersActive
        })
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function ServeState:render()
    self.paddle:render()
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('Level ' .. tostring(self.level), 0, VIRTUAL_HEIGHT / 3,
        VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Press Enter to serve!', 0, VIRTUAL_HEIGHT / 2,
        VIRTUAL_WIDTH, 'center')
end