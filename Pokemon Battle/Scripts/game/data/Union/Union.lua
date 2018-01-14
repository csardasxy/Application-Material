local _M = class("Union")

_M.Unions = {}

function _M.create(pbUnionInfo, pbMemberInfo, pbUnionMine)
    if pbUnionInfo.member == 0 then
        return nil
    end

    local union
    if _M.Unions[pbUnionInfo.id] then
        union = _M.Unions[pbUnionInfo.id]
    else
        union = _M.new(pbUnionInfo.id)
        union._members = {}
        union._dailyContributes = {}
        union._weeklyContributes = {}
        union._dailyActivePoints = {}
        union._hires = {}
        union._bosses = {}
        union._techs = {}
        union._impeach = {}
    end
    
    union:updateInfo(pbUnionInfo, pbUnionMine ~= nil)

    if pbMemberInfo then
        if pbMemberInfo then
            for _, mem in ipairs(pbMemberInfo) do
                local user = require("User").create(mem, true)
                union._members[user._id] = user
            end
        end
    end

    if pbUnionMine then
        local weeklyDonates, dailyDonates = pbUnionMine.weekly_donates, pbUnionMine.daily_donates
        if weeklyDonates and dailyDonates then
            local weekly = union._weeklyContributes
            for _, donate in ipairs(weeklyDonates) do
--                weekly[donate.id] = union:genContribution(donate.gold, donate.wood, donate.exp)
                weekly[donate.id] = union:genContribution(donate.exp)
            end

            local daily = union._dailyContributes
            for _, donate in ipairs(dailyDonates) do
--                daily[donate.id] = union:genContribution(donate.gold, donate.wood, donate.exp)
                daily[donate.id] = union:genContribution(donate.exp)
            end

            local active = union._dailyActivePoints
            for _, point in ipairs(dailyDonates) do
                active[point.id] = union:genActivePoint(point.power)
                if P._id==point.id then
                    P._playerUnion._myActivityPoint = point.power
                end
            end
        end

        local hires = pbUnionMine.lets
        if hires then
            for _, hire in ipairs(hires) do
                union:addHire(hire)
            end
        end

        union:updateTechs(pbUnionMine.data.techs)
        union:updateImpeach(pbUnionMine.impeaches)

        local props = pbUnionMine.data.props
        if props then
            for _, prop in ipairs(props) do
                P._propBag:setProps(prop.info_id, prop.num)
            end
        end
    end
    
    return union
end

function _M:ctor(id)
    self._id = id
    _M.Unions[id] = self
end

function _M:clear()
    _M.Unions[self._id] = nil
end

function _M:updateInfo(pbUnionInfo, isMine)
    self._id = pbUnionInfo.id
    self._name = pbUnionInfo.name
    self._level = pbUnionInfo.level
    self._reqLevel = pbUnionInfo.required_level
    self._joinType = pbUnionInfo.type
    self._badge = pbUnionInfo.avatar
    self._word = pbUnionInfo.tag
    self._memberNum = pbUnionInfo.member
    self._memberCapacity = 20+2*(self._level-1)
    self._announce = pbUnionInfo.announcement or ""

    if isMine then
        self._gold = pbUnionInfo.gold
        self._wood = pbUnionInfo.wood
        self._act = pbUnionInfo.exp or 0             -- exp represents the activity
    end
end

function _M:updateTechs(pbTechs)
    if pbTechs then
        for k, v in pairs(Data._unionTechInfo) do
            self:addTech(k)
        end

        for _, techData in ipairs(pbTechs) do
            local tech = self._techs[techData.id]
            tech:update(techData)
        end

        -- Check lock status
        for k, v in pairs(self._techs) do
            if v._level == 0 then
                if v._info._unlockLevel <= self._level then
                    v._level = 1
                end
            else
                if v._info._unlockLevel > self._level then
                    v._level = 0
                end
            end
        end
    end
end

function _M:updateImpeach(pbImpeaches)
    if pbImpeaches then
        self._impeach = {}
        for _, id in ipairs(pbImpeaches) do
            if self._members[id] then
               self._impeach[id] = true
            end
        end
    end
end

function _M:addHire(hire)
    local hero = require("HireHero").new(hire)
    self._hires[hero._guid] = hero
    return hero
end

function _M:setAllHired(ownerId)
    for _, hire in pairs(self._hires) do
        if hire._ownerId == ownerId then
            hire._isHired = true
        end
    end
end

