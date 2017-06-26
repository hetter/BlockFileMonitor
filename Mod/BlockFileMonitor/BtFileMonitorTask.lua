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
-- fbx tag
BtFileMonitorTask.FbxBlockWheelId = 13

BtFileMonitorTask.FbxModelConfig = 
{
[BtFileMonitorTask.FbxBlockWheelId] = 
{
	id = BtFileMonitorTask.FbxBlockWheelId;
	--modelPath = "blocktemplates/wheel.bmax";
	modelPath = "../blocktemplates/boywalk.fbx";
	scale = 1;
};

}

local cur_instance;

local cur_storycfg;

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

function GetActorFromItemName(self, itemDefaultName, bCreateIfNotExist)	
	for i, actor in pairs(self.actors) do
		local nameVariable = actor:GetVariable("name");
		if nameVariable then
			local defaultName = nameVariable:getDefaultValue();
			if defaultName == itemDefaultName then
				return actor;
			end
		end
	end

	if(bCreateIfNotExist) then		
		local function getStackDefaultVariable(itemStack, keyname)
			local timeseries = itemStack:GetDataField("timeseries");
			local nameVariable = timeseries[keyname];
			if nameVariable then
				local defaultName = nameVariable.data[1];
				return defaultName;
			end
		end
		
		local inventory = self.entity.inventory;
		for i=1, inventory:GetSlotCount() do
			local itemStack = inventory:GetItem(i);
			if(itemStack and itemStack.count>0) then
				local defaultName = getStackDefaultVariable(itemStack, "name");
				if defaultName == itemDefaultName then
					local item = itemStack:GetItem();
					if(item and item.CreateActorFromItemStack) then
						local actor = item:CreateActorFromItemStack(itemStack, self.entity);
						if(actor) then
							self:AddActor(actor);
							return actor;
						end
					end	
				end
			end
		end
	end
end

function BtFileMonitorTask:startModelFileMovie(blocks)
	if not cur_storycfg then
		return;
	end	
		
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
	local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")		

	-- save to current world	
	local name_normalized = cur_storycfg.bmaxFileName;
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
	
	--[[
	self.activeX = self.activeX or 19036;
	self.activeY = self.activeY or 5;
	self.activeZ = self.activeZ or 19506;				
	local block = BlockEngine:GetBlock(self.activeX, self.activeY, self.activeZ);
	if(block) then
		block:OnActivated(self.activeX, self.activeY, self.activeZ, fromEntity);
	end	
	--]]
	
	
	local ax = cur_storycfg.moviePos[1];
	local ay = cur_storycfg.moviePos[2];
	local az = cur_storycfg.moviePos[3];
	
	local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
	
	local movieEntity = BlockEngine:GetBlockEntity(ax,ay,az);
	if(movieEntity) then
		local movieClip = movieEntity:GetMovieClip();
		
		
		for ii, vv in ipairs(BtFileMonitorTask.boneModels) do
			local itemStack = movieClip:CreateNPC();
			BtFileMonitorTask.pushAddItemStack(itemStack);
			local actor = movieClip:GetActorFromItemStack(itemStack, true);
			actor.entity:SetModelFile(vv.config.modelPath);
			actor:SaveStaticAppearance();
			
			local keyname = "parent";
			local result = cur_storycfg.bmaxActorName .. "::bones::";
			
			result = result .. "," .. vv.x .. "," .. vv.y .. ","  .. vv.z;
			--actor_model::bones::,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000
			local v = {};
			local target, trans = result:match("^([^,]+)[,%s]*(.*)");
			target = target or "";
			v.target = target;
			local old_x,old_y,old_z, old_roll, old_pitch, old_yaw;
			if(trans) then
				local vars = CmdParser.ParseNumberList(trans, nil, "|,%s");
				if(vars and vars[1] and vars[2] and vars[3]) then
					v.pos = {vars[1], vars[2], vars[3]}
					if(vars[4] and vars[5] and vars[6]) then
						v.rot = {vars[4], vars[5], vars[6]}	
					end
				end
			end
			if(not v.pos and target~="") then
				old_x,old_y,old_z = actor:GetPosition();
				old_roll, old_pitch, old_yaw = actor:GetRollPitchYaw();
			end
			if(target=="") then
				-- this will automatically add a key frame, when link is removed. 
				actor:KeyTransform();
			else
				v.pos = v.pos or {0,0,0};
				v.rot = v.rot or {0,0,0};
			end
			actor:AddKeyFrameByName(keyname, nil, v);			
		end	
		
		local mainActor = GetActorFromItemName(movieClip, cur_storycfg.bmaxActorName, true);
		mainActor:AddKeyFrameByName("scaling", 0, 32.5);
		mainActor:AddKeyFrameByName("assetfile", 0, "blocktemplates/" .. cur_storycfg.bmaxFileName);
		
		movieClip:RefreshActors();
		
		-- 播放电影
		local block = BlockEngine:GetBlock(cur_storycfg.activePos[1], cur_storycfg.activePos[2], cur_storycfg.activePos[3]);
		if block then
			block:OnActivated(cur_storycfg.activePos[1], cur_storycfg.activePos[2], cur_storycfg.activePos[3], fromEntity);
		end
	end	
