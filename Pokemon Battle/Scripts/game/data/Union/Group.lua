local _M = class("Group")

function _M.create(info)
    local group
    if info then
        group = _M.new(info)
    end
    return group
end

function _M:ctor(info)
    self:updateInfo(info)
end

function _M:clear()
    self._members = nil
end

function _M:updateInfo(info)
    local pb = info._pb
    self._id = pb.id
    self._members = info._members or {}
    self._name = pb.name or "no name"
    self._avatar = pb.avatar or 1
    self._gameStarted = pb.masswar_started or false
end

function _M:getMembers()
    return self._members
end

return _M
