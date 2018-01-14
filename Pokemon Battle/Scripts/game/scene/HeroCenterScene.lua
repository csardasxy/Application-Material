local BaseUIScene = require("BaseUIScene")

local _M = class("HeroCenterScene", BaseUIScene)
local FilterWidget = require("FilterWidget")

local CardThumbnail = require("CardThumbnail")
local CardList = require("CardList")
local CardInfoPanel = require("CardInfoPanel")

local DATA_BG_CRECT = cc.rect(34, 40, 2, 2)
local ICON_LIST_CRECT = cc.rect(20, 54, 2, 2)

local THUMBNAIL_SCALE = 0.3
local TROOP_THUMBNAIL_SCALE = 0.275

local DIVIDING_LINE_HEIGHT = 8
local DIVIDING_LINE_COLOR = cc.c4b(235, 218, 175, 255)

----------------
-- syncData: 
--      onSelectTroop
--      showTab                     updateBottomValueAreas
--      updateCardList
--      cardList:refresh(true)
----------------

local MovingDir = 
{
    none = 0,
    horizontal = 1,
    vertical = 2,
}

_M.TouchStatus = 
{
    press = 1,
    move = 2,
    tap = 3,
}

_M.MODE_UNTROOP = 1
_M.MODE_TROOP = 2

_M.EXPEDITION_BASE_LEVEL = 1

local TROOP_AREA_WIDTH = 244
local TROOP_AREA_BOTTOM_HEIGHT = 240

function _M.create(troopType)
    return lc.createScene(_M, troopType)
end

function _M:init(troopType)
    if not _M.super.init(self, ClientData.SceneId.manage_troop, STR.SID_FIXITY_NAME_1006, BaseUIScene.STYLE_TAB, true) then return false end

    self._curTroopIndex = troopType or P._curTroopIndex
    
    self:createFrame()
    self:createTroopArea()
    self:createCardList()
    V.addHorizontalTabButtons(self._titleArea, {Str(STR.POKEMON), Str(STR.COMMAND)}, lc.ch(self._titleArea) + 62, lc.w(self) - 430, 650, 90)
    
    self._tabArea = self._titleArea._tabArea
    --[[
    local recommendBtn = ClientView.createShaderButton("recommend_troop_btn", function()
        local form = require("RecommendTroopListForm").create()
        local oriFunc = form.hide
        form.hide = function(sender)
            oriFunc(sender)
            self:updateTroopList()
        end
        self:releaseToopList()
        form:show()
    end)
    lc.addChildToPos(self, recommendBtn, cc.p(ClientView.SCR_W - 24 - lc.cw(recommendBtn), lc.top(self._troopArea) + 10 + lc.ch(recommendBtn)))
    recommendBtn:setVisible(Data.isNormalTroop(self._curTroopIndex))
    ]]
    self:syncData(true)

    self:updateButtonFlags()

    return true
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    self._listeners = {}
    
    local listener = lc.addEventListener(Data.Event.card_dirty, function(event)        
        self:updateBottomValueAreas()
    end)
    table.insert(self._listeners, listener)

    table.insert(self._listeners, lc.addEventListener(Data.Event.group_cards_dirty, function()
        self:onSelectTroop(self._curTroopIndex, true)
    end))

    listener = lc.addEventListener(Data.Event.card_flag_dirty, function(event) self:onCardFlagDirty(event) end)
    table.insert(self._listeners, listener)

    if self._needUpdateTroopList then
        self:updateTroopList()
        self._needUpdateTroopList = nil
    end
end

function _M:onExit()
    _M.super.onExit(self)
    
    for i = 1, #self._listeners do    
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    self:releaseToopList()
    self._needUpdateTroopList = true
end

function _M:onCleanup()
    _M.super.onCleanup(self)
    self:releaseToopList()
    CardInfoPanel._operateType = CardInfoPanel.OperateType.na
end

function _M:syncData(isInit)
    _M.super.syncData(self)

    ClientData._cloneTroops = {}

    if Data.isUnionBattleTroop(self._curTroopIndex) and not isInit then
        ClientView.getActiveIndicator():show(Str(STR.WAITING))
        ClientData.sendGetGroupCards()
    else
        self:onSelectTroop(self._curTroopIndex, true)
    end
end

function _M:createFrame()
    local frame = lc.createNode(cc.size(lc.w(self) - 60, lc.h(self) - TROOP_AREA_BOTTOM_HEIGHT - lc.h(self._titleArea)))
    lc.addChildToPos(self, frame, cc.p(lc.w(self) / 2, TROOP_AREA_BOTTOM_HEIGHT + lc.h(frame) / 2))
    self._frame = frame
end

