--[[
Title: 
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/BlockFileMonitor/main.lua");
local BlockFileMonitor = commonlib.gettable("Mod.BlockFileMonitor");
------------------------------------------------------------
]]


NPL.load("(gl)Mod/BlockFileMonitor/BtCommand.lua");

local BtCommand = commonlib.gettable("Mod.BlockFileMonitor.BtCommand");
local BlockFileMonitor = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.BlockFileMonitor"));

function BlockFileMonitor:ctor()
end

-- virtual function get mod name

function BlockFileMonitor:GetName()
	return "BlockFileMonitor"
end

-- virtual function get mod description 

function BlockFileMonitor:GetDesc()
	return "BlockFileMonitor is a plugin in paracraft"
end

function BlockFileMonitor:init()
	LOG.std(nil, "info", "BlockFileMonitor", "plugin initialized");
	
	BtCommand:init();
end

function BlockFileMonitor:OnLogin()

end
-- called when a new world is loaded. 

function BlockFileMonitor:OnWorldLoad()
LOG.std(nil, "info", "BlockFileMonitor", "plugin BlockFileMonitor:OnWorldLoad ");

	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
end
-- called when a world is unloaded. 

function BlockFileMonitor:OnLeaveWorld()
end

function BlockFileMonitor:OnDestroy()
end

