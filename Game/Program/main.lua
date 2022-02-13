local concord = require("Concord") --ECS library
local entity = concord.entity
local component = concord.component
local system = concord.system
local world = concord.world
local components = concord.components
local networking

local layers = {{},{},{},{},{},{}} --layers for drawing
local gameEntityMap = {} -- 2d array for every item in the game
local myTeamEntities = {} -- array containing all items in local team
local enemyTeamEntities = {}
local inputs = {"right", "left"}

local world = concord.world() -- create
---graphical entities whose variables are initialised
local highlightEntity
local readyToPlaceEntity
local placeBox
local popupDescriptionEntity
local helpCanvas

--array of colors
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
    red = {1,0,0},
    green = {0,1,0},
    transBorder = {1,0,0,0.5},
    grey = {0.3,0.3,0.3}
}

--game data
local game = {
    height = 700, 
    width = 1000,
    title = "Clash",
    side = false, -- starts on the left
    pfInterval = 1,
    pfSpeed = 0,
    player = {},
    enemy = {},
    help = false
}

--gameStates
local gameStates = {
    purchaseMode = false,
    loadoutChosen = false,
    enemyLoadoutChosen = false,
    over = false
}

--information about the game map and tiles
local tl = {
    height = 10,
    width = 20,
    size = 60, 
    xOffset = 0,
    defaultImageSize = 120
}

---loadouts and 
local loadouts = {
    {
        name = "Miltiary robot",
        cash = 300,
        health = 1500,
        damageMultiplier = 2.5
    },
    {
        name = "Famous Athlete",
        cash = 1000,
        health = 2000,
        damageMultiplier = 2
    },
    {
        name = "thug",
        cash = 1500,
        health = 750,
        damageMultiplier = 2.2
    },
    {
        name = "Billionaire",
        cash = 2000,
        health = 1000,
        damageMultiplier = 0.9
    }
}

--stats of every purchasble item
local purchasableEntities = {
    {
        price = 10,
        name = "tower attacker",
        drawable = true,
        pathfind = "tower",
        attack = "melee",
        attackSpeed = 1.5,
        damage = -5,
        maxHealth = 100
    },
    {
        price = 11,
        name = "enemy attacker",
        drawable = true,
        pathfind = "enemies",
        attack = "melee",
        attackSpeed = 1.5,
        damage = -5,
        maxHealth = 100
    },
    {
        price = 12,
        name = "enemy shooter",
        drawable = true,
        pathfind = "enemies",
        attack = "ranged",
        attackSpeed = 1.5,
        attackRange = 4,
        damage = -3,
        maxHealth = 100
    },
    {
        price = 13,
        name = "tower attacker local regen",
        drawable = true,
        pathfind = "tower",
        attack = "melee",
        attackSpeed = 1.5,
        effect = "regen",
        effectValue = 20,
        effectRange = 4,
        effectInterval = 1, 
        damage = -5,
        maxHealth = 100
    },
    {
        price = 14,
        name = "stationary shooter",
        drawable = true,
        attack = "ranged",
        attackSpeed = 1.5,
        attackRange = 4,
        damage = -30,
        maxHealth = 100
    },
    {
        price = 15,
        name = "bank attacker",
        pathfind = "tower",
        drawable = true,
        effect = "generate money",
        effectValue = 20,
        effectInterval = 1,
        attack = "melee",
        attackSpeed = 1.5,
        damage = -5,
        maxHealth = 100
    },
    {
        price = 16,
        name = "damage potion",
        effect = "damage",
        effectValue = 100,
        effectRange = 4,
        duration = 1
    },
    {
        price = 17,
        name = "heal potion",
        effect = "heal",
        effectRange = 4,
        effectValue = 100,
        duration = 1
    },
    {
        price = 18,
        name = "regen potion",
        effect = "regen",
        effectValue = 20,
        effectRange = 4,
        effectInterval = 2,
        duration = 10,
    },
    {
        price = 19,
        name = "poison potion",
        effect = "poison",
        effectValue = 20,
        effectRange = 4,
        effectInterval = 2,
        duration = 10,
    },
    {
        price = 20,
        name = "wall",
        drawable = true,
        maxHealth = 100
    },
    {
        price = 5,
        name = "cheap wall",
        drawable = true,
        maxHealth = 20
    },
    {
        price = 22,
        name = "thorny wall",
        drawable = true,
        thorns = 10,
        maxHealth = 100
    },
    {
        price = 23,
        name = "bank",
        drawable = true,
        effect = "generate money",
        effectValue = 20,
        effectInterval = 1,
        maxHealth = 100
    },
    {
        price = 24,
        name = "hospital",
        drawable = true,
        effect = "tower hospital",
        effectValue = 20,
        effectInterval = 1,
        maxHealth = 100
    }
}

--ui properties for the purchasing of items
local purchaseUI = {
    framePaddingY = 10,
    sizeX = 60,
    sizeY = 70,
    buttonPaddingX = 5,
    buttonPaddingY = 45,
    buttonHeight = 20,
    popupHeight = 150,
    popupWidth = 150
}

--init fonts
local fonts = {
    large = love.graphics.newFont(25),
    small = love.graphics.newFont(22),
    verySmall = love.graphics.newFont(16)
}

--inits all components
concord.component("highlightOnMouse")

concord.component("pos", function(sf, x, y)
    sf.x = x
    sf.y = y
end)

