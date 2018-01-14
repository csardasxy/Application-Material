local _M = class("ActivityScene", require("BaseUIScene"))

_M.Tab = {
    first_recharge = 1,
    package = 2, 
    month_card = 3,
    fund = 4,
    invite = 5,
    feed_back = 6,

    limit_small = 10,
    limit_large_01 = 11,
    limit_large_02 = 12,
    limit_large_03 = 13,
    limit_large_04 = 14,
    limit_large_05 = 15,

    return_to_game = 21,
}

function _M.create(...)
    return lc.createScene(_M, ...)
end

function _M:init(tab)
    if not _M.super.init(self, ClientData.SceneId.activity, STR.ACTIVITY, require("BaseUIScene").STYLE_SIMPLE, false) then return false end

    --bg
    --self._bg:setTexture("res/jpg/recharge_bg.jpg")
    --self._bg:setLocalZOrder(-2)

    -- edge
    local edge1 = lc.createSprite('res/jpg/activity_edge.jpg')
    edge1:setAnchorPoint(0, 0)
    lc.addChildToPos(self._bg, edge1, cc.p(228, 0))

    edge2 = lc.createSprite('res/jpg/activity_edge.jpg')
    edge2:setFlippedX(true)
    edge2:setAnchorPoint(1, 0)
    lc.addChildToPos(self._bg, edge2, cc.p(lc.w(self._bg) + 20, 0))
    
    -- ui
    self._initTab = tab
    --self:updateTabs(tab)

    return true
end

function _M:onEnter()
    _M.super.onEnter(self)

    local events = {
        Data.Event.month_card_dirty,
        Data.Event.fund_dirty, 
        Data.Event.package_dirty, 
        Data.Event.bonus_dirty
        }
    
    self._listeners = {}
    for i = 1, #events do
        local listener = lc.addEventListener(events[i], function(event) self:onEvent(event, events[i]) end)
        table.insert(self._listeners, listener)        
    end
    
    self:updateTabs()
    self:updateButtonFlags()
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    V.getMenuUI():updateActivityFlag()
end

function _M:onCleanup()
    _M.super.onCleanup(self)
    
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/recharge_bg.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_first_recharge.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_first_recharge_01.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_first_recharge_02.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_feedback.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_fund.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_month_card.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_invite_1.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_invite_2.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_01.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_02.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_03.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_04.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_05.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_return.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_recharge.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_package.jpg"))

    ClientData.unloadLCRes(self._resNames)
end

function _M:updateTabs()
    -- clean
    local preTab = nil
    if self._tabArea then
        if self._tabArea._focusedTab then
            preTab = self._tabArea._focusedTab._index
        end
        self._tabArea:removeFromParent()
    end

    -- ui
    local tabDefs = {
        {_index = _M.Tab.month_card, _str = Str(STR.MONTH_CARD)},
        {_index = _M.Tab.fund, _str = Str(STR.FUND_LEVEL)},
        {_index = _M.Tab.invite, _str = Str(STR.INVITE_PACKAGE)},
        {_index = _M.Tab.feed_back, _str = Str(STR.FEEDBACK_PACKAGE)},
    }

    -- package
    if not ClientData.isRecharged(Data.PurchaseType.package_6) then
         table.insert(tabDefs, 1, {_index = _M.Tab.package, _str = Str(STR.RECHARGE_PACKAGE)})
    end
    -- first rechage
    if self:getFirstRechargeStatus() == 0 then
        table.insert(tabDefs, 1, {_index = _M.Tab.first_recharge, _str = Str(STR.FIRST_RECHARGE_BONUS)})
    else
        table.insert(tabDefs, 1, {_index = _M.Tab.first_recharge, _str = Str(STR.FIRST_RECHARGE_BONUS_2)})
    end
    
    if ClientData.isActivityValidByParam(Data.PurchaseType.limit_2) then
        table.insert(tabDefs, 1, {_index = _M.Tab.limit_large_02, _str = Str(ClientData.getActivityByParam(Data.PurchaseType.limit_2)._nameSid)})
    end
    if ClientData.isActivityValidByParam(Data.PurchaseType.limit_1) then
        table.insert(tabDefs, 1, {_index = _M.Tab.limit_large_01, _str = Str(ClientData.getActivityByParam(Data.PurchaseType.limit_1)._nameSid)})
    end

    if ClientData.isReturnToGame() and not ClientData.isReturnToGameClaimed() then
        table.insert(tabDefs, 1, {_index = _M.Tab.return_to_game, _str = Str(STR.RETURN_PACKAGE)})
    end

    --for i = Data.PurchaseType.limit_3, Data.PurchaseType.limit_4 do
    for i = Data.PurchaseType.limit_3, Data.PurchaseType.limit_3 do
        if  ClientData.isActivityValidByParam(i) then
            local activityInfo = ClientData.getActivityByParam(i)
            table.insert(tabDefs, 1, {_index = _M.Tab.limit_large_03 + i - Data.PurchaseType.limit_3, _str = Str(activityInfo._nameSid)})
        end
    end
    
    local tabArea = V.createVerticalTabListArea(lc.bottom(self._titleArea), tabDefs, function(tab, isSameTab, isUserBehavior)
        if not isSameTab or isUserBehavior then
            self:showTab(tab)
        end
    end)
    lc.addChildToPos(self, tabArea, cc.p(lc.w(tabArea) / 2 - 4, lc.bottom(self._titleArea) / 2 + 2), 1)
    self._tabArea = tabArea

    -- reset
    local tab = self._initTab or preTab
    self._initTab = nil

    local isInList = false
    if tab then
        for i = 1, #tabDefs do
            if tabDefs[i]._index == tab then
                isInList = true
                break
            end
        end 
    end

    if not isInList then
        tab = tabDefs[1]._index
    end
    self._tabArea:showTab(tab, true)
