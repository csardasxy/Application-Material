local _M = class("PlayerMessage")

local Message = require("Message")

_M.Event = 
{
    send_ok                 = "send ok",
    msg_new                 = "msg new",
    msg_update              = "msg update",
    union_clear             = "union clear"
}

local CFG_KEYS = {
    ClientData.ConfigKey.new_world_msg,
    ClientData.ConfigKey.new_bulletin_msg,
    ClientData.ConfigKey.new_battle_msg,
    ClientData.ConfigKey.new_union_msg,
}

function _M:ctor()
    self:clear()

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    self._msgAll = {{}, {}, {}, {}}
end

function _M:clearUnion()
    self._msgAll[Data.MsgType.union] = {}
    self:sendMessageEvent(_M.Event.union_clear)
end

function _M:getNew(cfgType)
    if cfgType then
        if type(cfgType) == "number" then
            msgs = self._msgAll[cfgType]
            cfgType = CFG_KEYS[cfgType]
        end

        local timestamp = lc.readConfig(cfgType, 0)
        local number = 0
        for _, msg in ipairs(msgs) do
            if msg._user and msg._user._id ~= P._id then
                if math.floor(msg._timestamp) > math.ceil(timestamp) then
                    number = number + 1
                end
            end
        end
        
        return number
    end

    return self:getNewWorld() + self:getNewUnion() + self:getNewBulletin() + self:getNewBattle()
end

function _M:clearNew(cfgType)
    if type(cfgType) == "number" then
        cfgType = CFG_KEYS[cfgType]
    end

    lc.writeConfig(cfgType, ClientData.getCurrentTime())  
end

function _M:getNewWorld()
    return self:getNew(Data.MsgType.world)
end

function _M:getNewUnion()
    return self:getNew(Data.MsgType.union)
end

function _M:getNewBulletin()
    return self:getNew(Data.MsgType.bulletin)
end

function _M:getNewBattle()
    return self:getNew(Data.MsgType.battle)
end

