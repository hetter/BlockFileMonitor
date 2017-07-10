--[[
Title: bluetooth monitor
Author(s): dummy
Date: 20170607
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/BlockFileMonitor/main.lua");
local BlockFileMonitor = commonlib.gettable("Mod.BlockFileMonitor");
------------------------------------------------------------
]]

-- 把一个字符串分割成数组
local function split(szFullString, szSeparator)   
	local nFindStartIndex = 1   
	local nSplitIndex = 1   
	local nSplitArray = {}   
	while true do   
	   local nFindLastIndex, endIndex= string.find(szFullString, szSeparator, nFindStartIndex)   
	   if not nFindLastIndex then   
	    nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))   
	    break   
	   end   
	   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)   
	   nFindStartIndex = endIndex + 1;   
	   nSplitIndex = nSplitIndex + 1   
	end   
	return nSplitArray   
end

-- 把字符串转换成数组，并用itemConvertFunc转换所有元素
local function toArray(szSeparator , itemConvertFunc)
	return function(str)
		local strs = split(str , szSeparator)
		if itemConvertFunc then
			local items = {}
			for i , v in ipairs(strs) do
				table.insert(items , itemConvertFunc(v))
			end
			return items;
		else
			return strs;
		end
	end
end

-- 把字符串转换成数值数组
local function _toMultiArray(startIndex , ...)
	local arg = {...}
	if #arg == startIndex then
		local desc = arg[startIndex];
		return toArray(desc.sep , desc.converter);
	else	
		local function run(str)
			local desc = arg[startIndex];
			local item = split(str , desc.sep)
			local index = startIndex + 1;	
			for ii , vv in ipairs(item) do
				item[ii] = _toMultiArray(index , unpack(arg))(vv);
			end
		
			return item;
		end
		return run;
	end
end

-- 把字符串转换成多维数组
local function toStringArray(...)
	local arg = {...}
	local numArg = {};
	for i , v in ipairs(arg) do
		numArg[i] = {sep = v , converter = nil};
	end
	return _toMultiArray(1 , unpack(numArg));
end

-- 把字符串转换成数值数组
local function toNumberArray(...)
	local arg = {...}
	local numArg = {};
	for i , v in ipairs(arg) do
		numArg[i] = {sep = v , converter = tonumber};
	end
	return _toMultiArray(1 , unpack(numArg));
end



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