end

function _M:showTab(tab)
    if not self._detailLayer then
        self._detailLayer = lc.createNode(cc.size(math.min(V.SCR_W - lc.w(self._tabArea), 1126), V.SCR_H - lc.h(self._titleArea)))
        lc.addChildToPos(self, self._detailLayer, cc.p((V.SCR_W + lc.w(self._tabArea)) / 2, lc.ch(self._detailLayer)), -1)
    else
        self._detailLayer:removeAllChildren()
    end

    if tab._index == _M.Tab.month_card then
        self:initMonthCard()
    elseif tab._index == _M.Tab.fund then
        self:initFund()
    elseif tab._index == _M.Tab.package then
        self:initPackage()
    elseif tab._index == _M.Tab.first_recharge then
        self:initFirstRecharge()
    elseif tab._index == _M.Tab.feed_back then
        self:initFeedBack()
    elseif tab._index == _M.Tab.invite then
        self:initInvite()
    elseif tab._index == _M.Tab.limit_small then
        self:initLimitSmall()
    elseif tab._index == _M.Tab.limit_large_01 or tab._index == _M.Tab.limit_large_02 then
        self:initLimitLarge(tab._index)
    elseif tab._index >= _M.Tab.limit_large_03 and tab._index <= _M.Tab.limit_large_05 then
        self:initLimitLarge(tab._index)
    elseif tab._index == _M.Tab.return_to_game then
        self:initReturnPackage(tab._index)
    end
end

-----------------------------------
-- first recharge

