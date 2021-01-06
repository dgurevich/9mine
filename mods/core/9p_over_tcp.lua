class 'np_over_tcp'

-- initialize connection object with basic connection information
function np_over_tcp:np_over_tcp(attach_string, player_name)
    local addr, prot, host, port = parse_attach_string(attach_string)
    -- tcp socket on which 9p messages are transmitted
    self.tcp = nil
    -- 9p object generated by 9p.lua lib
    self.conn = nil
    self.addr = addr
    self.prot = prot
    self.host = host
    self.port = port
    self.player_name = player_name
end

function np_over_tcp:attach()
    local tcp = socket:tcp()
    self.tcp = tcp
    if not self.host or not self.port then
        if self.player_name then
            minetest.chat_send_player(self.player_name, "No host or port provided")
        end
        return false
    end
    local result, err = tcp:connect(self.host, self.port)
    if not result then
        print("Connection error to " .. self.addr .. ": " .. err)
        if self.player_name then
            minetest.chat_send_player(self.player_name, "Connection error to " .. self.addr .. ": " .. err)
        end
        return false
    end
    local conn = np.newconn(function(size)
        local size, err = tcp:receive(size)
        if err then
            print(err)
            return false
        end
        return size
    end, function(buf)
        tcp:send(buf)
    end)
    self.conn = conn
    conn:attach("root", "")
    if self.player_name then
        minetest.chat_send_player(self.player_name, "Attached to " .. self.addr)
    end
    print("Attached to " .. self.addr)
    return self
end

function np_over_tcp:reattach()
    self.tcp:close()
    print("Disconnected from " .. self.addr)
    self:attach()
end

function np_over_tcp:close()
    self.tcp:close()
end

function np_over_tcp:is_alive()
    local conn = self.conn
    local f = conn:newfid()
    local result = pcall(np.clone, conn, conn.rootfid, f)
    if result then
        conn:clunk(f)
    end
    return result
end

function np_over_tcp:set_cmdchan(cmdchan)
    self.cmdchan = cmdchan
end

function np_over_tcp:get_cmdchan()
    return self.cmdchan
end
-- parses string in form of '<protocol>!<hostname>!<port_number>'
parse_attach_string = function(attach_string)
    if not attach_string then return end 
    local info = {}
    for token in attach_string:gmatch("[^!]+") do
        table.insert(info, token)
    end
    local prot = info[1]
    local host = info[2]
    local port = tonumber(info[3])
    return attach_string, prot, host, port
end
