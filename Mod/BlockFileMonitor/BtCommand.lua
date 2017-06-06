--[[
Title: BtCommand
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/BlockFileMonitor/BtCommand.lua");
local BtCommand = commonlib.gettable("Mod.BlockFileMonitor.BtCommand");
------------------------------------------------------------
]]
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local BtCommand = commonlib.inherit(nil,commonlib.gettable("Mod.BlockFileMonitor.BtCommand"));

function BtCommand:ctor()
end

function BtCommand:init()
	LOG.std(nil, "info", "BtCommand", "init");
	self:InstallCommand();
end

function BtCommand:startModelFileMovie(blocks)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
	local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")		

	-- save to current world
	local name_normalized = self.replaceModelFileName or "huojian.bmax";
	local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
	local fileName = format("%s%s", GameLogic.current_worlddir.."blocktemplates/", name_normalized);

	local x, y, z = ParaScene.GetPlayer():GetPosition();
	local bx, by, bz = BlockEngine:block(x,y,z)
	local player_pos = string.format("%d,%d,%d",bx,by,bz);
			
	local params = {}

	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = fileName, params = params, blocks = blocks})
	task:Run();
	
	print("BlockTemplate save task run:" .. fileName);	

	local fromEntity = EntityManager.GetPlayer();
	self.activeX = self.activeX or 19036;
	self.activeY = self.activeY or 5;
	self.activeZ = self.activeZ or 19506;				
	local block = BlockEngine:GetBlock(self.activeX, self.activeY, self.activeZ);
	if(block) then
		block:OnActivated(self.activeX, self.activeY, self.activeZ, fromEntity);
	end	
end

function BtCommand:InstallCommand()
	Commands["setActiveMovie"] = {
		name="setActiveMovie", 
		quick_ref="/setActiveMovie [activeX activeY activeZ]", 
		desc=[[@param activeX activeY activeZ:active the block when the building is end]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)			
			local ax, ay, az;
			local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
			ax, ay, az, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			self.activeX = ax;
			self.activeY = ay;
			self.activeZ = az;
		end,
	};
	
	Commands["setChangeBuildFile"] = {
		name="setChangeBuildFile", 
		quick_ref="/setChangeBuildFile [filename]", 
		desc=[[]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)			
			local filename;
			local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
			filename, cmd_text = CmdParser.ParseString(cmd_text);
			self.replaceModelFileName = filename;
		end,
	};
	
	Commands["bluetoothfilemonitor"] = {
		name="bluetoothfilemonitor", 
		quick_ref="/bluetoothfilemonitor [x y z] [filename]", 
		desc=[[monitor a given file
	
	@param x y z: center block position where to show the block content, if not provided, it is the block where the player is standing
	@param filename: default to "temp/blocks.stream.xml", this can be relative to root or world directory. 
	Example:
	/bluetoothfilemonitor     :block at player position
	/bluetoothfilemonitor ~ ~1 ~ temp/blocks.stream.xml    :relative to player position. 
	/bluetoothfilemonitor blocktemplates/test.bmax :monitor a bmax file
		]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)			
			local x, y, z, filename;
			local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
			ax, ay, az, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			
			x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			--if(not x) then
			--	local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
			--	x, y, z = EntityManager.GetPlayer():GetBlockPos();
			--end
			
			filename, cmd_text = CmdParser.ParseString(cmd_text);
			filename = filename or "temp/blocks.stream.xml"
			if(not ParaIO.DoesFileExist(filename)) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
				local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
				filename = Files.GetWorldFilePath(filename)
			end

			if(filename) then
				NPL.load("(gl)Mod/BlockFileMonitor/BtFileMonitorTask.lua");
				
				local task = MyCompany.Aries.Game.Tasks.BtFileMonitorTask:new({filename=filename})
				task:Run();
			end
		end,
	};
end
