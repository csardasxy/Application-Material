local _M = class("User")

_M.Users = {}

function _M.create(pbUser, isCache)
    local user
    if isCache and _M.Users[pbUser.id] ~= nil then
        user = _M.Users[pbUser.id]
    else
        user = _M.new(pbUser.id)
    end
    
    user._name = pbUser.name
    user._gold = pbUser.gold
    user._grain = pbUser.grain
    user._ingot = pbUser.ingot
    user._level = pbUser.level
    user._avatar = pbUser.avatar
    user._avatarImage = pbUser.avatar_image
    user._exp = pbUser.exp
    user._trophy = pbUser.trophy
    user._vip = pbUser.vip
    user._shield = pbUser.shield
    user._unionId = pbUser.union_id
    user._unionName = pbUser.union_name
    user._unionJob = pbUser.union_title
    user._unionBadge = pbUser.union_avatar
    user._unionWord = pbUser.union_tag
    user._lastLogin = pbUser.last_login / 1000
    user._regionId = pbUser.rid
    if pbUser:HasField('crown') then
        user._crown = {_infoId = pbUser.crown.info_id, _num = pbUser.crown.num}
    end
    if pbUser:HasField('avatar_frame_count') then
        user._avatarFrameCount = pbUser.avatar_frame_count
    end
    
    if pbUser:HasField('mass_war_score') then
        user._massWarScore = pbUser.mass_war_score
    end

    user._avatarFrameId = pbUser.avatar_frame
    if user._avatarFrameId == 0 then
        user._avatarFrameId = Data.PropsId.avatar_frame
    end

    return user     
end

function _M.createNpc()
    local user = _M.new(0)
    user._name = Str(STR.NPC_NAME)    
    user._level = 1
    user._vip = 0
    user._unionId = 0
    user._avatar = 0
    user._avatarFrameId = Data.PropsId.avatar_frame
    return user
end

function _M:ctor(id)
    self._id = id
    _M.Users[id] = self 
end

function _M:getTitle()
    for i = 1, #Data._globalInfo._playerTitleTrophy do
        if i < #Data._globalInfo._playerTitleTrophy then
            if self._trophy >= Data._globalInfo._playerTitleTrophy[i] and self._trophy < Data._globalInfo._playerTitleTrophy[i + 1] then
                return i
            end
        else
            if self._trophy >= Data._globalInfo._playerTitleTrophy[i] then
                return i
            end
        end
    end
end

function _M:getGrainCapacity()
    local level = self._level
    if level > #Data._globalInfo._grainCapacity then
        level = #Data._globalInfo._grainCapacity
    end
    
    return Data._globalInfo._grainCapacity[level]
end

function _M:sendUserDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.user_dirty)
    eventCustom._data = self
    lc.Dispatcher:dispatchEvent(eventCustom)        
end

return _M
