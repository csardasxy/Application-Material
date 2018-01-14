local _M = class("PlayerRank")

local Rank = require("Rank")

_M.RANK_COUNT = 50

local rankClearTimer
local rankReady             -- used to dirty rank

function _M:ctor()
    self:clear()

    lc.addEventListener(Data.Event.level_dirty, function()
        self:clearRank(SglMsgType_pb.PB_TYPE_RANK_LEVEL)
        self:clearRank(SglMsgType_pb.PB_TYPE_RANK_REGION)
    end)

    lc.addEventListener(Data.Event.chapter_level_dirty, function()
        self:clearRank(SglMsgType_pb.PB_TYPE_RANK_STAR)
    end)

    lc.addEventListener(Data.Event.trophy_dirty, function()
        self:clearRank(SglMsgType_pb.PB_TYPE_RANK_TROPHY)
    end)

    lc.addEventListener(Data.Event.dark_trophy_dirty, function()
        self:clearRank(SglMsgType_pb.PB_TYPE_RANK_DARK)
    end)

    lc.addEventListener(Data.Event.union_level_upgrade, function()
        self:clearRank(SglMsgType_pb.PB_TYPE_RANK_UNION_LEVEL)
    end)

    lc.addEventListener(Data.Event.clash_trophy_dirty, function()
        for i = 0, #Data._globalInfo._ladderStage + 1 do
            self:clearRank(SglMsgType_pb.PB_TYPE_RANK_LADDER, i)
        end
    end)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    rankClearTimer = 0
    rankReady = {}
    reserveRanks = {}
end

function _M:initRanks()
    local ranks = {}
    for i = 1, _M.RANK_COUNT do
        table.insert(ranks, Rank.new())
    end
    return ranks
end

function _M:parseRankData(pbRanks, type, subType)
    local name = self:getRankName(type, subType)
    local genRanks = function(type)
        if self[name] == nil then
            self[name] = self:initRanks()
        end
        
        return self[name]
    end

    local ranks, isUnionRank = genRanks(type)
    if type == SglMsgType_pb.PB_TYPE_RANK_UNION_LEVEL or type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_TIME or type == SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY then
        isUnionRank = true
    elseif type == SglMsgType_pb.PB_TYPE_RANK_PRE then
        ranks._isReserve = true
    end

    local isGroupRank
    if type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM or type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM then
        isGroupRank = true
    end

    if pbRanks then
        ranks._count = #pbRanks.data

        if pbRanks:HasField("user_id") then
            ranks._rankId = pbRanks.user_id
        else
            if type == SglMsgType_pb.PB_TYPE_RANK_PRE or type == SglMsgType_pb.PB_TYPE_RANK_LADDER then
                ranks._rankId = 0
            else
                ranks._rankId = P._id
            end
        end

        if pbRanks:HasField("season") then
            ranks._season = pbRanks.season
        end

        ranks._selfRank = nil
        local j = 1
        for i = 1, #pbRanks.data do
            local data = pbRanks.data[i]

            if type == SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY and data.union_info.member == 0 then
                ranks._count = ranks._count - 1
            else

                local rank
                if j <= _M.RANK_COUNT then
                    rank = ranks[j]
                    rank:set(data, type, subType)
                end

                if (not isUnionRank and not isGroupRank and data.user_info.id == ranks._rankId) or (isUnionRank and data.union_info.id == P._unionId) or (isGroupRank and data.team.id == P._playerUnion._groupId) then
                    if rank == nil then
                        rank = Rank.new()
                        rank:set(data, type, subType)

                        ranks._count = ranks._count - 1
                    end

                    ranks._selfRank = rank
                end

                j = j + 1

            end
        end
    else
        ranks._count = 0
        ranks._rankId = P._id
        ranks._selfRank = nil
    end

    rankReady[name] = ranks
    self:sendRankListDirty(type, subType)
end

function _M:getRanks(type, subType)
    local ranks = self[self:getRankName(type, subType)]
    return ranks
end

