-- Dependencies
local Map = require(script.Parent.Map)
local Set = require(script.Parent.Set)

-- Local Functions
local function floorVector(v0) return Vector3.new(math.floor(v0.X), math.floor(v0.Y), math.floor(v0.Z)) end

local SpatialSystem = {}
SpatialSystem.__index = SpatialSystem

function SpatialSystem.new(cellSize)
    local self = {}

    -- Properties
    self.cellSize = cellSize

    -- Data
    self.objectPositions = Map.new()
    self.cellObjects = Map.new()

    return setmetatable(self, SpatialSystem)
end

function SpatialSystem:ToWorldSpace(cellPosition, anchorPoint)
    anchorPoint = anchorPoint or Vector3.new(0.5, 0.5, 0.5)
    return (cellPosition + anchorPoint) * self.CellSize
end

function SpatialSystem:ToCellSpace(worldPosition)
    return floorVector(worldPosition / self.CellSize)
end

function SpatialSystem:_allocateCell(cellPosition)
    if self.cellObjects:Contains(cellPosition) then return end
    self.cellObjects:Set(cellPosition, Set.new())
end

function SpatialSystem:_clean(object)
    -- Get Cell
    local cellPosition = self.objectPositions:Get(object)
    if not cellPosition then return end

    -- Remove Object
    self.cellObjects:Get(cellPosition):Remove(object)

    -- Clean
    if self.cellObjects:Get(cellPosition):Size() == 0 then
        self.cellObjects:Remove(cellPosition)
    end
end

function SpatialSystem:SetObjectPosition(object, worldPosition)
    -- Clean
    self:_clean(object)

    -- Allocate
    local cellPosition = self:ToCellSpace(worldPosition)
    self:_allocateCell(cellPosition)

    -- Set
    self.objectPositions:Set(object, cellPosition)
    self.cellObjects:Get(cellPosition):Add(object)
end

function SpatialSystem:RemoveObject(object)
    -- Clean
    self:_clean(object)

    -- Remove
    self.objectPositions:Remove(object)
end

function SpatialSystem:GetObjectsInCell(cellPosition)
    return self.cellObjects:Get(cellPosition):GetValues() or {}
end

function SpatialSystem:GetObjectsInRadius(worldPosition, radius)
    -- Get Cell
    local cellPosition = self:ToCellSpace(worldPosition)
    local cellRadius = math.ceil(radius / self.CellSize)

    -- Get Objects
    local objects = {}
    for x = -cellRadius, cellRadius do
        for y = -cellRadius, cellRadius do
            for z = -cellRadius, cellRadius do
                for _, object in ipairs(self:GetObjectsInCell(cellPosition + Vector3.new(x, y, z))) do
                    if (worldPosition - self.objectPositions:Get(object)).Magnitude <= radius then
                        table.insert(objects, object)
                    end
                end
            end
        end
    end

    return objects
end

return SpatialSystem