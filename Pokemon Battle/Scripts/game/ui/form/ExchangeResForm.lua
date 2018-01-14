local _M = class("ExchangeResForm", BaseForm)

local FORM_SIZE = cc.size(700, 520)
local EXCHANGE_AREA_SIZE = cc.size(580, 300)

function _M.create(resType)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(resType)
    
    V._resExchangeForms[resType] = panel

    return panel
end

function _M:init(resType)
    if resType ~= Data.ResType.gold and resType ~= Data.ResType.grain 
        and resType ~= Data.PropsId.dust_monster and resType ~= Data.PropsId.dust_magic and resType ~= Data.PropsId.dust_rare 
        and resType ~= Data.PropsId.dimension_bottle and resType ~= Data.PropsId.skin_crystal and resType ~= Data.PropsId.times_package_ticket then return end

    self._resType = resType
    local formSize = cc.size(FORM_SIZE.width, FORM_SIZE.height)
    local exchangeSize = cc.size(EXCHANGE_AREA_SIZE.width, EXCHANGE_AREA_SIZE.height)
    if resType == Data.ResType.grain then 
        formSize.height = formSize.height - 200 
        exchangeSize.height = exchangeSize.height - 200 
    end
    _M.super.init(self, formSize, nil, 0)
    
    self._isShowResourceUI = true

    local player, form = ClientData._player, self._form

    -- info
    local icon = IconWidget.create({_infoId = resType}, 0)
    --icon:setTouchEnabled(false)
    lc.addChildToPos(form, icon, cc.p(120, formSize.height - _M.FRAME_THICK_TOP - 30 - lc.h(icon) / 2), 1)
    self._icon = icon
    
    local name = V.createTTF(ClientData.getNameByInfoId(resType), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
    local nameBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(320, 40)}
    nameBg:setColor(lc.Color3B.black)
    nameBg:setOpacity(100)
    lc.addChildToPos(nameBg, name, cc.p(30 + lc.w(name) / 2, lc.h(nameBg) / 2 - 1))
    lc.addChildToPos(form, nameBg, cc.p(lc.right(icon) - 10 + lc.w(nameBg) / 2, lc.top(icon) - lc.h(nameBg) / 2 - 10))

    self:updateBuyTimes()

    local exchangeBg = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = exchangeSize}
    lc.addChildToPos(form, exchangeBg, cc.p(lc.w(form) / 2, lc.bottom(icon) - 10 - lc.h(exchangeBg) / 2))
    
    local addResIconVal = function(resType, ax, y)
        local icon = lc.createSprite(string.format(resType < 7000 and "img_icon_res%d_s" or "img_icon_props_s%d", resType))
        icon:setAnchorPoint(ax, 0.5)
        lc.addChildToPos(exchangeBg, icon, cc.p(0, y))

        local val = V.createBMFont(V.BMFont.huali_32, "")
        val:setAnchorPoint(ax, 0.5)
        lc.addChildToPos(exchangeBg, val, cc.p(0, y))

        return icon, val
    end

    self._line = resType == Data.ResType.grain and 1 or 3
    self._arrows = {}
    local y = exchangeSize.height / 2 + (resType == Data.ResType.grain and 0 or 90)
    for i = 1, self._line do
        local arrow = lc.createSprite("img_arrow_right")
        arrow:setColor(V.COLOR_TEXT_GREEN)
        lc.addChildToPos(exchangeBg, arrow, cc.p(exchangeSize.width / 2 - 106, y))
        y = y - 90
        self._arrows[i] = arrow
    end

    self._ingotIcons, self._ingotVals, self._resIcons, self._resVals = {}, {}, {}, {}
    for i = 1, self._line do
        self._ingotIcons[i], self._ingotVals[i] = addResIconVal(Data.ResType.ingot, 0, lc.y(self._arrows[i]))
        self._resIcons[i], self._resVals[i] = addResIconVal(resType, 0, lc.y(self._arrows[i]))

        local btnOk = V.createScale9ShaderButton("img_btn_1_s", function() self:exchange(i) end, V.CRECT_BUTTON_S, 150)
        btnOk:addLabel(Str(STR.EXCHANGE))
        lc.addChildToPos(exchangeBg, btnOk, cc.p(lc.x(self._arrows[i]) + 290, lc.y(self._arrows[i]) - 2))
    end
    
    self:updateExchange()
