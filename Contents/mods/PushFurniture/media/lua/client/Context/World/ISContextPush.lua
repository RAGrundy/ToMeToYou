ISWorldMenuElements = ISWorldMenuElements or {}

function ISWorldMenuElements.ContextPush()
    local self = ISMenuElement.new();

    function self.init()
    end

    function self.createMenu(_data)
        --print("ISContextPush.createMenu");

        for _, item in ipairs(_data.objects) do
            local square = item:getSquare();
            if square then
                --print("ISContextPush.createMenu - found item square");

                local moveProps = ISMoveableSpriteProps.fromObject(item);
                if moveProps and moveProps:canPickUpMoveable(_data.player, square, item) then
                    --print("ISContextPush.createMenu - found moveable item that can be picked up from props");

                    if self.isPlayerAdjacent(_data.player, square) then
                        --print("ISContextPush.createMenu - player is adjacent");

                        _data.context:addOption(getText("Push"), _data.player, self.push, moveProps, square, item);
                        --print("ISContextPush.createMenu - added option");
                    end
                end
            end
        end
    end

    function self.push(_player, _moveProps, _square, _item)
        local direction = self.getPushDirection(_player, _square);
        if direction then
            --print("ISContextPush.push - direction: " .. tostring(direction));

            local square = _square:getAdjacentSquare(direction);
            if _moveProps:canPlaceMoveable(_player, square, _item) then
                if (luautils.walkAdj(_player, _square)) then
                    ISTimedActionQueue.add(
                        ISMoveablesActionExtended:new(_player, _square, square, _item, _moveProps, "push",
                            _moveProps.spriteName));
                    --print("ISContextPush.push - Added push to timed actions");
                end
            end
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

    return self;
end
