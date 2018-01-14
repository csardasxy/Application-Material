local _M = class("PropProp")
local Prop = require "Prop"

function _M:ctor()
    self._props = {}
end

function _M:clear()
    self._props = {}
end

function _M:init(pbProp)
    for k, v in pairs(Data._propsInfo) do
        local prop = Prop.new(k)
        self._props[prop._infoId] = prop
    end

    local props = pbProp.props
    for i = 1, #props do
        local prop = self._props[props[i].info_id]
        if prop then  
            prop._num = props[i].num
        end
    end

    local chests = pbProp.chests
    for i = 1, #chests do
        local prop = self._props[chests[i].id]
        if prop then
            prop._isOpened = chests[i].opened
            prop._num = 1
        end
    end

    local crowns = pbProp.crowns
    for i = 1, #crowns do
        local prop = self._props[crowns[i].info_id]
        if prop then
            prop._num = crowns[i].num
        end
    end
end

function _M:hasProps(propId, delta)
    if self._props[propId] ~= nil and self._props[propId]._num >= delta then
        return true
    end
    
    return false
end

function _M:changeProps(propId, delta)
    local prop = self._props[propId]
    if prop then
        if delta == 0 then
            return true
        end

        local num = prop._num + delta
        if num >= 0 then
            prop._num = num
            prop:sendPropDirty()
            return true
        end
    end
    
    return false
end

function _M:setProps(propId, number)
    local prop = self._props[propId]
    if prop then
        prop._num = number
        prop:sendPropDirty()
    end
end

function _M:useProp(prop, number)
    local num = number or 1
    if self:hasProps(prop._infoId, num) then
        self:changeProps(prop._infoId, -num)
        return Data.ErrorType.ok
    end

    return Data.ErrorType.error
end

function _M:validPropId(infoId, isSelf)
    local baseId, id

    local getValidId = function(baseId, count)
        for i = count, 1, -1 do
            if self._props[baseId + i]._num > 0 then
                return baseId + i
            end
        end
    end

    if infoId == Data.PropsId.avatar_frame_level_rank or
       infoId == Data.PropsId.avatar_frame_level_rank1 or
       infoId == Data.PropsId.avatar_frame_level_rank2 or
       infoId == Data.PropsId.avatar_frame_level_rank3 then
        baseId = Data.PropsId.avatar_frame_level_rank

        if isSelf then
            id = getValidId(baseId, 3)
        end

    elseif infoId == Data.PropsId.avatar_frame_xmas or
           infoId == Data.PropsId.avatar_frame_xmas_1 or
           infoId == Data.PropsId.avatar_frame_xmas_2 then
        if infoId == Data.PropsId.avatar_frame_xmas_2 then
            baseId = Data.PropsId.avatar_frame_xmas_1
        else
            baseId = infoId
        end

        if isSelf then
            id = getValidId(Data.PropsId.avatar_frame_xmas, 2)
        end
    else
        baseId, id = infoId, infoId
    end

    return baseId, id or infoId
end

return _M
