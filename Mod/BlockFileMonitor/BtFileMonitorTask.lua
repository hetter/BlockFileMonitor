--[[
Title: For files from blue tooth. 
Author(s): LiXizhi
Date: 2013/1/26
Desc: Drag and drop *.block.xml block template file to game to create blocks where it is. 
when the file changes, the block is automatically updated. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockFileMonitorTask.lua");
local task = MyCompany.Aries.Game.Tasks.BtFileMonitorTask:new({filename="worlds/DesignHouse/blockdisk/box.blocks.xml", cx=nil, cy=nil, cz = nil })
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local BtFileMonitorTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BtFileMonitorTask"));

-- this is always a top level task. 
BtFileMonitorTask.is_top_level = true;

-- end tag
BtFileMonitorTask.EndBlockId = 12

local cur_instance;

function BtFileMonitorTask:ctor()
end

function BtFileMonitorTask.RegisterHooks()
	local self = cur_instance;
	self:LoadSceneContext();
end

function BtFileMonitorTask.UnregisterHooks()
	local self = cur_instance;
	if(self) then
		self:UnloadSceneContext();
	end
end

function BtFileMonitorTask:Run()
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end

	cur_instance = self;
	
	if(not self.filename or not ParaIO.DoesFileExist(self.filename)) then
		return
	end

	local bx, by, bz = EntityManager.GetPlayer():GetBlockPos();
	self.cx = self.cx or bx;
	self.cy = self.cy or by;
	self.cz = self.cz or bz;
	

	BtFileMonitorTask.mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		BtFileMonitorTask.OnUpdateBlocks();
	end})
	BtFileMonitorTask.mytimer:Change(0, 200);

	BtFileMonitorTask.finished = false;
	BtFileMonitorTask.RegisterHooks();
	BtFileMonitorTask.isSkipEnd = true;
	BtFileMonitorTask.ShowPage();
end


function BtFileMonitorTask:OnExit()
	if not BtFileMonitorTask.isSkipEnd then
		BtFileMonitorTask.EndEditing();
	end	
end


-- @param bCommitChange: true to commit all changes made 
function BtFileMonitorTask.EndEditing(bCommitChange)
	BtFileMonitorTask.finished = true;
	BtFileMonitorTask.ClosePage()
	BtFileMonitorTask.UnregisterHooks();
	if(cur_instance) then
		local self = cur_instance;
		cur_instance = nil
	end
	if(BtFileMonitorTask.mytimer) then
		BtFileMonitorTask.mytimer:Change();
		BtFileMonitorTask.mytimer = nil;
	end
end

function BtFileMonitorTask:mousePressEvent(event)
end

function BtFileMonitorTask:mouseMoveEvent(event)
end

function BtFileMonitorTask:mouseReleaseEvent(event)
end

function BtFileMonitorTask:keyPressEvent(event)
	local dik_key = event.keyname;

	if(dik_key == "DIK_ESCAPE")then
		-- exit editing mode without commit any changes. 
		BtFileMonitorTask.EndEditing(false);
	elseif(dik_key == "DIK_DELETE" or dik_key == "DIK_DECIMAL")then
		BtFileMonitorTask.DeleteAll()
	end	
end

function BtFileMonitorTask:FrameMove()
end

------------------------
-- page function 
------------------------
local page;
function BtFileMonitorTask.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "Mod/BlockFileMonitor/BtFileMonitorTask.html", 
			name = "BtFileMonitorTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false, 
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = false,
			click_through = true,
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 80,
				width = 128,
				height = 512,
		});
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
end

function BtFileMonitorTask.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function BtFileMonitorTask.OnInit()
	NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
	page = document:GetPageCtrl();
end

function BtFileMonitorTask.RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function BtFileMonitorTask.DoClick(name)
	local self = cur_instance;
	if(not self) then
		return
	end 

	if(name == "camera_up") then
		self.dy = 1;
		BtFileMonitorTask.OnUpdateBlocks()
	elseif(name == "camera_down") then
		self.dy = -1;
		BtFileMonitorTask.OnUpdateBlocks()
	elseif(name == "delete") then
		BtFileMonitorTask.isSkipEnd = false;
		BtFileMonitorTask.DeleteAll()
	--[[	
	elseif(name == "save_template") then
		if(self.blocks) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
			local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
			BlockTemplatePage.ShowPage(true, self.blocks);
		end
	--]]	
	end
end

function BtFileMonitorTask.DeleteAll()
	local self = cur_instance;
	if(not self) then
		return
	end 

	self.filename = nil;

	local cx, cy, cz = self.cx, self.cy, self.cz;
	local blocks = self.blocks or {};
	local _, b;
	for _, b in ipairs(blocks) do
		if(b[1]) then
			local x, y, z = cx+b[1], cy+b[2], cz+b[3];
			BlockEngine:SetBlock(x,y,z, 0);
		end
	end
	BtFileMonitorTask.EndEditing();
