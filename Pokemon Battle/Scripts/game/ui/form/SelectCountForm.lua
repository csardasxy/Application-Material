local _M = class("SelectCountForm", require("BaseForm"))

local FORM_SIZE = cc.size(640, 420)

function _M.create(data)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)    
    panel:init(data)
    return panel    
end

function _M:init(data)
    self._data = data

    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))
    local form = self._form

    self._isShowResourceUI = true

    -- info
    local icon = IconWidget.create(data, IconWidget.DisplayFlag.COUNT)
    icon:setTouchEnabled(false)
    lc.addChildToPos(form, icon, cc.p(120, FORM_SIZE.height - _M.FRAME_THICK_TOP - 30 - lc.h(icon) / 2))
    self._icon = icon
    
    local name = V.createTTF(ClientData.getNameByInfoId(data._infoId), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
    local nameBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(320, 40)}
    nameBg:setColor(lc.Color3B.black)
    nameBg:setOpacity(100)
    lc.addChildToPos(nameBg, name, cc.p(30 + lc.w(name) / 2, lc.h(nameBg) / 2 - 1))
    lc.addChildToPos(form, nameBg, cc.p(lc.right(icon) - 10 + lc.w(nameBg) / 2, lc.top(icon) - lc.h(nameBg) / 2 - 10))

    local ownCount = P:getItemCount(data._infoId)
    if ownCount >= 0 then
        local label = (Data.isUnionRes(data._infoId) and Str(STR.UNION_OWN) or Str(STR.CURRENT_OWN))
        local have = V.createTTF(string.format("(%s: %s)", label, ClientData.formatNum(ownCount, 9999)), V.FontSize.S1, V.COLOR_LABEL_LIGHT)
        lc.addChildToPos(form, have, cc.p(lc.w(form) - lc.w(have) / 2 - 60, lc.y(nameBg)))
    end

    self:updateBuyTimes()

    -- count manipulate
    local widget = require("SelectCountWidget").create(function(count) self:updateBuyPrice(count) end, 140, P._playerMarket:getBuyGoodsNumber(self._data._infoId))
    self._countWidget = widget
    lc.addChildToPos(form, widget, cc.p(lc.w(form) / 2, lc.bottom(icon) - 30 - widget.HEIGHT / 2))
    
    -- buttons
    local btnCancel = V.createScale9ShaderButton("img_btn_2", function() self:hide() end, V.CRECT_BUTTON, 150)
    btnCancel:addLabel(Str(STR.CANCEL))
    lc.addChildToPos(form, btnCancel, cc.p(lc.w(form) / 2 - lc.w(btnCancel) / 2 - 20, 80))

    local btnOk = V.createResConsumeButtonArea(150, string.format("img_icon_res%d_s", data._resType), V.COLOR_RES_LABEL_BG_LIGHT, "0", Str(STR.BUY))
    btnOk._btn._callback = function() self:buy() end
    lc.addChildToPos(form, btnOk, cc.p(lc.w(form) / 2 + lc.w(btnOk) / 2 + 20, lc.bottom(btnCancel) + lc.h(btnOk) / 2))
    self._price = btnOk._resLabel
    self:updateBuyPrice() 
end

function _M:buy()
    local count = self._countWidget:getCount()
    local result = P._playerMarket:buyGoods(self._data, count)
    if result == Data.ErrorType.ok then
        ClientData.sendBuyGoods(self._data._id, count)
        ToastManager.push(Str(STR.BUYSUCCESS))
        self:hide()

    elseif result == Data.ErrorType.need_more_ingot then
        require("PromptForm").ConfirmBuyIngot.create():show()

    elseif result == Data.ErrorType.need_more_gold then
        ToastManager.push(Str(STR.NOT_ENOUGH_GOLD))
        require("ExchangeResForm").create(Data.ResType.gold):show()

    elseif result == Data.ErrorType.need_more_grain then
        ToastManager.push(Str(STR.NOT_ENOUGH_GRAIN))        
        require("ExchangeResForm").create(Data.ResType.grain):show()
    end
end

function _M:updateBuyTimes()
    if self._buyTimes then
        self._buyTimes:removeFromParent()
    end

    local market = P._playerMarket
    local remainTimes, totalTimes = market:getBuyGoodsNumber(self._data._infoId), market:getBuyGoodsNumber(self._data._infoId, true)
    local times = string.format(Str(STR.DAILY_BUY_TIMES), remainTimes, totalTimes)

    local buyTimes = V.createBoldRichText(times, {_normalClr = V.COLOR_TEXT_LIGHT, _boldClr = V.COLOR_TEXT_GREEN_DARK, _fontSize = V.FontSize.S1})
    lc.addChildToPos(self._form, buyTimes, cc.p(lc.right(self._icon) + 20 + lc.w(buyTimes) / 2, lc.bottom(self._icon) + lc.h(buyTimes) / 2))
    self._buyTimes = buyTimes
end

function _M:updateBuyPrice(count)
    count = count or 1

    local price = self._data._cost * count
    self._price:setString(tostring(price))

    local resType, player = self._data._resType, P
    local resHave = (resType == Data.ResType.gold and player._gold or player._ingot)
    self._price:setColor(price > resHave and lc.Color3B.red or lc.Color3B.white)
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.vip_dirty, function() self:updateBuyTimes() end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.ingot_dirty, function() self:updateBuyPrice() end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.gold_dirty, function() self:updateBuyPrice() end))
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

return _M