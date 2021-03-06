class 'common'
function common.set_look(player, destination)
    local d = vector.direction(player:get_pos(), destination)
    player:set_look_vertical(-math.atan2(d.y, math.sqrt(d.x * d.x + d.z * d.z)))
    player:set_look_horizontal(-math.atan2(d.x, d.z))
end

function common.goto_platform(player, pos)
    if not pos then return end
    local destination = table.copy(pos)
    pos.x = pos.x - 2
    pos.y = pos.y + 1
    pos.z = pos.z - 2
    player:set_pos(pos)
    common.set_look(player, destination)
end

function common.get_platform_string(player)
    local player_pos = player:get_pos()
    if not player_pos then return nil, "Error" end
    local node_pos = minetest.find_node_near(player:get_pos(), 6, {"core:platform"})
    if not node_pos then return end
    local area = area_store:get_areas_for_pos(node_pos, false, true)
    local value = select(2, next(area))
    if not value then
        minetest.chat_send_player(player:get_player_name(),
                                  "No platform for this position in AreaStore")
        return
    end
    return value.data
end

function common.get_platform_string_by_pos(player, pos)
    if not pos then return nil, "Error" end
    local area = area_store:get_areas_for_pos(pos, false, true)
    local value = select(2, next(area))
    if not value then
        minetest.chat_send_player(player:get_player_name(),
                                  "No platform for this position in AreaStore")
        return
    end
    return value.data
end

function common.qid_as_key(dir)
    if not dir or type(dir) == "string" then return end
    local new_dir = {}
    for _, stat in pairs(dir) do new_dir[stat.qid.path_hex] = stat end
    return new_dir
end

function common.name_as_key(dir)
    local new_dir = {}
    for _, stat in pairs(dir) do new_dir[stat.name] = stat end
    return new_dir
end

function common.path_to_table(path)
    local i = 1
    local paths = {}
    if path:match("^/") then table.insert(paths, 1, "/") end
    while true do
        i = path:find("/", i + 1)
        if not i then
            table.insert(paths, 1, path)
            break
        end
        table.insert(paths, 1, path:sub(1, i - 1))
    end
    return paths
end

function common.send_warning(player_name, warning)
    minetest.chat_send_player(player_name, warning)
    minetest.show_formspec(player_name, "core:warning",
                           table.concat({"formspec_version[3]", "size[10,2,false]",
        "label[0.5,0.5;" .. minetest.formspec_escape(warning) .. "]",
        "button_exit[7,1.0;2.5,0.7;close;close]"}, ""))
end

function common.flight(entity, directory_entry)
    local to = directory_entry:get_pos()
    local from = entity:get_pos()
    local dir = vector.direction(from, to)
    local fast_dir = vector.multiply(dir, 20)
    fast_dir.y = fast_dir.y + 9
    entity:set_acceleration({x = 0, y = -9, z = 0})
    entity:set_velocity(fast_dir)
    minetest.after(0.5, common.flight_correction, entity, to, directory_entry)
end

-- correct flying path during mv/cp commands
function common.flight_correction(entity, to, directory_entry)
    entity:set_properties({nametag = directory_entry.stat.name})
    local current_pos = entity:get_pos()
    local distance = vector.distance(current_pos, to)
    if distance < 3 then
        entity:set_velocity(vector.new())
        local final_dst = {x = to.x, y = to.y + 2, z = to.z}
        entity:set_pos(final_dst)
        directory_entry:filter(entity)
        return
    end
    local dir = vector.direction(current_pos, to)
    local speed = distance > 5 and 20 or 8
    local fast_dir = vector.multiply(dir, speed)
    fast_dir.y = fast_dir.y + 9
    entity:set_acceleration({x = 0, y = -9, z = 0})
    entity:set_velocity(fast_dir)
    minetest.after(0.3, common.flight_correction, entity, to, directory_entry)
end

function common.hex(value) return md5.sumhexa(value):sub(1, 16) end

