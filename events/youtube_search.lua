youtube_search = function(player, formname, fields)
    local ss = fields["search_string"]
    if (ss == "") or (not ss) then return end  
    local name = player:get_player_name()
    local a, path, player = plt_by_name(name)
    local node = graphs[name]:findnode(md5.sumhexa(a .. path))
    local rp = node.result_path

    file_write(a, node.ctl_path, name, ss)

    local req = get_entity(node.ctl_p)

    req:set_nametag_attributes({text = "Searching . . . "})
    req:set_acceleration({x = 0, y = -2, z = 0})
    req:set_velocity({x = 0, y = 1, z = 0})
    req:get_luaentity().search_string = ss

    minetest.after(0.5, chk_res, name, node, req)
end
