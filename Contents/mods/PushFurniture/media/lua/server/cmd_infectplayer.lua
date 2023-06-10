require 'lua_server_commands'

local pi2 = math.pi * 2.0

LuaServerCommands.register("infectplayer", function(author, command, args)
    -- Check if the correct number of arguments are passed.
    if #args ~= 1 then
        return "/testcmd [player]";
    end

    -- NOTE: The helper only becomes visible in global scope when the first lua server command is fired.
    --       Make sure to reference the helper inside of the command's handler function.
    local helper = LuaServerCommandHelper;

    -- Attempt to resolve the player using the helper method.
    local username = args[1];
    local player = helper.getPlayerByUsername(username);
    if player == nil then
        --print("checkinfected - Player not found: " .. tostring(username));
        return "Player not found: " .. tostring(username)
    end

    local bodyDamage = player:getBodyDamage();
    bodyDamage:setInfected(true);
    bodyDamage:setInfectionMortalityDuration(0.75);
    bodyDamage:setInfectionTime(5);
    bodyDamage:setInfectionLevel(50);

    --print("checkinfected - Host is infected");

    local bodyParts = bodyDamage:getBodyParts();
    for i = 0, bodyParts:size() - 1 do
        if (i == 0) then
            local bodyPart = bodyParts:get(i);
            bodyPart:SetInfected(true);

            --print(tostring(bodyPart) .. " is infected");
        end
    end

    --print("checkinfected - Infected player: " .. tostring(author));
    return "Infected player: "
        .. tostring(author);
end)
