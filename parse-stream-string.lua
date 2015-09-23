
--~ author:chear
--~ Noted: print every package from received, stream package like below  ,
--[[
ADAAAA0480028536C2AAAA04800283CC2EAAAA048002A8F9DCAAAA048002ED6927AAAA048002345BEEAAAA04800259ED37AAAA04800247AA8CAAAA0480020E442BAAAA048002DC8819AAAA048002DCB9E8AAAA0480020CACC5AAAA0480023B4FF3
]]--


--~ local SRC_FILENAME = [[streamlog.txt]];
--~ local SRC_FILENAME = [[/Users/test1/Downloads/ECG/kirk.txt]];
--~ local SRC_FILENAME = [[C:\Users\admin\Downloads\data\serial_1min_2hz_gnd.txt]];
local SRC_FILENAME = [[C:\Users\admin\Documents\Tencent Files\122274130\FileRecv\example.txt]];


-- Global variables for splitFile functionality
local splitFileNumber = 0;
local splitFileRootname = SRC_FILENAME;
local splitFilename = nil;
local splitFile = nil;

local firstTime = nil;
local timestamp = 0;
local lineNumber = 0;
local rawCount = 0;
local numPackets = 0;


----------------------
-- DEFINE FUNCTIONS --
----------------------

--
--
--
local function openNextSplitFile( rootname )

    if( rootname ) then splitFileRootname = rootname; end
    splitFileNumber = splitFileNumber + 1;
    splitFilename = string.format( "%s.%03d.csv", splitFileRootname, splitFileNumber );

    if( splitFile ) then splitFile:close(); end
    splitFile = assert( io.open(splitFilename, "w"), splitFilename );
    splitFile:write( "Value\n" );

end -- openNextSplitFile()

--
-- Prints an error message to io.stderr, with line number and byte
-- offset number.
--
local function printErr( lineNumber, byteNumber, byte, ... )

    if( PRINT_ERRORS ) then
        io.stderr:write( "Line ", string.format("%5s",lineNumber) );
        io.stderr:write( " (", string.format("%.3f", timestamp), ")" );
        io.stderr:write( " byte ", string.format("%3s", byteNumber) );
        io.stderr:write( " (", byte,")" );
        io.stderr:write( ": " );
        io.stderr:write( string.format(...) );
        io.stderr:write( '\n' );
        io.stderr:flush();
    end

end -- printErr()


--
-- Process a DataRow as applicable to your application.  A DataRow
-- consists of: its excodeLevel/code, which defines what type of data
-- the valueBytes[] contain; the vLength which defines the number of
-- bytes in valueBytes[]; and valueBytes[], which are the bytes of the
-- DataRow's data value.
--
local function handleDataRow( excodeLevel, code, vLength, valueBytes )

    -- Process valueBytes[] based on excodeLevel/CODE...
    if( excodeLevel == 0 ) then

        -- CODE: Raw wave sample
        if( code == 0x80 ) then

            rawCount = rawCount + 1;

            -- Output raw wave sample value bytes
            local rawValue = valueBytes[1]*256 + valueBytes[2];
            if( rawValue >= 2^15 ) then rawValue = rawValue - 2^16; end
            print("raw:"..rawValue);
            splitFile:write( rawValue, "\n" );


        elseif( code == 0x90 ) then
            rawCount = rawCount + 1;
            if( rawCount == 128 ) then
                rawCount = 0;
            end
        if( not rawTimestamp ) then rawTimestamp = valueBytes[3]-1; end
        if( valueBytes[3] ~= (rawTimestamp + 1)%256 ) then
            io.write( "Line  ", lineNumber, " (", timestamp, ") Last: ", rawTimestamp, " This: ", valueBytes[3], "\n" );
        end
        rawTimestamp = valueBytes[3];

        -- CODE: Signal Poor Quality
        elseif( code == 0x02 ) then

            -- Output rawCount
            --io.stderr:write(
--            string.format("%-14s (%7.3f)",timestamp, timestamp-(lastts or 0))..
--            " rawCount: "..rawCount.." poorSignal: "..valueBytes[1].."\n" );
            if( timestamp-(lastts or 0) > 2 ) then
                io.stderr:write( "JUMP!\n" );
            end
            io.stderr:flush();
            rawCount = 0;

            lastts = timestamp;

        -- CODE: Invalid
        else

            return nil, "Invalid code "..code;

        end -- "Switch based on CODE..."

    end -- "Process valueBytes[]..."

    return true;

end -- handleDataRow()


