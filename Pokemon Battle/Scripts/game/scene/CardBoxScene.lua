local CardList = require("CardList")
local FilterWidget = require("FilterWidget")
local BaseUIScene = require("BaseUIScene")
local CardOperatePanel = require("CardOperatePanel")

local _M = class("CardBoxScene", BaseUIScene)

----------------
-- syncData: 
--      showTab                     updateView
--      updateCardList
--      cardList:refresh(true)
----------------

local THUMBNAIL_SCALE = 0.6
local TAB_BASE_ZORDER = 1
local TRANSFER_EFFECT_DURATION   = 1.0

function _M.create(sceneId, tabIndex)
    return lc.createScene(_M, sceneId, tabIndex)
end

function _M:init(sceneId, tabIndex)
    if not _M.super.init(self, sceneId, STR.SID_FIXITY_NAME_1005, BaseUIScene.STYLE_TAB, true) then return false end
    
    self:createFrame()
    self:createCardList()
    V.addVerticalTabButtons(self, {Str(STR.MONSTER), Str(STR.MAGIC), Str(STR.TRAP), Str(STR.RARE)..Str(STR.MONSTER)}, lc.top(self._frame) - 80, lc.left(self._frame) - 124, 480)
    
    self._tabArea._focusTabIndex = tabIndex or Data.CardType.monster

    self:syncData()
    
    return true
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}

    listener = lc.addEventListener(Data.Event.card_list_dirty, function(event)
        self:updateView()
    end)
    table.insert(self._listeners, listener)

    self:updateView()

    if ClientData._hasNewLotteryBook then
        self:updateCardList()
        ClientData._hasNewLotteryBook = false
    end
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i]) 
    end    
    self._listeners = {} 
end

function _M:syncData()
    _M.super.syncData(self)

    self:showTab(self._tabArea._focusTabIndex)
    self:updateView()

    if ClientData._hasNewLotteryBook then
        self:updateCardList()
        ClientData._hasNewLotteryBook = false
    end
end

function _M:createFrame()
    local frame = V.createFrameBox(cc.size(lc.w(self) - (16 + V.FRAME_TAB_WIDTH) * 2, lc.bottom(self._titleArea)))
    lc.addChildToPos(self, frame, cc.p(lc.w(self) / 2, lc.bottom(self._titleArea) / 2))
    self._frame = frame
end

function _M:createCardList()
    local bottomH = 80

    self._cardList = require("CardList").create(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM - bottomH), 0.6, false)
    self._cardList:setAnchorPoint(0.5, 0.5)
    self._cardList:registerCardSelectedHandler(function(data, index) self:onCardSelected(data, index) end)
    lc.addChildToPos(self._frame, self._cardList, cc.p(lc.w(self._frame) / 2, bottomH / 2 + lc.h(self._frame) / 2))
    
    local offsetx = (lc.w(self._frame) - lc.w(self._cardList)) / 2 + 16
    self._cardList._pageLeft._pos = cc.p(-offsetx, 8)
    self._cardList._pageRight._pos = cc.p(lc.w(self._cardList) + offsetx, 8)

    offsetx = offsetx + 32
    local pageBg = lc.createSprite({_name = "img_page_bg", _size = cc.size(125, 33), _crect = cc.rect(11, 11, 4, 8)}) 
    lc.addChildToPos(self._frame, pageBg, cc.p(-lc.w(pageBg) / 2 + 12, 40), -1)
    self._pageBg = pageBg
    self._cardList._pageLabel:setPosition(-offsetx, -68)

    local bottomArea = V.createLineSprite("img_bottom_bg", lc.w(self._cardList))
    bottomArea:setAnchorPoint(0.5, 0)
    lc.addChildToPos(self._frame, bottomArea, cc.p(lc.w(self._frame) / 2, V.FRAME_INNER_BOTTOM - 12), -1)
    self._bottomArea = bottomArea

    local info = V.createBMFont(V.BMFont.huali_26, '')
    info:setAnchorPoint(0, 0.5)
    lc.addChildToPos(bottomArea, info, cc.p(20, lc.h(bottomArea) / 2))
    self._info = info

    --[[
    local line = lc.createSprite("img_divide_line_7")
    line:setScaleX(lc.w(bottomArea) / lc.w(line))
    lc.addChildToPos(bottomArea, line, cc.p(lc.w(bottomArea)  / 2, lc.h(bottomArea) - lc.h(line) / 2))
    ]]
