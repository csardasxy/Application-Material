local _M = class("CardList", lc.ExtendUIWidget)

_M.ModeType = 
{
    sacrifice = 1,
    mix = 2,
    radio = 3,
    check = 4,
    mix_book = 5,
    exchange = 6,
    troop = 7,
    expedition_troop = 8,
    hire = 9,
    multi_select = 10,
    recruite = 11,
    recruite_langend = 12,
    recruite_list = 13,
    union_shop = 14,
    rare_shop = 15,
    god_shop = 16,
    union_battle_troop = 17,
    diamond_shop = 18,
    dark_troop = 19,
}

_M.FilterType = 
{
    country = 1,
    equip = 2,
    quality = 3,
    category = 5,
    status = 5,
    search = 6,
    cost = 7,
}

function _M.create(size, itemScale, hideBottom, addH)
    local list = _M.new(lc.EXTEND_LAYOUT)
    list:setTouchEnabled(not GuideManager.isGuideEnabled())    
    list:setContentSize(size)
    list:setCascadeOpacityEnabled(true)
    list._itemScale = itemScale or 1
    list._hideBottom = hideBottom
    list._addH = addH

    list._tip = cc.Label:createWithTTF("", V.TTF_FONT, V.FontSize.S1)
    list._tip:setPosition(lc.w(list) / 2, lc.h(list) / 2)
    list:addProtectedChild(list._tip)   
    
    list:initUI()
    
    return list
end

function _M:initUI()
    local bottomH = self._hideBottom and 0 or 50
    bottomH = bottomH + (self._addH and self._addH or 0)
    local w = V.CARD_SIZE.width * self._itemScale
    local h = (V.CARD_SIZE.height + bottomH) * self._itemScale
    local r, c = 2, 4
    local gapH = (lc.h(self) - r * h) / (r + 1)
    local gapW = (lc.w(self) - c * w) / (c + 1)

    while gapW > 40 do 
        c = c + 1
        gapW = (lc.w(self) - c * w) / (c + 1)
    end

    while gapW < 28 do 
        c = c - 1
        gapW = (lc.w(self) - c * w) / (c + 1)
    end

    --if r * h > lc.h(self) then r = 1 end
    
    local x = gapW + w / 2
    local y = gapH + h / 2 + bottomH * self._itemScale / 2
    self._itemRow, self._itemCol = r, c
    self._curPage = 1
    self._totalPage = 1

    self._items = {{}, {}}
    for i = 1, r do
        for j = 1, c do
            local item = require("CardThumbnail").createFromPool(nil, self._itemScale)
            local thumbnail = item._thumbnail
            --thumbnail:setScale(THUMBNAIL_SCALE)
            thumbnail._infoId = nil
            thumbnail._index = (i - 1) * c + j
            thumbnail:setTouchEnabled(true)
            thumbnail:addTouchEventListener(function(sender, type)
                self:onTouchThumbnail(sender, type)
            end)  

            item:setVisible(false)
            
            if r > 1 then
                lc.addChildToPos(self, item, cc.p(x + (j - 1) * (w + gapW), y + (2 - i) * (h + gapH)))
            else
                lc.addChildToPos(self, item, cc.p(x + (j - 1) * (w + gapW), y + (h + gapH) / 2))
            end
            self._items[i][j] = item
        end
    end

    local pos = cc.p(self._items[1][1]:getPositionX() - V.CARD_SIZE.width / 2 - 30, lc.h(self) / 2)
    self._pageLeft = V.createPageArrow(true, pos, function() 
        if self._curPage > 1 then self._curPage = self._curPage - 1 end
        self:refresh(false)
    end)
    lc.addChildToPos(self, self._pageLeft, pos)

    pos = cc.p(self._items[1][self._itemCol]:getPositionX() + V.CARD_SIZE.width / 2 + 30, lc.h(self) / 2)
    self._pageRight = V.createPageArrow(false, pos, function()
        if self._curPage < self._totalPage then self._curPage = self._curPage + 1 end
        self:refresh(false)
    end)
    lc.addChildToPos(self, self._pageRight, pos)

    local pageLabel = V.createBMFont(V.BMFont.huali_26, "1/1")
    pageLabel:setScale(0.8)
    lc.addChildToPos(self, pageLabel, cc.p(lc.w(self) - 64, lc.h(self) + 20))
    self._pageLabel = pageLabel
end  