concord.component("drawable", function(sf, type, layer, args)
    sf.type = type
    sf.layer = layer

    if type == "rectangle" then
        local width, height, color, fillType = unpack(args)
        sf.width = width
        sf.height = height
        sf.color = color
        sf.fillType = fillType
    elseif type == "circle" then
        local radius, color, fillType = unpack(args)    
        sf.radius = radius
        sf.color = color
        sf.fillType = fillType
    elseif type == "canvas" then
        local canvas = unpack(args)
        sf.canvas = canvas
    elseif type == "image" then
        local image, scale = unpack(args)
        sf.image = image
        sf.scale = scale
    elseif type == "filterImage" then
        local image, scale, filterColor = unpack(args)
        sf.image = image
        sf.scale = scale
        sf.filterColor = filterColor

    elseif type == "line" then
        local lineCoords, color = unpack(args)
        local xOne, yOne, xTwo, yTwo = unpack(lineCoords)
        sf.xOne = xOne
        sf.xTwo = xTwo
        sf.yOne = yOne
        sf.yTwo = yTwo
        sf.color = color
    end
end)

concord.component("garbage", function(sf, maxTime)
    sf.time = 0
    sf.maxTime = maxTime
end)

concord.component("button", function(sf, x, y, width, height, func, args)
    sf.x = x
    sf.y = y
    sf.width = width
    sf.height = height
    sf.func = func
    sf.args = args
end)

concord.component("gameEntity", function(sf, index, xLoc, yLoc, side)
    sf.index = index
    sf.xLoc = xLoc
    sf.yLoc = yLoc
    sf.team = side
end)

concord.component("pathfind", function(sf, pathfind)
    sf.target = pathfind
end)

concord.component("attack", function(sf, attack, damage, speed)
    sf.method = attack
    sf.damage = damage
    sf.speed = speed
    sf.toHit = 0
end)

concord.component("thorns", function(sf, damage)
    sf.damage = damage
end)

concord.component("attackRange", function(sf, attackRange)
    sf.range = attackRange
end)

concord.component("health", function(sf, health)
    sf.hp = health
    sf.maxHealth = health
end)

concord.component("effect", function(sf, effect, effectValue)
    sf.effect = effect
    sf.value = effectValue
end)

concord.component("effectRange", function(sf, effectRange)
    sf.range = effectRange
end)

concord.component("recurringEffect", function(sf, interval)
    sf.interval = interval
    sf.timeSince = interval
end)
concord.component("popupDescription")

concord.component("fader")

--inits systems
local gameSystem = concord.system({
    gameEntities = {"gameEntity"},
    pathfinders = {"pathfind"},
    attackers = {"attack"},
    effects = {"effect"}
})

local drawUI = concord.system({
    drawables = {"drawable"},
})

local buttonSystem = concord.system({
    buttons = {"button"},
    highlightables = {"button", "highlightOnMouse"},
    popups = {"popupDescription"}
})

local garbageSystem = concord.system({
    garbage = {"garbage"},
})

local fadeSystem = concord.system({
    faders = {"drawable", "fader", "garbage"}
})

function drawUI:init()
    --drawable added to drawUI
    self.drawables.onEntityAdded = function(pool, entity)
        layer = entity.drawable.layer
        
        if not layers[layer] then
            layers[layer] = {}
        end

        layers[layer][entity] = true
    end
    --drawable removed from drawUI
    self.drawables.onEntityRemoved = function(pool, entity)
        layers[entity.drawable.layer][entity] = nil
    end
end

function gameSystem:init()
    --game item added to gameentitmap
    self.gameEntities.onEntityAdded = function(pool, entity)
        local ge = entity.gameEntity
        gameEntityMap[ge.yLoc][ge.xLoc] = entity

        if ge.team == game.side then -- my team
            myTeamEntities[entity] = true
        else
            enemyTeamEntities[entity] = true
        end
    end
    --game items reomved from gameentitmap
    self.gameEntities.onEntityRemoved = function(pool, entity)
        local ge = entity.gameEntity
        gameEntityMap[ge.yLoc][ge.xLoc] = nil

        if ge.team == game.side then
            myTeamEntities[entity] = nil
        else
            enemyTeamEntities[entity] = nil
        end
    end
end

