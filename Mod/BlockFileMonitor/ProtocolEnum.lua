--[[
Title: ProtocolEnum
Author(s): dummy
Date: 20170708
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/BlockFileMonitor/ProtocolEnum.lua");
local ProtocolEnum = commonlib.gettable("Mod.BlockFileMonitor.ProtocolEnum");
------------------------------------------------------------
]]

local ProtocolEnum = {};
local ProtocolEnum = commonlib.gettable("Mod.BlockFileMonitor.ProtocolEnum");

-- java call lua enum
ProtocolEnum.CREATE_NEW_WORLD = 101;
ProtocolEnum.BLOCK_DATA_TRANSFER = 102;
ProtocolEnum.LOAD_PRWORLD = 103;

-- lua call java enum
ProtocolEnum.OPEN_SDK_ACTIVITY = 1001;