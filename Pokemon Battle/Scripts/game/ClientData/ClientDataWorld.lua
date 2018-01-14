local _M = ClientData

-- world

function _M.sendGetExpeditionEx()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_GET_EXPEDITION_EX
    _M.sendProtoMsg(msg)
end

function _M.sendWorldLottery(isToken, count)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_LOTTERY
    msg.Extensions[World_pb.SglWorldMsg.world_lottery_user_token] = isToken
    msg.Extensions[World_pb.SglWorldMsg.world_lottery_count] = count
    _M.sendProtoMsg(msg)
end

function _M.sendWorldFindNpc(troopIndex)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_FIND_NPC    
    if troopIndex then
        local req = msg.Extensions[World_pb.SglWorldMsg.world_find_ex_req]
        req.troop_id = troopIndex
        req.type = 1
    end
    _M.sendProtoMsg(msg)
end