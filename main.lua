--[[
    Flappy Bird Remake

    Author: Ilias Tolegenov
    mister.tolegenov@gmail.com

    A mobile game by Dong Nguyen that went viral in 2013, utilizing a very simple 
    but effective gameplay mechanic of avoiding pipes indefinitely by just tapping 
    the screen, making the player's bird avatar flap its wings and move upwards slightly. 
    A variant of popular games like "Helicopter Game" that floated around the internet
    for years prior. Illustrates some of the most basic procedural generation of game
    levels possible as by having pipes stick out of the ground by varying amounts, acting
    as an infinitely generated obstacle course for the player.
]]

-- virtual resolution handling library
push = require 'push'

-- classic OOP class library
Class = require 'class'

-- bird class we've written
require 'Bird'

-- pipe class we've written
require 'Pipe'

-- class representing pair of pipes together
require 'PipePair'

-- all code related to game state and state machines
require 'StateMachine'
require 'states/BaseState'
require 'states/PlayState'
require 'states/CountdownState'
require 'states/ScoreState'
require 'states/TitleScreenState'

-- physical screen dimensions
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- virtual resolution dimensions
VIRTUAL_WIDTH = 512
VIRTUAL_HEIGHT = 288

--
-- images we load into memory from files to later draw onto the screen
--

-- background image and starting scroll location on X axis
local background = love.graphics.newImage('background.png')
local backgroundScroll = 0

-- ground image and starting scroll location on X axis
local ground = love.graphics.newImage('ground.png')
local groundScroll = 0

-- speed at which we should scroll our images, scaled by dt
local BACKGROUND_SCROLL_SPEED = 30
local GROUND_SCROLL_SPEED = 60

-- point at which we should loop our background back to X = 0
local BACKGROUND_LOOPING_POINT = 413

-- point at which we should loop our ground back to X = 0
local GROUND_LOOPING_POINT = 514

-- scrolling variable to pause the game when we collide with a pipe
local scrolling = true

function love.load()
    -- initialize our nearest-neighbor filter
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- app window title
    love.window.setTitle('Flappy Bird')

    -- initialize our nice-looking retro text fonts
    smallFont = love.graphics.newFont('font.ttf', 8)
    mediumFont = love.graphics.newFont('flappy.ttf', 14)
    flappyFont = love.graphics.newFont('flappy.ttf', 28)
    hugeFont = love.graphics.newFont('flappy.ttf', 56)
    love.graphics.setFont(flappyFont)

    -- initialize our virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- initialize state machine with all state-returning functions
    gStateMachine = StateMachine {
        ['title'] = function() return TitleScreenState() end,
        ['countdown'] = function() return CountdownState() end,
        ['play'] = function() return PlayState() end,
        ['score'] = function() return ScoreState() end
    }
    gStateMachine:change('title')

    -- initialize input table
    love.keyboard.keysPressed = {}
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    -- add to our table of keys pressed this frame
    love.keyboard.keysPressed[key] = true

    if key == 'escape' then
        love.event.quit()
    end
end

--[[
    New function used to check our global iput table for keys we activated during
    this frame, looked up by their string value
]]
function love.keyboard.wasPressed(key)
    if love.keyboard.keysPressed[key] then
        return true
    else
        return false
    end
end

function love.update(dt)
    -- scroll background by preset speed * dt, looping back to 0 after the looping point
    backgroundScroll = (backgroundScroll + BACKGROUND_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT

    -- scroll ground by preset speed * dt, looping back to 0 after the screen width passes
    groundScroll = (groundScroll + GROUND_SCROLL_SPEED * dt) % GROUND_LOOPING_POINT

    -- now, we just update the state machine, which deferes to the right state
    gStateMachine:update(dt)

    -- reset input table
    love.keyboard.keysPressed = {}
end

function love.draw()
    push:start()
    
    -- here, we draw our images shifted to the left by their looping point; evetually,
    -- they will revert back to 0 once a certain distance has elapsed, which will make it
    -- seem as if they are infinitely scrolling. Choosing a looping point that is seameless
    -- is key, so as to provide the illusion of looping

    -- draw the background at the negative looping point
    love.graphics.draw(background, -backgroundScroll, 0)

    -- draw state machine between background and ground, which defers
    -- render logic to the currently active state
    gStateMachine:render()

    -- draw the ground on top of the background, toward the bottom of the screen
    -- at its negative looping point
    love.graphics.draw(ground, -backgroundScroll, VIRTUAL_HEIGHT - 16)

    
    push:finish()
end