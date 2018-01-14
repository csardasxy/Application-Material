local _M = ClientData

-- IAP

function _M.sendIAPStartReq(type)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_IAP_START
    msg.Extensions[Buy_pb.SglBuyMsg.iap_start_req] = type
    _M.sendProtoMsg(msg)    
end

function _M.sendIAPFinishReq()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_IAP_FINISH
    local resp = msg.Extensions[Buy_pb.SglBuyMsg.iap_finish_req]
    resp.purchase_id = _M._purchaseId or 0
    resp.is_success = false
    resp.fail_desc = ""
    _M.sendProtoMsg(msg)    
end

function _M.sendBuyGold(grade)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BUY_GOLD    
    msg.Extensions[Buy_pb.SglBuyMsg.buy_gold_req] = grade
    _M.sendProtoMsg(msg)
end

function _M.sendBuyGrain()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BUY_GRAIN    
    _M.sendProtoMsg(msg)    
end

function _M.sendBuyIngot(index)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BUY_INGOT
    msg.Extensions[Buy_pb.SglBuyMsg.buy_ingot_req] = index
    _M.sendProtoMsg(msg)        
end

function _M.sendBuyDust(dustType, grade)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BUY_DUST    
    local req = msg.Extensions[Buy_pb.SglBuyMsg.buy_dust_req]
    req.id = dustType
    req.grade = grade
    _M.sendProtoMsg(msg)        
end

function _M:sendBuyMonth()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BUY_MONTH   
    _M.sendProtoMsg(msg)      
end

function _M.sendBuyGoods(id, count)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BUY_DAILY
    local req = msg.Extensions[Buy_pb.SglBuyMsg.buy_daily_req]
    req.id = id
    req.count = count
    _M.sendProtoMsg(msg)
end

-- Bonus
function _M.sendClaimBonus(infoId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BONUS_CLAIM
    msg.Extensions[Bonus_pb.SglBonusMsg.bonus_claim_req] = infoId
    _M.appendGuideIdIfNeed(msg)
    _M.sendProtoMsg(msg)
end

function _M.sendClaimOnlineBonus(infoId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BONUS_ONLINE_CLAIM
    msg.Extensions[Bonus_pb.SglBonusMsg.bonus_claim_req] = infoId
    _M.sendProtoMsg(msg)
end

function _M.sendSupplyMonthCheckinBonus(infoId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BONUS_RE_CHECK_CLAIM
    msg.Extensions[Bonus_pb.SglBonusMsg.bonus_claim_req] = infoId
    _M.sendProtoMsg(msg)    
end

function _M.sendClaimServerBonus(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BONUS_ACTIVITY_CLAIM
    msg.Extensions[Bonus_pb.SglBonusMsg.bonus_activity_claim_req] = id
    _M.sendProtoMsg(msg)
end

function _M.sendGetDailyGold()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SPAWN_GOLD
    _M.sendProtoMsg(msg)    
end

function _M.sendClaimDailyGold() 
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_COLLECT_GOLD    
    _M.sendProtoMsg(msg)    
end

function _M.sendClaimActivityBonus(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BONUS_ACTIVITY_EX_CLAIM
    msg.Extensions[Bonus_pb.SglBonusMsg.bonus_claim_req] = id
    _M.sendProtoMsg(msg)
end

function _M.sendTeachingFinish(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BONUS_TEACHING_FINISH
    msg.Extensions[Bonus_pb.SglBonusMsg.bonus_teaching_finish_req] = id
    _M.sendProtoMsg(msg)
end

