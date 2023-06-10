require "TimedActions/ISBaseTimedAction"

ISMoveablesActionExtended = ISBaseTimedAction:derive("ISMoveablesAction")

function ISMoveablesActionExtended:isReachableObjectType()
    local moveProps = self.moveProps;
    local object = moveProps.object;
    local isWall = moveProps.spriteProps:Is("WallNW") or moveProps.spriteProps:Is("WallN") or
        moveProps.spriteProps:Is("WallW");
    local isWallTrans = moveProps.spriteProps:Is("WallNWTrans") or moveProps.spriteProps:Is("WallNTrans") or
        moveProps.spriteProps:Is("WallWTrans");
    local isDoor = instanceof(object, "IsoDoor");
    local isWindow = instanceof(object, "IsoWindow") or moveProps.type == "Window";
    local isFence = (instanceof(object, "IsoObject") or instanceof(object, "IsoThumpable")) and object:isHoppable();
    return isWall or isWallTrans or isDoor or isWindow or isFence;
end

function ISMoveablesActionExtended:isValidObject()
    if (not self.square) then return false; end
    if (not self.moveProps) then return false; end
    local objects = self.square:getObjects();
    if objects then
        for i = 0, objects:size() - 1 do
            local object = objects:get(i);
            if object and self.moveProps.object == object then
                return true;
            end
        end
    end
    return false;
end

function ISMoveablesActionExtended:isValid()
    --print("ISMoveablesActionExtended - Checking if valid action")

    local plSquare = self.character:getSquare();
    if (plSquare and self.square) and (plSquare:getZ() == self.square:getZ()) then
        --print("ISMoveablesActionExtended - Object level with player")

        --ensure we can reach the object from here (wall, door, window or fence)
        if self.square:isSomethingTo(plSquare) and not self:isReachableObjectType() then
            --print("ISMoveablesActionExtended - Unreachable")

            self:stop();
            return false;
        end

        --ensure the player hasn't moved too far away while the action was in queue
        local playerCoordinates = { x = self.character:getX(), y = self.character:getY() };
        local itemCoordinates = { x = self.square:getX(), y = self.square:getY() };


        if self.mode == "push" then
            if math.floor(playerCoordinates.x) ~= itemCoordinates.x + 1 and
                math.floor(playerCoordinates.x) ~= itemCoordinates.x - 1 and
                math.floor(playerCoordinates.y) ~= itemCoordinates.y + 1 and
                math.floor(playerCoordinates.y) ~= itemCoordinates.y - 1 then
                --print("ISMoveablesActionExtended - Too far away")
                self:stop();
                return false;
            end
        elseif self.mode == "pull" then
            if math.floor(playerCoordinates.x) ~= itemCoordinates.x + 2 and
                math.floor(playerCoordinates.x) ~= itemCoordinates.x - 2 and
                math.floor(playerCoordinates.y) ~= itemCoordinates.y + 2 and
                math.floor(playerCoordinates.y) ~= itemCoordinates.y - 2 then
                --print("ISMoveablesActionExtended - Too far away")
                self:stop();
                return false;
            end
        end

        --prevent actions in safehouse for non-members
        if isClient() and SafeHouse.isSafeHouse(self.square, self.character:getUsername(), true) then
            --SafehouseAllowLoot allows push
            if self.mode == "push" and not getServerOptions():getBoolean("SafehouseAllowLoot") then
                --print("ISMoveablesActionExtended - Only SafehouseAllowLoot allows push")
                self:stop();
                return false;
            end
        end

        --print("ISMoveablesActionExtended - Valid action");
        return true;
    end

    --print("ISMoveablesActionExtended - Invalid action");
    self:stop();
    return false;
end

function ISMoveablesActionExtended:waitToStart()
    self.character:faceLocation(self.square:getX(), self.square:getY())
    return self.character:shouldBeTurning()
end

function ISMoveablesActionExtended:update()
    self.character:faceLocation(self.square:getX(), self.square:getY());

    if self.sound and not self.character:getEmitter():isPlaying(self.sound) then
        self:setActionSound();
    end

    self.character:setMetabolicTarget(Metabolics.UsingTools);
