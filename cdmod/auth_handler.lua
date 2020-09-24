minetest.register_on_authplayer(function(name, ip, is_success)
    if is_success then
    else
        local signer = config.signer_addr
        local lcmd = config.lcmd
        local rcmd = config.rcmd
        local ldir = config.ldir
        write_file(lcmd, "rm " .. ldir .. name .. "/password")
        authenticated = false
        cache[name] = {}
    end
end)
minetest.register_authentication_handler(
    {
        get_auth = function(name)
            local signer = config.signer_addr
            local lcmd = config.lcmd
            local rcmd = config.rcmd
            local ldir = config.ldir
            if authenticated == true then return cache[name] end
            -- check if password is in local storage 
            local success, password = pcall(read_file,
                                            ldir .. name .. "/password")
            -- if not, go to create_auth
            if success == false then return nil end
            -- try to authenticate with local password
            local response = getauthinfo(lcmd, signer, name, password)
            -- if not successfull, authentication fail
            if not string.match(response, "Auth ok") then
                write_file(lcmd, "echo rm " .. ldir .. name .. "/password")
                password = 'password'
            end
            local privs = {}
            if string.match(response, "Auth ok") then
                privs = get_privs(rcmd, name)
                authenticated = true
            end
            cache[name] = {
                password = password,
                privileges = privs,
                last_login = -1
            }
            return cache[name]
        end,

        create_auth = function(name, password)
            local signer = config.signer_addr
            local lcmd = config.lcmd
            local rcmd = config.rcmd
            local ldir = config.ldir
            local rnew = config.rnew

            -- check if user with given name already exists
            write_file(rcmd, "ls /users/" .. name)
            local exists = read_file(rcmd)
            print(exists)
            -- if exists, try to authenticate with minetest client provided password
            if string.match(exists, "does not exist") == nil then
                local response = getauthinfo(lcmd, signer, name, password)
                print("response from server: " .. response)
                -- if password is not match, authentication fails
                if not string.match(response, "Auth ok") then
                    minetest.after(2, minetest.kick_player, name)
                    authenticated = true
                    return {
                        password = 'password',
                        privileges = {},
                        last_login = -1
                    }
                end
                -- if user with not exists with a given name, create one. Authentication Ok.
            else
                write_file(lcmd, "mkdir " .. ldir .. name)
                write_file(lcmd, "touch " .. ldir .. name .. "/password")
                write_file(ldir .. name .. "/password", password)
                local privs = minetest.settings:get("default_privs")
                write_file(rnew, name .. " " .. password .. " " .. privs .. "")
                cache[name] = {
                    password = password,
                    privileges = minetest.string_to_privs(privs),
                    last_login = -1
                }
                authenticated = true
                return cache[name]
            end

        end,
        set_password = function(name, password)
            print("setting password failed")
        end,
        reload = function() return false end
    })

minetest.register_on_leaveplayer(function(ObjectRef, timed_out)
    local name = ObjectRef:get_player_name()
    authenticated = false
    cache[name] = {}
end)

