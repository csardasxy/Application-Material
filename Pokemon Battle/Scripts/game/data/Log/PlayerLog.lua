local _M = class("PlayerLog")

local Log = require("Log")

_M.Event = 
{
    attack_log_dirty = "attack log dirty",
    defense_log_dirty = "defense log dirty",
    clash_log_dirty = "clash log dirty",
    melee_log_dirty = "melee log dirty",
    room_log_dirty = "room log dirty",
    log_item_dirty = "log item dirty",
    log_already_shared = "log already shared",
    dark_log_dirty = "dark log dirty",
}

function _M:ctor()
    self:clear()

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    self. _attackLogs = {}
    self._defenseLogs = {}

    self._clashLogs = {}
    self._isClashLogsReady = false

    self._meleeLogs = {}
    self._isMeleeLogsReady = false

    self._roomLogs = {}
    self._isRoomLogsReady = false

    self._darkLogs = {}
    self._isDarkLogsReady = false
end

function _M:addLog(log, logType)
    local logs = self:getLogs(logType, log._isAttack)
    logs[log._id] = log
end

function _M:sendLogDirty(event, logId)
    local eventCustom = cc.EventCustom:new(Data.Event.log_dirty)
    eventCustom._event = event
    eventCustom._logId = logId
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendLogShared(logId)
    local eventCustom = cc.EventCustom:new(Data.Event.log_shared)
    eventCustom._event = _M.Event.log_already_shared
    eventCustom._logId = logId
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:getLogs(logType, isAttack)
    if logType == Battle_pb.PB_BATTLE_WORLD_LADDER then
        return self._clashLogs

    elseif logType == Battle_pb.PB_BATTLE_WORLD_LADDER_EX then
        return self._meleeLogs

    elseif logType == Battle_pb.PB_BATTLE_MATCH then
        return self._roomLogs

    elseif logType == Battle_pb.PB_BATTLE_DARK then
        return self._darkLogs

    else
        return isAttack and self._attackLogs or self._defenseLogs
    end
end

function _M:getLogList(logType, isAttack)
    if logType == Battle_pb.PB_BATTLE_WORLD_LADDER then
        if not self._isClashLogsReady then
            return nil
        end
    elseif logType == Battle_pb.PB_BATTLE_MATCH then
        if not self._isRoomLogsReady then
            return nil
        end
    elseif logType == Battle_pb.PB_BATTLE_WORLD_LADDER_EX then
        if not self._isMeleeLogsReady then
            return nil
        end
    elseif logType == Battle_pb.PB_BATTLE_DARK then
        if not self._isDarkLogsReady then
            return nil
        end
    end

    local temp = {}
    local logs = self:getLogs(logType, isAttack)
    for k, v in pairs(logs) do
        table.insert(temp, v)
    end
    table.sort(temp, function(a, b) return a._timestamp > b._timestamp end)
    
    return temp
end

function _M:getNewAttackLogCount()
    local timestamp = lc.readConfig(ClientData.ConfigKey.new_attack_log, 0)
    local number = 0
    if self._attackLogs ~= nil then
        for id, log in pairs(self._attackLogs) do
            if log._timestamp > timestamp then
                number = number + 1
            end
        end
    end
    
    return number
end

function _M:getNewDefenseLogCount()
    local timestamp = lc.readConfig(ClientData.ConfigKey.new_defense_log, 0)
    local number = 0
    if self._defenseLogs ~= nil then
        for id, log in pairs(self._defenseLogs) do
            if log._timestamp > timestamp then
                number = number + 1
            end
        end
    end
    
    return number
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == SglMsgType_pb.PB_TYPE_BATTLE_LOG then
        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_log_resp]
        for i = 1, #resp.attack_log do
            local log = Log.new(true, resp.attack_log[i])
            self:addLog(log, Battle_pb.PB_BATTLE_PLAYER)
        end               
        for i = 1, #resp.defend_log do
            local log = Log.new(false, resp.defend_log[i])
            self:addLog(log, Battle_pb.PB_BATTLE_PLAYER)
        end
        self:sendLogDirty(_M.Event.attack_log_dirty)
        self:sendLogDirty(_M.Event.defense_log_dirty)
    
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_LOG_EX then
        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_log_ex_resp]
        local pvpType, pbLogs = resp.type, resp.logs

        for _, pbLog in ipairs(pbLogs) do
            local log = Log.new(nil, pbLog)
            self:addLog(log, pvpType)
        end               

        if pvpType == Battle_pb.PB_BATTLE_WORLD_LADDER then
            self._isClashLogsReady = true
            self:sendLogDirty(_M.Event.clash_log_dirty)
        elseif pvpType == Battle_pb.PB_BATTLE_MATCH then
            self._isRoomLogsReady = true
            self:sendLogDirty(_M.Event.room_log_dirty)
        elseif pvpType == Battle_pb.PB_BATTLE_DARK then
            self._isDarkLogsReady = true
            self:sendLogDirty(_M.Event.dark_log_dirty)
        else
            self._isMeleeLogsReady = true
            self:sendLogDirty(_M.Event.melee_log_dirty)
        end        

        return true
    end
    
    return false
end

return _M
