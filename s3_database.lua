--[[

]]

require"lfs";

JSON = assert(loadfile ("EXTENSION\\JSON.lua"));
local S3_PATH = [[E:\tmp-copy\neuroskyecg]];

function getFile(path, wefind, r_table)
	for file in lfs.dir(path) do

		if file ~= "." and file ~= ".." and string.find(file,".DS_Store")==nil then
			local subpath = path..'\\'..file;
			local n = file;
			for subfile in lfs.dir(subpath) do
				if subfile ~= "." and subfile ~= ".." and string.find(subfile, wefind) ~= nil then
					local _table = {n,subpath..'\\'..subfile};

					table.insert(r_table,_table);
--~ 					print('table:'.._table);
					print(subpath..'\\'..subfile);
					file = io.open(subpath..'\\'..subfile, "rb");
					fileString = file:read();
					local lua_value = JSON:decode(fileString);

				end
			end
		end
	end
end

function getUserNameFromString(str)
	local start = string.find(str,'-')+1;
	local name = string.sub(nameStr,start);
	print('string'..str..',name:'..name);
end

local input_table = {}
getFile(S3_PATH, "ped.txt",  input_table);

print('count:'..#input_table);
for item = 1, #input_table do
	nameStr =input_table[item][1];
	path =input_table[item][2];
	print(nameStr..', ==> path:'..path);
	getUserNameFromString(nameStr);

	print('value'..lua_value[1])
end












