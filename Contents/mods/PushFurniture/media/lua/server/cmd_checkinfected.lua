require 'lua_server_commands'

local pi2 = math.pi * 2.0

LuaServerCommands.register("checkinfected", function(author, command, args)
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
    if bodyDamage:IsInfected() == true then
        --print("checkinfected - Host is infected");

        local bodyParts = bodyDamage:getBodyParts();
        for i = 0, bodyParts:size() - 1 do
            local bodyPart = bodyParts:get(i);
            if bodyPart:IsInfected() == true then
                --print("checkinfected - Infected player: " .. --tostring(author) .. ". Infected body part" .. tostring(bodyPart));

                return "Infected player: " .. tostring(author) .. ". Infected body part" .. tostring(bodyPart);
            end
        end
    end

    --print("checkinfected - Uninfected player: " .. tostring(author));
    return "Uninfected player: " .. tostring(author);
end)
