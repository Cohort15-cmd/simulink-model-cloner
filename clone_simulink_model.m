% ✅ RELIABLE MODEL CLONE with correct block references (no label parsing)
function clone_simulink_model(srcModel, destModel)
    % Load source model
    load_system(srcModel);

    % Create and open destination model
    new_system(destModel);
    open_system(destModel);

    % Copy blocks from top level
    srcBlocks = find_system(srcModel, 'SearchDepth', 1, 'Type', 'Block');
    srcBlocks = setdiff(srcBlocks, [srcModel]);

    blockMap = containers.Map(); % original full path → new full path

    for i = 1:length(srcBlocks)
        blk = srcBlocks{i};
        try
            relPath = erase(blk, [srcModel '/']);
            newBlkPath = add_block(blk, [destModel '/' relPath], 'MakeNameUnique', 'on');
            pos = get_param(blk, 'Position');
            set_param(newBlkPath, 'Position', pos);

            blockMap(blk) = newBlkPath;

            fprintf('✅ Cloned: %s\n', relPath);
        catch
            warning('⚠️ Failed to clone: %s', blk);
        end
    end

    % Copy lines using full port handles
    lines = find_system(srcModel, 'FindAll', 'on', 'Type', 'line');
    for i = 1:length(lines)
        try
            line = lines(i);

            srcPortHandle = get_param(line, 'SrcPortHandle');
            dstPortHandles = get_param(line, 'DstPortHandle');

            if srcPortHandle == -1 || any(dstPortHandles == -1)
                continue;
            end

            srcBlockFull = get_param(get_param(srcPortHandle, 'Parent'), 'Parent');
            srcBlock = getfullname(get_param(srcPortHandle, 'Parent'));
            srcPortNum = get_param(srcPortHandle, 'PortNumber');

            if ~isKey(blockMap, srcBlock)
                continue;
            end

            for j = 1:length(dstPortHandles)
                dstBlock = getfullname(get_param(dstPortHandles(j), 'Parent'));
                dstPortNum = get_param(dstPortHandles(j), 'PortNumber');

                if ~isKey(blockMap, dstBlock)
                    continue;
                end

                srcStr = sprintf('%s/%d', blockMap(srcBlock), srcPortNum);
                dstStr = sprintf('%s/%d', blockMap(dstBlock), dstPortNum);

                add_line(destModel, srcStr, dstStr, 'autorouting', 'on');
            end
        catch ME
            warning('⚠️ Failed to connect line #%d: %s', i, ME.message);
        end
    end

    save_system(destModel);
    close_system(destModel);
    fprintf('\n✅ Final model cloned to "%s" with blocks and connections.\n', destModel);
end
