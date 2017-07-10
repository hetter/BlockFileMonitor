--[[
Title: BtFileMonitorContext or CommandContext
Author(s): LiXizhi
Date: 2015/8/8
Desc: BtFileMonitorContext is also called CommandContext, since it is usually binded with a command object. 
Custom commands or tasks can redirect input to their own member functions with BtFileMonitorContext. 
Please note when context is deacticated, the command's OnExit will also be called. 
See SelectBlocksTask for example. 
By default, the redirect context does very little, and it will never modify the scene in anyway. 
Thus making it a good candicate base class to user defined scene context, besides BaseContext. 

virtual or redirected functions:
	mousePressEvent(event)
	mouseMoveEvent(event)
	mouseReleaseEvent(event)
	mouseWheelEvent(event)
	keyPressEvent(event)
	
	handleLeftClickScene(event, result)
	handleRightClickScene(event, result)
	handleMiddleClickScene(event, result)
	handlePlayerKeyEvent(event)
	OnLeftMouseHold(fDelta)
	OnRightMouseHold(fDelta)
	OnLeftLongHoldBreakBlock()
	UpdateManipulators()

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BtFileMonitorContext.lua");
-- usage one: subclass and provide your own handler
local MyContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.BtFileMonitorContext"), nil);
-- usage two: redirect event handler to another class
function cmdOrTaskInstance:mousePressEvent(event)
end
MyContext = Game.SceneContext.BtFileMonitorContext:new():RedirectInput(cmdOrTaskInstance);
-- activate this context
MyContext:activate();
-- switch back to default context. 
MyContext:close();
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BaseContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local BtFileMonitorContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.BtFileMonitorContext"));

BtFileMonitorContext:Property("Name", "BtFileMonitorContext");

function BtFileMonitorContext:ctor()
	self:EnableAutoCamera(true);
end

-- redirect input to a given command or task object. 
-- for example, cmd:keyPressEvent(event) will be called. 
function BtFileMonitorContext:RedirectInput(cmd)
	self.redirect_cmd = cmd;
	return self;
end

-- virtual function: 
-- try to select this context. 
function BtFileMonitorContext:OnSelect(lastContext)
	BtFileMonitorContext._super.OnSelect(self);
	self:EnableMousePickTimer(true);
end

-- the command object should use close() to deactivate. 
-- calling deactivate directly will also exit the associated command object. 
function BtFileMonitorContext:deactivate()
	if(BtFileMonitorContext._super.deactivate(self)) then
		if(not self.is_closing) then
			if(self.redirect_cmd and self.redirect_cmd.OnExit) then
				self.redirect_cmd:OnExit();
			end
		end
		return true;
	end
end

function BtFileMonitorContext:close()
	self.is_closing = true;
	local res = BtFileMonitorContext._super.close(self);
	self.is_closing = nil;
	return res;
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function BtFileMonitorContext:OnUnselect()
	BtFileMonitorContext._super.OnUnselect(self);
	return false;
end

-- return true if redirection occurs
function BtFileMonitorContext:RedirectEvent(eventName, event, ...)
	if(self.redirect_cmd and self.redirect_cmd[eventName] and not self.is_redirecting) then
		self.is_redirecting = true;
		self.redirect_cmd[eventName](self.redirect_cmd, event, ...);
		self.is_redirecting = false;
		return true;
	end
end


--virtual:
function BtFileMonitorContext:UpdateManipulators()
	return self:RedirectEvent("UpdateManipulators");
end

-- virtual: 
function BtFileMonitorContext:mousePressEvent(event)
	if(self:RedirectEvent("mousePressEvent", event)) then
		return;
	end
	BtFileMonitorContext._super.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function BtFileMonitorContext:handleItemMouseEvent(event)
	-- disable item event
end

function BtFileMonitorContext:handleItemKeyEvent(event)
	-- disable item event
end

-- virtual: 
function BtFileMonitorContext:mouseMoveEvent(event)
	if(self:RedirectEvent("mouseMoveEvent", event)) then
		return;
	end
	BtFileMonitorContext._super.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function BtFileMonitorContext:handleLeftClickScene(event, result)
	if(self:RedirectEvent("handleLeftClickScene", event, result)) then
		return;
	end
end

function BtFileMonitorContext:handleRightClickScene(event, result)
	if(self:RedirectEvent("handleRightClickScene", event, result)) then
		return;
	end
end

function BtFileMonitorContext:handleMiddleClickScene(event, result)
	if(self:RedirectEvent("handleMiddleClickScene", event, result)) then
		return;
	end
	return BtFileMonitorContext._super.handleMiddleClickScene(self, event);
end

function BtFileMonitorContext:OnLeftMouseHold(fDelta)
	if(self:RedirectEvent("OnLeftMouseHold", event)) then
		return;
	end
	local click_data = self:GetClickData();
	
	local last_x, last_y, last_z = click_data.last_mouse_down_block.blockX, click_data.last_mouse_down_block.blockY, click_data.last_mouse_down_block.blockZ;
	local result = self:CheckMousePick();
	
	if(result) then
		if(result.block_id) then
			click_data.last_mouse_down_block.blockX, click_data.last_mouse_down_block.blockY, click_data.last_mouse_down_block.blockZ = result.blockX,result.blockY,result.blockZ;
			local block = block_types.get(result.block_id);

			if(block) then
				self:UpdateClickStrength(fDelta, result);

				click_data.left_holding_time = click_data.left_holding_time + fDelta;

				if(click_data.strength and click_data.strength > self.max_break_time) then
					self:OnLeftLongHoldBreakBlock();
					click_data.left_holding_time = 0;
				end
			end
		elseif(result.blockX) then
			self:UpdateClickStrength(fDelta, result);
			click_data.left_holding_time = click_data.left_holding_time + fDelta;
		end
	end
end

function BtFileMonitorContext:OnRightMouseHold(fDelta)
	if(self:RedirectEvent("OnRightMouseHold", event)) then
		return;
	end
	local click_data = self:GetClickData();
	click_data.right_holding_time = click_data.right_holding_time + fDelta;
end

function BtFileMonitorContext:OnLeftLongHoldBreakBlock(fDelta)
	if(self:RedirectEvent("OnLeftLongHoldBreakBlock", event)) then
		return;
	end
end

-- virtual: 
function BtFileMonitorContext:mouseReleaseEvent(event)
	if(self:RedirectEvent("mouseReleaseEvent", event)) then
		return;
	end
	BtFileMonitorContext._super.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	if(self.is_click) then
		local result = Game.SelectionManager:GetPickingResult();
		if(event.mouse_button == "left") then
			self:handleLeftClickScene(event, result)
		elseif(event.mouse_button == "right") then
			self:handleRightClickScene(event, result);
		elseif(event.mouse_button == "middle") then
			self:handleMiddleClickScene(event, result);
		end
	end
end
-- virtual: 
function BtFileMonitorContext:mouseWheelEvent(event)
	if(self:RedirectEvent("mouseWheelEvent", event)) then
		return;
	end
	BtFileMonitorContext._super.mouseWheelEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

--virtual 
function BtFileMonitorContext:handlePlayerKeyEvent(event)
	if(self:RedirectEvent("handlePlayerKeyEvent", event)) then
		return event:isAccepted();
	end
	return BtFileMonitorContext._super.handlePlayerKeyEvent(self, event);
end

-- virtual: actually means key stroke. 
function BtFileMonitorContext:HandleGlobalKey(event)
	BtFileMonitorContext._super.HandleGlobalKey(self, event);
	if(event:isAccepted()) then
		return true;
	end
	
	event:accept();
	return true;	
end
