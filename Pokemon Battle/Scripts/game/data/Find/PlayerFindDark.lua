local _M = class("PlayerFindDark")

local DARK_ACTIVITY_TYPE = 1304

function _M:ctor()
    self:clear()

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    self._inning = 0
    self._winScore = 0
    self._loseScore = 0
    self._trophy = 0
end

function _M:clearScore()
    self._inning = 0
    self._winScore = 0
    self._loseScore = 0
end

function _M:init(pbDark)
    self._inning = pbDark.inning or 0
    self._trophy = pbDark.score or 0
    self._winScore = pbDark.win or 0
    self._loseScore = pbDark.opWin or 0
end

function _M:onMsg(msg)
    local msgType = msg.type

    return false
end

function _M:isDarkFinished()
    local ret = false
    if self._inning >= 3 or (self._winScore >= 2 or self._loseScore >= 2 ) then
        ret = true
    end
    return ret
end

function _M:isInDarkBattle()
    return self._inning > 0 and not self:isDarkFinished()
end

function _M.getDarkDuration()
    local defaultInfo, specificInfo
    local info = ClientData.getActivityByType(DARK_ACTIVITY_TYPE)
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

function _M:getIsDarkActivityValid()
    local info = ClientData.getActivityByType(DARK_ACTIVITY_TYPE)
    return info ~= nil and (info._beginTime == '' or ClientData.isActivityValid(info))
end

function _M:getIsValidTime()
    local hour, day, month, year = ClientData.getServerDate()
    local param = self:getDarkDuration()
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
    local param = self:getDarkDuration()
--    local weekday = ClientData.getDayOfWeek()
    local weekday = 5
    local startHour = param[3 * (weekday - 1) + 2]
    local endHour = param[3 * (weekday - 1) + 3]
    local remainSeconds = startHour * 3600 - todayTimestamp
--    return self:getRemainSecondsStr(remainSeconds)
    return string.format(Str(STR.DARK_START_TIP), startHour, endHour)
end

function _M:getEndTimeTip()
    local hour, day, month, year = ClientData.getServerDate()
    local todayTimestamp = ClientData.getCurrentTime() - ClientData.getExpireTimestamp(0)
    local param = self:getDarkDuration()
--    local weekday = ClientData.getDayOfWeek()
    local weekday = 5
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

function _M:find(isForce)
    if self:isDarkFinished() then
        if isForce then
            self:clearScore()
            ClientData.sendWorldFindEx(P._curTroopIndex, Battle_pb.PB_BATTLE_DARK)
        end
    else
        ClientData.sendWorldFindEx(P._curTroopIndex, Battle_pb.PB_BATTLE_DARK)
    end
end

function _M:onFind()
    self._inning = self._inning + 1
    if self._inning == 1 then
        local price = Data._globalInfo._darkDuelCost
        P:changeResource(Data.ResType.gold, - price)
    end
end

function _M:onFindCancled()
    self:clearScore()
end

function _M:retreat(needFind)
    local add = math.min(2, self._loseScore + 3 - self._inning) - self._loseScore
    self._loseScore = self._loseScore + add
    self._inning = self._inning + add
    if needFind then
        ClientData.sendWorldFindEx(P._curTroopIndex, Battle_pb.PB_BATTLE_DARK)
    end
    ClientData.sendDarkRetreat()
end

function _M:onInningEnd(pbResp)
    self._inning = pbResp.inning
    self._winScore = pbResp.win
    self._loseScore = pbResp.lose
    if not self:isDarkFinished() then
        self:find()
    end
end

return _M