function gameSystem:update(dt)
    game.pfSpeed = game.pfSpeed + dt
    --pathfinds after every set interval
    if game.pfSpeed > game.pfInterval then
        game.pfSpeed = 0

        -- iterates through everything that can pathfind
        for _, bge in ipairs(self.pathfinders) do
            local pfMode = bge.pathfind.target
            
            local towerNode = {1, tl.height/2}
            if not bge.gameEntity.team then
                towerNode[1] = tl.width     
            end
            

            local posX, posY

            if pfMode == "tower" then
                posX, posY = unpack(
                    gameEntityMap:pathfindForTower({bge.gameEntity.xLoc, bge.gameEntity.yLoc}, towerNode)
                )
            elseif pfMode == "enemies" then
                posX, posY = unpack(
                    gameEntityMap:pathfindForEnemy({bge.gameEntity.xLoc, bge.gameEntity.yLoc}, towerNode, bge.gameEntity.team)
                )
            end

            if posX then
                gameEntityMap[bge.gameEntity.yLoc][bge.gameEntity.xLoc] = nil

                bge.gameEntity.xLoc = posX
                bge.gameEntity.yLoc = posY
                bge.pos.x = (posX-1) * tl.size
                bge.pos.y = (posY-1) * tl.size

                gameEntityMap[posY][posX] = bge
            end
        end
    end

    --iterates through everything that can attack
    for _, bge in ipairs(self.attackers) do
        if gameEntityMap[bge.gameEntity.yLoc][bge.gameEntity.xLoc] then 
            bge.attack.toHit = bge.attack.toHit + dt
            if bge.attack.toHit > bge.attack.speed then
                bge.attack.toHit = 0
                local enemyEntity
                local ranged

                local towerNode = {1, tl.height/2}
                if not bge.gameEntity.team then
                    towerNode[1] = tl.width     
                end

                if bge.attack.method == "melee" then
                    enemyEntity = gameEntityMap:getLocalEnemies({bge.gameEntity.xLoc, bge.gameEntity.yLoc}, towerNode)
                elseif bge.attack.method == "ranged" then
                    ranged = bge.attackRange.range
                    
                    enemyEntity = gameEntityMap:rangedGetLocalEnemies({bge.gameEntity.xLoc, bge.gameEntity.yLoc}, towerNode, bge.gameEntity.team, ranged)
                end

                if enemyEntity then
                    local damage = bge.attack.damage
                    local team = bge.gameEntity.team

                    if team == game.side then -- my team
                        damage = damage * game.player.damageMultiplier
                    else
                        damage = damage * game.enemy.damageMultiplier
                    end

                    damage = math.ceil(damage)

                    if enemyEntity == "tower" then
                        game:updateHealth(team==game.side, damage)
                        enemyEntity = towerNode
                    else
                        gameEntityMap:updateHealth(enemyEntity[1], enemyEntity[2], damage, bge.gameEntity.xLoc, bge.gameEntity.yLoc)
                        if false then
                            local lineCoords = {(bge.gameEntity.xLoc-0.5)*tl.size, (bge.gameEntity.yLoc-0.5)*tl.size, (enemyEntity[1]-0.5)*tl.size, (enemyEntity[2]-0.5)*tl.size}
                            local lineEntity = concord.entity(world)
                            :give("drawable", "line", 6, {lineCoords, cl.red})
                            :give("garbage", 0.1)
                        end
                    end
                    local lineCoords = {(bge.gameEntity.xLoc-0.5)*tl.size, (bge.gameEntity.yLoc-0.5)*tl.size, (enemyEntity[1]-0.5)*tl.size, (enemyEntity[2]-0.5)*tl.size}
                    local lineEntity = concord.entity(world)
                    :give("drawable", "line", 6, {lineCoords, cl.red})
                    :give("garbage", 0.1)
                end
            end
        end
    end

    --iterates through all "effects"
    for _, bge in ipairs(self.effects) do
        local effect = bge.effect.effect
        local value = bge.effect.value
        local team = bge.gameEntity.team
        local xloc = bge.gameEntity.xLoc
        local yloc = bge.gameEntity.yLoc
        local color 
        local range
        if bge.effectRange then
            range = bge.effectRange.range
        end

        local iterationGroup 
        local towerNode = {1, tl.height/2}

        if effect == "damage" or effect == "poison" then
            iterationGroup = gameEntityMap:getSortedListOfEnemies({xloc, yloc}, team)
            value = -value
            color = cl.red
            if team == game.side then
                towerNode[1] = tl.width
            end
        elseif effect == "heal" or effect == "regen" then
            iterationGroup = gameEntityMap:getSortedListOfEnemies({xloc, yloc}, not team)    
            color = cl.green
            if team ~= game.side then
                towerNode[1] = tl.width
            end
        end

        if not bge.recurringEffect then 
            if iterationGroup then      
                for _, v in ipairs(iterationGroup) do
                    if v[2].health then
                        if v[1] < range then
                            gameEntityMap:updateHealth(v[2].gameEntity.xLoc, v[2].gameEntity.yLoc, value)
                        else
                            break
                        end
                    end
                end

                if distanceAlgorithm(towerNode, {xloc, yloc}) < range then
                    if towerNode[1] == tl.width then
                        game:updateHealth(not game.side, value)
                    else
                        game:updateHealth( game.side, value)
                    end
                end

                placeEffectGraphic(xloc, yloc, range, color)
            end
            world:removeEntity(bge) -- remove the effect, add the graphic
        else
            bge.recurringEffect.timeSince = bge.recurringEffect.timeSince + dt

            if bge.recurringEffect.timeSince > bge.recurringEffect.interval then
                bge.recurringEffect.timeSince = 0

                if iterationGroup then
                    for _,v in ipairs(iterationGroup) do
                        if v[2].health then
                            if v[1] < range then
                                gameEntityMap:updateHealth(v[2].gameEntity.xLoc, v[2].gameEntity.yLoc, value)
                            else
                                break
                            end 
                        end
                    end
                    
                    if distanceAlgorithm(towerNode, {xloc, yloc}) < range then
                        if towerNode[1] == tl.width then
                            game:updateHealth(game.side, value)
                        else
                            game:updateHealth(not game.side, value)
                        end
                    end

                    placeEffectGraphic(xloc, yloc, range, color)
                elseif effect == "generate money" then
                    game:updateMoney(value)
                elseif effect == "tower hospital" then
                    game:updateHealth(team, value)
                end
            end
        end
    end
end

--garbage system responsible for deleting effects after set time
function garbageSystem:update(dt)
    --increments time property for all garbage
    for _, garbage in ipairs(self.garbage) do
        garbage.garbage.time = garbage.garbage.time + dt
    end
    --deletes or removes garbage that has existed for too long
    for _, garbage in ipairs(self.garbage) do
        if garbage.garbage.time > garbage.garbage.maxTime then
            world:removeEntity(garbage)
        end
    end
end

