-- handle connection string received from attach tool
youtube = function(player, formname, fields)
    local texture, rsp = next(fields)
    spawn_video(player, texture)
    minetest.close_formspec(player:get_player_name(), formname)
end
