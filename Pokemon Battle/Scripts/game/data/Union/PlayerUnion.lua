local _M = class("PlayerUnion")

_M.Operate = 
{
    exit_union          = 101,
    buy_product         = 102,
    contribute_gold     = 103,
    contribute_wood     = 104,
    send_message        = 105,
    refresh_store       = 106,
    give_fund           = 107,
    impeach             = 108,

    fire_member         = 201,
    agree_user          = 202,
    refuse_user         = 203,
    launch_battle       = 204,
    cancel_battle       = 205,
    invite_user         = 206,
    edit                = 207,
    upgrade             = 208,
    view_contribute     = 209,
    view_activity       = 210,
    upgrade_tech        = 212,

    set_job             = 301,
    give_leader         = 302
}

function _M:ctor()
    self._searchUnions = {}
    self._recommandUnions = {}
    self._myActivityPoint = 0
    self._groupId = nil
    self._groupJob = nil
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    self._searchUnions = {}
    self._recommandUnions = {} 

    self._hireMembers = {}
    self._myHires = {}

    self._hiredHero = nil
    self._lastHireTimestamp = nil
    self:stopHireSchedule()

    if self._myUnion then
        self._myUnion:clear()
        self._myUnion = nil

        self._hasDetailInfo = nil
    end

    self._nextRefreshTime = nil
    P._playerMarket:clearUnionMarket()

    self._myGroup = nil
    self._groupId = nil
    self._groupJob = nil
    self._isSyncData = nil
end

function _M:initBase(pbUnionMini)
    self:clear()

    self:initMyUnion(pbUnionMini.info, pbUnionMini.techs)
    self:init(pbUnionMini.data)
end

function _M:init(pbUnion)
    self._nextRefreshTime = pbUnion.next_refresh / 1000
    P._playerMarket:initProducts(pbUnion.bundles, Data.MarketBuyType.union)

    -- Heroes hired from other memebers
    self._hireMembers = {}
    if #pbUnion.rented > 0 then
        for _, userId in ipairs(pbUnion.rented) do
            table.insert(self._hireMembers, userId)
        end
    end

    self._techs = {}
    for k, v in pairs(Data._unionTechInfo) do
        self._techs[k] = require("UnionTech").new(k)
        self._techs[k]._isSelf = true
    end

    if #pbUnion.techs > 0 then
        for _, tech in ipairs(pbUnion.techs) do
            self._techs[tech.id]:update(tech)
        end
    end

    if #pbUnion.cards > 0 then
        self._hiredHero = require("HireHero").new(pbUnion)
        self._lastHireTimestamp = pbUnion.last_rent / 1000
        self._lastHireSpan = (Data._globalInfo._unionRentTime + self:getTechVal(Data.UnionTechId.lord_hired)) * 60
        
        self:startHireSchedule()
    else
        self._hiredHero = nil
        self._lastHireTimestamp = nil
        self:stopHireSchedule()
    end

    self._groupId = pbUnion:HasField("team_info") and pbUnion.team_info.id or nil
    self._battleTrophy = pbUnion:HasField("team_info") and pbUnion.team_info.masswar_score or 500
end

function _M:initMyUnion(pbUnionMine, pbTechs)
    local detail, union = pbUnionMine.detail
    if detail then
        if detail.union_info.id == P._unionId then
            union = require("Union").create(detail.union_info, detail.member_info, pbUnionMine)
            self._hasDetailInfo = true
        end
    else
        -- pbUnionMine is equal to union_info
        if pbUnionMine.id == P._unionId then
            union = require("Union").create(pbUnionMine)
        end
    end

    if union then
        self._myUnion = union

        -- Set easy to access
        P._unionName = union._name
        P._unionBadge = union._badge
        P._unionWord = union._word
        P._unionType = union._joinType

        -- Heroes of mine in the hire center
        self._myHires = {}
        for _, hero in pairs(union._hires) do
            if hero:isSelfCard() then
                table.insert(self._myHires, hero)
            end
        end

        if pbTechs then
            union:updateTechs(pbTechs)
        end

        union:sendUnionDirty()
        union:sendUnionResDirty()
    end
end

function _M:getMyUnion()
    return self._myUnion
end

