local _M = class("ServerBonus")

function _M:ctor(pbBonus)
    self._id = pbBonus.id
    self._timestamp = pbBonus.timestamp / 1000
    self._isClaimed = pbBonus.claimed
    self._value = 0

    self._infoId = pbBonus.info_id

    if pbBonus:HasField("title") then
        self._title = pbBonus.title
    end
    if pbBonus:HasField("extra") then
        self._extraBonus = {}
        for _, bonus in ipairs(pbBonus.extra.resources) do
            table.insert(self._extraBonus, {_infoId = bonus.info_id, _count = bonus.num, _level = bonus._level, _isFragment = bonus.is_fragment})
        end
    else
        self._info = Data._bonusInfo[self._infoId]
    end
end

function _M:sendBonusDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.bonus_dirty)
    eventCustom._data = self
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:canClaim()
    return true
end

return _M
