Map = Class{}

TILE_EMPTY = 4
TILE_BRICK = 1

function Map:init()
    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 30
    self.mapHeight = 28
    self.tiles = {}

    self.tileSprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)

    -- fill the map with empty tiles
    for y = 1, self.mapHeight / 2 do
        for x = 1, self.mapWidth do 
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    --starting halfway down the map, populate it with bricks
    for y = self.mapHeight / 2, self.mapHeight do
        for x = 1, self.mapWidth do
            self:setTile(x, y, TILE_BRICK)
        end
    end
end

function Map:setTile(x, y, tile)
    self.tiles[(y - 1) * self.mapWidth + x] = tile
end

function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

function Map:update(dt)

end

function Map:render()
    for y = 1, self.mapHeight do 
        for x = 1, self.mapWidth do
            love.graphics.draw(self.spritesheet, self.tileSprites[self:getTile(x, y)],
                (x-1) * self.tileWidth, (y - 1) * self.tileWidth)
        end
    end
end 