--system that reduces transparency of faders every update
function fadeSystem:update(dt)
    for _, bge in ipairs(self.faders) do
        local transparency = 1-(bge.garbage.time/bge.garbage.maxTime)
        bge.drawable.color = {bge.drawable.color[1], bge.drawable.color[2], bge.drawable.color[3], transparency}
    end
end

function buttonSystem:checkClick(x, y)
    --finds the button that was clicked, if exists
    for _, ent in ipairs(self.buttons) do
        local button = ent.button
        if x > button.x and x < button.x + button.width and y > button.y and y < button.y + button.height then
            highlightEntity:give("pos", 1200, 1200)
            button.func(button.args)
            break
        end
    end

    if gameStates.loadoutChosen and gameStates.enemyLoadoutChosen and gameStates.purchaseMode then
        --popupDescriptionEntity:give("pos", 1200, 1200)
        if y < (tl.size * tl.height) and not (yPos == tl.height/2 and (xPos == 1 or xPos == tl.width)) then
            local purchaseIndex = gameStates.purchaseMode
            posX, posY = getTilePosition(x,y)
            if game.player.cash >= purchasableEntities[purchaseIndex].price and gameEntityMap[posY][posX] == nil then
                if not (posY == tl.height/2 and (posX == 1 or posX == self.width)) then
                    if posX < tl.width/2 + 1 or not purchasableEntities[purchaseIndex].drawable then
                        if networking then 
                            networking:send("p"..tostring(purchaseIndex)..":"..tostring(posX)..":"..tostring(posY)) 
                        end

                        game.player.cash = game.player.cash - purchasableEntities[purchaseIndex].price

                        placeEntity(purchaseIndex, posX, posY, game.side)
                    
                        readyToPlaceEntity:give("pos", 1200, 1200)
                    end
                end
            end
        end
    end
end

--whenever mouse moves, checks to see if hovering over button to highlight
function buttonSystem:highlight(x,y)
    local highlighted = false

    for _, ent in ipairs(self.highlightables) do
        local button = ent.button
        if x > button.x and x < button.x + button.width and y > button.y and y < button.y + button.height then
            highlighted = ent
            highlightEntity:give("pos", button.x, button.y)
            highlightEntity.drawable.width = button.width
            highlightEntity.drawable.height = button.height
            break
        end
    end

    if not highlighted then --move highlight away
        highlightEntity:give("pos", 1200, 1200) 

        if gameStates.loadoutChosen then
            popupDescriptionEntity:give("pos", 1200, 1200)
        end
    else
        if self.popups:has(highlighted) then --and not gameStates.purchaseMode 
            local canvas = generatePopUp(unpack(highlighted.button.args))
            popupDescriptionEntity:give("pos", highlighted.button.x, highlighted.button.y - purchaseUI.popupHeight - purchaseUI.framePaddingY - purchaseUI.buttonPaddingY - 5)
            :give("drawable", "canvas", 2, {canvas})        
        end
    end

    if gameStates.loadoutChosen and gameStates.purchaseMode then
       setPurchaseHighlightPosition(x,y) 
    end
end

--draws game objects
function drawUI:draw() 
    for i,layer in ipairs(layers) do
        for entity,_ in pairs(layer) do
            if entity.drawable.type == "rectangle" then
                love.graphics.setColor(entity.drawable.color)
                love.graphics.rectangle(entity.drawable.fillType, entity.pos.x, entity.pos.y, entity.drawable.width, entity.drawable.height)
                love.graphics.setColor(cl.default)
            elseif entity.drawable.type == "circle" then
                love.graphics.setColor(entity.drawable.color)
                love.graphics.circle(entity.drawable.fillType, entity.pos.x + tl.xOffset, entity.pos.y, entity.drawable.radius)
                love.graphics.setColor(cl.default)
            elseif entity.drawable.type == "canvas" then
                love.graphics.draw(entity.drawable.canvas, entity.pos.x, entity.pos.y)
            elseif entity.drawable.type == "image" then
                love.graphics.draw(entity.drawable.image, entity.pos.x + tl.xOffset, entity.pos.y, 0,entity.drawable.scale, entity.drawable.scale)
            elseif entity.drawable.type == "filterImage" then
                love.graphics.setColor(entity.drawable.filterColor)
                love.graphics.draw(entity.drawable.image, entity.pos.x + tl.xOffset, entity.pos.y, 0,entity.drawable.scale, entity.drawable.scale)
                love.graphics.setColor(cl.default)
            elseif entity.drawable.type == "line" then
                love.graphics.setColor(entity.drawable.color)
                love.graphics.setLineWidth(1)
                love.graphics.line(entity.drawable.xOne + tl.xOffset, entity.drawable.yOne, entity.drawable.xTwo + tl.xOffset, entity.drawable.yTwo)
                love.graphics.setColor(cl.default)          
            end
        end
    end
end

--draws background grid
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
            if y == self.height/2 and (x == 1 or x == self.width) then
                love.graphics.setColor(cl.red)
            end

            love.graphics.rectangle("fill", posX + tl.xOffset, posY, self.size, self.size)
            love.graphics.setColor(cl.default)
        end
    end

    love.graphics.setLineWidth(10)
    love.graphics.setColor(cl.grey)
    love.graphics.line(tl.width/2 * tl.size + tl.xOffset, 0, tl.width/2 * tl.size + tl.xOffset, tl.height * tl.size)
    love.graphics.setColor(cl.default)
end

--finds distance between two points
function distanceAlgorithm(startNode, endNode)
    return math.sqrt((endNode[2] - startNode[2])^2 + (startNode[1] - endNode[1])^2)
end

