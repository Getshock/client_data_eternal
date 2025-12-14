function onSay(cid, words, param)
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[BESTIARY_START]")

    for _, cfg in pairs(BestiaryConfig) do
        local cycle = getPlayerStorageValue(cid, cfg.cycleStorage)
        local progress = getPlayerStorageValue(cid, cfg.progressStorage)

        if cycle ~= -1 or progress ~= -1 then
            if cycle < 1 then cycle = 1 end
            if progress < 0 then progress = 0 end

            local required = Bestiary_GetRequiredKills(cfg, cycle)
            if required < 1 then required = 1 end

            local percent = math.floor(progress * 100 / required)
            if percent > 100 then percent = 100 end

            local jsonLine = string.format(
                '{"name":"%s","cycle":%d,"maxCycles":%d,"progress":%d,"required":%d,"percent":%d,"lookType":%d,"lookHead":%d,"lookBody":%d,"lookLegs":%d,"lookFeet":%d,"lookAddons":%d}',
                cfg.monsterName, cycle, cfg.maxCycles, progress, required, percent, 
                cfg.lookType or 21,
                cfg.lookHead or 0,
                cfg.lookBody or 0,
                cfg.lookLegs or 0,
                cfg.lookFeet or 0,
                cfg.lookAddons or 0
            )

            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, jsonLine)
        end
    end

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[BESTIARY_END]")
    return true
end