function common.table_length(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function common.show_info(player_name, info)
    -- minetest.chat_send_player(player_name, warning)
    minetest.show_formspec(player_name, "core:info",
                           table.concat({"formspec_version[3]", "size[10,2,false]",
        "label[0.5,0.5;" .. minetest.formspec_escape(info) .. "]",
        "button_exit[7,1.0;2.5,0.7;close;close]"}, ""))
end

function common.show_wait_notification(player_name, info)
    -- minetest.chat_send_player(player_name, warning)
    minetest.show_formspec(player_name, "core:info",
                           table.concat({"formspec_version[4]", "size[10,3,false]",
        "hypertext[0.5,0.5;9,2;;<big><center>Hello ", player_name, "\n",
        minetest.formspec_escape(info), "<center><big>]"}))
end

-- finds core:platform nearby (in radius of 1) and reads it's platform_string from metadata
function common.get_platform_string_near(entity, player)
    local node_pos = minetest.find_node_near(entity:get_pos(), 1, {"core:platform"})
    if not node_pos then
        minetest.chat_send_player(player:get_player_name(), "No platform found")
        return
    end
    local meta = minetest.get_meta(node_pos)
    return meta:get_string("platform_string")
end

function common.add_ns_to_inventory(player, result)
    local inventory = player:get_inventory()
    local ns = ItemStack("core:ns_node")
    local ns_meta = ns:get_meta()
    ns_meta:set_string("ns", result)
    ns_meta:set_string("description", result)
    inventory:add_item("main", ns)
end

-- Shows absolute path of the platform nearby
-- in right lower corner
function common.update_path_hud(player, id, addr_id, bg_id, tools)
    local platform_string, error = common.get_platform_string(player)
    if error then return end
    local player_graph = graphs:get_player_graph(player:get_player_name())
    if not player_graph then
        minetest.after(1, common.update_path_hud, player, id, addr_id, bg_id)
        return
    end
    local platform = player_graph:get_platform(platform_string)
    if not platform_string or not platform then
        if id then
            if tools then
            local inventory = player:get_inventory()
            for i, tool in pairs(tools) do
                if inventory:contains_item("main", tool) then
                    inventory:set_stack("main", i, "")
                end
            end
            inventory = player:get_inventory()
            local inv_size = inventory:get_size("main")
            -- move tools from inventory end to inventory start
            for i = 1, inv_size, 1 do
                if inventory:get_list("main")[i]:is_empty() then
                    for j = inv_size, i + 1, -1 do
                        if not inventory:get_list("main")[j]:is_empty() then
                            local stack = inventory:get_stack("main", j)
                            inventory:set_stack("main", j, "")
                            inventory:set_stack("main", i, stack)
                            break
                        end
                    end
                end
            end
        end
            player:hud_remove(bg_id)
            player:hud_remove(id)
            player:hud_remove(addr_id)
            id = nil
        end
    else
        tools = platform:get_toolset()
        local inventory = player:get_inventory()
        for i, tool in pairs(tools) do
            if not inventory:contains_item("main", tool) then
                print(i, "stack setting", tool)
                local stack = inventory:get_stack("main", i)
                inventory:set_stack("main", i, tool)
                inventory:add_item("main", stack)
            end
        end
        if id then
            player:hud_change(bg_id, "number", (#platform.addr) > (#platform.path)
                                  and (#platform.addr) or (#platform.path))
            player:hud_change(addr_id, "text", platform.addr)
            player:hud_change(addr_id, "offset", {x = -(#platform.addr * 10), y = 20})
            player:hud_change(id, "text", platform.path)
            player:hud_change(id, "offset", {x = -(#platform.path * 10) - 5, y = 60})
        else
            id = player:hud_add({
                hud_elem_type = "text",
                position = {x = 1, y = 0},
                offset = {x = -(#platform.path * 10) - 5, y = 60},
                text = platform.path,
                number = 0x00FF00,
                size = {x = 2},
                scale = {x = 100, y = 100}
            })

            addr_id = player:hud_add({
                hud_elem_type = "text",
                position = {x = 1, y = 0},
                offset = {x = -(#platform.addr * 10), y = 20},
                text = platform.addr,
                number = 0x00FF00,
                size = {x = 2},
                scale = {x = 100, y = 100}
            })

            bg_id = player:hud_add({
                hud_elem_type = "statbar",
                z_index = -400,
                direction = 1,
                number = (#platform.addr) > (#platform.path) and (#platform.addr) or (#platform.path),
                position = {x = 1, y = 0},
                size = {x = 45, y = 85},
                text = "core_hud_bg.png"
            })
        end
    end
    minetest.after(1, common.update_path_hud, player, id, addr_id, bg_id, tools)
end

function common.read_registry_index(connection_string, player_name)
    local connection
    if player_name then
        connection = connections:get_connection(player_name, connection_string, true)
    else
        connection = np_over_tcp(connection_string, player_name)
        connection = connection:attach()
    end
    if connection then return np_prot.file_read(connection.conn, "index") end
end

function common.parse_registry_index(registry_index)
    local services = {}
    for token in registry_index:gmatch("[^\n]+") do
        local service = {}
        service.service_addr = token:match("[^ ]+")
        local args = token:gsub(token:match("[^ ]+"):gsub("%%", "%%%%"):gsub("%-", "%%%-"):gsub(
            "%(", "%%%("):gsub("%)", "%%%)"):gsub("%.", "%%%."):gsub("%?", "%%%?")
            :gsub("%*", "%%%*"):gsub("%+", "%%%+"):gsub("%[", "%%%["):gsub("%]", "%%%]"):gsub("%^",
                                                                                              "%%%^")
            :gsub("%$", "%%%$"), "", 1):gsub("^%s+", ""):gsub("''", "$_/\\@")
        local key = true
        local previous
        while (#args > 0) do
            if args:sub(1, 1):match("^'") then
                if key then
                    previous = args:match("^'[^']+'"):gsub("'", ""):gsub("$_/\\@", "'")
                    key = false
                else
                    service[previous] = args:match("^'[^']+'"):gsub("'", ""):gsub("$_/\\@", "'")
                    key = true
                end
                args = args:gsub(args:match("^'[^']+'"):gsub("%%", "%%%%"):gsub("%-", "%%%-"):gsub(
                    "%(", "%%%("):gsub("%)", "%%%)"):gsub("%.", "%%%."):gsub("%?", "%%%?"):gsub(
                    "%*", "%%%*"):gsub("%+", "%%%+"):gsub("%[", "%%%["):gsub("%]", "%%%]"):gsub(
                    "%^", "%%%^"):gsub("%$", "%%%$"), "", 1):gsub("^%s+", "")
            else
                if key then
                    previous = args:match("^[^ ]+")
                    key = false
                else
                    service[previous] = args:match("^[^ ]+")
                    key = true
                end
                args = args:gsub(args:match("^[^ ]+"):gsub("%%", "%%%%"):gsub("%-", "%%%-"):gsub(
                    "%(", "%%%("):gsub("%)", "%%%)"):gsub("%.", "%%%."):gsub("%?", "%%%?"):gsub(
                    "%*", "%%%*"):gsub("%+", "%%%+"):gsub("%[", "%%%["):gsub("%]", "%%%]"):gsub(
                    "%^", "%%%^"):gsub("%$", "%%%$"), "", 1):gsub("^%s+", "")
            end
        end
        table.insert(services, service)
    end
    return services
end

function common.filter_registry_by_type(object, type)
    local formspec_table_string = ""
    local objects = {}
    for _, entry in pairs(object) do
        if entry.type == type then
            formspec_table_string = formspec_table_string == "" and entry.service_addr
                                        or formspec_table_string .. "," .. entry.service_addr
            table.insert(objects, entry)
        end
    end
    return objects, formspec_table_string
end

function common.filter_registry_by_keyword(object, keyword)
    local formspec_table_string = ""
    local objects = {}
    for _, entry in pairs(object) do
        local flag = false
        for key, value in pairs(entry) do
            if key:match(keyword) or value:match(keyword) then flag = true end
        end
        if flag then
            formspec_table_string = formspec_table_string == "" and entry.service_addr
                                        or formspec_table_string .. "," .. entry.service_addr
            table.insert(objects, entry)
        end
    end
    return objects, formspec_table_string
end

function common.icon_from_url(service)
    if not texture.exists(common.hex(service.service_addr) .. ".png", "registry") then
        texture.download(service.icon, service.icon:match("https://") and true or false,
                         common.hex(service.service_addr) .. ".png", "registry")
    end
    return common.hex(service.service_addr) .. ".png"
end

function common.icon_from_9p(service, player_name)
    if not texture.exists(common.hex(service.service_addr) .. ".png", "registry") then
        local connection = connections:get_connection(player_name, common.get_env("GRIDFILES_ADDR"),
                                                      true)
        if connection then
            local result = texture.download_from_9p(connection.conn, '/9mine/registry/logo/'
                                                        .. service.service_addr,
                                                    common.hex(service.service_addr) .. ".png",
                                                    "registry")
            if result then return common.hex(service.service_addr) .. ".png" end
        end
    else
        return common.hex(service.service_addr) .. ".png"
    end
end

function common.parse_man(manpage)
    manpage = manpage:gsub("\n ", "\n<style color=#00ffffff size=1>.</style>        "):gsub("%[",
                                                                                            "\\%[")
        :gsub("%]", "\\%]"):gsub(";", "\\;")
    local links = {}
    for token in manpage:gmatch("[%a%-%d]+%(%d%)") do links[token] = true end
    for k in pairs(links) do
        manpage = manpage:gsub(k:gsub("%(", "%%%("):gsub("%)", "%%%)"):gsub("%-", "%%%-"),
                               "<action name=" .. k .. ">" .. k .. "</action>")
    end
    return manpage
end

function common.show_man(player_name, manpage)
    minetest.show_formspec(player_name, "core:man",
                           table.concat({"formspec_version[4]", "size[14,13,false]",
        "hypertext[0.5, 0.5; 13.0, 11.0;;`", "<global background=#FFFFea color=black><big>",
        manpage, "</big>`]", "button_exit[11, 11.8;2.5,0.7;close;close]"}, ""))
end

-- parses string in form of '<protocol>!<hostname>!<port_number>'
common.parse_attach_string = function(attach_string)
    if not attach_string then return end
    local info = {}
    for token in attach_string:gmatch("[^!]+") do table.insert(info, token) end
    local prot = info[1]
    local host = info[2]
    local port = tonumber(info[3])
    return attach_string, prot, host, port
end

function common.get_env(env) return os.getenv(env) ~= "" and os.getenv(env) or core_conf:get(env) end
