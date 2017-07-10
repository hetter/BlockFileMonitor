--[[
Title: Touch controller
Author(s): LiXizhi
Date: 2014/9/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/LogiTowerTouchController.lua");
local LogiTowerTouchController = commonlib.gettable("MyCompany.Aries.Game.GUI.LogiTowerTouchController");
LogiTowerTouchController.ShowPage(true);
LogiTowerTouchController.SwitchTouchMouseMode(true);
-- check touch key pressed
LogiTowerTouchController.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchButton.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolManager.lua");
local PlayerController = commonlib.gettable("MyCompany.Aries.Game.PlayerController")
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local ToolManager = commonlib.gettable("MyCompany.Aries.Game.Tools.ToolManager");
local TouchSceneController = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchSceneController");
local TouchButton = commonlib.gettable("MyCompany.Aries.Game.Common.TouchButton")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local LogiTowerTouchController = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GUI.LogiTowerTouchController"));


-- default to 10 pixels
local default_finger_size = 10;
-- default to 300 ms. 
local default_min_hold_time = 300;
-- touch key states that can be queried externally. 
local touch_key_states = {};
-- ms seconds to auto hide the UI when it is not used for some time. 
local touch_ui_auto_hide_time = 5000;
local last_touch_event_time;

local page;

function LogiTowerTouchController:ctor()
	-- tool manager
	ToolManager:InitSingleton();

	-- touch selector
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/TouchSelection.lua");
	local TouchSelection = commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelection");
	TouchSelection:InitSingleton();
	-- touch select bar
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/TouchSelectionBar.lua");
	local TouchSelectionBar = commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelectionBar");
	TouchSelectionBar:InitSingleton();
	
	self.Connect(TouchSelection, TouchSelection.SelectionChanged, TouchSelectionBar, TouchSelectionBar.OnSelectionChanged);
		
	-- register all tool actions
	self.actions = {};
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchDefaultMode.lua");
	self.actions["default"] = ToolManager:RegisterTool(MyCompany.Aries.Game.Tools.ToolTouchDefaultMode:new());
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchPen.lua");
	self.actions["pen"] = ToolManager:RegisterTool(MyCompany.Aries.Game.Tools.ToolTouchPen:new());
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchPick.lua");
	self.actions["pick"] = ToolManager:RegisterTool(MyCompany.Aries.Game.Tools.ToolTouchPick:new());
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchSelect.lua");
	self.actions["select"] = ToolManager:RegisterTool(MyCompany.Aries.Game.Tools.ToolTouchSelect:new());
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolTouchErase.lua");
	self.actions["erase"] = ToolManager:RegisterTool(MyCompany.Aries.Game.Tools.ToolTouchErase:new());

	self.Connect(ToolManager, ToolManager.SelectedToolChanged, self, self.SetSelectedTool);
	self:TriggerAction("default");
end

function LogiTowerTouchController:OnKeyDown(dik_key)
	local tab_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_TAB);
	if(tab_pressed) then
		if(dik_key == "DIK_1") then
			LogiTowerTouchController:TriggerAction("erase");
		elseif(dik_key == "DIK_2") then
			LogiTowerTouchController:TriggerAction("pick");
		elseif(dik_key == "DIK_3") then
			LogiTowerTouchController:TriggerAction("select");
		elseif(dik_key == "DIK_4") then
			LogiTowerTouchController:TriggerAction("pen");
		elseif(dik_key == "DIK_TAB") then
			LogiTowerTouchController:TriggerAction("default");
		end
		return true;
	end
end

function LogiTowerTouchController:GetAction(name)
	if(name) then
		return self.actions[name];
	end
end

function LogiTowerTouchController:TriggerAction(name)
	local action = self.actions[name];
	if(action) then
		action:trigger();
	end
end

-- tool name to button name. Refactor this!
local tool_to_button = {
	["ToolTouchErase"] = "del", 
	["ToolTouchPick"] = "alt", 
	["ToolTouchSelect"] = "ctrl", 
	["ToolTouchPen"] = "shift", 
}

function LogiTowerTouchController:GetButtonNameByTool(tool)
	if(tool) then
		return tool_to_button[tool:GetName()];
	end
end

function LogiTowerTouchController:SetSelectedTool(tool)
	if (self.selectedTool == tool) then
		return;
	end
	if (self.selectedTool) then
		-- deselect old
		self.UpdateKeyButton(self:GetButtonNameByTool(self.selectedTool), false);
	end
	if (tool) then
		self.selectedTool = tool;
		-- select new
		self.UpdateKeyButton(self:GetButtonNameByTool(tool), true);
	end
end

function LogiTowerTouchController.Init()
	LogiTowerTouchController:InitSingleton();
	page = document:GetPageCtrl();
	GameLogic.events:AddEventListener("game_mode_change", LogiTowerTouchController.OnGameModeChanged, LogiTowerTouchController, "LogiTowerTouchController");
	GameLogic.events:AddEventListener("OnEditEntity", LogiTowerTouchController.OnEditEntity, LogiTowerTouchController, "LogiTowerTouchController");
	GameLogic.events:AddEventListener("System.SettingChange", LogiTowerTouchController.OnSettingChange, LogiTowerTouchController, "LogiTowerTouchController");
	GameLogic:Connect("WorldLoaded", LogiTowerTouchController, LogiTowerTouchController.OnWorldLoaded, "UniqueConnection")
end

function LogiTowerTouchController:OnWorldLoaded()
	LogiTowerTouchController:InitSingleton();
	LogiTowerTouchController:TriggerAction("default");
end

-- whether to automatically show/hide the controller. 
function LogiTowerTouchController.SetAutoShowHide(bAutoShow)
	if(not LogiTowerTouchController.timer) then
		LogiTowerTouchController.timer = commonlib.Timer:new({callbackFunc = LogiTowerTouchController.OnTimer})
	end
	if(bAutoShow) then
		LogiTowerTouchController.timer:Change(500, 500);
	else
		LogiTowerTouchController.timer:Change();
	end
end

function LogiTowerTouchController.GetLastTouchEventTime()
	if(last_touch_event_time) then
		return last_touch_event_time;
	else
		last_touch_event_time = commonlib.TimerManager.GetCurrentTime();
		return last_touch_event_time;
	end
end

function LogiTowerTouchController.SetLastTouchEventTime(curTime)
	last_touch_event_time = curTime or commonlib.TimerManager.GetCurrentTime();
	if(LogiTowerTouchController.IsSleeping()) then
		-- wake it up when touch event arrives. 
		LogiTowerTouchController.SetSleepingMode(false);
	end
end

function LogiTowerTouchController.IsSleeping()
	return LogiTowerTouchController.bIsSleeping;
end

function LogiTowerTouchController.SetSleepingMode(bEnable)
	LogiTowerTouchController.bIsSleeping = bEnable;
	if(page) then
		local parent = page:GetParentUIObject();
		if(parent and parent:IsValid()) then
			if(bEnable) then
				parent.colormask = "255 255 255 128";
			else
				parent.colormask = "255 255 255 255";
			end
			parent:CallField("ApplyColorMask");
		end
	end
end

function LogiTowerTouchController.OnSettingChange()
	if(GameLogic.IsStarted) then
		LOG.std(nil, "info", "LogiTowerTouchController", "slate mode change event received");
		LogiTowerTouchController.OnTimer();
	end
end

-- this is mostly used by Intel 2in1 touch pad. We will detect if mouse is available or not, and adjust UI to mouse or touch dynamically. 
function LogiTowerTouchController.SwitchTouchMouseMode(bIsTouchMode)
	if(bIsTouchMode) then
		LogiTowerTouchController.ShowPage(true);
	else
		LogiTowerTouchController.ShowPage(false);
	end
end


function LogiTowerTouchController.OnTimer()
	if(System.options.IsMobilePlatform) then
		-- TODO: fade away if not active for a long time ? 
		if( (commonlib.TimerManager.GetCurrentTime() - LogiTowerTouchController.GetLastTouchEventTime()) > touch_ui_auto_hide_time and not LogiTowerTouchController.IsSleeping()) then
			LogiTowerTouchController.SetSleepingMode(true);
		end
	else
		local bHasDevice = GameLogic.options:HasTouchDevice();
		if(not bHasDevice and page and page:IsVisible()) then
			-- hide touch UI
			LogiTowerTouchController.SwitchTouchMouseMode(false);
		elseif(bHasDevice and (not page or not page:IsVisible())) then
			-- show touch UI
			if(not GameLogic.GameMode:IsMovieMode()) then
				LogiTowerTouchController.SwitchTouchMouseMode(true);	
			end
		end
	end
end

-- @param blocks: block list 
function LogiTowerTouchController.ShowPage(bShow)

	PlayerController:SetFlyUsingCameraDir(not bShow);

	local params = {
			url = "Mod/BlockFileMonitor/LogiTowerTouchController.html", 
			name = "PC.LogiTowerTouchController", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = false,
			bShow = bShow,
			zorder = -10,
			click_through = true, 
			cancelShowAnimation = true,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

-- @param keycode: such as DIK_SCANCODE.DIK_LSHIFT, DIK_SCANCODE.DIK_LCONTROL
function LogiTowerTouchController.IsKeyPressed(keycode)
	return touch_key_states[keycode];
end

function LogiTowerTouchController.SetKeyPressed(keycode, bPressed)
	touch_key_states[keycode] = bPressed;
end

-- when entity editor page is shown, we will hide controller. 
function LogiTowerTouchController:OnEditEntity(events)
	if(page) then
		if(page:IsVisible()) then 
			if(events.isBegin) then
				LogiTowerTouchController.ShowPage(false);
			end
		else
			if(not events.isBegin) then
				LogiTowerTouchController.ShowPage(true);
			end
		end
	end
end

function LogiTowerTouchController:RefreshPage(delayTime)
	if(page) then
		page:Refresh(delayTime or 0.1);
	end
end

function LogiTowerTouchController:OnGameModeChanged(events)
	if(page) then
		if(page:IsVisible()) then 
			if(GameLogic.GameMode:ShouldHideTouchController()) then
				LogiTowerTouchController.ShowPage(false);
			else
				LogiTowerTouchController:RefreshPage();
			end
		else
			if(not GameLogic.GameMode:ShouldHideTouchController()) then
				LogiTowerTouchController.ShowPage(true);
			end
			LogiTowerTouchController:RefreshPage();
		end
	end
end

local function secrete_test()
	ParaEngine.GetAttributeObject():CallField("RecreateRenderer");
end

function LogiTowerTouchController.OnTouchFlyUp(name, mcmlNode, touch)
	if(not LogiTowerTouchController.touch_button_fly_up) then
		local function OnPressTick(self)
			local player = EntityManager.GetFocus();
			if(player)then
				if(not player:IsFlying()) then
					player:ToggleFly(true);
				end
				player:Jump();
			end
		end
		LogiTowerTouchController.touch_button_fly_up = TouchButton:new({
			OnTick = OnPressTick, OnTouchMove = OnPressTick, 
			OnTouchUp = function(self)
				local dx, dy = self:GetOffsetFromStartLocation();
				if(dy < -20 and GameLogic.GameMode:IsAllowGlobalEditorKey()) then
					-- go upstairs
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
					local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({mode="vertical", isUpward = true, add_to_history=false});
					task:Run();
					-- TODO: remove this
					-- secrete_test();
				end
			end,
		})
	end
	LogiTowerTouchController.touch_button_fly_up:OnTouchEvent(touch);
end

function LogiTowerTouchController.OnTouchFlyDown(name, mcmlNode, touch)
	if(not LogiTowerTouchController.touch_button_fly_down) then
		local function OnPressTick()
			local player = EntityManager.GetFocus();
			if(player) then 
				local bx, by, bz = player:GetBlockPos();
				local block = BlockEngine:GetBlock(bx, by-1, bz);
				if(block and block.id ~= 0) then
					player:ToggleFly(false);
					-- falling on ground sound
					SoundManager:Vibrate();
				else
					local obj = player:GetInnerObject();
					if(obj) then
						obj:ToCharacter():AddAction(action_table.ActionSymbols.S_FLY_DOWNWARD);
					end
				end
			end
		end
		LogiTowerTouchController.touch_button_fly_down = TouchButton:new({
			OnTick = OnPressTick, OnTouchMove = OnPressTick,
			OnTouchUp = function(self)
				local dx, dy = self:GetOffsetFromStartLocation();
				if(dy > 20 and GameLogic.GameMode:IsAllowGlobalEditorKey()) then
					-- go downstairs
					NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
					local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({mode="vertical", isUpward = false, add_to_history=false});
					task:Run();
				end
			end,
		})
	end
	LogiTowerTouchController.touch_button_fly_down:OnTouchEvent(touch);
end


-- @param name: "move_pad" or "camera_pad"
function LogiTowerTouchController.UpdateTouchPad(name, bIsPressed)
	if(page) then
		local ctl = page:FindUIControl(name);
		if(ctl) then
			local btnColor;
			if(bIsPressed) then
				btnColor = "255 255 255 72";
			else
				btnColor = "255 255 255 48";
			end
			_guihelper.SetUIColor(ctl, btnColor);
			for i=0, ctl:GetChildCount() do
				local child = ctl:GetChildAt(i);
				_guihelper.SetUIColor(child, btnColor);
			end
		end
	end
end

-- @param touch: like {type="WM_POINTERUPDATE",x=242,y=426,id=0,time=ms}
function LogiTowerTouchController.OnTouchMove(name, mcmlNode, touch)
	LogiTowerTouchController.SetLastTouchEventTime();
	if(not LogiTowerTouchController.touch_button_move) then
		LogiTowerTouchController.touch_button_move = TouchButton:new({
			OnTouchDown = function(self)
				LogiTowerTouchController.UpdateTouchPad("move_pad", true);
				local player = EntityManager.GetFocus(); 
				if(player) then 
					player:BeginTouchMove();
				end
				if(page) then
					local uiobj = page:FindControl("move_pad");
					if(uiobj) then
						local touch = self:GetStartTouch();
						-- suppose the finger size is 30 pixels
						local finger_size = 30;
						local x, y, width, height = uiobj:GetAbsPosition();
						local cx, cy = x + width*0.5, y + height*0.5;
						if(math.abs(touch.x-cx) > math.abs(touch.y-cy)) then
							if(touch.x > cx) then
								touch.x = math.max(cx, touch.x - finger_size);
							else
								touch.x = math.min(cx, touch.x + finger_size);
							end
						else
							if(touch.y > cy) then
								touch.y = math.max(cy, touch.y - finger_size);
							else
								touch.y = math.min(cy, touch.y + finger_size);
							end
						end
					end
				end
			end,
			OnTick = function(self)
				local player = EntityManager.GetFocus(); 
				if(player) then 
					local dx, dy = self:GetOffsetFromStartLocation();
					if((math.abs(dx)+math.abs(dy)) > 10) then
						local pos_angle = 0;
						if(dx == 0) then
							if(dy == 0) then
								return;
							end
							if(dy > 0) then
								pos_angle = math.pi;
							else
								pos_angle = 0;
							end
						else
							pos_angle = math.pi * 0.5 + math.atan(dy / dx);
							if(dx < 0) then
								pos_angle = pos_angle + math.pi;
							end
						end
						player:TouchMove(pos_angle);
					end
				end
			end, 
			OnTouchUp = function(self)
				LogiTowerTouchController.UpdateTouchPad("move_pad", false);
				local player = EntityManager.GetFocus(); 
				if(player) then 
					player:EndTouchMove();
				end
			end,
		})
	end
	LogiTowerTouchController.touch_button_move:OnTouchEvent(touch);
end

-- click time is smaller than 0.3 seconds, and the dragging distance is smaller than 10 pixels.
function LogiTowerTouchController.IsTouchClick(start_touch, end_touch)
	if(start_touch and end_touch and (end_touch.time - start_touch.time) < default_min_hold_time and 
		(not start_touch.max_delta or start_touch.max_delta < default_finger_size)) then
		return true;
	end
end

-- @param touch: like {type="WM_POINTERUPDATE",x=242,y=426,id=0,time=ms}
function LogiTowerTouchController.OnTouchCamera(name, mcmlNode, touch)
	LogiTowerTouchController.OnTouchScene(name, mcmlNode, touch);
	LogiTowerTouchController.SetLastTouchEventTime();
	if(touch.type == "WM_POINTERDOWN") then
		LogiTowerTouchController.UpdateTouchPad("camera_pad", true);
		LogiTowerTouchController.camera_start = touch;
	elseif(touch.type == "WM_POINTERUP") then
		LogiTowerTouchController.UpdateTouchPad("camera_pad", false);
		if(LogiTowerTouchController.IsTouchClick(LogiTowerTouchController.camera_start,touch)) then
			local player = EntityManager.GetPlayer();
			if(player and player:IsFlying()) then
				-- stop flying if we are flying
				player:ToggleFly(false);
			else
				GameLogic.DoJump();
			end
		end
		LogiTowerTouchController.camera_start = nil;
	end
end

function LogiTowerTouchController:GetCurrentTool()
	return self.selectedTool;
end

function LogiTowerTouchController.OnTouchScene(name, mcmlNode, touch)
	LogiTowerTouchController.SetLastTouchEventTime();
	local tool = LogiTowerTouchController:GetCurrentTool();
	if(tool) then
		tool:OnTouchScene(touch);
	end
end

function LogiTowerTouchController.OnTouchAlt(name, mcmlNode, touch)
	LogiTowerTouchController.SetLastTouchEventTime();
	if(not LogiTowerTouchController.touch_button_alt) then
		LogiTowerTouchController.touch_button_alt = TouchButton:new({
			OnTouchDown = function(self)
				LogiTowerTouchController:TriggerAction("pick");
			end,
			OnTouchUp = function(self)
				LogiTowerTouchController:TriggerAction("default");
			end,
		})
	end
	LogiTowerTouchController.touch_button_alt:OnTouchEvent(touch);
end

-- simulate the shift key on key board. 
-- sneaking action and mount on entities. 
function LogiTowerTouchController.OnTouchShift(name, mcmlNode, touch)
	LogiTowerTouchController.SetLastTouchEventTime();
	if(not LogiTowerTouchController.touch_button_shift) then
		LogiTowerTouchController.touch_button_shift = TouchButton:new({
			OnTouchDown = function(self)
				LogiTowerTouchController:TriggerAction("pen");
				-- LogiTowerTouchController.SetKeyPressed(DIK_SCANCODE.DIK_LSHIFT, true);
			end,
			OnTouchUp = function(self)
				LogiTowerTouchController:TriggerAction("default");
				-- LogiTowerTouchController.SetKeyPressed(DIK_SCANCODE.DIK_LSHIFT, false);
			end,
		})
	end
	LogiTowerTouchController.touch_button_shift:OnTouchEvent(touch);
end

function LogiTowerTouchController.OnTouchCtrl(name, mcmlNode, touch)
	LogiTowerTouchController.SetLastTouchEventTime();
	if(not LogiTowerTouchController.touch_button_ctrl) then
		LogiTowerTouchController.touch_button_ctrl = TouchButton:new({
			OnTouchDown = function(self)
				LogiTowerTouchController:TriggerAction("select");
				-- LogiTowerTouchController.SetKeyPressed(DIK_SCANCODE.DIK_LCONTROL, true);
			end,
			OnTouchUp = function(self)
				LogiTowerTouchController:TriggerAction("default");
				-- LogiTowerTouchController.SetKeyPressed(DIK_SCANCODE.DIK_LCONTROL, false);
			end,
		})
	end
	LogiTowerTouchController.touch_button_ctrl:OnTouchEvent(touch);
end

-- both undo/redo on the same button. 
function LogiTowerTouchController.OnTouchUndo(name, mcmlNode, touch)
	LogiTowerTouchController.SetLastTouchEventTime();
	if(not LogiTowerTouchController.touch_button_undo) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
		local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");

		LogiTowerTouchController.touch_button_undo = TouchButton:new({
			OnTouchDown = function(self)
				LogiTowerTouchController.UpdateKeyButton("undo", true);
			end,
			OnTouchUp = function(self)
				LogiTowerTouchController.UpdateKeyButton("undo", false);
				local dx, dy = self:GetOffsetFromStartLocation();
				if(dx > 50 or self:IsPressHold()) then
					-- gesture: press hold or slide right to redo
					if(GameLogic.GameMode:IsAllowGlobalEditorKey()) then
						UndoManager.Redo();
					end
				else
					-- any other gesture to undo
					if(GameLogic.GameMode:IsAllowGlobalEditorKey()) then
						UndoManager.Undo();
					end
				end
			end,
		})
	end
	LogiTowerTouchController.touch_button_undo:OnTouchEvent(touch);
end

function LogiTowerTouchController.OnClickTouchMode(name, mcmlNode, touch)
	if(not LogiTowerTouchController.touch_button_touch_mode) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
		local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");

		LogiTowerTouchController.touch_button_touch_mode = TouchButton:new({
			OnTouchDown = function(self)
				if(GameLogic.GameMode:IsAllowGlobalEditorKey()) then
					LogiTowerTouchController:TriggerAction("erase");
				end
			end,
			OnTouchUp = function(self)
				if(GameLogic.GameMode:IsAllowGlobalEditorKey()) then
					LogiTowerTouchController:TriggerAction("default");
				end
			end,
		})
	end
	LogiTowerTouchController.SetLastTouchEventTime();
	LogiTowerTouchController.touch_button_touch_mode:OnTouchEvent(touch);
end

-- update button and player animation according to button state. 
-- @param name: "del", "undo", "ctrl","shift", see html page for their definitions.
function LogiTowerTouchController.UpdateKeyButton(btnName, bIsPressed)
	if(not btnName) then
		return
	end
	local ctl = page:FindUIControl(btnName.."_inner");
	local ctl2 = page:FindUIControl(btnName.."_outer");
			
	if(ctl and ctl2) then
		if(bIsPressed) then
			_guihelper.SetUIColor(ctl, "255 255 255 200");
			_guihelper.SetUIColor(ctl2, "255 255 255 200");
		else
			_guihelper.SetUIColor(ctl, "255 255 255 80");
			_guihelper.SetUIColor(ctl2, "255 255 255 48");
		end
	end
	if(btnName == "del" or btnName == "undo" or btnName == "ctrl" or btnName == "alt" or btnName == "shift") then
		local player = EntityManager.GetPlayer();
		if(player and not player.ridingEntity) then
			if(bIsPressed) then
				-- bending
				player:SetAnimation(66);
			else
				player:SetAnimation(0);
			end
		end
	end
end