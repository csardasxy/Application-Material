local _M = ClientData

local SOCKET_LOG_NAME           = "socketLog.txt"

-- send extend data

function _M.submitRoleData(submitType)
    local roleData = 
    {
        roleId = P._id, 
        roleName = string.gsub(P._name, "'", ""),
        roleLevel = P:getMaxCharacterLevel(),
        roleVipLevel = P._vip,
        roleRegTime = P._regTime,

        zoneId = _M._userRegion._id,
        zoneName = string.gsub(_M._userRegion._name, "'", ""),

        unionId = P._unionId or 0,
        unionName = string.gsub(P._unionName or "", "'", ""),

        ingot = P._ingot,
        gold = P._gold,
        exp = P._exp
    }
    local roleDataStr = json.encode(roleData)
    lc.App:submitExtendData(submitType, roleDataStr)
end
    
-- send proto messages

function _M.appendGuideIdIfNeed(msg)
    local guideId = GuideManager.getCurSaveGuideId()
    if guideId then msg.Extensions[User_pb.SglUserMsg.user_set_guide_req] = guideId end
end

function _M.sendProtoMsg(msg)
    if _M._socket ~= nil then
        msg.dt = _M.getRunningTime() * 1000
        _M._socket:sendProtoMsg(msg)
    end
end

function _M.sendHeartBeat()
     if _M._sentHeartbeatTimestamp ~= nil and _M._receivedHeartbeatTimestamp ~= nil then
        local gap = _M._sentHeartbeatTimestamp - _M._receivedHeartbeatTimestamp
        --local gap = _M.getRunningTime()
        --lc.log ("[NETWORK] heartbeat %d, %d, %d", _M._sentHeartbeatTimestamp, _M._receivedHeartbeatTimestamp, gap)
        if gap > 60.0 then
            lc.log ("[NETWORK] heartbeat lost", gap)
            lc._runningScene:reconnect(Str(STR.HEARTBEAT_LOST))
            
            _M.writeSocketLog(_M.SocketLog.reconnect, gap)
            
            return
        elseif gap > 30.0 then
            --lc.log ("[NETWORK] heartbeat gap", gap)
            if lc._runningScene._reloadDialog == nil then
                if lc.FrameCache:getSpriteFrame("img_icon_wifi_low") ~= nil then
                    local richText = ccui.RichTextEx:create()
                    local ico = cc.Sprite:createWithSpriteFrameName("img_icon_wifi_low")
                    ico:runAction(lc.rep(lc.sequence(0.5, cc.Show:create(), 0.5, cc.Hide:create()))) 
                    richText:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, ico))
                    richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_DARK, 255, Str(STR.HEARTBEAT_GAP), V.TTF_FONT, V.FontSize.S1))
                    _M._heartbeatGapNoticeId = NoticeManager.show(richText, nil, _M._heartbeatGapNoticeId)
                end  
            end

            _M.writeSocketLog(_M.SocketLog.unstable, gap)
        else 
            if _M._heartbeatGapNoticeId ~= nil then
                NoticeManager.hide(_M._heartbeatGapNoticeId)
                _M._heartbeatLostNoticeId = nil
            end
            if _M._heartbeatLostNoticeId ~= nil then
                NoticeManager.hide(_M._heartbeatLostNoticeId)
                _M._heartbeatLostNoticeId = nil
            end

            _M.writeSocketLog(_M.SocketLog.recover, gap)
        end
    end
    
    _M._sentHeartbeatTimestamp = lc.Director:getCurrentTime()
        
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_HEART_BEAT
    _M.sendProtoMsg(msg)

    -- Check local time hour changed
    local hour = math.floor(_M.getCurrentTime() / 3600)
    if _M._hour == nil or _M._hour ~= hour then
        _M._hour = hour
        local eventCustom = cc.EventCustom:new(Data.Event.time_hour_changed)
        lc.Dispatcher:dispatchEvent(eventCustom)
    end

    -- Check server refresh every day
    local hour, day = _M.getServerDate()
    if hour then
        if _M._serverHour == nil or _M._serverHour ~= hour then
            _M._serverHour = hour
            local eventCustom = cc.EventCustom:new(Data.Event.server_hour_changed)
            lc.Dispatcher:dispatchEvent(eventCustom)

            if _M._serverDay == nil or _M._serverDay ~= day then
                if _M._serverDay then
                    lc._runningScene:showReloadDialog(Str(STR.NEW_DAY_BEGIN))
                end

                _M._serverDay = day
                local eventCustom = cc.EventCustom:new(Data.Event.server_day_changed)
                lc.Dispatcher:dispatchEvent(eventCustom)
            end
        end
    end
