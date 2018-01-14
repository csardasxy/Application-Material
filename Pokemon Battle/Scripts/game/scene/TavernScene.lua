local BaseUIScene = require("BaseUIScene")

local _M = class("TavernScene", BaseUIScene)

local CardInfoPanel = require("CardInfoPanel")

local LOTTERY_EFFECT_DURATION   = 1.0

local BUTTON_WIDTH = 220
local RES_WIDTH = 110

local PROP_ID = {Data.PropsId.miracle_indicator, Data.PropsId.dust_rare, Data.PropsId.dust_magic, Data.PropsId.dust_monster}

_M.TAB = {
    time_limit      = 1,
    draw_card      = 2,
    rare_draw_card      = 3,
    --[[
    depot_shop    = 4,
    rare_shop        = 6,
    diamond_shop = 7,
    god_shop        = 8,
    times_limit      = 9,
    god_pump     = 10,
    ]]
}


function _M.create(focusInfoId, tabIndex)
    return lc.createScene(_M, focusInfoId, tabIndex)
end

function _M:init(focusInfoId, tabIndex)
    if not _M.super.init(self, ClientData.SceneId.tavern, STR.SID_FIXITY_NAME_1007, BaseUIScene.STYLE_SIMPLE, true) then return false end 
    
    self:generateCardPackageData()

    self._focusInfoId = focusInfoId
    local tab = tabIndex or _M.TAB.draw_card

    local tabDefs = {}

--    if #self._timesLimitPackages > 0 then
--        table.insert(tabDefs, {_index = _M.TAB.times_limit, _str = Str(STR.TIMES_SHOP)})
--        tab = _M.TAB.times_limit
--    end

    if #self._timeLimitPackages > 0 then
        table.insert(tabDefs, {_index = _M.TAB.time_limit, _str = Str(STR.TIME_LIMIT_PACKAGE)})
        tab = _M.TAB.time_limit
    end

    table.insert(tabDefs, {_index = _M.TAB.draw_card, _str = Str(STR.COMMON_PACKAGE)})
    table.insert(tabDefs, {_index = _M.TAB.rare_draw_card, _str = Str(STR.RARE_PACKAGE)})

    if #self._godPumpPackages > 0 and P._vip >= 1 then
        table.insert(tabDefs, {_index = _M.TAB.god_pump, _str = Str(STR.GOD_PUMP)})
    end

    --table.insert(tabDefs, {_index = _M.TAB.rare_shop, _str = Str(STR.GOD_SHOP)})
    --table.insert(tabDefs, {_index = _M.TAB.diamond_shop, _str = Str(STR.DIAMOND_SHOP)})

    --table.insert(tabDefs, {_index = _M.TAB.depot_shop, _str = Str(STR.DEPOT_SHOP)})

    local bg = lc.createSprite({_name = "img_troop_bg_1", _size = cc.size(lc.w(self), lc.h(self) - V.HORIZONTAL_TAB_HEIGHT - 70), _crect = cc.rect(25, 24, 2, 8)})
    lc.addChildToPos(self, bg, cc.p(lc.cw(self), lc.ch(bg)))
    self._bg = bg

    local bg2 = lc.createSprite({_name = "img_troop_bg_2", _size = cc.size(lc.w(self._bg) - 50, lc.h(self._bg) - 58), _crect = cc.rect(16, 14, 9, 6)})
    lc.addChildToCenter(self._bg, bg2)
    self._bg2 = bg2
    bg2:setVisible(false)

    local tabArea = V.createHorizontalTabListArea(lc.w(bg), tabDefs, function(tab, isSameTab, isUserBehavior)

            if not isSameTab or isUserBehavior then
                self:showTab(tab)
            end
        end)
    lc.addChildToPos(bg, tabArea, cc.p(lc.cw(bg), lc.top(bg) + lc.ch(tabArea) - 11), 1)
    self._tabArea = tabArea

    self._titleArea._btnBack._callback = function ()
    --[[
        if self._detailPanel then
            self:hideCardBox()
        elseif self._rareShopArea._detailPanel then
            self._rareShopArea:hideCardBox()
        elseif self._diamondShopArea._detailPanel then
            self._diamondShopArea:hideCardBox()
        else
            self:hide()
        end]]
        self:hide()
    end

    local list = lc.List.createH(cc.size(lc.w(bg) - 10, lc.h(bg) - 10), 50, 60)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(bg, list)

    self._recruitItems = {}
    
    list:setVisible(false)
    self._list = list

    -- server Data
    self._packageCards = {}

    --[[
    self._depotShopArea = require("DepotShopArea").create(lc.w(self._list) - 100, lc.h(self._list))
    lc.addChildToPos(self, self._depotShopArea, cc.p(lc.x(self._list), lc.y(self._list) - 20))
    ]]

    self._rareShopArea = require("RareShopArea").create(lc.w(self._list) - 100, lc.h(self._list) + 100)
    lc.addChildToPos(self, self._rareShopArea, cc.p(lc.x(self._list) - 2, lc.y(self._list) - 10))

    self._diamondShopArea = require("DiamondShopArea").create(lc.w(self._list) - 100, lc.h(self._list) + 100)
    lc.addChildToPos(self, self._diamondShopArea, cc.p(lc.x(self._list) - 2, lc.y(self._list) - 10))

--    if #self._timesLimitPackages > 0 then
--        self._timesShopArea = require("TimesShopArea").create(self, self._timesLimitPackages[1], lc.w(self._list) - 100, lc.h(self._list))
--        lc.addChildToPos(self, self._timesShopArea, cc.p(lc.x(self._list), lc.y(self._list) - 20))
--    end

    local info = {_value = focusInfoId}
    if focusInfoId then 
        if Data.getIsTimeLimitRecruite(info) then
            tab = _M.TAB.time_limit
        elseif Data.getIsTimesLimitRecruite(info) then
            tab = _M.TAB.times_limit
        elseif Data.getIsRareRecruite(info) then
            tab = _M.TAB.rare_draw_card
        elseif Data.getIsCharacterRecruite(info) then
            tab = _M.TAB.draw_card
        end
    end
    
    self._tabArea:showTab(tab)

    return true
end