function _M:init(type, excepts, sort, filters, selectedCards)    
    self._type = type
    self._excepts = excepts

    if sort then
        self:setSortFunc(sort._func, sort._isReverse, false)
    else
        self._sort = nil
    end

    self._filters = {}
    if filters then
        for k, v in pairs(filters) do
            self:setFilterFunc(k, v._func, v._keyVal, false)
        end
    end

    self._selectedCards = selectedCards or {}
end

function _M:onEnter()
    self._listeners = {}

    local listener = lc.addEventListener(Data.Event.card_list_dirty, function(event)
        if self._type == event._type then
            self:refresh(false)
        end
    end)
    table.insert(self._listeners, listener)

    local listener = lc.addEventListener(Data.Event.card_dirty, function(event)
        for i = 1, self._itemRow do
            for j = 1, self._itemCol do
                local item = self._items[i][j]
                if item._thumbnail._infoId == event._infoId then
                    self:refreshItem(item, event._infoId)
                end
            end
    end
    end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end)
    table.insert(self._listeners, listener)           
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
    self._listeners = {}
end

function _M:onCleanup()
    for i = 1, self._itemRow do
        for j = 1, self._itemCol do
            local item = self._items[i][j]
            require("CardThumbnail").releaseToPool(item)
        end
    end
end

function _M:getThumbnail(data)
    for i = 1, self._itemRow do
        for j = 1, self._itemCol do
            local item = self._items[i][j]
            if item and item._thumbnail._infoId == data then
                return item._thumbnail
            end
        end
    end
end

function _M:insertItem(card, index)
    local newIndex = index
    if newIndex == nil or newIndex <= 0 then
        newIndex = #self._cards + 1
    end
    table.insert(self._cards, newIndex, card)
end

function _M:onTouchThumbnail(sender, type)
    sender:stopAllActions()
    if type == ccui.TouchEventType.began then
        sender:runAction(cc.ScaleTo:create(0.1, 0.95))
        if self._onTouchThumbnail ~= nil then self._onTouchThumbnail(sender, type) end
    elseif type == ccui.TouchEventType.ended then
        sender:runAction(cc.ScaleTo:create(0.08, 1.0))
        if self._onTouchThumbnail ~= nil then self._onTouchThumbnail(sender, type) end
        if self._onCardSelected ~= nil then  self._onCardSelected(sender._infoId, sender._index) end
    elseif type == ccui.TouchEventType.moved then
        if self._onTouchThumbnail ~= nil then self._onTouchThumbnail(sender, type) end
    elseif type == ccui.TouchEventType.canceled then
        sender:runAction(cc.ScaleTo:create(0.08, 1.0))
        if self._onTouchThumbnail ~= nil then self._onTouchThumbnail(sender, type) end
    end
end

function _M:registerCardSelectedHandler(handler)
    self._onCardSelected = handler
end

function _M:registerTouchThumbnail(handler)
    self._onTouchThumbnail = handler
end

function _M:registerTapBtnCustom1(handler)
    self._onTapBtnCustom1 = handler
end

function _M:registerTapRadio(handler)
    self._onTapRadio = handler
end

function _M:registerTapCheck(handler)
    self._onTapCheck = handler
end

function _M:registerCardSelectCountChangeHandler(handler)
    self._onCardSelectCountChange = handler
end

function _M:setMode(mode)
    if self._mode then return end
    self._mode = mode
end

function _M:setSortFunc(func, isReverse)
    self._sort = 
    {
        _func = func,
        _isReverse = isReverse,
    }
end

function _M:setFilterFunc(filterType, func, keyVal)
    self._filters[filterType] = {_func = func, _keyVal = keyVal}
end

