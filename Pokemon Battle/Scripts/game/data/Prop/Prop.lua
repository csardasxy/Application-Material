local _M = class("Prop")

function _M:ctor(infoId, pbProp)
    self._infoId = infoId
    self._info = Data._propsInfo[infoId]
    
    if pbProp ~= nil then
        self._num = pbProp.num
    else
        self._num = 0
    end
end

function _M:getQuality()
    return self._info._quality
end

function _M:sendPropDirty()
    if self._infoId >= 7201 and self._infoId <= 7206 then
        if P._crown == nil or self._infoId <= P._crown._infoId then
            P._crown = {_infoId = self._infoId, _num = self._num}
            
            local eventCustom = cc.EventCustom:new(Data.Event.crown_dirty)
            eventCustom._data = self
            lc.Dispatcher:dispatchEvent(eventCustom)
        end

    elseif self._infoId >= 7213 and self._infoId <= 7215 then
        local eventCustom = cc.EventCustom:new(Data.Event.crown_dirty)
        eventCustom._data = self
        lc.Dispatcher:dispatchEvent(eventCustom)

    else
        local eventCustom = cc.EventCustom:new(Data.Event.prop_dirty)
        eventCustom._data = self
        lc.Dispatcher:dispatchEvent(eventCustom)
    end
end

return _M