function _M:getMyGroup()
--    self._groupId = 2
--    self._groupJob = Data.GroupJob.leader
--    self._myGroup = require("Group").create({_id = 2, _members = {P}})
    return self._myGroup
end

function _M:getGroups()
--    self._groups = {}
--    self._groups[1] = require("Group").create({_id = 1, _members = {P}})
--    self._groups[2] = require("Group").create({_id = 2, _members = {P}})
--    self._groups[3] = require("Group").create({_id = 3, _members = {P}})
--    self._groups[40] = require("Group").create({_id = 40, _members = {P}})
--    self._groups[5] = require("Group").create({_id = 5, _members = {P}})
--    self._groups[6] = require("Group").create({_id = 6, _members = {P}})

    return self._groups
end

function _M:canLottery()
    local lotteryTimes = math.floor(self._myUnion._energy / 100)
    
    return lotteryTimes > P._unionLottery
end

function _M:addMember(user)
    local union = self._myUnion
    if union then
        union:addMember(user)
    end
end

function _M:removeMember(userId, isKickout)
    local union = self._myUnion
    if union then
        union:removeMember(userId)

        if userId == P._id then
            P._unionId = 0
            P._playerMessage:clearUnion()

            -- invalid union fund
            P:setUnionFundValid(false)
            lc.sendEvent(Data.Event.union_fund_dirty)

            self:clear()
            self:sendExitUnionDirty()

            if isKickout then
                ToastManager.push(Str(STR.UNION_BE_KICKED_OUT))
            end
        else
            union._impeach[userId] = nil
        end
    end
end

function _M:upgrade(isTry)
    local union = self._myUnion
    if union then
        if isTry then
--            if union._gold < union:getLevelupGold() then
--                return Data.ErrorType.need_more_union_gold
--            end

--            if union._wood < union:getLevelupWood() then
--                return Data.ErrorType.need_more_union_wood
--            end
            if union._level>=#Data._globalInfo._unionLevel then
                return Data.ErrorType.union_level_max
            end
            if union._act < union:getLevelupAct() then
                return Data.ErrorType.need_more_union_act
            end
        else
            union:upgrade()

            lc.sendEvent(Data.Event.union_level_upgrade)
        end
    
        return Data.ErrorType.ok
    end
end

function _M:upgradeTech(techId)
    local tech = self._techs[techId]
    local yubi = tech:getUpgradeYubi()

    if P:getItemCount(Data.PropsId.yubi) < yubi then
        return Data.ErrorType.need_more_yubi
    end

    P._propBag:changeProps(Data.PropsId.yubi, -yubi)
    tech._level = tech._level + 1

    lc.sendEvent(Data.Event.union_tech_dirty, tech)
    
    if techId == Data.UnionTechId.lord_hired then
        if self._hiredHero then
            self._lastHireSpan = (Data._globalInfo._unionRentTime + self:getTechVal(techId)) * 60
        end
    end

    return Data.ErrorType.ok
end

function _M:getTech(techId)
    local union = self._myUnion
    if union then
        local tech = self._techs[techId]
        local level = math.min(tech._level, union._techs[techId]._level)

        return tech, level
    end

    return nil
end

function _M:getTechVal(techId)
    local tech, techLevel = self:getTech(techId)
    return tech and tech._info._val[techLevel] or 0
end

function _M:addMyHire(hero)
    local hire = require("HireHero").addHire(hero)
    table.insert(self._myHires, hire)
    return #self._myHires
end

function _M:removeMyHire(index)
    if self._myHires == nil or index > #self._myHires then return end

    table.remove(self._myHires, index)
    return #self._myHires
end

function _M:hire(hire)
    table.insert(self._hireMembers, hire._ownerId)
    hire._isHired = true

    -- Set all cards of this owner to "hired"
    self._myUnion:setAllHired(hire._ownerId)

    self._hiredHero = hire
    self._lastHireTimestamp = ClientData.getCurrentTime()
    self._lastHireSpan = (Data._globalInfo._unionRentTime + self:getTechVal(Data.UnionTechId.lord_hired)) * 60
    self:startHireSchedule()
end

function _M:startHireSchedule()
    self:stopHireSchedule()

    self._hireSchedulerId = lc.Scheduler:scheduleScriptFunc(function(dt)
        local finishTime = self._lastHireTimestamp + self._lastHireSpan
        if ClientData.getCurrentTime() >= finishTime then
            self._hiredHero = nil
            self._lastHireTimestamp = nil
            self:stopHireSchedule()
        end
    end, 1, false)
