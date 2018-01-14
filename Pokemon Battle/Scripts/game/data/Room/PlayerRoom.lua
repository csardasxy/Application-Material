local _M = class("PlayerRoom")

local Room = require("Room")

function _M:ctor()
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    if self._myRoom then
        self._myRoom:clear()
    end
    self._myRoom = nil
    self._myIdInRoom = nil
    P._roomId = nil
    P._roomJob = nil

end

function _M:initMyRoom(pbRoomMine)
    local room = Room.create(pbRoomMine)

    if room then
        self._myRoom = room
        P._roomId = room._id
        P._lastRoomId = room._id
        self._myIdInRoom = pbRoomMine.user_id
        if self._myIdInRoom == room._creator._idInRoom then
            P._roomJob = Data.RoomJob.leader
        else
            P._roomJob = Data.RoomJob.rookie
        end
        lc._runningScene:onEnterRoom()
    end
end

function _M:updateMyRoom(info)
    self._myRoom:updateInfo(info)
    local room = self._myRoom
    P._roomId = room._id
    self._myIdInRoom = info.user_id
        if self._myIdInRoom == room._creator._idInRoom then
            P._roomJob = Data.RoomJob.leader
        else
            P._roomJob = Data.RoomJob.rookie
        end
    self._myRoom:sendRoomDirty()
end


function _M:getMyRoom()
    return self._myRoom
end

function _M:addMember(user)
    local room = self._myRoom
    if room then
        room:addMember(user)
    end
end

function _M:removeMember(userId, isKickout)
    local room = self._myRoom
    if room then
        room:removeMember(userId)

        if userId == P._id then
            P._roomId = 0
--            P._playerMessage:clearRoom()

            self:clear()
            self:sendExitRoomDirty()

            if isKickout then
                ToastManager.push(Str(STR.ROOM_BE_KICKED_OUT))
            end
        else
            room._impeach[userId] = nil
        end
    end
end

function _M:sendEnterRoomDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.room_enter_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendExitRoomDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.room_exit_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

----------------------------- socket receive --------------------------------------
function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status
    lc.log(msg.type..msg.status)
    if msgType == SglMsgType_pb.PB_TYPE_WORLD_GET_MATCH then
        local indicator = V.getActiveIndicator()
        if indicator._isShowing then
            indicator:hide()
        end
        local resp = msg.Extensions[World_pb.SglWorldMsg.world_get_match_resp]
        if not self._myRoom then
            self:initMyRoom(resp)
        else
            self:updateMyRoom(resp)
        end
        
        return true
    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_CLOSE_MATCH then
        self:clear()
        self:sendExitRoomDirty()
        return true
    end
    return false
end

function _M:exitMyRoom()
    self:clear()
    ClientData.sendQuitRoom()
end

function _M:sendGetRoomLog()
    ClientData.sendGetPvpLogs(Battle_pb.PB_BATTLE_MATCH)
end

return _M
