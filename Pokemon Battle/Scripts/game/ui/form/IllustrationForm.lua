local _M = class("IllustrationForm", BaseForm)
local FilterWidget = require("FilterWidget")
local CardInfoPanel = require("CardInfoPanel")

local MARGIN_H = 30
local TITLE_CARD_FLAG = 100
local ICON_D = 100
local ICON_GAP = 26

function _M.create(tab)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(tab)
    return panel
end

function _M:init(tab)
    local visibleSize = lc.Director:getVisibleSize()
    --_M.super.init(self, cc.size(visibleSize.width - (16 + V.FRAME_TAB_WIDTH) * 2, 680), Str(STR.ILLUSTRATION), bor(0))

    self._bg = lc.createNode(cc.size(lc.w(self), lc.h(self)))
    lc.addChildToCenter(self, self._bg)
    local bg = lc.createSprite("res/jpg/ui_scene_bg.jpg")
    for i = 0, lc.w(self), lc.w(bg) do
        self._bg:addChild(bg)
        bg:setScaleY(lc.h(self._bg)/lc.h(bg))
        bg:setAnchorPoint(0,0)
        bg:setPosition(i, 0)
        bg = lc.createSprite("res/jpg/ui_scene_bg.jpg")
    end

    ---[[
    local size = cc.size(visibleSize.width - 2 * 30, 750)
    self._isForce = true
    self._ignoreBlur = (lc._runningScene and lc._runningScene._sceneId == ClientData.SceneId.battle)

    -- Form content main container
    self._form = ccui.Widget:create()
    self._form:setContentSize(size)
    self._form:setTouchEnabled(true)
    self._form:setAnchorPoint(0.5, 0.5)

    -- Add form frame
    local frame = lc.createNode(size)
    local frameBg = lc.createSprite({_name = 'res/jpg/illustration_panel.png', _crect = cc.rect(176, 381, 2, 2), _size = size})
    lc.addChildToCenter(frame, frameBg, -2)
    frame._bg = frameBg
       
    lc.addChildToCenter(self._form, frame)
    self._frame = frame
    
    -- Create form according to the flag
    flag = flag or 0

    local bgOffset = cc.p(0, -2)
    local bgSize = cc.size(lc.w(self._form) - _M.FRAME_THICK_LEFT - _M.FRAME_THICK_RIGHT, lc.h(self._form) - _M.FRAME_THICK_TOP - _M.FRAME_THICK_BOTTOM)

    if band(flag, _M.FLAG.TOP_AREA) ~= 0 then
        self:addTopBg()
        bgSize.height = bgSize.height - 64
    end
    
    if band(flag, _M.FLAG.BOTTOM_AREA) ~= 0 then
        self:addBottomBg()
        bgSize.height = bgSize.height - 72
        bgOffset.y = bgOffset.y + 72
    end

    --self._bg = V.createShadowColorBg(bgSize)

    --lc.addChildToPos(self._form, self._bg, cc.p(_M.FRAME_THICK_LEFT + lc.w(self._bg) / 2 + bgOffset.x, _M.FRAME_THICK_BOTTOM + lc.h(self._bg) / 2 + bgOffset.y), -1)

    local offsetY = 0

    self._form:setPosition(lc.w(self) / 2, lc.h(self) / 2 + offsetY)
    self:addChild(self._form)
    
    if band(flag, _M.FLAG.NO_CLOSE_BTN) == 0 then
        local btnBack = V.createShaderButton("img_btn_close", function(sender) self:hide() end)
        btnBack:setPosition(lc.w(self._form) - 63, lc.h(self._form) - 92)
        btnBack:setTouchRect(cc.rect(0, 0, 108, 108))
        self._form:addChild(btnBack, 20)
        self._btnBack = btnBack
    end
    --]]]
    self._form:setTouchEnabled(false)
    self:createCardArea()

    if tab == nil or type(tab) == "number" then

        V.createIllustrationTabs(self._form, {Str(STR.POKEMON), Str(STR.COMMAND)}, lc.top(self._frame) - 280 + 3, lc.right(self._frame) - 140 + 8, 480, 155)
        self:createFilters()    
    else

        self._searchKey = tab
        self:updateCardList()
    end

    self._form.showTab = function(form, tabIndex)
        self._form._tabArea:showTab(tabIndex)

        self:updateCardList()

        -- Update filter
        for _, filter in ipairs(self._filters) do
            filter:setVisible(false)
        end
        self._filters[tabIndex]:setVisible(true)

        return true
    end

    self._form:showTab(1)

    local searchTop = V.createShaderButton("illustration_search", function(sender) self._filters[self._form._tabArea._focusTabIndex]._searchArea:setVisible(not self._filters[self._form._tabArea._focusTabIndex]._searchArea:isVisible()) end)
    searchTop:setAnchorPoint(0, 0.5)
    lc.addChildToPos(self._form, searchTop, cc.p(lc.left(self._form) - 28, lc.ch(self._form)))
    -- adjust searchArea's position
    for i, item in pairs(self._filters) do
        item._searchArea:setPosition(cc.p(lc.cw(self._form), lc.top(self._form) + 280))
    end

    CardInfoPanel._operateType = CardInfoPanel.OperateType.view
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    CardInfoPanel._operateType = CardInfoPanel.OperateType.na
end