--
-- Parses a payload[] into DataRows, and calls handleDataRow() to
-- further process each DataRow.  The payload CHKSUM should already
-- have been verified before calling this function.
--
local function parsePayload( payload )

    -- Parse each DataRow of payload...
    --io.write( "payload length: ", #payload, "\n" );
    local i = 1;
    while( i <= #payload ) do

        -- EXCODE
        local excodeLevel = 0;
        while( payload[i] == 0x55 ) do
            excodeLevel = excodeLevel + 1;
            i = i + 1;
        end

        -- CODE
        local code = payload[i];
        i = i + 1;
        --io.write( excodeLevel, " ", code, "\n" );

        -- VLENGTH
        local vLength = 1;
        if( code >= 0x80 ) then
            vLength = payload[i];
            i = i + 1;
        end
        --io.write( "vLength: ", vLength, "\n" );

        -- VALUE
        local valueBytes = {};
        for j=i,i+vLength-1 do
            valueBytes[#valueBytes+1] = payload[j];
        end
        handleDataRow( excodeLevel, code, vLength, valueBytes );
        --io.write( "Value bytes: " );
        --for j=i,i+vLength-1 do io.write( string.format("%02X", i) ); end
        --io.write( "\n" );
        i = i + vLength;

    end -- "Parse each DataRow..."

end -- parsePayload()


------------------
-- BEGIN SCRIPT --
------------------

-- If no command line args specified, assume SRC_FILENAME is only arg
if( #arg < 1 ) then arg[1] = SRC_FILENAME; end

-- For each command line argument...
for i,arg in ipairs( arg ) do
    io.stderr:write( "Processing file ", arg, "...\n" );
    SRC_FILENAME = arg;

    -- If a source filename was given, attempt to open it as the input stream
    if( SRC_FILENAME ) then assert( io.input(SRC_FILENAME) ); end

    -- Parser state variables
    local state = "SYNC";
    local pLength;          -- The expected length of the current Packet's payload
    local pLengthReceived;  -- The number of payload bytes currently received
    local payload;          -- The bytes of the payload
    local sum;              -- Running sum of the bytes of the current payload
    local cksum;            -- The checksum reported by the packet

    -- Initialize Splitfile functionality
    splitFileNumber = 0;
    splitFile = nil;
    openNextSplitFile( SRC_FILENAME );

    -- reading data from text file
    file = io.open(SRC_FILENAME, "rb")
    fileString = file:read()
    print("file path:"..SRC_FILENAME);
    print("string length = "..#fileString);


    -- The index (1-based) of the current byte being parsed on the line
    local byteNumber = 0;

    -- For each byte(string) of input...
    for i=1,#fileString,2 do
        word = string.sub(fileString,i,i+1);
        print("byte:"..word);
        byteNumber = byteNumber + 1;

        -- SYNC
        if( state == "SYNC" ) then
            if( word ~= "AA" ) then
                printErr( lineNumber, byteNumber, word, "Not SYNC" );
            else
                state = "SYNC2";
            end

        -- SYNC2
        elseif( state == "SYNC2" ) then
            if( word ~= "AA" ) then
                printErr( lineNumber, byteNumber, word, "Unmatched SYNC" );
                state = "SYNC";
            else
                state = "PLENGTH";
            end

        -- PLENGTH
        elseif( state == "PLENGTH" ) then
            pLength = tonumber("0x"..word);
            if( not pLength or (pLength < 0) or (pLength > 169) ) then
                printErr( lineNumber, byteNumber, word, "Invalid PLENGTH" );
                state = "SYNC";
            else
                payload = {};
                pLengthReceived = 0;
            if( pLength > 0 )
                then state = "PAYLOAD";
            else state = "CKSUM";
            end
        end

        -- PAYLOAD
        elseif( state == "PAYLOAD" ) then
            word = tonumber("0x"..word);
            table.insert( payload, word );
            pLengthReceived = pLengthReceived + 1;
            if( pLengthReceived == pLength ) then
                state = "CKSUM";
            end

        -- CKSUM
        elseif( state == "CKSUM" ) then
            cksum = assert( tonumber("0x"..word), word );
            if( not cksum or (cksum < 0) or (cksum > 255) ) then
                printErr( lineNumber, byteNumber, word, "Invalid CKSUM" );
            else
            --printErr( lineNumber, byteNumber, word, "Packet" );
            end

        -- Calculate payload sum
        sum = 0;
        for i,byte in ipairs(payload) do
            if( not byte or (byte < 0) or (byte > 255) ) then
                printErr( lineNumber, byteNumber, byte,
                "Invalid payload byte" );
            end
            sum = sum + byte;
            while( sum >= 256 ) do sum = sum - 256; end
        end

        -- Check if payload cksum failed...
        if( cksum ~= (255-sum) ) then
            printErr( lineNumber, byteNumber, word, "CKSUM failed:" );
            if( PRINT_CKSUM_ERROR_PAYLOAD ) then
                io.stderr:write( "    ",
                "Payload ("..
                " length: "..string.format("%3d", pLength)..
                " sum: "..string.format("%02X", sum)..
                " invert: "..string.format("%02X",255-sum),
                " ): " );
                for i,byte in ipairs(payload) do
                io.stderr:write( " ", string.format("%02X", byte) );
            end
            io.stderr:write( "\n" );
        end

        -- Else payload checksum passed...
        else

        numPackets = numPackets + 1;

        -- Parse the payload DataRows
        parsePayload( payload );

        end -- "Else checksum passed..."

        -- Checksum byte done, expecting SYNC byte next
        state = "SYNC";

        end -- "CHKSUM"


    end -- "For each byte(string) of input..."

    print("----------------------");
    print("-- Operate Finished --");
    print("----------------------");
end -- "For each command line argument..."