function BlockFileMonitor:initProtoclFunc()

	NPL.load("(gl)Mod/BlockFileMonitor/ProtocolEnum.lua");
	local ProtocolEnum = commonlib.gettable("Mod.BlockFileMonitor.ProtocolEnum");
		
	local function createFreeWorld(pId, worldName)
		
		local worlds_template = {
			-- this is pure block world with "flat" generator
			{name = L"积木世界", world_path = "worlds/Templates/Empty/flatsandland",icon = "", world_generator = "flat", seed = nil, },
		};
		
		local templ_world = worlds_template[1];
		
		local world_name = worldName;
		world_name = world_name:gsub("[%s/\\]", "");
		
		local world_name_locale = commonlib.Encoding.Utf8ToDefault(world_name);
		
		if(world_name == "") then
			_guihelper.MessageBox(L"世界名字不能为空, 请输入世界名称");
			return
		elseif(string.len(world_name) > 20) then
			_guihelper.MessageBox(L"世界名字太长了, 请重新输入");
			return
		end
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");
		local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")

		local params = {
			-- since world name is used as the world path name, we will only use letters as filename. 
			--worldname = ParaGlobal.GetDateFormat("yyMMdd").."_"..ParaGlobal.GetTimeFormat("Hmmss").."_"..string.gsub(world_name, "%W", ""),
			worldname = world_name_locale,
			title = world_name,
			creationfolder = CreateNewWorld.GetWorldFolder(),
			parentworld = templ_world.world_path,
			world_generator = "superflat",
			seed = templ_world.seed or world_name,
			inherit_scene = true,
			inherit_char = true,
		}
		
		LOG.std(nil, "info", "CreateNewWorld", params);

		local worldpath, error_msg = CreateNewWorld.CreateWorld(params);
		
		if(not worldpath) then
			if(error_msg) then
				commonlib.echo(error_msg);
			end
		else
			NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
			local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")			
			WorldCommon.OpenWorld(worldpath, true);
		end	
	end
	
	NPL.load("(gl)script/mobile/API/local_service_wrapper.lua");
	
	LocalService.RegisterProtocolCallBacks(ProtocolEnum.CREATE_NEW_WORLD, createFreeWorld);
	
	
	local function blockDataTransfer(pId, blockData)
		commonlib.echo("=====================blockData:" .. tostring(blockData));
	end
	LocalService.RegisterProtocolCallBacks(ProtocolEnum.BLOCK_DATA_TRANSFER, blockDataTransfer);
	
	-- 从手机启动世界
	local function startWorldFromMobile(pId, worldData)
	
		local dataArray = toNumberArray("_")(worldData);
		
		local worldId = dataArray[1];
		local worldStep = dataArray[1];
		
		NPL.load("(gl)Mod/BlockFileMonitor/main.lua");
		
		NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
		
		local BtFileMonitorTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.BtFileMonitorTask");
		
		if worldId == -1 then	
			WorldCommon.OpenWorld("worlds/DesignHouse/default_world", true);	
			BtFileMonitorTask.setStoryConfig();
		else
		
			local BtWorldConfig = commonlib.gettable("Mod.BlockFileMonitor.BtWorldConfig");
			local worldsCfg = BtWorldConfig:getCfg("BtWorldConfig");
			local worldCfg = worldsCfg[worldId];

			commonlib.echo("worldCfg.path:"..worldCfg.path);
			WorldCommon.OpenWorld(worldCfg.path, true);	

			BtFileMonitorTask.setStoryConfig(worldCfg.storys, worldStep - 1);
		end
	end
	LocalService.RegisterProtocolCallBacks(ProtocolEnum.LOAD_PRWORLD, startWorldFromMobile);	
end

function BlockFileMonitor:init()
	LOG.std(nil, "info", "BlockFileMonitor", "plugin initialized");
	
	BtCommand:init();
	
	BtWorldConfig:init();

	self:initProtoclFunc();
	-- test
	--BlockFileMonitor.StartWorldFromMobile(key, value);
end

function BlockFileMonitor:OnLogin()

end

-- called when a new world is loaded. 
function BlockFileMonitor:OnWorldLoad()
	commonlib.echo("===========BlockFileMonitor:OnWorldLoad");
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/LogiTowerTouchController.lua");
	local TouchController = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchController");
	TouchController.ShowPage(false);
	
	NPL.load("(gl)script/mobile/paracraft/Areas/SystemMenuPage.lua");
	local SystemMenuPage = commonlib.gettable("ParaCraft.Mobile.Desktop.SystemMenuPage");
	SystemMenuPage.ShowPage(false);
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
	local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
	QuickSelectBar.ShowPage(false);
	
	TouchController.ShowPage = function()
	end
	SystemMenuPage.ShowPage = function()
	end
	QuickSelectBar.ShowPage = function()
	end	
	
	--NPL.load("(gl)Mod/BlockFileMonitor/BtFileMonitorContext.lua");
	--self.sceneContext = Game.SceneContext.BtFileMonitorContext:new();
	--self.sceneContext:activate();
	--self.sceneContext:UpdateManipulators();	
	
	NPL.load("(gl)Mod/BlockFileMonitor/LogiTowerTouchController.lua");
	local LogiTowerTouchController = commonlib.gettable("MyCompany.Aries.Game.GUI.LogiTowerTouchController");
	LogiTowerTouchController.ShowPage(true);
	
	return true;	
end

function BlockFileMonitor:OnInitDesktop()
	commonlib.echo("===========BlockFileMonitor:OnInitDesktop");
end

-- called when a world is unloaded. 
function BlockFileMonitor:OnLeaveWorld()
end

function BlockFileMonitor:OnDestroy()
end