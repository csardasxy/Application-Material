local MainTask = require "MainTask"
local ActivityTask = require "ActivityTask"

local _M = class("PlayerAchieve")

function _M:ctor()
    self:clear()

end

function _M:clear()
    self._mainTasks = {}
    self._activityTasks = {}
end

function init()
    initMainTask()
    initActivityTask()
end

function _M:initMainTask()
    for k, v in pairs(Data._mainTaskInfo) do
        --TODO--
        if v._type <= 0 then
            local task = MainTask.new(k)
            self._mainTasks[k] = task
        end
    end
end

function _M:initActivityTask()
    for k, v in pairs(Data._activityTaskInfo) do
        if type(k) == "number" then         -- Only use number key
            local task = ActivityTask.new(k)
            self._activityTasks[k] = task
        end
    end
end

function _M:getDailyTaskLevel(dailyTaskType)
    if dailyTaskType == Data.DailyTaskType.player_battle_win then
        return Data._globalInfo._unlockFindMatch
    elseif dailyTaskType == Data.DailyTaskType.upgrade_equip then
        return P._playerCity:getBlacksmithUnlockLevel()
    elseif dailyTaskType == Data.DailyTaskType.challenge_elite then
        return Data._globalInfo._unlockElite
    elseif dailyTaskType == Data.DailyTaskType.copy_boss then
        return Data._globalInfo._unlockRobExp
    elseif dailyTaskType == Data.DailyTaskType.collect_fragment then
        return P._playerCity:getGuardUnlockLevel()
    elseif dailyTaskType == Data.DailyTaskType.rob_horse then
        return Data._globalInfo._unlockCommander
    elseif dailyTaskType == Data.DailyTaskType.upgrade_horse then
        return P._playerCity:getStableUnlockLevel()
    elseif dailyTaskType == Data.DailyTaskType.expedition then
        return Data._globalInfo._unlockExpedition
    elseif dailyTaskType == Data.DailyTaskType.challenge_uboss then
        return P._playerCity:getUnionUnlockLevel()
    end

    return 0
end

function _M:getOrderedMainTasks()
    return lc.reorderToArray(self._mainTasks, function(a, b) return a._infoId < b._infoId end)
end

function _M:getOrderedActivityTasks()
    return lc.reorderToArray(self._activityTasks, function(a, b) return a._infoId < b._infoId end)
end

function _M:dailyTaskDone(dailyTaskType, delta)
    --TODO--
    return

    --[[
    local bonus = P._playerBonus._bonusDailyTask[dailyTaskType]
    if bonus == nil then return end

    local lastValue = bonus._value
    bonus._value = bonus._value + (delta or 1)
    bonus:sendBonusDirty(lastValue)
    ]]
end

function _M:activityTaskDone(taskId)
    local bonus = self._activityTasks[taskId]:getBonus()
    if bonus == nil then return end

    local lastValue = bonus._value
    bonus._value = bonus._value + (delta or 1)
    bonus:sendBonusDirty(lastValue)
end

function _M:sendAchieveListDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.achieve_list_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

return _M
