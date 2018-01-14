local _M = ClientData

-- battle

function _M.sendWorldAttack(troopIndex, levelId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_ATTACK
    local req = msg.Extensions[World_pb.SglWorldMsg.world_attack_req]
    req.troop_id = troopIndex
    req.level_id = levelId
    _M.sendProtoMsg(msg)
end

function _M.sendWorldChallenge(troopIndex, cityId, chapterId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_CHALLENGE
    local req = msg.Extensions[World_pb.SglWorldMsg.world_challenge_req]
    req.city.id = cityId 
    req.city.chapter = chapterId
    req.troop_id = troopIndex
    _M.sendProtoMsg(msg)
end

function _M.sendWorldExpedition(troopIndex)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_EXPEDITION
    msg.Extensions[World_pb.SglWorldMsg.world_expedition_req] = troopIndex
    _M.sendProtoMsg(msg)    
end

function _M.sendWorldExpeditionEx(troopIndex, npcId, isBoss)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = isBoss and SglMsgType_pb.PB_TYPE_WORLD_EXPEDITION_EX_BOSS or SglMsgType_pb.PB_TYPE_WORLD_EXPEDITION_EX
    local req = msg.Extensions[World_pb.SglWorldMsg.world_expedition_ex_req]
    req.troop_id = troopIndex
    req.npc_id = npcId
    _M.sendProtoMsg(msg)    
end

function _M.sendWorldJoin(userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_BATTLE_JOIN
    msg.Extensions[World_pb.SglWorldMsg.world_battle_join_req] = userId
    _M.sendProtoMsg(msg)
end

function _M.sendWorldRescueJoin(userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_RESCUE_JOIN
    msg.Extensions[World_pb.SglWorldMsg.world_rescue_join_req] = userId
    _M.sendProtoMsg(msg)
end

function _M.sendChallengeElite(troopIndex, copyId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_CHALLENGE_ELITE
    local req = msg.Extensions[World_pb.SglWorldMsg.world_challenge_elite_req]
    req.troop_id = troopIndex
    req.copy_id = copyId
    _M.sendProtoMsg(msg)
end

function _M.sendChallengeGold(troopIndex, copyId, propId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_ROB_GOLD
    local req = msg.Extensions[World_pb.SglWorldMsg.world_rob_gold_req]
    req.troop_id = troopIndex
    req.copy_id = copyId
    req.prop_id = propId
    _M.sendProtoMsg(msg)
end

function _M.sendChallengeCommander(troopIndex, copyId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_CHALLENGE_COMMANDER
    local req = msg.Extensions[World_pb.SglWorldMsg.world_challenge_commander_req]
    req.troop_id = troopIndex
    req.copy_id = copyId
    _M.sendProtoMsg(msg)
end

function _M.sendCopySweep(id, times, propId)
    local msg = SglMsg_pb.SglReqMsg()
    if times == 1 then
        msg.type = SglMsgType_pb.PB_TYPE_WORLD_SWEEP_COPY_ONCE
    else
        msg.type = SglMsgType_pb.PB_TYPE_WORLD_SWEEP_COPY
    end
    local req = msg.Extensions[World_pb.SglWorldMsg.world_sweep_copy_req]
    req.copy_id = id
    req.prop_id = propId
    _M.sendProtoMsg(msg)
end

function _M.sendCopyPvpUnlock()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_FIND_RESET
    _M.sendProtoMsg(msg)
end

function _M.sendWorldFindStart(troopIndex, index)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_WORLD_FIND_START
    local req = msg.Extensions[World_pb.SglWorldMsg.world_find_start_req]
    req.troop_id = troopIndex
    req.choice = index
    _M.sendProtoMsg(msg)
end

function _M.sendBattleReplay(replayId, isLocal)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = isLocal and SglMsgType_pb.PB_TYPE_BATTLE_REPLAY or SglMsgType_pb.PB_TYPE_BATTLE_REPLAY_EX
    msg.Extensions[Battle_pb.SglBattleMsg.battle_replay_req] = replayId
    _M.sendProtoMsg(msg)
end

function _M.sendBattleShareReplay(logId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_REPLAY_SHARE
    msg.Extensions[Battle_pb.SglBattleMsg.battle_replay_share_req] = logId
    _M.sendProtoMsg(msg)
end

function _M.sendTutorialReplay(tutorialId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_REPLAY_TUTORIAL
    msg.Extensions[Battle_pb.SglBattleMsg.battle_replay_tutorial_req] = tutorialId
    _M.sendProtoMsg(msg)
end

function _M.sendBattleStart(troopId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_START
    local req = msg.Extensions[Battle_pb.SglBattleMsg.battle_start_req]
    req.troop_id = troopId
    _M.sendProtoMsg(msg)
end

function _M.sendBattleEnd(checkGuideId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_SKIP

    if checkGuideId then
        msg.Extensions[User_pb.SglUserMsg.user_set_guide_req] = P._guideID
    end

    _M.sendProtoMsg(msg)
end

function _M.sendBattleSkip()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_SKIP
    _M.sendProtoMsg(msg)
end

function _M:sendBattleSync()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_SYNC
    _M.sendProtoMsg(msg)
end

function _M.sendBattleUseCard(player, type, ids)
    ids = ids or {}

    local timestamp = math.floor(_M.getCurrentTime())

    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_USECARD
    local req = msg.Extensions[Battle_pb.SglBattleMsg.battle_usecard_req]
    req:append(timestamp)
    req:append(type)
    req:append(#ids)
    for i = 1, #ids do
        req:append(ids[i])
    end
  
    _M.sendProtoMsg(msg)

    if player._isOnlinePvp and player._playerType ~= BattleData.PlayerType.observe then
        table.insert(player._ops, {_type = type, _ids = ids, _timestamp = timestamp})
    end
end

function _M.sendBattleOppoUseCard(player, type, ids)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_OP_USECARD
    local req = msg.Extensions[Battle_pb.SglBattleMsg.battle_op_usecard_req]
    req:append(-math.floor(_M.getCurrentTime()))
    req:append(type)
    req:append(#ids)
    for i = 1, #ids do
        req:append(ids[i])
    end
    
    _M.sendProtoMsg(msg)
end

function _M.sendBattleRetry()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_RETRY
    _M.sendProtoMsg(msg)
end

function _M.sendBattleChat(str)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_CHAT
    msg.Extensions[Battle_pb.SglBattleMsg.battle_chat_req] = str
    _M.sendProtoMsg(msg)
end

function _M.sendBattleLogGet()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_LOG
    _M.sendProtoMsg(msg)
end

function _M.sendBattleShare(id, str)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_SHARE
    local req = msg.Extensions[Battle_pb.SglBattleMsg.battle_share_req]
    req.log_id = id
    req.text = str
    _M.sendProtoMsg(msg)
end

function _M.sendBattleAgain()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_AGAIN
    msg.Extensions[Battle_pb.SglBattleMsg.battle_again_req] = P._curTroopIndex
    _M.sendProtoMsg(msg)
end