function _M:genContribution(--[[gold, wood, ]]act)
--    return {[Data.ResType.union_gold] = gold or 0, [Data.ResType.union_wood] = wood or 0, [Data.ResType.union_act] = act or 0}
    return {[Data.ResType.union_act] = act or 0}
end

function _M:genActivePoint(point)
    return {[Data.ResType.union_personal_power] = point or 0}
end

function _M:contribute(userId, resType, resVal)
    local daily, weekly = self:getContribution(userId)
    daily[resType] = daily[resType] + resVal
    weekly[resType] = weekly[resType] + resVal
end

function _M:getActivePoint(userId)
    local daily = self._dailyActivePoints[userId]
    if daily == nil then
        daily = self:genActivePoint()
        self._dailyActivePoints[userId] = daily
    end
    return daily
end

function _M:getContribution(userId)
    local daily = self._dailyContributes[userId]
    if daily == nil then
        daily = self:genContribution()
        self._dailyContributes[userId] = daily
    end

    local weekly = self._weeklyContributes[userId]
    if weekly == nil then
        weekly = self:genContribution()
        self._weeklyContributes[userId] = weekly
    end

    return daily, weekly
end

function _M:getMembersNum()
    return self._memberNum
end

function _M:getMembers()
    local members = {}
    if self._members ~= nil then
        for k, v in pairs(self._members) do
            table.insert(members, v)
        end
    end
    
    return members
end

function _M:addMember(user)
    if self._members[user._id] == nil then
        self._members[user._id] = user
        self._memberNum = self._memberNum + 1
        lc.sendEvent(Data.Event.union_member_dirty)
    end
end

function _M:removeMember(userId)
    if self._members[userId] then
        self._members[userId] = nil
        self._memberNum = self._memberNum - 1

        -- remove hire heroes
        local isHireDirty
        for _, hire in pairs(self._hires) do
            if hire._ownerId == userId then
                self._hires[hire._guid] = nil
                isHireDirty = true
            end
        end

        if isHireDirty then
            lc.sendEvent(Data.Event.union_hires_dirty)
        end

        lc.sendEvent(Data.Event.union_member_dirty)
    end
end

function _M:findMember(id)
    if self._members == nil then return nil end
    return self._members[id]
end

function _M:getMaxLevel()
    return #Data._globalInfo._unionLevelupExp
end

function _M:upgrade()
    if self._act then
--        self._gold = self._gold - self:getLevelupGold()
--        self._wood = self._wood - self:getLevelupWood()
        self._act = self._act - self:getLevelupAct()

        self:sendUnionResDirty()
    end

    self._level = self._level + 1
    self._memberCapacity = self._memberCapacity<28 and self._memberCapacity+2 or 30

    -- check union tech
--    for _, tech in pairs(self._techs) do
--        if tech._info._unlockLevel <= self._level and tech._level == 0 then
--            tech._level = 1
--        end
--    end
end

function _M:getLevelupGold()
    return Data._globalInfo._unionLevelupGold[self._level + 1]
end

function _M:getLevelupWood()
    return Data._globalInfo._unionLevelupWood[self._level + 1]
end

function _M:getLevelupAct()
    return Data._globalInfo._unionLevelupExp[self._level + 1]
end

function _M:addTech(techId)
    local tech = require("UnionTech").new(techId)
    self._techs[techId] = tech
    return tech
end

function _M:upgradeTech(techId, isTry)
    local tech = self._techs[techId]
    local gold, wood, techRes = tech:getUpgradeRes()

    if isTry then
        if self._gold < gold then
            return Data.ErrorType.need_more_union_gold
        end
       
        if self._wood < wood then
            return Data.ErrorType.need_more_union_wood
        end

        if P:getItemCount(tech._info._updateUnionBook) < techRes then
            return Data.ErrorType.need_more_union_tech_res
        end
    else
        if self._gold then
            self._gold = self._gold - gold
            self._wood = self._wood - wood
        end

        P._propBag:changeProps(tech._info._updateUnionBook, -techRes)
        tech._level = tech._level + 1

        lc.sendEvent(Data.Event.union_tech_dirty, tech)
    end
    
    return Data.ErrorType.ok
end

function _M:sendUnionDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.union_dirty)
    eventCustom._data = self
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendUnionResDirty(infoId)
    local eventCustom = cc.EventCustom:new(Data.Event.union_res_dirty)
    eventCustom._infoId = infoId
    lc.Dispatcher:dispatchEvent(eventCustom)  
end

return _M
