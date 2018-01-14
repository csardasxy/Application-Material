local _M = ClientData

-- find match
function _M.sendWorldFind()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_FIND
    _M.sendProtoMsg(msg)
end

function _M.sendWorldFindEx(troopIndex, type)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_FIND_EX
    local req = msg.Extensions[World_pb.SglWorldMsg.world_find_ex_req]
    req.troop_id = troopIndex
    req.type = type
    _M.sendProtoMsg(msg)
end

function _M.sendWorldFindExCancel()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_FIND_EX_CANCEL
    _M.sendProtoMsg(msg)
end

function _M.sendGetPvpLogs(pvpType)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_LOG_EX
    msg.Extensions[Battle_pb.SglBattleMsg.battle_log_ex_req] = pvpType
    _M.sendProtoMsg(msg)
end

function _M.sendClashSync()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_RANK_PRE
    _M.sendProtoMsg(msg)
end

function _M.sendUnionBattleSync()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_MASSWAR_PRE
    _M.sendProtoMsg(msg)
end

function _M.sendUserVisitRegion(userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_VISIT_EX
    msg.Extensions[User_pb.SglUserMsg.user_visit_req] = userId
    _M.sendProtoMsg(msg)
end

function _M.sendClashResetLadderLose()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_RESET_LADDER_LOSE
    _M.sendProtoMsg(msg)
end

--room match
function _M.sendCreateRoom()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_CREATE_MATCH
    _M.sendProtoMsg(msg)
end

function _M.sendQueryRoom(roomId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_QUERY_MATCH
    msg.Extensions[World_pb.SglWorldMsg.world_query_match_req] = tonumber(roomId)
    _M.sendProtoMsg(msg)
end

function _M.sendQuitRoom()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_QUIT_MATCH
    _M.sendProtoMsg(msg)
end

function _M.sendToggleRoomMatch()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_TOGGLE_MATCH
    _M.sendProtoMsg(msg)
end

function _M.sendStartRoomMatch()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_START_MATCH
    _M.sendProtoMsg(msg)
end

-- ladder match
function _M.sendLadderBuyTicket(resType)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_BUY_TICKET
    msg.Extensions[World_pb.SglWorldMsg.world_buy_ticket_req] = resType
    _M.sendProtoMsg(msg)
end

function _M.sendLadderSelectCharacter(characterId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_SELECT_CHAR
    msg.Extensions[World_pb.SglWorldMsg.world_select_char_req] = characterId
    _M.sendProtoMsg(msg)
end

function _M.sendLadderSelectCard(cardId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_SELECT_CARD
    msg.Extensions[World_pb.SglWorldMsg.world_select_card_req] = cardId
    _M.sendProtoMsg(msg)
end

function _M.sendLadderQuit()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_QUIT
    _M.sendProtoMsg(msg)
end