end

function _M:exchange(grade)
    local result = Data.ErrorType.ok 
    if self._resType == Data.ResType.gold then
        result = ClientData._player:buyGold(grade)
    elseif self._resType == Data.ResType.grain then
        result = ClientData._player:buyGrain()
    else
        result = ClientData._player:buyDust(self._resType, grade)
    end

    if result == Data.ErrorType.ok then
        self:updateExchange()
        V.showResChangeText(self, self._resType, tonumber(self._resVals[grade]:getString()))

        if self._resType == Data.ResType.gold then
            ClientData.sendBuyGold(grade)
        elseif self._resType == Data.ResType.grain then
            ClientData.sendBuyGrain()
        else
            ClientData.sendBuyDust(self._resType, grade)
        end

    elseif result == Data.ErrorType.need_more_ingot then
        if ClientData.isHideCharge() then
            ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._resInfo[Data.ResType.ingot]._nameSid)))
        else
            require("PromptForm").ConfirmBuyIngot.create():show()
        end

    elseif result == Data.ErrorType.need_more_daily_buy_gold or result == Data.ErrorType.need_more_daily_buy_grain then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH_BUY_TIMES), Str(STR.BUY)..ClientData.getNameByInfoId(self._resType)))
    end  
end

function _M:updateExchange()
    for i = 1, self._line do
        local ingot, value
        if self._resType == Data.ResType.gold then
            ingot, value = ClientData._player:getExchangeGold(i)
        elseif self._resType == Data.ResType.grain then
            ingot, value = ClientData._player:getExchangeGrain()
        else
            ingot, value = ClientData._player:getExchangeDust(self._resType, i)
        end

        self._ingotVals[i]:setString(tostring(ingot))
        self._ingotIcons[i]:setPositionX(lc.left(self._arrows[i]) - 132)
        self._ingotVals[i]:setPositionX(lc.right(self._ingotIcons[i]) + 6)
        

        self._ingotVals[i]:setColor(ingot > ClientData._player._ingot and lc.Color3B.red or lc.Color3B.white)
    
        self._resVals[i]:setString(tostring(value))
        self._resIcons[i]:setPositionX(lc.right(self._arrows[i]) + 20)
        self._resVals[i]:setPositionX(lc.right(self._resIcons[i]) + 6)
    end

    self:updateBuyTimes()
end

function _M:updateBuyTimes()
    if self._resType ~= Data.ResType.grain then return end

    if self._buyTimes then
        self._buyTimes:removeFromParent()
    end

    local player, remainTimes, totalTimes = ClientData._player
    if self._resType == Data.ResType.gold then
        remainTimes = player:getBuyGoldTimes()
        totalTimes = remainTimes + player._dailyBuyGold
    else
        remainTimes = ClientData._player:getBuyGrainTimes()
        totalTimes = remainTimes + player._dailyBuyGrain
    end

    local times = string.format(Str(STR.DAILY_EXCHANGE_TIMES), remainTimes, totalTimes)

    local buyTimes = V.createBoldRichText(times, {_normalClr = V.COLOR_TEXT_LIGHT, _boldClr = V.COLOR_TEXT_GREEN_DARK, _fontSize = V.FontSize.S1})
    lc.addChildToPos(self._form, buyTimes, cc.p(lc.right(self._icon) + 20 + lc.w(buyTimes) / 2, lc.bottom(self._icon) + lc.h(buyTimes) / 2 + 10))
    self._buyTimes = buyTimes
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.vip_dirty, function() self:updateBuyTimes() end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.ingot_dirty, function() self:updateExchange() end))
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)
    
    V._resExchangeForms[self._resType] = nil
end

return _M