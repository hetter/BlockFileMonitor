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
	print("add_filter BtFileMonitorTask_End");
	GameLogic.GetFilters():add_filter("BtFileMonitorTask_End", function(blocks)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
		local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
		local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
		local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")		
		
		-- save to current world
		local name_normalized = "huojian";
		local fileName = format("%s%s.bmax", GameLogic.current_worlddir.."blocktemplates/", name_normalized);
		
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(x,y,z)
		local player_pos = string.format("%d,%d,%d",bx,by,bz);
				
		local params = {
			name = name_normalized,
			author_nid = System.User.nid,
			creation_date = ParaGlobal.GetDateFormat("yyyy-MM-dd").."_"..ParaGlobal.GetTimeFormat("HHmmss"),
			player_pos = player_pos,
			pivot = pivot,
			relative_motion = nil,
		}
		
		local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = fileName, params = params, blocks = blocks})
		task:Run();
		print("BlockTemplate save task run:" .. fileName);		


	end)
end
-- called when a world is unloaded. 

function BlockFileMonitor:OnLeaveWorld()
end

function BlockFileMonitor:OnDestroy()
end

