--
--this function its use to convert rawdata format from hex string to Int,
--data like  "ff fe 00 19 00" the first its highByte next its lowByte
--
function fileRead_2_rawDataWithInt32(filename)
	local count = 0;
	local f = assert(io.open(filename, "rb"))
	local block = 5;
	local bytes = f:read("*line");
	local payload;
	payload = {};
	count = 0;
	for word in bytes:gmatch( "[^%s]+" ) do
		word = tonumber("0x"..word);
		table.insert( payload, word );
		count = count + 1;
	end
	print("count = "..count);
	for i = 1,count,2 do
		highByte = payload[i];
		lowByte = payload[i + 1];
		local rawValue = highByte*256 + lowByte;
		if( rawValue >= 2^15 ) then rawValue = rawValue - 2^16; end
			--splitFile:write( rawValue, "\n" );
		print(rawValue);
	end
end

fileRead_2_rawDataWithInt32("");
