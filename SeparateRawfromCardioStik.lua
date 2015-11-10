--~ author:chear
--~ Noted: seprate 'ECG_RAW' and 'PO_IR_PPG' from txt file,data format like below:
--[[
	PO_IR_PPG	147
	PO_IR_PPG	146
	PO_IR_PPG	145
	PO_IR_PPG	143
	PO_IR_PPG	142
	ECG_RAW	1152
	ECG_RAW	1152
	ECG_RAW	1152
	ECG_RAW	1152
	ECG_RAW	1152
	ECG_RAW	1152
	ECG_RAW	1152
	PO_IR_PPG	140
	PO_IR_PPG	139
	PO_IR_PPG	137
	PO_IR_PPG	135

]]--


--local SRC_FILENAME = [[streamlog.txt]];
local SRC_FILENAME = [[C:\Users\chear\Downloads\ECG_PPG.txt]];

local splitFileRootname;
local splitFileNumber;
-- output the eeg&ppg to Text file.
local eegSplitFile;
local ppgSplitFile;

--
-- get path and file name without extension name.
--
function getFileName(str)
    local idx = str:match(".+()%.%w+$")
    if(idx) then
        return str:sub(1, idx-1)
    else
        return str
    end
end


--
--
--
local function openSplitFile( rootname )
	if( rootname ) then splitFileRootname = rootname; end
	splitFileRootname = getFileName(splitFileRootname);
	splitFileNumber = splitFileNumber + 1;

	-- open eeg file for write ECG_RAW
	eegFileName = string.format( "%s_%03d_eeg.txt", splitFileRootname, splitFileNumber );
	print(eegFileName);
	if( eegSplitFile ) then eegSplitFile:close(); end
    eegSplitFile = assert( io.open(eegFileName, "w"), eegSplitFile );
    --eegSplitFile:write( "Value\n" );

	-- open ppg file for write PPG_RAW
	ppgFileName = string.format( "%s_%03d_ppg.txt", splitFileRootname, splitFileNumber );
	print(ppgFileName);
	if( ppgSplitFile ) then ppgSplitFile:close(); end
    ppgSplitFile = assert( io.open(ppgFileName, "w"), ppgSplitFile );
    --ppgSplitFile:write( "Value\n" );
end



------------------
-- BEGIN SCRIPT --
------------------

-- If no command line args specified, assume SRC_FILENAME is only arg
if( #arg < 1 ) then arg[1] = SRC_FILENAME; end

-- For each command line argument...
for i,arg in ipairs( arg ) do
--~     io.stderr:write( "Processing file ", arg, "...\n" );
	print("Processing file ", arg, "...\n");
    SRC_FILENAME = arg;

    -- If a source filename was given, attempt to open it as the input stream
    if( SRC_FILENAME ) then assert( io.input(SRC_FILENAME) ); end

	-- read file
	file = io.open(SRC_FILENAME, "rb")
    print("file path:"..SRC_FILENAME);

	-- open file and propare to write to them
	splitFileNumber= 0;
	openSplitFile(SRC_FILENAME);

	local eegTable = {};
	local ppgTable = {};

	while true do
		local bytes = file:read("*l");
		if bytes~=nil then
--~ 			print("bytes="..bytes);
			if (string.find(bytes,"PO_IR_PPG")) then
				table.insert( ppgTable, bytes );
				ppgSplitFile:write(bytes);
			end

			if string.find(bytes,"ECG_RAW") then
				table.insert( eegTable, bytes );
				eegSplitFile:write(bytes);
			end

		else
			print("----------------------");
			print("-- eeg count "..#eegTable.."---");
			print("-- ppg count "..#ppgTable.."---");
			print("----------------------");
			break;
		end;
	end

end