end

function _M:showTab(tabIndex)
    if tabIndex == _M.TAB_TRANFER then
        if P._level < Data._globalInfo._unlockSplit then
            ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockSplit))
            return
        end
    end

    self._tabArea:showTab(tabIndex)

    self:updateTabFlag()
    self:updateTabContent()
    
    if tabIndex == _M.TAB_MIX then
        if GuideManager.getCurStepName() == "show tab mixbook" then
            GuideManager.finishStep()
        end
    end
    
    return true
end

function _M:updateTabContent()
    local focusIndex = self._tabArea._focusTabIndex

    if self._filterWidget then
        self._filterWidget:removeFromParent()
        self._filterWidget = nil
    end
       
    local filterWidget = nil
    local cardStr = ''
    if focusIndex == Data.CardType.monster then
        filterWidget = FilterWidget.create(FilterWidget.ModeType.monster, lc.h(self._frame) - 80)
        filterWidget:resetAllFilter()
        cardStr = Str(STR.MONSTER)
    elseif focusIndex == Data.CardType.magic then 
        filterWidget = FilterWidget.create(FilterWidget.ModeType.magic, lc.h(self._frame) - 80)
        filterWidget:resetAllFilter()
        cardStr = Str(STR.MAGIC)
    elseif focusIndex == Data.CardType.trap then 
        filterWidget = FilterWidget.create(FilterWidget.ModeType.trap, lc.h(self._frame) - 80)
        filterWidget:resetAllFilter()
        cardStr = Str(STR.TRAP)
    end
    
    if filterWidget then
        self._filterWidget = filterWidget
        self._filterWidget:resetAllFilter()
        filterWidget:registerSortFilterHandler(function() self:updateCardList() end)
    
        lc.addChildToPos(self._frame, filterWidget, cc.p(lc.w(self._frame) + V.FRAME_TAB_WIDTH - lc.w(filterWidget) / 2 + 2, lc.h(filterWidget) / 2))
    end

    self:updateCardList()

    self._info:setString(cardStr..': '..#self._cardList._cards)
end

function _M:updateCardList()
    local sort
    local filters = {}
    if self._filterWidget then
        local sortFunc, isAscending = self._filterWidget:getSortFunc()  
        if sortFunc then sort = {_func = sortFunc, _isReverse = not isAscending} end
               
        local filterCountryFunc, FilterNatureKeyword = self._filterWidget:getFilterNatureFunc()
        if filterCountryFunc then filters[CardList.FilterType.country] = {_func = filterCountryFunc, _keyVal = FilterNatureKeyword} end       

        local filterCategoryFunc, filterCategoryKeyword = self._filterWidget:getFilterCategoryFunc()
        if filterCategoryFunc then filters[CardList.FilterType.category] = {_func = filterCategoryFunc, _keyVal = filterCategoryKeyword} end

        local filterCostFunc, filterCostKeyword = self._filterWidget:getFilterLevelFunc()
        if filterCostFunc then filters[CardList.FilterType.cost] = {_func = filterCostFunc, _keyVal = filterCostKeyword} end
        
        local filterQualityFunc, filterQualityKeyword = self._filterWidget:getFilterQualityFunc()
        if filterQualityFunc then filters[CardList.FilterType.quality] = {_func = filterQualityFunc, _keyVal = filterQualityKeyword} end
        
        local filterSearchFunc, keyword = self._filterWidget:getFilterSearchFunc()
        if filterSearchFunc then filters[CardList.FilterType.search] = {_func = filterSearchFunc, _keyVal = keyword} end
    end        

    self._cardList:init(self._tabArea._focusTabIndex, excepts, sort, filters) 
    self._cardList:refresh(true)
end

function _M:updateTabFlag()
    --local number = 0
    --V.checkNewFlag(self._tabArea._tabs[1], number, -20)
end

function _M:onCardSelected(infoId, index)
    CardOperatePanel.create(infoId, CardOperatePanel.OperateMode.decompose):show()
end

function _M:onCardMix(card, count, isForce)
    count = count or 1
    if ClientData.isMixable(card._infoId) then
        local isComFragFirst = (self._frameBottomArea._checkArea and self._frameBottomArea._checkArea._isCheck or false)
        if not isForce then
            require("PromptForm").ConfirmMix.create(card, isComFragFirst, function(count)
                self:onCardMix(card, count, true)
            --end):show()
            end, card._type == Data.CardType.common_fragment):show()
            return
        end

        local thumbnail = self._cardList:getThumbnail(card)
        local particle = Particle.create("par_card_mix")
        if thumbnail then
            particle:setPosition(self:convertToNodeSpace(thumbnail:convertToWorldSpace(cc.p(lc.w(thumbnail) / 2, lc.h(thumbnail) / 2))))
        else
            particle:setVisible(false)
        end
        self:addChild(particle, ClientData.ZOrder.effect)
    
        V.getActiveIndicator():show()
        self:runAction(cc.Sequence:create(cc.DelayTime:create(particle:getDuration()), cc.CallFunc:create(function() 
            V.getActiveIndicator():hide()    
        
            local result, newCard = P._playerCard:composeCard(card._infoId, isComFragFirst)
            
            if result == Data.ErrorType.ok and newCard then
                ClientData.sendCardCompose(newCard._infoId, count)
                
                particle:stopSystem()             
                particle:removeFromParent()
            
                self:updateTabFlag()
                 
                if card._type == Data.CardType.common_fragment then
                    local RewardPanel = require("RewardPanel")
                    RewardPanel.create({{_infoId = card._infoId, _count = count}}, RewardPanel.MODE_MIX_FRAGMENT):show()
                else
                    if card:isMonster() then
                        local eventCustom = cc.EventCustom:new(Data.Event.mix_hero)                    
                        lc.Dispatcher:dispatchEvent(eventCustom)
                    end

                    require("RewardCardPanel").create(Str(STR.COMPOSE)..Str(STR.SUCCESS), {newCard}):show()
                end
            end
        end)))  
        
        lc.Audio.playAudio(AUDIO.E_CARD_MIX)
    else
        ToastManager.push(Str(STR.NEED_FRAGMENTS_MIX))
    end