function _M:createTroopArea()
    local troopBg = lc.createSprite({_name = "img_troop_bg_1", _size = cc.size(lc.w(self), TROOP_AREA_BOTTOM_HEIGHT), _crect = cc.rect(25, 24, 2, 2)})
    
    local troopArea = lc.createNode(cc.size(lc.w(self), lc.h(troopBg)))
    lc.addChildToPos(self, troopArea, cc.p(lc.w(self) / 2, lc.h(troopArea) / 2))
    self._troopArea = troopArea

    local troopBgSmall = lc.createNode(cc.size(190, TROOP_AREA_BOTTOM_HEIGHT - 10))    
    
    local troopBg2 = lc.createSprite({_name = "img_troop_bg_2", _size = cc.size(lc.w(troopBg) - lc.w(troopBgSmall) - 18, lc.h(troopBg) - 20), _crect = cc.rect(16, 14, 9, 6)})
    lc.addChildToPos(troopBg, troopBg2, cc.p(lc.cw(troopBg2) + 9, lc.ch(troopBg)))

    lc.addChildToPos(troopArea, troopBgSmall, cc.p(lc.w(troopArea) - lc.cw(troopBgSmall) - 14, lc.ch(troopBgSmall) - 4), 1)

    lc.addChildToCenter(troopArea, troopBg)


    -- card num
    local cardNumBg = lc.createNode(cc.size(110, 28))
    lc.addChildToPos(troopBgSmall, cardNumBg, cc.p(lc.cw(troopBgSmall),  lc.h(troopBgSmall) - lc.ch(cardNumBg) - 90))

    local cardNumIcon = lc.createSprite("img_icon_cardnum")
    cardNumIcon:setScale(0.8)
    lc.addChildToPos(cardNumBg, cardNumIcon, cc.p(lc.cw(cardNumIcon) - 14, lc.ch(cardNumBg)))

    local countLabel = ClientView.createTTFStroke('1/1', V.FontSize.S3)
    lc.addChildToPos(cardNumBg, countLabel, cc.p(lc.cw(cardNumBg) + 8, lc.y(cardNumIcon) + 2))
    self._cardNumValue = countLabel

    local cardTypeNumLabel = ClientView.createTTFStroke(string.format(Str(STR.TROOP_TYPE_COUNT, true), 0, 0), V.FontSize.S2)
    lc.addChildToPos(troopBgSmall, cardTypeNumLabel, cc.p(lc.x(cardNumBg), lc.bottom(cardNumBg) - lc.ch(cardTypeNumLabel) - 4))
    self._cardTypeNumLabel = cardTypeNumLabel

    -- clear
    local btnClear = ClientView.createShaderButton("img_icon_clear", function(sender) 
            require("Dialog").showDialog(Str(STR.SURE_TO_CLEAR_TROOP), function() self:clearTroop()  end)
        end)
    lc.addChildToPos(troopBgSmall, btnClear, cc.p(lc.cw(troopBgSmall) + 60, lc.h(troopBgSmall) - lc.ch(btnClear) - 24))
    
    local list = lc.List.createH(cc.size(lc.w(troopArea) - lc.w(troopBgSmall) - 40, lc.h(troopArea) - 16), 10, 10)
    lc.addChildToPos(troopArea, list, cc.p(24, 8))
    self._troopList = list

    if Data.isNormalTroop(self._curTroopIndex) or Data.isUnionBattleTroop(self._curTroopIndex) or Data.isDarkTroop(self._curTroopIndex) then
        local btnTroop = ClientView.createScale9ShaderButton("img_btn_1_s", function(sender) self:popSelectTroop() end, ClientView.CRECT_BUTTON_1_S, 110, 50)
        lc.addChildToPos(troopBgSmall, btnTroop, cc.p(lc.cw(troopBgSmall) - 15, lc.y(btnClear)))
        --[[
        btnTroop:addLabel(string.format("%s %d", Str(STR.TROOP), P._curTroopIndex))
        if Data.isUnionBattleTroop(self._curTroopIndex) then
            btnTroop._label:setString(string.format("%s %d", Str(STR.UNION_TROOP), self._curTroopIndex - Data.TroopIndex.union_battle1 + 1))
        elseif Data.isDarkTroop(self._curTroopIndex) then
            btnTroop._label:setString(string.format("%s %d", Str(STR.DARK_TROOP), self._curTroopIndex - Data.TroopIndex.dark_battle1 + 1))
        end
        ]]
        btnTroop:addLabel(string.format("%s%d", Str(STR.TROOP), P._curTroopIndex))
        --lc.offset(btnTroop._label, 0, -5)
        self._btnTroop = btnTroop
        
    else
        local tipStr
        if tipStr then
            local tip = ClientView.createBoldRichText(tipStr, {_normalClr = ClientView.COLOR_LABEL_LIGHT, _boldClr = ClientView.COLOR_TEXT_GREEN, _fontSize = ClientView.FontSize.S1})
            lc.addChildToPos(troopBgSmall, tip, cc.p(12 + lc.w(tip) / 2, lc.h(troopBgSmall) / 2))
        end
    end
end

