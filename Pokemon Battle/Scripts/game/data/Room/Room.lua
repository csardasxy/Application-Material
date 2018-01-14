local _M = class("Room")

function _M.create(pbRoomMine)
    local room
    if pbRoomMine then
        room = _M.new(pbRoomMine)
    end
    return room
end

function _M:ctor(info)
    self:updateInfo(info)
end

function _M:clear()
    self._members = nil
end

function _M:updateInfo(info)
    self._id = info.id
    local creator = require("User").create(info.creator.info, true)
    creator._idInRoom = info.creator.id
    self._creator = creator
    self._creator._roomJob = Data.RoomJob.leader
    local playerO, playerA, playerB
    if info:HasField("playerO") then
        playerO = require("User").create(info.playerO.info, true)
        playerO._idInRoom = info.playerO.id
        playerO._win = info.playerO.win
    end
    if info:HasField("playerA") then
        playerA = require("User").create(info.playerA.info, true)
        playerA._idInRoom = info.playerA.id
        playerA._win = info.playerA.win
    end
    if info:HasField("playerB") then
        playerB = require("User").create(info.playerB.info, true)
        playerB._idInRoom = info.playerB.id
        playerB._win = info.playerB.win
    end
    self._members = {playerO, playerA, playerB}
    for _, player in ipairs(self._members) do
        if player then
            if player._idInRoom == self._creator._idInRoom then
                player._roomJob = Data.RoomJob.leader
            else
                player._roomJob = Data.RoomJob.rookie
            end
        end
    end
    
end

function _M:getMembers()
    return self._members
end

function _M:sendRoomDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.room_dirty)
    eventCustom._data = self
    lc.Dispatcher:dispatchEvent(eventCustom)
end

return _M
