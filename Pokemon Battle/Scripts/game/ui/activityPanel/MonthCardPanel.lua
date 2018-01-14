local _M = class("MonthCardPanel", lc.ExtendUIWidget)

local ITEM_AREA_SIZE = cc.size(418, 344) 

function _M.create(bgName, size)
    local panel = _M.new(lc.EXTEND_LAYOUT)
    panel:setContentSize(size)
    panel:setAnchorPoint(0.5, 0.5)
    panel:init(bgName)
    return panel
end

function _M:init(bgName)
    --local titleBg = lc.createSprite('res/jpg/activity_top.jpg')
    --lc.addChildToPos(self, titleBg, cc.p(lc.w(self) / 2, lc.h(self) - lc.h(titleBg) / 2))

    local title = V.createCheckinTitle(Str(STR.MONTH_CARD_CHECKIN_TITLE), 0)
    lc.addChildToPos(self, title, cc.p(lc.w(self) / 2 + 140, lc.h(self) - lc.h(title) / 2 - 24))

    local tip = V.createTTF(Str(STR.MONTH_CARD_CHECKIN_TIP), V.FontSize.S1, V.COLOR_TEXT_DARK)    
    lc.addChildToPos(self, tip, cc.p(lc.x(title), lc.bottom(title) - lc.h(tip) / 2 - 12))

    local bonusBG = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = cc.size(lc.w(self) - 20, 390)}
    lc.addChildToPos(self, bonusBG, cc.p(lc.w(self) / 2, lc.h(bonusBG) / 2))

    self._areas = {}
    local area = self:createItemArea(1)
    lc.addChildToPos(self, area, cc.p(38 + ITEM_AREA_SIZE.width / 2, lc.y(bonusBG)))
    table.insert(self._areas, area)

    area = self:createItemArea(2)
    lc.addChildToPos(self, area, cc.p(lc.w(self) - 38 - ITEM_AREA_SIZE.width / 2, lc.y(bonusBG)))
    table.insert(self._areas, area)
end

function _M:createItemArea(index)
    local area = lc.createSprite{_name = "activity_bonus_bg2", _crect = cc.rect(30, 30, 8, 4), _size = ITEM_AREA_SIZE}

    local bonus = P._playerBonus._bonusMonthCard[index]
    area._bonus = bonus

    local info, items = bonus._info, {}
    for i = 1, #info._rid do
        local item = IconWidget.createByBonus(info, i)
        item._name:setColor(lc.Color3B.white)
        table.insert(items, item)
    end

    lc.addNodesToCenterH(area, {items[1], items[2], items[3]}, 30, ITEM_AREA_SIZE.height - 150)

    --[[local offTip = lc.createSprite(string.format("activity_m%d_off", index))
    lc.addNodesToCenterH(area, {offTip}, 2, lc.bottom(items[1]) - 70)]]

    local btnClaim = V.createScale9ShaderButton("img_btn_1", function()
        if bonus._value >= bonus._info._val then
            local result = ClientData.claimBonus(bonus)
            V.showClaimBonusResult(bonus, result)
        else
            ToastManager.push(Str(STR.MONTH_CARD_NO_DAYS))
        end
    end, V.CRECT_BUTTON, 180)
    btnClaim:addLabel(Str(STR.CLAIM))
    lc.addChildToPos(area, btnClaim, cc.p(lc.cw(area), 20 + lc.h(btnClaim) / 2))
    area._btnClaim = btnClaim

    local claimedFlag = V.createStatusLabel(Str(STR.CLAIMED), V.COLOR_TEXT_GREEN)
    lc.addChildToPos(area, claimedFlag, cc.p(btnClaim:getPosition()))
    area._claimedFlag = claimedFlag

    local icon = lc.createSprite(string.format("activity_icon_%d", 100 + index))
    lc.addChildToPos(area, icon, cc.p(lc.cw(area) - 70, lc.h(area) - 40))

    local label = V.createTTF("", V.FontSize.S1)
    label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(area, label, cc.p(lc.right(icon) + 6, lc.y(icon)))
    area._label = label
  
    local btnBuy = V.createScale9ShaderButton("img_btn_3", function()
        --require("FundForm").create(true):show(true)
        lc.pushScene(require("ActivityScene").create(require("ActivityScene").Tab.month_card))
    end, V.CRECT_BUTTON, 180)
    btnBuy:addLabel(Str(STR.BUY_MONTH_CARD))
    lc.addChildToPos(area, btnBuy, cc.p(btnClaim:getPosition()))
    area._btnBuy = btnBuy

    area._index = index
    return area
end

function _M:updateAreaView(area)
    local index, bonus = area._index, area._bonus
    local remain = (index == 1 and P._monthCardDay1 or P._monthCardDay2)

    area._btnClaim:setVisible(remain > 0 and not bonus._isClaimed)
    area._claimedFlag:setVisible(remain > 0 and bonus._isClaimed)
    area._btnBuy:setVisible(remain <= 0)

    if remain > 0 then
        area._label:setString(string.format(Str(STR.REMAIN_DAYS), remain))
        area._label:setColor(V.COLOR_TEXT_GREEN)
    else
        area._label:setString(string.format(Str(STR[string.format("MONTH_CARD%d", index)])))
        area._label:setColor(V.COLOR_TEXT_ORANGE)
    end
end

function _M:onEnter()
    self._listener = lc.addEventListener(Data.Event.bonus_dirty, function(event)
        for _, area in ipairs(self._areas) do
            if event._data == area._bonus then
                self:updateAreaView(area)
                break
            end
        end
    end)

    for _, area in ipairs(self._areas) do
        self:updateAreaView(area)
    end
end

function _M:onExit()
    lc.Dispatcher:removeEventListener(self._listener)
end

return _M