function _M:createCardList()
    self._cardList = require("CardList").create(cc.size(lc.w(self._frame) - ClientView.FRAME_INNER_LEFT - ClientView.FRAME_INNER_RIGHT, lc.h(self._frame)), THUMBNAIL_SCALE, false)
    self._cardList:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._frame, self._cardList, cc.p(lc.w(self._frame) / 2, lc.h(self._frame) / 2))

    self._cardList:registerCardSelectedHandler(function(data, index) 
        self:onCardSelected(data, index)
    end)
    self._cardList:registerTouchThumbnail(function(sender, type) 
        self:onCardTouch(sender, type)
    end)
    if Data.isUnionBattleTroop(self._curTroopIndex) then
        self._cardList:setMode(CardList.ModeType.union_battle_troop)
    elseif Data.isDarkTroop(self._curTroopIndex) then
        self._cardList:setMode(CardList.ModeType.dark_troop)
    else
        self._cardList:setMode(CardList.ModeType.troop)
    end

    local offsetx = (lc.w(self._frame) - lc.w(self._cardList)) / 2 + 16
    self._cardList._pageLeft._pos = cc.p(-offsetx, 80)
    self._cardList._pageRight._pos = cc.p(lc.w(self._cardList) + offsetx, 80)

    offsetx = offsetx + 32
    --[[
    local pageBg = lc.createSprite({_name = "img_page_bg", _size = cc.size(125, 33), _crect = cc.rect(11, 11, 4, 8)}) 
    lc.addChildToPos(self._frame, pageBg, cc.p(lc.cw(self._frame), lc.ch(pageBg) - 22), -1)
    ]]
    self._cardList._pageLabel:setPosition(lc.w(self._frame) - 29, 10)
    
    self._filterWidgets = {}
    local filterWidgetTypes = {FilterWidget.ModeType.monster, FilterWidget.ModeType.magic}
    for i = 1, #filterWidgetTypes do
        local filterWidget = FilterWidget.create2(filterWidgetTypes[i], lc.w(self._frame)-10)
        filterWidget:resetAllFilter() 
        filterWidget:registerSortFilterHandler(function() self:updateCardList(true) end)
        filterWidget:setVisible(i == 1)

        print ('@@@@@@@@', self._frame, filterWidget)
        --filterWidget:setScale(0.75)
        lc.addChildToPos(self._titleArea, filterWidget, cc.p(lc.w(self._titleArea._btnBack) + 50 + V.FRAME_TAB_WIDTH - lc.w(filterWidget) / 2, lc.ch(self._titleArea)))
        self._filterWidgets[i] = filterWidget
    end
end

function _M:onSelectTroop(troopIndex, isForce) 
    if self._curTroopIndex == troopIndex and (not isForce) then
        return
    end
    self._curTroopIndex = troopIndex
    
    local troop = ClientData._cloneTroops[self._curTroopIndex]
    if troop == nil then
        troop = P._playerCard:getTroop(self._curTroopIndex, true)
        ClientData._cloneTroops[self._curTroopIndex] = troop
    end

    self:updateTroopList()
    
    self._lastTabIndex = nil
    local titleArea = self._titleArea
    titleArea.showTab = function(titleArea, tabIndex)
        self:showTab(tabIndex)
    end
    titleArea:showTab(self._tabArea._focusTabIndex and self._tabArea._focusTabIndex or 1)
end

function _M:releaseToopList()
    local items = self._troopList:getItems()
    for _, layout in ipairs(items) do
        CardThumbnail.releaseToPool(layout._item)        
        layout:release() 
    end

    self._troopList:removeAllItems()
end

function _M:remainItemFromList(troop)
    local itemList = {}

    local items = self._troopList:getItems()
    for i = #items, 1, -1 do
        local layout = items[i];

        local inList = false
        for _, card in ipairs(troop) do
            if layout._card._infoId == card._infoId then
                inList = true
                break
            end
        end 

        if inList then
            table.insert(itemList, layout)
            self._troopList:removeItem(i - 1, false)
        end
    end

    return itemList
end

function _M:updateTroopList()
    local troop, items = ClientData._cloneTroops[self._curTroopIndex], {}

    -- remove
    --local itemList = self:remainItemFromList(troop)
    self:releaseToopList()

    -- add new
    for _, card in ipairs(troop) do
        local cardType = Data.getType(card._infoId)

        if true then
            local layout
            --[[
            for i = 1, #itemList do
                if itemList[i]._card._infoId == card._infoId then
                    layout = itemList[i]
                    break
                end
            end
            ]]

            if not layout then
                layout = ccui.Layout:create()
                layout:retain()
         
                local item = CardThumbnail.createFromPool(card._infoId, TROOP_THUMBNAIL_SCALE, P._playerCard:getSkinId(card._infoId))
                item._countArea:update(true, card._num)
                layout:setContentSize(item._thumbnail:getContentSize())
                layout:setAnchorPoint(cc.p(0.5, 0.5))
                lc.addChildToPos(layout, item, cc.p(lc.cw(layout), lc.ch(layout) + 10))

                item._thumbnail:setTouchEnabled(true)
                item._thumbnail:addTouchEventListener(function(sender, type)
                    self:onTroopTouchThumbnail(sender, type)
                end)

                layout._item = item
            else
                layout._item._countArea:update(true, card._num)
            end

            table.insert(items, layout)  
            layout._card = card
        end
    end

    -- Sort cards by order: hired, wei, shu, wu, qun, horse, book
    table.sort(items, function(a, b)
        local originIdA = Data.getOriginId(a._card._infoId)
        local originIdB = Data.getOriginId(b._card._infoId)
        if originIdA < originIdB then return true
        elseif originIdA > originIdB then return false
        else return a._card._infoId < b._card._infoId
        end
     end)

    for _, item in ipairs(items) do
        self._troopList:pushBackCustomItem(item)
    end
end

function _M:showTab(tabIndex)
    --[[
    if Data.BaseCardTypes[tabIndex] == Data.CardType.magic then
        local level = P._playerCity:getStableUnlockLevel()
        if P._level < level then
            ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), level))
            return
        end                    
    elseif Data.BaseCardTypes[tabIndex] == Data.CardType.trap then
        local level = P._playerCity:getLibraryUnlockLevel()
        if P._level < level then
            ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), level))
            return
        end
    end
    ]]

    self._tabArea:showTab(tabIndex)
    
    for i = 1, #self._filterWidgets do
        self._filterWidgets[i]:setVisible(self._tabArea._focusTabIndex == i)
    end
    
    self:updateCardList(true)

    if self._lastTabIndex == nil then
        self:updateTroopList()
    end

    self:updateBottomValueAreas()

    self._lastTabIndex = tabIndex
    
    local curStep = GuideManager.getCurStepName()
    if string.find(curStep, "show tab") then
        GuideManager.finishStepLater()
    end