end

function _M:stopHireSchedule()
    if self._hireSchedulerId then
        lc.Scheduler:unscheduleScriptEntry(self._hireSchedulerId)
        self._hireSchedulerId = nil
    end
end

function _M:canOperate(operate)
    if P._unionId > 0 then
        local job = math.floor(operate / 100)
        if P._unionJob >= job then
            return Data.ErrorType.ok
        end

        if job == Data.UnionJob.leader then
            return Data.ErrorType.leader_operate
        elseif job == Data.UnionJob.elder then
            return Data.ErrorType.elder_operate
        elseif job == Data.UnionJob.rookie then
            return Data.ErrorType.rookie_operate
        end
    end
     
    return Data.ErrorType.union_operate
end

function _M:getSearchUnions()
    local unions = {}
    for k, v in pairs(self._searchUnions) do
        table.insert(unions, v)
    end
    
    return unions
end

function _M:getRecommandUnions()
    local unions = {}
    for k, v in pairs(self._recommandUnions) do
        table.insert(unions, v)
    end
    
    return unions
end

function _M:getMaxResource(resType)
    local union = self._myUnion
    if union == nil then return 0 end
    
    if resType == Data.ResType.union_gold then
        return Data._globalInfo._unionMaxGold[union._level]

    elseif resType == Data.ResType.union_wood then
        return Data._globalInfo._unionMaxWood[union._level]

    elseif resType == Data.ResType.union_act then
        return Data._globalInfo._unionLevelupExp[union._level]

    end
end

function _M:isReachMaxResource(resType, delta)
    local union = self._myUnion
    if union == nil then return true end
    
    if resType == Data.ResType.union_gold then
        return union._gold + delta > Data._globalInfo._unionMaxGold[union._level]

    elseif resType == Data.ResType.union_wood then
        return union._wood + delta > Data._globalInfo._unionMaxWood[union._level]

    end
end

function _M:changeResource(resType, delta)
    local union = self._myUnion
    if union == nil then return end
    
    if resType == Data.ResType.union_gold then
        local max = self:getMaxResource(resType)
        local gold = union._gold + delta
        if gold >= 0 then
            if gold > max then gold = max end

            union._gold = gold
            union:sendUnionResDirty(resType)
        end

    elseif resType == Data.ResType.union_wood then
        local max = self:getMaxResource(resType)
        local wood = union._wood + delta
        if wood >= 0 then
            if wood > max then wood = max end

            union._wood = wood
            union:sendUnionResDirty(resType)
        end

    elseif resType == Data.ResType.union_act then
        local act = union._act + delta
        if act >= 0 then
            union._act = act
            union:sendUnionResDirty(resType)
            if self:upgrade(true)==Data.ErrorType.ok then
                self:upgrade(false)
            end
        end
    
    
    end
end

function _M:sendSearchUnionsDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.union_search_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendRecommandUnionsDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.union_recommand_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)    
end

function _M:sendEnterUnionDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.union_enter_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendExitUnionDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.union_exit_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendEditUnionDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.union_edit_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)    
end

