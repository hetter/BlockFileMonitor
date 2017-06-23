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
NPL.load("(gl)Mod/BlockFileMonitor/BtWorldConfig.lua");
NPL.load("(gl)Mod/BlockFileMonitor/BtFileMonitorTask.lua");

local BtCommand = commonlib.gettable("Mod.BlockFileMonitor.BtCommand");
local BtWorldConfig = commonlib.gettable("Mod.BlockFileMonitor.BtWorldConfig");
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
	
	BtWorldConfig:init();

	-- test
	--BlockFileMonitor.StartWorldFromMobile(key, value);
end

function BlockFileMonitor:OnLogin()

end

-- called when a new world is loaded. 
function BlockFileMonitor:OnWorldLoad()

end

-- called when a world is unloaded. 
function BlockFileMonitor:OnLeaveWorld()
end

function BlockFileMonitor:OnDestroy()
end

-- 从手机启动世界
function BlockFileMonitor.StartWorldFromMobile(key, value)
	--[[
	commonlib.echo("===========HandleCallback protoName:" .. "BtWorld_Response");
	if not LocalBridgePB_pb then
		NPL.load("(gl)script/mobile/NetWork/LocalBridgePB_pb.lua")
	end
	-- BtWorld_Response 仍未定义
	local rsp = LocalBridgePB_pb["BtWorld_Response"]();
	rsp:ParseFromString(value)
	-- create a raw data table as returned message
	local raw_rsp = ParseRawDataFromProtoMsg(rsp);
	
	commonlib.echo("===========HandleCallback protoName:" .. raw_rsp.worldId);
	
	local worldId = raw_rsp.worldId;
	local worldStep = raw_rsp.worldStep;
	--]]
	
	local worldId = 1;
	local worldStep = 1;	
	local worldsCfg = BtWorldConfig:getCfg("BtWorldConfig.csv");
	local worldCfg = worldsCfg[worldId];
	
	NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	WorldCommon.OpenWorld(worldCfg.path, true);	

	local BtFileMonitorTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.BtFileMonitorTask");
	BtFileMonitorTask.setStoryConfig(worldCfg.storys, worldStep - 1);
end