end

function _M:updateCardList(isReset)
    local troops = ClientData._cloneTroops[self._curTroopIndex]
    if troops == nil then
        troops = P._playerCard:getTroop(self._curTroopIndex, true)
        ClientData._cloneTroops[self._curTroopIndex] = troops
    end
    
    local focusIndex, exceptCards = self._tabArea._focusTabIndex, {}
    
    local filters, sort = {}
    local filterWidget = self._filterWidgets[focusIndex]
        
    local sortFunc, isAscending = filterWidget:getSortFunc()  
    if sortFunc then sort = {_func = sortFunc, _isReverse = not isAscending} end
           
    if Data.BaseCardTypes[focusIndex] == Data.CardType.monster then
        local filterCountryFunc, FilterNatureKeyword = filterWidget:getFilterNatureFunc()
        if filterCountryFunc then filters[CardList.FilterType.country] = {_func = filterCountryFunc, _keyVal = FilterNatureKeyword} end

        local filterCategoryFunc, filterCategoryKeyword = filterWidget:getFilterCategoryFunc()
        if filterCategoryFunc then filters[CardList.FilterType.category] = {_func = filterCategoryFunc, _keyVal = filterCategoryKeyword} end

        local filterCostFunc, filterCostKeyword = filterWidget:getFilterLevelFunc()
        if filterCostFunc then filters[CardList.FilterType.cost] = {_func = filterCostFunc, _keyVal = filterCostKeyword} end
    end
    
    local filterQualityFunc, filterQualityKeyword = filterWidget:getFilterQualityFunc()
    if filterQualityFunc then filters[CardList.FilterType.quality] = {_func = filterQualityFunc, _keyVal = filterQualityKeyword} end
    
    local filterSearchFunc, filterSearchKeyword = filterWidget:getFilterSearchFunc()
    if filterSearchFunc then filters[CardList.FilterType.search] = {_func = filterSearchFunc, _keyVal = filterSearchKeyword} end   
    
    local cardList = self._cardList
    cardList._troopIndex = self._curTroopIndex

    cardList:init(Data.BaseCardTypes[focusIndex], exceptCards, sort, filters)
    cardList._pageLeft._pos = cc.p(16, lc.ch(cardList))
    cardList._pageRight._pos = cc.p(lc.w(cardList) - 16, lc.ch(cardList))

    cardList:refresh(isReset)
end

function _M:popSelectTroop()
    local btnDefs = {}

    if Data.isUnionBattleTroop(self._curTroopIndex) then
        local maxTroopCount = Data.TroopIndex.union_battle1 + Data.GROUP_NUM - 1
        for i = Data.TroopIndex.union_battle1, maxTroopCount do
            local def = {}
            def._str = string.format("%s %d", Str(STR.UNION_TROOP), i - Data.TroopIndex.union_battle1 + 1)
            def._hideRemark = true
            def._hideExchange = true
            def._handler = function(type)
                if type == 1 then
                    self:onSelectTroop(i, false)
                elseif type == 2 then
                else
                end
            end
            table.insert(btnDefs, def)
        end
    elseif Data.isDarkTroop(self._curTroopIndex) then
        local maxTroopCount = Data.TroopIndex.dark_battle3
        for i = Data.TroopIndex.dark_battle1, maxTroopCount do
            local def = {}
            def._str = string.format("%s %d", Str(STR.DARK_TROOP), i - Data.TroopIndex.dark_battle1 + 1)
            def._hideRemark = true
            def._hideExchange = i == self._curTroopIndex
            def._handler = function(type)
                if type == 1 then
                    self:onSelectTroop(i, false)
                elseif type == 2 then
                elseif type == 4 then
                    self:exchangeTroop(i)
                else
                    local InputForm = require("InputForm")
                    InputForm.create(InputForm.Type.TROOP_REMARK, i, function() self:popSelectTroop() end):show()
                end
            end
            table.insert(btnDefs, def)
        end
    else
        local maxTroopCount = P:getCharacterCount()
        for i = 1, maxTroopCount do
            local def = {_str = nil, _handler = nil}
            if i > P:getCharacterUnlockCount() then
                def._str = string.format(Str(STR.NEED_UNLOCK_CHARACTER_COUNT), i)
            else
                def._str = string.format("%s %d", Str(STR.TROOP), i)
                def._isDef = false
                def._remark = P._troopRemarks[i]
                def._hideExchange = true
                def._handler = function(type)
                    if type == 1 then
                        self:onSelectTroop(i, false)
                    elseif type == 2 then
                        --self:popSelectTroop()
                    else
                        local InputForm = require("InputForm")
                        InputForm.create(InputForm.Type.TROOP_REMARK, i, function() self:popSelectTroop() end):show()
                    end
                end
            end

            table.insert(btnDefs, def)
        end
    end

    local btnTroop, panel = self._btnTroop, require("TopMostPanel").TroopList.create()
    if panel then
        local gPos = lc.convertPos(cc.p(lc.cw(btnTroop), lc.ch(btnTroop)), btnTroop)
        panel:setButtonDefs(btnDefs)
        panel:setPosition(gPos.x - lc.w(panel) / 2 + 66, gPos.y + lc.h(panel) / 2)
        panel:linkNode(self._btnTroop)
        panel:show()
    end