function _M:generateCardPackageData()
    local infos = {}
    for k, v in pairs(Data._recruitInfo) do
        infos[#infos + 1] = v
    end

    table.sort(infos, function(a, b)
        local activityA = a._value > 200000
        local activityB = b._value > 200000
        local legendA = a._value > 100000
        local legendB = b._value > 100000
        local lockedA = self:isLocked(a)
        local lockedB = self:isLocked(b)

        if activityA and not activityB then return true
        elseif not activityA and activityB then return false
        elseif not lockedA and lockedB then return true
        elseif lockedA and not lockedB then return false
        elseif legendA and not legendB then return true
        elseif not legendA and legendB then return false
        else return a._value < b._value
        end
    end)

    local timesLimitPackages = {}
    local timeLimitPackages = {}
    local godPumpPackages = {}
    local drawCardPackages = {}
    local rareDrawCardPackages = {}
    self._timeLimitPackages = timeLimitPackages
    self._timesLimitPackages = timesLimitPackages
    self._godPumpPackages = godPumpPackages
    self._drawCardPackages = drawCardPackages
    self._rareDrawCardPackages = rareDrawCardPackages

    local generatePackageData = function(once, ten, fifty)
        return {_once = once, _ten = ten, _fifty = fifty}
    end

    if self:isGuideRarePackage() then
        table.insert(rareDrawCardPackages, generatePackageData(Data._dropInfo[P._guideID <118 and 1 or 2], infos[2], infos[3]))
--        local item = self:createRecruitItem(Data._dropInfo[P._guideID <118 and 1 or 2], infos[2], infos[3])
--        list:pushBackCustomItem(item)
--        self._recruitItems[#self._recruitItems + 1] = item
    end

    local i = 1
    while i <= #infos do
        local isShow = true
        if Data.getIsTimeLimitRecruite(infos[i]) or Data.getIsTimesLimitRecruite(infos[i]) then 
            isShow = not self:isGuideRarePackage() and not ClientData.isHideActivityPackage() and ClientData.isActivityValidByParam(infos[i]._value - 200000)
            if not self:isGuideRarePackage() and Data.getIsTimeLimitRoleRecruite(infos[i]) and P:isNewBie(infos[i]) then
                isShow = true
            end
        elseif Data.getIsRareRecruite(infos[i]) then 
            isShow = not self:isGuideRarePackage() and (P:getCharacterUnlockCount() >= 2 or V.isPackageShowInRareShop(infos[i]._value))  
        end

        if isShow then  
--            local item = self:createRecruitItem(infos[i], infos[i + 1], infos[i + 2])
--            list:pushBackCustomItem(item)
--            self._recruitItems[#self._recruitItems + 1] = item
            if Data.getIsTimeLimitRecruite(infos[i]) then
                table.insert(timeLimitPackages, generatePackageData(infos[i], infos[i + 1], infos[i + 2]))
            elseif Data.getIsRareRecruite(infos[i]) then
                table.insert(rareDrawCardPackages, generatePackageData(infos[i], infos[i + 1], infos[i + 2]))
            elseif Data.getIsCharacterRecruite(infos[i]) then
                table.insert(drawCardPackages, generatePackageData(infos[i], infos[i + 1], infos[i + 2]))
            elseif Data.getIsTimesLimitRecruite(infos[i]) then
                table.insert(timesLimitPackages, infos[i])
            elseif Data.getIsGodPumpRecruite(infos[i]) then
                table.insert(godPumpPackages, generatePackageData(infos[i], infos[i + 1]))
            end
        end

        if Data.getIsTimesLimitRecruite(infos[i]) then
            i = i + 1
        elseif Data.getIsGodPumpRecruite(infos[i]) then
            i = i + 2
        else
            i = i + 3
        end
    end
end

function _M:showTab(tab)
    if self._detailPanel then
        self:hideCardBox()
    end

    if self._rareShopArea._detailPanel then
        self._rareShopArea:hideCardBox()
    end

    if self._diamondShopArea._detailPanel then
        self._diamondShopArea:hideCardBox()
    end

    for i = 1, #self._recruitItems do
        lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/lottery_"..self._recruitItems[i]._infoOnce._value..".jpg"))  
    end

    self._recruitItems = {}

    

    self._list:setVisible(false)
    --self._depotShopArea:setVisible(false)
    self._rareShopArea:setVisible(false)
    self._diamondShopArea:setVisible(false)
    if self._timesShopArea then
        self._timesShopArea:setVisible(false)
    end

    if tab._index == _M.TAB.draw_card then

        local list = self._list
        local listData = self._drawCardPackages
        list:setVisible(true)
        list:bindData(listData, function(item, data) self:createRecruitItem(item, data._once, data._ten, data._fifth) end, math.min(8, #listData), 1)
        for i = 1, list._cacheCount do
            local data = listData[i]
            local item = self:createRecruitItem(nil, data._once, data._ten, data._fifty)
            list:pushBackCustomItem(item)
            table.insert(self._recruitItems, item)
        end

    elseif tab._index == _M.TAB.rare_draw_card then
        
        local list = self._list
        local listData = self._rareDrawCardPackages
        list:setVisible(true)
        list:bindData(listData, function(item, data) self:createRecruitItem(item, data._once, data._ten, data._fifth) end, math.min(8, #listData), 1)
        for i = 1, list._cacheCount do
            local data = listData[i]
            local item = self:createRecruitItem(nil, data._once, data._ten, data._fifty)
            list:pushBackCustomItem(item)
            table.insert(self._recruitItems, item)
        end

    elseif tab._index == _M.TAB.time_limit then
        
        local list = self._list
        local listData = self._timeLimitPackages
        list:setVisible(true)
        list:bindData(listData, function(item, data) self:createRecruitItem(item, data._once, data._ten, data._fifth) end, math.min(8, #listData), 1)
        for i = 1, list._cacheCount do
            local data = listData[i]
            local item = self:createRecruitItem(nil, data._once, data._ten, data._fifty)
            list:pushBackCustomItem(item)
            table.insert(self._recruitItems, item)
        end

    elseif tab._index == _M.TAB.god_pump then
        
        local list = self._list
        local listData = self._godPumpPackages
        list:setVisible(true)
        list:bindData(listData, function(item, data) self:createRecruitItem(item, data._once, data._ten, data._fifth) end, math.min(6, #listData), 1)
        for i = 1, list._cacheCount do
            local data = listData[i]
            local item = self:createRecruitItem(nil, data._once, data._ten, nil)
            list:pushBackCustomItem(item)
            table.insert(self._recruitItems, item)
        end

    elseif tab._index == _M.TAB.times_limit then
        self._timesShopArea:setVisible(true)

    elseif tab._index == _M.TAB.depot_shop then
        --self._depotShopArea:setVisible(true)
        --self._depotShopArea._cardList:refresh()

    elseif tab._index == _M.TAB.rare_shop then
        self._rareShopArea:setVisible(true)

    elseif tab._index == _M.TAB.diamond_shop then
        self._diamondShopArea:setVisible(true)
    end

    self:setResourcePanel()
end

function _M:setResourcePanel()
    local resPanel = V.getResourceUI()
    resPanel:setMode(Data.ResType.gold)
    local tab = self._tabArea._focusedTab
    if tab._index == _M.TAB.god_pump then
        resPanel:setMode(Data.PropsId.common_fragment)
    elseif tab._index == _M.TAB.times_limit then
        resPanel:setMode(Data.PropsId.times_package_ticket)
    elseif tab._index == _M.TAB.diamond_shop then
        resPanel:setMode(Data.PropsId.times_package_ticket)
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    self:setResourcePanel()

    if self._tabArea._focusedTab._index == self.TAB.times_limit then
        V.getResourceUI():setMode(Data.PropsId.times_package_ticket)
    end
    
    self._tokenListener = lc.addEventListener(Data.Event.prop_dirty, function(event)
        if event._data == P._propBag._props[Data.PropsId.dust_monster] 
            or event._data == P._propBag._props[Data.PropsId.dust_magic] 
            or event._data == P._propBag._props[Data.PropsId.dust_rare]
            or event._data == P._propBag._props[Data.PropsId.common_fragment]
            or event._data == P._propBag._props[Data.PropsId.miracle_indicator] then
            self:updateCardBox()
        end
    end)

    self._ingotListener = lc.addEventListener(Data.Event.ingot_dirty, function(event)
        self:updateCardBox()
    end)

    self._goldListener = lc.addEventListener(Data.Event.gold_dirty, function(event)
        self:updateCardBox()
    end)

    self._fragmentListener = lc.addEventListener(Data.Event.fragment_dirty, function(event)
        self:updateCardBox()
    end)
    
    self:syncData()
end

function _M:onExit()
    _M.super.onExit(self)

    lc.Dispatcher:removeEventListener(self._tokenListener)
    lc.Dispatcher:removeEventListener(self._ingotListener)
    lc.Dispatcher:removeEventListener(self._goldListener)
    lc.Dispatcher:removeEventListener(self._fragmentListener)

    self:unscheduleUpdate()
end

function _M:onCleanup()
    _M.super.onCleanup(self)
        
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/tavern_item_bg.jpg"))  
    for i = 1, #self._recruitItems do
        lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/lottery_"..self._recruitItems[i]._infoOnce._value..".jpg"))  
    end
end

function _M:syncData()
    _M.super.syncData(self)

    self:updateCardBox()
end

function _M:createRecruitItem(layout, infoOnce, infoTen, infoFifty)
    if layout then
        lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/lottery_"..layout._infoOnce._value..".jpg"))
        layout:removeFromParent()
    end
    layout = ccui.Layout:create()
    layout:setContentSize(cc.size(250, 690))
    layout:setAnchorPoint(0.5, 0.5)

    local titleBg = V.createCardPackage(infoOnce)

    local btn = V.createShaderButton(nil, function(sender) self:sendShowDetail(infoOnce, infoTen, infoFifty) end)
    btn:setContentSize(titleBg:getContentSize())
    btn:setZoomScale(0.02)
    lc.addChildToCenter(btn, titleBg, -1)

    lc.addChildToCenter(layout, btn)
    layout._btn = btn
    layout._infoOnce = infoOnce
    layout._infoTen = infoTen

    --check locked
    local isLocked, str = self:isLocked(infoOnce)
    if isLocked then
        --btn:setTouchEnabled(false)
        titleBg:setGray()

        local bg = lc.createSprite("img_com_bg_45")
        lc.addChildToPos(titleBg, bg, cc.p(lc.cw(titleBg), lc.ch(titleBg) + 30))

        local label = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S2)
        lc.addChildToCenter(bg, label)
    end

    -- time
    if Data.getIsTimeLimitRecruite(infoOnce) then
        if Data.getIsTimeLimitRoleRecruite(infoOnce) and P:isNewBie(infoOnce) then
            local time = V.createBMFont(V.BMFont.huali_26, string.format(Str(STR.NEWBIE_PACKAGE_TIP), infoOnce._param[3]))
            lc.addChildToPos(titleBg, time, cc.p(lc.cw(titleBg), 158))
        else
            local activityInfo = ClientData.getActivityByParam(infoOnce._value - 200000)
            if activityInfo then
                local time = V.createBMFont(V.BMFont.huali_26, ClientData.getActivityDurationStr(activityInfo))
                lc.addChildToPos(titleBg, time, cc.p(lc.cw(titleBg), 158))
            end
        end
    end
    
    return layout
end

function _M:createCostArea(recruitInfo, buyCount, baseInfo)
    local iconName, resNeed = nil, recruitInfo._param[2]
    if Data.getIsRareRecruite(recruitInfo) and P._propBag:hasProps(Data.PropsId.rare_package_ticket, buyCount) then
        iconName = ClientData.getPropIconName(Data.PropsId.rare_package_ticket)
        resNeed = buyCount
    elseif Data.getIsCharacterRecruite(recruitInfo) and P._propBag:hasProps(Data.PropsId.character_package_ticket, buyCount) then
        iconName = ClientData.getPropIconName(Data.PropsId.character_package_ticket)
        resNeed = buyCount
    elseif recruitInfo._param[1] == Data.ResType.ingot or recruitInfo._param[1] == Data.ResType.gold then
        iconName = string.format("img_icon_res%d_s", recruitInfo._param[1])
    else
        iconName = ClientData.getPropIconName(recruitInfo._param[1])
    end

    local str = buyCount == 1 and 'img_btn_1_s' or (buyCount == 10 and 'img_btn_1_s' or 'img_btn_1_s')
    local btn = V.createResConsumeButton(BUTTON_WIDTH, RES_WIDTH, iconName, '999999', string.format(Str(STR.RECRUIT_MULTIPLE), buyCount), str)
    btn._resNeed = resNeed
    lc.offset(btn._resArea, 15, 0)

    btn.update = function(btn)
        local iconName, resNeed = nil, recruitInfo._param[2]
        if Data.getIsRareRecruite(recruitInfo) and P._propBag:hasProps(Data.PropsId.rare_package_ticket, buyCount) then
            iconName = ClientData.getPropIconName(Data.PropsId.rare_package_ticket)
            resNeed = buyCount
        elseif Data.getIsCharacterRecruite(recruitInfo) and P._propBag:hasProps(Data.PropsId.character_package_ticket, buyCount) then
            iconName = ClientData.getPropIconName(Data.PropsId.character_package_ticket)
            resNeed = buyCount
        elseif recruitInfo._param[1] == Data.ResType.ingot or recruitInfo._param[1] == Data.ResType.gold then
            iconName = string.format("img_icon_res%d_s", recruitInfo._param[1])
        else
            iconName = ClientData.getPropIconName(recruitInfo._param[1])
        end
        btn._resNeed = resNeed

        local label = btn._resLabel
        label:setString(string.format("%d", btn._resNeed))
        btn._resArea._ico:setSpriteFrame(iconName)
        if Data.getIsRareRecruite(recruitInfo) and P._propBag:hasProps(Data.PropsId.rare_package_ticket, buyCount) then
            label:setColor(lc.Color3B.white)
        elseif Data.getIsCharacterRecruite(recruitInfo) and P._propBag:hasProps(Data.PropsId.character_package_ticket, buyCount) then
            label:setColor(lc.Color3B.white)
        elseif recruitInfo._param[1] == Data.ResType.ingot then
            label:setColor(P._ingot < btn._resNeed and lc.Color3B.red or lc.Color3B.white)
        elseif recruitInfo._param[1] == Data.ResType.gold then
            label:setColor(P._gold < btn._resNeed and lc.Color3B.red or lc.Color3B.white)
        else
            label:setColor(P._propBag._props[recruitInfo._param[1]]._num < btn._resNeed and lc.Color3B.red or lc.Color3B.white)
        end
    end

    if recruitInfo._value ~= baseInfo._value then
        local discountValue = recruitInfo._param[2] / baseInfo._param[2]

        local discount = cc.Sprite:createWithSpriteFrameName("img_hl_bg")        
        discount:setRotation(-10)
        discount:setScale(0.8)
        lc.addChildToPos(btn, discount, cc.p(lc.w(btn) - 10, lc.h(btn) - 6))

        local discountStr
        if discountValue > math.floor(discountValue) then
            discountStr = string.format("%.1f%s", discountValue, Str(STR.DISCOUNT))
        else        
            discountStr = string.format("%d%s", discountValue, Str(STR.DISCOUNT))
        end

        local discountLabel = V.createBMFont(V.BMFont.huali_20, discountStr)
        discountLabel:setColor(V.COLOR_TEXT_RED)
        lc.addChildToPos(discount, discountLabel, cc.p(lc.w(discount) / 2, lc.h(discount) / 2 + 4))
        if discountValue >= 10 then discount:setVisible(false) end
    end

    --reset
    btn:update()
    return btn
end

function _M:onMsg(msg)
    if _M.super.onMsg(self, msg) then return true end
    
    local msgType = msg.type
    local msgStatus = msg.status
    
    if msgType == SglMsgType_pb.PB_TYPE_CARD_LOTTERY then
        if not self._detailInfoOnce then return false end
        V.getActiveIndicator():hide()
        local objs = msg.Extensions[Card_pb.SglCardMsg.card_lottery_resp]
        if Data.getIsGodPumpRecruite(self._detailInfoOnce) then
            local rewards = {}
            for i, obj in ipairs(objs) do
                table.insert(rewards, {_infoId = obj.info_id, _count = obj.num, _isFragment = false, _level = 1})
            end
            require("RewardPanel").create(objs):show(require("RewardPanel").MODE_LOTTERY)
            return true
        end
        local newProps = {}
        local newCards = {}
        local objTypes = {}
        for i = 1, #objs do
            local obj = objs[i]
            local objType = Data.getType(obj.info_id)
            if obj.info_id ~= Data.PropsId.void_diamond then
                if P._playerCard:addCard(obj.info_id, obj.num) then
                    objTypes[objType] = true
                end
                newCards[#newCards + 1] = {_infoId = obj.info_id, _num = obj.num}
                self:removeCardFromPackage(obj.info_id, obj.num)
            else
                newProps[#newProps + 1] = {_infoId = obj.info_id, _num = obj.num}
            end
        end
        
        for type in pairs(objTypes) do
            P._playerCard:sendCardListDirty(type)
        end
        
        local eventCustom = cc.EventCustom:new(Data.Event.hero_lottery)
        eventCustom._times = (type == RECRUIT_LEGEND and 1 or #newCards)
        lc.Dispatcher:dispatchEvent(eventCustom)

        self:updateCardBox()

        local propId = Data.PropsId.void_diamond
        if #newProps > 0 and newProps[1]._infoId == propId then
            P._propBag:changeProps(propId, newProps[1]._num)
            ToastManager.push(string.format(Str(STR.GOT_VOID_DIAMOND), newProps[1]._num, Str(Data._propsInfo[propId]._nameSid)))
        end
         
        local mode = require("CardPackagePanel").Mode.open_one
        local panel = require("CardPackagePanel").create(mode, newCards, self._curRecruitInfo, self._detailInfoOnce)
        panel:show()
        
        local curStep = GuideManager.getCurStepName()
        if string.find(curStep, "buy once") then
            GuideManager._finger:setVisible(false)
            GuideManager.finishStepLater(0.8)
        end
                        
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_CARDBOX_INFO or msgType == SglMsgType_pb.PB_TYPE_RESET_CARDBOX then
        if not self._detailInfoOnce then return false end
        if Data.getIsTimesLimitRecruite(self._detailInfoOnce) then return false end
        local objs = msg.Extensions[Card_pb.SglCardMsg.card_box_info_resp]

        self._packageCards = {}
        for i = 1, #objs do

            if (Data.getInfo( objs[i].info_id) ~= nil) then
                self._packageCards[i] = {_infoId = objs[i].info_id, _getNum = objs[i].get_num, _remainNum = objs[i].remain_num}
            end
        end

        if msg:HasExtension(Card_pb.SglCardMsg.remain_pkg_ur_resp) then
            self._remainUrCount = msg.Extensions[Card_pb.SglCardMsg.remain_pkg_ur_resp] 
        else
            self._remainUrCount = nil
        end

        V.getActiveIndicator():hide()
        self:showCardBox()

        local curStep = GuideManager.getCurStepName()
        if string.find(curStep, "buy package") then
            GuideManager._finger:setVisible(false)
            GuideManager.finishStepLater(0.8)
        end

    --[[elseif msgType == SglMsgType_pb.PB_TYPE_REMAIN_PKG_UR then
        local remainUrCount = msg.Extensions[Card_pb.SglCardMsg.remain_pkg_ur_resp]

        self._remainUrCount = remainUrCount

        V.getActiveIndicator():hide()
        self:updateCardBox()]]

    end
    
    return false
end

function _M:afterOpenPackage(cards)
    GuideManager.finishStep()

    -- legend
    if self._detailInfoOnce._type == 1001 or self._detailInfoOnce._type == 1012 then
        if self._remainUrCount <= 0 then
            self:sendShowDetail(self._detailInfoOnce, self._detailInfoTen, self._detailInfoFifty)
        else
            for i = 1, #cards do
                local card = cards[i]
                if Data.getInfo(card._infoId)._quality == Data.CardQuality.UR then
                    self:sendShowDetail(self._detailInfoOnce, self._detailInfoTen, self._detailInfoFifty)
                    break
                end
            end
        end
    
    -- normal
    elseif self._detailInfoOnce._type == 1002 then
        local _, _, packageCount = self:getPackageInfo() 

        if packageCount <= 0 then
            self:sendShowDetail(self._detailInfoOnce, self._detailInfoTen, self._detailInfoFifty)
        end

    end
end

function _M:addRecruitEffects(recruitItem)
    local position = recruitItem:getParent():convertToWorldSpace(cc.p(lc.x(recruitItem), lc.top(recruitItem) - 120))
    --if recruitTimes == RECRUIT_ONCE and recruitType ~= RECRUIT_LEGEND then
    if false then
        local particle1 = Particle.create("par_lottery2")
        local particle2 = Particle.create("par_lottery3")
        particle1:setPosition(position)
        particle2:setPosition(position)
        self._scene:addChild(particle1, ClientData.ZOrder.effect)
        self._scene:addChild(particle2, ClientData.ZOrder.effect)
    else
        local particle = Particle.create("par_lottery1")
        particle:setPosition(position)
        self._scene:addChild(particle, ClientData.ZOrder.effect)
    end
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if self._tabArea._focusedTab._index ~= _M.TAB.rare_draw_card then
        self._tabArea:showTab(_M.TAB.rare_draw_card)
    end
    if string.sub(curStep, 1, 11) == "buy package" then
        local focusItem = self._recruitItems[1]
        self._list:forceDoLayout()
--        self._list:gotoPos(lc.left(focusItem) - 10)
        GuideManager.setOperateLayer(focusItem)
    elseif string.sub(curStep, 1, 8) == "buy once" then
        local focusItem = self._detailPanel._costOnceBtn
        GuideManager.setOperateLayer(focusItem)
    elseif curStep == "leave tavern" then
        GuideManager.setOperateLayer(self._titleArea._btnBack)
    else
        return
    end
        
    event:stopPropagation()
end

function _M:isGuideRarePackage()
    return P._guideID < 154
end

function _M:sendShowDetail(infoOnce, infoTen, infoFifty)
    self._detailInfoOnce = infoOnce
    self._detailInfoTen = infoTen
    self._detailInfoFifty = infoFifty

    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendCardBoxInfo(infoOnce._value)
end

function _M:sendBuyPackage(recruitInfo)
    lc.Audio.playAudio(AUDIO.E_TAVERN_BUY_PACKAGE)
    
    self._curRecruitInfo = recruitInfo

    if self._remainUrCount then
        self._remainUrCount = self._remainUrCount - recruitInfo._value % 100
    end

    local resNeed = recruitInfo._param[2]
    if Data.getIsRareRecruite(recruitInfo) and P._propBag:hasProps(Data.PropsId.rare_package_ticket, recruitInfo._value % 100) then
        resNeed = recruitInfo._value % 100
        if not P._propBag:hasProps(Data.PropsId.rare_package_ticket, resNeed) then
            ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._propsInfo[Data.PropsId.rare_package_ticket]._nameSid)))
            return false
        else
            V.getActiveIndicator():show(Str(STR.RECRUITING))
            ClientData.sendCardLottery(recruitInfo._value, false, true)
        
            P._propBag:changeProps(Data.PropsId.rare_package_ticket, -resNeed)
        end
    elseif Data.getIsCharacterRecruite(recruitInfo) and P._propBag:hasProps(Data.PropsId.character_package_ticket, recruitInfo._value % 100) then
        resNeed = recruitInfo._value % 100
        if not P._propBag:hasProps(Data.PropsId.character_package_ticket, resNeed) then
            ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._propsInfo[Data.PropsId.character_package_ticket]._nameSid)))
            return false
        else
            V.getActiveIndicator():show(Str(STR.RECRUITING))
            ClientData.sendCardLottery(recruitInfo._value, false, true)
        
            P._propBag:changeProps(Data.PropsId.character_package_ticket, -resNeed)
        end
    elseif recruitInfo._param[1] == Data.ResType.ingot or recruitInfo._param[1] == Data.ResType.gold then
        if (recruitInfo._param[1] == Data.ResType.ingot and V.checkIngot(resNeed)) or (recruitInfo._param[1] == Data.ResType.gold and V.checkGold(resNeed)) then    
            V.getActiveIndicator():show(Str(STR.RECRUITING))
            ClientData.sendCardLottery(recruitInfo._value, false, false)
        
            P:changeResource(recruitInfo._param[1], -resNeed)
        end
    else
        if not P._propBag:hasProps(recruitInfo._param[1], resNeed) then
            ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._propsInfo[recruitInfo._param[1]]._nameSid)))
            if recruitInfo._param[1] ~= Data.PropsId.miracle_indicator then
                require("ExchangeResForm").create(recruitInfo._param[1]):show()
            end
            return false
        else
            V.getActiveIndicator():show(Str(STR.RECRUITING), LOTTERY_EFFECT_DURATION)
            ClientData.sendCardLottery(recruitInfo._value, false, false)
        
            P._propBag:changeProps(recruitInfo._param[1], -resNeed)
        end
    end
end

function _M:sendResetBox(recruitInfo)
    V.getActiveIndicator():show(Str(STR.RECRUITING), LOTTERY_EFFECT_DURATION)
    ClientData.sendCardBoxReset(recruitInfo._value, false)
end

function _M:showCardBox()
    if Data.getIsGodPumpRecruite(self._detailInfoOnce) then
        return self:showGodPumpBox()
    end

    if self._detailPanel then
        return self:updateCardBox()
    end

    local infoOnce = self._detailInfoOnce
    local infoTen = self._detailInfoTen
    local infoFifty = self._detailInfoFifty

    self._list:setVisible(false)

    local node = cc.Node:create()
    node:setContentSize(V.SCR_SIZE)
    node:setAnchorPoint(cc.p(0.5, 0.5))
    lc.addChildToCenter(self, node, 1)
    self._detailPanel = node

    local package = V.createCardPackage(infoOnce)
    lc.addChildToPos(self, package, cc.p(lc.cw(package) + 20, lc.ch(self._bg)) , 101)
    self._detailPanel._package = package
    local btn = V.createShaderButton(nil, function ()
        if self._detailPanel then
            self:hideCardBox()
        elseif self._rareShopArea._detailPanel then
            self._rareShopArea:hideCardBox()
        elseif self._diamondShopArea._detailPanel then
            self._diamondShopArea:hideCardBox()
        end
    end)

    btn:setContentSize(cc.size(lc.w(package), lc.h(package)))
    lc.addChildToCenter(package, btn)

    local RR_count = lc.createSprite("tavern_rr")
    RR_count:setAnchorPoint(0, 1)
    lc.addChildToPos(package, RR_count, cc.p(lc.right(package) - 24, lc.top(package) - 40))
    RR_count:setVisible(false)

    self._bg2:setVisible(true)

    --check whether it's locked
    local isLocked, str = self:isLocked(infoOnce)

    -- card list
    self:initCardList(node, require("CardList").ModeType[infoOnce._type == 1002 and "recruite" or "recruite_langend"])

    -- box info
    
    local bg = lc.createSprite({_name = infoOnce._type == 1002 and "img_com_bg_39" or "img_com_bg_40", _size = cc.size(V.SCR_W - 240, 66), _crect = cc.rect(4, 33, 1, 1)})
    lc.addChildToPos(node, bg, cc.p(V.SCR_W - lc.cw(bg), 166))
    
    bg:setVisible(false)

    local countBgSize
    if infoOnce._type == 1002 then
        countBgSize = cc.size(80, 30)
    else
        countBgSize = cc.size(40, 30)
    end
    node._cardCounts = {}
    node._qulityRemain = {}
    local qualityIcons = {"img_icon_quality_c", "img_icon_quality_u", "img_icon_quality_r", "img_icon_quality_rr"}
    for i = 1, 4 do
        local icon = lc.createSprite(qualityIcons[i])
        local pos = cc.p(lc.right(package) + lc.cw(icon) - 24, lc.top(package) - 40 - lc.ch(icon) - (lc.h(icon) + 4) * (i - 1))
        lc.addChildToPos(package, icon, pos)
        node._qulityRemain[i] = icon

        local label = V.createTTF("100\n100", V.FontSize.S3)
        label:setScale(0.9)
        lc.addChildToPos(icon, label, cc.p(lc.cw(icon), lc.ch(icon) - 10))
        node._cardCounts[i] = label
    end

    if infoOnce._type == 1002 then
        RR_count:setVisible(false)

        -- remain package count
        local countBg = lc.createSprite{_name = "tavern_reset_bg", _crect = cc.rect(3, 0, 1, 38), _size = cc.size(lc.w(package) - 40, 38)}
        lc.addChildToPos(package, countBg, cc.p(lc.cw(package), 100), 3)
        local countRemain = V.createTTFStroke(Str(STR.REMIAN_CARD_PACKAGE), V.FontSize.S3)
        lc.addChildToPos(countBg, countRemain, cc.p(70, lc.ch(countBg)))

        local countLabel = V.createTTFBold("200", V.FontSize.S3)
        lc.addChildToPos(countBg, countLabel, cc.p(lc.right(countRemain) + 25, lc.ch(countBg)))
        node._packageCount = countLabel
        --HERE
        local resetBtn = V.createShaderButton("img_btn_reset", function(sender) 
            if isLocked then
                ToastManager.push(str)
            else
                require("Dialog").showDialog(Str(STR.CONFIRM_RESET_PACKAGES), function()
                    self:sendResetBox(infoOnce) 
                end, false)
            end
        end)
        lc.addChildToPos(countBg, resetBtn, cc.p(lc.w(countBg) - 40, lc.ch(countBg)))

        local tips = lc.createSprite("txt_tips")
        lc.addChildToPos(countBg, tips, cc.p(V.SCR_W - 85, V.SCR_CH - 176), 3)

        for i = 1, 4 do
            node._qulityRemain[i]:setVisible(true)
        end
    
    else
        -- remain ui count
        RR_count:setVisible(true)
        local str = string.format(Str(STR.RECRUIT_MORE_TIP), 10)
        local buyTip = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S2, 28)
        buyTip:setAnchorPoint(cc.p(0.5, 1))
        buyTip:setScale(0.9)
        lc.addChildToPos(RR_count, buyTip, cc.p(lc.cw(RR_count) - 122, lc.h(RR_count) - 3), 2)
        node._buyTip = buyTip

        local urRareCards = {}
         for i = 1, #self._packageCards do
            local info = self._packageCards[i]
            local quality = Data.getInfo(info._infoId)._quality
            if quality==Data.CardQuality.UR then
                table.insert(urRareCards , info._infoId)
            end
        end
        local composeBtn = V.createScale9ShaderButton("img_btn_1_s" , function(sender) require("ComposeForm").create(urRareCards, infoOnce._value):show() end ,   cc.rect(0,0,0,0), 90, 60)
        composeBtn:addLabel(Str(STR.COMPOSE))
        lc.addChildToPos(bg, composeBtn, cc.p(lc.w(bg) - 70, lc.ch(bg)))

        composeBtn:setVisible(false)
        lc.offset(buyTip, 120, 0)

        for i = 1, 4 do
            node._qulityRemain[i]:setVisible(false)
        end

    end
    
    -- button
    local margin = 26 - 22 * (1366 - V.SCR_W) / (1366 - 1024)
    local costOnceBtn = self:createCostArea(infoOnce, 1, infoOnce)
    costOnceBtn._callback = function(sender)
        if isLocked then
            ToastManager.push(str)
        else
            self:sendBuyPackage(infoOnce)
        end 

        -- Close the guide if exists
        --GuideManager.closeNpcTipLayer()
    end
    lc.addChildToPos(node, costOnceBtn, cc.p(cc.p((V.SCR_W + lc.right(self._detailPanel._package)) / 2 - lc.w(costOnceBtn) - margin, 70)), 3)
    node._costOnceBtn = costOnceBtn

    local costTenBtn = self:createCostArea(infoTen, 10, infoOnce)
    costTenBtn._callback = function(sender)
        if isLocked then
            ToastManager.push(str)
        else
            self:sendBuyPackage(infoTen)
        end 
    end
    lc.addChildToPos(node, costTenBtn, cc.p((V.SCR_W + lc.right(self._detailPanel._package)) / 2 , 70), 2)
    node._costTenBtn = costTenBtn
    
    local costFiftyBtn = self:createCostArea(infoFifty, 50, infoOnce)
    costFiftyBtn._callback = function(sender)
       if isLocked then
            ToastManager.push(str)
        else
            self:sendBuyPackage(infoFifty)
        end 
    end
    lc.addChildToPos(node, costFiftyBtn, cc.p((V.SCR_W + lc.right(self._detailPanel._package)) / 2 + lc.w(costFiftyBtn) + margin, 70), 1)
    node._costFiftyBtn = costFiftyBtn

    if Data.getIsTimeLimitRoleRecruite(infoOnce) then
        node._costOnceBtn:setPosition(node._costTenBtn:getPosition())
        node._costTenBtn:setVisible(false)
        node._costFiftyBtn:setVisible(false)
    end

    -- reset
    self:updateCardBox()

    -- animation
    package:setPosition(cc.p(lc.x(package) + 100, lc.y(package)))
    package:runAction(lc.sequence(
        lc.moveBy(0.2, cc.p(-100, 0))
        ))

    node:setVisible(false)
    node:setPosition(cc.p(V.SCR_CW-200, V.SCR_CH))
    node:runAction(lc.sequence(
        lc.delay(0.2), 
        lc.show(),
        lc.ease(lc.moveBy(0.3, cc.p(200, 0)), "BackO")
        ))

    if Data.getIsRareRecruite(infoOnce) then
        V.getResourceUI():setMode(Data.PropsId.rare_package_ticket)
    elseif Data.getIsCharacterRecruite(infoOnce) then
        V.getResourceUI():setMode(Data.PropsId.character_package_ticket)
    end
end

function _M:showGodPumpBox()
    if not Data.getIsGodPumpRecruite(self._detailInfoOnce) then
        return 
    end
    self._list:setVisible(false)

    if self._detailPanel then
        return self:updateGodPumpBox()
    end

    --self._bg:setTexture("res/jpg/god_pump_bg.jpg")

    local bottomArea = V.createLineSprite("img_bottom_bg", V.SCR_W)
    lc.addChildToPos(self, bottomArea, cc.p(V.SCR_CW, lc.ch(bottomArea)))
    self._bottomArea = bottomArea

    local infoOnce = self._detailInfoOnce
    local infoTen = self._detailInfoTen

    local node = cc.Node:create()
    node:setContentSize(V.SCR_SIZE)
    node:setAnchorPoint(cc.p(0.5, 0.5))
    lc.addChildToCenter(self, node, 1)
    self._detailPanel = node

    local cardsNode = lc.createNode()
    lc.addChildToPos(node, cardsNode, cc.p(lc.cw(node), lc.ch(node) + 70))
    local cards = {}
    local scale = 0.6
    for i, card in ipairs(self._packageCards) do
        local id = card._infoId
        local cardArea = lc.createNode()
        cardArea._id = id
        local cardBtn = V.createShaderButton(nil, function() CardInfoPanel.create(id, 1, CardInfoPanel.OperateType.view):show() end)
        local card = require("CardThumbnail").create(id, 1.0)
        card:setScale(scale)
        cardBtn:setContentSize(lc.w(card) * scale, lc.h(card) * scale)
        lc.addChildToCenter(cardBtn, card)

        local stage = lc.createSprite("god_pump_stage")
        local light = lc.createSprite("god_pump_light")
        cardArea:setContentSize(lc.w(light), lc.h(card) * scale + 140)
        lc.addChildToPos(cardArea, stage, cc.p(lc.cw(cardArea), lc.ch(stage)))
        lc.addChildToPos(cardArea, light, cc.p(lc.cw(cardArea), lc.h(stage) + lc.ch(light) - 40))

        lc.addChildToPos(cardArea, cardBtn, cc.p(lc.cw(cardArea), lc.h(cardArea) - lc.ch(cardBtn)))

        local effectNode = lc.createNode()
--        effectNode:setContenSize(card:getContenSize())
        lc.addChildToPos(cardArea, effectNode, cc.p(cardBtn:getPosition()), -1)
        cardArea._effectNode = effectNode

        local composeBtn = V.createShaderButton("god_pump_btn", function(sender)
                
                if P._playerCard:composeCardByFragment(cardArea._id, true) == Data.ErrorType.compose_common_fragment then
                    require("Dialog").showDialog(string.format(Str(STR.COMFIRM_COMPOSE_WITH_COMMON_FRAGMENT), Data._globalInfo._legendCardMixCount - P._playerCard:getFragmentCount(cardArea._id)), function()
                        P._playerCard:composeCardByFragment(cardArea._id)
                        require("CardComposePanel").create(cardArea._id):show()
                        end)
                elseif P._playerCard:composeCardByFragment(cardArea._id, true) == Data.ErrorType.ok then
                    require("Dialog").showDialog(Str(STR.COMFIRM_COMPOSE_FRAGMENT), function()
                        P._playerCard:composeCardByFragment(cardArea._id)
                        require("CardComposePanel").create(cardArea._id):show()
                        end)
                else
                    return ToastManager.push(Str(STR.FRAGMENT_NOT_ENOUGH))
                end
            end)
        composeBtn:setDisabledShader(V.SHADER_DISABLE)
        lc.addChildToPos(cardArea, composeBtn, cc.p(lc.cw(cardArea), lc.ch(composeBtn)))
        composeBtn:addLabel(Str(STR.COMPOSE))
        cardArea._composeBtn = composeBtn

        local progressBar = V.createLabelProgressBar(lc.w(composeBtn), nil, V.COLOR_TEXT_WHITE, V.COLOR_TEXT_BLUE)
        lc.addChildToPos(cardArea, progressBar, cc.p(lc.cw(cardArea), lc.top(composeBtn) + 10))
        progressBar._bar:setPercent(P._playerCard:getFragmentCount(cardArea._id) / Data._globalInfo._legendCardMixCount * 100)
        progressBar:setLabel(P._playerCard:getFragmentCount(cardArea._id), Data._globalInfo._legendCardMixCount)
        cardArea._progressBar = progressBar

        table.insert(cards, cardArea)
    end
    lc.addNodesToCenterH(cardsNode, cards,  - 40)
    node._cards = cards

    local checkOwn = function()
        local allOwn = true
        for _, card in ipairs(self._packageCards) do
            local info = Data.getInfo(card._infoId)
            if P._playerCard:getCardCount(card._infoId) < info._maxCount and P._playerCard:getFragmentCount(card._infoId) < Data._globalInfo._legendCardMixCount then
                allOwn = false
                break
            end
        end
        if allOwn then
            ToastManager.push(Str(STR.ALL_CARDS_OWNED))
            return false
        end
        return true
    end

    local costOnceBtn = self:createCostArea(infoOnce, 1, infoOnce)
    costOnceBtn._callback = function(sender)
        if checkOwn() then
            self:sendBuyPackage(infoOnce)
        end
    end
    lc.addChildToPos(node, costOnceBtn, cc.p(lc.cw(node) - 200, lc.ch(node) - 200))
    node._costOnceBtn = costOnceBtn

    local costTenBtn = self:createCostArea(infoTen, 10, infoTen)--dont show discount
    costTenBtn._callback = function(sender)
        if checkOwn() then
            self:sendBuyPackage(infoTen)
        end
    end
    lc.addChildToPos(node, costTenBtn, cc.p(lc.cw(node) + 200, lc.ch(node) - 200))
    node._costTenBtn = costTenBtn

    -- log
    local unOpenedBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender) require("GodPumpUnopendForm").create():show() end, V.CRECT_BUTTON_S, 120)
    lc.addChildToPos(node, unOpenedBtn, cc.p(lc.w(node) - 280, 40))
    unOpenedBtn:addLabel(Str(STR.LOTTERY_UNOPENED))

    local openedBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender) require("GodPumpOpendForm").create():show() end, V.CRECT_BUTTON_S, 120)
    lc.addChildToPos(node, openedBtn, cc.p(lc.w(node) - 130, 40))
    openedBtn:addLabel(Str(STR.LOTTERY_OPENED))

    -- reset
    self:updateGodPumpBox()

    -- animation
    node:setVisible(false)
    node:setPosition(cc.p(V.SCR_CW-200, V.SCR_CH))
    node:runAction(lc.sequence(
        lc.delay(0.2), 
        lc.show(),
        lc.ease(lc.moveBy(0.3, cc.p(200, 0)), "BackO")
        ))