function _M:getRankName(type, subType)
    local name = ""
    if type == SglMsgType_pb.PB_TYPE_RANK_LEVEL then
        name = "lordLevel"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_POWER then
        name = "power"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_STAR then
        name = "cityStar"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_TROPHY then
        name = "trophy"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_UNION_LEVEL then
        name = "unionLevel"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_BOSS then
        name = "worldBoss"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_SCORE then
        name = "uboss"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_LADDER then
        name = "findClash"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_LADDER_EX then
        name = "findLadder"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_PRE then
        name = "findClashPre"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY then
        name = "unionTrophy"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP then
        name = "unionBattleMvp"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM then
        name = "unionBattleTeam"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_MVP then
        name = "unionBattlePreMvp"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM then
        name = "unionBattlePreTeam"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_DARK then
        name = "dark"
    elseif type == SglMsgType_pb.PB_TYPE_RANK_DARK_PRE then
        name = "darkPre"
    end

    return subType and string.format("_%sRanks_%s", name, subType) or string.format("_%sRanks", name)
end

function _M:getRankBonusInfo(rank, type)
    type = type or SglMsgType_pb.PB_TYPE_RANK_TROPHY
    for _, info in pairs(Data._rankBonusInfo) do
        if info._type == type and rank >= info._min and rank <= info._max then
            return info
        end
    end
end

function _M:scheduler(dt)
    rankClearTimer = rankClearTimer + dt
    if rankClearTimer > 30 then                -- clear rank every 30 seconds
        rankClearTimer = 0

        for name, ranks in pairs(rankReady) do
            if not ranks._isReserve then
                rankReady[name] = nil
            end
        end
    end
end

function _M:clearRank(type, subType)
    local name = self:getRankName(type, subType)
    rankReady[name] = nil
end

function _M:clearPreRank(type, subType)
    local name = self:getRankName(type, subType)
    self[name] = nil
    rankReady[name] = nil
end

function _M:sendRankRequest(type, subType)
    local name = self:getRankName(type, subType)

    if not rankReady[name] then
        if type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_SCORE or type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_TIME then
            ClientData.sendRankUBoss(type, subType)
        else
            ClientData.sendRankRequest(type, subType)
        end

        return true

    else
        self:sendRankListDirty(type, subType)
    end
end

function _M:sendRankListDirty(type, subType)
    local eventCustom = cc.EventCustom:new(Data.Event.rank_list_dirty)
    eventCustom._type = type
    eventCustom._subType = subType
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:onMsg(msg)
    local msgType = msg.type

    if msgType == SglMsgType_pb.PB_TYPE_RANK_LEVEL or
       msgType == SglMsgType_pb.PB_TYPE_RANK_POWER or
       msgType == SglMsgType_pb.PB_TYPE_RANK_STAR or
       msgType == SglMsgType_pb.PB_TYPE_RANK_TROPHY or
       msgType == SglMsgType_pb.PB_TYPE_RANK_UNION_LEVEL or
       msgType == SglMsgType_pb.PB_TYPE_RANK_BOSS or
       msgType == SglMsgType_pb.PB_TYPE_RANK_UBOSS_SCORE or
       msgType == SglMsgType_pb.PB_TYPE_RANK_UBOSS_TIME or
       msgType == SglMsgType_pb.PB_TYPE_RANK_LADDER or
       msgType == SglMsgType_pb.PB_TYPE_RANK_LADDER_EX or
       msgType == SglMsgType_pb.PB_TYPE_RANK_CHAR_LEVEL or 
       msgType == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM or 
       msgType == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP or
       msgType == SglMsgType_pb.PB_TYPE_RANK_DARK or
       msgType == SglMsgType_pb.PB_TYPE_RANK_DARK_PRE or
       msgType == SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY then

        local data, subType = msg.Extensions[Rank_pb.SglRankMsg.rank_list_resp]
        if msgType == SglMsgType_pb.PB_TYPE_RANK_UBOSS_SCORE or msgType == SglMsgType_pb.PB_TYPE_RANK_UBOSS_TIME then
            subType = msg.Extensions[Rank_pb.SglRankMsg.rank_uboss_resp]
        elseif msgType == SglMsgType_pb.PB_TYPE_RANK_LADDER then
            subType = msg.Extensions[Rank_pb.SglRankMsg.rank_ladder_resp]
        elseif msgType == SglMsgType_pb.PB_TYPE_RANK_CHAR_LEVEL then
            subType = msg.Extensions[Rank_pb.SglRankMsg.rank_char_resp]
        end

        self:parseRankData(data, msgType, subType)
        return true
    elseif msgType == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE then
        local ranks = msg.Extensions[Rank_pb.SglRankMsg.rank_top_team_mvp_resp].ranks
        self:parseRankData(ranks[1], SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM, nil)
        self:parseRankData(ranks[2], SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_MVP, nil)
        return true
    end
   
    return false
end

return _M
