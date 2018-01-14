local _M = class("CardSelectForm", BaseForm)

local CardList = require("CardList")
local FilterWidget = require("FilterWidget")
local CardInfoPanel = require("CardInfoPanel")

_M.MODE_SWALLOW = 1
_M.MODE_TRANSFER = 5
_M.MODE_RARE_COMPOSE = 6

local THUMBNAIL_SCALE = 0.6
local BOTTOM_H = 80

local FORM_SIZE = cc.size(math.min(1200, lc.Director:getVisibleSize().width) - (16 + V.FRAME_TAB_WIDTH) * 2, 680)

local initFlag = bor(BaseForm.FLAG.ADVANCE_TITLE_BG, BaseForm.FLAG.PAPER_BG, BaseForm.FLAG.TOP_AREA, BaseForm.FLAG.BOTTOM_AREA, BaseForm.FLAG.SCROLL_H)

function _M.createSwallowForm(exceptCard, selectCards)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)    
    panel:initSwallowForm(exceptCard, selectCards)
    
    return panel 
end

function _M.createTransferForm(selectType, quality, exceptCards, selectCards)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)    
    panel:initTransferForm(selectType, quality, exceptCards, selectCards)
    
    return panel 
end

function _M.createRareComposeForm(cards, selectCards)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:initRareComposeForm(cards, selectCards)

    return panel
end

function _M:initSwallowForm(exceptCard, selectCards)
    self._mode = _M.MODE_SWALLOW
    if type(exceptCard) == "number" then
        self._exceptCard = nil
        self._selectType = exceptCard
    else
        self._exceptCard = exceptCard
        self._selectType = self._exceptCard._type
    end
    
    local title = ''
    if self._selectType == Data.CardType.monster then
        title = Str(STR.MONSTER)
    elseif self._selectType == Data.CardType.book then
        title = Str(STR.BOOK)
    elseif self._selectType == Data.CardType.horse then
        title = Str(STR.HORSE)
    elseif self._selectType == Data.CardType.weapon then
        title = Str(STR.WEAPON)
    elseif self._selectType == Data.CardType.armor then
        title = Str(STR.ARMOR)
    end
    _M.super.init(self, FORM_SIZE, Str(STR.SELECT)..title, initFlag)
    
    self._selectCards = selectCards
    
    local width = lc.w(self._form) - _M.FRAME_THICK_LEFT - _M.FRAME_THICK_RIGHT - 24
    if self._selectType == Data.CardType.monster then
        self._filterWidget = FilterWidget.create(FilterWidget.ModeType.monster, width)
        self._filterWidget:setFilterNature(FilterWidget.FilterNature.all)        
    elseif self._selectType == Data.CardType.book then
        self._filterWidget = FilterWidget.create(FilterWidget.ModeType.book, width)
    elseif self._selectType == Data.CardType.horse then
        self._filterWidget = FilterWidget.create(FilterWidget.ModeType.horse, width)
    elseif self._selectType == Data.CardType.weapon then
        self._filterWidget = FilterWidget.create(FilterWidget.ModeType.weapon, width)
    elseif self._selectType == Data.CardType.armor then
        self._filterWidget = FilterWidget.create(FilterWidget.ModeType.armor, width)
    end
    
    self._filterWidget:resetAllFilter()
    self._filterWidget:registerSortFilterHandler(function() self:updateCardList() end)          
    lc.addChildToPos(self._form, self._filterWidget, cc.p(lc.w(self._form) / 2, 40))
    
    self:createListArea()
    self:createBottomArea()
end

function _M:initTransferForm(selectType, quality, exceptCards, selectCards)
    self._mode = _M.MODE_TRANSFER
    
    self._selectType = selectType
    self._exceptCards = exceptCards
    self._selectCards = selectCards

    local title = ''
    if self._selectType == Data.CardType.monster then
        title = Str(STR.MONSTER)
    elseif self._selectType == Data.CardType.magic then
        title = Str(STR.MAGIC)
    elseif self._selectType == Data.CardType.trap then
        title = Str(STR.TRAP)
    end

    local visibleSize = lc.Director:getVisibleSize()
    _M.super.init(self, cc.size(visibleSize.width - (16 + V.FRAME_TAB_WIDTH) * 2, visibleSize.height - 40), Str(STR.SELECT)..title, initFlag)
    
    if self._selectType == Data.CardType.monster then
        self._filterWidget = FilterWidget.create(FilterWidget.ModeType.monster, lc.h(self._frame) - 80)
        self._filterWidget:setFilterNature(FilterWidget.FilterNature.all)        
    elseif self._selectType == Data.CardType.magic then
        self._filterWidget = FilterWidget.create(FilterWidget.ModeType.magic, lc.h(self._frame) - 80)
    elseif self._selectType == Data.CardType.trap then
        self._filterWidget = FilterWidget.create(FilterWidget.ModeType.trap, lc.h(self._frame) - 80)
    end
    
    self._filterWidget:resetAllFilter()
    self._filterWidget:registerSortFilterHandler(function() self:updateCardList() end)          
    lc.addChildToPos(self._frame, self._filterWidget, cc.p(lc.w(self._frame) + V.FRAME_TAB_WIDTH - lc.w(self._filterWidget) / 2 + 2, lc.h(self._filterWidget) / 2))
    lc.offset(self._filterWidget._searchArea, 0, 196)
    
    self:createListArea()
    self:createBottomArea()

    self:updateSelectCount()
