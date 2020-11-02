plt.resize = function(root, slots, old_size, size, addr, path)
    local p1 = root
    local p2 = {x = p1.x + size, y = p1.y, z = p1.z + size}
    for z = p1.z, p2.z do
        for y = p1.y, p2.y do
            for x = p1.x, p2.x do
                if p1.x + old_size - x >= 0 and p1.z + old_size - z >= 0 then
                else
                local p = {x = x, y = y, z = z}
                minetest.add_node(p, {name = "core:plt"})
                local node = minetest.get_meta(p)
                node:set_string("addr", addr)
                node:set_string("path", path)
                table.insert(slots, p)
                end
            end
        end
    end
    table.shuffle(slots)
    return size
end