function _M:createFilters()
    local createFilter = function(modeStr)
        return FilterWidget.create(FilterWidget.ModeType[modeStr] + FilterWidget.ModeType.illustration, lc.h(self._frame) - 80)
    end

    local filterMonster = createFilter("monster")
    filterMonster:setFilterNature(FilterWidget.FilterNature.all)
    filterMonster:setFilterLevel(FilterWidget.FilterLevel.all)
    filterMonster:setFilterCategory(FilterWidget.FilterCategory.all)

    local filterRare = createFilter("rare")
    filterRare:setFilterNature(FilterWidget.FilterNature.all)
    filterRare:setFilterLevel(FilterWidget.FilterLevel.all)
    filterRare:setFilterCategory(FilterWidget.FilterCategory.all)

    self._filters = {filterMonster, createFilter("magic")}
    
    for _, filter in ipairs(self._filters) do
        filter:setFilterQuality(FilterWidget.FilterQuality.all)
        filter:setVisible(false)
        filter:registerSortFilterHandler(function() self:updateCardList() end)
        lc.addChildToPos(self._frame, filter, cc.p(lc.left(self._frame) + V.FRAME_TAB_WIDTH - 55 + 7, lc.h(self._frame) / 2 - 443))
    end
end

function _M:createCardArea()
    local areaW = lc.w(self._frame) - 351
    local areaH = lc.h(self._frame) - 123
       
    local list = lc.List.createV(cc.size(areaW, areaH), 10, 10)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._frame, list, cc.p(lc.cw(self._frame), lc.ch(self._frame) + 6))
    self._list = list

    self._cardCountInRow = math.floor(lc.w(list) / (ICON_D + ICON_GAP))

    -- Prepare card data   
    self._data = {{}, {}, {}, {}}

    local monsters = self._data[1]
    for infoId, info in pairs(Data._monsterInfo) do
        if Data.isUserVisible(infoId) then
            monsters[#monsters + 1] = info
        end
    end
    table.sort(monsters, function(a, b) return a._id < b._id end)
    
    local magics = self._data[2]
    for infoId, info in pairs(Data._magicInfo) do
        if Data.isUserVisible(infoId) then
            magics[#magics + 1] = info
        end
    end
    table.sort(magics, function(a, b) return a._id < b._id end)

end

function _M:updateCardList(flag)
    local listData = {}

    if self._searchKey then
        local addCards = function(index)
            -- Insert the title
            table.insert(listData, TITLE_CARD_FLAG + index)

            local cards = ClientData._player:filterBySearch(self._data[index], self._searchKey)

            -- Insert cards
            local rowData = {}
            for _, info in ipairs(cards) do
                table.insert(rowData, info)
                if #rowData == self._cardCountInRow then
                    table.insert(listData, rowData)
                    rowData = {}
                end
            end

            if #rowData > 0 then
                table.insert(listData, rowData)
            end

            -- Check whether there are any data in this quality
            if type(listData[#listData]) == "number" then
                table.remove(listData)
            end
        end

        addCards(1)
        addCards(2)
        addCards(3)
        addCards(4)
    else
        local index = self._form._tabArea._focusTabIndex

        local cards = self._data[index]
        local filter = self._filters[index]
        local player = ClientData._player

        if Data.BaseCardTypes[index] == Data.CardType.monster then
            local func, keyword = filter:getFilterNatureFunc()
            if func then cards = func(player, cards, keyword) end

            local func, keyword = filter:getFilterLevelFunc()
            if func then cards = func(player, cards, keyword) end

            local func, keyword = filter:getFilterCategoryFunc()
            if func then cards = func(player, cards, keyword) end
        end
    
        local func, keyword = filter:getFilterSearchFunc()
        if func then cards = func(player, cards, keyword) end
    
        -- Prepare data
        -- Simple number indicates the label and others indicates the CARD_COUNT_IN_ROW card info structure
        for quality = Data.CardQuality.UR, Data.CardQuality.C, -1 do
            -- Insert the title
            table.insert(listData, quality)

            -- Insert cards
            local rowData = {}
            for _, info in ipairs(cards) do
                if info._quality == quality then
                    table.insert(rowData, info)
                    if #rowData == self._cardCountInRow then
                        table.insert(listData, rowData)
                        rowData = {}
                    end
                end
            end

            if #rowData > 0 then
                table.insert(listData, rowData)
            end

            -- Check whether there are any data in this quality
            if type(listData[#listData]) == "number" then
                table.remove(listData)
            end
        end
    end

    local list = self._list
    list:bindData(listData, function(item, data) self:setOrCreateItem(item, data) end, math.min(8, #listData), 1)

    for i = 1, list._cacheCount do
        local data = listData[i]
        local item = self:setOrCreateItem(nil, data)
        list:pushBackCustomItem(item)
    end

    list:jumpToTop()
end

function _M:setOrCreateItem(item, data)
    if item == nil then
        item = ccui.Widget:create()
    end

    item:removeAllChildren()
    -- title
    if type(data) == "number" then
        local strs = {Str(STR.MONSTER), Str(STR.MAGIC)}
        local titleNode = lc.createNode(cc.size(lc.w(self._list), 40))
        local bg = lc.createSprite{_name = "img_title_decoration", _crect = V.CRECT_LABEL_DECORATION, _size = cc.size(lc.w(self._list) / 2 - 40, V.CRECT_LABEL_DECORATION.height)}
        lc.addChildToPos(titleNode, bg, cc.p(lc.cw(bg), lc.ch(titleNode)))
        local bg2 = lc.createSprite{_name = "img_title_decoration", _crect = V.CRECT_LABEL_DECORATION, _size = cc.size(lc.w(self._list) / 2 - 40, V.CRECT_LABEL_DECORATION.height)}
        bg2:setScaleX(-1)
        lc.addChildToPos(titleNode, bg2, cc.p(lc.w(titleNode) - lc.cw(bg2), lc.ch(titleNode)))
        if data < TITLE_CARD_FLAG then
            local quality = data
            local qualityStr, qualityClr = V.getCardQualityStrColor(quality)
            --[[        
            local title = V.createBMFont(V.BMFont.huali_26, qualityStr)
            title:setColor(qualityClr)
            title:setScale(2.4)
            ]]
            local title = lc.createSprite(qualityStr)

            lc.addChildToCenter(titleNode, title)
        else
            local title = V.createBMFont(V.BMFont.huali_26, strs[data - TITLE_CARD_FLAG])
            lc.addChildToCenter(titleNode, title)
        end

        item:setContentSize(lc.w(self._list), 50)
        lc.addChildToPos(item, titleNode, cc.p(lc.cw(item), lc.ch(item)))
    else
        local width = (ICON_D + ICON_GAP) * self._cardCountInRow - ICON_GAP

        item:setContentSize(width, 130)

        local acquired = ClientData._player._playerCard._levels
        local pos = cc.p(ICON_D / 2, lc.h(item) / 2)
        for _, info in ipairs(data) do
            local icon = IconWidget.create({_infoId = info._id})
            icon:setGray(not acquired[info._id])
            icon._name:setColor(V.COLOR_BMFONT)
            lc.addChildToPos(item, icon, pos)
            pos.x = pos.x + ICON_D + ICON_GAP
        end
    end

    return item
end

return _M