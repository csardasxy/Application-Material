local _M = class("ActivityTask")

function _M:ctor(infoId)
    self._infoId = infoId
    self._info = Data._activityTaskInfo[infoId]
    
    -- Connect level task with bonus
    local bonus = self:getBonus()
    if bonus and bonus._info._type == 20 then
        bonus._task = self
    end

    -- Exchange res
    if self:isExchangeTask() then
        self._resNeed = {}
        for _, res in ipairs(self._info._param) do
            table.insert(self._resNeed, {_infoId = res[1], _count = res[2]})
        end
    end
end

function _M:getBonus()
    return P._playerBonus._bonuses[self._info._bonusId]
end

function _M:getTitle()
    local bonusInfo = self:getBonus()._info
    return Str(bonusInfo._nameSid)
end

function _M:exchange()
    if self:isExchangable() then
        local bonus = self:getBonus()
        if self:isExchangeTask() then
            local info = bonus._info
            P:addResources(info._rid, info._level, info._count, info._isFragment)

            for _, res in ipairs(self._resNeed) do
                local resType = Data.getType(res._infoId)
                if resType == Data.CardType.res then
                    P:changeResource(res._infoId, -res._count)
                elseif resType == Data.CardType.props then
                    P._propBag:changeProps(res._infoId, -res._count)
                end
            end

            ClientData.sendClaimActivityBonus(self._infoId)

            if self._info._type == Data.ActivityTaskType.exchange_daily or self._info._type == Data.ActivityTaskType.exchange_once then
                bonus._isClaimed = true
            end

        else
            P._playerBonus:claimBonus(bonus._infoId)
        end

        return Data.ErrorType.ok
    end

    return Data.ErrorType.need_more_exchange_res
end

function _M:isExchangeTask()
    local taskType = self._info._type
    return taskType >= Data.ActivityTaskType.exchange_minor and taskType <= Data.ActivityTaskType.exchange_once
end

function _M:isExchangable()
    if self._resNeed then
        for _, res in ipairs(self._resNeed) do
            local resNum = P:getItemCount(res._infoId)
            if res._count > resNum then
                return false
            end
        end

        return true
    end
end

function _M:isValid()
    return true
end

return _M
