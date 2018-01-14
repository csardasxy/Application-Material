local _M = ClientData

-- card

function _M.sendCardUnlockConfirmed(infoId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_UNLOCK
    msg.Extensions[Card_pb.SglCardMsg.card_unlock_req] = infoId
    _M.sendProtoMsg(msg)
end

function _M.sendCardUpgrade(id, infoId, swallowIds, swallowExp)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_UPGRADE
    local req = msg.Extensions[Card_pb.SglCardMsg.card_upgrade_req]
    req.id = id
    req.info_id = infoId
    if swallowIds ~= nil then
        for i = 1, #swallowIds do
            req.swallow_id:append(swallowIds[i])
        end
    end
    if swallowExp ~= nil then
        req.swallow_exp = swallowExp
    end

    _M.appendGuideIdIfNeed(msg)
    _M.sendProtoMsg(msg)
end 

function _M.sendCardEvolution(id, infoId, swallowIds)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_EVOLUTION
    local req = msg.Extensions[Card_pb.SglCardMsg.card_evolution_req]
    req.id = id
    req.info_id = infoId
    if swallowIds ~= nil then    
        for i = 1, #swallowIds do
            req.swallow_id:append(swallowIds[i])
        end
    end

    _M.appendGuideIdIfNeed(msg)
    _M.sendProtoMsg(msg)
end

function _M.sendCardUpgrade(infoId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_UPGRADE
    msg.Extensions[Card_pb.SglCardMsg.card_upgrade_req] = infoId
    _M.sendProtoMsg(msg)
end

function _M.sendCardSetSkill(id, infoId, isUseCache)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_SKILL_SET
    local req = msg.Extensions[Card_pb.SglCardMsg.card_skill_set_req]
    req.id = id
    req.info_id = infoId
    req.is_keep = not isUseCache
    _M.sendProtoMsg(msg)
end

function _M.sendCardCompose(packageId, targetCard, costCards)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_COMPOSE
    msg.Extensions[Card_pb.SglCardMsg.card_compose_package_id] = tonumber(packageId)
    local req = msg.Extensions[Card_pb.SglCardMsg.card_compose_req]
--    req.info_id = infoId
--    req.num = count
    local targetResource = req:add()
    targetResource.info_id = targetCard
    targetResource.num = 1
    for k,v in pairs(costCards) do
        local resource = req:add()
        resource.info_id = k
        resource.num = v
    end
    _M.sendProtoMsg(msg)    
end

function _M.sendCardDecompose(infoId, count)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_DECOMPOSE
    local req = msg.Extensions[Card_pb.SglCardMsg.card_decompose_req]
    req.info_id = infoId
    req.num = count
    _M.sendProtoMsg(msg)    
end

function _M.sendCardRecovery(infoId, count)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_RECOVERY
    local req = msg.Extensions[Card_pb.SglCardMsg.card_recovery_req]
    req.info_id = infoId
    req.num = count
    _M.sendProtoMsg(msg)    
end

function _M.sendCardDecomposeBatch()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_DECOMPOSE_BATCH
    _M.sendProtoMsg(msg)    
end

function _M.sendCardSell(infoId, ids)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_SELL
    local req = msg.Extensions[Card_pb.SglCardMsg.card_sell_req]
    req.info_id = infoId
    for i = 1, #ids do
        req.id:append(ids[i])
    end   
    _M.sendProtoMsg(msg)
end

function _M.sendCardTransfer(cards)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_TRANSFER
    local req = msg.Extensions[Card_pb.SglCardMsg.card_transfer_req]
    for k, v in pairs(cards) do 
        local resource = req:add() 
        resource.info_id = k
        resource.num = v
    end   
    
    _M.sendProtoMsg(msg)       
end

function _M.sendCardLottery(pkgId, isFree, isUseTicket)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_LOTTERY
    local req = msg.Extensions[Card_pb.SglCardMsg.card_lottery_req]
    req.pkg_id = pkgId
    req.is_free = isFree
    if isUseTicket then
        msg.Extensions[Card_pb.SglCardMsg.card_lottery_use_token] = true
    end
    _M.appendGuideIdIfNeed(msg)
    _M.sendProtoMsg(msg)
end

function _M.sendCardLotteryRecord(heroId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_LOTTERY_RECORD
    msg.Extensions[Card_pb.SglCardMsg.card_lottery_record_req] = heroId
    _M.sendProtoMsg(msg)
end

function _M.sendCardBoxInfo(pkgId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARDBOX_INFO
    msg.Extensions[Card_pb.SglCardMsg.card_box_info_req] = pkgId
    _M.sendProtoMsg(msg)
end

function _M.sendCardBoxReset(pkgId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_RESET_CARDBOX
    msg.Extensions[Card_pb.SglCardMsg.reset_card_box_req] = pkgId
    _M.sendProtoMsg(msg)
end

function _M.sendCardEquip(heroId, equipId, isEquip)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_CARD_EQUIP
    local req = msg.Extensions[Card_pb.SglCardMsg.card_equip_req]
    req.hero_id = heroId
    req.equip_id = equipId
    req.is_equip = isEquip

    _M.appendGuideIdIfNeed(msg)
    _M.sendProtoMsg(msg)
end