function _M:refresh(isReset)
    local selected, front, arr, back = {}, {}, {}, {}
    
    if self._mode == _M.ModeType.hire then
        local cards = P._playerUnion:getMyUnion()._hires
        for _, v in pairs(cards) do
            if v:isSelfCard() then
                table.insert(back, v)
            elseif v:isHired() then
                table.insert(arr, v)
            else
                table.insert(front, v)
            end
        end

    elseif self._mode == _M.ModeType.union_shop then
        for i = 1, #self._unionInfo do
            local infoId = self._unionInfo[i]._infoId
            arr[#arr + 1] = infoId 
        end

    elseif self._mode == _M.ModeType.rare_shop then
        for i = 1, #self._rareInfo do
            local infoId = self._rareInfo[i]._infoId
            arr[#arr + 1] = infoId 
        end

    elseif self._mode == _M.ModeType.diamond_shop then
        for i = 1, #self._diamondInfo do
            local infoId = self._diamondInfo[i]._infoId
            arr[#arr + 1] = infoId 
        end

    elseif self._mode == _M.ModeType.god_shop then
        for i = 1, #self._godInfo do
            local infoId = self._godInfo[i]._infoId
            arr[#arr + 1] = infoId 
        end

    elseif self._mode == _M.ModeType.recruite or self._mode == _M.ModeType.recruite_langend then
        for i = 1, #self._recruiteInfo do
            local infoId = self._recruiteInfo[i]._infoId
            arr[#arr + 1] = infoId 
        end

    elseif self._mode == _M.ModeType.recruite_list then
        for i = 1, #self._recruiteInfo do
            local infoId = self._recruiteInfo[i]._infoId
            arr[#arr + 1] = infoId
        end
    elseif self._mode == _M.ModeType.multi_select and self._rareCards~=nil then
        for i = 1, #self._rareCards do
            local selectCard = {}
            selectCard._infoId = self._rareCards[i]
            selectCard._selected = self._selectedCards[selectCard._infoId] or 0
            selectCard._num = P._playerCard:getCardCount(selectCard._infoId) - P._playerCard:getCardCountInTroop(selectCard._infoId)
            local selectedCards = self._selectedCards
            function selectCard:setSelected(num)
                selectCard._selected = num
                selectedCards[selectCard._infoId] = num
            end
            table.insert(arr, selectCard)
        end
    elseif self._mode == _M.ModeType.union_battle_troop then
        local cards = P._playerCard:getGroupCards(self._type)
        for k, v in pairs(cards) do
            if v > 0 then table.insert(arr, k) end
        end
    else
        local cards = P._playerCard:getCards(self._type)
        for k, v in pairs(cards) do
            if self._excepts == nil or self._excepts[k] == nil then
                while true do
                    if self._mode == _M.ModeType.troop then
                        if GuideManager.isGuideEnabled() then
                            if self._guideFront == nil then self._guideFront = {} end
                            if self._guideFront[k] == nil then self._guideFront[k] = (P._playerCard:getCardCountInTroop(k) < P._playerCard:getCardCount(k)) end
                        end
                        if self._guideFront and (self._guideFront[k] == true) then
                                table.insert(front, k)
                            break
                        end
                    elseif self._mode == _M.ModeType.radio or self._mode == _M.ModeType.check then
                        if self._selectedCards[k] then
                            table.insert(selected, k)
                            break
                        end
                    elseif self._mode == _M.ModeType.sacrifice then
                        if not GuideManager.isGuideEnabled() --[[ TODO o and (not self._ignoreNewCards and v.isNew and v:isNew()) ]] then
                            table.insert(front, k)
                            break
                        end
                    elseif self._mode == _M.ModeType.expedition_troop then
                        --TODO 
                        --[[
                        if v._isDead then
                            table.insert(front, k)
                            break
                        end
                        ]]
                    end
                        
                    if v > 0 then table.insert(arr, k) end
                    break
                end
            end
        end  
    end
    
    if self._sort then
        selected = self._sort._func(P, selected, self._sort._isReverse)            
        front = self._sort._func(P, front, self._sort._isReverse)
        arr = self._sort._func(P, arr, self._sort._isReverse)
        back = self._sort._func(P, back, self._sort._isReverse)
    end

    for k, v in pairs(self._filters) do
        selected = v._func(P, selected, v._keyVal)
        front = v._func(P, front, v._keyVal)
        arr = v._func(P, arr, v._keyVal)
        back = v._func(P, back, v._keyVal)
    end
    
    local cardNum = #selected + #front + #arr + #back
    

    self._cards = {}
    
    for _, card in ipairs(selected) do self:insertItem(card) end
    for _, card in ipairs(front) do self:insertItem(card) end
    for _, card in ipairs(arr) do self:insertItem(card) end
    for _, card in ipairs(back) do self:insertItem(card) end

    self._totalPage = (#self._cards == 0) and 1 or (math.floor((#self._cards - 1) / (self._itemRow * self._itemCol)) + 1)
    if isReset then
        self._curPage = 1
    end

    for i = 1, self._itemRow do
        for j = 1, self._itemCol do
            local item = self._items[i][j]
            local card = self._cards[(self._curPage - 1) * self._itemRow * self._itemCol + (i - 1) * self._itemCol + j]
            self:refreshItem(item, card)
        end
    end

    self._pageLabel:setString(string.format("%s%d/%d%s", lc.str(STR.PAGE_PREFIX), self._curPage, self._totalPage, lc.str(STR.PAGE_SUFFIX)))
    self._pageLeft:setVisible(self._curPage > 1)
    self._pageLeft:float()
    
    self._pageRight:setVisible(self._curPage < self._totalPage)
    self._pageRight:float()

    self._tip:setString("")
    if self._mode == _M.ModeType.sacrifice 
    or self._mode == _M.ModeType.radio or self._mode == _M.ModeType.check or (self._mode == _M.ModeType.multi_select and self._rareCards==nil)
    or self._mode == _M.ModeType.troop or self._mode == _M.ModeType.expedition_troop or self._mode == _M.ModeType.dark_troop or self._mode == _M.ModeType.union_battle_troop then
        if cardNum == 0 then
            if self._type == Data.CardType.monster then
                self._tip:setString(string.format(Str(STR.LIST_EMPTY_NO_CARD), Str(STR.MONSTER)))
            elseif self._type == Data.CardType.magic then
                self._tip:setString(string.format(Str(STR.LIST_EMPTY_NO_CARD), Str(STR.MAGIC)))
            elseif self._type == Data.CardType.trap then
                self._tip:setString(string.format(Str(STR.LIST_EMPTY_NO_CARD), Str(STR.TRAP)))
            else
                self._tip:setString(string.format(Str(STR.LIST_EMPTY_NO_CARD), Str(STR.RARE)..Str(STR.MONSTER)))
            end
            self._tip:setColor(V.COLOR_LABEL_LIGHT)
        end
    elseif self._mode == _M.ModeType.multi_select and self._rareCards~=nil then
        if cardNum == 0 then
            self._tip:setString(Str(STR.COMPOSE_LIST_EMPTY_NO_CARD))
            self._tip:setColor(V.COLOR_LABEL_LIGHT)
        end
    elseif self._mode == _M.ModeType.recruite or self._mode == _M.ModeType.recruite_langend then
        if cardNum == 0 then
            if self:isMonster() then
                self._tip:setString(string.format(Str(STR.LIST_EMPTY_NO_X), Str(STR.MONSTER)..Str(STR.CARD)))
            elseif self._type == Data.CardType.magic then
                self._tip:setString(string.format(Str(STR.LIST_EMPTY_NO_X), Str(STR.MAGIC)..Str(STR.CARD)))
            elseif self._type == Data.CardType.trap then
                self._tip:setString(string.format(Str(STR.LIST_EMPTY_NO_X), Str(STR.TRAP)..Str(STR.CARD)))
            else
                self._tip:setString(string.format(Str(STR.LIST_EMPTY_NO_X), Str(STR.RARE)..Str(STR.MONSTER)..Str(STR.CARD)))
            end
            self._tip:setColor(V.COLOR_LABEL_LIGHT)
        end
    elseif self._mode == _M.ModeType.hire then
        if cardNum == 0 then
            self._tip:setString(Str(STR.LIST_EMPTY_NO_HIRE))
            self._tip:setColor(V.COLOR_LABEL_LIGHT)
        end
    elseif self._mode == _M.ModeType.union_shop then
        if cardNum == 0 then
            self._tip:setString(Str(STR.LIST_EMPTY_SHOP))
            self._tip:setColor(V.COLOR_LABEL_LIGHT)
        end
    elseif self._mode == _M.ModeType.rare_shop then
        if cardNum == 0 then
            self._tip:setString(Str(STR.LIST_EMPTY_SHOP))
            self._tip:setColor(V.COLOR_LABEL_LIGHT)
        end
    elseif self._mode == _M.ModeType.diamond_shop then
        if cardNum == 0 then
            self._tip:setString(Str(STR.LIST_EMPTY_SHOP))
            self._tip:setColor(V.COLOR_LABEL_LIGHT)
        end
    elseif self._mode == _M.ModeType.god_shop then
        if cardNum == 0 then
            self._tip:setString(Str(STR.LIST_EMPTY_SHOP))
            self._tip:setColor(V.COLOR_LABEL_LIGHT)
        end
    end
end

function _M:refreshItem(item, card)
    if card ~= nil then
        if self._mode == _M.ModeType.recruite or self._mode == _M.ModeType.recruite_langend then
            item._thumbnail:updateComponent(card)
        elseif self._mode == _M.ModeType.multi_select and self._rareCards then
            item._thumbnail:updateComponent(card._infoId)
        else
            item._thumbnail:updateComponent(card, P._playerCard:getSkinId(card))
        end
        item:setVisible(true)
        self:refreshItemCustom(item, card)
    else
        item:setVisible(false)
    end
end

function _M:refreshItemCustom(item, card)
--------------------------------- troop & expedition_troop & dark_troop & union_battle_troop --------------------------------------    
    if self._mode == _M.ModeType.troop or self._mode == _M.ModeType.expedition_troop or self._mode == _M.ModeType.union_battle_troop or self._mode == _M.ModeType.dark_troop then
        local statusRect = item._statusRect

        if self._mode == _M.ModeType.expedition_troop then
            local isShowStatusRect = (card._fragmentNum == nil and card._isDead)
            item:showStatusRect(isShowStatusRect, Str(STR.CARD_DEAD_STATUS), V.COLOR_TEXT_RED)
        end

        local troop = ClientData._cloneTroops[self._troopIndex]
        if self._mode == _M.ModeType.union_battle_troop then
            local count, specificCount = self:getCardCountInTroop(troop, card)
            local countInOtherTroops = self:getCardCountInUnionTroops(card)
            local info, cardType = Data.getInfo(item._thumbnail._infoId)
            item._countArea:update(true, count, info._maxCount * Data.GROUP_NUM, specificCount, P._playerCard:getGroupCardCount(card) - countInOtherTroops)
        elseif self._mode == _M.ModeType.dark_troop then
            local count, specificCount = self:getCardCountInTroop(troop, card)
            local countInOtherTroops = self:getCardCountInDarkTroops(card)
            local info, cardType = Data.getInfo(item._thumbnail._infoId)
            item._countArea:update(true, count, info._maxCount, specificCount, P._playerCard:getCardCount(card) - countInOtherTroops)
        else
            local count, specificCount = self:getCardCountInTroop(troop, card)
            local info, cardType = Data.getInfo(item._thumbnail._infoId)
            item._countArea:update(true, count, info._maxCount, specificCount)
        end

        item._thumbnail:updateFlag()
        
--------------------------------- troop & expedition troop --------------------------------------        
        
--------------------------------- radio & check -------------------------------------------------        
    elseif self._mode == _M.ModeType.radio or self._mode == _M.ModeType.check then   
        local button
        if self._mode == _M.ModeType.radio then
            item._btnRadio:setVisible(true)                            
            item._btnRadio._checkedSprite:setVisible(self._selectedCards[card] ~= nil)
            if self._selectedCards[card] then self._lastSelectCard = card end
                
            item._btnRadio:setEnabled(true)
            item._btnRadio:addTouchEventListener(function(sender, type) 
                if type == ccui.TouchEventType.ended then
                    lc.Audio.playAudio(AUDIO.E_BUTTON_DEFAULT)
                    if self._lastSelectCard ~= nil and self._lastSelectCard ~= card then
                        self._selectedCards[self._lastSelectCard] = nil
                        P._playerCard:sendCardSelect(self._lastSelectCard, 0)
                    end
                    self._lastSelectCard = card
                    if self._selectedCards[card] then
                        self._selectedCards[card] = nil             
                        P._playerCard:sendCardSelect(self._lastSelectCard, 0)
                    else
                        self._selectedCards[card] = 1             
                        P._playerCard:sendCardSelect(self._lastSelectCard, 1)
                    end
                    if self._onTapRadio ~= nil then self._onTapRadio(card) end
                                        
                    if GuideManager.isGuideEnabled() then
                        GuideManager.finishStep()
                    end
                end
            end)
            
            button = item._btnRadio
        else
            item._btnCheck:setVisible(true)
            item._btnCheck._checkedSprite:setVisible(card._selected > 0)
            item._btnCheck:setEnabled(true)
            item._btnCheck:addTouchEventListener(function(sender, type)
                if type == ccui.TouchEventType.ended then
                    lc.Audio.playAudio(AUDIO.E_BUTTON_DEFAULT)
                    card:setSelected(card._selected == 0 and 1 or 0)
                    if self._onTapCheck ~= nil then self._onTapCheck(card) end

                    if GuideManager.isGuideEnabled() then
                        GuideManager.finishStep()
                    end
                end
            end)              
            
            button = item._btnCheck
        end
         
------------------------------- radio & check ----------------------------------------------     

------------------------------- multi_select ---------------------------------------------------------    
    elseif self._mode == _M.ModeType.multi_select then
        local multiSelectArea = item._multiSelectArea
        multiSelectArea:setVisible(true)
        multiSelectArea._callbackAdd = function(sender) 
            local num = card._num
            if card._selected < num then 
                card:setSelected(card._selected + 1)
                multiSelectArea._label:setString(card._selected)
                if self._onCardSelectCountChange then self._onCardSelectCountChange() end
            end
        end
        multiSelectArea._callbackMinus = function(sender) 
            if card._selected > 0 then 
                card:setSelected(card._selected - 1)
                multiSelectArea._label:setString(card._selected)
                if self._onCardSelectCountChange then self._onCardSelectCountChange() end
            end
        end
        multiSelectArea._label:setString(card._selected) 
------------------------------- multi_select ---------------------------------------------------------    
    
------------------------------- mix ---------------------------------------------------------    
    elseif self._mode == _M.ModeType.mix or self._mode == _M.ModeType.mix_book then
        --[[
        local statusRect = item._statusRect

        local updateFragCount = function()
            local fragNum
            if self._mode == _M.ModeType.mix then
                fragArea._ico:setSpriteFrame("card_fragment")
                fragNum = P._playerCard:getFragmentNum(card._infoId)
            else
                if card._fragmentNum then 
                    fragArea._ico:setSpriteFrame("card_thu_"..ClientData.getPicIdByInfoId(card._info._fid))
                else
                    local fragment = P._playerCard:getCommonFragmentByQuality(card._type, card:getQuality())
                    fragArea._ico:setSpriteFrame("card_thu_"..ClientData.getPicIdByInfoId(fragment._infoId))
                end
                fragNum = P._playerCard:getMixCommonFragmentNum(card._infoId)
            end

            fragArea._label:setString(string.format("%d/%d", fragNum, card._info._fragmentCount))
        end
        ]]

        --updateFragCount()
 

        --[[
        item._btnCustom1:setVisible(true)
        item._btnCustom1:setEnabled(true)
        item._btnCustom1:setContentSize(160, V.CRECT_BUTTON.height)
        item._btnCustom1._label:setString(Str(STR.COMPOSE))
        item._btnCustom1._label:setPositionX(lc.w(item._btnCustom1) / 2)        
        item._btnCustom1._callback = function() if self._onTapBtnCustom1 then self._onTapBtnCustom1(card) end end

        --item:setContentSize(lc.w(item._thumbnail), lc.h(item._thumbnail) + lc.h(item._btnCustom1) + 40)
        --item._thumbnail:setPosition(lc.w(item) / 2, lc.h(item) - lc.h(item._thumbnail) / 2)
        item._btnCustom1:setPosition(lc.w(item) / 2, lc.h(item._btnCustom1) / 2)        
        ]]
        
        item._countArea:update(true)
--------------------------------- mix ---------------------------------------------------------------------------------      
    
    elseif self._mode == _M.ModeType.hire then
        --[[
        local btn = item._btnCustom1
        btn:setVisible(true)
        btn:setEnabled(true)
        btn:setContentSize(160, V.CRECT_BUTTON.height)
        btn._label:setPositionX(lc.w(btn) / 2)

        btn._callback = function() if self._onTapBtnCustom1 then self._onTapBtnCustom1(card) end end
        if card:isSelfCard() then
            btn._label:setString(Str(STR.UNION_HIRE_MY))
        else
            if card:isHired() then
                btn._label:setString(Str(STR.HIRE_INVALID))
            else
                btn._label:setString(Str(STR.HIRE))
            end
        end

        --item:setContentSize(lc.w(item._thumbnail), lc.h(item._thumbnail) + lc.h(btn) + 100)
        btn:setPosition(lc.w(item) / 2, lc.h(btn) / 2)
        --item._thumbnail:setPosition(lc.w(item) / 2, lc.h(item) - lc.h(item._thumbnail) / 2)
        ]]

    elseif self._mode == _M.ModeType.recruite then
        local index = (self._curPage - 1) * self._itemRow * self._itemCol + item._thumbnail._index
        local info = self._recruiteInfo[index]
        if info then
            item._countArea:updateDetermined(true, info._remainNum, info._remainNum + info._getNum)
        end

        

    elseif self._mode == _M.ModeType.recruite_langend then
        item._countArea:update(false)

    elseif self._mode == _M.ModeType.recruite_list then
        local index = (self._curPage - 1) * self._itemRow * self._itemCol + item._thumbnail._index
        local info = self._recruiteInfo[index]
        item._countArea:update(true, info._num)

        item._thumbnail:updateFlag()
        

    elseif self._mode == _M.ModeType.union_shop then
        local index = (self._curPage - 1) * self._itemRow * self._itemCol + item._thumbnail._index
        local info = self._unionInfo[index]
        local getNum = P._playerCard:getCardCount(info._infoId)
        local cardInfo = Data.getInfo(info._infoId)
        local maxCount = cardInfo._maxCount or 3
        remainNum = maxCount - getNum
        --todo
        item._thumbnail:updateUnionShopFlag(getNum, remainNum + getNum, info._price, info._priceType, info._disCount)
        local btn = item._btnCustom1
        btn:loadTextureNormal("buy_button", ccui.TextureResType.plistType)
        btn:setVisible(true)
--        btn:setEnabled(true)
        btn:setContentSize(140, 90)
        btn._label:setVisible(false)
--        btn._label:setString(Str(STR.BUY))
--        btn._label:setPosition(lc.cw(btn), lc.ch(btn))
        V.addPriceToBtn(btn, info._price, info._priceType, 100, 30)

        btn._card = info
        if btn._callback==nil and self._onTapBtnCustom1~=nil then
            btn._callback = self._onTapBtnCustom1
        end

        btn:setPosition(0, lc.bottom(item._countArea) - lc.ch(btn) + 20)
        btn:setLocalZOrder(-3)

    elseif self._mode == _M.ModeType.rare_shop then
        local index = (self._curPage - 1) * self._itemRow * self._itemCol + item._thumbnail._index
        local info = self._rareInfo[index]
        local getNum = P._playerCard:getCardCount(info._infoId)
        local cardInfo = Data.getInfo(info._infoId)
        local maxCount = cardInfo._maxCount or 3
        remainNum = maxCount - getNum
        local hasBought = false
        if P._playerMarket._rareGoodsMap[info._id] then hasBought = true end
        item._thumbnail:updateRareShopFlag(getNum, remainNum + getNum, info._price, info._priceType, hasBought)
        local btn = item._btnCustom1
        btn:loadTextureNormal("buy_button", ccui.TextureResType.plistType)
        btn:setVisible(true)
        btn:setContentSize(140, 90)
        btn._label:setVisible(false)
        V.addPriceToBtn(btn, info._price, info._priceType, 100, 30)

        btn._card = info
        if btn._callback==nil and self._onTapBtnCustom1~=nil then
            btn._callback = self._onTapBtnCustom1
        end

        btn:setPosition(0, lc.bottom(item._countArea) - lc.ch(btn) + 20)
        btn:setLocalZOrder(-3)

    elseif self._mode == _M.ModeType.diamond_shop then
        local index = (self._curPage - 1) * self._itemRow * self._itemCol + item._thumbnail._index
        local info = self._diamondInfo[index]
        local getNum = P._playerCard:getCardCount(info._infoId)
        local cardInfo = Data.getInfo(info._infoId)
        local maxCount = cardInfo._maxCount or 3
        remainNum = maxCount - getNum
        item._thumbnail:updateDiamondShopFlag(getNum, remainNum + getNum, info._price, info._priceType)
        local btn = item._btnCustom1
        btn:loadTextureNormal("buy_button", ccui.TextureResType.plistType)
        btn:setVisible(true)
        btn:setContentSize(140, 90)
        btn._label:setVisible(false)
        V.addPriceToBtn(btn, info._price, info._priceType, 100, 30)

        btn._card = info
        if btn._callback==nil and self._onTapBtnCustom1~=nil then
            btn._callback = self._onTapBtnCustom1
        end

        btn:setPosition(0, lc.bottom(item._countArea) - lc.ch(btn) + 20)
        btn:setLocalZOrder(-3)

----------------------------------------- sacrifice -----------------------------------------------------------------   
                            
    else -- sacrifice
        --[[
        item._btnCustom1:setVisible(true)
        item._btnCustom1:setEnabled(true)
        item._btnCustom1._label:setString(Str(STR.UPGRADE))
        item._btnCustom1._label:setPositionX(lc.w(item._btnCustom1) / 2)
        item._btnCustom1._callback = function() if self._onTapBtnCustom1 then self._onTapBtnCustom1(card) end end
        
        if self:isMonster() or self._type == Data.CardType.equip or self._type == Data.CardType.horse then
            local listener = lc.addEventListener(Data.Event.gold_dirty, function(event) 
            end)
            table.insert(item._listeners, listener)

            listener = lc.addEventListener(Data.Event.prop_dirty, function(event) 
            end)
            table.insert(item._listeners, listener)

            listener = lc.addEventListener(Data.Event.fragment_dirty, function(event)
                if event._data._infoId == card._infoId then
                end
            end)
            table.insert(item._listeners, listener)

        end
    
        --item:setContentSize(lc.w(item._thumbnail), lc.h(item._thumbnail) + lc.h(item._btnCustom1) + 20)
        --item._thumbnail:setPosition(lc.w(item) / 2, lc.h(item) - lc.h(item._thumbnail) / 2)
        ]]

        item._countArea:update(true)
    end 
end

function _M:onGuide(event)    
    local curStep, isStop = GuideManager.getCurStepName()
    if curStep == "enter upgrade card" then      
        if self._mode == _M.ModeType.sacrifice then
            -- Find level 1 legend card
            local items = self:getItems()
            for _, item in ipairs(items) do
                local card = item._thumbnail._card
                if card:getQuality() == Data.CardQuality.UR and card._level == 1 then                    
                    GuideManager.setOperateLayer(item._btnCustom1)
                    isStop = true
                    break
                end
            end
        end
        
    elseif curStep == "enter evolve card" then    
        if self._mode == _M.ModeType.sacrifice then
            -- Find evolution 1 legend card
            local items = self:getItems()
            for _, item in ipairs(items) do
                local card = item._thumbnail._card
                if card:getQuality() == Data.CardQuality.UR then                    
                    GuideManager.setOperateLayer(item._btnCustom1)
                    isStop = true
                    break
                end
            end
        end
        
    elseif curStep == "pick card" then
        if self._mode == _M.ModeType.check or self._mode == _M.ModeType.radio then
            local items = self:getItems()
            for _, item in ipairs(items) do
                GuideManager.setOperateLayer(self._mode == _M.ModeType.check and item._btnCheck or item._btnRadio)
                break
            end

            isStop = true
        end
    else
        return
    end    
    if isStop then event:stopPropagation() end
end

function _M:getSelectedCards()
    return self._selectedCards
end

function _M:getUnselectedCards()
    local cards = {}
    for i = 1, #self._cards do    
        if self._cards[i]._selected == 0 then
            table.insert(cards, self._cards[i])
        end
    end
    
    return cards
end

function _M:getSelectedCardNumber()
    local number = 0
    for i = 1, #self._cards do
        if self._cards[i]._selected > 0 then
            number = number + self._cards[i]._selected
        end
    end
    
    return number
end

function _M:getUnselectedCardNumber()
    local number = 0
    for i = 1, #self._cards do
        if self._cards[i]._selected == 0 then
            number = number + 1
        end
    end

    return number
end

function _M:selectAllCards()
    for i = 1, #self._cards do
        self._cards[i]:setSelected(1)
    end
end

function _M:unselectAllCards()
    for i = 1, #self._cards do
        self._cards[i]:setSelected(0)
    end
end

function _M:getCardCountInTroop(troop, infoId)
    local originId = Data.getOriginId(infoId)
    local count, specificCount = 0, 0
    for i = 1, #troop do
        if Data.getOriginId(troop[i]._infoId) == originId then
            count = count + troop[i]._num
        end
        if troop[i]._infoId == infoId then
            specificCount = specificCount + troop[i]._num
        end
    end
    return count, specificCount
end

function _M:getCardCountInUnionTroops(infoId)
    local originId = Data.getOriginId(infoId)
    local count, specificCount = 0, 0
    for index = Data.TroopIndex.union_battle1, Data.TroopIndex.union_battle1 + Data.GROUP_NUM - 1 do
        if index ~= self._troopIndex then
            local troop = ClientData._cloneTroops[index]
            if not troop then
                troop = P._playerCard:getTroop(index, false)
            end
            for i = 1, #troop do
                if Data.getOriginId(troop[i]._infoId) == originId then
                    count = count + troop[i]._num
                end
                if troop[i]._infoId == infoId then
                    specificCount = specificCount + troop[i]._num
                end
            end
        end
    end
    return count, specificCount
end

function _M:getCardCountInDarkTroops(infoId)
    local originId = Data.getOriginId(infoId)
    local count, specificCount = 0, 0
    for index = Data.TroopIndex.dark_battle1, Data.TroopIndex.dark_battle3 do
        if index ~= self._troopIndex then
            local troop = ClientData._cloneTroops[index]
            if not troop then
                troop = P._playerCard:getTroop(index, false)
            end
            for i = 1, #troop do
                if Data.getOriginId(troop[i]._infoId) == originId then
                    count = count + troop[i]._num
                end
                if troop[i]._infoId == infoId then
                    specificCount = specificCount + troop[i]._num
                end
            end
        end
    end
    return count, specificCount
end

return _M