--bubble sort algorithm
function bubbleSortEnemies(array)
    local swaps = true

    repeat 
        swaps = false

        for index, value in ipairs(array) do
            if array[index + 1] then
                if value[1] > array[index + 1][1] then
                    local temp = value
                    array[index] = array[index + 1]
                    array[index + 1] = temp

                    swaps = true
                end
            end
        end
        
    until not swaps

    return array
end

--returns list of enemies sorted by distance
function gameEntityMap:getSortedListOfEnemies(startNode, team)
    local tempArray = {}
    
    local pathfindGroup

    if team ~= game.side then -- enemy team
        pathfindGroup = myTeamEntities
    else
        pathfindGroup = enemyTeamEntities
    end


    for key, value in pairs(pathfindGroup) do
        local distance = distanceAlgorithm(startNode, {key.gameEntity.xLoc, key.gameEntity.yLoc})
        if distance == 1 then
            return {{distance, key}}
        end
        table.insert(tempArray, {distance, key})
    end

    return bubbleSortEnemies(tempArray)
end

--finds best path to given enemy
function gameEntityMap:pathfindForEnemy(startNode, endNode, team)

    local sortedListOfEnemies = self:getSortedListOfEnemies(startNode, team)


    for _,enemy in ipairs(sortedListOfEnemies) do
        local posX, posY, reached = unpack(gameEntityMap:pathfind(startNode, {enemy[2].gameEntity.xLoc, enemy[2].gameEntity.yLoc}))
        if posX then 
            return {posX, posY}
        elseif reached then
            return startNode
        end
    end
    -- no possible way to enemies or no enemies
    local posX, posY = unpack(gameEntityMap:pathfindForTower(startNode, endNode))
    return {posX, posY}
end

--A* algorithm
function gameEntityMap:pathfind(startNode, endNode) -- already |found path| no path
    local distance = distanceAlgorithm(startNode, endNode)
    if distance == 1 then
        return {nil, nil, true}
    end

    local temp = startNode
    local startNode = endNode
    local endNode = temp

    local tempMap = {}

    for yPos,row in ipairs(gameEntityMap) do
        tempMap[yPos] = {}

        for xPos, value in pairs(row) do
            tempMap[yPos][xPos] = "a"
        end
    end
    
    tempMap[endNode[2]][endNode[1]] = nil

    local bestNode = {startNode[1], startNode[2],distance}

    repeat 
        tempMap[bestNode[2]][bestNode[1]] = "closed"

        for a = 1,4 do
            local i, j

            i = -1+ math.floor(a / 2)
            j = 1 - math.fmod(a,3)

            if i+bestNode[2] >= 1 and i+bestNode[2] <= tl.height and j+bestNode[1] >= 1 and j+bestNode[1] <= tl.width then
                if not tempMap[i+bestNode[2]][j+bestNode[1]] then
                    tempMap[i+bestNode[2]][j+bestNode[1]] = {}
                    tempNode = tempMap[i+bestNode[2]][j+bestNode[1]]
                    tempNode.gCost = distanceAlgorithm(startNode, {j+bestNode[1],i+bestNode[2]})
                    tempNode.hCost = distanceAlgorithm(endNode,   {j+bestNode[1],i+bestNode[2]})
                    tempNode.fCost = tempNode.hCost + tempNode.gCost
                end
                if tempMap[i+bestNode[2]][j+bestNode[1]] then
                    if tempMap[i+bestNode[2]][j+bestNode[1]].fCost then
                        if tempMap[i+bestNode[2]][j+bestNode[1]].hCost == 0 then
                            return {bestNode[1], bestNode[2], true}
                        end
                    end
                end
            end
        end

        bestNode = nil

        for i = 1, tl.height do -- finds lowest f cost
            for j = 1, tl.width do
                if tempMap[i][j] and tempMap[i][j] ~= "closed" then
                    if tempMap[i][j].fCost then
                        if not bestNode then
                            bestNode = {j,i, tempMap[i][j].fCost}
                        elseif bestNode[3] > tempMap[i][j].fCost then
                            bestNode = {j, i, tempMap[i][j].fCost}
                        end
                    end
                end
            end
        end



    until not bestNode

    return {nil, nil, false}

end

--pathfinds to enemy tower
function gameEntityMap:pathfindForTower(startNode, endNode)   
    local posX, posY, possible = unpack(gameEntityMap:pathfind(startNode, endNode))

    if possible then
        return {posX, posY}
    end

    return gameEntityMap:moveToTower(startNode, endNode)
end

--if no path, then just moves to tower
function gameEntityMap:moveToTower(startNode, endNode)
    local distance = distanceAlgorithm(startNode, endNode)

    for a = 1,4 do -- moves as close to the wall as possible
        local i, j

        i = -1+ math.floor(a / 2)
        j = 1 - math.fmod(a,3)

        if i+startNode[2] >= 1 and i+startNode[2] <= tl.height and j+startNode[1] >= 1 and j+startNode[1] <= tl.width then
            if not self[i+startNode[2]][j+startNode[1]] then
                local newDist = distanceAlgorithm({i+startNode[2],j+startNode[1]}, {endNode[2], endNode[1]})
                if newDist < distance then
                    return {j+startNode[1], i+startNode[2]}
                end
            end
        end
    end

    return {nil, nil}
end