end

function _M:updateView()
end

function _M:checkUnlockModule()  
    local strs = {}

    local curLevel = P._level
    local prevLevel = lc.readConfig(ClientData.ConfigKey.lock_level_split, curLevel)        
    if prevLevel < Data._globalInfo._unlockSplit and curLevel >= Data._globalInfo._unlockSplit then
        table.insert(strs, #strs, Str(STR.DECOMPOSE)..Str(STR.UNLOCKED))
        lc.writeConfig(ClientData.ConfigKey.lock_level_split, curLevel)
    end

    if self._sceneId == ClientData.SceneId.factory_monster then
        prevLevel = lc.readConfig(ClientData.ConfigKey.lock_level_equip, curLevel)

        local level = P._playerCity:getBlacksmithUnlockLevel()
        if prevLevel < level and curLevel >= level then
            table.insert(strs, #strs + 1, Str(STR.EQUIP)..Str(STR.UNLOCKED))
            lc.writeConfig(ClientData.ConfigKey.lock_level_equip, curLevel)
        end                  
    end

    if #strs > 0 then
        ToastManager.pushArray(strs)
    end
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "leave heromansion"
        or curStep == "leave blacksmith"
        or curStep == "leave stable"
        or curStep == "leave library" then
        GuideManager.setOperateLayer(self._btnBack)

    elseif curStep == "show card info" then
        GuideManager.setOperateLayer(self._cardList:getItem(0)._thumbnail)

    elseif curStep == "enter lottery book" then
        GuideManager.setOperateLayer(self._btnLottery)
    elseif curStep == "show tab mixbook" then
        GuideManager.setOperateLayer(self._tabArea._tabs[_M.TAB_MIX])
    else
        return
    end
    
    event:stopPropagation()
end



return _M