local _M = class("OnlinePanel", lc.ExtendUIWidget)
local CheckinBonusWidget = require("CheckinBonusWidget")

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

    local title = V.createCheckinTitle(Str(STR.CHECKIN_ONLINE), 0)
    lc.addChildToPos(self, title, cc.p(lc.w(self) / 2 + 140, lc.h(self) - lc.h(title) / 2 - 24))

    local tip = V.createTTF(Str(STR.ONLINE_CHECKIN_TIP), V.FontSize.S1, V.COLOR_TEXT_DARK)    
    lc.addChildToPos(self, tip, cc.p(lc.x(title), lc.bottom(title) - lc.h(tip) / 2 - 12))

    local bonusBG = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = cc.size(lc.w(self) - 20, 390)}
    lc.addChildToPos(self, bonusBG, cc.p(lc.w(self) / 2, lc.h(bonusBG) / 2))

    self._bonusList = lc.List.createV(cc.size(lc.w(bonusBG) - 32, lc.h(bonusBG) - 20), 16, 10)
    lc.addChildToPos(bonusBG, self._bonusList, cc.p(16, 10))
    
    self:refreshList()
end

function _M:refreshList()
    local bonuses, claimableBonuses, unclaimBonuses, claimedBonuses = {}, P._playerBonus.splitBonus(P._playerBonus._bonusOnlineTask)
    for _, bonus in ipairs(claimableBonuses) do table.insert(bonuses, bonus) end
    for _, bonus in ipairs(unclaimBonuses) do table.insert(bonuses, bonus) end
    for _, bonus in ipairs(claimedBonuses) do table.insert(bonuses, bonus) end

    self._bonusList:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #bonuses))

    for i = 1, self._bonusList._cacheCount do
       self._bonusList:pushBackCustomItem(self:setOrCreateItem(nil, bonuses[i]))
    end
end

function _M:setOrCreateItem(item, data)
--    local title = string.format(Str(data._info._nameSid), data._info._val)
    local str = string.sub(Str(data._info._nameSid), -7)
    local item = CheckinBonusWidget.create(str, data)
    item:registerClaimHandler(function(bonus) 
        if bonus._value >= bonus._info._val then
            if not bonus._isClaimed then
                local result = ClientData.claimBonus(bonus)
                self:refreshList()
                V.showClaimBonusResult(bonus, result)
            end
        end
    end)
    return item
end

return _M