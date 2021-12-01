local concord = require("Concord")
local entity = concord.entity
local component = concord.component
local system = concord.system
local world = concord.world
local components = concord.components
local networking

local socket = require "socket"

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
    purchaseBoxBuyButton = {0.3,0.3,0.3},
    buttonHighlight = {0,0,0,0.5},
    black = {0,0,0},
    red = {1,0,0}
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
    height = 10,
    width = 20,
    size = 60, 
    xOffset = 0,
    defaultImageSize = 120
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
        name = "shoaib"
    },
    {
        price = 20,
        name = "kant"
    },
    {
        price = 30,
        name = "leibniz"
    },
    {
        price = 40,
        name = "descartes"
    },
    {
        price = 50,
        name = "nietszche"
    },
    {
        price = 60,
        name = "rousseau"
    },
    {
        price = 70,
        name = "sartre"
    },
    {
        price = 80,
        name = "foccault"
    },
    {
        price = 90,
        name = "schopen"
    },
    {
        price = 100,
        name = "camus"
    },
    {
        price = 110,
        name = "voltaire"
    },
    {
        price = 120,
        name = "witttein"
    },
    {
        price = 130,
        name = "locke"
    },
    {
        price = 140,
        name = "hegel"
    },
    {
        price = 150,
        name = "aquinas"
    }
}

local loadoutUI = {
    paddingY = 50,
    amount = 4,
    width = 220
} 

local purchaseUI = {
    framePaddingY = 10,
    amount = 15,
    sizeX = 60,
    sizeY = 70,
    buttonPaddingX = 5,
    buttonPaddingY = 45,
    buttonHeight = 20,
    popupHeight = 150,
    popupWidth = 150
}

local fonts = {
    large = love.graphics.newFont(25),
    small = love.graphics.newFont(22)
    
}

local layers = {{},{},{},{},{},{}}
local gameEntityMap = {}

local inputs = {"right", "left"}

local world = concord.world()
local highlightEntity
local popupDescriptionEntity

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
        image, scale = unpack(args)
        sf.image = image
        sf.scale = scale
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

concord.component("popupDescription")

local gameSystem = concord.system({
    gameEntities = {"gameEntity"}
})

local drawUI = concord.system({
    drawables = {"pos", "drawable"}
})

