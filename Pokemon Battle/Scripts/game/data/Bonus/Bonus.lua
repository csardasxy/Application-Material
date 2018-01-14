local _M = class("Bonus")

function _M:ctor(infoId)
    self._infoId = infoId
    self._info = Data._bonusInfo[infoId]
    self._type = self._info._type
    self._value = 0
    self._isClaimed = false
end

function _M:sendBonusDirty(lastValue)
    if self._task and not self._task:isValid() then
        return
    end

    local eventCustom = cc.EventCustom:new(Data.Event.bonus_dirty)
    eventCustom._data = self
    eventCustom._lastValue = lastValue
    lc.Dispatcher:dispatchEvent(eventCustom)
    
    if self._value >= self._info._val and not self._isDefaultClaimable then
        self._isDefaultClaimable = true
    end
end

function _M:setValue(value)
    if value == self._value then
        return false
    end

    self._value = value
    return true
end

function _M:isChapter()
    local cid = self._info._cid
    return cid == 103 or cid == 104 or cid == 105
end

function _M:isTeach()
    return self._info._type == Data.BonusType.teach 
end

function _M:canClaim()
    local info = self._info
    local result = (self._value >= info._val and info._val > 0 and not self._isClaimed)

    if not result then
        return false
    end

    if info._type == Data.BonusType.online then
        local prevBonus = self:getPrevBonus()
        if prevBonus ~= nil and not prevBonus._isClaimed then
            return false
        end

    elseif info._type == Data.BonusType.fund_level then
        return ClientData.isRecharged(Data.PurchaseType.fund) or P:isUnionFundValid()

    elseif info._type == Data.BonusType.invite then
        return self._claimTimes < self._claimTimesMax and self._value > self._claimTimes

    end

    return true
end

function _M:getPrevBonus()
    local info = self._info
    local prevBonus = P._playerBonus._bonuses[info._id - 1]
    if prevBonus ~= nil and prevBonus._info._type ~= self._type then
        prevBonus = nil
    end

    return prevBonus
end

return _M