end

-- 通过电影命令行给模型设置动画
function BtFileMonitorTask:setMovieActorAnimId(animId)
	if cur_storycfg then
		local ax = cur_storycfg.moviePos[1];
		local ay = cur_storycfg.moviePos[2];
		local az = cur_storycfg.moviePos[3];
		
		local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
		
		local movieEntity = BlockEngine:GetBlockEntity(ax,ay,az);
		if(movieEntity) then
			local movieClip = movieEntity:GetMovieClip();	
			
			for k, itemStack in ipairs(BtFileMonitorTask.dynamicInventory) do
				local animActor = movieClip:GetActorFromItemStack(itemStack, true);	
				local curTime = animActor:GetTime();
				animActor:AddKeyFrameByName("anim", curTime + 1, animId);
			end	
		end
	end	
end

function BtFileMonitorTask:Run()
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end
	
	local isStoryMode = true;
	
	if isStoryMode then
		BtFileMonitorTask.clearFbxModelData();
		-- 设置下一个情节的参数	
		BtFileMonitorTask.setNextStoryConfig();
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

function BtFileMonitorTask.setStoryConfig(storys, worldStep)
	local BtWorldConfig = commonlib.gettable("Mod.BlockFileMonitor.BtWorldConfig");
	local storyConfig = BtWorldConfig:getCfg("BtStoryConfig")[storys[worldStep]];
	BtFileMonitorTask.nowStep = worldStep;
	BtFileMonitorTask.storys = storys;
	cur_storycfg = storyConfig;
end

-- 保存额外模型相关配置
function BtFileMonitorTask.pushBoneModel(config, x, y, z)
	table.insert(BtFileMonitorTask.boneModels, {config = config, x = x, y = y, z = z});
end

-- 保存额外模型的电影演员ItemStack
function BtFileMonitorTask.pushAddItemStack(itemStack)
	table.insert(BtFileMonitorTask.dynamicInventory, itemStack);
end

-- fbx模型连接数据清理
function BtFileMonitorTask.clearFbxModelData()
	BtFileMonitorTask.boneModels = {};
	if cur_storycfg and BtFileMonitorTask.dynamicInventory then	
		local ax = cur_storycfg.moviePos[1];
		local ay = cur_storycfg.moviePos[2];
		local az = cur_storycfg.moviePos[3];	
		
		-- 清除上个电影方块中,用于连接骨骼的额外模型演员
		local movieEntity = BlockEngine:GetBlockEntity(ax,ay,az);

		if movieEntity then
			local inventory = movieEntity.inventory;
			
			for k, itemStack in ipairs(BtFileMonitorTask.dynamicInventory) do
				
				local slot_index;
				for i=(3), (inventory:GetSlotCount()) do
					local slots = inventory.slots;
					local item = slots[i];
					if(item and item == itemStack and item.count>0) then
						slot_index = i;
						break;
					end
				end

				inventory:RemoveItem(slot_index);
			end
		end
	end
	BtFileMonitorTask.dynamicInventory = {};	
end	

