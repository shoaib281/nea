local concord = require("Concord")
local entity = concord.entity
local component = concord.component
local system = concord.system
local world = concord.world
local components = concord.components

local cl = {
    default = {1,1,1,1},
    loadoutBackgroundColor = {0,1,0},
    backgroundColor = {0.5,1,0},
    alternateBackgroundColor = {0.7,1,0.1},
    loadoutButtonColor = {0,0.5,1},
    loadoutText = {1,1,1},
    loadoutName = {0,0.8,1},
    loadoutInfo = {0.7, 0.7,0.7},
    purchaseBar = {0.6, 0.6,0.6},
    purchaseBox = {0.5,0.5,0.5},
    buttonHighlight = {0,0,0,0.5}
}

local game = {
    height = 700, 
    width = 1000,
    title = "Clash",
}

local gameStates = {
    purchaseMode = false,
    loadoutChosen = false
}

local player = {
    cash = 1000
}

local tl = {
    height = 5,
    width = 20,
    size = 120, 
    xOffset = 0
}

local loadouts = {
    {
        name = "Homeless",
        cash = 100
    },
    {
        name = "Poor",
        cash = 250
    },
    {
        name = "Middle class",
        cash = 500
    },
    {
        name = "Billionaire",
        cash = 2000
    }
}

local purchasableEntities = {
    {
        price = 10,
    },
    {
        price = 20
    },
    {
        price = 30
    },
    {
        price = 40
    },
    {
        price = 50
    },
    {
        price = 60
    },
    {
        price = 70
    },
    {
        price = 80
    },
    {
        price = 90
    },
    {
        price = 100
    },
    {
        price = 110
    },
    {
        price = 120
    },
    {
        price = 130
    },
    {
        price = 140
    },
    {
        price = 150
    }
}

local loadoutUI = {
    paddingY = 50,
    amount = 4,
    width = 220
} 

local purchaseUI = {
    amount = 15,
    size = 55
}

local fonts = {
    large = love.graphics.newFont(25),
    small = love.graphics.newFont(22)
    
}

local layers = {{},{},{},{},{},{}}
local gameEntityMap = {{},{},{},{},{}}

local inputs = {"right", "left"}

local world = concord.world()
local highlightEntity

concord.component("highlightOnMouse")

concord.component("pos", function(sf, x, y)
    sf.x = x
    sf.y = y
end)

concord.component("drawable", function(sf, type, layer, args)
    sf.type = type
    sf.layer = layer

    if type == "rectangle" then
        width, height, color = unpack(args)
        sf.width = width
        sf.height = height
        sf.color = color
    elseif type == "canvas" then
        canvas = unpack(args)
        sf.canvas = canvas
    elseif type == "image" then
        image = unpack(args)
        sf.image = image
    end
end)

concord.component("button", function(sf, x, y, width, height, func, args)
    sf.x = x
    sf.y = y
    sf.width = width
    sf.height = height
    sf.func = func
    sf.args = args
end)

concord.component("gameEntity", function(sf, index, xLoc, yLoc)
    sf.index = index
    sf.xLoc = xLoc
    sf.yLoc = yLoc
end)

local gameSystem = concord.system({
    gameEntities = {"gameEntity"}
})

local drawUI = concord.system({
    drawables = {"pos", "drawable"}
})

local buttonSystem = concord.system({
    buttons = {"button"},
    highlightables = {"button", "highlightOnMouse"}
})

function drawUI:init()
    self.drawables.onEntityAdded = function(pool, entity)
        layer = entity.drawable.layer
        
        if not layers[layer] then
            layers[layer] = {}
        end

        layers[layer][entity] = true
    end
    self.drawables.onEntityRemoved = function(pool, entity)
        layers[entity.drawable.layer][entity] = nil
    end
end

function gameSystem:init()
    self.gameEntities.onEntityAdded = function(pool, entity)
        local ge = entity.gameEntity
        gameEntityMap[ge.yLoc][ge.xLoc] = entity
    end
    self.gameEntities.onEntityRemoved = function(pool, entity)
        local ge = entity.gameEntity
        gameEntityMap[ge.yLoc][ge.xLoc] = nil
    end
end

function buttonSystem:checkClick(x, y)
    for _, ent in ipairs(self.buttons) do
        button = ent.button
        if x > button.x and x < button.x + button.width and y > button.y and y < button.y + button.height then
            highlightEntity:give("pos", 1200, 1200)
            button.func(button.args)
            break
        end
    end

    if gameStates.loadoutChosen and gameStates.purchaseMode then
        if y < (tl.size * tl.height) then
            local purchaseIndex = gameStates.purchaseMode
            posX, posY = getTilePosition(x,y)
            if player.cash >= purchasableEntities[purchaseIndex].price and gameEntityMap[posY][posX] == nil then
                player.cash = player.cash - purchasableEntities[purchaseIndex].price

                local newEntity = concord.entity(world)
                :give("gameEntity", purchaseIndex, posX, posY)
                :give("drawable", "image", 5,{purchasableEntities[purchaseIndex].image})
                :give("pos", (posX-1) * tl.size, (posY-1) * tl.size)
               
                readyToPlaceEntity:give("pos", 1200, 1200)
            end
        end
    end
