local _M = ClientData


-- Union

function _M.sendGetMyUnionDetail()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_MINE
    _M.sendProtoMsg(msg)     
end

function _M.sendGetUnionDetail(unionId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_DETAIL
    msg.Extensions[Union_pb.SglUnionMsg.union_detail_req] = unionId
    _M.sendProtoMsg(msg)  
end

function _M.sendGetUnionMine()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_MINE    
    _M.sendProtoMsg(msg)
end

function _M.sendGetSearchUnions(typeName, keyword)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_SEARCH
    local req = msg.Extensions[Union_pb.SglUnionMsg.union_search_req]
    req[typeName] = keyword
    _M.sendProtoMsg(msg)      
end

function _M.sendGetRecommandUnions()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_RECOMMEND
    _M.sendProtoMsg(msg)     
end

function _M.sendChangeUnion(name, desc, level, joinType, badge, word)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_EDIT
    local req = msg.Extensions[Union_pb.SglUnionMsg.union_edit_req]
    req.name = name
    req.announcement = desc
    req.required_level = level
    req.type = joinType
    req.avatar = badge
    req.tag = word
    _M.sendProtoMsg(msg)
end

function _M.sendCreateUnion(name, desc, level, joinType, badge, word)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_CREATE
    local req = msg.Extensions[Union_pb.SglUnionMsg.union_create_req]
    req.name = name
    req.announcement = desc
    req.required_level = level
    req.type = joinType
    req.avatar = badge
    req.tag = word
    msg.Extensions[Union_pb.SglUnionMsg.create_union_use_token] = P:getItemCount(Data.PropsId.union_create) > 0
    _M.sendProtoMsg(msg)
end

function _M.sendUnionApply(id, message)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_APPLY
    local req = msg.Extensions[Union_pb.SglUnionMsg.union_apply_req]
    req.id = id
    req.message = message
    _M.sendProtoMsg(msg)
end

function _M.sendUnionInvite(id, message)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_INVITE
    local req = msg.Extensions[Union_pb.SglUnionMsg.union_invite_req]
    req.id = id
    req.message = message
    _M.sendProtoMsg(msg)
end

function _M.sendUnionAcceptApply(id, isAccept)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_ACCEPT_APPLY
    local req = msg.Extensions[Union_pb.SglUnionMsg.union_accept_req]
    req.id = id
    req.is_accept = isAccept

    if not isAccept then
        req.content = Str(STR.REFUSE_APPLY)
    end

    _M.sendProtoMsg(msg)
end

function _M.sendUnionAcceptInvite(id, isAccept)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_ACCEPT_INVITE
    local req = msg.Extensions[Union_pb.SglUnionMsg.union_accept_req]
    req.id = id
    req.is_accept = isAccept

    if not isAccept then
        req.content = Str(STR.REFUSE_INVITE)
    end

    _M.sendProtoMsg(msg)  
end

function _M.sendUnionKickout(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_KICKOUT
    msg.Extensions[Union_pb.SglUnionMsg.union_kickout_req] = id
    _M.sendProtoMsg(msg)
end

function _M.sendUnionLeave()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_LEAVE    
    _M.sendProtoMsg(msg)    
end

function _M.sendUnionPromote(userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_PROMOTE
    msg.Extensions[Union_pb.SglUnionMsg.union_promote_req] = userId    
    _M.sendProtoMsg(msg)   
end

function _M.sendUnionDemote(userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_DEMOTE
    msg.Extensions[Union_pb.SglUnionMsg.union_demote_req] = userId    
    _M.sendProtoMsg(msg)
end

function _M.sendUnionGiveLeader(userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_RESIGN
    msg.Extensions[Union_pb.SglUnionMsg.union_resign_req] = userId    
    _M.sendProtoMsg(msg)
end

function _M.sendUnionUpgrade()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_UPGRADE
    _M.sendProtoMsg(msg)  
end

function _M.sendUnionContribute(index, dstRes)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_DONATE
    local req = msg.Extensions[Union_pb.SglUnionMsg.union_donate_req]
    req.grade = index
    req.donate_type = dstRes
    _M.sendProtoMsg(msg)
end

function _M.sendUnionWorship(userId, index)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_WORSHIP
    local req = msg.Extensions[Union_pb.SglUnionMsg.union_worship_req]
    req.id = userId
    req.grade = index
    _M.sendProtoMsg(msg)
end

function _M.sendUnionAddHire(heroId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_LET
    msg.Extensions[Union_pb.SglUnionMsg.union_let_req] = heroId
    _M.sendProtoMsg(msg)
end

function _M.sendUnionHire(hireGuid)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_RENT
    msg.Extensions[Union_pb.SglUnionMsg.union_rent_req] = hireGuid
    _M.sendProtoMsg(msg)
end

function _M.sendUnionHireClaim(hireGuid)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_CLAIM_LET
    msg.Extensions[Union_pb.SglUnionMsg.union_claim_let_req] = hireGuid
    _M.sendProtoMsg(msg)
end

function _M.sendUnionHireRecall(hireGuid)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_UNLET
    msg.Extensions[Union_pb.SglUnionMsg.union_unlet_req] = hireGuid
    _M.sendProtoMsg(msg)
end

function _M.sendGetUnionLog()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_LOG
    _M.sendProtoMsg(msg)
end

function _M.sendUnionUpgradeTech(techId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_TECH_UPGRADE
    msg.Extensions[Union_pb.SglUnionMsg.union_tech_upgrade_req] = techId
    _M.sendProtoMsg(msg)  
end

function _M.sendUnionUpgradeTechSelf(techId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_TECH_UPGRADE
    msg.Extensions[User_pb.SglUserMsg.user_tech_upgrade_req] = techId
    _M.sendProtoMsg(msg)
end

function _M.sendUnionImpeach(leaderId, isImpeached)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = isImpeached and SglMsgType_pb.PB_TYPE_UNION_UNIMPEACH or SglMsgType_pb.PB_TYPE_UNION_IMPEACH    
    if not isImpeached then
        msg.Extensions[Union_pb.SglUnionMsg.union_impeach_req] = leaderId
    end
    _M.sendProtoMsg(msg)
end

-- Union World, War, Battle

function _M.sendUnionBattleScout(warId, unionId, campId, needMyTroop)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_WAR_BATTLE_SCOUT 
    local req = msg.Extensions[UnionWar_pb.SglUnionWarMsg.union_battle_scout_req]
    req.war_id = warId
    req.union_id = unionId
    req.camp_id = campId
    _M.sendProtoMsg(msg)  
end

function _M.sendUnionBattleAttack(warId, unionId, campId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_WAR_BATTLE_ATTACK
    local req = msg.Extensions[UnionWar_pb.SglUnionWarMsg.union_battle_attack_req]
    req.war_id = warId
    req.union_id = unionId
    req.camp_id = campId
    _M.sendProtoMsg(msg)  
end

function _M.sendUnionBattleJoin(attackerId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_UNION_WAR_BATTLE_JOIN
    msg.Extensions[UnionWar_pb.SglUnionWarMsg.union_battle_join_req] = attackerId
    _M.sendProtoMsg(msg)  
end