end

function ISMoveablesActionExtended:setActionSound()
    self.sound = self.moveProps:getSoundFromTool(self.square, self.character, "place");
end

function ISMoveablesActionExtended:start()
    self:setActionSound();
    if self.sound and self.sound ~= 0 then
        self.character:stopOrTriggerSound(self.sound);
    end
end

function ISMoveablesActionExtended:stop()
    if self.sound and self.sound ~= 0 then
        self.character:stopOrTriggerSound(self.sound);
    end
    ISBaseTimedAction.stop(self)
end

function ISMoveablesActionExtended:perform()
    --print("ISMoveablesActionExtended - Performing Action");

    if self.sound and self.sound ~= 0 then
        self.character:stopOrTriggerSound(self.sound);
    end
    if self.moveProps and self.moveProps.isMoveable then
        --print("ISMoveablesActionExtended - IsMoveable");
        if self.mode == "push" then
            --print("ISMoveablesActionExtended - Picking up Object")
            self.startPushMoveableViaCursor(self.moveProps, self.character, self.square, self.moveCursor)

            IsoPlayer:getInstance():AttemptAttack()

            --print("ISMoveablesActionExtended - Placing Object")
            self.finishPushMoveableViaCursor(self.moveProps, self.character, self.newSquare, self.origSpriteName,
                self.moveCursor);
        elseif self.mode == "pull" then
            --print("ISMoveablesActionExtended - Picking up Object")
            self.startPushMoveableViaCursor(self.moveProps, self.character, self.square, self.moveCursor)

            --print("ISMoveablesActionExtended - Placing Object")
            self.finishPushMoveableViaCursor(self.moveProps, self.character, self.newSquare, self.origSpriteName,
                self.moveCursor);
        end
    end

    ISBaseTimedAction.perform(self)
end