function _M:initFirstRecharge()
    local layer = self._detailLayer

    local status = self:getFirstRechargeStatus()
    if status == 0 then
        local bg = lc.createSprite("res/jpg/activity_first_recharge.jpg")
        lc.addChildToCenter(layer, bg)

        -- bonus
        local bonus = P._playerBonus._packageBonus[1120]
        local info = bonus._info

        local icons = {}
        for i = 1, #info._rid do
            local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
            icon._name:setVisible(false)
            icon:setScale(0.85)
            table.insert(icons, icon)
        end
        P:sortResultItems(icons)

        local centerPos = cc.p(lc.cw(bg) - 20, lc.ch(bg) - 210)
        for i = 1, #icons do
            local icon = icons[i]
            local pos = cc.p(centerPos.x + (lc.w(icon) + 0) * (i - (#icons + 1) / 2), centerPos.y)
            lc.addChildToPos(bg, icon, pos)
        end

        -- btn
        local btn = V.createShaderButton("img_btn_recharge_1", function(sender) end) 
        lc.addChildToPos(bg, btn, cc.p(lc.cw(bg) + 260, lc.ch(bg) - 200))
        btn:setDisabledShader(V.SHADER_DISABLE)
        btn:addLabel(Str(STR.RECHARGE_NOW))
        self._firstChargeBtn = btn

    elseif status == 1 then
        self._resNames = ClientData.loadLCRes("res/first_recharge.lcres")

        local bg = lc.createSprite("res/jpg/activity_first_recharge_01.jpg")
        lc.addChildToCenter(layer, bg)

        local jigsawBg = lc.createSprite('recharge_jigsaw_bg')
        lc.addChildToPos(layer, jigsawBg, cc.p(lc.cw(layer), 536))
        self._jigsawBg = jigsawBg

        local jigSawLines = lc.createSprite('recharge_jigsaw_lines')
        lc.addChildToCenter(jigsawBg, jigSawLines, 1)
        self._jigSawLines = jigSawLines

        local btn = V.createShaderButton("recharge_btn", function(sender) self:onClaimRecharge7Bonus() end) 
        lc.addChildToPos(layer, btn, cc.p(lc.cw(layer), 380))
        btn:setDisabledShader(V.SHADER_DISABLE)
        self._recharge7Btn = btn

        self:addDailyRechargeArea()
        
    else
        local bg = lc.createSprite("res/jpg/activity_first_recharge_02.jpg")
        lc.addChildToCenter(layer, bg)

        self:addDailyRechargeArea()

    end

    self:updateFirstRecharge()
end

function _M:addDailyRechargeArea()
    local layer = self._detailLayer
    self._daiyChargeBtns = {}
    for i = 1, 2 do
        local bonus = P._playerBonus._packageBonus[1303 + i]

        local icons = {}
        local info = bonus._info
        for i = 1, #info._rid do
            local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
            icon._name:setVisible(false)
            table.insert(icons, icon)
        end
        P:sortResultItems(icons)

        -- icons
        local sx, sy = -214, 170
        if i == 2 then
            sx, sy = 214, 170
        end

        for j = 1, #icons do
            local icon = icons[j]
            local pos = cc.p(lc.cw(layer) + sx + (lc.w(icon) + 8) * (j - (#icons + 1) / 2), sy)
            icon:setScale(0.9)
            lc.addChildToPos(layer, icon, pos)
        end

        local btn = V.createShaderButton("img_btn_recharge_1", function(sender) self:onBuy(Data.PurchaseType.daily_1 + i - 1) end) 
        lc.addChildToPos(layer, btn, cc.p(lc.cw(layer) + (i == 1 and -220 or 220), 54))
        btn:setDisabledShader(V.SHADER_DISABLE)
        btn:addLabel(Str(STR.BUY_NOW))
        self._daiyChargeBtns[i] = btn
    end
end

function _M:updateFirstRecharge()
    local status = self:getFirstRechargeStatus()
    if status == 0 then
        local btn = self._firstChargeBtn
        local bonus = P._playerBonus._packageBonus[1120]

        if not ClientData.isGemRecharged() then
            btn._label:setString(Str(STR.RECHARGE_NOW))
            btn._callback = function ()
                lc.pushScene(require("RechargeScene").create())
            end

        elseif bonus._value >= bonus._info._val and not bonus._isClaimed then
            btn._label:setString(Str(STR.CLAIM))
            btn._callback = function ()
                self:onClaimFirstRecharge()
            end

        else
            btn._label:setString(Str(STR.CLAIMED))
            btn:setEnabled(false)
            btn._callback = function () end
        end

    elseif status == 1 then
        local value = ClientData.getRecharge7BonusValue()
        if value >= 7 then
            local jigsawFg = lc.createSprite('recharge_jigsaw_fg')
            lc.addChildToCenter(self._jigsawBg, jigsawFg, 1)

            self._recharge7Btn:setEnabled(true)
            
            local bgLight = lc.createSprite('recharge_jigsaw_light')
            bgLight:setScale(9)
            bgLight:runAction(lc.rep(lc.sequence(lc.scaleTo(0.5, 8.5), lc.scaleTo(0.5, 9))))
            lc.addChildToCenter(self._jigsawBg, bgLight, -1)

            local btnLight = lc.createSprite('recharge_btn_light')
            btnLight:setScale(6)
            btnLight:runAction(lc.rep(lc.sequence(lc.scaleTo(0.5, 5.5), lc.scaleTo(0.5, 6))))
            lc.addChildToPos(self._recharge7Btn, btnLight, cc.p(lc.cw(self._recharge7Btn), lc.ch(self._recharge7Btn) + 4), -1)

        else
            for i = 1, value do
                local jigsawPart = lc.createSprite('recharge_jigsaw_0'..i)
                jigsawPart:setOpacity(0)
                jigsawPart:runAction(lc.fadeIn(2))
                lc.addChildToCenter(self._jigsawBg, jigsawPart)
            end

            self._recharge7Btn:setEnabled(false)
        end

        self:updateDailyRechargeArea()

    else
        self:updateDailyRechargeArea()

    end
end

function _M:updateDailyRechargeArea()
    local isRecharged = ClientData.isRecharged(Data.PurchaseType.daily_1) or ClientData.isRecharged(Data.PurchaseType.daily_2)
    for i = 1, 2 do
        if isRecharged then
            self._daiyChargeBtns[i]._label:setString(Str(STR.PURCHASED))
            self._daiyChargeBtns[i]:setEnabled(false)
        end
    end
end

-----------------------------------
-- package

function _M:initPackage()
    local layer = self._detailLayer

    local purchaseTypes = {
        Data.PurchaseType.package_1,
        Data.PurchaseType.package_2,
        Data.PurchaseType.package_3,
        Data.PurchaseType.package_4,
        Data.PurchaseType.package_5,
        Data.PurchaseType.package_6,
    }

    local list = lc.List.createH(layer:getContentSize())
    lc.addChildToCenter(layer, list)

    self._packageItems = {}
    for i = 1, #purchaseTypes do
        local purchaseType = purchaseTypes[i]
        local bonus = P._playerBonus._packageBonus[1121 + purchaseType - Data.PurchaseType.package_1]
        local price = Data._globalInfo._packageRmb[i]

        local widget, item = self:createPackageItem(purchaseType, bonus, price)
        list:pushBackCustomItem(widget)
        self._packageItems[i] = item
    end

    self:updatePackage()
end

function _M:updatePackage()
    for i = 1, #self._packageItems do
        local item = self._packageItems[i]
        local purchaseType = item._purchaseType
        local btn = item._btn

        local bonus = P._playerBonus._packageBonus[1121 + purchaseType - Data.PurchaseType.package_1]
        local info = bonus._info

        if i > 1 and not ClientData.isRecharged(purchaseType - 1) then
            item:setHide(true)

        else
            item:setHide(false)

            if ClientData.isRecharged(purchaseType) then
                btn._label:setString(Str(STR.PURCHASED))
                btn:setEnabled(false)
            end
        end
    end
end

function _M:createPackageItem(purchaseType, bonus, price)
    local widget = ccui.Layout:create()

    local item = lc.createSpriteWithMask("res/jpg/package_bg.jpg")
    widget:setContentSize(item:getContentSize())
    widget:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(widget, item)
    item._purchaseType = purchaseType

    local bones = DragonBones.create("lihe")
    lc.addChildToPos(item, bones, cc.p(lc.cw(item), lc.ch(item) + 150))
    bones:gotoAndPlay(string.format("effect%d", purchaseType))

    local title = lc.createSpriteWithMask(string.format("res/jpg/package_title_%d.jpg", purchaseType))
    lc.addChildToPos(item, title, cc.p(lc.cw(item), lc.h(item) - 20))
        
    local desc = lc.createSpriteWithMask(string.format("res/jpg/package_desc_%d.jpg", purchaseType))
    lc.addChildToPos(item, desc, cc.p(lc.cw(item), 200 + lc.ch(desc)))

    local once = lc.createSprite("img_recharge_once")
    lc.addChildToPos(item, once, cc.p(lc.cw(item) + 50, lc.ch(item) + 90))

    local label = lc.createSprite("img_recharge_once_tip")
    lc.addChildToPos(once, label, cc.p(lc.cw(once), lc.ch(once)))

    local unkown = lc.createSprite("img_unkown")
    lc.addChildToPos(item, unkown, cc.p(bones:getPosition()))

    -- bonus
    local info = bonus._info

    local icons = {}
    for i = 1, #info._rid do
        local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
        icon._name:setVisible(false)
        table.insert(icons, icon)
    end
    P:sortResultItems(icons)

    local scale = #icons == 2 and 0.8 or 0.7
    local margin = #icons == 2 and 14 or 2

    for i = 1, #icons do
        local icon = icons[i]
        local pos = cc.p(lc.cw(item) + (lc.w(icon) * scale + margin) * (i - (#icons + 1) / 2), 140)
        icon:setScale(scale)
        lc.addChildToPos(item, icon, pos)
    end

    -- btn
    local btn = V.createShaderButton("img_btn_recharge_2", function(sender) 
            self:onBuy(purchaseType)
        end) 
    lc.addChildToPos(item, btn, cc.p(lc.cw(item), 54))
    btn:setDisabledShader(V.SHADER_DISABLE)
    btn:addLabel((purchaseType ~= Data.PurchaseType.limit_2 and Str(STR.RMB) or '')..price)
    item._btn = btn

    if purchaseType == Data.PurchaseType.limit_2 then
        btn:addIcon('img_icon_res3_s')
        lc.offset(btn._icon, 50, 0)
    end

    --func
    item.setHide = function (self, isHide)
        unkown:setVisible(isHide)

        bones:setVisible(not isHide)
        title:setVisible(not isHide)
        desc:setVisible(not isHide)
        once:setVisible(not isHide)
        btn:setVisible(not isHide)
        for i = 1, #icons do
            icons[i]:setVisible(not isHide)
        end
    end

    return widget, item
end

-----------------------------------
-- month card

function _M:initMonthCard()
    local layer = self._detailLayer

    local hour, day, month, year = ClientData.getServerDate()

    local bg = lc.createSprite(string.format("res/jpg/activity_month_card_%d.jpg", month))
    lc.addChildToCenter(layer, bg)

    local purchaseTypes = {
        Data.PurchaseType.month_card_1,
        Data.PurchaseType.month_card_2,
    }

    for i = 1, #purchaseTypes do
        local purchaseType = purchaseTypes[i]
        local centerPos = cc.p(lc.cw(layer) + (i == 1 and -200 or 200), lc.ch(layer))

        --[[local item = lc.createSpriteWithMask(string.format("res/jpg/month_card_%d.jpg", i))
        local pos = cc.p(lc.cw(layer) + (lc.w(item) + margin) * (i - 1.5) - 4, lc.ch(layer) + 30)
        lc.addChildToPos(layer, item, pos)
        item._purchaseType = purchaseType
        self._monthCardItems[i] = item

        local tip = V.createBMFont(V.BMFont.huali_26, Str(STR.MONTH_CARD_BONES_TIP))
        lc.addChildToPos(item, tip, cc.p(lc.cw(tip) + 40, lc.h(item) - 150))

        local extra = V.createBMFont(V.BMFont.huali_26, Str(STR.MONTH_CARD_BONES_EXTAR))
        lc.addChildToPos(item, extra, cc.p(lc.cw(extra) + 40, lc.ch(item) - 16))
        extra:setColor(V.COLOR_TEXT_RED)

        -- REMAIN_DAYS
        local day = i == 1 and P._monthCardDay1 or P._monthCardDay2
        local remainDays = V.createBMFont(V.BMFont.huali_26, string.format(Str(STR.REMAIN_DAYS), day))
        remainDays:setScale(0.8)
        lc.addChildToPos(item, remainDays, cc.p(lc.w(item) - lc.cw(remainDays) - 20, lc.h(item) - 100))
        item._remainDays = remainDays]]

        -- bonus
        local value = P._playerBonus._bonusMonthCardBought[i]._value
        local bonus = (value == 1 or value == 2) and P._playerBonus._bonusMonthCardPackage[(i - 1) * 2 + value] or P._playerBonus._bonusMonthCard[i]
        local info = bonus._info

        local icons = {}
        for i = 1, #info._rid do
            local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
            icon._name:setVisible(false)
            icon:setScale(0.9)
            table.insert(icons, icon)
        end
        --P:sortResultItems(icons)

        for i = 1, #icons do
            local icon = icons[i]
            local pos = cc.p(centerPos.x + (lc.w(icon) + 6) * (i - (#icons + 1) / 2) + 12, centerPos.y - 100)
            lc.addChildToPos(layer, icon, pos)
        end

        -- label
        local label = V.createBMFont(V.BMFont.huali_26, (value == 1 or value == 2) and string.format(Str(STR.MONTHCARD_TIP2), value + 1) or Str(STR.MONTHCARD_TIP1))
        label:setScale(0.8)
        label:setAnchorPoint(0, 0.5)
        lc.addChildToPos(layer, label, cc.p(centerPos.x - 170, centerPos.y - 14))


        -- dirct bonus
        local startId = i == 1 and 9003 or 9015
        local _, _, month, _ = ClientData.getServerDate()
        local bonusInfo = Data._bonusInfo[startId + month - 1]

        local cardInfo = Data.getInfo(bonusInfo._rid[1])
        --[[local name = V.createBMFont(V.BMFont.huali_26, string.format("%s(%s)", Str(cardInfo._nameSid), Str(STR.NOT_BUYABLE)))
        name:setColor(V.COLOR_TEXT_GREEN)
        lc.addChildToPos(layer, name, cc.p(centerPos.x - 70, centerPos.y + 60))]]
         
        local shaderBtn = V.createShaderButton(nil, function () 
            require("CardInfoPanel").create(cardInfo._id, 1):show()
        end)
        shaderBtn:setContentSize(cc.size(350, 170))
        lc.addChildToPos(layer, shaderBtn, cc.p(centerPos.x, centerPos.y + 90))

        -- btn
        local btn = V.createShaderButton("img_btn_recharge_2", function(sender) self:onBuy(purchaseType) end) 
        lc.addChildToPos(layer, btn, cc.p(centerPos.x+ 10, 100))
        if P._playerBonus._bonusMonthCardBought[i]._value >= 3 then
            btn:setDisabledShader(V.SHADER_DISABLE)
            btn:setEnabled(false)
            btn:addLabel(Str(STR.PURCHASED)..string.format(Str(STR.CARD_AMOUNT), 3))
        else
            btn:addLabel(Str(STR.BUY_NOW))
        end
    end

    self:updateMonthCard()
end

function _M:updateMonthCard()
    --[[for i = 1, #self._monthCardItems do
        local item = self._monthCardItems[i]
        local purchaseType = item._purchaseType
        local remainDays = item._remainDays

        local day = i == 1 and P._monthCardDay1 or P._monthCardDay2
        remainDays:setString(string.format(Str(STR.REMAIN_DAYS), day))
        remainDays:setPositionX(lc.w(item) - lc.cw(remainDays) - 20)
    end]]
end

-----------------------------------
-- fund

function _M:initFund()
    local layer = self._detailLayer

    local bg = lc.createSprite("res/jpg/activity_fund.jpg")
    lc.addChildToPos(layer, bg, cc.p(lc.cw(bg) + 4, lc.ch(bg)), 10)
    local bgWidth = lc.w(bg)

    --[[local bg = lc.createSprite({_name = "img_com_bg_47", _crect = cc.rect(36, 40, 1, 1), _size = cc.size(bgWidth, lc.h(layer))})
    lc.addChildToPos(layer, bg, cc.p(lc.cw(bg), lc.ch(bg)))

    local glow = lc.createSprite("img_recharge_glow")
    lc.addChildToPos(bg, glow, cc.p(lc.cw(bg), lc.ch(bg) + 40))
    glow:setScale((lc.w(bg) - 40) / lc.w(glow), (lc.h(bg) - 40) / lc.h(glow))

    local label = lc.createSpriteWithMask("res/jpg/activity_label_3.jpg")
    lc.addChildToPos(bg, label, cc.p(lc.cw(bg), lc.h(bg) - lc.ch(label)))
    label:setScale(math.min(1.0, (bgWidth - 40) / lc.w(label)))

    local tipBg = lc.createSprite({_name = "img_com_bg_46", _crect = V.CRECT_COM_BG46, _size = cc.size(bgWidth - 30, 118)})
    lc.addChildToPos(bg, tipBg, cc.p(lc.cw(bg), 286))
    tipBg:setScale(1.0, 90 / lc.h(tipBg))

    local tip = lc.createSpriteWithMask("res/jpg/activity_label_5.jpg")
    lc.addChildToPos(bg, tip, cc.p(tipBg:getPosition()))
    tip:setScale(math.min(1.0, (bgWidth - 40) / lc.w(tip)))

    local bones = DragonBones.create("jijin")
    lc.addChildToPos(bg, bones, cc.p(lc.cw(bg), lc.ch(bg) + 84))
    bones:gotoAndPlay("effect11")
    
    local labelBg = lc.createSprite({_name = "img_com_bg_48", _crect = cc.rect(43, 58, 1, 1), _size = cc.size(lc.w(bg), 118)})
    lc.addChildToPos(bg, labelBg, cc.p(lc.cw(bg), 190))
    
    local label = lc.createSpriteWithMask("res/jpg/activity_label_4.jpg")
    lc.addChildToCenter(labelBg, label)
    
    ]]

    local btn = V.createShaderButton("img_btn_recharge_5", function(sender) self:onBuy(Data.PurchaseType.fund) end) 
    lc.addChildToPos(bg, btn, cc.p(lc.cw(bg), 50))
    btn:setDisabledShader(V.SHADER_DISABLE)
    btn:addLabel(Str(STR.BUY_NOW))
    self._fundBtn = btn

    -- list
    local list = lc.List.createV(cc.size(lc.w(layer) - lc.w(bg) - 8, lc.h(layer)), 16, 10)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(layer, list, cc.p(lc.w(layer) - lc.cw(list), lc.ch(list)))
    self._fundList = list

    --[[for i = 1, 10 do
        local layout = ccui.Layout:create()
        layout:setContentSize(cc.size(lc.w(list), 160))
        layout:setAnchorPoint(cc.p(0.5, 0.5))
        list:pushBackCustomItem(layout)

        local bonusBG = lc.createSprite{_name = "img_com_bg_33", _crect = V.CRECT_COM_BG33, _size = layout:getContentSize()}
        lc.addChildToCenter(layout, bonusBG)

        local deco = lc.createSprite('img_bg_deco_29')
        deco:setScale(lc.h(layout) / lc.h(deco))
        deco:setPosition(cc.p(lc.w(bonusBG) - lc.sw(deco) / 2, lc.h(layout) / 2))
        bonusBG:addChild(deco)

    end]]

    self:updateFund()
end

function _M:updateFund()
    -- btn
    local btn = self._fundBtn
    if not ClientData.isRecharged(Data.PurchaseType.fund) then
        btn._label:setString(Str(STR.BUY_NOW))
    else
        btn._label:setString(Str(STR.PURCHASED))
        btn:setEnabled(false)
    end

    -- update list
    local list = self._fundList
    local bonus = P._playerBonus._bonusFundLevel

    local bonuses, claimableBonuses, unclaimBonuses, claimedBonuses = {}, P._playerBonus.splitBonus(bonus)
    table.sort(claimableBonuses, function (a, b) return a._info._val < b._info._val end)
    table.sort(unclaimBonuses, function (a, b) return a._info._val < b._info._val end)
    table.sort(claimedBonuses, function (a, b) return a._info._val < b._info._val end)

    for _, bonus in ipairs(claimableBonuses) do table.insert(bonuses, bonus) end
    for _, bonus in ipairs(unclaimBonuses) do table.insert(bonuses, bonus) end
    for _, bonus in ipairs(claimedBonuses) do table.insert(bonuses, bonus) end

    list:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #bonuses))

    for i = 1, list._cacheCount do
        list:pushBackCustomItem(self:setOrCreateItem(nil, bonuses[i]))
    end
end

function _M:setOrCreateItem(item, data)
    local title = string.format(Str(data._info._nameSid), data._info._val)   

    if item == nil then
        item = require("BonusWidget").create(lc.w(self._fundList), data, title)
    else
        item:setBonus(data, title)
    end
    item:registerCallback(function(bonus) self:onClainFund(bonus) end)

    return item
end

-----------------------------------
-- feedback

function _M:initFeedBack()
    local layer = self._detailLayer

    -- feedback_bg
    local bg = lc.createSprite("res/jpg/activity_feedback.jpg")
    lc.addChildToCenter(layer, bg)

    -- bonus
    --[[
    local info = Data._bonusInfo[11078]

    local icons = {}
    for i = 1, #info._rid do
        local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
        icon._name:setVisible(false)
        table.insert(icons, icon)
    end
    P:sortResultItems(icons)

    for i = 1, #icons do
        local icon = icons[i]
        local pos = cc.p(lc.cw(layer) + (lc.w(icon) + 20) * (i - (#icons + 1) / 2) + 4, 160)
        lc.addChildToPos(layer, icon, pos)
    end
    ]]

    -- btn
    local btn = V.createScale9ShaderButton("img_btn_1", function(sender) 
        local InputForm = require("InputForm")
        InputForm.create(InputForm.Type.FEEDBACK):show()
    end, V.CRECT_BUTTON, 240) 
    lc.addChildToPos(layer, btn, cc.p(lc.cw(layer), 112))
    btn:setDisabledShader(V.SHADER_DISABLE)
    btn:addLabel(Str(STR.FEEDBACK))
end

-----------------------------------
-- invite

function _M:initInvite()
    local layer = self._detailLayer

    local panel = require("InvitePanel").create(layer:getContentSize())
    lc.addChildToCenter(layer, panel)
    self._invitePanel = panel
end

function _M:updateInvite()
    
end

--------------------------------------
-- limit small

function _M:initLimitSmall()
    local layer = self._detailLayer

    local purchaseTypes = {
        Data.PurchaseType.limit_1,
        Data.PurchaseType.limit_2,
    }

    local list = lc.List.createH(layer:getContentSize())
    lc.addChildToCenter(layer, list)

    self._packageItems = {}
    for i = 1, #purchaseTypes do
        local purchaseType = purchaseTypes[i]
        local bonus = P._playerBonus._limitBonus[1401 + purchaseType - Data.PurchaseType.limit_1]
        local price = i == 1 and 30 or 520

        local widget, item = self:createPackageItem(purchaseType, bonus, price)
        list:pushBackCustomItem(widget)
        self._packageItems[i] = item
    end

    self:updateLimitSmall()
end

function _M:updateLimitSmall()
    for i = 1, #self._packageItems do
        local item = self._packageItems[i]
        local purchaseType = item._purchaseType
        local btn = item._btn

        local bonus = P._playerBonus._limitBonus[1401 + purchaseType - Data.PurchaseType.limit_1]

        item:setHide(false)

        if ClientData.isRecharged(purchaseType) then
            btn._label:setString(Str(STR.PURCHASED))
            if btn._icon then btn._icon:setVisible(false) end
            btn._label:setPositionX(lc.cw(btn))
            btn:setEnabled(false)
        end
    end
end

--------------------------------------
-- limit large

function _M:initLimitLarge(tabIndex)
    local purchaseType = Data.PurchaseType.limit_1 + tabIndex - _M.Tab.limit_large_01

    local btns = _M.createLimitLarge(purchaseType, self._detailLayer, true)
    if btns == nil then return end

    for i = 1, #btns do
        if purchaseType == Data.PurchaseType.limit_1 or purchaseType == Data.PurchaseType.limit_2 then
            btns[i]._callback = function(sender)
                self:onBuy(purchaseType + i - 1)
            end

            if ClientData.isRecharged(purchaseType + i - 1) then
                btns[i]._label:setString(Str(STR.PURCHASED))
                btns[i]:setEnabled(false)
            end
        else
            btns[i]._callback = function(sender)
                if purchaseType == Data.PurchaseType.limit_3 then V.tryGotoFindLadder(false)
                elseif purchaseType == Data.PurchaseType.limit_4 then V.tryGotoFindClash(false)
                --elseif purchaseType == Data.PurchaseType.limit_5 then local TavernScene = require("TavernScene") lc.replaceScene(TavernScene.create(nil, TavernScene.TAB.rare_draw_card))
                end
            end
        end  
    end
end

function _M.createLimitLarge(purchaseType, layer, showBtn) 
    -- feedback_bg
    local bg = lc.createSprite("res/jpg/activity_limit_large_0"..(purchaseType - Data.PurchaseType.limit_1 + 1)..".jpg")
    lc.addChildToCenter(layer, bg)
    layer._bg = bg

    local btns = {}

    --if purchaseType == Data.PurchaseType.limit_3 or purchaseType == Data.PurchaseType.limit_4 then
    if purchaseType == Data.PurchaseType.limit_3 then
        -- time label
        local activityInfo = ClientData.getActivityByParam(purchaseType)
        local timeStr = ClientData.getActivityDurationStr(activityInfo)
        local timeLabel = V.createBMFont(V.BMFont.huali_26, timeStr)
        local poses = {cc.p(790, 360), cc.p(854, 360), cc.p(790, 360)}
        lc.addChildToPos(bg, timeLabel, poses[purchaseType - Data.PurchaseType.limit_3 + 1])

        -- btn
        if showBtn then
            local poses = {cc.p(564, 70), cc.p(564, 110), cc.p(564, 70)}
            local btn = V.createShaderButton("img_btn_recharge_1", function(sender) end)
            lc.addChildToPos(bg, btn, poses[purchaseType - Data.PurchaseType.limit_3 + 1])
            btn:addLabel(Str(STR.GO))
            btns[1] = btn
        end
    end

    if purchaseType == Data.PurchaseType.limit_4 then
        local icons = {}
        local pids = Data._dropInfo[69]._pid
        for i = 1, 10 do
            local icon = IconWidget.create{_infoId = pids[i][1]}
            icon._name:setVisible(false)
            table.insert(icons, icon)
        end
        P:sortResultItems(icons)

        -- icons
        local sx, sy = 166, 300
        for j = 1, 2 do
            for k = 1, 5 do
                local icon = icons[(j - 1) * 5 + k]
                local pos = cc.p(lc.cw(layer) + sx + (lc.w(icon) + 0) * (k - (5 + 1) / 2), sy - j * 110)
                icon:setScale(0.9)
                lc.addChildToPos(layer, icon, pos)
            end
        end

        return
    end

    if purchaseType >= Data.PurchaseType.limit_3 then return btns end
    
    for i = 1, 1 do
        local bonus = P._playerBonus._limitBonus[1400 + purchaseType - Data.PurchaseType.limit_1 + i]

        local icons = {}
        local info = bonus._info
        for i = 1, #info._rid do
            local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
            icon._name:setVisible(false)
            table.insert(icons, icon)
        end
        P:sortResultItems(icons)

        -- icons
        local sx, sy = -130, 236
        if purchaseType == Data.PurchaseType.limit_2 or i == 2 then
            sx, sy = -154, 240
        end

        for j = 1, #icons do
            local icon = icons[j]
            local pos = cc.p(lc.cw(layer) + sx + (lc.w(icon) + 10) * (j - (#icons + 1) / 2), sy)
            icon:setScale(0.9)
            lc.addChildToPos(layer, icon, pos)
        end

        -- btn
        if showBtn then
            local btn = V.createShaderButton("img_btn_recharge_1", function(sender) end)
            local bx, by = 436, 106
            if purchaseType == Data.PurchaseType.limit_2 or i == 2 then
                bx, by = 410, 96
            end
            lc.addChildToPos(bg, btn, cc.p(bx, by))
            btn:setDisabledShader(V.SHADER_DISABLE)
            btn:addLabel(Str(STR.BUY_NOW))
        
            btns[i] = btn
        end
    end

    return btns
end

-----------------------------------------------------------------
-- charge, package, return package

function _M:initReturnPackage()
    local btn = _M.createReturnPackage(self._detailLayer, true)

    btn._callback = function(sender) 
        self:onClaimReturnPackage()
    end

    if ClientData.isReturnToGameClaimed() then
        btn._label:setString(Str(STR.CLAIMED))
        btn:setEnabled(false)
    end
end

function _M.createReturnPackage(layer, showBtn) 
    local bg = lc.createSprite("res/jpg/activity_return.jpg")
    lc.addChildToCenter(layer, bg)
    layer._bg = bg

    local bonus = P._playerBonus._returnBonus

    local icons = {}
    local info = bonus._info
    for i = 1, #info._rid do
        local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
        icon._name:setVisible(false)
        table.insert(icons, icon)
    end
    P:sortResultItems(icons)

    -- icons
    local sx, sy = -122, 374
    for j = 1, 2 do
        for k = 1, 3 do
            local icon = icons[(j - 1) * 3 + k]
            if icon ~= nil then
                local pos = cc.p(lc.cw(layer) + sx + (lc.w(icon) + 20) * (k - (3 + 1) / 2), sy - j * 110)
                icon:setScale(0.9)
                lc.addChildToPos(layer, icon, pos)
            end
        end
    end

    -- btn
    local btn = V.createShaderButton("img_btn_recharge_1", function(sender) end)
    local bx, by = 436, 56
    lc.addChildToPos(bg, btn, cc.p(bx, by))
    btn:setDisabledShader(V.SHADER_DISABLE)
    btn:addLabel(Str(STR.CLAIM))
    btn:setVisible(showBtn)

    return btn
end

function _M.createAdRecharge(layer) 
    local bg = lc.createSprite("res/jpg/activity_recharge.jpg")
    lc.addChildToCenter(layer, bg)
    layer._bg = bg

    local bonus = P._playerBonus._packageBonus[1120]

    local icons = {}
    local info = bonus._info
    for i = 1, #info._rid do
        local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
        icon._name:setVisible(false)
        table.insert(icons, icon)
    end
    P:sortResultItems(icons)

    -- icons
    local sx, sy = -122, 256
    for j = 1, #icons do
        local icon = icons[j]
        local pos = cc.p(lc.cw(layer) + sx + (lc.w(icon) + 10) * (j - (#icons + 1) / 2), sy)
        icon:setScale(0.9)
        lc.addChildToPos(layer, icon, pos)
    end
end

function _M.createAdPackage(layer) 
    local bg = lc.createSprite("res/jpg/activity_package.jpg")
    lc.addChildToCenter(layer, bg)
    layer._bg = bg

    local bonus = P._playerBonus._packageBonus[1121]

    local icons = {}
    local info = bonus._info
    for i = 1, #info._rid do
        local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
        icon._name:setVisible(false)
        table.insert(icons, icon)
    end
    P:sortResultItems(icons)

    -- icons
    local sx, sy = -128, 228
    for j = 1, #icons do
        local icon = icons[j]
        local pos = cc.p(lc.cw(layer) + sx + (lc.w(icon) + 10) * (j - (#icons + 1) / 2), sy)
        icon:setScale(0.9)
        lc.addChildToPos(layer, icon, pos)
    end
end

-----------------------------------------------------------------
-- msg

function _M:onClaimFirstRecharge()
    local bonus = P._playerBonus._packageBonus[1120]
    if bonus._value >= bonus._info._val then
        local result = ClientData.claimBonus(bonus)
        V.showClaimBonusResult(bonus, result)
        self:updateAll()
    end
end

function _M:onClaimRecharge7Bonus()
    local bonus = P._playerBonus._packageBonus[1306]
    if bonus._value >= bonus._info._val then
        local result = ClientData.claimBonus(bonus)
        V.showClaimBonusResult(bonus, result)
        self:updateAll()
    end
end

function _M:onClaimReturnPackage()
    local bonus = P._playerBonus._returnBonus
    if bonus._value >= bonus._info._val then
        local result = ClientData.claimBonus(bonus)
        V.showClaimBonusResult(bonus, result)
        self:updateAll()
    end
end

function _M:onClainFund(bonus)
    if bonus._value >= bonus._info._val then
        if not bonus._isClaimed then
            local result = ClientData.claimBonus(bonus)
            self:updateAll()
            V.showClaimBonusResult(bonus, result)
        end
    end
end

function _M:onBuy(type)
    --[[
    if type == Data.PurchaseType.limit_2 then
        local grade = 6000
        local result = ClientData._player:buyGold(grade)
        if result == Data.ErrorType.ok then
            P:changeResource(Data.ResType.gold, -grade)
            ClientData.sendBuyGold(grade)

            local bonus = P._playerBonus._limitBonus[type - Data.PurchaseType.limit_1 + 1401]
            local RewardPanel = require("RewardPanel")
            local data = {}
            for i = 1, #bonus._info._rid do
                data[#data + 1] = {info_id = bonus._info._rid[i], num = bonus._info._count[i]}
            end
            RewardPanel.create(data, RewardPanel.MODE_BUY):show()
            
            ClientData.setRecharged(type)
            bonus._isClaimed = true
            P:sendPackageDirty()
            
        elseif result == Data.ErrorType.need_more_ingot then
            if ClientData.isHideCharge() then
                ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._resInfo[Data.ResType.ingot]._nameSid)))
            else
                require("PromptForm").ConfirmBuyIngot.create():show()
            end

        elseif result == Data.ErrorType.need_more_gold then
            ToastManager.push(Str(STR.NOT_ENOUGH_GOLD))
            require("ExchangeResForm").create(Data.ResType.gold):show()

        end  
        return
    end
    ]]

    V.startIAP(type)   
end

function _M:getFirstRechargeStatus()
    if (not ClientData.isGemRecharged()) or P._playerBonus:getFirstRechargeFlag() > 0 then return 0
    elseif not ClientData.isRecharge7BonusClaimed() then return 1
    else return 2
    end
end

function _M:updateAll()
    self:updateTabs()
    self:updateButtonFlags()
end

function _M:updateButtonFlags()
    local tabs = self._tabArea._list:getItems()

    local tab = self:getTabByType(_M.Tab.first_recharge)
    if tab then
        local status = self:getFirstRechargeStatus()
        if status == 0 then V.checkNewFlag(tab, P._playerBonus:getFirstRechargeFlag(), -10, -10) 
        elseif status == 1 then V.checkNewFlag(tab, P._playerBonus:getRecharge7Flag(), -10, -10) 
        end
    end

    local tab = self:getTabByType(_M.Tab.fund)
    if tab then V.checkNewFlag(tab, P._playerBonus:getFundBonusFlag(), -10, -10) end

    local tab = self:getTabByType(_M.Tab.invite)
    if tab then V.checkNewFlag(tab, P._playerBonus:getInviteBonusFlag(), -10, -10) end

    local tab = self:getTabByType(_M.Tab.return_to_game)
    if tab then V.checkNewFlag(tab, P._playerBonus:getReturnPackageFlag(), -10, -10) end
end

function _M:getTabByType(tabType)
    local tabs = self._tabArea._list:getItems()

    for i = 1, #tabs do
        local tab = tabs[i]
        if tab._index == tabType then
            return tab
        end
    end

    return nil
end

function _M:onEvent(event, eventType)
    if eventType == Data.Event.fund_dirty or eventType == Data.Event.month_card_dirty or eventType == Data.Event.package_dirty then
        self:updateAll()

    elseif eventType == Data.Event.bonus_dirty then
        local bonus = event._data
        if bonus and bonus._info._type == Data.BonusType.fund_all then
            self:updateAll()
        end
    end
end

return _M