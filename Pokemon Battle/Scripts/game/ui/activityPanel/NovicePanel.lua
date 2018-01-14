local _M = class("NovicePanel", lc.ExtendUIWidget)
local CheckinBonusWidget = require("CheckinBonusWidget")

function _M.create(bgName, size)
    local panel = _M.new(lc.EXTEND_LAYOUT)
    panel:setContentSize(size)
    panel:setAnchorPoint(0.5, 0.5)
    panel:init(bgName)
    return panel
end

function _M:init(bgName)
    local titleBg = lc.createSprite('res/jpg/activity_top.jpg')
    lc.addChildToPos(self, titleBg, cc.p(lc.w(self) / 2, lc.h(self) - lc.h(titleBg) / 2))

    local title = V.createCheckinTitle(Str(STR.NOVICE_CHECKIN_TITLE), 0)
    lc.addChildToPos(self, title, cc.p(lc.w(self) / 2 + 140, lc.h(self) - lc.h(title) / 2 - 24))

    --[[
    local tip = V.createTTF(Str(not ClientData.isAndroidTest0602() and STR.NOVICE_CHECKIN_TIP or STR.NOVICE_CHECKIN_TIP_TEST), V.FontSize.S1, V.COLOR_TEXT_DARK)    
    lc.addChildToPos(self, tip, cc.p(lc.x(title), lc.bottom(title) - lc.h(tip) / 2 - 12))
    ]]

    local bonusBG = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = cc.size(lc.w(self) - 20, 390)}
    lc.addChildToPos(self, bonusBG, cc.p(lc.w(self) / 2, lc.h(bonusBG) / 2))

    local bonusList = lc.List.createV(cc.size(lc.w(bonusBG) - 32, lc.h(bonusBG) - 20), 16, 10)
    lc.addChildToPos(bonusBG, bonusList, cc.p(16, 10))
    
    local bonuses, claimableBonuses, unclaimBonuses, claimedBonuses = {}, P._playerBonus.splitBonus(P._playerBonus._bonusLogin, function(i, bonus) return {_bonus = bonus, _label = string.format(Str(STR.DATE_NUM), bonus._info._val)} end)
    for _, bonus in ipairs(claimableBonuses) do table.insert(bonuses, bonus) end
    for _, bonus in ipairs(claimedBonuses) do table.insert(bonuses, bonus) end
    for _, bonus in ipairs(unclaimBonuses) do table.insert(bonuses, bonus) end

    bonusList:bindData(bonuses, function(item, bonus) item:updateData(bonus._label, bonus._bonus) end, math.min(4, #bonuses))

    for i = 1, bonusList._cacheCount do
        local item = CheckinBonusWidget.create(bonuses[i]._label, bonuses[i]._bonus)
        item:registerClaimHandler(function(bonus) 
            local result = ClientData.claimBonus(bonus)
            V.showClaimBonusResult(bonus, result)
        end)
        bonusList:pushBackCustomItem(item)                         
    end
end

return _M