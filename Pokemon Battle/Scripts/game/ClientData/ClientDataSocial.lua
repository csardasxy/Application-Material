local _M = ClientData


-- friend

function _M.sendFriendList()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_LIST
    _M.sendProtoMsg(msg)
end

function _M.sendFriendSearch(str)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_SEARCH
    msg.Extensions[Friend_pb.SglFriendMsg.friend_search_req] = str
    _M.sendProtoMsg(msg)
end

function _M.sendFriendRecommend()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_RECOMMEND
    _M.sendProtoMsg(msg)
end

function _M.sendFriendInvite(id, message)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_INVITE
    local req = msg.Extensions[Friend_pb.SglFriendMsg.friend_invite_req]
    req.id = id
    req.message = message
    _M.sendProtoMsg(msg)
end

function _M.sendFriendRemove(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_REMOVE
    msg.Extensions[Friend_pb.SglFriendMsg.friend_remove_req] = id
    _M.sendProtoMsg(msg)
end

--[[
function _M.sendFriendBattle(troopId, id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_BATTLE
    local req = msg.Extensions[Friend_pb.SglFriendMsg.friend_battle_req]
    req.troop_id = troopId
    req.friend_id = id
    _M.sendProtoMsg(msg)
end

function _M.sendFriendBattleJoin(battleId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_BATTLE_JOIN
    msg.Extensions[Friend_pb.SglFriendMsg.friend_battle_join_req] = battleId
    _M.sendProtoMsg(msg)
end
]]

function _M.sendUnionFriendBattle(troopId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_BATTLE
    msg.Extensions[Friend_pb.SglFriendMsg.friend_battle_req] = troopId
    _M.sendProtoMsg(msg)
end

function _M.sendUnionFriendBattleJoin(troopId, battleId, userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_BATTLE_JOIN
    local req = msg.Extensions[Friend_pb.SglFriendMsg.friend_battle_join_req]
    req.troop_id = troopId
    req.battle_id = battleId
    req.user_id = userId
    _M.sendProtoMsg(msg)
end

function _M.sendUnionFriendBattleCancel()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FRIEND_BATTLE_CANCEL
    _M.sendProtoMsg(msg)
end

-- mail

function _M.sendMailList()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MAIL_LIST
    _M.sendProtoMsg(msg)
end

function _M.sendMailSend(content, userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MAIL_SEND
    local req = msg.Extensions[Mail_pb.SglMailMsg.mail_send_req]

    if userId then
        req.type = Mail_pb.PB_MAIL_FRIEND
        req.id = userId
    else
        req.type = Mail_pb.PB_MAIL_UNION
        req.id = P._unionId
    end

    req.content = content
    _M.sendProtoMsg(msg)
end

-- chat

function _M.sendGetMessages()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_LOADING_DONE
    _M.sendProtoMsg(msg)
end

function _M.sendChat(type, id, content)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CHAT
    local req = msg.Extensions[Chat_pb.SglChatMsg.chat_send_req]
    req.type = type
    req.id = id
    req.content = content
    _M.sendProtoMsg(msg)
end

function _M.sendFeedback(type, content)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_FEEDBACK
    local req = msg.Extensions[Feedback_pb.SglFeedbackMsg.feedback_req]
    req.type = type
    req.content = content
    _M.sendProtoMsg(msg)
end

function _M.sendShareLike(logId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_THUMBS_UP
    msg.Extensions[Battle_pb.SglBattleMsg.battle_thumbs_up_req] = logId
    _M.sendProtoMsg(msg)
end

function _M.sendShareLikeCancel(logId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_THUMBS_UP_CANCEL
    msg.Extensions[Battle_pb.SglBattleMsg.battle_thumbs_up_req] = logId
    _M.sendProtoMsg(msg)
end


-- Notice

function _M.sendNoticeRequest()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_NEWS_ANNOUNCEMENT
    _M.sendProtoMsg(msg)
end

-- Resource

function _M.sendResCollect(infoId)
    local msg = SglMsg_pb.SglReqMsg()
    if infoId == Data.FixityId.farmland then
        msg.type = SglMsgType_pb.PB_TYPE_CITY_COLLECT_GRAIN
    else
        msg.type = SglMsgType_pb.PB_TYPE_CITY_COLLECT_GOLD
    end    

    _M.appendGuideIdIfNeed(msg)
    _M.sendProtoMsg(msg)
end

-- Rank

function _M.sendRankRequest(rankType, param)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = rankType

    if rankType == SglMsgType_pb.PB_TYPE_RANK_LADDER then
        msg.Extensions[Rank_pb.SglRankMsg.rank_ladder_req] = param
    elseif rankType == SglMsgType_pb.PB_TYPE_RANK_CHAR_LEVEL then
        msg.Extensions[Rank_pb.SglRankMsg.rank_char_req] = param
    end

    _M.sendProtoMsg(msg)
end

function _M.sendRankUBoss(rankType, bossId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = rankType
    msg.Extensions[Rank_pb.SglRankMsg.rank_uboss_req] = bossId
    _M.sendProtoMsg(msg)
end

function _M.sendRankChapter(chapterId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_TUTORIAL
    msg.Extensions[Battle_pb.SglBattleMsg.battle_tutorial_req] = chapterId
    _M.sendProtoMsg(msg)
end

function _M.sendBonusRequest(msgType)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = msgType
    _M.sendProtoMsg(msg)
end

-- Guide

function _M.sendGuideID(guideId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_GUIDE  
    if guideId then msg.Extensions[User_pb.SglUserMsg.user_set_guide_req] = guideId end
    _M.sendProtoMsg(msg)
end

-- Props

function _M.sendOpenBox(infoId, number)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_OPEN_CHEST 
    local req = msg.Extensions[User_pb.SglUserMsg.user_open_chest_req]
    req.id = infoId
    req.num = number
    _M.sendProtoMsg(msg)
end

function _M.sendUseVipCard(number)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_APPLY_VIP_CARD
    msg.Extensions[User_pb.SglUserMsg.user_apply_vip_card_req] = number
    _M.sendProtoMsg(msg)
end




-- Invitation

function _M.sendGetInviteCode()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_GET_INVITE_CODE
    _M.sendProtoMsg(msg)
end

function _M.sendGetInviteInfo(code)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_CHECK_INVITE_CODE
    msg.Extensions[User_pb.SglUserMsg.user_check_invite_code_req] = code
    _M.sendProtoMsg(msg)
end

function _M.sendBindInvite(code)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_BIND_INVITE_CODE
    msg.Extensions[User_pb.SglUserMsg.user_bind_invite_code_req] = code
    _M.sendProtoMsg(msg)
end