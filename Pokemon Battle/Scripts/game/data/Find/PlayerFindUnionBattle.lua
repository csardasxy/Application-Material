local _M = class("PlayerFindUnionBattle")

local UNION_BATTLE_ACTIVITY_TYPE = 1303

function _M:ctor()
    self:clear()

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
end

function _M:init(pbLadder)
end

function _M:onMsg(msg)
    local msgType = msg.type

    return false
end

function _M.getLadderDuration()
    local defaultInfo, specificInfo
    local info = ClientData.getActivityByType(UNION_BATTLE_ACTIVITY_TYPE)
    if info then
        if info._beginTime == '' then
            defaultInfo = info
        elseif ClientData.isActivityValid(info) then
            specificInfo = info
        end
    end
    local info = specificInfo or defaultInfo
    return info._param
end

function _M:getIsUnionBattleActivityValid()
    local info = ClientData.getActivityByType(UNION_BATTLE_ACTIVITY_TYPE)
    return info ~= nil and (info._beginTime == '' or ClientData.isActivityValid(info))
end

function _M:getIsValidTime()
    local hour, day, month, year = ClientData.getServerDate()
    local param = self:getLadderDuration()
    local weekday = ClientData.getDayOfWeek()
    weekday = weekday == 0 and 7 or weekday
    local startHour = param[3 * (weekday - 1) + 2]
    local endHour = param[3 * (weekday - 1) + 3]
    local result = 0
    if hour < startHour then
        result = 1--not yet
    elseif hour >= endHour then
        result = -1--ended
    end

    return result
end

function _M:getStartTimeTip()
    local hour, day, month, year = ClientData.getServerDate()
    local todayTimestamp = ClientData.getCurrentTime() - ClientData.getExpireTimestamp(0)
    local param = self:getLadderDuration()
--    local weekday = ClientData.getDayOfWeek()
    local weekday = 6
    local startHour = param[3 * (weekday - 1) + 2]
    local endHour = param[3 * (weekday - 1) + 3]
    local remainSeconds = startHour * 3600 - todayTimestamp
--    return self:getRemainSecondsStr(remainSeconds)
    return string.format(Str(STR.UNION_BATTLE_START_TIP), startHour, endHour)
end

function _M:getEndTimeTip()
    local hour, day, month, year = ClientData.getServerDate()
    local todayTimestamp = ClientData.getCurrentTime() - ClientData.getExpireTimestamp(0)
    local param = self:getLadderDuration()
--    local weekday = ClientData.getDayOfWeek()
    local weekday = 6
    local startHour = param[3 * (weekday - 1) + 2]
    local endHour = param[3 * (weekday - 1) + 3]
    local remainSeconds = endHour * 3600 - todayTimestamp
    return self:getRemainSecondsStr(remainSeconds)
end

function _M:getRemainSecondsStr(seconds)
    local hour = math.floor(seconds / 3600)
    local minute = math.floor((seconds - hour * 3600) / 60)
    local second = math.floor(seconds % 60)
    local str = string.format("%d:%02d:%02d", hour, minute, second)
    return str
end

return _M