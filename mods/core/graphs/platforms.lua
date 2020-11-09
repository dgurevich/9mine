class 'platforms'

function platforms:platforms(graph)
    local platforms_graph = graph.open("platforms")
    self.graph = platforms_graph
    self.root_node = platforms_graph:node("platforms")
end

function platforms:get(platform_string)
    if platform_string then
        return self.graph:findnode(platform_string)
    else
        return self.graph
    end
end

function platforms:get_platform(platform_string)
    local platform_node = self:get(platform_string)
    if platform_node then
        return platform_node.object
    end
end

function platforms:get_root()
    return self.root_node
end

function platforms:add(platform, parent_platform)
    local platform_node = self.graph:node(platform.platform_string)
    platform_node.object = platform
    if not parent_platform then
        local host_node = self.graph:findnode(platform.conn.addr)
        self.graph:edge(host_node, platform_node)
    else
        self.graph:edge(parent_platform:get_node(), platform_node)
    end
    return platform_node
end

function platforms:add_host(attach_string)
    local host_node = self.graph:node(attach_string)
    self.graph:edge(self.root_node, host_node)
    return host_node
end
