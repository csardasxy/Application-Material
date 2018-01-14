local _M = ClientData


--group

function _M.sendCreateGroup(name, avatar)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_CREATE_TEAM
    local req = msg.Extensions[UnionWar_pb.SglUnionWarMsg.masswar_create_team_req]
    req.team_name = name
    req.team_avatar = avatar
    _M.sendProtoMsg(msg)
end

function _M.sendGetGroups()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_QUERY_INFO
    _M.sendProtoMsg(msg)
end

function _M.sendStopUpdateGroups()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_QUIT_INFO
    _M.sendProtoMsg(msg)
end

function _M.sendExitGroup(groupId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_QUIT_TEAM
    local req = msg.Extensions[UnionWar_pb.SglUnionWarMsg.masswar_team_user_id]
    req.team_id = groupId
    _M.sendProtoMsg(msg)
end

function _M.sendGroupKick(groupId, userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_KICK_OUT_TEAM
    local req = msg.Extensions[UnionWar_pb.SglUnionWarMsg.masswar_team_user_id]
    req.team_id = groupId
    req.user_id = userId
    _M.sendProtoMsg(msg)
end

function _M.sendGroupJoin(groupId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_JOIN_TEAM
    local req = msg.Extensions[UnionWar_pb.SglUnionWarMsg.masswar_team_user_id]
    req.team_id = groupId
    _M.sendProtoMsg(msg)
end

function _M.sendGetGroupCards()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_LOAD_CARDS
    _M.sendProtoMsg(msg)
end

function _M.sendStartUnionBattle()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_START
    _M.sendProtoMsg(msg)
end

function _M.sendQuitUnionBattle()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_QUIT
    _M.sendProtoMsg(msg)
end

function _M.sendFindUnionBattle()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_FIND
    _M.sendProtoMsg(msg)
end

function _M.sendFindUnionBattleCancle()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_FIND_CANCEL
    _M.sendProtoMsg(msg)
end

function _M.sendGetPreRanks()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE
    _M.sendProtoMsg(msg)
end

function _M.sendActivityExchange(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_SHOP_EXCHANGE_PROP
    msg.Extensions[Shop_pb.SglShopMsg.shop_exchange_prop_req] = id
    _M.sendProtoMsg(msg)
end

function _M.sendProp(userId, bonusId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BONUS_GIFT
    local req = msg.Extensions[Bonus_pb.SglBonusMsg.send_gift_req]
    req.user_id = userId
    req.bonus_id = bonusId
    _M.sendProtoMsg(msg)
end

function _M:sendGetLotteryOpened()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_LOTTERY_OPENED
    _M.sendProtoMsg(msg)
end

function _M:sendGetLotteryUnopened()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_LOTTERY_UNOPEN
    _M.sendProtoMsg(msg)
end

function _M.sendComposeCard(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_LEGEND_COMPOSE
    msg.Extensions[Card_pb.SglCardMsg.legend_card_compose] = id
    _M.sendProtoMsg(msg)
end

function _M.sendGetRecommendTroops()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_RECOMMEND_TROOP
    _M.sendProtoMsg(msg)
end

function _M.getAttackUserFromInput(input)
    local player = input._player
    local oppo = input._opponent
    return input._isAttacker and player or oppo
end

function _M.sendGetDarkInfo()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_DARK_DUEL_DASHBOARD
    _M.sendProtoMsg(msg)
end

function _M.sendDarkRetreat()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_DARK_DUEL_RECHEAT
    _M.sendProtoMsg(msg)
end