end

function _M.checkSocketLog()
    local log = lc.readFile(lc.File:getWritablePath()..SOCKET_LOG_NAME)
    
    if log == nil or log == "" then
        _M._socketLog = log
        return
    end

    local lines = string.splitByChar(log, "\n")
    for _, line in ipairs(lines) do
        if line ~= "" then
            _M.sendUserEvent({socketLog = line})
        end
    end

    _M._socketLog = nil
    lc.writeFile(lc.File:getWritablePath()..SOCKET_LOG_NAME, "")
end

function _M.writeSocketLog(logType, timeGap)
    if _M._lastSocketLogType == logType or (_M._lastSocketLogType ~= _M.SocketLog.unstable and logType == _M.SocketLog.recover) then return end
        
    _M._lastSocketLogType = logType
    
    local time = os.date("%c", _M.getCurrentTime())
    local line = string.format("%s %s (gap:%d)\n", time, logType, timeGap or 0)

    _M._socketLog = (_M._socketLog or "")..line
    lc.writeFile(lc.File:getWritablePath()..SOCKET_LOG_NAME, _M._socketLog)
end


-- other

function _M.sendQueryGcid(gcid)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_QUERY_GCID
    if gcid ~= "" and gcid ~= "UDID" then
        msg.Extensions[User_pb.SglUserMsg.user_gcid_req] = gcid
    end
    _M.sendProtoMsg(msg)
end

function _M.sendBattleLoadingDone()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_LOADING_DONE
    _M.sendProtoMsg(msg)
end

function _M.sendServerPushSwitch(flag)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_CONFIG
    msg.Extensions[User_pb.SglUserMsg.user_set_config_req] = flag
    _M.sendProtoMsg(msg)
end

function _M.sendUserEvent(data)
    if _M.isLogin() then
        local msg = SglMsg_pb.SglReqMsg()
        msg.type = SglMsgType_pb.PB_TYPE_USER_SET_EVENT
        msg.Extensions[User_pb.SglUserMsg.user_set_event_req] = json.encode(data)
        _M.sendProtoMsg(msg)
    end
end

function _M.sendUserFacebook(cid)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_FACEBOOK
    msg.Extensions[User_pb.SglUserMsg.user_facebook_req] = cid
    _M.sendProtoMsg(msg)
end

function _M.sendBuyDepot(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_SHOP_MAGICBOX
    msg.Extensions[Shop_pb.SglShopMsg.shop_buy_req] = id
    _M.sendProtoMsg(msg)
end

function _M.sendBuyUnion(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_SHOP_UNION
    msg.Extensions[Shop_pb.SglShopMsg.shop_buy_req] = id
    _M.sendProtoMsg(msg)
end

function _M.sendBuyRare(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_SHOP_RARE
    msg.Extensions[Shop_pb.SglShopMsg.shop_buy_req] = id
    _M.sendProtoMsg(msg)

    P._playerMarket._rareGoodsMap[id] = 1
end

function _M.sendBuyDiamond(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_SHOP_DIAMOND
    msg.Extensions[Shop_pb.SglShopMsg.shop_buy_req] = id
    _M.sendProtoMsg(msg)
end

function _M.sendResetFundTask(cid)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BONUS_DAILY_TASK_RESET
    msg.Extensions[Bonus_pb.SglBonusMsg.daily_task_reset_req] = cid
    _M.sendProtoMsg(msg)
end
