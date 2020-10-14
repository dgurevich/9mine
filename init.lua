-- include libraries
socket = require 'socket'

-- include files 
local path = minetest.get_modpath("youtube")

-- load mod.conf settings
youtube_conf = Settings(path .. "/mod.conf")

-- entities
dofile(path .. "/entities/search.lua")
dofile(path .. "/entities/video.lua")

-- tools
dofile(path .. "/tools/youtube.lua")
dofile(path .. "/tools/youtube_connect.lua")

-- functions
dofile(path .. "/funcs/populate_inventory.lua")
dofile(path .. "/funcs/save_thumbnail.lua")
dofile(path .. "/funcs/show_thumbnails.lua")
dofile(path .. "/funcs/spawn_video.lua")
dofile(path .. "/funcs/blink.lua")
dofile(path .. "/funcs/list_youtube.lua")
dofile(path .. "/funcs/spawn_youtube.lua")


-- on player join
dofile(path .. "/on_join/inventory.lua")

-- events
dofile(path .. "/events/init.lua")
dofile(path .. "/events/video_id.lua")
dofile(path .. "/events/youtube.lua")
dofile(path .. "/events/youtube_connect.lua")
dofile(path .. "/events/youtube_search.lua")

-- entities 
dofile(path .. "/entities/video.lua")
dofile(path .. "/entities/search.lua")

-- chat commands
-- chat messages
-- 9p interactions