-- 设置下个情节的配置
function BtFileMonitorTask.setNextStoryConfig()
	if BtFileMonitorTask.nowStep and BtFileMonitorTask.storys then
		local nowStep = BtFileMonitorTask.nowStep + 1;
		local storys = BtFileMonitorTask.storys;
		if storys[nowStep] then
			local BtWorldConfig = commonlib.gettable("Mod.BlockFileMonitor.BtWorldConfig");
			local storyConfig = BtWorldConfig:getCfg("BtStoryConfig")[storys[nowStep]];
			BtFileMonitorTask.nowStep = nowStep;
			BtFileMonitorTask.storys = storys;
			cur_storycfg = storyConfig;				
		end
	end	
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
				local blockInx, b
				
				-- 算出最小高度
				local checkLeastHigh = 0;
				for blockInx, b in ipairs(blocks) do
					if(b[2]) then
						if b[2] < checkLeastHigh then
							checkLeastHigh = b[2];
						end
					end
				end		
				
				-- 1,2,3 x,y,z 坐标
				-- 4 材质ID
				-- 5 硬件ID
				for blockInx, b in ipairs(blocks) do
					while true do
						if(b[1]) then							
							-- 微调
							--b[1] = b[1] + 5;
							--b[3] = b[3] - 2;
							b[2] = b[2] - checkLeastHigh; -- 保持高度不插地
							
							local x, y, z = cx+b[1], cy+b[2], cz+b[3];
							
							local sparse_index =x*30000*30000+y*30000+z;
							local new_id = b[4] or 96;
							
							local hardware_id = b[5] or 0;
							
							-- 如果有重复，忽略aabb透明方块
							if blockInx == aabb_block_min_inx or blockInx == aabb_block_max_inx then
								if blocks.map[sparse_index] and blocks.map[sparse_index] ~= 0 then								
									break;
								end
							end						
							
							if hardware_id == BtFileMonitorTask.EndBlockId then
								isEndBlock = true;
							end	
							
							blocks.map[sparse_index] = {};
							
							-- 记录材质id
							blocks.map[sparse_index].new_id = new_id;
							-- 记录硬件id
							blocks.map[sparse_index].hardware_id = hardware_id;
							
							blocks.map[sparse_index].blockInx = blockInx;

							if(last_blocks.map[sparse_index] == nil or 
								(last_blocks.map[sparse_index].new_id ~= new_id and last_blocks.map[sparse_index].hardware_id ~= hardware_id)) then
								--
								local modelConfig = BtFileMonitorTask.FbxModelConfig[hardware_id];
								
								if modelConfig then		
									local block_id = block_types.names.BlockModel;
									local data = 0;
									local xml_data = {};
									xml_data.attr = {};
									xml_data.attr.filename = modelConfig.modelPath;
									
									-- 重新记录材质id为模型
									b[4] = block_id;
									new_id = b[4];
									blocks.map[sparse_index].new_id = new_id;
									
									BlockEngine:SetBlock(x, y, z, new_id, data, 3, xml_data);
									local entity = BlockEngine:GetBlockEntity(x,y,z);
									entity:setScale(modelConfig.scale);
								else
									BlockEngine:SetBlock(x,y,z, new_id, b[5], nil, b[6]);	
								end
							end
						end
						break;
					end
				end
				
				if(self.dy) then
					cy = cy - self.dy;
					self.dy = nil;
				end
				
				-- 清除方块
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
				local newBlocks = {};
				
				for _, b in ipairs(self.blocks) do
					local modelConfig = BtFileMonitorTask.FbxModelConfig[b[5]];
					if modelConfig then
						
						local cx, cy, cz = self.cx, self.cy, self.cz;
						local x, y, z = cx+b[1], cy+b[2], cz+b[3];
						
						--blocks[_] = {};
						
						--如果是模型方块，删除自己并记录，
						local function getBlock(_x, _y, _z)
							
							local sparse_index =_x*30000*30000+_y*30000+_z;
							if blocks.map[sparse_index] then
								return blocks.map[sparse_index].blockInx;
							end						
						end
						
						--寻找与模型方块临接的方块
						local nearBlockInx;
						if not nearBlockInx then
							nearBlockInx = getBlock(x + 1, y, z);
						end
						if not nearBlockInx then
							nearBlockInx = getBlock(x - 1, y, z);
						end
						if not nearBlockInx then
							nearBlockInx = getBlock(x, y + 1, z);
						end						
						if not nearBlockInx then
							nearBlockInx = getBlock(x, y - 1, z);
						end
						if not nearBlockInx then
							nearBlockInx = getBlock(x, y, z + 1);
						end
						if not nearBlockInx then
							nearBlockInx = getBlock(x, y, z - 1);
						end
						
						-- 有邻接方块时才继续
						if nearBlockInx then							
							
							local nearB = blocks[nearBlockInx];
							
							local blockLen = 0.03333334 --
							local bonePosX = b[1] * blockLen;
							local bonePosY = b[2] * blockLen;
							local bonePosZ = b[3] * blockLen;
							
							BtFileMonitorTask.pushBoneModel(modelConfig, bonePosX, bonePosY, bonePosZ);
							--[[
							-- 从普通方块改成骨骼方块
							local block_id = block_types.names.Bone;
							local data = 5;
							local xml_data = {};
							xml_data.name="entity";
							xml_data.attr = {};
							
							xml_data.attr.bx = 0;
							xml_data.attr.by = 0;
							xml_data.attr.bz = 0;
							
							xml_data.attr.px = 0;
							xml_data.attr.py = 0;
							xml_data.attr.pz = 0;
							
							xml_data.attr.class = "EntityBlockBone";
							
							xml_data.item_id = block_types.names.Bone;
							
							nearB[1] = nearB[1];
							nearB[2] = nearB[2];
							nearB[3] = nearB[3];
							nearB[4] = block_id;
							nearB[5] = data;
							nearB[6] = xml_data;
							--]]
						end
						
					else
						table.insert(newBlocks, b);
					end
				end
				
				
				GameLogic.GetFilters():apply_filters("BtFileMonitorTask_End", newBlocks);
				
				self:startModelFileMovie(newBlocks);
				
				BtFileMonitorTask.isSkipEnd = false;
				BtFileMonitorTask.DeleteAll();				
			end

		end
	end

end
