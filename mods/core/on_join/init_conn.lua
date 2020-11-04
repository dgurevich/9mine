minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    if not connections[name] then connections[name] = {} end
    minetest.after(0.5, automount, player)
end)
