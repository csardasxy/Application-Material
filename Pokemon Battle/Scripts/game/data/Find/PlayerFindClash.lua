local _M = class("PlayerFindClash")

local Log = require("Log")

function _M:ctor()
    self:clear()
    self._trophy = 0

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    lc.addEventListener(Data.Event.prop_dirty, function(event) self:syncChests() end)
end

function _M:clear()
    self._isSyncData = false    

    self._chests = {}
end

function _M:simulate()
    self._isSyncData = true

    self._endTime = 0
    self._preRank = 0
    self._preTrophy = 0
    self._trophy = 600
    self._grade = self:getGrade(self._trophy)

    self._isFirst = true    -- resp.is_first

    lc.sendEvent(Data.Event.clash_sync_ready)
end

function _M:changeTrophy(delta)
    local trophy = self._trophy + delta

    self._trophy = trophy
    self._grade = self:getGrade(trophy)

    for i = 1, #P._playerBonus._bonusClashTarget do
        P._playerBonus._bonusClashTarget[i]:setValue(math.max(self._trophy, P._playerBonus._bonusClashTarget[i]._value))
    end

    lc.sendEvent(Data.Event.clash_trophy_dirty)
end

function _M:getGrade(trophy)    
    for i = Data.FindClashGrade.bronze + 1, Data.FindClashGrade.legend do
        local limit = Data._ladderInfo[i]._trophy
        if trophy < limit then
            return i - 1
        end
    end

    return Data.FindClashGrade.legend
end

function _M:resetChests()
    for i = Data.PropsId.clash_chest, Data.PropsId.clash_chest_end do
        local prop = P._propBag._props[i]
        if prop and prop._num > 0 then
            prop._isOpened = false
            P._propBag:setProps(i, 0)
        end
    end

    self._chests = {}
end

function _M:syncChests()
    self._chests = {}

    for i = Data.PropsId.clash_chest, Data.PropsId.clash_chest_end do
        local prop = P._propBag._props[i]
        if prop and prop._num > 0 then
            local index = i % 10
            if self._chests[index] == nil then
                local grade = math.floor((i - Data.PropsId.clash_chest) / 10) + 1
                self._chests[index] = {_prop = prop, _grade = grade}
            end
        end
    end
end

function _M:getChestGrade(index)
    if self._chests[index] then
        return self._chests[index]._grade
    else
        return self._grade
    end
end

function _M:isAllChestsOpened()
    for index = 1, 5 do
        if self._chests[index] == nil or (not self._chests[index]._prop._isOpened) then
            return false
        end
    end

    return true
end

function _M:onMsg(msg)
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_RANK_PRE then
        if self._isSyncData then return true end
        self._isSyncData = true

        local resp = msg.Extensions[Rank_pb.SglRankMsg.rank_pre_resp]
        self._endTime = resp.end_time / 1000
        self._preRank = resp.pre_rank
        self._preTrophy = resp.pre_trophy

        self._trophy = 0
        self:changeTrophy(resp.trophy)
        self._grade = self:getGrade(self._trophy)

        self._period = resp.period

        self._isFirst = resp.is_first

        self._ladderTrophy = 0
        if resp:HasField('ladder_ex_trophy') then
            -- speical for player find ladder
            self._ladderTrophy = resp.ladder_ex_trophy
        end
        
        local gInfo = Data._globalInfo._ladderStage
        for i = 0, #gInfo + 1 do
            local rank = resp.ranks[i + 1]
            if rank then
                rank.user_id = resp.user_id
            end

            P._playerRank:parseRankData(rank, SglMsgType_pb.PB_TYPE_RANK_PRE, i)
        end
        self._clashId = resp.user_id

        self:syncChests()

        lc.sendEvent(Data.Event.clash_sync_ready)

        return true
    end
    
    return false
end

return _M