end

function _M:initRareComposeForm(cards, selectCards)
    self._mode = _M.MODE_RARE_COMPOSE
    self._cards = cards
    self._selectCards = selectCards
    local title = ""

    local visibleSize = lc.Director:getVisibleSize()
    _M.super.init(self, cc.size(visibleSize.width - (16 + V.FRAME_TAB_WIDTH) * 2, visibleSize.height - 40), Str(STR.SELECT)..title, initFlag)
    
    self:createListArea()
    self:createBottomArea()

    self:updateSelectCount()
end

function _M:createBottomArea()
    local bottomArea = V.createLineSprite("img_bottom_bg", lc.w(self._cardList))
    bottomArea:setAnchorPoint(0.5, 0)
    lc.addChildToPos(self._frame, bottomArea, cc.p(lc.w(self._frame) / 2, V.FRAME_INNER_BOTTOM - 12), -1)
    self._bottomArea = bottomArea

    local info = V.createBMFont(V.BMFont.huali_26, '')
    info:setAnchorPoint(0, 0.5)
    lc.addChildToPos(bottomArea, info, cc.p(20, lc.h(bottomArea) / 2))
    self._info = info

    local btnConfirm = V.createScale9ShaderButton("img_btn_1_s", 
        function() if self._cardList:getSelectedCardNumber()<=6 then self:onConfirmSelected() end end,
        V.CRECT_BUTTON, 100, V.CRECT_BUTTON_S.height)
    btnConfirm:setDisabledShader(V.SHADER_DISABLE)
    btnConfirm:addLabel(Str(STR.OK))
    lc.addChildToPos(self._bottomArea, btnConfirm, cc.p(lc.w(self._bottomArea) - lc.w(btnConfirm) / 2 - 20, lc.h(self._bottomArea) / 2))
    btnConfirm:setEnabled(false)
    self._btnConfirm = btnConfirm
    
    if self._mode == _M.MODE_SWALLOW then
        local btnSelectAll = V.createShaderButton("img_btn_1", function(sender) self._cardList:selectAllCards() end)
        btnSelectAll:addLabel(Str(STR.SELECT_ALL))
        lc.addChildToPos(self._form, btnSelectAll, cc.p(lc.w(btnSelectAll) / 2 + _M.FRAME_THICK_LEFT + 12, lc.y(btnConfirm)))
        
        local btnUnselectAll = V.createShaderButton("img_btn_1", function(sender) self._cardList:unselectAllCards() end)
        btnUnselectAll:addLabel(Str(STR.UNSELECT_ALL))
        lc.addChildToPos(self._form, btnUnselectAll, cc.p(lc.right(btnSelectAll) + lc.w(btnUnselectAll) / 2 + 10, lc.y(btnConfirm)))
        
        local selLabel
        selLabel, self._cardNumValue = V.createKeyValueLabel(Str(STR.SELECTED), "0", V.FontSize.S1, true)
        selLabel:addToParent(self._form, cc.p(lc.right(btnUnselectAll) + 280, lc.y(btnUnselectAll)))        
            
    end
end

function _M:createListArea()
    local cardList, mode = CardList.create(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM - BOTTOM_H), THUMBNAIL_SCALE), self._mode
    cardList:setAnchorPoint(0.5, 0.5)
    self._cardList = cardList

    if mode == _M.MODE_TRANSFER then
        cardList:setMode(CardList.ModeType.multi_select)
    elseif mode == _M.MODE_RARE_COMPOSE then
        cardList._rareCards = self._cards
        cardList:setMode(CardList.ModeType.multi_select)
    else
        cardList:setMode(CardList.ModeType.check)
    end

    cardList:setPosition(lc.w(self._frame) / 2, lc.h(self._frame) / 2 + BOTTOM_H  / 2)
    cardList:registerCardSelectedHandler(function(data) 
        CardInfoPanel.create(data, nil, CardInfoPanel.OperateType.own):show()
    end)
    cardList:registerCardSelectCountChangeHandler(function(data) 
        self:onCardSelectCountChange()
    end)
    self._form:addChild(cardList)

    local offsetx = (lc.w(self._frame) - lc.w(self._cardList)) / 2 + 16
    self._cardList._pageLeft._pos = cc.p(-offsetx, 26)
    self._cardList._pageRight._pos = cc.p(lc.w(self._cardList) + offsetx, 26)

    offsetx = offsetx + 32
    local pageBg = lc.createSprite({_name = "img_page_bg", _size = cc.size(125, 33), _crect = cc.rect(11, 11, 4, 8)}) 
    lc.addChildToPos(self._frame, pageBg, cc.p(-lc.w(pageBg) / 2 + 12, 40), -1)
    self._pageBg = pageBg
    self._cardList._pageLabel:setPosition(-offsetx, -68)
    
    self:updateCardList()