--get list of enemies in vicinity
function gameEntityMap:getLocalEnemies(startNode, towerNode)
    if distanceAlgorithm(startNode, towerNode) == 1 then
        return "tower"
    end

    for a = 1,4 do
        local i, j

        i = -1+ math.floor(a / 2)
        j = 1 - math.fmod(a,3)

        if i+startNode[2] >= 1 and i+startNode[2] <= tl.height and j+startNode[1] >= 1 and j+startNode[1] <= tl.width then
            if self[i+startNode[2]][j+startNode[1]] then
                if self[i+startNode[2]][j+startNode[1]].gameEntity.team == not self[startNode[2]][startNode[1]].gameEntity.team then
                    return {j+startNode[1], i+startNode[2]}
                end
            end
        end
    end
end

--get list of enemies within vicinity with given range
function gameEntityMap:rangedGetLocalEnemies(startNode, towerNode, team, range)
    local sortedListOfEnemies = self:getSortedListOfEnemies(startNode, team)

    local endEnemy = sortedListOfEnemies[1]
    if endEnemy then
        local endNode = {endEnemy[2].gameEntity.xLoc, endEnemy[2].gameEntity.yLoc}
        if endEnemy[1] <= range then
            return endNode
        end
    end

    if distanceAlgorithm(startNode, towerNode) ==  1 then
        return "tower"
    end
end

--updates health of entity when attacked
function gameEntityMap:updateHealth(x,y,damage,attackerX, attackerY)
    if self[y][x].health then
        self[y][x].health.hp = self[y][x].health.hp + damage
        
        if self[y][x].health.hp < 0 then
            world:removeEntity(self[y][x])
            self[y][x] = nil
        elseif self[y][x].health.hp > self[y][x].health.maxHealth then
            self[y][x].health.hp = self[y][x].health.maxHealth

            if attackerX then
                local thorns = self[y][x].thorns 
                if thorns then
                    gameEntityMap:updateHealth(attackerX, attackerY, -thorns.damage)
                end
            end
        end
    end
end

--puts entity in given position and gives all relevant properties
function placeEntity(index, posX, posY, side)
    print("Placing entity at ", posX, posY, index)
    local newEntity = concord.entity(world)
    :give("gameEntity", index, posX, posY, side)
    :give("pos", (posX-1) * tl.size, (posY-1) * tl.size)

    local purchasedItem = purchasableEntities[index]

    if purchasedItem.drawable then
        if side == game.side then
            newEntity:give("drawable", "image", 5,{purchasableEntities[index].image, tl.size/tl.defaultImageSize})
        else
            newEntity:give("drawable", "filterImage", 5, {purchasableEntities[index].image, tl.size/tl.defaultImageSize, cl.red})
        end
    end

    if purchasedItem.pathfind then
        newEntity:give("pathfind",purchasedItem.pathfind)
    end

    if purchasedItem.attack then
        newEntity:give("attack", purchasedItem.attack, purchasedItem.damage, game.pfInterval * (1/purchasedItem.attackSpeed))
    end
    
    if purchasedItem.attackRange then
        newEntity:give("attackRange", purchasedItem.attackRange)
    end

    if purchasedItem.maxHealth then
        newEntity:give("health", purchasedItem.maxHealth)
    end

    if purchasedItem.effect then
        newEntity:give("effect", purchasedItem.effect, purchasedItem.effectValue)
    end

    if purchasedItem.effectRange then
        newEntity:give("effectRange", purchasedItem.effectRange)
    end

    if purchasedItem.effectInterval then
        newEntity:give("recurringEffect", purchasedItem.effectInterval)
    end

    if purchasedItem.duration then
        newEntity:give("garbage", purchasedItem.duration)
    end

    if purchasedItem.thorns then
        newEntity:give("thorns", purchasedItem.thorns)
    end
end

--place effects
function placeEffectGraphic(xloc, yloc, range, color)
    local newEntity = concord.entity(world)
    :give("drawable", "circle",6,  {range * tl.size/2.3, color, "fill"})
    :give("pos", (xloc - 0.5) * tl.size, (yloc - 0.5) * tl.size)
    :give("fader")
    :give("garbage", 1)

end

--updates tower health
function game:updateHealth(team, amount)
    if team then
        self.enemy.health = self.enemy.health + amount

        if self.enemy.health <= 0 then
            game:gameOver("You have won!")
        end
    else
        self.player.health = self.player.health + amount
        
        if self.player.health <= 0 then
            game:gameOver("Your friend has won!")
        end
    end
end

--updates player cash
function game:updateMoney(amount)
    self.player.cash = self.player.cash + amount
end

--when game is over
function game:gameOver(winner)
    world:clear()
    world:addEntity(highlightEntity)

    local button = concord.entity(world)

    local buttonWidth = 100
    local buttonHeight = 50
    local buttonX = game.width/2 - buttonWidth/2
    local buttonY = game.height/5*4 - buttonHeight/5*4 

    local buttonEntity = concord.entity(world)
    buttonEntity:give("button", buttonX, buttonY, buttonWidth, buttonHeight, game.exitGame)
    buttonEntity:give("highlightOnMouse")


    local canvasDraw = love.graphics.newCanvas(buttonWidth, buttonHeight)    
    love.graphics.setCanvas(canvasDraw)
    love.graphics.setColor(cl.grey)
    love.graphics.rectangle("fill", 0,0, canvasDraw:getWidth(), canvasDraw:getHeight())
    love.graphics.setColor(cl.red)
    love.graphics.printf("Exit", 0, canvasDraw:getHeight()/2 - 15, canvasDraw:getWidth(), "center")
    love.graphics.setCanvas()

    local canvas = concord.entity(world)
    :give("pos", buttonX, buttonY)
    :give("drawable", "canvas", 1, {canvasDraw})
    

    gameStates.loadoutChosen = false

    if winner then
        gameStates.over = winner
    end