end

function _M:updateGodPumpBox()
    local node = self._detailPanel
    if not node then return end

    local cards = node._cards
    for i, cardArea in ipairs(cards) do
        local info = Data.getInfo(cardArea._id)
        local progressBar = cardArea._progressBar
        progressBar._bar:setPercent(P._playerCard:getFragmentCount(cardArea._id) / Data._globalInfo._legendCardMixCount * 100)
        if P._playerCard:getCardCount(cardArea._id) < info._maxCount then
            progressBar:setLabel(P._playerCard:getFragmentCount(cardArea._id), Data._globalInfo._legendCardMixCount)
        else
            progressBar:setLabel(Str(STR.UNION_SHOP_OWN))
        end
        local composeResult = P._playerCard:composeCardByFragment(cardArea._id, true)
        cardArea._composeBtn:setEnabled(composeResult ~= Data.ErrorType.fragment_not_enough)
        cardArea._composeBtn:setVisible(P._playerCard:getCardCount(cardArea._id) < info._maxCount)
        cardArea._effectNode:removeAllChildren()
        if composeResult == Data.ErrorType.compose_common_fragment and P._playerCard:getCardCount(cardArea._id) < info._maxCount then
            local bones = DragonBones.create("xuanzhong")
            bones:setScale(1.2)
            bones:gotoAndPlay("effect1")
            lc.addChildToCenter(cardArea._effectNode, bones)