end

function _M:updateCardList()        
    local filters, sort = {}
    if self._filterWidget then        
        local sortFunc, isAscending = self._filterWidget:getSortFunc()
        if sortFunc ~= nil then sort = {_func = sortFunc, _isReverse = not isAscending} end

        local filterCountryFunc, FilterNatureKeyword = self._filterWidget:getFilterNatureFunc()
        if filterCountryFunc ~= nil then filters[CardList.FilterType.country] = {_func = filterCountryFunc, _keyVal = FilterNatureKeyword} end  
        
        local filterCategoryFunc, filterCategoryKeyword = self._filterWidget:getFilterCategoryFunc()
        if filterCategoryFunc then filters[CardList.FilterType.category] = {_func = filterCategoryFunc, _keyVal = filterCategoryKeyword} end   
        
        local filterCostFunc, filterCostKeyword = self._filterWidget:getFilterLevelFunc()
        if filterCostFunc then filters[CardList.FilterType.cost] = {_func = filterCostFunc, _keyVal = filterCostKeyword} end  

        local filterQualityFunc, filterQualityKeyword = self._filterWidget:getFilterQualityFunc()
        if filterQualityFunc ~= nil then filters[CardList.FilterType.quality] = {_func = filterQualityFunc, _keyVal = filterQualityKeyword} end
        
        local filterSearchFunc, keyword = self._filterWidget:getFilterSearchFunc()
        if filterSearchFunc ~= nil then filters[CardList.FilterType.search] = {_func = filterSearchFunc, _keyVal = keyword} end
    end        
    
    local cards = P._playerCard:getCards(self._selectType)
    if self._mode==_M.MODE_RARE_COMPOSE then
        cards = self._cards
    end
    local exceptCards = {}
    for k, v in pairs(cards) do
        --v._selected = self._selectCards[k] or 0
        
        if self._mode == _M.MODE_SWALLOW then
            if v == self._exceptCard or (not v:isSwallowable()) then
                exceptCards[k] = v                
            end
        elseif self._mode == _M.MODE_TRANSFER then
            for i = 1, #self._exceptCards do
                if v == self._exceptCards[i] then
                    exceptCards[k] = v
                end
            end
        end

    end
    
    self._cardList:init(self._selectType, exceptCards, sort, filters, self._selectCards)
    self._cardList:refresh(true)
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    self._listeners = {}
    
    local listener = lc.addEventListener(Data.Event.card_select, function(event) self:updateView() end)
    table.insert(self._listeners, listener)
    
    listener = lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end)
    table.insert(self._listeners, listener)
    
    self:updateView()           
end

function _M:onExit()
    _M.super.onExit(self)
    
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i]) 
    end
end

function _M:onShowActionFinished()
    if GuideManager.isGuideEnabled() then    
        GuideManager.finishStep()
    end
end

function _M:onHideActionFinished()
    if GuideManager.isGuideEnabled() then
        GuideManager.finishStep()
    end
end

function _M:onConfirmSelected()
    if self._selectRadioHandler ~= nil then
        local selectCard = nil
        for k, v in pairs(self._selectCards) do
            selectCard = k
        end        
        self._selectRadioHandler(selectCard)
    end
    
    if self._selectHandler ~= nil then        
        self._selectHandler(self._selectCards)
    end
    
    self:hide()
end

function _M:updateView()
--    if self._selectCards then self._selectCards = self._cardList:getSelectedCards() end

    self._selectCount = 0
    for k, v in pairs(self._selectCards) do
        self._selectCount = self._selectCount + v
    end
   
    if self._cardNumValue ~= nil then self._cardNumValue:setString(self._selectCount) end    
end

function _M:registerRadioSelectedHandler(handler)
    self._selectRadioHandler = handler
end

function _M:registerSelectedHandler(handler)
    self._selectHandler = handler
end

function _M:onGuide(event)
    if GuideManager.getCurStepName() == "confirm pick card" then        
        GuideManager.setOperateLayer(self._btnConfirm)
    else
        return
    end
    
    event:stopPropagation()
end

function _M:onCardSelectCountChange()
    self:updateSelectCount()
end

function _M:updateSelectCount()
    local count = self._cardList:getSelectedCardNumber()
    self._info:setString(string.format(Str(STR.SELECT_MULTI_NEED), 6)..Str(STR.COMMA)..string.format(Str(STR.SELECT_MULTI_CURRENT), count))
    self._btnConfirm:setEnabled(count<=6)
end

return _M