local concord = require("Concord")
local entity = concord.entity
local component = concord.component
local system = concord.system
local world = concord.world

local components = concord.components

local gameSize = {
    height = 700, 
    width = 1000
}

concord.component("pos", function(sf, x, y)
    sf.x = x
    sf.y = y
end)

concord.component("canvas", function(sf, canvas)
    sf.canvas = canvas
end)

local drawUI = concord.system({
    canvases = {"pos", "canvas"}
})

function drawUI:draw()
    for _,canvas in ipairs(self.canvases) do
        love.graphics.draw(canvas.canvas.canvas, canvas.pos.x, canvas.pos.y)
    end
end

local world = concord.world()
world:addSystems(drawUI)

local container = {
    padding = 100,
    amount = 4,
    width = 100
} 



function love.load()
    love.window.setMode(gameSize.width, gameSize.height)

    for i = 1,container.amount do
        local canvas = love.graphics.newCanvas(container.width, gameSize.height - container.padding * 2)
        love.graphics.setCanvas(canvas)

        love.graphics.setColor(1,1,0)
        love.graphics.rectangle("fill",0,0, canvas:getWidth(), canvas:getHeight())

        love.graphics.setColor(1,0,0)
        love.graphics.rectangle("fill", 0, canvas:getHeight() - 150, canvas:getWidth(), 100)

        local canvas = concord.entity(world)
        :give("pos", 200 * i - container.width/2, container.padding)
        :give("canvas", canvas)

        love.graphics.setColor(1, 1,1,1)
        love.graphics.setCanvas()
    end
end

function love.update(dt)
    world:emit("update", dt)
end

function love.draw()
    world:emit("draw")
end