--            par:runAction(lc.rep(lc.sequence(0.2, function() par:resetSystem() end)))
        elseif composeResult == Data.ErrorType.ok and P._playerCard:getCardCount(cardArea._id) < info._maxCount then
            local par = Particle.create("par_urxz")
            par:setScale(0.5)
            lc.addChildToCenter(cardArea._effectNode, par)
        end
    end

    node._costOnceBtn:update()
    node._costTenBtn:update()
end

function _M:hideCardBox()
    --self._bg:setTexture("res/jpg/ui_scene_bg.jpg")
    --lc.TextureCache:removeTextureForKey("res/jpg/god_pump_bg.jpg")
    self._list:setVisible(true)
    self._bg2:setVisible(false)

    if self._bottomArea then
        self._bottomArea:removeFromParent()
        self._bottomArea = nil
    end

    if self._detailPanel then
        if self._detailPanel._package then
            self._detailPanel._package:removeFromParent()
            self._detailPanel._package = nil
        end

        self._detailPanel:removeFromParent()
        self._detailPanel = nil

        self._detailInfoOnce = nil
        self._detailInfoTen = nil

    end


    self:setResourcePanel()
end

function _M:updateCardBox()
    if not self._detailPanel or not self._detailInfoOnce then
        return
    end

    if Data.getIsGodPumpRecruite(self._detailInfoOnce) then
        return self:updateGodPumpBox()
    end

    self:updateCardList()

    local remainCounts, getCounts, packageCount = self:getPackageInfo()

    if self._detailPanel._packageCount then
        for i = 1, #self._detailPanel._cardCounts do
            self._detailPanel._cardCounts[i]:setString(string.format("%d\n%d", remainCounts[i], getCounts[i] + remainCounts[i]))
        end

        self._detailPanel._packageCount:setString(packageCount)
