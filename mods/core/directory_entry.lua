class 'directory_entry'

-- object which encapsulates readdir entry
function directory_entry:directory_entry(stat)
    -- stat record from readdir 
    self.stat = table.copy(stat)
    -- attachment string, in form of prot!host!port
    self.addr = nil
    -- full path, starting with /, including entry name 
    self.path = nil
    -- position of corresponding entity in for of {x, y, z}
    self.pos = nil
    -- platform path in for of /parent/platform/path
    self.platform_path = nil
    -- address and path of parent directory in for of prot!host!port/path
    self.platform_string = nil
    -- address and path of entry itself in form of prot!host!port/path/file.name
    self.entry_string = nil
    -- reference to the node, which holds reference to the current entry (self)
    self.node = nil
end

-- Getters
function directory_entry:get_stat()
    return self.stat
end
function directory_entry:get_addr()
    return self.addr
end
function directory_entry:get_path()
    return self.path
end
function directory_entry:get_pos()
    return table.copy(self.pos)
end
function directory_entry:get_platform_path()
    return self.platform_path
end
function directory_entry:get_platform_string()
    return self.platform_string
end
function directory_entry:get_entry_string()
    return self.entry_string
end
function directory_entry:get_graph_entry_string()
    return self.entry_string .. self.stat.qid.path_hex
end

-- Additional getters
-- return qid as hex string
function directory_entry:get_qid()
    return self.stat.qid.path_hex
end

-- Setters
function directory_entry:set_stat(stat)
    self.stat = table.copy(stat)
    return self
end
function directory_entry:set_addr(addr)
    self.addr = addr
    return self
end
function directory_entry:set_pos(pos)
    self.pos = table.copy(pos)
    return self
end
function directory_entry:set_path(platform_path)
    self.path = platform_path == "/" and platform_path .. self.stat.name or platform_path .. "/" .. self.stat.name
    return self
end
function directory_entry:set_platform_path(platform_path)
    self.platform_path = platform_path
    return self
end
function directory_entry:set_platform_string(platform_string)
    self.platform_string = platform_string
    return self
end
function directory_entry:set_entry_string()
    self.entry_string = self.addr .. self.path
    return self
end

-- methods
function directory_entry:filter(stat_entity)
    local texture
    for index, f in pairs(filters) do
        texture = f(self, stat_entity)
    end
    if not texture then
        texture = "core_file.png"
        if self.stat.qid.type == 128 then
            texture = "core_dir.png"
        end
        stat_entity:set_properties({
            textures = {texture},
            nametag = self.stat.name
        })
    end
    local lua_entity = stat_entity:get_luaentity()
    lua_entity.texture = texture
    lua_entity.entry_string = self:get_entry_string()
    stat_entity:set_properties({
        nametag = self.stat.name
    })
    stat_entity:set_acceleration({
        x = 0,
        y = -9.81,
        z = 0
    })
    return self
end

function directory_entry:delete_node()
    if not self.node.object then
        self.node:delete()
        self.node = nil
    end
    return self
end

-- return new copy of current directory_entry
function directory_entry:copy()
    local new_directory_entry = directory_entry(self.stat)
    new_directory_entry.stat = self.stat
    new_directory_entry.addr = self.addr
    new_directory_entry.path = self.path
    new_directory_entry.pos = self.pos
    new_directory_entry.platform_path = self.platform_path
    new_directory_entry.platform_string = self.platform_string
    new_directory_entry.entry_string = self.entry_string
    new_directory_entry.node = self.node
    return new_directory_entry
end
