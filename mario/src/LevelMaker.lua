--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)
    local hole = 0
    local key_done = false
    local lock_done = false
    local key_chance = math.floor(width * 0.3)
    local lock_chance = math.floor(width * 0.7)
    local key_limit = math.floor(width * 0.3)
    local lock_limit = math.floor(width * 0.7)
    local pillar = true
    local block = false
    local nothing = true

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if ((math.random(7) == 1) and hole < 2) then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
            hole = hole + 1
            pillar = false
            block = false
        else
            nothing = true
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4 

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if (math.random(8) == 1) and not (pillar == true and block == true) then
                nothing = false
                blockHeight = 1.5
                pillar = true
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block. second condition is to spawn a lock block
            -- in case we are reaching the end yet there is still no lock block
            if math.random(10) == 1 or (x >= lock_limit and lock_done == false) then
                nothing = false
                -- chance to spawn a lock block
                if pillar == true then
                    block = true
                end
                
                if (lock_done == false) and (math.random(lock_chance) == 1 or x >= lock_limit) then
                    --if there was a pillar before this block, we need to set the block flag
                    --this will let us know there was a block directly after a pillar,
                    --so that we can avoid putting another pillar directly after this block
                    --and creating a situation where we cannot hit this block
            
                    
                    table.insert(objects,

                        -- locks
                        GameObject {
                            texture = 'keys/locks',
                            x = (x - 1) * TILE_SIZE,
                            y = (blockHeight - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,

                            -- make it a random variant
                            frame = math.random(5, 8),
                            collidable = true,
                            hit = false,
                            solid = true,
                            consumable = false,

                            -- collision function takes itself
                            onCollide = function(obj, player)
                                if obj.consumable == false and player.y > obj.y then
                                    gSounds['empty-block']:play()
                                end
                                
                            end,

                            onConsume = function(obj, player) end
                            

                        }
                    )
                    lock_done = true
                    lock_chance = -1
                else
                
                    table.insert(objects,

                        -- jump block
                        GameObject {
                            texture = 'jump-blocks',
                            x = (x - 1) * TILE_SIZE,
                            y = (blockHeight - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,

                            -- make it a random variant
                            frame = math.random(#JUMP_BLOCKS),
                            collidable = true,
                            hit = false,
                            solid = true,

                            -- collision function takes itself
                            onCollide = function(obj, player)

                                -- spawn a gem if we haven't already hit the block
                                if not obj.hit then

                                    -- chance to spawn gem, not guaranteed
                                    if math.random(3) == 1 then

                                        -- maintain reference so we can set it to nil
                                        local gem = GameObject {
                                            texture = 'gems',
                                            x = (x - 1) * TILE_SIZE,
                                            y = (blockHeight - 1) * TILE_SIZE - 4,
                                            width = 16,
                                            height = 16,
                                            frame = math.random(#GEMS),
                                            collidable = true,
                                            consumable = true,
                                            solid = false,

                                            -- gem has its own function to add to the player's score
                                            onConsume = function(object, player)
                                                gSounds['pickup']:play()
                                                player.score = player.score + 100
                                            end
                                        }
                                        
                                        -- make the gem move up from the block and play a sound
                                        Timer.tween(0.1, {
                                            [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                        })
                                        gSounds['powerup-reveal']:play()

                                        table.insert(objects, gem)
                                    end

                                    obj.hit = true
                                end

                                if player.y > obj.y then
                                    gSounds['empty-block']:play()
                                end
                            end
                        }
                    )
                end
                    
                
            end
            hole = 0
            if nothing == true then
                pillar = false
                block = false
            end
        end

        -- chance to generate key
        if (key_done == false and (math.random(key_chance) == 1 or x >= key_limit)) then
            local key = GameObject {
                texture = 'keys/locks',
                x = (x - 1) * TILE_SIZE,
                y = 2 * TILE_SIZE,
                width = 16,
                height = 16,
                frame = math.random(1, 4),
                collidable = true,
                consumable = true,
                solid = false,

                -- consuming key unlocks block
                onConsume = function(player, object)
                    gSounds['pickup']:play()
                    for k, object in pairs(objects) do
                        if (object.texture == 'keys/locks') and (object.frame >= 5) then
                            object.consumable = true
                            object.onConsume = function(obj, player)
                                gSounds['powerup-reveal']:play()
                                local x_value = 0
                                for i = width, 1, -1 do
                                    if tiles[7][i].id == TILE_ID_GROUND then
                                        local marker = true
                                        for k, object in pairs(objects) do
                                            
                                            if ((object.x / TILE_SIZE) + 1 == i) then
                                                marker = false
                                            end
                                            
                                        end
                                        if marker == true then
                                            x_value = i
                                            break
                                        end

                                    end
                                end
                                local y_value = 0
                                if tiles[5][x_value].id == TILE_ID_GROUND then
                                    y_value = 1 * TILE_SIZE
                                else
                                    y_value = 3 * TILE_SIZE
                                end

                                
                                flagpole = GameObject {
                                        texture = 'flags/flagpoles',
                                        x = (x_value - 1) * TILE_SIZE,
                                        y = y_value + TILE_SIZE,
                                        width = 16,
                                        height = 48,
                                        
                                        -- select random frame from bush_ids whitelist, then random row for variance
                                        frame = math.random(6),
                                        collidable = true,
                                        consumable = true,
                                        
                                        onCollide = function() end,
                                        onConsume = function(object, player)
                                            gSounds['pickup']:play()
                                            gStateMachine:change('play', {levelnum = gStateMachine.current.levelnum + 1, 
                                                                            playerScore = player.score})
                                        end
                                    }
                                flag = Entity {
                                    x = (x_value - 2) * TILE_SIZE + 4,
                                    y = y_value + TILE_SIZE,
                                    width = 16,
                                    height = 16,
                                    texture = 'flags/flagpoles',
                                    stateMachine = StateMachine {
                                        ['flying'] = function() return flagFlyingState(flag) end
                                    },
                                    map = function () end,
                                    level = function () end                        
                                }
                                Timer.tween(0.1, {
                                    [flagpole] = {y = y_value},
                                    [flag] = {y = y_value}
                                })
                        
                                flag:changeState('flying')
                                table.insert(objects, flagpole)
                                table.insert(objects, flag)
                                    
                            
                            end
                            break
                        end
                    end
                end
            }

            table.insert(objects, key)
            key_done = true
        end

        -- decrease key_chance and lock_chance so we increase their chances of spawning 
        if key_chance > 1 then
            key_chance = key_chance - 1
        end

        if lock_chance > 1 then 
            lock_chance = lock_chance - 1
        end

    end

    local map = TileMap(width, height)
    map.tiles = tiles

    
    return GameLevel(entities, objects, map)
end