end

--toggles help upon click
function game:toggleHelp()
    if self.help then
        helpCanvas:give("pos", 1200,1200)        
    else 
        print(helpCanvas.drawable.canvas)
        helpCanvas:give("pos", game.width/2 - helpCanvas.drawable.canvas:getWidth()/2, game.height/2 - helpCanvas.drawable.canvas:getHeight()/2)
    end

    self.help = not self.help
end

--exits game
function game:exitGame()
    print("game is done")

    love.event.quit(0)
end

--adds systems to worlds
world:addSystems(drawUI)
world:addSystems(buttonSystem)
world:addSystems(garbageSystem)

--adds properties to entities
highlightEntity = concord.entity(world)
:give("pos", 1200,1200)
:give("drawable", "rectangle", 4,{20,20, cl.buttonHighlight, "fill"})

readyToPlaceEntity = concord.entity(world)
:give("pos", 1200, 1200)
:give("drawable","rectangle", 2,{tl.size, tl.size, cl.buttonHighlight, "fill"})

placeBox = concord.entity(world)
:give("pos", 1200, 1200)
:give("drawable", "rectangle", 2,{game.width, tl.size *tl.height, cl.transBorder, "line"})

--toggles red outline if purchasemode
function purchaseMode(args)
    local enabled = unpack(args)

    gameStates.purchaseMode = enabled

    if enabled then
        placeBox:give("pos", 0, 0)
    else
        placeBox:give("pos", 1200, 1200)
    end
end

--highlighting button add popup
function generatePopUp(index)

    local canvas = love.graphics.newCanvas(purchaseUI.popupWidth, purchaseUI.popupHeight)
    
    love.graphics.setCanvas(canvas)
    love.graphics.setColor(cl.loadoutInfo)
    love.graphics.rectangle("fill",0,0,canvas:getWidth(), canvas:getHeight())
    love.graphics.setFont(fonts.verySmall)

    local y = 0

    for ind, value in pairs(purchasableEntities[index]) do
        love.graphics.setColor(cl.default)
        if ind ~= "image" and ind ~= "drawable" then
            love.graphics.print(ind.. ": ".. value, 0, y)
            y = y + 15
        end
    end


    love.graphics.setCanvas()
    love.graphics.setColor(cl.default)
    
    return canvas
end

--updates proeprties to reflect loadout chosen
function setLoadoutStats(myTeam, loadoutNumber)
    local target
    if myTeam then
        target = game.player
    else
        target = game.enemy
    end

    local loadout = loadouts[tonumber(loadoutNumber)]

    for key, value in pairs(loadout) do
        target[key] = value
    end 
end

