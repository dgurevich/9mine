-- handle connection string received from attach tool
spawn_attach = function(player, fields)
    local addr, path, player = connect(player, fields)
    if addr and path and player then list_directory(addr, path, player) end
end