end

function _M:clearTroop()
    ClientData._cloneTroops[self._curTroopIndex] = {}
    ClientData._cloneTroops[self._curTroopIndex]._isDirty = true

    if ClientData.saveTroops() then self:updateBottomValueAreas() end

    self:updateCardList()
    self:updateTroopList()
end

function _M:exchangeTroop(index)
    local indexA, indexB = index, self._curTroopIndex
    local tempA = ClientData._cloneTroops[index]
    if not tempA then
        tempA = P._playerCard:getTroop(index, true)
    end
    local tempB = ClientData._cloneTroops[indexB]
    if not tempB then
        tempB = P._playerCard:getTroop(indexB, true)
    end
    ClientData._cloneTroops[indexA] = tempB
    ClientData._cloneTroops[indexA]._isDirty = true
    ClientData._cloneTroops[indexB] = tempA
    ClientData._cloneTroops[indexB]._isDirty = true

    if ClientData.saveTroops() then self:updateBottomValueAreas() end

    self:updateCardList()
    self:updateTroopList()
end

function _M:updateBottomValueAreas()
    local isRare = self._tabArea._focusTabIndex == Data.CardType.rare

    if isRare then
        self._cardNumValue:setString(string.format("%d/%d", P._playerCard:getTroopCardCountByType(Data.CardType.rare, self._curTroopIndex), Data.MAX_RARE_TROOP_CARD_COUNT))
    elseif Data.isUnionBattleTroop(self._curTroopIndex) then
        self._cardNumValue:setString(string.format("%d/%d", P._playerCard:getTroopCardCountByType(nil, self._curTroopIndex), Data.MAX_UNION_TROOP_CARD_COUNT))
    
    else
        self._cardNumValue:setString(string.format("%d/%d", P._playerCard:getTroopCardCountByType(nil, self._curTroopIndex), Data.MAX_TROOP_CARD_COUNT))
    end

    if isRare then
        self._cardTypeNumLabel:setString(string.format(Str(STR.TROOP_RARE_COUNT, true), P._playerCard:getTroopCardCountByType(Data.CardType.rare, self._curTroopIndex)))
    else
        self._cardTypeNumLabel:setString(string.format(Str(STR.TROOP_TYPE_COUNT, true), P._playerCard:getTroopCardCountByType(Data.CardType.monster, self._curTroopIndex), P._playerCard:getTroopCardCountByType(Data.CardType.magic, self._curTroopIndex) + P._playerCard:getTroopCardCountByType(Data.CardType.trap, self._curTroopIndex)))
    end

    if Data.isUnionBattleTroop(self._curTroopIndex) then
        self._btnTroop._label:setString(Str(STR.UNION_TROOP)..(self._curTroopIndex - Data.TroopIndex.union_battle1 + 1))
    else
        self._btnTroop._label:setString(Str(STR.TROOP)..' '..self._curTroopIndex)
    end
end

function _M:onItemPress(item, type)   
    if self._movingSprite then 
        return 
    end

    self._touchStatus = _M.TouchStatus.press
    self._movingDir = MovingDir.none

    self._movingDeadCard = nil
end

function _M:onItemMove(item, type)
   if self._touchStatus == _M.TouchStatus.tap then return end  
    
   self._touchStatus = _M.TouchStatus.move

   if self._movingSprite == nil then
        if self._movingDir == MovingDir.none then
            local deltaX = math.abs(cc.pSub(item:getTouchMovePosition(), item:getTouchBeganPosition()).x)
            local deltaY = math.abs(cc.pSub(item:getTouchMovePosition(), item:getTouchBeganPosition()).y)
            if deltaX > 32 or deltaY > 32 then
                self._movingDir = deltaX >= deltaY and MovingDir.horizontal or MovingDir.vertical
            end
        end 
        
        if type == _M.MODE_TROOP or self._movingDir == MovingDir.vertical then
            self:createMovingSpriteAndMaskLayer(item, type)
        end
    end

    -- do not use else
    if self._movingSprite then
        self._movingSprite:setPosition(cc.pAdd(self._movingSprite._srcPos, cc.pSub(item:getTouchMovePosition(), item:getTouchBeganPosition())))
        self:checkList((type == _M.MODE_TROOP) and self._troopList or self._cardList)
    end
end