--[[
    else
        for i = 1, #self._detailPanel._cardCounts do
            self._detailPanel._cardCounts[i]:setString(getCounts[i] + remainCounts[i])
        end
]]
    end

    if self._detailPanel._buyTip then
        if Data.getIsTimeLimitRoleRecruite(self._detailInfoOnce) then
            V.updateBoldRichTextMultiLine(self._detailPanel._buyTip, Str(STR.RECRUIT_MORE_TIP_2))
        else
            local str = string.format(Str(STR.RECRUIT_MORE_TIP), self._remainUrCount)
            V.updateBoldRichTextMultiLine(self._detailPanel._buyTip, str)
        end
    end

    self._detailPanel._costOnceBtn:update()
    self._detailPanel._costTenBtn:update()
    self._detailPanel._costFiftyBtn:update()
end

function _M:initCardList(node, mode)
    local width = math.min(V.SCR_W - 440 + 20, 800 + 20)

    self._cardList = require("CardList").create(cc.size(width, 480), 0.33, false)
    self._cardList:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(node, self._cardList, cc.p((V.SCR_W + lc.right(self._detailPanel._package)) / 2, V.SCR_CH - 24))

    self._cardList:setMode(mode)
    self._cardList._recruiteInfo = self._packageCards
    
    local offsetx = -15 -- (V.SCR_W - 380 - lc.w(self._cardList)) / 8
    self._cardList._pageLeft._pos = cc.p(-offsetx, lc.ch(self._cardList))
    self._cardList._pageRight._pos = cc.p(lc.w(self._cardList) + offsetx, lc.ch(self._cardList))
    
    offsetx = 240 - (lc.x(self._cardList) - lc.cw(self._cardList))
    local pageBg = lc.createSprite({_name = "img_page_bg", _size = cc.size(125, 33), _crect = cc.rect(11, 11, 4, 8)}) 
    lc.addChildToPos(self._cardList, pageBg, cc.p(lc.cw(self._cardList), mode == self._cardList.ModeType.recruite and -8 or -2), -1)
    pageBg:setFlippedX(true)
    pageBg:setScale(0.8)
    self._cardList._pageLabel:setPosition(cc.p(pageBg:getPosition()))

    self._cardList:registerCardSelectedHandler(function(data) 
        require("CardInfoPanel").create(data, 1, require("CardInfoPanel").OperateType.view):show()
    end)