local buttonSystem = concord.system({
    buttons = {"button"},
    highlightables = {"button", "highlightOnMouse"},
    popups = {"popupDescription"}
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
        popupDescriptionEntity:give("pos", 1200, 1200)
        if y < (tl.size * tl.height) then
            local purchaseIndex = gameStates.purchaseMode
            posX, posY = getTilePosition(x,y)
            if player.cash >= purchasableEntities[purchaseIndex].price and gameEntityMap[posY][posX] == nil then
                if posX ~= 1 and posX ~= tl.width then
                    if networking then 
                        networking:send("p"..tostring(purchaseIndex)..":"..tostring(posX)..":"..tostring(posY)) 
                    end

                    player.cash = player.cash - purchasableEntities[purchaseIndex].price

                    placeEntity(purchaseIndex, posX, posY)
                
                    readyToPlaceEntity:give("pos", 1200, 1200)
                end
            end
        end
    end
end

function placeEntity(index, posX, posY)
    print(purchasableEntities)
    print(index, posX, posY, purchasableEntities[index], tl.size, tl.defaultImageSize)
    local newEntity = concord.entity(world)
    :give("gameEntity", index, posX, posY)
    :give("drawable", "image", 5,{purchasableEntities[index].image, tl.size/tl.defaultImageSize})
    :give("pos", (posX-1) * tl.size, (posY-1) * tl.size)
end

function buttonSystem:highlight(x,y)
    local highlighted = false

    for _, ent in ipairs(self.highlightables) do
        button = ent.button
        if x > button.x and x < button.x + button.width and y > button.y and y < button.y + button.height then
            highlighted = ent
            highlightEntity:give("pos", button.x, button.y)
            highlightEntity.drawable.width = button.width
            highlightEntity.drawable.height = button.height
            break
        end
    end

    if not highlighted then
        highlightEntity:give("pos", 1200, 1200)

        if gameStates.loadoutChosen then
            popupDescriptionEntity:give("pos", 1200, 1200)
        end
    else
        if self.popups:has(highlighted) and not gameStates.purchaseMode then
            popupDescriptionEntity:give("pos", highlighted.button.x, highlighted.button.y - purchaseUI.popupHeight - purchaseUI.framePaddingY - purchaseUI.buttonPaddingY - 5)
        end
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
                love.graphics.draw(entity.drawable.image, entity.pos.x + tl.xOffset, entity.pos.y, 0,entity.drawable.scale, entity.drawable.scale)
                --love.graphics.draw()
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
            if (y == 1 and x == 1) or (x == 1 and y == self.height) or (x == self.width and y == 1) or (x == self.width and y == self.height) then
                love.graphics.setColor(cl.black)
            elseif x == 1 or x == self.width then
                love.graphics.setColor(cl.red)
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

function generatePopUp(index)

    local canvas = love.graphics.newCanvas(purchaseUI.popupWidth, purchaseUI.popupHeight)
    
    love.graphics.setCanvas(canvas)
    love.graphics.setColor(cl.loadoutInfo)
    love.graphics.rectangle("fill",0,0,canvas:getWidth(), canvas:getHeight())

    local y = 0

    for ind, value in pairs(purchasableEntities[index]) do
        love.graphics.setColor(cl.default)
        if ind ~= "image" then
            love.graphics.print(ind.. ": ".. value, 0, y)
            y = y + 15
        end
    end


    love.graphics.setCanvas()
    love.graphics.setColor(cl.default)
    
    return canvas
end

function chooseAloadout(args)
    if networking then
        networking:send("norm")
    end

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
    
    local stripSize = (canvas:getWidth() - (purchaseUI.amount * purchaseUI.sizeX)) / (purchaseUI.amount + 1)
    for i = 1,purchaseUI.amount do
        xPos = (i * stripSize) + ((i-1) * purchaseUI.sizeX)
        yPos = purchaseUI.framePaddingY

        love.graphics.setColor(cl.purchaseBox)
        love.graphics.rectangle("fill", xPos, yPos, purchaseUI.sizeX, purchaseUI.sizeY)
        
        love.graphics.setColor(cl.default)
        love.graphics.printf(purchasableEntities[i].name, xPos, yPos, purchaseUI.sizeX, "center")
        love.graphics.printf("".. purchasableEntities[i].price, xPos, yPos + 20, purchaseUI.sizeX, "center")

        love.graphics.setColor(cl.purchaseBoxBuyButton)
        love.graphics.rectangle("fill", xPos+purchaseUI.buttonPaddingX, yPos + purchaseUI.buttonPaddingY, purchaseUI.sizeX - (purchaseUI.buttonPaddingX * 2), purchaseUI.buttonHeight )
        love.graphics.setColor(cl.default)
        love.graphics.printf("Buy", xPos+purchaseUI.buttonPaddingX, yPos + purchaseUI.buttonPaddingY + 2, purchaseUI.sizeX - (purchaseUI.buttonPaddingX * 2), "center")

        --love.graphics.rectangle()


        local buttonEntity = concord.entity(world)
        buttonEntity:give("button", canvasX+xPos+purchaseUI.buttonPaddingX,canvasY+yPos + purchaseUI.buttonPaddingY, purchaseUI.sizeX - (purchaseUI.buttonPaddingX * 2), purchaseUI.buttonHeight, purchaseMode, {i})
        buttonEntity:give("highlightOnMouse")
        buttonEntity:give("popupDescription")
    end

    love.graphics.setCanvas()
    love.graphics.setColor(cl.default)

    local canvas = concord.entity(world)
    :give("pos", canvasX, canvasY)
    :give("drawable","canvas", 3, {canvas})

    for i = 1, purchaseUI.amount do
        purchasableEntities[i].image = love.graphics.newImage("Images/"..i..".png")
    end

    local canvas = generatePopUp(1)

    popupDescriptionEntity = concord.entity(world)
    :give("pos", 1200, 1200)
    :give("drawable", "canvas", 2, {canvas})

    for i =1, tl.height do
        gameEntityMap[i] = {}
    end
end

function love.load(args)
    local myIp, myPort, plrIp, plrPort = unpack(args)

    --udp = socket.udp()
    --udp:settimeout(0)
    --udp:setpeername(plrIp, plrPort)

    --upd:send("string")

    if myIp then
        networking = require("networking")
        networking:init(myIp, myPort, plrIp, plrPort)
    end

    love.window.setMode(game.width, game.height)
    love.window.setTitle(game.title..tostring(myPort))
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

    if xPos ~= tl.width and xPos ~= 1 then
        if yPos <= tl.height and yPos > 0 then
            if gameEntityMap[yPos][xPos] == nil then
                readyToPlaceEntity:give("pos", ((xPos-1)*tl.size) + tl.xOffset, (yPos-1) * tl.size)
            else
                readyToPlaceEntity:give("pos", 1200, 1200)    
            end
        else
            readyToPlaceEntity:give("pos", 1200, 1200)
        end
    else
        readyToPlaceEntity:give("pos", 1200, 1200)
    end
end

function love.update(dt)
    world:emit("update", dt)

    if networking then
        if not networking.client then
            networking.client = networking.listeningSocket:accept()

            if networking.client then
                print("hi")
                print(networking.client)
                networking.client:settimeout(0)
            end
        else
            local data = networking:listen()
            if data then
                print(data, data[1])
                if string.sub(data, 1, 1) == "p" then
                    data = data:sub(2)
                    local purchaseInfo = {}
                    for value in string.gmatch(data, "([^:]+)") do
                        table.insert(purchaseInfo, value)
                    end
                    local purchasedIndex, posX, posY = unpack(purchaseInfo)

                    print(purchasedIndex, posX, posY, data)

                    placeEntity(tonumber(purchasedIndex), tonumber(posX), tonumber(posY))                    
                end
            end 
        end
    end

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


            print(tl.xOffset, tl.size, tl.width, game.width)
            if tl.xOffset > 0  then
                tl.xOffset = 0
            elseif tl.xOffset < game.width - (tl.size * tl.width) then
                print("resetl")
                tl.xOffset = game.width - (tl.size * tl.width)
            end

            if gameStates.purchaseMode then
                setPurchaseHighlightPosition(love.mouse.getPosition())
            end
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