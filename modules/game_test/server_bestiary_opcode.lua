--[[
    SCRIPT DE EXEMPLO PARA O SERVIDOR (BESTIARY)
    
    COLOQUE ESTE ARQUIVO EM: data/scripts/bestiary_opcode.lua
    (Se o seu servidor usar a pasta data/scripts com TFS 1.2+, 1.3, 1.4, 1.5, etc)

    Se for servidor antigo (TFS 0.4), veja as instruções no final do arquivo.
]]

local OPCODE_BESTIARY = 45

-- ============================================================================
-- CONFIGURAÇÃO FAKE (Você deve substituir isso pela sua tabela real de bestiary)
-- ============================================================================
local MONSTER_CONFIG = {
    ["Demon"] = { storage = 20001, required = 6666, lookType = 35 },
    ["Rat"]   = { storage = 20002, required = 500,  lookType = 21 },
    ["Dragon"]= { storage = 20003, required = 1000, lookType = 34 },
}
-- ============================================================================


local bestiaryOpcode = GlobalEvent("BestiaryOpcode")

function bestiaryOpcode.onExtendedOpcode(player, opcode, buffer)
    if opcode == OPCODE_BESTIARY then
        if buffer == "request" then
            
            local bestiaryData = {}
            
            -- Itera sobre a configuração e pega os dados do jogador
            for monsterName, config in pairs(MONSTER_CONFIG) do
                local kills = player:getStorageValue(config.storage)
                if kills < 0 then kills = 0 end
                
                table.insert(bestiaryData, {
                    name = monsterName,
                    lookType = config.lookType,
                    kills = kills,
                    required = config.required,
                    
                    -- Exemplo de lógica de ciclo (pode adaptar)
                    cycle = 1,
                    maxCycles = 3,
                    
                    -- Se quiser calcular ciclo baseado em kills:
                    -- cycle = math.min(3, math.floor(kills / (config.required/3)) + 1)
                })
            end

            -- Envia JSON de volta
            -- Se não tiver json.encode, faremos manual:
            local json_data = ""
            if json and json.encode then
                json_data = json.encode(bestiaryData)
            else
                -- Fallback manual
                json_data = "["
                local items = {}
                for _, m in ipairs(bestiaryData) do
                    table.insert(items, string.format(
                        '{"name":"%s","lookType":%d,"kills":%d,"required":%d,"cycle":%d,"maxCycles":%d}',
                        m.name, m.lookType, m.kills, m.required, m.cycle, m.maxCycles
                    ))
                end
                json_data = json_data .. table.concat(items, ",") .. "]"
            end

            player:sendExtendedOpcode(OPCODE_BESTIARY, json_data)
        end
    end
end

bestiaryOpcode:register()


--[[
    ============================================================================
    INSTRUÇÕES PARA SERVIDORES ANTIGOS (TFS 0.4 / OTX)
    ============================================================================
    
    1. Crie o arquivo em data/creaturescripts/scripts/bestiary_opcode.lua
    2. Copie APENAS a função onExtendedOpcode (remova a parte 'local bestiaryOpcode = ...')
       A assinatura deve ser: function onExtendedOpcode(cid, opcode, buffer) ... end
       Use 'local player = Player(cid)' ou funções compativeis com sua versão.
       
    3. Em data/creaturescripts/creaturescripts.xml:
       <event type="extendedopcode" name="BestiaryOpcode" script="bestiary_opcode.lua" />
       
    4. Em data/creaturescripts/scripts/login.lua:
       registerCreatureEvent(cid, "BestiaryOpcode")
]]