end

function _M:updateCardList()
    self._cardList._recruiteInfo = self._packageCards
    self._cardList:init(nil, {})
    self._cardList:refresh(true)
end

function _M:getPackageInfo()
    local remainCounts = {0, 0, 0, 0, 0}
    local getCounts = {0, 0, 0, 0, 0}
    for i = 1, #self._packageCards do
        local info = self._packageCards[i]
        local index = Data.getInfo(info._infoId)._quality
        remainCounts[index] = remainCounts[index] + info._remainNum 
        getCounts[index] = getCounts[index] + info._getNum
    end

    local totalCount = 0
    for i = 1, #remainCounts do
        totalCount = totalCount + remainCounts[i]
    end
    local packageCount = math.floor(totalCount / 5)

    return remainCounts, getCounts, packageCount
end

function _M:removeCardFromPackage(infoId, num)
    if self._detailInfoOnce._type == 1002 then 
        for i = 1, #self._packageCards do
            local info = self._packageCards[i]
            if info._infoId == infoId then
                info._getNum = info._getNum + num
                info._remainNum = info._remainNum - num
            end
        end
    end
end

function _M:isLocked(info)
    local isLocked, str = false, ""
    local value = math.floor(info._value / 100) * 100 + 1
    if Data.getIsTimeLimitRecruite(info) then
        if Data.getIsTimeLimitRoleRecruite(info) then
            local heroInfos = {[205001] = Data._characterInfo[3], [206001] = Data._characterInfo[2], [207001] = Data._characterInfo[5], [208001] = Data._characterInfo[12], [209001] = Data._characterInfo[4], [210001] = Data._characterInfo[13]}
            local heroInfo = heroInfos[value]
            if heroInfo and not P:isCharacterUnlocked(heroInfo._id) then
                isLocked = true
                str = string.format("%s\n|%s|", Str(STR.NEED_UNLOCK), lc.str(heroInfo._nameSid))
            end
        end
    elseif Data.getIsRareRecruite(info) then
        if value == 102001 then
        elseif value == 103001 and P:getCharacterUnlockCount() < 2 then
            isLocked = true
            str = string.format(Str(STR.NEED_UNLOCK_CHARACTER_COUNT), 2)
        elseif value == 104001 and P:getCharacterUnlockCount() < 2 then
            isLocked = true
            str = string.format(Str(STR.NEED_UNLOCK_CHARACTER_COUNT), 2)
        end
    elseif Data.getIsCharacterRecruite(info) then
        local heroInfo = nil
        for id, info in pairs(Data._characterInfo) do
            if info._packageIds[1] == value then
                heroInfo = info
                break
            end
        end

        if heroInfo and not P:isCharacterUnlocked(heroInfo._id) then
            isLocked = true
            str = string.format("%s\n|%s|", Str(STR.NEED_UNLOCK), lc.str(heroInfo._nameSid))
        end
    end
    return isLocked, str
end

return _M