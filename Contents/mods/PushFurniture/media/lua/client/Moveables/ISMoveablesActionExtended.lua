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

        if math.floor(playerCoordinates.x) ~= itemCoordinates.x + 1 and
            math.floor(playerCoordinates.x) ~= itemCoordinates.x - 1 and
            math.floor(playerCoordinates.y) ~= itemCoordinates.y + 1 and
            math.floor(playerCoordinates.y) ~= itemCoordinates.y - 1 then
            --print("ISMoveablesActionExtended - Too far away")
            self:stop();
            return false;
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

    self.character:setMetabolicTarget(Metabolics.UsingTools);
end

function ISMoveablesActionExtended:start()
end

function ISMoveablesActionExtended:stop()
    ISBaseTimedAction.stop(self)
end

--[[
-- The moveprops of the new facing (where applies) are always used to perform the actions, the origSpriteName is passed to retrieve the original object from tile or inventory.
 ]]
function ISMoveablesActionExtended:perform()
    --print("ISMoveablesActionExtended - Performing Action");
    if self.moveProps and self.moveProps.isMoveable and self.mode == "push" then
        --print("ISMoveablesActionExtended - IsMoveable");
        if self.mode == "push" then
            --print("ISMoveablesActionExtended - Picking up Object")
            self.moveProps:pickUpMoveableViaCursor(self.character, self.square, self.origSpriteName, self.moveCursor)

            IsoPlayer:getInstance():AttemptAttack()

            --print("ISMoveablesActionExtended - Placing Object")
            self.moveProps:placeMoveableViaCursor(self.character, self.newSquare, self.origSpriteName, self.moveCursor);
            buildUtil.setHaveConstruction(self.square, true);
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