function ISMoveablesActionExtended:new(character, _oldSquare, _newSquare, _item, _moveProps, _mode, _origSpriteName,
                                       _moveCursor)
    --print("ISMoveablesActionExtended - New Action")
    --print("ISMoveablesActionExtended - Sprite - " .. _origSpriteName)

    local o = {};
    setmetatable(o, self);
    self.__index     = self;
    o.character      = character;
    o.square         = _oldSquare;
    o.newSquare      = _newSquare;
    o.item           = _item;
    o.origSpriteName = _origSpriteName;
    o.stopOnWalk     = true;
    o.stopOnRun      = true;
    o.maxTime        = 50;
    o.spriteFrame    = 0;
    o.mode           = _mode;
    o.moveProps      = _moveProps;
    o.moveCursor     = _moveCursor;

    function self.canStartPushMoveable(_moveProps, _character, _square, _object)
        if _moveProps.isMoveable and _moveProps.isMultiSprite then
            local sgrid = _moveProps:getSpriteGridInfo(_square, true);
            if not sgrid then return false; end
            for _, gridMember in ipairs(sgrid) do
                if not ISMoveablesActionExtended.canStartPushMoveableInternal(_moveProps, _character, gridMember.square, not gridMember.sprInstance and gridMember.object or nil, true) then
                    return false;
                end
            end
            return true;
        else
            return ISMoveablesActionExtended.canStartPushMoveableInternal(_moveProps, _character, _square, _object, false);
        end
    end

    function self.canStartPushMoveableInternal(_moveProps, _character, _square, _object, _isMulti)
        --print("ISMoveablesActionExtended.canStartPushMoveableInternal - checking if " ..
        --tostring(_moveProps.name) .. " can start to be pushed");

        local canPickUp = false;
        if _moveProps.isMoveable and instanceof(_square, "IsoGridSquare") then
            --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is Moveable");

            canPickUp = not _object and true or _moveProps:objectNoContainerOrEmpty(_object);

            if not _isMulti and canPickUp then
                --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is not Multi");

                canPickUp = _character:getInventory():hasRoomFor(_character, _moveProps.weight);
            end
            if canPickUp and _moveProps.isTable then
                --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is Table");

                canPickUp = not _square:Is("IsTableTop") and _object == _moveProps:getTopTable(_square);
            end
            _moveProps.yOffsetCursor = _object and _object:getRenderYOffset() or 0;

            if canPickUp and _moveProps.isWaterCollector then
                --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is Water Collector");

                if _object and _object:hasWater() then
                    canPickUp = false
                end
            end

            if canPickUp and CMetalDrumSystem.instance:isValidIsoObject(_object) and
                (_object:getModData().haveCharcoal or _object:getModData().haveLogs) then
                canPickUp = false
            end

            if canPickUp and _moveProps.type == "Window" then
                --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is Window");

                canPickUp = false;
            end

            if canPickUp and _moveProps.type == "WindowObject" then
                --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is Window Object");

                canPickUp = false;
            end

            if _moveProps.isoType == "IsoMannequin" then
                --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is Mannequin");

                canPickUp = true
            end

            if instanceof(_object, "IsoBarbecue") then
                --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is Barbecue");

                canPickUp = not _object:isLit() and not _object:hasPropaneTank();
            end

            if instanceof(_object, "IsoFireplace") then
                --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is Fireplace");

                canPickUp = not (_object:isLit() or _object:isSmouldering())
            end

            if canPickUp and _character and instanceof(_character, "IsoGameCharacter") then
                --print("ISMoveablesActionExtended.canStartPushMoveableInternal - item is other");

                canPickUp = true;
            end
        end
        return canPickUp;
    end

    function self.canFinishPushMoveable(_moveProps, _character, _square)
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
                    if not item or not ISMoveablesActionExtended:canFinishPushMoveableInternal(_moveProps, _character, gridMember.square) then
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
                    if not item or not ISMoveablesActionExtended.canFinishPushMoveableInternal(_moveProps, _character, gridMember.square) then
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
        --print("ISMoveablesActionExtended.canFinishPushMoveableInternal - checking if " ..
        --tostring(_moveProps.name) .. " can finish being pushed");

        local canPlace = false;
        if _square and _square:isVehicleIntersecting() then
            return false
        end

        if _moveProps.isMoveable then
            --print("ISMoveablesActionExtended.canFinishPushMoveableInternal - item is Moveable");

            local hasTileFloor = _square and _square:getFloor();
            if not hasTileFloor and _moveProps.type ~= "Window" then
                return false;
            end

            if _moveProps.type == "Object" then
                if _moveProps.isTableTop then
                    --print("ISMoveablesActionExtended.canFinishPushMoveableInternal - item is Table Top");

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
                    --print("ISMoveablesActionExtended.canFinishPushMoveableInternal - item is Free Tile");
                    canPlace = true;
                    if _square:Is("IsHigh") then
                        canPlace = _moveProps.isLow;
                    end
                    if _square:Is("IsLow") then
                        canPlace = _moveProps.isHigh;
                    end
                elseif _moveProps.isStackable and _moveProps.isTable and _moveProps.surface and _square:Is("IsTable") and not _square:Is("IsTableTop") and not _square:Is("IsHigh") then
                    --print("ISMoveablesActionExtended.canFinishPushMoveableInternal - item is Stackable");

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

    function self.startPushMoveableViaCursor(_moveProps, _character, _square, _moveCursor)
        self.startPushMoveable(_moveProps, _character, _square, true);
        if _moveCursor then
            _moveCursor:clearCache()
        end
    end

    function self.startPushMoveable(_moveProps, _character, _square, _createItem)
        if _moveProps.isMoveable and instanceof(_character, "IsoGameCharacter") and instanceof(_square, "IsoGridSquare") then
            local obj, sprInstance = _moveProps:findOnSquare(_square, _moveProps.spriteName);
            local items = {};
            if obj and (self.canStartPushMoveable(_moveProps, _character, _square, not sprInstance and obj or nil)) then
                if _moveProps.isMultiSprite then
                    local sgrid = _moveProps:getSpriteGridInfo(_square, true);
                    if not sgrid then return false; end

                    local createItem = _createItem and not _moveProps.isForceSingleItem;
                    for _, gridMember in ipairs(sgrid) do
                        table.insert(items,
                            self.startPushMoveableInternal(_moveProps, _character, gridMember.square, gridMember.object,
                                gridMember.sprInstance, gridMember.sprite:getName(), createItem));
                    end

                    if _createItem and _moveProps.isForceSingleItem then
                        local spriteGrid = _moveProps.sprite:getSpriteGrid();
                        if not spriteGrid then return false; end

                        local item = _moveProps:instanceItem(spriteGrid:getAnchorSprite():getName());
                        _character:getInventory():AddItem(item);
                    end
                else
                    self.startPushMoveableInternal(_moveProps, _character, _square, obj, sprInstance,
                        _moveProps.spriteName,
                        _createItem);
                end
                ISMoveableCursor.clearCacheForAllPlayers();
                return items;
            end
        end
    end

    function self.startPushMoveableInternal(_moveProps, _character, _square, _object, _sprInstance,
                                            _spriteName,
                                            _createItem, _rotating)
        local objIsIsoWindow = _moveProps.type == "Window" and instanceof(_object, "IsoWindow");
        local item           = _moveProps:instanceItem(_spriteName);

        if item or (objIsIsoWindow and _object:isDestroyed()) then
            if not objIsIsoWindow or not _object:isDestroyed() then
                if not _rotating and _moveProps:doBreakTest(_character) then
                    if _moveProps.type ~= "Window" then
                        _moveProps:playBreakSound(_character, _object);
                        _moveProps:addBreakDebris(_square);
                    elseif objIsIsoWindow then
                        if not _object:isDestroyed() then
                            _object:smashWindow();
                        end
                    end
                elseif item then
                    if instanceof(_object, "IsoThumpable") then
                        item:getModData().name = _object:getName() or ""
                        item:getModData().health = _object:getHealth()
                        item:getModData().maxHealth = _object:getMaxHealth()
                        item:getModData().thumpSound = _object:getThumpSound()
                        item:getModData().color = _object:getCustomColor()
                        if _object:hasModData() then
                            item:getModData().modData = copyTable(_object:getModData())
                        end
                    else
                        if _object:hasModData() and _object:getModData().movableData then
                            item:getModData().movableData = copyTable(_object:getModData().movableData)
                        end

                        if _object:hasModData() and _object:getModData().itemCondition then
                            item:setConditionMax(_object:getModData().itemCondition.max);
                            item:setCondition(_object:getModData().itemCondition.value);
                        end
                    end
                    if _createItem then
                        if _moveProps.isMultiSprite then
                            _square:AddWorldInventoryItem(item, ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), 0);
                        else
                            _character:getInventory():AddItem(item);
                        end
                    end
                end
            end

            if instanceof(_object, "IsoLightSwitch") and _sprInstance == nil then
                _object:setCustomSettingsToItem(item);
            end

            if instanceof(_object, "IsoMannequin") then
                _object:setCustomSettingsToItem(item)
            end

            if not _sprInstance then
                if _moveProps.isoType == "IsoRadio" or _moveProps.isoType == "IsoTelevision" then
                    if instanceof(_object, "IsoWaveSignal") then
                        local deviceData = _object:getDeviceData();
                        if deviceData then
                            item:setDeviceData(deviceData);
                        else
                            --print("Warning: device data missing?>?")
                        end
                    end
                end
                if _moveProps.spriteProps and not _moveProps.spriteProps:Is(IsoFlagType.waterPiped) then
                    if _object:hasModData() then
                        if _object:getModData().waterAmount then
                            item:getModData().waterAmount = _object:getModData().waterAmount;
                            item:getModData().taintedWater = _object:isTaintedWater();
                        end
                    else
                        local waterAmount = tonumber(_object:getWaterAmount());
                        if waterAmount then
                            item:getModData().waterAmount = waterAmount;
                            item:getModData().taintedWater = _object:isTaintedWater();
                        end
                    end
                end
                triggerEvent("OnObjectAboutToBeRemoved", _object)
                _square:transmitRemoveItemFromSquare(_object)
            end
            _square:RecalcProperties();
            _square:RecalcAllWithNeighbours(true);

            triggerEvent("OnContainerUpdate")

            IsoGenerator.updateGenerator(_square)
            return item;
        end
    end

    function self.finishPushMoveableViaCursor(_moveProps, _character, _square, _origSpriteName,
                                              _moveCursor)
        self.finishPushMoveable(_moveProps, _character, _square, _origSpriteName);
        if _moveCursor then
            _moveCursor:clearCache()
        end
    end

    function self.finishPushMoveable(_moveProps, _character, _square, _origSpriteName)
        if _moveProps.isMoveable and instanceof(_character, "IsoGameCharacter") and instanceof(_square, "IsoGridSquare") then
            if _moveProps.isMultiSprite then
                --print("ISMoveablesActionExtended.finishPushMoveable: isMultiSprite")
                local spriteGrid = _moveProps.sprite:getSpriteGrid();
                if not spriteGrid then return false; end

                local sgrid = _moveProps:getSpriteGridInfo(_square, false);
                if not sgrid then return false; end

                if not _moveProps.isForceSingleItem then
                    local max = spriteGrid:getSpriteCount();
                    local items = {};
                    for i, gridMember in ipairs(sgrid) do
                        local item, container = _moveProps:findInInventoryMultiSprite(_character,
                            _moveProps.name .. " (" .. i .. "/" .. max .. ")");
                        if not item or not self.canFinishPushMoveableInternal(_moveProps, _character, gridMember.square) then
                            return false;
                        end
                        items[i] = { item, container };
                    end
                    for i, gridMember in ipairs(sgrid) do
                        local item, inventory = items[i][1], items[i][2];
                        self.finishPushMoveableInternal(_moveProps, gridMember.square, item, gridMember.sprite:getName());

                        if inventory == "floor" then
                            if item:getWorldItem() ~= nil then
                                item:getWorldItem():getSquare():transmitRemoveItemFromSquare(item:getWorldItem());
                                item:getWorldItem():getSquare():removeWorldObject(item:getWorldItem());
                                item:setWorldItem(nil);
                            end
                        else
                            inventory:Remove(item);
                        end
                    end
                else
                    local item = _moveProps:findInInventoryMultiSprite(_character, _moveProps.name .. " (1/1)");
                    if item then
                        for i, gridMember in ipairs(sgrid) do
                            if not self.canFinishPushMoveableInternal(_moveProps, _character, gridMember.square) then
                                return false;
                            end
                        end
                        for i, gridMember in ipairs(sgrid) do
                            local gridItem = _moveProps:instanceItem(gridMember.sprite:getName());
                            if gridMember.sprite == spriteGrid:getAnchorSprite() then
                                gridItem = item;
                            end
                            self.finishPushMoveableInternal(_moveProps, gridMember.square, gridItem,
                                gridMember.sprite:getName())
                        end

                        _character:getInventory():Remove(item);
                    end
                end

                ISMoveableCursor.clearCacheForAllPlayers();
            else
                --print("ISMoveablesActionExtended.finishPushMoveable: not isMultiSprite")
                local item = _moveProps:findInInventory(_character, _origSpriteName);
                if item and self.canFinishPushMoveableInternal(_moveProps, _character, _square) then
                    self.finishPushMoveableInternal(_moveProps, _square, item, _moveProps.spriteName)
                    _character:getInventory():Remove(item);
                    ISMoveableCursor.clearCacheForAllPlayers();
                end
            end
        end
    end

    function self.finishPushMoveableInternal(_moveProps, _square, _item, _spriteName)
        local obj;
        local insertIndex       = _square:getObjects() and _square:getObjects():size();
        local removeList        = {};
        local TileIsoObjectType = getSprite(_spriteName):getType()

        if insertIndex and insertIndex > 0 then
            local objects = _square:getObjects()
            --print("ISMoveablesActionExtended.finishPushMoveableInternal - insertIndex: " ..
            --insertIndex .. " objects:size(): " .. objects:size())
            for i = objects:size(), 1, -1 do
                if not instanceof(objects:get(i - 1), "IsoWorldInventoryObject") then
                    insertIndex = i
                    break
                end
            end
        end

        --print("ISMoveablesActionExtended.finishPushMoveableInternal - insertIndex: " .. insertIndex)

        if _moveProps.isoType == "IsoObject" and _moveProps.isoType ~= getSprite(_spriteName):getProperties():Val("IsoType") and getSprite(_spriteName):getProperties():Val("IsoType") ~= nil then
            _moveProps.isoType = getSprite(_spriteName):getProperties():Val("IsoType")
        end

        --print("ISMoveablesActionExtended.finishPushMoveableInternal - _moveProps.isoType: " .. _moveProps.isoType)

        _moveProps.container = getSprite(_spriteName):getProperties():Is("container") and
            getSprite(_spriteName):getProperties():Val("container") or nil

        if _spriteName == "appliances_misc_01_0" then
            local genItem = InventoryItemFactory.CreateItem("Base.Generator")
            obj = IsoGenerator.new(genItem, getCell(), _square)
        else
            local itemSprite = _spriteName;
            local sprite = getSprite(itemSprite);
            local props = sprite and sprite:getProperties();
            local currentSurface = _moveProps:getTotalTableHeight(_square);
            if _moveProps.isMoveable and _moveProps.isTableTop and (not _moveProps.ignoreSurfaceSnap) then
                local objects = _square:getObjects();
                for i = 0, objects:size() - 1 do
                    local object = objects:get(i);
                    local spr    = object:getSprite();
                    local mprops = ISMoveableSpriteProps.new(spr);
                    if _moveProps.facing ~= nil and mprops.isMoveable and mprops.isTable and mprops:hasFaces() then
                        insertIndex = i + 1;
                        local tmpSprite = _moveProps:getFaceSpriteFromParentObject(object);
                        if tmpSprite then
                            itemSprite = tmpSprite;
                            break;
                        end
                    end
                end
            end

            local doDestroyAble = false;

            --print("ISMoveablesActionExtended.finishPushMoveableInternal - getting Object")
            if _moveProps.isoType == "IsoBarbecue" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoBarbecue")

                local bbqSprite = getSprite(itemSprite);
                if bbqSprite then
                    obj = IsoBarbecue.new(getCell(), _square, bbqSprite);
                    obj:setMovedThumpable(true);
                end
            elseif _moveProps.isoType == "IsoCombinationWasherDryer" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoCombinationWasherDryer")

                obj = IsoCombinationWasherDryer.new(getCell(), _square, getSprite(itemSprite))
                obj:setMovedThumpable(true);
            elseif _moveProps.isoType == "IsoClothingDryer" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoClothingDryer")

                obj = IsoClothingDryer.new(getCell(), _square, getSprite(itemSprite))
                obj:setMovedThumpable(true);
            elseif _moveProps.isoType == "IsoClothingWasher" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoClothingWasher")

                obj = IsoClothingWasher.new(getCell(), _square, getSprite(itemSprite))
                obj:setMovedThumpable(true);
            elseif _moveProps.isoType == "IsoCompost" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoCompost")

                obj = IsoCompost.new(getCell(), _square, getSprite(itemSprite))
                obj:setMovedThumpable(true);
            elseif _moveProps.isoType == "IsoMannequin" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoMannequin")

                obj = IsoMannequin.new(getCell(), _square, getSprite(itemSprite))
                obj:setSquare(_square)
                obj:getCustomSettingsFromItem(_item)
                if _moveProps.cursorFacing then
                    local facing = { "N", "W", "S", "E" }
                    local dir = IsoDirections[facing[_moveProps.cursorFacing]]
                    obj:setDir(dir)
                end
            elseif _moveProps.isoType == "IsoRadio" or _moveProps.isoType == "IsoTelevision" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoRadio or IsoTelevision")

                local obj = nil
                if instanceof(_item, "Radio") then
                    if _moveProps.isoType == "IsoRadio" then
                        obj = IsoRadio.new(getCell(), _square, getSprite(itemSprite));
                    elseif _moveProps.isoType == "IsoTelevision" then
                        obj = IsoTelevision.new(getCell(), _square, getSprite(itemSprite));
                    end
                    local deviceData = _item:getDeviceData();
                    if deviceData then
                        if deviceData.setIsTurnedOn ~= nil then
                            deviceData:setIsTurnedOn(deviceData:getIsTurnedOn());
                        end
                        obj:setDeviceData(deviceData);
                    else
                        --print("Warning: device data missing?>?")
                    end
                else
                    if _moveProps.isoType == "IsoRadio" then
                        --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoRadio")

                        obj = IsoRadio.new(getCell(), _square, getSprite(itemSprite));
                        obj:setMovedThumpable(true);
                    elseif _moveProps.isoType == "IsoTelevision" then
                        --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoTelevision")

                        obj = IsoTelevision.new(getCell(), _square, getSprite(itemSprite));
                        obj:setMovedThumpable(true);
                    end
                end
            elseif _moveProps.isoType == "IsoJukebox" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoJukebox")

                obj = IsoJukebox.new(getCell(), _square, getSprite(itemSprite));
                obj:setMovedThumpable(true);
            elseif _moveProps.isoType == "IsoStove" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoStove")

                obj = IsoStove.new(getCell(), _square, getSprite(itemSprite));
                obj:setMovedThumpable(true);
            elseif _moveProps.isoType == "IsoFireplace" or _moveProps.container == "fireplace" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoFireplace")

                obj = IsoFireplace.new(getCell(), _square, getSprite(itemSprite));
            elseif _moveProps.isoType == "IsoMultiMedia" then
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - IsoMultiMedia")

                obj = IsoMultiMedia.new(getCell(), _square, getSprite(itemSprite));
            else
                --print("ISMoveablesActionExtended.finishPushMoveableInternal - Other")
                local blockStyleSolid = props and (props:Is(IsoFlagType.solid) or props:Is(IsoFlagType.solidtrans)) or
                    false;

                if props and TileIsoObjectType == IsoObjectType.lightswitch then
                    --print("ISMoveablesActionExtended.finishPushMoveableInternal - lightswitch")
                    if props:Is("streetlight") then
                        createTile(_spriteName, _square)
                        getPlayer():setHaloNote("Light tiles will be updated when zone will reloaded")
                    else
                        obj = IsoLightSwitch.new(getCell(), _square, getSprite(_spriteName), _square:getRoomID());
                        obj:addLightSourceFromSprite();
                        obj:getCustomSettingsFromItem(_item);
                    end
                elseif not blockStyleSolid or _moveProps.isTableTop then
                    --print(
                    --"ISMoveablesActionExtended.finishPushMoveableInternal - not blockStyleSolid or _moveProps.isTableTop")
                    obj = IsoObject.new(getCell(), _square, itemSprite);
                else
                    if luautils.stringStarts(_spriteName, 'blends_natural_02') then
                        if luautils.stringStarts(_spriteName, 'blends_natural_02_0') or luautils.stringStarts(_spriteName, 'blends_natural_02_5') or luautils.stringStarts(_spriteName, 'blends_natural_02_6') or luautils.stringStarts(_spriteName, 'blends_natural_02_7') then
                            local spr = getSprite(_spriteName);
                            local floor = _square:getFloor();
                            if floor and spr then
                                for i = _square:getObjects():size() - 1, 0, -1 do
                                    local object = _square:getObjects():get(i)
                                    if object ~= floor then
                                        if isClient() then _square:transmitRemoveItemFromSquare(object) end
                                        _square:RemoveTileObject(object);
                                    end
                                end
                                floor:clearAttachedAnimSprite()
                                _square:addFloor(itemSprite)
                            end
                            getPlayer():setHaloNote("Tiles around water will improve when zone will reloaded")
                        else
                            getPlayer():setHaloNote("This water tiles not work because need water zone for it")
                            return
                        end
                    else
                        --print("ISMoveablesActionExtended.finishPushMoveableInternal - Creating new IsoThumpable")
                        obj = IsoThumpable.new(getCell(), _square, itemSprite, false, {});
                        obj:setMaxHealth(_moveProps:getObjectHealth());
                        obj:setHealth(obj:getMaxHealth());
                        obj:setThumpDmg(1);
                        obj:setIsThumpable(true);
                        obj:setBlockAllTheSquare(true);
                        obj:setCanPassThrough(false);
                        obj:setCanPassThrough(false);
                        obj:setHoppable(false);
                        obj:setBreakSound("BreakObject");
                        if _item:hasModData() then
                            local modData = _item:getModData()
                            if type(modData.name) == "string" then
                                obj:setName(modData.name)
                            end
                            if tonumber(modData.health) and tonumber(modData.maxHealth) then
                                obj:setHealth(tonumber(modData.health))
                                obj:setMaxHealth(tonumber(modData.maxHealth))
                            end
                            if type(modData.thumpSound) == "string" then
                                obj:setThumpSound(modData.thumpSound)
                            end
                            if type(modData.modData) == "table" then
                                for key, value in pairs(modData.modData) do
                                    obj:getModData()[key] = value
                                end
                            end
                            if type(modData.color) == "userdata" then
                                obj:setCustomColor(modData.color);
                            end
                        end
                    end
                end
            end

            if _spriteName == "camping_01_04" or _spriteName == "camping_01_05" or _spriteName == "camping_01_06" then
                getPlayer():setHaloNote("Tile will start work when zone will reloaded")
            end

            if obj and _item and _item:hasModData() and _item:getModData().movableData then
                obj:getModData().movableData = copyTable(_item:getModData().movableData);
            end

            if obj and _item and _item:getConditionMax() > 0 then
                obj:getModData().itemCondition = { value = _item:getCondition(), max = _item:getConditionMax() };
            end

            if obj and doDestroyAble then
                if instanceof(obj, "IsoThumpable") then
                    obj:setMaxHealth(_moveProps:getObjectHealth());
                    obj:setHealth(obj:getMaxHealth());
                    obj:setThumpDmg(1);
                    obj:setIsThumpable(true);
                    obj:setBreakSound("BreakObject");
                end
            end

            if obj and _moveProps.isTableTop then
                if _moveProps.surface and _moveProps.surfaceIsOffset then
                    currentSurface = currentSurface - _moveProps.surface;
                end
                obj:setRenderYOffset(currentSurface);
            end

            if obj and _moveProps.isTable then
                obj:setRenderYOffset(currentSurface);
            end

            if props and obj then
                obj:createContainersFromSpriteProperties()
                for i = 1, obj:getContainerCount() do
                    obj:getContainerByIndex(i - 1):setExplored(true)
                end

                if props:Is(IsoFlagType.waterPiped) then
                    obj:getModData().canBeWaterPiped = true;
                end

                if props:Is("waterAmount") and _spriteName ~= "camping_01_16" then
                    obj:setWaterAmount(0);
                    if (not props:Is(IsoFlagType.waterPiped)) and _item and _item:hasModData() then
                        local modData = _item:getModData()
                        if modData.waterAmount and tonumber(modData.waterAmount) then
                            obj:setWaterAmount(tonumber(modData.waterAmount));
                            obj:getModData().waterAmount = tonumber(modData.waterAmount);
                            obj:getModData().taintedWater = modData.taintedWater;
                        end
                    end
                end
            end
        end

        if _square:getObjects() and insertIndex > _square:getObjects():size() then
            insertIndex = _square:getObjects():size();
        end

        if obj then
            _square:AddSpecialObject(obj, insertIndex);
            if isClient() then obj:transmitCompleteItemToServer(); end
            triggerEvent("OnObjectAdded", obj)
        end

        for _, remObject in ipairs(removeList) do
            if isClient() then _square:transmitRemoveItemFromSquare(remObject) end
            _square:RemoveTileObject(remObject);
        end

        getTileOverlays():fixTableTopOverlays(_square);

        _square:RecalcProperties();
        _square:RecalcAllWithNeighbours(true);

        triggerEvent("OnContainerUpdate")

        IsoGenerator.updateGenerator(_square)
    end

    if _moveCursor and (_mode == "push") then
        o.cursorFacing = _moveCursor.cursorFacing or _moveCursor.joypadFacing
    end

    if ISMoveableDefinitions.cheat then
        o.maxTime = 10;
    else
        if o.moveProps and o.moveProps.isMoveable and _mode then
            o.maxTime = o.moveProps:getActionTime(character, _mode);
        end
    end
    return o;
end
