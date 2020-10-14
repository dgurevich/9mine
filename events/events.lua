minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "youtube:grid" then
            youtube_grid(player, formname, fields)
        end
        if formname == "youtube:connect" then
            youtube_connect(player, formname, fields)
        end
        if formname == "youtube:search" then
            youtube_search(player, formname, fields)
        end
    end)
