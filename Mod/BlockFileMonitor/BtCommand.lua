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

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local BtCommand = commonlib.inherit(nil,commonlib.gettable("Mod.BlockFileMonitor.BtCommand"));

function BtCommand:ctor()
end

function BtCommand:init()
	LOG.std(nil, "info", "BtCommand", "init");
	self:InstallCommand();
end

local cur_task;

function BtCommand:InstallCommand()
	Commands["setActorAnimation"] = {
		name="setActorAnimation", 
		quick_ref="/setActorAnimation [startFrame endFrame]", 
		desc=[[@param]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			if cur_task then
				local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
				local animId = CmdParser.ParseBlockId(cmd_text)
				
				cur_task:setMovieActorAnimId(animId);
			end
		end
			
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
				cur_task = task;
			end
		end,
	};
end
