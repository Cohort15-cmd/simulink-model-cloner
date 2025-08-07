% Robust IEEE 9-Bus Cloning Script with Safe Connection Handling and Debugging
function clone_model_safe(originalModel, clonedModel)
    % Load and open original model
    load_system(originalModel);

    % Create new model and copy all blocks
    new_system(clonedModel);
    open_system(clonedModel);

    % Get all blocks from original
    blocks = find_system(originalModel, 'SearchDepth', 1, 'Type', 'Block');
    clonedBlocks = containers.Map;

    % Clone blocks
    for i = 1:length(blocks)
        blk = blocks{i};
        parts = split(blk, '/');
        blkName = strjoin(parts(2:end), '_');

        try
            newBlk = add_block(blk, [clonedModel '/' blkName], 'MakeNameUnique', 'on');
            clonedBlocks(blkName) = newBlk;
            fprintf("✅ Block cloned: %s\n", blkName);
        catch ME
            fprintf("❌ Block clone failed: %s | %s\n", blkName, ME.message);
        end
    end

    % Copy line connections safely with debugging
    lines = find_system(originalModel, 'FindAll', 'on', 'Type', 'line');
    totalConnected = 0;

    for i = 1:length(lines)
        line = lines(i);
        try
            srcBlkHandle = get_param(line, 'SrcBlockHandle');
            dstBlkHandles = get_param(line, 'DstBlockHandle');

            if any([srcBlkHandle dstBlkHandles] <= 0)
                continue; % Skip invalid handles
            end

            srcBlkPath = getfullname(srcBlkHandle);
            srcParts = split(srcBlkPath, '/');
            srcKey = strjoin(srcParts(2:end), '_');
            srcPortNum = get_param(line, 'SrcPort');

            dstPortNums = get_param(line, 'DstPort');

            fprintf("\n🔎 Line debug:");
            fprintf("\n  Source: %s (port %d)", srcKey, srcPortNum);

            for j = 1:length(dstBlkHandles)
                dstBlkPath = getfullname(dstBlkHandles(j));
                dstParts = split(dstBlkPath, '/');
                dstKey = strjoin(dstParts(2:end), '_');
                fprintf("\n  Dest[%d]: %s (port %d)", j, dstKey, dstPortNums(j));

                if isKey(clonedBlocks, srcKey) && isKey(clonedBlocks, dstKey)
                    newSrc = clonedBlocks(srcKey);
                    newDst = clonedBlocks(dstKey);

                    srcHandles = get_param(newSrc, 'PortHandles');
                    dstHandles = get_param(newDst, 'PortHandles');

                    % Display port handles for inspection
                    fprintf("\n    SrcHandles.Outport: %s", mat2str(srcHandles.Outport));
                    fprintf("\n    DstHandles.Inport: %s", mat2str(dstHandles.Inport));

                    % Attempt auto-matching of ports
                    try
                        if isscalar(srcHandles.Outport) && isscalar(dstHandles.Inport)
                            add_line(clonedModel, srcHandles.Outport, dstHandles.Inport, 'autorouting', 'on');
                            totalConnected = totalConnected + 1;
                            fprintf(" ✅ Auto-matched and connected\n");
                        elseif ~isempty(srcHandles.Outport) && ~isempty(dstHandles.Inport)
                            add_line(clonedModel, srcHandles.Outport(1), dstHandles.Inport(1), 'autorouting', 'on');
                            totalConnected = totalConnected + 1;
                            fprintf(" ✅ Fallback connected (1st ports)\n");
                        else
                            fprintf(" ⚠️ Empty port handle lists\n");
                        end
                    catch connErr
                        fprintf(" ⚠️ Connection error: %s\n", connErr.message);
                    end
                else
                    fprintf(" ⚠️ Block not found in cloned map\n");
                end
            end

        catch err
            fprintf("⚠️  Line skip due to error: %s\n", err.message);
        end
    end

    save_system(clonedModel);
    fprintf("\n🔧 Cloning completed: %d lines connected.\n", totalConnected);
    close_system(clonedModel);
end
