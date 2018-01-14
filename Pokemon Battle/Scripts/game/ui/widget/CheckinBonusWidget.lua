local _M = class("CheckinBonusWidget", lc.ExtendUIWidget)

local ITEM_SIZE = cc.size(850, 152)
local TAG_ITEM = 1000

function _M.create(label, bonus)
    local item = _M.new(lc.EXTEND_LAYOUT)
    item:setContentSize(ITEM_SIZE)
    item:init(label, bonus)
    return item
end

function _M:init(label, bonus)
    self._label = label
    self._bonus = bonus
    
    local bonusBG = lc.createSprite{_name = "img_com_bg_33", _crect = V.CRECT_COM_BG33, _size = ITEM_SIZE}
    lc.addChildToCenter(self, bonusBG)

    local bar = lc.createSprite('img_bg_deco_33')
    bar:setColor(cc.c3b(72, 134, 232))
    lc.addChildToPos(bonusBG, bar, cc.p(lc.w(bar) / 2, lc.h(bonusBG) / 2 + 4))

    local deco = lc.createSprite('img_bg_deco_29')
    deco:setScale(lc.h(self) / lc.h(deco))
    deco:setPosition(cc.p(lc.w(bonusBG) - lc.sw(deco) / 2, lc.h(self) / 2))
    bonusBG:addChild(deco)

    --local dateBG = lc.createSprite("activity4_date_bg")
    --lc.addChildToPos(self, dateBG, cc.p(lc.w(dateBG) / 2 + 12, ITEM_SIZE.height / 2))
    
    local dateLabel = V.createBMFont(V.BMFont.huali_32, label)
    --dateLabel:setColor(lc.Color3B.yellow)
    lc.addChildToPos(self, dateLabel, cc.p(lc.w(dateLabel) / 2 + 34, ITEM_SIZE.height / 2))
    --lc.addChildToCenter(dateBG, dateLabel)
    self._dateLabel = dateLabel

    local btnClaim = V.createScale9ShaderButton("img_btn_1_s", function(sender)
        if self._claimHandler then
            self._claimHandler(self._bonus)
        end
    end, V.CRECT_BUTTON_1_S, 140)
    btnClaim:addLabel(Str(STR.CLAIM))
    btnClaim:setDisabledShader(V.SHADER_DISABLE)
    lc.addChildToPos(self, btnClaim, cc.p(ITEM_SIZE.width - 90, ITEM_SIZE.height / 2))
    self._btnClaim = btnClaim

    local claimedFlag = V.createStatusLabel(Str(STR.CLAIMED), V.COLOR_TEXT_GREEN)
    lc.addChildToPos(self, claimedFlag, cc.p(ITEM_SIZE.width - 90, ITEM_SIZE.height / 2))
    self._claimedFlag = claimedFlag

    local info = bonus._info
    if info._type == Data.BonusType.online then
        local tip = V.createTTF("", V.FontSize.S1, V.COLOR_TEXT_DARK)
        tip:setScale(0.8)
        tip:setAnchorPoint(1, 1)
        lc.addChildToPos(self, tip, cc.p(lc.right(btnClaim), lc.bottom(btnClaim) ))
        self._tip = tip
    end
end

function _M:onEnter()
    self._listener = lc.addEventListener(Data.Event.bonus_dirty, function(event) 
        if event._data == self._bonus then
            self:updateView()
        end
    end)
    self:updateData(self._label, self._bonus)
    self:scheduleUpdateWithPriorityLua(function(dt) self:onSchedule(dt) end, 0)
end

function _M:onExit()
    lc.Dispatcher:removeEventListener(self._listener)
    self:unscheduleUpdate()
end

function _M:updateData(label, bonus)
    self._label = label
    self._bonus = bonus    
    
    self._dateLabel:setString(label)

    self:removeChildrenByTag(TAG_ITEM)
    local info = bonus._info
    local items, ids, levels, counts, isFragments = {}, info._rid, info._level, info._count, info._isFragment
    for i, id in ipairs(ids) do
        local item = IconWidget.create{_infoId = id, _level = levels[i], _isFragment = isFragments[i] > 0, _count = counts[i]}
        item._name:setColor(V.COLOR_TEXT_DARK)
        table.insert(items, item)
    end
    
    P:sortResultItems(items)

    local x, y = 180, ITEM_SIZE.height / 2
    for _, item in ipairs(items) do
        lc.addChildToPos(self, item, cc.p(x + lc.w(item) / 2, y), 0, TAG_ITEM)
        x = x + lc.w(item) + 18

        item:checkHighlight()
    end

    self:updateView()
end

function _M:registerClaimHandler(handler)
    self._claimHandler = handler
end

function _M:updateView()
    local bonus = self._bonus
    local isEnabled = self._bonus._value >= self._bonus._info._val
    self._btnClaim:setVisible(not bonus._isClaimed)
    self._btnClaim:setEnabled(isEnabled)
    self._btnClaim:setTouchSwallow(isEnabled)
    self._claimedFlag:setVisible(bonus._isClaimed)
end

function _M:onSchedule(dt)
    local info = self._bonus._info
    if info then
        if info._type == Data.BonusType.online then
            self:updateOnlineBonusTip()
        end
    end
end

function _M:updateOnlineBonusTip()
    local bonus, info = self._bonus, self._bonus._info
    local prevBonus = bonus:getPrevBonus()
    if prevBonus == nil or prevBonus._isClaimed then
        if bonus._isClaimed or bonus:canClaim() then
            self._tip:setString("")
        else
            local dt = math.ceil(info._val - bonus._value)
            if dt < 0 then dt = 0 end
            self._tip:setString(string.format(Str(STR.CLAIM_AFTER1), ClientData.formatPeriod(dt)))
        end
    else
        local dt = info._val - (prevBonus and prevBonus._info._val or 0)
        if dt < 0 then dt = 0 end
        self._tip:setString(string.format(Str(STR.CLAIM_AFTER2), ClientData.formatPeriod(dt, 1)))
    end
end

return _M