----------------------------- socket receive --------------------------------------
function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == SglMsgType_pb.PB_TYPE_UNION_MINE then
        local resp = msg.Extensions[Union_pb.SglUnionMsg.union_mine_resp]
        self:initMyUnion(resp)

        ClientData._unionLogs = nil
           
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_EDIT then
        ToastManager.push(Str(STR.SUCCESS)..Str(STR.CHANGE)..Str(STR.UNION)..Str(STR.INFO))
        self:sendEditUnionDirty()
    
        return true
       
    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_CREATE then        
        local union = msg.Extensions[Union_pb.SglUnionMsg.union_create_resp]
        P._unionId = union.info.id
        P._unionJob = Data.UnionJob.leader        

        if P:getItemCount(Data.PropsId.union_create) > 0 then
            P:addResource(Data.PropsId.union_create, 1, -1)
        else
            P:changeResource(Data.ResType.ingot, -Data._globalInfo._createUnionIngot)
        end
            
        self:initBase(union)
        self:sendEnterUnionDirty()
    
        return true
                    
    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_JOIN then        
        local union = msg.Extensions[Union_pb.SglUnionMsg.union_join_resp]
        P._unionId = union.info.id
        P._unionJob = Data.UnionJob.rookie

        self:initBase(union)
        self:sendEnterUnionDirty()
            
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_LEAVE or msgType == SglMsgType_pb.PB_TYPE_UNION_KICKOUT then
        self:removeMember(P._id, msgType == SglMsgType_pb.PB_TYPE_UNION_KICKOUT)

        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_SEARCH then
        self._searchUnions = {}
       
        local resp = msg.Extensions[Union_pb.SglUnionMsg.union_search_resp]
        for i = 1, #resp do
            local union = require("Union").create(resp[i])
            if union then
                self._searchUnions[union._id] = union
            end
        end
        self:sendSearchUnionsDirty()
        
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_RECOMMEND then
        self._recommandUnions = {}
        
        local resp = msg.Extensions[Union_pb.SglUnionMsg.union_recommend_resp]
        for i = 1, #resp do
            local union = require("Union").create(resp[i])
            if union then
                self._recommandUnions[union._id] = union
            end
        end
        self:sendRecommandUnionsDirty()

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_REFRESH or msgType == SglMsgType_pb.PB_TYPE_UNION_REFRESH_EX then
        local resp = msg.Extensions[Union_pb.SglUnionMsg.union_refresh_resp]
        self:init(resp)
                
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_LET then
        local union = self._myUnion
        if union then
            local resp = msg.Extensions[Union_pb.SglUnionMsg.union_let_resp]
            local hero = union:addHire(resp)
            lc.sendEvent(Data.Event.union_hires_dirty)

            -- check and update my hire guid
            if hero:isSelfCard() then
                for i, myHire in ipairs(self._myHires) do
                    if myHire._infoId == hero._infoId then
                        myHire._guid = hero._guid
                        break
                    end
                end
            end
        end

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_UNLET then
        local union = self._myUnion
        if union then
            local guid = msg.Extensions[Union_pb.SglUnionMsg.union_unlet_resp]
            if union._hires[guid] then
                union._hires[guid] = nil
                lc.sendEvent(Data.Event.union_hires_dirty)
            end
        end

    elseif msgType == SglMsgType_pb.PB_TYPE_USER_FUND_GIVEN then
        P:givenUnionFund()
        lc.sendEvent(Data.Event.union_fund_dirty)

    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_MESSAGE then
        local union = self._myUnion
        if union then
            local changeJob = function(userId, job)
                local user = union:findMember(userId)
                if user then
                    user._unionJob = job
                    if P._id == userId then
                        P._unionJob = job
                    end
                    user:sendUserDirty()
                end
            end

            local pbMsgs = msg.Extensions[Union_pb.SglUnionMsg.union_message_resp]
            for _, pbMsg in ipairs(pbMsgs) do
                local action, user1Id, user2Id = pbMsg.type, pbMsg.user1.id
                if pbMsg:HasField("user2") then user2Id = pbMsg.user2.id end
                if action == Union_pb.PB_UNION_JOIN then
                    self:addMember(require("User").create(pbMsg.user1))

                elseif action == Union_pb.PB_UNION_KICKOUT then
                    self:removeMember(user2Id)

                    if user1Id == P._id then
                        ToastManager.push(Str(STR.UNION_KICKOUT_SUCCESS))
                    end

                elseif action == Union_pb.PB_UNION_LEAVE then
                    self:removeMember(user1Id)

                elseif action == Union_pb.PB_UNION_TO_MEMBER or action == Union_pb.PB_UNION_TO_CO_LEADER then
                    changeJob(user2Id, pbMsg.user2.union_title)

                    if user1Id == P._id then
                        ToastManager.push(Str(STR.CHANGE_JOB_SUCCESS))
                    end

                elseif action == Union_pb.PB_UNION_TO_LEADER then 
                    changeJob(user1Id, pbMsg.user1.union_title)
                    union._impeach = {}

                elseif action == Union_pb.PB_UNION_RESIGN then
                    changeJob(user1Id, pbMsg.user1.union_title)
                    changeJob(user2Id, pbMsg.user2.union_title)
                    union._impeach = {}

                elseif action == Union_pb.PB_UNION_UPGRADE then
                    self:upgrade()

                    if user1Id == P._id then
                        require("LevelUpPanel").createUnion(union._level - 1, union._level):show()
                    end

                elseif action == Union_pb.PB_UNION_TECH_UPGRADE then
                    local tech = union._techs[pbMsg.param2]
                    union:upgradeTech(tech._infoId)

                    -- Self tech maybe change level
                    local selfTech = self._techs[pbMsg.param2]
                    lc.sendEvent(Data.Event.union_tech_dirty, selfTech)

                    if user1Id == P._id then
                        ToastManager.push(string.format(Str(STR.UNION_TECH_UPGRADE_SUCCESS), Str(tech._info._nameSid), pbMsg.param1))
                        lc.sendEvent(Data.Event.union_tech_upgrade, tech)
                    end

                elseif action == Union_pb.PB_UNION_IMPEACH then
                    union._impeach[user1Id] = true

                elseif action == Union_pb.PB_UNION_UNIMPEACH then
                    union._impeach[user1Id] = nil

                elseif action == Union_pb.PB_UNION_IMPEACHED then
                    changeJob(user1Id, pbMsg.user1.union_title)

                elseif action == Union_pb.PB_UNION_ADD_EXP then
                    local resources = pbMsg.resource
                    for _,v in ipairs(resources) do
                        self:changeResource(v._infoId, v._num)
                    end

                end
            end
        end
    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_MASSWAR_PRE then
        self._isSyncData = true
        local resp = msg.Extensions[World_pb.SglWorldMsg.world_user_id_resp]
        lc.sendEvent(Data.Event.union_battle_ready)

        return true
    elseif msgType == SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_QUERY_INFO then
        local resp = msg.Extensions[UnionWar_pb.SglUnionWarMsg.masswar_team_list_resp]
        self:initGroups(resp)
        lc.sendEvent(Data.Event.union_group_dirty)

    elseif msgType == SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_CREATE_TEAM then
        V.getActiveIndicator():hide()
        local resp = msg.Extensions[UnionWar_pb.SglUnionWarMsg.masswar_team_list_resp]
        self:initGroups(resp)
        lc.sendEvent(Data.Event.union_group_dirty)

    elseif msgType == SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_START then
        V.getActiveIndicator():hide()
        local resp = msg.Extensions[UnionWar_pb.SglUnionWarMsg.masswar_team_list_resp]
        self:initGroups(resp)
        lc.sendEvent(Data.Event.union_group_dirty)

    elseif msgType == SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_QUIT_TEAM then
        V.getActiveIndicator():hide()
        self._groupId = nil
        self._groupJob = nil
        self._myGroup = nil
        lc.sendEvent(Data.Event.union_group_dirty)
    end

    return false
