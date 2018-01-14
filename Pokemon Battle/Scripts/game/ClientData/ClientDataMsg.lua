local _M = ClientData


function _M.onMsg(msg)
    for i = 1, #_M._msgListeners do
        local listener = _M._msgListeners[i]
        if listener._onMsg(msg) then
            return true
        end
    end
    
    return false
end

function _M.onError(msg)
    for i = 1, #_M._errorListeners do
        local listener = _M._errorListeners[i]
        if listener._onError(msg) then
            return true
        end
    end
    
    return false
end

function _M.addMsgListener(target, func, priority)
    local t = {_target = target, _onMsg = func, _priority = priority}
    
    for i = 1, #_M._msgListeners do
        local listener = _M._msgListeners[i]
        if listener._target == t._target and listener._priority == t._priority then
            return
        end
        
        if t._priority < listener._priority then
            table.insert(_M._msgListeners, i, t)
            return
        end
    end
    
    table.insert(_M._msgListeners, t)
end

function _M.removeMsgListener(target)
    for i = 1, #_M._msgListeners do
        local handler = _M._msgListeners[i]
        if handler._target == target then
            table.remove(_M._msgListeners, i)
            return
        end
    end
end

function _M.addErrorListener(target, func, priority)
    local t = {_target = target, _onError = func, _priority = priority}
    
    for i = 1, #_M._errorListeners do
        local listener = _M._errorListeners[i]
        if listener._target == t._target then
            return
        end
        
        if t._priority < listener._priority then
            table.insert(_M._errorListeners, i, t)
            return
        end
    end
    
    table.insert(_M._errorListeners, #_M._errorListeners + 1, t)
end

function _M.removeErrorListener(target)
    for i = 1, #_M._errorListeners do
        local handler = _M._errorListeners[i]
        if handler._target == target then
            table.remove(_M._errorListeners, i)
            return
        end
    end
end

function _M.onMsgBeforeScene(msg)
    local msgStatus = msg.status
    --[[
    if msg.type ~= SglMsgType_pb.PB_TYPE_HEART_BEAT or msgStatus ~= SglMsg_pb.PB_STATUS_OK then
        lc.log("msg type:%d, msg status:%d", msg.type, msgStatus)
    end
    ]]--

    if msgStatus ~= SglMsg_pb.PB_STATUS_OK then
       lc._runningScene:onMsgErrorStatus(msg, msgStatus)
       return true  -- always return true here
    end
    
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_AUTHENTICATION then
        _M.onConnectedAndAuthorized()
        return true
        
    elseif (msgType == SglMsgType_pb.PB_TYPE_USER_LOGIN or msgType == SglMsgType_pb.PB_TYPE_USER_REGISTER) then
        _M._socketStatus = _M.SocketStatus.login

        local resp = msg.Extensions[User_pb.SglUserMsg.user_in_resp]
        _M.loadPlayerData(P, resp)

        local isInBattle = resp.is_in_battle
        local isInRoom = resp.is_in_match
        lc.log("login success! %s", isInBattle and "now in battle!" or "")
        _M.sendUserEvent({type = "login", isInBattle = tostring(isInBattle), sceneId = lc._runningScene and lc._runningScene._sceneId or 0, regIds = _M._regIds})
        if isInBattle ~= true and not isInRoom then
            lc._runningScene:onLogin()
        end

        _M.checkSocketLog()
        _M.syncServerPush()

        local eventCustom = cc.EventCustom:new(Data.Event.login)
        lc.Dispatcher:dispatchEvent(eventCustom)         

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_USER_QUERY_GCID then
        local channelName = lc.App:getChannelName()
        local needSwitch = msg.Extensions[User_pb.SglUserMsg.user_query_gcid_resp]
        if channelName == 'APPSTORE' then
            if needSwitch then
                lc._runningScene:onGameCenterIdChanged()
            end
        elseif channelName == "FACEBOOK" then
            P._canBind = not needSwitch
            V.getActiveIndicator():hide()
            ToastManager.push(Str(needSwitch and STR.BIND_GCID_SUCCEED or STR.BIND_GCID_FAILED)) 
            local eventCustom = cc.EventCustom:new(Data.Event.bind_gcid_dirty)
            lc.Dispatcher:dispatchEvent(eventCustom)

            if needSwitch then
                ClientData.sendUserFacebook(2401)
                P._playerBonus:onFacebookTaskDirty(2401)
            end
        end
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_USER_NOTIFY_EVENT then
        local resp = msg.Extensions[User_pb.SglUserMsg.user_notify_event_resp]
        if resp.type == 1 then
            -- level
            for i = 1, #P._playerBonus._bonusInvite do
                local bonus = P._playerBonus._bonusInvite[i]
                bonus._value = bonus._value + 1
            end
            bonus:sendBonusDirty()

        elseif resp.type == 2 then
            -- ingot
            P._inviteIngot = P._inviteIngot + resp.param
            lc.sendEvent(Data.Event.invite_ingot_dirty)

        elseif resp.type == 3 then
            -- count
            P._inviteCount = P._inviteCount + 1
            lc.sendEvent(Data.Event.invite_count_dirty)

        end

        return true
        
    -- heartbeat
    elseif msgType == SglMsgType_pb.PB_TYPE_HEART_BEAT then
        _M._receivedHeartbeatTimestamp = lc.Director:getCurrentTime()
        return true 
        
    -- friend
    elseif msgType == SglMsgType_pb.PB_TYPE_FRIEND_BATTLE then
        local resp = msg.Extensions[Friend_pb.SglFriendMsg.friend_battle_resp]
        local input = _M.genInputFromFriendBattleResp(resp)
        lc._runningScene:onFriendBattle(input)
        return true
    
    -- battle
    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_ATTACK then
        local resp = msg.Extensions[World_pb.SglWorldMsg.world_attack_resp]
        local input = _M.genInputFromAttackResp(resp)
        lc._runningScene:onAttack(input)
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_EXPEDITION_EX or msgType == SglMsgType_pb.PB_TYPE_WORLD_EXPEDITION_EX_BOSS then
        local resp = msg.Extensions[World_pb.SglWorldMsg.world_expedition_ex_resp]

        local input
        if msg:HasExtension(World_pb.SglWorldMsg.world_get_expedition_ex_resp) then
            input = _M.genInputFromExpeditionExResp(resp, msg.Extensions[World_pb.SglWorldMsg.world_get_expedition_ex_resp])
        else
            input = _M.genInputFromExpeditionExResp(resp)
        end
        
        lc._runningScene:onExpeditionEx(input)
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_REPLAY or msgType == SglMsgType_pb.PB_TYPE_BATTLE_REPLAY_EX or msgType == SglMsgType_pb.PB_TYPE_BATTLE_REPLAY_TUTORIAL or msgType == SglMsgType_pb.PB_TYPE_BATTLE_REPLAY_SHARE then
        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_replay_resp]
        local input = _M.genInputFromReplayResp(resp)
        lc._runningScene:onReplay(input)
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_RECOVER then
        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_recover_resp]
        _M.initConfig(resp.player_troop.info.id)
        
        local input = _M.genInputFromRecoverResp(resp, msg)
        print ('battle recover')

        if resp.type == Battle_pb.PB_BATTLE_DARK then 
            P._playerFindDark:onFind()
        end

        if V._findMatchPanel then
            V._findMatchPanel:onFind(input)
        else
            lc._runningScene:onBattleRecover(input)
        end
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_FIND_EX_CANCEL then
--        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_recover_resp]--todo dark
--        if resp.type == Battle_pb.PB_BATTLE_DARK then 
--            P._playerFindDark:onFindCancled()
--        end

        if V._findMatchPanel then
            V._findMatchPanel:hide()
        end
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_END then
        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_end_resp]
        if resp:HasField("dark_duel_end_resp") then
            P._playerFindDark:onInningEnd(resp.dark_duel_end_resp)
        end
        lc._runningScene:onBattleEnd(resp)
        return true
    
    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_BATTLE_START then       
        local resp = msg.Extensions[World_pb.SglWorldMsg.world_battle_start_resp]

        if (not resp.is_revenge) and (not resp.is_rescue) then
            P._underAttack:addBattle(resp)
        
            --[[
            if lc._runningScene._sceneId ~= ClientData.SceneId.battle then
			    local battleInfo = P._underAttack._list[#P._underAttack._list]
			    local str = string.format(Str((not battleInfo._isRevenge) and STR.JOIN_ATTACK_BEGIN or STR.JOIN_REVENGE_BEGIN), battleInfo._user._name)
                ToastManager.push(str)
            end
            --]]
        end

        return true
    
    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_BATTLE_END then
        if msg:HasExtension(World_pb.SglWorldMsg.world_battle_end_resp) then
            local resp = msg.Extensions[World_pb.SglWorldMsg.world_battle_end_resp]
        
            local log = require("Log").new(false, resp)
            P._playerLog:addLog(log, Battle_pb.PB_BATTLE_PLAYER)
            P._playerLog:sendLogDirty(require("PlayerLog").Event.defense_log_dirty)
            P:changeTrophy(log._resultType == Data.BattleResult.win and log._trophy or -log._trophy)
            if log._resultType == Data.BattleResult.lose then
                local city = P._playerWorld._cities[log._city]
                if city then
                    city:cityOccupied(log._timestamp, log._opponent._id)
                end
            end
        
		    local battleInfo = P._underAttack:removeBattle(log._opponent._id)

            --[[
            local str = ""
            if log._isWin then
                str = string.format(Str(STR.JOIN_ATTACK_WIN), log._opponent._name)
            else
                local city = P._playerWorld._cities[log._city]
                if city then
                    str = string.format(Str(STR.JOIN_ATTACK_LOSE_CITY), Str(city._info._nameSid), log._opponent._name)
                else
                    str = Str(STR.JOIN_ATTACK_LOSE)
                end
            end

            ToastManager.push(str)
            ]]--
        end
        
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_RESCUE_END then
        local cityId = msg.Extensions[World_pb.SglWorldMsg.world_rescue_end_resp]        

        -- reset city       
        local city = P._playerWorld._cities[cityId]
        if city then
            city:captureSuccess()

            if lc._runningScene._sceneId == ClientData.SceneId.world then
                V._worldScene:hideTab()
            end
        end

    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_OP_USECARD then
        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_op_usecard_resp]
        for i = 1, #resp do
            table.insert(_M._usedCardsToAdd, resp[i])
        end
        -- do not return true here
     
    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_USECARD then
        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_op_usecard_resp]
        for i = 1, #resp do
            table.insert(_M._observeUsedCards, resp[i])
        end
        
    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_OP_ONLINE then
        _M.sendBattleSync()
        _M._isOppoOnline = true
        -- do not return true here

    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_OP_OFFLINE then
        _M._isOppoOnline = false
        -- do not return true here

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_LOTTERY then
        -- lottery
        local pbRes = msg.Extensions[World_pb.SglWorldMsg.world_lottery_resp]
        local count = #pbRes
        if P._propBag:hasProps(Data.PropsId.lottery_token, count) then
            P._propBag:changeProps(Data.PropsId.lottery_token, -count)
        else 
            P:changeResource(Data.ResType.ingot, -Data._globalInfo._expeditionDialCost * count)
        end
        ClientData._lotteryPower = ClientData._lotteryPower + count

        --P:addResource(pbRes.info_id, 1, pbRes.num, false)
    
    end
    
    return false
end

function _M.onMsgAfterScene(msg)
    local msgType = msg.type
    

    return false
end
