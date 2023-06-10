PlaceWindowBarricades = {};

function PlaceWindowBarricades.onloadgs(sq)
    local modData = sq:getModData();
    if (not modData["BarricadeRiverwoodPD:isBarricaded"]) then
        local sqCoordinates = { x = sq:getX(), y = sq:getY(), z = sq:getZ() };

        if sqCoordinates.x > 6070 and sqCoordinates.x < 6095 and sqCoordinates.y > 5250 and sqCoordinates.y < 5270 then
            --print("BarricadeRiverwoodPD - Checking square " .. --sqCoordinates.x .. ", " .. sqCoordinates.y .. ", " .. sqCoordinates.z);

            local tileIsoObjects = sq:getObjects();
            local numberTileIsoObjects = tileIsoObjects:size();
            for i = 0, numberTileIsoObjects - 1 do
                local tileIsoObject = tileIsoObjects:get(i);

                if tileIsoObject and instanceof(tileIsoObject, "IsoWindow") and not tileIsoObject:isBarricaded() then
                    local coordinates = { x = tileIsoObject:getX(), y = tileIsoObject:getY(), z = tileIsoObject:getZ() };
                    --print("BarricadeRiverwoodPD - Placing barricade at " .. coordinates.x .. ", " .. coordinates.y .. ", " .. coordinates.z);

                    tileIsoObject:addBarricadesDebug(2, false);
                end

                if tileIsoObject and instanceof(tileIsoObject, "IsoDoor") and tileIsoObject:isExterior() then
                    --print("BarricadeRiverwoodPD - Found door at " .. sqCoordinates.x .. ", " .. sqCoordinates.y .. ", " .. sqCoordinates.z);

                    local oppositeSquare = tileIsoObject:getOppositeSquare()
                    if oppositeSquare:getRoom() then
                        --print("BarricadeRiverwoodPD - Found room at " .. oppositeSquare:getX() .. ", " .. oppositeSquare:getY() .. ", " .. oppositeSquare:getZ());

                        local cabinet = IsoObject.new(oppositeSquare, "location_business_office_generic_01_16", false);
                        cabinet:createContainersFromSpriteProperties();
                        oppositeSquare:AddSpecialObject(cabinet);
                        if isClient() then cabinet:transmitCompleteItemToServer() end
                        triggerEvent("OnObjectAdded", cabinet)
                    else
                        local square = tileIsoObject:getSquare()
                        --print("BarricadeRiverwoodPD - Found room at " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ());

                        local cabinet = IsoObject.new(square, "location_business_office_generic_01_16", false);
                        cabinet:createContainersFromSpriteProperties();
                        square:AddSpecialObject(cabinet);
                        if isClient() then cabinet:transmitCompleteItemToServer() end
                        triggerEvent("OnObjectAdded", cabinet)
                    end
                end
            end
        end

        modData["BarricadeRiverwoodPD:isBarricaded"] = true;
    end
end

Events.LoadGridsquare.Add(PlaceWindowBarricades.onloadgs);