end

function buttonSystem:highlight(x,y)
    local highlighted = false

    for _, ent in ipairs(self.highlightables) do
        button = ent.button
        if x > button.x and x < button.x + button.width and y > button.y and y < button.y + button.height then
            highlighted = true
            highlightEntity:give("pos", button.x, button.y)
            highlightEntity.drawable.width = button.width
            highlightEntity.drawable.height = button.height
            break
        end
    end

    if not highlighted then
        highlightEntity:give("pos", 1200, 1200)
    end

    if gameStates.loadoutChosen and gameStates.purchaseMode then
       setPurchaseHighlightPosition(x,y) 
    end
end

function drawUI:draw()
    for i,layer in ipairs(layers) do
        for entity,_ in pairs(layer) do
            if entity.drawable.type == "rectangle" then
                love.graphics.setColor(entity.drawable.color)
                love.graphics.rectangle("fill", entity.pos.x, entity.pos.y, entity.drawable.width, entity.drawable.height)
                love.graphics.setColor(cl.default)
            elseif entity.drawable.type == "canvas" then
                love.graphics.draw(entity.drawable.canvas, entity.pos.x, entity.pos.y)
            elseif entity.drawable.type == "image" then
                love.graphics.draw(entity.drawable.image, entity.pos.x + tl.xOffset, entity.pos.y)
            end
        end
    end
end

function tl:draw()
    for y = 1, self.height do
        for x = 1, self.width do
            posX = (x - 1) * self.size 
            posY = (y - 1) * self.size

            if (math.abs(y - x) + 2) % 2 == 0 then
                love.graphics.setColor(cl.backgroundColor)    
            else
                love.graphics.setColor(cl.alternateBackgroundColor)
            end
            love.graphics.rectangle("fill", posX + tl.xOffset, posY, self.size, self.size)
            love.graphics.setColor(cl.default)
        end
    end
end


world:addSystems(drawUI)
world:addSystems(buttonSystem)

highlightEntity = concord.entity(world)
:give("pos", 1200,1200)
:give("drawable", "rectangle",4,{20,20, cl.buttonHighlight})

readyToPlaceEntity = concord.entity(world)
:give("pos", 1200, 1200)
:give("drawable","rectangle", 2,{tl.size, tl.size, cl.buttonHighlight})

function purchaseMode(args)
    gameStates.purchaseMode = unpack(args)
end

function chooseAloadout(args)
    world:clear()

    world:addEntity(highlightEntity)
    world:addEntity(readyToPlaceEntity)
    world:addSystems(gameSystem)

    loadoutNumber = unpack(args)
    gameStates.loadoutChosen = loadoutNumber
    local loadout = loadouts[loadoutNumber]
    player.cash = loadout.cash

    local canvas = love.graphics.newCanvas(game.width, game.height - (tl.size * tl.height))
    local canvasX = 0
    local canvasY = game.height - canvas:getHeight()

    love.graphics.setCanvas(canvas)
    love.graphics.setColor(cl.purchaseBar)
    love.graphics.rectangle("fill",0,0, canvas:getWidth(), canvas:getHeight())
    
    love.graphics.setColor(cl.purchaseBox)
    local stripSize = (canvas:getWidth() - (purchaseUI.amount * purchaseUI.size)) / (purchaseUI.amount + 1)
    for i = 1,purchaseUI.amount do
        xPos = (i * stripSize) + ((i-1) * purchaseUI.size)
        yPos = 20

        love.graphics.rectangle("fill", xPos, yPos, purchaseUI.size, purchaseUI.size)

        local buttonEntity = concord.entity(world)
        buttonEntity:give("button", canvasX + xPos, canvasY + yPos, purchaseUI.size, purchaseUI.size, purchaseMode, {i})
        buttonEntity:give("highlightOnMouse")
    end

    love.graphics.setCanvas()
    love.graphics.setColor(cl.default)

    local canvas = concord.entity(world)
    :give("pos", canvasX, canvasY)
    :give("drawable","canvas", 3, {canvas})

    for i = 1, purchaseUI.amount do
        purchasableEntities[i].image = love.graphics.newImage("Images/"..i..".png")
    end
end

