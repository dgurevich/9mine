minetest.register_on_chat_message(function(player_name, message)
    local player = minetest.get_player_by_name(player_name)
    local player_graph = graphs:get_player_graph(player_name)
    local platform = player_graph:get_platform(common.get_platform_string(player))
    if not platform then
        minetest.chat_send_player(player_name, "No platform found nearby")
        return true
    end
    local cmdchan = platform:get_cmdchan()
    if not cmdchan then
        return
    end
    local path = platform:get_path()
    local commands = core_conf:get("pcmd")
    local command = message:match("[^ ]+")
    if commands:match(command) then
        if message:match("| minetest$") then
            message = message:gsub("| minetest", "")
            local result = cmdchan:execute(message, path)
            cmdchan:show_response(result, player_name)
        elseif message:match(" | inventory$") then
            message = message:gsub("| inventory", "")
            local result = cmdchan:execute(message)
            common.add_ns_to_inventory(player, result)
        elseif message:match(" | man$") then
            message = message:gsub("| man", "")
            local response = cmdchan:execute(message)            
            local player_name = player:get_player_name()
            common.show_man(player_name, common.parse_man(response))
        else
            local result = cmdchan:execute(message, path)
            minetest.chat_send_player(player_name, result .. "\n")
            if result:match("^/") then
                result = result:gsub("\n", "")
                platform:spawn_path(result, player)
            end
        end
        return true
    end
end)

local man_event = function(player, formname, fields)
    if formname == "core:man" then
        if fields.quit then
            return
        end
        local player_name = player:get_player_name()
        local player = minetest.get_player_by_name(player_name)
        local player_graph = graphs:get_player_graph(player_name)
        local platform = player_graph:get_platform(common.get_platform_string(player))
        if not platform then
            minetest.chat_send_player(player_name, "No platform found nearby")
            return true
        end
        local cmdchan = platform:get_cmdchan()
        if not cmdchan then
            return
        end
        print(dump(fields))
        local k, v = next(fields)
        print(v)
        v = v:gsub("action:", "")
        print(v)
        local path = platform:get_path()
        local response = cmdchan:execute("man " .. v)    
        common.show_man(player_name, common.parse_man(response))
    end
end

register.add_form_handler("core:man", man_event)