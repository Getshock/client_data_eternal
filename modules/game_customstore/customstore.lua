local OPCODE_CUSTOM_STORE = 217

local storeWindow = nil

-- Client-side Configuration (Received from Server)
local categories = {}
local currentOffers = {}
local homeConfig = {}
local selectedCategory = nil
local selectedOffer = nil

function init()
    g_ui.importStyle('customstore')

    ProtocolGame.registerExtendedOpcode(OPCODE_CUSTOM_STORE, onExtendedOpcode)
    
    connect(g_game, {
        onGameEnd = terminate
    })
end

function terminate()
    ProtocolGame.unregisterExtendedOpcode(OPCODE_CUSTOM_STORE)
    if storeWindow then
        storeWindow:destroy()
        storeWindow = nil
    end
end

function toggle()
    if not storeWindow then
        local status, result = pcall(g_ui.createWidget, 'CustomStoreWindow', rootWidget)
        if not status then
            return
        end
        storeWindow = result
        storeWindow:hide()
    end
    
    if storeWindow:isVisible() then
        storeWindow:hide()
    else
        storeWindow:show()
        storeWindow:raise()
        storeWindow:focus()
        
        -- Request data from server
        refresh()
    end
end

function refresh()
    local protocol = g_game.getProtocolGame()
    if protocol then
        -- Manual JSON to avoid encoding issues
        local json_data = '{"action": "fetch"}'
        protocol:sendExtendedOpcode(OPCODE_CUSTOM_STORE, json_data)
    end
end

function onExtendedOpcode(protocol, opcode, buffer)
    if opcode ~= OPCODE_CUSTOM_STORE then return end
    
    local status, data = pcall(json.decode, buffer)
    if not status then
        return
    end
    
    if data.action == 'open' or data.action == 'data' then
        
        if not storeWindow and data.action == 'open' then
            local status, result = pcall(g_ui.createWidget, 'CustomStoreWindow', rootWidget)
            if status then
                storeWindow = result
                storeWindow:hide()
            end
        end
        
        -- Process data if available
        if data.categories then
            categories = data.categories
        end
        
        if data.offers then
            currentOffers = data.offers
        end

        if data.homeConfig then
            homeConfig = data.homeConfig
        end
        
        if storeWindow then
            if not storeWindow:isVisible() then
                storeWindow:show()
                storeWindow:raise()
                storeWindow:focus()
            end
            
            updateCategories()
            
            -- If user hasn't selected a category yet, select the first one
            if not selectedCategory and #categories > 0 then
                 selectCategory(categories[1].id)
            -- If user has selected a category, refresh it (important for offers update)
            elseif selectedCategory then
                 selectCategory(selectedCategory)
            end
        end
        
    elseif data.action == 'balance' then
        if modules.game_textmessage then
            modules.game_textmessage.displayGameMessage(data.text)
        else
            -- fallback
        end
    end
end

function updateCategories()
    if not storeWindow then return end
    
    local list = storeWindow:getChildById('leftPanel'):getChildById('categoryList')
    list:destroyChildren()
    
    for _, cat in ipairs(categories) do
        local widget = g_ui.createWidget('CategoryButton', list)
        widget:setText(cat.name)
        widget:setId('cat_' .. cat.id)
        widget.categoryId = cat.id
        widget.onClick = function() selectCategory(cat.id) end
        
        -- Select if matches current
        if selectedCategory == cat.id then
            widget:setChecked(true)
        end
    end
end

function selectCategory(catId)
    selectedCategory = catId
    selectedOffer = nil -- Reset offer selection when changing category
    
    if not storeWindow then return end
    
    -- Highlight selection
    local list = storeWindow:getChildById('leftPanel'):getChildById('categoryList')
    for _, child in ipairs(list:getChildren()) do
        if child.categoryId == catId then
            child:setChecked(true)
        else
            child:setChecked(false)
        end
    end
    
    -- Reset Details Panel
    local details = storeWindow:getChildById('detailsPanel')
    details:getChildById('selectedItemPreview'):setVisible(false)
    details:getChildById('selectedItemName'):setText("Select an offer")
    details:getChildById('selectedItemDescription'):setText("")
    details:getChildById('selectedItemPrice'):setText("")
    details:getChildById('buyButton'):setEnabled(false)
    
    updateOffers(catId)
end

function updateOffers(catId)
    if not storeWindow then return end
    
    local panel = storeWindow:getChildById('middlePanel'):getChildById('offersPanel')
    panel:destroyChildren()
    
    -- Try both string and number keys
    local offers = currentOffers[catId] or currentOffers[tostring(catId)] or {}
    
    for _, offer in ipairs(offers) do
        local widget = g_ui.createWidget('StoreOffer', panel)
        widget:getChildById('name'):setText(offer.name)
        widget:getChildById('price'):setText(offer.price .. " gold")
        widget:getChildById('item'):setItemId(offer.itemId)
        widget:getChildById('item'):setItemCount(offer.count or 1)
        
        widget.offer = offer
        widget.onClick = function() selectOffer(offer) end
        
        if selectedOffer and selectedOffer.id == offer.id then
            widget:setChecked(true)
        end
    end
    
    -- Auto-select first offer if available
    if #offers > 0 and not selectedOffer then
        selectOffer(offers[1])
    end
end

function selectOffer(offer)
    selectedOffer = offer
    
    if not storeWindow then return end
    
    -- Highlight in list
    local panel = storeWindow:getChildById('middlePanel'):getChildById('offersPanel')
    for _, child in ipairs(panel:getChildren()) do
        if child.offer and child.offer.id == offer.id then
            child:setChecked(true)
        else
            child:setChecked(false)
        end
    end
    
    -- Update Details Panel
    local details = storeWindow:getChildById('detailsPanel')
    
    local itemWidget = details:getChildById('selectedItemPreview')
    itemWidget:setVisible(true)
    itemWidget:setItemId(offer.itemId)
    itemWidget:setItemCount(offer.count or 1)
    
    details:getChildById('selectedItemName'):setText(offer.name)
    details:getChildById('selectedItemDescription'):setText(offer.description or "")
    details:getChildById('selectedItemPrice'):setText(offer.price .. " gold")
    
    local buyBtn = details:getChildById('buyButton')
    buyBtn:setEnabled(true)
    buyBtn.onClick = function() buyOffer() end
end

function buyOffer()
    if not selectedCategory or not selectedOffer then return end
    
    local protocol = g_game.getProtocolGame()
    if protocol then
        local data = {
            action = 'buy',
            categoryId = selectedCategory,
            offerId = selectedOffer.id
        }
        local json_data = json.encode(data)
        protocol:sendExtendedOpcode(OPCODE_CUSTOM_STORE, json_data)
    end
end