end

function BtFileMonitorTask.OnUpdateBlocks()
	local self = cur_instance;
	if(not self) then
		return
	end 
	
	--[[ TODO: detect file change
	local sInitDir = self.filename:gsub("([^/\\]+)$", "");
	sInitDir = sInitDir:gsub("\\", "/");
	local filename = self.filename:match("([^/\\]+)$");
	
	if(not filename) then
		return;
	end

	local search_result = ParaIO.SearchFiles(sInitDir,filename, "", 0, 1, 0);
	local nCount = search_result:GetNumOfResult();		
	local i;
	if(nCount>=1)  then
		local item = search_result:GetItemData(0, {});
		local date = item.writedate;
	end
	]]

	local xmlRoot = ParaXML.LuaXML_ParseFile(self.filename);
	if(xmlRoot) then
		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
		if(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]);
			local isEndBlock = false;
			
			
			-- bbaa的面积
			local boxLenth = 8;
			-- add aabb unvisible block
			local aabb_block_min_inx = #blocks + 1;
			blocks[aabb_block_min_inx] = {};
			blocks[aabb_block_min_inx][1] = boxLenth; --x
			blocks[aabb_block_min_inx][2] = 0; --y
			blocks[aabb_block_min_inx][3] = boxLenth; --z 
			blocks[aabb_block_min_inx][4] = 0; --id
			
			local aabb_block_max_inx = #blocks + 1;
			blocks[aabb_block_max_inx] = {};
			blocks[aabb_block_max_inx][1] = -boxLenth; --x
			blocks[aabb_block_max_inx][2] = boxLenth; --y
			blocks[aabb_block_max_inx][3] = -boxLenth; --z 
			blocks[aabb_block_max_inx][4] = 0; --id
						
			if(blocks and #blocks > 0) then
				self.cy = self.cy + (self.dy or 0);
				local cx, cy, cz = self.cx, self.cy, self.cz;
				local last_blocks = self.blocks or {};
								
				blocks.map = {};
				last_blocks.map = last_blocks.map or {};
				local _, b
				
				-- 算出最小高度
				local checkLeastHigh = 0;
				for _, b in ipairs(blocks) do
					if(b[2]) then
						if b[2] < checkLeastHigh then
							checkLeastHigh = b[2];
						end
					end
				end		
				
				for _, b in ipairs(blocks) do
					while true do
						if(b[1]) then
							

							
							-- 微调
							b[1] = b[1] + 5;
							b[3] = b[3] - 2;
							b[2] = b[2] - checkLeastHigh; -- 保持高度不插地
							
							local x, y, z = cx+b[1], cy+b[2], cz+b[3];
							
							local sparse_index =x*30000*30000+y*30000+z;
							local new_id = b[4] or 96;
							
							-- 如果有重复，忽略aabb透明方块
							if _ == aabb_block_min_inx or _ == aabb_block_max_inx then
								if blocks.map[sparse_index] and blocks.map[sparse_index] ~= 0 then								
									break;
								end
							end						
							
							if b[5] == BtFileMonitorTask.EndBlockId then
								isEndBlock = true;
							end	
							
							blocks.map[sparse_index] = new_id;

							if(last_blocks.map[sparse_index] ~= new_id) then
								BlockEngine:SetBlock(x,y,z, new_id, b[5], nil, b[6]);
							end
						end
						break;
					end
				end
				
				if(self.dy) then
					cy = cy - self.dy;
					self.dy = nil;
				end
				for _, b in ipairs(last_blocks) do
					if(b[1]) then
						local x, y, z = cx+b[1], cy+b[2], cz+b[3];
						local sparse_index =x*30000*30000+y*30000+z;
						if(not blocks.map[sparse_index]) then
							BlockEngine:SetBlock(x,y,z, 0);
						end
					end
				end

				self.blocks = blocks;
				if(#blocks~=self.block_count) then
					self.block_count = #blocks;
					if(page) then
						-- 减去aabb的两个透明顶点方块
						page:SetValue("blockcount", self.block_count - 2);
					end
				end
			end
			
			if isEndBlock then
				GameLogic.GetFilters():apply_filters("BtFileMonitorTask_End", self.blocks);

				
				local fromEntity = EntityManager.GetPlayer();
				self.activeX = self.activeX or 19036;
				self.activeY = self.activeY or 5;
				self.activeZ = self.activeZ or 19506;				
				local block = BlockEngine:GetBlock(self.activeX, self.activeY, self.activeZ);
				if(block) then
					block:OnActivated(self.activeX, self.activeY, self.activeZ, fromEntity);
				end
				
				BtFileMonitorTask.isSkipEnd = false;
				BtFileMonitorTask.DeleteAll();				
			end

		end
	end

end