--runs when loadout is chosen
function chooseAloadout(args)

    local loadoutNumber = unpack(args)


    networking:send("l"..tostring(loadoutNumber))

    world:clear()

    world:addEntity(highlightEntity)
    world:addEntity(readyToPlaceEntity)
    world:addEntity(placeBox)
    world:addSystems(gameSystem)
    world:addSystems(fadeSystem)

    gameStates.loadoutChosen = loadoutNumber
    
    setLoadoutStats(true, loadoutNumber)

    local canvas = love.graphics.newCanvas(game.width, game.height - (tl.size * tl.height))
    local canvasX = 0
    local canvasY = game.height - canvas:getHeight()

    love.graphics.setCanvas(canvas)
    love.graphics.setColor(cl.purchaseBar)
    love.graphics.rectangle("fill",0,0, canvas:getWidth(), canvas:getHeight())
    
    local stripSize = (canvas:getWidth() - (#purchasableEntities * purchaseUI.sizeX)) / (#purchasableEntities + 1)
    for i = 1,#purchasableEntities do
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

    for i = 1, #purchasableEntities do
        purchasableEntities[i].image = love.graphics.newImage("Images/"..i..".png")
    end

    local canvas = generatePopUp(1)

    popupDescriptionEntity = concord.entity(world)
    :give("pos", 1200, 1200)
    :give("drawable", "canvas", 6, {canvas})

    for i =1, tl.height do
        gameEntityMap[i] = {}
    end

    ---creates help canvas
    local width = 500
    local height = 500
    local x = game.width/2 - width/2
    local y = game.height/2 - height/2
    local helpText = "Press H to close. Press the left and right arrows to pan over the map. Click buy on an item below and then click on a place in the map to place the item. You can only place characters to the left of the line. Characters will defend your tower or attack the enemy tower. Your goal is to destroy the enemy tower before the enemy destroys yours! Good luck!"

    local canvas = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(canvas)
    love.graphics.setColor(cl.loadoutButtonColor)
    love.graphics.rectangle("fill",0,0, width, height)
    love.graphics.setColor(cl.loadoutText)
    love.graphics.printf(helpText,0,0, width)
    love.graphics.setColor(cl.default)
    love.graphics.setCanvas()

    helpCanvas = concord.entity(world)
    :give("pos", 1200, 0)
    :give("drawable", "canvas", 6, {canvas})
end

function love.load(args)
    local myIp, myPort, plrIp, plrPort = unpack(args)

    if myIp then
        networking = require("networking")
        networking:init(myIp, myPort, plrIp, plrPort)
    end

    love.window.setMode(game.width, game.height)
    love.window.setTitle(game.title..tostring(myPort))
    love.graphics.setBackgroundColor(cl.backgroundColor)
    love.graphics.setLineWidth(10)
    local largeFont = fonts.large
    local smallFont = fonts.verySmall

    local loadoutUIWidth = 220
    local loadoutUIpaddingY = 50

    local stripSize = (game.width - (#loadouts * loadoutUIWidth)) / (#loadouts + 1) 
    
    --generates loadout menu
    for i = 1,#loadouts do
        local canvas = love.graphics.newCanvas(loadoutUIWidth, game.height - loadoutUIpaddingY * 2)
        local canvasX = (i * stripSize) + ((i - 1) * loadoutUIWidth)
        local canvasY = loadoutUIpaddingY

        local subCanvasOffset = 10
        local subCanvasWidth = canvas:getWidth() - (subCanvasOffset * 2)

        love.graphics.setCanvas(canvas)
        love.graphics.setColor(cl.loadoutBackgroundColor)

        love.graphics.rectangle("fill",0,0, canvas:getWidth(), canvas:getHeight()) -- total  

        love.graphics.setColor(cl.loadoutName) -- loadout name
        love.graphics.rectangle("fill",subCanvasOffset,20, subCanvasWidth, 100)

        love.graphics.setColor(cl.loadoutText)
        love.graphics.printf(loadouts[i].name, largeFont, subCanvasOffset, 50,subCanvasWidth, "center")
        
        love.graphics.setColor(cl.loadoutInfo) -- stats
        love.graphics.rectangle("fill", subCanvasOffset, 140, subCanvasWidth, 310) -- 120, 350

        love.graphics.setColor(cl.loadoutText)
        
        local height = 170

        for key, value in pairs(loadouts[i]) do
            love.graphics.printf(key .. ": " .. value, smallFont, subCanvasOffset, height, subCanvasWidth, "center")
            height = height + 30
        end

        local buttonCanvas = love.graphics.newCanvas(subCanvasWidth, 100)
        local buttonCanvasX = subCanvasOffset
        local buttonCanvasY = canvas:getHeight() - 130

        love.graphics.setCanvas(buttonCanvas)

        love.graphics.setColor(cl.loadoutButtonColor) -- button
        love.graphics.rectangle("fill", 0, 0, buttonCanvas:getWidth(), buttonCanvas:getHeight()) -- select box

        love.graphics.setColor(cl.loadoutText)
        love.graphics.printf("Select", largeFont,0, 30, buttonCanvas:getWidth(),"center") -- select button
        
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

--gets position of tile based on x,y
function getTilePosition(x,y)
    xPos = x - tl.xOffset
    yPos = y

    xPos = math.ceil(xPos/tl.size)
    yPos = math.ceil(yPos/tl.size)

    return xPos, yPos
end

--sets position of highlight button for placing down entities
function setPurchaseHighlightPosition(x,y)
    xPos, yPos = getTilePosition(x,y)

    if not (yPos == tl.height/2 and (xPos == 1 or xPos == tl.width)) then
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

--runs every frame
function love.update(dt)
    world:emit("update", dt) --every listener listening for update runs

    if networking then --handling received enemy actions
        if not networking.client then --try to initialise networking client
            networking.client = networking.listeningSocket:accept()

            if networking.client then
                networking.client:settimeout(0)
            end
        else
            local data = networking:listen() 
            if data then
                if string.sub(data, 1, 1) == "p" then
                    data = data:sub(2)
                    local purchaseInfo = {}
                    for value in string.gmatch(data, "([^:]+)") do
                        table.insert(purchaseInfo, value)
                    end
                    local purchasedIndex, posX, posY = unpack(purchaseInfo)
                    placeEntity(tonumber(purchasedIndex), tl.width - tonumber(posX) + 1, tonumber(posY), not game.side)                    
                elseif string.sub(data,1,1) == "l" then
                    loadoutNumber = data:sub(2)
                    setLoadoutStats(false, loadoutNumber) 
                    gameStates.enemyLoadoutChosen = true
                end
            end 
        end
    end

    --pans camera left and right to input
    if gameStates.loadoutChosen and gameStates.enemyLoadoutChosen then 
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
            elseif tl.xOffset < game.width - (tl.size * tl.width) then
                tl.xOffset = game.width - (tl.size * tl.width)
            end

            if gameStates.purchaseMode then
                setPurchaseHighlightPosition(love.mouse.getPosition())
            end
        end
    end
end

function love.draw()
    if gameStates.loadoutChosen and gameStates.enemyLoadoutChosen then -- draws background tilemap
        tl:draw()
    elseif gameStates.over then --if game over draws something else
        love.graphics.setColor(cl.black)
        love.graphics.rectangle("fill", 0,0,game.width, game.height)
        love.graphics.setColor(cl.red)
        love.graphics.printf(gameStates.over,0, game.height/2 - 300, game.width, "center")
    end

    world:emit("draw") --every listener with draw runs


    if gameStates.loadoutChosen and gameStates.enemyLoadoutChosen then -- draws textual ui info

        love.graphics.setFont(fonts.small)
        love.graphics.print("Cash: ".. game.player.cash, 10,10)
        love.graphics.print("Health: ".. game.player.health, 10, 40)
        love.graphics.print("Enemy Health: ".. game.enemy.health, 10, 70)
        love.graphics.print("Press H for help", 10, 100)
    end
end

--action for mouseclick
function love.mousereleased(x,y, button) 
    world:emit("checkClick", x, y)
end

--action for mousemove
function love.mousemoved(x,y)
    world:emit("highlight",x,y)
end

--action for keypress
function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        if gameStates.loadoutChosen then 
            purchaseMode({false}) 
            readyToPlaceEntity:give("pos", 1200, 1200)
        end 
    elseif key == "H" or key == "h" then
        if gameStates.loadoutChosen then
            game:toggleHelp()
        end
    end
end