function _M:onItemTap(item, type)
    self._touchStatus = _M.TouchStatus.tap

    local infoId = item._infoId
    local info, cardType = Data.getInfo(infoId)
    local troop = ClientData._cloneTroops[self._curTroopIndex]
    local slotNum = (Data.isUnionBattleTroop(self._curTroopIndex) and Data.MAX_UNION_TROOP_CARD_COUNT or Data.MAX_TROOP_CARD_COUNT)
    local cardNum = P._playerCard:getTroopCardCountByType(nil, self._curTroopIndex)
    local cardCount = self:getTroopCardCount(troop, infoId)

    if type == _M.MODE_TROOP then
        if self._movingSprite and self._isInList then
            -- add card to troop
            local maxCount = info._maxCount
            if Data.isUnionBattleTroop(self._curTroopIndex) then
                maxCount = maxCount * Data.GROUP_NUM
            end
            if cardNum < slotNum and cardCount < maxCount then
                self:onCardUnlocked(infoId)

                troop._isDirty = true

                self:addCardToTroop(troop, infoId)
                self:updateCardList(false)
                self:updateTroopList()
                if ClientData.saveTroops() then self:updateBottomValueAreas() end

                -- effects
                self:playAction(infoId, true, self._movingSprite._srcPos)

                ---------------------------------------- Guide ------------------------------------------------------------------------
                local curStep = GuideManager.getCurStepName()
                if string.sub(curStep, 1, 10) == "troop card" then
                    -- The card item is removed after aniDuration, so guide must wait for that
                    GuideManager.finishStepLater(0.1)
                end
                ---------------------------------------- Guide ------------------------------------------------------------------------                                

            -- unable add to troop
            elseif cardNum >= slotNum then
                ToastManager.push(Str(STR.FULL_IN_TROOP))
            elseif cardType == Data.CardType.monster then
                ToastManager.push(string.format(Str(STR.SAME_CARD_IN_TROOP), Str(STR.MONSTER)))
            elseif cardType == Data.CardType.magic then
                ToastManager.push(string.format(Str(STR.SAME_CARD_IN_TROOP), Str(STR.MAGIC)))
            elseif cardType == Data.CardType.trap then
                ToastManager.push(string.format(Str(STR.SAME_CARD_IN_TROOP), Str(STR.TRAP)))
            end
        end

    elseif type == _M.MODE_UNTROOP then
        if self._movingSprite and self._isInList then
            troop._isDirty = true
            self:removeCardFromTroop(troop, infoId)

            self:updateCardList(false)
            self:updateTroopList()
            if ClientData.saveTroops() then self:updateBottomValueAreas() end

            -- effects
            self:playAction(infoId, false, self._movingSprite._srcPos)
        end
    end

    if self._maskLayer then
        self:removeMaskLayer(type)
    end

    if self._movingSprite then
        self._movingSprite:removeFromParent()
        self._movingSprite = nil
    end
end

function _M:onTroopTouchThumbnail(sender, type)
    sender:stopAllActions()
    if type == ccui.TouchEventType.began then
        sender:runAction(lc.scaleTo(0.1, 0.95))
        
        self:onItemPress(sender, _M.MODE_UNTROOP)
    elseif type == ccui.TouchEventType.ended or type == ccui.TouchEventType.canceled then
        sender:runAction(lc.scaleTo(0.08, 1.0))
        
        self:onItemTap(sender, _M.MODE_UNTROOP)
        if type == ccui.TouchEventType.ended then
            self:onTroopThumbnailSelected(sender) 
        end
    elseif type == ccui.TouchEventType.moved then        
        self:onItemMove(sender, _M.MODE_UNTROOP)
    end
end

