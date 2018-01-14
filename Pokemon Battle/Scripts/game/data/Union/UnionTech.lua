local _M = class("UnionTech")

function _M:ctor(infoId, pbTech)
    self._infoId = infoId
    self._info = Data._unionTechInfo[infoId]

    if pbTech then
        self:update(pbTech)
    else
        self._level = 0
    end
        
    return union
end

function _M:update(pbTech)
    self._level = pbTech.level
end

function _M:getUpgradeRes()
    local info, level = self._info, self._level
    return info._updateUnionCoin[level + 1], info._updateUnionWood[level + 1], info._updateUnionBookNum[level + 1]
end

function _M:getUpgradeYubi()
    return self._info._updateCoin[self._level + 1]
end

return _M