function _M:addMsg(pbMsg, pbMsgType)
    local msg = Message.new(pbMsg, pbMsgType)
    if msg._hiddenInChat then
        return nil
    end

    local msgs = self._msgAll[msg._type]
    local maxCount = (pbMsgType == SglMsgType_pb.PB_TYPE_UNION_MESSAGE or pbMsgType == SglMsgType_pb.PB_TYPE_FRIEND_BATTLE) and 
        ClientData.MAX_UNION_MSG_COUNT or ClientData.MAX_MSG_COUNT

    if #msgs >= maxCount then
        table.remove(msgs, #msgs)
    end
    table.insert(msgs, 1, msg)

    return msg
end

function _M:isLogShared(logId)
    for _, msg in ipairs(self._msgAll[Data.MsgType.battle]) do
        if msg._log and msg._log._id == logId then
            return true
        end
    end

    return false
end

function _M:sendMessageEvent(event, msgType, param)
    local eventCustom = cc.EventCustom:new(Data.Event.message)
    eventCustom._event = event
    eventCustom._type = msgType
    eventCustom._param = param
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:onMsg(msg, msgType)
    msgType = msgType or msg.type
    if msgType == SglMsgType_pb.PB_TYPE_USER_LOADING_DONE then
        self:onMsg(msg, SglMsgType_pb.PB_TYPE_CHAT)
        self:onMsg(msg, SglMsgType_pb.PB_TYPE_NEWS)
        self:onMsg(msg, SglMsgType_pb.PB_TYPE_BATTLE_SHARE)

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_CHAT then
        local pbMsgs = msg.Extensions[Chat_pb.SglChatMsg.chat_receive_resp]
        local newWordCount, newBulletinCount = 0, 0
        for _, pbMsg in ipairs(pbMsgs) do
            local msg = self:addMsg(pbMsg, msgType)
            if msg then
                if msg._type == Data.MsgType.world then
                    newWordCount = newWordCount + 1
                else
                    newBulletinCount = newBulletinCount + 1
                end
            end
        end

        -- Player chat message
        if newWordCount > 0 then
            self:sendMessageEvent(_M.Event.msg_new, Data.MsgType.world, newWordCount)
        end

        -- System notice message
        if newBulletinCount > 0 then
            self:sendMessageEvent(_M.Event.msg_new, Data.MsgType.bulletin, newBulletinCount)
        end
                           
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_MESSAGE then
        if P:hasUnion() then
            local pbMsgs, newCount = msg.Extensions[Union_pb.SglUnionMsg.union_message_resp], 0
            for _, pbMsg in ipairs(pbMsgs) do
                if self:addMsg(pbMsg, msgType) then
                    newCount = newCount + 1
                end
            end

            pbMsgs = msg.Extensions[Friend_pb.SglFriendMsg.friend_battle_resp]
            for _, pbMsg in ipairs(pbMsgs) do
                if self:addMsg(pbMsg, SglMsgType_pb.PB_TYPE_FRIEND_BATTLE) then
                    newCount = newCount + 1
                end
            end 

            table.sort(self._msgAll[Data.MsgType.union], function(a, b) return a._timestamp > b._timestamp end)

            if newCount > 0 then
                self:sendMessageEvent(_M.Event.msg_new, Data.MsgType.union, newCount)
            end
        end

        -- Do not return true, because union class may process this message
        
    elseif msgType == SglMsgType_pb.PB_TYPE_NEWS then
        local pbMsgs, newCount = msg.Extensions[News_pb.SglNewsMsg.news_receive_resp], 0
        for _, pbMsg in ipairs(pbMsgs) do
            if self:addMsg(pbMsg, msgType) then
                newCount = newCount + 1
            end
        end

        self:sendMessageEvent(_M.Event.msg_new, Data.MsgType.bulletin, newCount)
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_SHARE then
        local pbMsgs, newCount = msg.Extensions[Battle_pb.SglBattleMsg.battle_share_resp], 0
        for _, pbMsg in ipairs(pbMsgs) do
            local msg = self:addMsg(pbMsg, msgType)
            if msg then
                newCount = newCount + 1

                if msg._log then
                    if msg._user._id > 0 then
                        P._playerLog:sendLogDirty(P._playerLog.Event.log_item_dirty, msg._log._id)
                    end
                end
            end
        end

        self:sendMessageEvent(_M.Event.msg_new, Data.MsgType.battle, newCount)
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_FRIEND_BATTLE_START then
        local pbMsg = msg.Extensions[Friend_pb.SglFriendMsg.friend_battle_start_resp]
        if self:addMsg(pbMsg, msgType) then
            self:sendMessageEvent(_M.Event.msg_new, Data.MsgType.battle, 1)
        end
        
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_FRIEND_BATTLE_END then
        local pbMsg = msg.Extensions[Friend_pb.SglFriendMsg.friend_battle_end_resp]
        for _, msg in ipairs(self._msgAll[Data.MsgType.battle]) do
            if msg._battleId == pbMsg.id then
                msg._result = pbMsg.result_type == Data.BattleResult.win and 1 or 0
                msg._content = pbMsg.result_type == Data.BattleResult.win and Str(STR.FRIEND_BATTLE_WIN) or Str(STR.FRIEND_BATTLE_LOSE)
                self:sendMessageEvent(_M.Event.msg_update, Data.MsgType.battle, msg)
                break
            end
        end
        
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_USER_BAN_CHAT then
        local userId = msg.Extensions[User_pb.SglUserMsg.user_ban_chat_resp]
        P._chatBanList[userId] = true

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_THUMBS_UP or msgType == SglMsgType_pb.PB_TYPE_BATTLE_THUMBS_UP_CANCEL then
        local pbMsg = msg.Extensions[Battle_pb.SglBattleMsg.battle_thumbs_up_resp]
        local userId, logId = pbMsg.user_id, pbMsg.log_id
        for _, msg in ipairs(self._msgAll[Data.MsgType.battle]) do
            if msg._log and msg._log._id == pbMsg.log_id then
                if msgType == SglMsgType_pb.PB_TYPE_BATTLE_THUMBS_UP then
                    msg._likeIds[userId] = true
                    msg._likeIdsCount = msg._likeIdsCount + 1
                else
                    msg._likeIds[userId] = nil
                    msg._likeIdsCount = math.max(0, msg._likeIdsCount - 1)
                end

                self:sendMessageEvent(_M.Event.msg_update, Data.MsgType.battle, msg)
                break
            end
        end
        
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_SHARE_WATCH then
        local pbMsg = msg.Extensions[Battle_pb.SglBattleMsg.battle_share_watch_resp]
        local userId, logId = pbMsg.user_id, pbMsg.log_id
        for _, msg in ipairs(self._msgAll[Data.MsgType.battle]) do
            if msg._log and msg._log._id == pbMsg.log_id then
                if not msg._watchIds[userId] then
                    msg._watchIds[userId] = true
                    msg._watchIdsCount = msg._watchIdsCount + 1
                end

                self:sendMessageEvent(_M.Event.msg_update, Data.MsgType.battle, msg)
                break
            end
        end
        
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_FRIEND_BATTLE_UPDATE then
        local pbMsg = msg.Extensions[Friend_pb.SglFriendMsg.friend_battle_update_resp]
        for _, msg in ipairs(self._msgAll[Data.MsgType.union]) do
            if msg._battleId and msg._battleId == pbMsg.battle_id then
                if pbMsg:HasField("user2") then
                    msg._opponent = require("User").create(pbMsg.user2)
                end
                msg._isValid = pbMsg.is_valid
                if pbMsg:HasField("result") then
                    msg._resultType = pbMsg.result.result_type
                    msg._replayId = pbMsg.result.replay_id
                end

                self:sendMessageEvent(_M.Event.msg_update, Data.MsgType.union, msg)
                break
            end
        end

    end    
    
    return false
end

return _M