function _M:onTroopThumbnailSelected(thumbnail)
    if cc.pGetDistance(thumbnail:getTouchEndPosition(), thumbnail:getTouchBeganPosition()) < 32 then       
        local panel = CardInfoPanel.create(thumbnail._infoId, P._playerCard._levels[thumbnail._infoId], CardInfoPanel.OperateType.troop)

        local cards = {}
        local index = 0
        local items = self._troopList:getItems()
        for i = 1, #items do
            local item = items[i]._item
            local t = item._thumbnail
            cards[#cards + 1] = {_infoId = t._infoId, _num = t._count}
            if thumbnail == t then
                index = i
            end
        end

        panel:setCardList(cards, index, Str(STR.CUR_TROOP))
        panel:setCardCount(thumbnail._count)
        panel:show()
    end
end

function _M:onCardTouch(sender, type)
    if type == ccui.TouchEventType.began then
        self:onItemPress(sender, _M.MODE_TROOP)
    elseif type == ccui.TouchEventType.ended or type == ccui.TouchEventType.canceled then
        if self._movingDeadCard then
            return
        end

        self:onItemTap(sender, _M.MODE_TROOP)
    elseif type == ccui.TouchEventType.moved then
        if sender._item._locked or self._movingDeadCard then return end
        self:onItemMove(sender, _M.MODE_TROOP)
     end
end

function _M:onCardSelected(data, index)
    local thumbnail = self._cardList:getThumbnail(data)
    if cc.pGetDistance(thumbnail:getTouchEndPosition(), thumbnail:getTouchBeganPosition()) < 20 then  
        for i = 1,  #lc._runningScene._scene:getChildren() do
            local child = lc._runningScene._scene:getChildren()[i]
            if child._panelName == "CardInfoPanel" then return end
        end

        self:onCardUnlocked(data)
        
        local operateType = CardInfoPanel.OperateType.operate
        if Data.isUnionBattleTroop(self._curTroopIndex) or Data.isDarkTroop(self._curTroopIndex) then
            operateType = CardInfoPanel.OperateType.na
        end

        local panel = CardInfoPanel.create(data, thumbnail._level, operateType)
        if not GuideManager.isGuideEnabled() then
            local listIndex = (self._cardList._curPage - 1) * self._cardList._itemRow * self._cardList._itemCol + index
            panel:setCardList(self._cardList._cards, listIndex, ClientData.getStrByCardType(Data.getType(thumbnail._infoId))..Str(STR.CARD_LIST))
        else
            local curStep = GuideManager.getCurStepName()
            if curStep == "rare card" then
                GuideManager.finishStep()
            end
        end
        panel:show()

        if GuideManager.isGuideEnabled() then
            GuideManager.pauseGuide()
        end
    end
end

function _M:onCardUnlocked(data)
    if P._playerCard:isUnlocked(data) then
        P._playerCard:removeUnlocked(data)
        ClientData.sendCardUnlockConfirmed(data)
    end
end

function _M:createMovingSpriteAndMaskLayer(item, type)
    local toList = (type == _M.MODE_TROOP) and self._troopList or self._cardList
    local fromList = (type == _M.MODE_TROOP) and self._cardList or self._troopList

    local srcPos = item:convertToWorldSpace(cc.p(lc.w(item) / 2, lc.h(item) / 2))
    srcPos = self:convertToNodeSpace(srcPos)

    local infoId = item._infoId

    local thumbnail = CardThumbnail.create(infoId, THUMBNAIL_SCALE, P._playerCard:getSkinId(infoId))
    self:addChild(thumbnail, ClientData.ZOrder.ui + 2)
    self._movingSprite = thumbnail
    
    self._movingSprite._srcPos = srcPos
    self._movingSprite._abc = 1
    self._movingSprite:setPosition(cc.pAdd(srcPos, cc.pSub(item:getTouchMovePosition(), item:getTouchBeganPosition())))

    if fromList == self._troopList then
        fromList:setIsScrollEnabled(false)
    end

    local startPos = toList:convertToWorldSpace(cc.p(0, 0))
    startPos = self:convertToNodeSpace(startPos)
    startPos.x = 0
    local stencilRect = cc.rect(startPos.x, startPos.y, lc.w(self), lc.h(toList))
    self._maskLayer = self:createMaskLayer(stencilRect)
    self:addChild(self._maskLayer, ClientData.ZOrder.ui + 1)

    -- The separator pos between toList and fromList
    self._separatorPos = (type == _M.MODE_UNTROOP and startPos.y or (startPos.y + stencilRect.height))
end

function _M:createMaskLayer(stencilRect)
    local mask = cc.LayerColor:create(cc.c4b(0, 0, 0, 192), lc.w(self), lc.h(self))
    return ClientView.createClipNode(mask, stencilRect, true)
end

function _M:removeMaskLayer(type)
    if type == _M.MODE_TROOP then
    else
        self._troopList:setIsScrollEnabled(true)
    end

    self._maskLayer:removeFromParent(true)
    self._maskLayer = nil
end

function _M:checkList(list)
    local isTroopList = (list == self._troopList)
    local offset = (isTroopList and 0.5 or 0)
    
    local sprite = self._movingSprite
    
    if isTroopList then
        self._isInList = (self._separatorPos > lc.y(sprite))
    else
        self._isInList = (self._separatorPos < lc.y(sprite))
    end
end

function _M:checkUnlockModule()
    local curLevel = P._level
    local prevLevel = lc.readConfig(ClientData.ConfigKey.lock_level_herocenter, curLevel)                
    
    local strs = {}

    --[[
    local level = P._playerCity:getStableUnlockLevel()
    if prevLevel < level and curLevel >= level then
        table.insert(strs, #strs + 1, Str(STR.HORSE)..Str(STR.INTROOP)..Str(STR.UNLOCKED))
    end
    
    level = P._playerCity:getLibraryUnlockLevel()
    if prevLevel < level and curLevel >= level then
        table.insert(strs, #strs + 1, Str(STR.BOOK)..Str(STR.INTROOP)..Str(STR.UNLOCKED))
    end
    ]]
    
    local curTroopNum = P:getUnlockTroopNumber(curLevel)
    local prevTroopNum = P:getUnlockTroopNumber(prevLevel)
    local numStr = ""
    for i = prevTroopNum + 1, curTroopNum do
        if numStr ~= "" then
            numStr = string.format("%s,%d", numStr, i)
        else
            numStr = string.format("%d", i)
        end
    end
    if numStr ~= "" then
        table.insert(strs, #strs + 1, Str(STR.TROOP)..numStr..Str(STR.UNLOCKED))
    end      

    if #strs > 0 then
        ToastManager.pushArray(strs)
        lc.writeConfig(ClientData.ConfigKey.lock_level_herocenter, curLevel)        
    end  
end

function _M:getTotalTroopCardCount(index)
    local troop = ClientData._cloneTroops[index]
    if not troop then
        troop = P._playerCard:getTroop(index, true)
    end

    local cardNum = 0
    for i = 1, #troop do 
        cardNum = cardNum + troop[i]._num 
    end

    return cardNum
end

function _M:hide()
    -- check card count
    local isTroopValid, msg = P._playerCard:checkTroop(self._curTroopIndex)
    if not isTroopValid then return require("Dialog").showDialog(msg, function()
        if Data.isDarkTroop(self._curTroopIndex) then
            P._playerRank:clearRank(SglMsgType_pb.PB_TYPE_RANK_POWER)
            self:syncTroop()
            _M.super.hide(self)
        end
    end, true) end

    -- hide
    P._playerRank:clearRank(SglMsgType_pb.PB_TYPE_RANK_POWER)

    self:syncTroop()

    _M.super.hide(self)
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if string.sub(curStep, 1, 10) == "troop card" then
        local card = nil
        for i = 1, self._cardList._itemRow do
            for j = 1, self._cardList._itemCol do
                if not self._cardList._items[i][j]._locked then
                    card = self._cardList._items[i][j]
                    break
                end
            end
            if card ~= nil then break end
        end
        local linkNodes = {}
        for i = 1, self._cardList._itemRow do
            for j = 1, self._cardList._itemCol do
                linkNodes[#linkNodes + 1] = self._cardList._items[i][j]._thumbnail
            end
        end
        --local index = tonumber(string.sub(curStep, 11, 12))
        --local card = self._cardList._items[index <= 4 and 1 or 2][index <= 4 and index or (index - 4)]
        local dstX = self:convertToNodeSpace(card:convertToWorldSpace(cc.p(lc.w(card) / 2, lc.h(card) / 2))).x
        local dstY = self:convertToNodeSpace(self._troopList:convertToWorldSpace(cc.p(lc.w(self._troopList) / 2, lc.h(self._troopList) / 2))).y
        GuideManager.setOperateLayer(card._thumbnail, cc.p(dstX, dstY), linkNodes)
    elseif curStep == "rare card" then
        local card = self._cardList._items[1][1]
        GuideManager.setOperateLayer(card._thumbnail)
    elseif curStep == "show tab magic" then
        local tab = self._tabArea._tabs[2]
        GuideManager.setOperateLayer(tab)  
    elseif curStep == "show tab rare" then
        local tab = self._tabArea._tabs[4]
        GuideManager.setOperateLayer(tab)
    elseif curStep == "leave manage troop" then
        GuideManager.setOperateLayer(self._titleArea._btnBack)
    else
        return
    end
    
    event:stopPropagation()
end

function _M:addCardToTroop(troop, infoId)
    for i = 1, #troop do
        local troopCard = troop[i]
        if troopCard._infoId == infoId then
            troopCard._num = troopCard._num + 1
            return
        end
    end

    troop[#troop + 1] = {_infoId = infoId, _num = 1}
end

function _M:removeCardFromTroop(troop, infoId)
    for i = 1, #troop do
        local troopCard = troop[i]
        if troopCard._infoId == infoId then
            troopCard._num = troopCard._num - 1
            if troopCard._num == 0 then
                table.remove(troop, i)
            end           
            break
        end
    end
end

function _M:getTroopCardCount(troop, infoId)
    for i = 1, #troop do
        local troopCard = troop[i]
        if troopCard._infoId == infoId then
            return troopCard._num
        end
    end

    return 0
end

function _M:getTroopItem(infoId)
    local items = self._troopList:getItems()

    for i = 1, #items do
        local item = items[i]._item
        local thumbnail = item._thumbnail
        if thumbnail and thumbnail._infoId == infoId then
            return item
        end
    end

    return nil
end

function _M:getCardItem(infoId)
    for i = 1, self._cardList._itemRow do
        for j = 1, self._cardList._itemCol do
            local item = self._cardList._items[i][j]
            if item and item._thumbnail._infoId == infoId then
                return item
            end
        end
    end

    return nil
end

function _M:playAction(infoId, isToTroop, scrPos)
    self:runAction(lc.sequence(
        lc.delay(0),
        lc.call(function () 
            local cardPos, iconPos
            if isToTroop then
                cardPos = scrPos

                local iconUi = self:getTroopItem(infoId)
                iconPos = iconUi and self:convertToNodeSpace(iconUi:convertToWorldSpace(cc.p(lc.cw(iconUi), lc.ch(iconUi)))) or cc.p(ClientView.SCR_W - 120, 60)
                iconPos.x = math.min( ClientView.SCR_W - 120,  math.max(0, iconPos.x) )
            else
                iconPos = scrPos

                local cardUi = self:getCardItem(infoId)
                cardPos = cardUi and self:convertToNodeSpace(cardUi:convertToWorldSpace(cc.p(lc.cw(cardUi), lc.ch(cardUi)))) or cc.p(100, ClientView.SCR_CH + 50)
            end

            local node = cc.Node:create()
            self:addChild(node)

            local par1 = Particle.create("sz1")
            lc.addChildToCenter(node, par1)

            local par2 = Particle.create("sz2")
            lc.addChildToCenter(node, par2)

            local startPos = isToTroop and cardPos or iconPos
            local endPos = isToTroop and iconPos or cardPos

            node:setPosition(startPos)
            node:setScale(2.0)

            node:runAction(lc.sequence(
                lc.moveTo(0.4, endPos),
                lc.call(function () 
                    par1:setDuration(0.1)
                    par2:setDuration(0.1)
                end),
                lc.delay(1.0),
                lc.remove()
                ))
        end)
        ))
end

--------------- event -------------------------

function _M:onCardFlagDirty(event)
    self:updateButtonFlags()

    local item = self:getCardItem(event._infoId)
    if item then
        item._thumbnail:updateFlag()
    end
end

function _M:updateButtonFlags()
    local number = P._playerCard:getMonsterFlag()
    ClientView.checkNewFlag(self._tabArea._tabs[1], number, 40, -2)

    local number = P._playerCard:getMagicFlag()
    ClientView.checkNewFlag(self._tabArea._tabs[2], number, 40, -2)
end

function _M:syncTroop()
    ClientData.sendTroops(true, self._curTroopIndex)

    if Data.isNormalTroop(self._curTroopIndex) then
        ClientData.sendDefTroopIndex(self._curTroopIndex)
     
        local troop = ClientData._cloneTroops[self._curTroopIndex]
        if troop ~= nil and #troop > 0 then  
            P:setCurrentTroopIndex(self._curTroopIndex, false)
        end
    end

    if Data.isUnionBattleTroop(self._curTroopIndex) then
        return ClientData.sendQuitGroupCards()
    end
end

return _M