end

function _M:createGroup(name, avatar)
    ClientData.sendCreateGroup(name, avatar)
end

function _M:joinGroup(groupId)
    ClientData.sendGroupJoin(groupId)
end

function _M:exitGroup()
    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendExitGroup(self._groupId)
end

function _M:initGroups(info)
    self._groups = {}
    self._myGroup = nil
    self._groupId = nil
    self._groupJob = nil
    local union = self:getMyUnion()
    if not union then return end
    local groupInfos = info.teams
    for i = 1, #groupInfos do
        local isMine = false
        local myIndex
        local memInfos = groupInfos[i].user_info
        local mems = {}
        for j = 1,  #memInfos do
            local memInfo = memInfos[j]
            if memInfo.id == P._id then
                isMine = true
                myIndex = j
            end
            table.insert(mems, require("User").create(memInfo))
        end
        local group = require("Group").create({_members = mems, _pb = groupInfos[i]})
        self._groups[group._id] = group
        if isMine then
            self._myGroup = group
            self._groupId = group._id
            if myIndex == 1 then
                self._groupJob = Data.GroupJob.leader
            else
                self._groupJob = Data.GroupJob.rookie
            end
        end
    end
end

function _M:getUnionUpgradeExp()
    local union = self._myUnion
    local isMax = false
    local exp = -1
    if union._level >= self:getUnionMaxLevel() then
        isMax = true
    else
        exp = Data._globalInfo._unionLevelupExp[union._level+1] - union._act
    end
    return isMax,exp
end

function _M:getUnionMaxLevel()
    return #Data._globalInfo._unionLevelupExp
end

return _M
