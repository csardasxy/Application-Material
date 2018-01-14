local _M = class("PlayerInvite")

function _M:ctor()
    self:clear()
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    self._ingot = 0
    self._invitedNum = 0
    self._inviter = nil
end

function _M:init(pbInvite)
    
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == 1 then

    end    
    
    return false
end