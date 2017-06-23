NPL.load("(gl)script/ide/Document/CSVDocReader.lua");
local CSVDocReader = commonlib.gettable("commonlib.io.CSVDocReader");	
local PluginLoader = commonlib.gettable("System.Plugins.PluginLoader");
	

-- 配置文件
local BtWorldConfig = commonlib.inherit(nil,commonlib.gettable("Mod.BlockFileMonitor.BtWorldConfig"));

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

-- 加载配置
function BtWorldConfig:_loadConfig(filePath)
	if not self.AllCfg then
		self.AllCfg = {};
	end
	
	if not self.AllCfg[filePath] then
		self.AllCfg[filePath] = {};
		
		local nowCfg = self.AllCfg[filePath];
		
		local reader = CSVDocReader:new();

		if(reader:LoadFile(PluginLoader:GetPluginFolder().."BlockFileMonitor/" .. filePath, 1)) then 
			local rows = reader:GetRows();
						
			-- 第一行注释，第二行类型，第三行id，第四行后是数据
			local startRow = 2;
			local typeTable = {};
			for keyInx, dataType in ipairs(rows[startRow]) do
				typeTable[keyInx] = dataType;
			end
			
			local keyTable = {};
			for keyInx, keyName in ipairs(rows[startRow + 1]) do
				keyTable[keyInx] = keyName;
			end

			for i = startRow + 2, #rows do
				local row = rows[i];
				local nowRowCfg = nil;
				for keyInx, keyValue in ipairs(rows[i]) do
					-- 默认第一个值为主键
					if keyInx == 1 then
						
						local tableKey;
						if typeTable[keyInx] == "str" then
							tableKey = keyValue;
						elseif typeTable[keyInx] == "num" then
							tableKey = tonumber(keyValue);
						end
						
						nowCfg[tableKey] = {};
						nowRowCfg = nowCfg[tableKey];
					end
					
					local keyName = keyTable[keyInx];
										
					if typeTable[keyInx] == "strArr" then
						nowRowCfg[keyName] = toArray("_")(keyValue);
					elseif typeTable[keyInx] == "numArr" then
						nowRowCfg[keyName] = toNumberArray("_")(keyValue);
					elseif typeTable[keyInx] == "str" then
						nowRowCfg[keyName] = keyValue;
					elseif typeTable[keyInx] == "num" then
						nowRowCfg[keyName] = tonumber(keyValue);
					end
				end
				nowRowCfg = nil;
			end
		else
			self.AllCfg[filePath] = nil;
		end
	end	
end	

function BtWorldConfig:init()
	self:_loadConfig("BtStoryConfig.csv");
	self:_loadConfig("BtWorldConfig.csv");
end

function BtWorldConfig:getCfg(cfgName)
	local aaa = self.AllCfg[cfgName];
	return aaa;
end