function love.load()
    love.window.setMode(game.width, game.height)
    love.window.setTitle(game.title)
    love.graphics.setBackgroundColor(cl.backgroundColor)
    local font = fonts.large

    local stripSize = (game.width - (loadoutUI.amount * loadoutUI.width)) / (loadoutUI.amount + 1) 
    
    for i = 1,loadoutUI.amount do
        local canvas = love.graphics.newCanvas(loadoutUI.width, game.height - loadoutUI.paddingY * 2)
        local canvasX = (i * stripSize) + ((i - 1) * loadoutUI.width)
        local canvasY = loadoutUI.paddingY

        local subCanvasOffset = 10
        local subCanvasWidth = canvas:getWidth() - (subCanvasOffset * 2)

        love.graphics.setCanvas(canvas)
        love.graphics.setColor(cl.loadoutBackgroundColor)

        love.graphics.rectangle("fill",0,0, canvas:getWidth(), canvas:getHeight()) -- total  

        love.graphics.setColor(cl.loadoutName) -- loadout name
        love.graphics.rectangle("fill",subCanvasOffset,20, subCanvasWidth, 100)

        love.graphics.setColor(cl.loadoutText)
        love.graphics.printf(loadouts[i].name, font, subCanvasOffset, 50,subCanvasWidth, "center")
        
        love.graphics.setColor(cl.loadoutInfo) -- stats
        love.graphics.rectangle("fill", subCanvasOffset, 140, subCanvasWidth, 310) -- 120, 350

        local buttonCanvas = love.graphics.newCanvas(subCanvasWidth, 100)
        local buttonCanvasX = subCanvasOffset
        local buttonCanvasY = canvas:getHeight() - 130

        love.graphics.setCanvas(buttonCanvas)

        love.graphics.setColor(cl.loadoutButtonColor) -- button
        love.graphics.rectangle("fill", 0, 0, buttonCanvas:getWidth(), buttonCanvas:getHeight()) -- select box

        love.graphics.setColor(cl.loadoutText)
        love.graphics.printf("Select", font,0, 30, buttonCanvas:getWidth(),"center") -- select button
        
        local buttonEntity = concord.entity(world)
        buttonEntity:give("button", canvasX + buttonCanvasX, canvasY + buttonCanvasY, buttonCanvas:getWidth(), buttonCanvas:getHeight(), chooseAloadout, {i})
        buttonEntity:give("highlightOnMouse")

        love.graphics.setCanvas(canvas)
        love.graphics.setColor(cl.default)
        love.graphics.draw(buttonCanvas, buttonCanvasX, buttonCanvasY)

        local canvas = concord.entity(world)
        :give("pos", canvasX, canvasY)
        :give("drawable", "canvas", 1, {canvas})

        love.graphics.setColor(cl.default)
        love.graphics.setCanvas()
    end
end

function getTilePosition(x,y)
    xPos = x - tl.xOffset
    yPos = y

    xPos = math.ceil(xPos/tl.size)
    yPos = math.ceil(yPos/tl.size)

    return xPos, yPos
end

function setPurchaseHighlightPosition(x,y)
    xPos, yPos = getTilePosition(x,y)

    if yPos <= tl.height then
        if gameEntityMap[yPos][xPos] == nil then
            readyToPlaceEntity:give("pos", ((xPos-1)*tl.size) + tl.xOffset, (yPos-1) * tl.size)
        else
            readyToPlaceEntity:give("pos", 1200, 1200)    
        end
    else
        readyToPlaceEntity:give("pos", 1200, 1200)
    end
end

function love.update(dt)
    world:emit("update", dt)

    if gameStates.loadoutChosen then
        local left = false
        local right = false

        for _, key in pairs(inputs) do
            if love.keyboard.isDown(key) then
                if key == "right" then
                    right = true
                elseif key == "left" then
                    left = true
                end
            end
        end

        if left ~= right then
            if right then
                tl.xOffset = tl.xOffset -10
            else
                tl.xOffset = tl.xOffset + 10
            end

            if tl.xOffset > 0  then
                tl.xOffset = 0
            elseif tl.xOffset < - 1400 then
                tl.xOffset = -1400
            end

            setPurchaseHighlightPosition(love.mouse.getPosition())
        end
    end
end

function love.draw()
    if gameStates.loadoutChosen then
        tl:draw()
    end
    world:emit("draw")

    if gameStates.loadoutChosen then
        love.graphics.setFont(fonts.small)
        love.graphics.print("Cash: ".. player.cash, 10,10)
    end
end

function love.mousereleased(x,y, button)
    world:emit("checkClick", x, y)
end

function love.mousemoved(x,y)
    world:emit("highlight",x,y)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        if gameStates.loadoutChosen then 
            gameStates.purchaseMode = false 
            readyToPlaceEntity:give("pos", 1200, 1200)
        end 
    end
end