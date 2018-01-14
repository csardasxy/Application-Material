local _M = class("Fixity")

function _M:ctor(infoId)    
    self._infoId = infoId
    self._info = Data._fixityInfo[self._infoId]    
    self._isLock = false
    
    if self._infoId == Data.FixityId.farmland or self._infoId == Data.FixityId.residence then
        self._remainRes = 0
    elseif self._infoId == Data.FixityId.guard then
        self._guards = {}
    end
end

function _M:getRes(dt)                
    if dt < 0 then dt = 0 end

    local resNumber = 0    
    if self._infoId == Data.FixityId.residence then
        resNumber = math.floor(dt * Data._globalInfo._residenceCapacity / (Data._globalInfo._residenceResumeTime * 60) + self._remainRes)
        if resNumber > Data._globalInfo._residenceCapacity then resNumber = Data._globalInfo._residenceCapacity end 
    elseif self._infoId == Data.FixityId.farmland then
        resNumber = math.floor(dt * Data._globalInfo._farmlandCapacity / (Data._globalInfo._farmlandResumeTime * 60) + self._remainRes)
        if resNumber > Data._globalInfo._farmlandCapacity then resNumber = Data._globalInfo._farmlandCapacity end
    end
    
    return resNumber
end

function _M:clearRes(remain)
    if self._infoId ~= Data.FixityId.farmland and self._infoId ~= Data.FixityId.residence then
        return
    end

    if remain == nil or remain < 0 then 
        self._remainRes = 0 
    else
        self._remainRes = remain
    end
end

function _M:getFullGrainTimestamp()
    return (Data._globalInfo._farmlandCapacity - self._remainRes) * (Data._globalInfo._farmlandResumeTime * 60) / Data._globalInfo._farmlandCapacity + self._timestamp
end

function _M:getFullGoldTimestamp()
    return (Data._globalInfo._residenceCapacity - self._remainRes) * (Data._globalInfo._residenceResumeTime * 60) / Data._globalInfo._residenceCapacity + self._timestamp
end

function _M:sendFixityDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.fixity_dirty)
    eventCustom._data = self
    lc.Dispatcher:dispatchEvent(eventCustom)        
end

return _M
