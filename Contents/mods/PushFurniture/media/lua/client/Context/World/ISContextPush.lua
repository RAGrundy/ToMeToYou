ISWorldMenuElements = ISWorldMenuElements or {}

function ISWorldMenuElements.ContextPush()
    local self = ISMenuElement.new();

    function self.init()
    end

    function self.createMenu(_data)
        --print("ISContextPush.createMenu");

        for _, item in ipairs(_data.objects) do
            local square = item:getSquare();
            if square and not square:isSomethingTo(_data.player:getSquare()) then
                --print("ISContextPush.createMenu - found item square with nothing between it and player");

                local moveProps = ISMoveableSpriteProps.fromObject(item);
                if moveProps and self.canStartPushMoveable(moveProps, _data.player, square, item) then
                    --print("ISContextPush.createMenu - found moveable item that can be picked up from props");

                    if self.isPlayerAdjacent(_data.player, square) then
                        --print("ISContextPush.createMenu - player is adjacent");

                        local direction = self.getPushDirection(_data.player, square);
                        if (direction) then
                            --print("IsContextPush.createMenu - direction: " .. tostring(direction));

                            local adjacentSquare = square:getAdjacentSquare(direction);

                            if self.canFinishPushMoveable(moveProps, _data.player, adjacentSquare) and not square:isSomethingTo(adjacentSquare) then
                                _data.context:addOption(getText("Push " .. tostring(moveProps.name)), _data.player,
                                    self.push,
                                    moveProps, square, item,
                                    adjacentSquare);
                                --print("ISContextPush.createMenu - added option for " .. tostring(moveProps.name));
                            end
                        end
                    end
                end
            end
        end
    end

    function self.push(_player, _moveProps, _square, _item, _adjacentSquare)
        if (luautils.walkAdj(_player, _square)) then
            ISTimedActionQueue.add(
                ISMoveablesActionExtended:new(_player, _square, _adjacentSquare, _item, _moveProps, "push",
                    _moveProps.spriteName));
            --print("ISContextPush.push - Added push to timed actions");
        end
    end

    function self.isPlayerAdjacent(_player, _square)
        local playerCoordinates = self.getCoordinates(_player);
        local itemCoordinates = self.getCoordinates(_square);

        return math.floor(playerCoordinates.x) == itemCoordinates.x + 1 or
            math.floor(playerCoordinates.x) == itemCoordinates.x - 1 or
            math.floor(playerCoordinates.y) == itemCoordinates.y + 1 or
            math.floor(playerCoordinates.y) == itemCoordinates.y - 1;
    end

    function self.getPushDirection(_player, _square)
        local playerCoordinates = self.getCoordinates(_player);
        local itemCoordinates = self.getCoordinates(_square);

        local xDiff = math.floor(playerCoordinates.x) - itemCoordinates.x;
        local yDiff = math.floor(playerCoordinates.y) - itemCoordinates.y;
        if yDiff == -1 then
            return IsoDirections.S;
        elseif yDiff == 1 then
            return IsoDirections.N
        elseif xDiff == -1 then
            return IsoDirections.E
        elseif xDiff == 1 then
            return IsoDirections.W
        end
    end

    function self.getCoordinates(_objectWithCoords)
        local objectCoords = { x = _objectWithCoords:getX(), y = _objectWithCoords:getY() };
        --print("ISContextPush.getCoordinates - objectCoords: " .. objectCoords.x .. ", " .. objectCoords.y)

        return objectCoords;
    end

    function self.canStartPushMoveable(_moveProps, _character, _square, _object)
        if _moveProps.isMoveable and _moveProps.isMultiSprite then
            local sgrid = _moveProps:getSpriteGridInfo(_square, true);
            if not sgrid then return false; end
            for _, gridMember in ipairs(sgrid) do
                if not self.canStartPushMoveableInternal(_moveProps, _character, gridMember.square, not gridMember.sprInstance and gridMember.object or nil, true) then
                    return false;
                end
            end
            return true;
        else
            return self.canStartPushMoveableInternal(_moveProps, _character, _square, _object, false);
        end
    end

    function self.canStartPushMoveableInternal(_moveProps, _character, _square, _object, _isMulti)
        --print("ISContextPush.canStartPushMoveableInternal - checking if " ..
        --tostring(_moveProps.name) .. " can start to be pushed");

        local canPickUp = false;
        if _moveProps.isMoveable and instanceof(_square, "IsoGridSquare") then
            --print("ISContextPush.canStartPushMoveableInternal - item is Moveable");

            canPickUp = not _object and true or _moveProps:objectNoContainerOrEmpty(_object);

            if not _isMulti and canPickUp then
                --print("ISContextPush.canStartPushMoveableInternal - item is not Multi");

                canPickUp = _character:getInventory():hasRoomFor(_character, _moveProps.weight);
            end
            if canPickUp and _moveProps.isTable then
                --print("ISContextPush.canStartPushMoveableInternal - item is Table");

                canPickUp = not _square:Is("IsTableTop") and _object == _moveProps:getTopTable(_square);
            end
            _moveProps.yOffsetCursor = _object and _object:getRenderYOffset() or 0;

            if canPickUp and _moveProps.isWaterCollector then
                --print("ISContextPush.canStartPushMoveableInternal - item is Water Collector");

                if _object and _object:hasWater() then
                    canPickUp = false
                end
            end

            if canPickUp and CMetalDrumSystem.instance:isValidIsoObject(_object) and
                (_object:getModData().haveCharcoal or _object:getModData().haveLogs) then
                canPickUp = false
            end

            if canPickUp and _moveProps.type == "Window" then
                --print("ISContextPush.canStartPushMoveableInternal - item is Window");

                canPickUp = false;
            end

            if canPickUp and _moveProps.type == "WindowObject" then
                --print("ISContextPush.canStartPushMoveableInternal - item is Window Object");

                canPickUp = false;
            end

            if _moveProps.isoType == "IsoMannequin" then
                --print("ISContextPush.canStartPushMoveableInternal - item is Mannequin");

                canPickUp = true
            end

            if instanceof(_object, "IsoBarbecue") then
                --print("ISContextPush.canStartPushMoveableInternal - item is Barbecue");

                canPickUp = not _object:isLit() and not _object:hasPropaneTank();
            end

            if instanceof(_object, "IsoFireplace") then
                --print("ISContextPush.canStartPushMoveableInternal - item is Fireplace");

                canPickUp = not (_object:isLit() or _object:isSmouldering())
            end

            if canPickUp and _character and instanceof(_character, "IsoGameCharacter") then
                --print("ISContextPush.canStartPushMoveableInternal - item is other");

                canPickUp = true;
            end
        end
        return canPickUp;
    end

    function self.canFinishPushMoveable(_moveProps, _character, _square)
        --print("IsContextPush.canFinishPushMoveable - checking if " ..
        --tostring(_moveProps.name) .. " can finish being pushed");
        if _moveProps.isMoveable and _moveProps.isMultiSprite then
            local spriteGrid = _moveProps.sprite:getSpriteGrid();
            if not spriteGrid then return false; end

            local sX = _square:getX() - spriteGrid:getSpriteGridPosX(_moveProps.sprite);
            local sY = _square:getY() - spriteGrid:getSpriteGridPosY(_moveProps.sprite);
            local sZ = _square:getZ();

            local square = getCell():getGridSquare(sX, sY, sZ);

            local sgrid = _moveProps:getSpriteGridInfo(square, false);
            if not sgrid then return false; end

            if not _moveProps.isForceSingleItem then
                local max = spriteGrid:getSpriteCount();
                for i, gridMember in ipairs(sgrid) do
                    local item, container = _moveProps:findInInventoryMultiSprite(_character,
                        _moveProps.name .. " (" .. i .. "/" .. max .. ")");
                    if not item or not self:canFinishPushMoveableInternal(_moveProps, _character, gridMember.square) then
                        return false;
                    end
                    if container and container == "floor" then
                        local radius = ISMoveableSpriteProps.multiSpriteFloorRadius - 1;
                        if radius < 1 then radius = 1 end
                        ;
                        if _square:getX() < _character:getX() - (radius + 1) or _square:getX() > _character:getX() + radius then
                            return false;
                        end
                        if _square:getY() < _character:getY() - (radius + 1) or _square:getY() > _character:getY() + radius then
                            return false;
                        end
                    end
                end
            else
                local item = _moveProps:findInInventoryMultiSprite(_character, _moveProps.name .. " (1/1)");
                for i, gridMember in ipairs(sgrid) do
                    if not item or not self.canFinishPushMoveableInternal(_moveProps, _character, gridMember.square) then
                        return false;
                    end
                end
            end

            if _moveProps:isWallBetweenParts(spriteGrid, sX, sY, sZ) then
                return false
            end

            return true;
        else
            return self.canFinishPushMoveableInternal(_moveProps, _character, _square);
        end
    end

    function self.canFinishPushMoveableInternal(_moveProps, _character, _square)
        --print("ISContextPush.canFinishPushMoveableInternal - checking if " ..
        --tostring(_moveProps.name) .. " can finish being pushed");

        local canPlace = false;
        if _square and _square:isVehicleIntersecting() then
            return false
        end

        if _moveProps.isMoveable then
            --print("ISContextPush.canFinishPushMoveableInternal - item is Moveable");

            local hasTileFloor = _square and _square:getFloor();
            if not hasTileFloor and _moveProps.type ~= "Window" then
                return false;
            end

            if _moveProps.type == "Object" then
                if _moveProps.isTableTop then
                    --print("ISContextPush.canFinishPushMoveableInternal - item is Table Top");

                    local currentSurface = _moveProps:getTotalTableHeight(_square);
                    if _square:Is("IsTable") then
                        canPlace = not _square:Is("IsTableTop") and (currentSurface <= 64);
                    else
                        canPlace = _moveProps.blocksPlacement and _moveProps:isFreeTile(_square);
                    end
                    if _moveProps.surface and _moveProps.surfaceIsOffset then
                        currentSurface = currentSurface - _moveProps.surface;
                    end
                    _moveProps.yOffsetCursor = currentSurface;
                elseif _moveProps:isFreeTile(_square) then
                    --print("ISContextPush.canFinishPushMoveableInternal - item is Free Tile");
                    canPlace = true;
                    if _square:Is("IsHigh") then
                        canPlace = _moveProps.isLow;
                    end
                    if _square:Is("IsLow") then
                        canPlace = _moveProps.isHigh;
                    end
                elseif _moveProps.isStackable and _moveProps.isTable and _moveProps.surface and _square:Is("IsTable") and not _square:Is("IsTableTop") and not _square:Is("IsHigh") then
                    --print("ISContextPush.canFinishPushMoveableInternal - item is Stackable");

                    local totalTableHeight = _moveProps:getTotalTableHeight(_square)
                    if totalTableHeight + _moveProps.surface <= 96 then
                        canPlace = true
                    end
                    _moveProps.yOffsetCursor = totalTableHeight
                end
                if _moveProps:isSquareAtTopOfStairs(_square) then
                    canPlace = false
                end
            elseif _moveProps.type == "WallObject" or _moveProps.type == "WallOverlay" or _moveProps.type == "FloorTile" or _moveProps.type == "FloorRug" or _moveProps.type == "Vegitation" or _moveProps.type == "WindowObject" or _moveProps.type == "Window" then
                canPlace = false
            end

            if canPlace and _character and instanceof(_character, "IsoPlayer") then
                canPlace = true;
            end
        end
        return canPlace;
    end

    return self;
end
