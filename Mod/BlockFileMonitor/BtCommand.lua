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

function BtCommand:InstallCommand()
	Commands["bluetoothfilemonitor"] = {
		name="bluetoothfilemonitor", 
		quick_ref="/bluetoothfilemonitor [x y z] [filename]", 
		desc=[[monitor a given file
	@param activeX activeY activeZ:active the block when the building is end
	@param x y z: center block position where to show the block content, if not provided, it is the block where the player is standing
	@param filename: default to "temp/blocks.stream.xml", this can be relative to root or world directory. 
	Example:
	/bluetoothfilemonitor     :block at player position
	/bluetoothfilemonitor ~ ~1 ~ temp/blocks.stream.xml    :relative to player position. 
	/bluetoothfilemonitor blocktemplates/test.bmax :monitor a bmax file
		]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)			
			local ax, ay, az, x, y, z, filename;
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
				local task = MyCompany.Aries.Game.Tasks.BtFileMonitorTask:new({filename=filename, activeX=ax, activeY=ay, activeZ=az})
				task:Run();
			end
		end,
	};
end
