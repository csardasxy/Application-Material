local _M = ClientData

-- troop

function _M.sendTroopReload(troops, checkGuideId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_TROOP_RELOAD
    
    for i = 1, #troops do
        local reloadReq = msg.Extensions[Troop_pb.SglTroopMsg.troop_reload_req]:add()
        reloadReq.troop_id = troops[i]._troopIndex
        reloadReq.is_check = troops[i]._isCheck
        for j = 1, #troops[i]._cards do
            local troopInfo = reloadReq.troop_info:add()
            troopInfo.info_id = troops[i]._cards[j]._infoId
            troopInfo.num = troops[i]._cards[j]._num
        end
    end

    if checkGuideId then
        _M.appendGuideIdIfNeed(msg)
    end

    _M.sendProtoMsg(msg)
end

function _M.sendTroops(checkGuideId, curTroopIndex)
    if ClientData._cloneTroops == nil then return end

    local msg = {}
    local troops = {}
    local troopsIndex = {}
    for k, v in pairs(ClientData._cloneTroops) do
        if v._isDirty then
            v._isDirty = false
            table.insert(troops, v)
            table.insert(troopsIndex, k)
        end
    end

    for i = 1, #troops do
        local troopMsg =
            {
                _troopIndex = troopsIndex[i],
                _cards = {},
                _isCheck = P._guideID > 172 and lc.App:getChannelName() ~= 'OFFICIAL' and troopsIndex[i] == curTroopIndex and not Data.isDarkTroop(curTroopIndex),
            }     
        for j = 1, #troops[i] do
            table.insert(troopMsg._cards, {_infoId = troops[i][j]._infoId, _num = troops[i][j]._num})            
        end
        table.insert(msg, troopMsg)
    end

    if #msg == 0 and curTroopIndex >= Data.TroopIndex.union_battle1 and curTroopIndex <= Data.TroopIndex.union_battle5 then
        local emptyMsg = 
        {
            _troopIndex = curTroopIndex,
            _cards = {},
            _isCheck = false,
        }
        table.insert(msg, emptyMsg)
    end

    if #msg > 0 then
        ClientData.sendTroopReload(msg, checkGuideId)
    end 
end

function _M.sendDefTroopIndex(troopIndex)    
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_DEF_TROOP
    msg.Extensions[User_pb.SglUserMsg.user_set_troop_req] = troopIndex
    _M.sendProtoMsg(msg)
end

function _M.sendCurToopIndex()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_CUR_TROOP
    msg.Extensions[User_pb.SglUserMsg.user_set_troop_req] = P._curTroopIndex
    _M.sendProtoMsg(msg)
end

function _M.sendTroopRemark(troopIndex, remark)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_TROOP_MARK
    local req = msg.Extensions[Troop_pb.SglTroopMsg.troop_mark_req]
    req.troop_id = troopIndex
    req.name = remark
    _M.sendProtoMsg(msg)
end

