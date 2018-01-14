local _M = class("MainTask")

function _M:ctor(infoId)
    self._infoId = infoId
    self._info = Data._mainTaskInfo[infoId]
    
    -- Connect level task with bonus
    local bonus = self:getBonus()
    if bonus._info._type == 1 then
        bonus._task = self
    end
end

function _M:getBonus()
    return P._playerBonus._bonuses[self._info._bonusId]
end

function _M:getDesc()
    local bonusInfo = self:getBonus()._info
    local type = self._info._type
    
    if type == Data.MainTaskType.chapter then
        local strs = {Str(STR.STORY_LINE), Str(STR.REBEL), Str(STR.CHAOS)}
        local levelInfo = Data._levelInfo[bonusInfo._val]
        return string.format(Str(bonusInfo._nameSid), string.format("%s"..Str(STR.BRACKETS_S), Str(levelInfo._nameSid), strs[math.floor(levelInfo._id / 10000)]))

    elseif type == Data.MainTaskType.level then
        return string.format(Str(bonusInfo._nameSid), bonusInfo._val)

    elseif type == Data.MainTaskType.card then
        local val = bonusInfo._val

        local bonusCid = self:getBonus()._info._cid
        if bonusCid == 205 or bonusCid == 305 then
            val = val + 1
        end

        return string.format(Str(bonusInfo._nameSid), val)

    else
        return Str(bonusInfo._nameSid)
    end
end

function _M:getClaimableCount()
    local bonusInfo = self:getBonus()._info
    local type, cid = bonusInfo._type, bonusInfo._cid

    local count = 0
    for _, t in pairs(P._playerAchieve._mainTasks) do
        local bonus = t:getBonus()
        if bonus._info._type == type and bonus._info._cid == cid then
            if bonus:canClaim() then
                count = count + 1
            end
        end
    end

    return count
end

function _M:isDefaultValid()
    return not self:isDone()    
end

function _M:isValid()
    if not self:isDefaultValid() then return false end

    local condition = self._info._condition
    for i = 1, #condition do
        local task = P._playerAchieve._mainTasks[condition[i]]
        if task ~= nil and not task:isDone() then
            return false
        end
    end
    
    -- main task chapter
    if self._infoId < 1000 then
        local bonus = self:getBonus()
        local levelId = bonus._info._val
        local levelInfo = Data._levelInfo[levelId]
        if levelInfo ~= nil then
            --[[
            local passId = cityChapter._passId
            local isPass = true
            for i = 1, #passId do
                local passCityChapter = Data._levelInfo[ passId[i] ]
                if passCityChapter ~= nil then
                    local passCity = P._playerWorld._cities[passCityChapter._levelId]
                    isPass = (isPass and passCity._chapter > passCityChapter._chapter)
                end
            end
            if not isPass then return false end
            ]]
        end
    end 

    return true
end

function _M:isDone()
    local bonus = self:getBonus()
    return bonus._value >= bonus._info._val and bonus._isClaimed
end

return _M
