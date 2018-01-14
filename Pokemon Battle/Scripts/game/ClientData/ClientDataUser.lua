local _M = ClientData

-- user

function _M.sendUserRegister()
    local uid = lc.App:loadUserId()
    local rid = _M._userRegion._id
    local deviceInfo = lc.getDeviceInfo()
	local version = _M.getVersion()
    local binVersion = _M.getBinVersion()
    local channelName = lc.App:getChannelName()

    local gcid = uid
    if channelName == "OFFICIAL" or channelName == "APPSTORE" then 
        if uid == "UDID" then gcid = nil end
        uid = lc.App:getUdid()
    elseif channelName == "FACEBOOK" then
        if uid == "UDID" then 
            gcid = nil 
            uid = lc.App:getUdid()
        else
            uid = ""
        end
    end

    local alias = lc.App:bindAlias(channelName..uid..rid)
    if channelName == 'APPSTORE' then
        alias = ClientData.getAppId().."."..alias
    elseif channelName == 'FACEBOOK' then
        alias = ClientData.getAppId().."."..alias
    elseif channelName == 'ASDK' then
        local subChannelName = ClientData.getSubChannelName()
        local appId = ClientData.getAppId()
        alias = subChannelName.."."..appId.."."..alias
    end

    lc.log("register to game server: %s with (uid: %s, rid: %d, alias: %s, device_info: %s, version: %s)", _M._userRegion._ip, uid, rid, alias, deviceInfo, version)

    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_REGISTER
    local req = msg.Extensions[User_pb.SglUserMsg.user_reg_req] 
    req.uid = uid
    req.rid = rid
    req.cid = alias
    req.device_info = deviceInfo
    req.version = version   
    req.binary_version = binVersion
    req.appid = ClientData.getAppId()

    if channelName == "APPSTORE" and lc.App.getIdfa ~= nil then
        req.idfa = lc.App:getIdfa()
    end

    if channelName == "OFFICIAL" or channelName == "APPSTORE" or channelName == "FACEBOOK"  then 
        if gcid ~= nil then
            msg.Extensions[User_pb.SglUserMsg.user_gcid_req] = gcid
        end
    end

    _M._regIds = string.format("gcid:%s, uid:%s", gcid, uid)

    local redirectGameServer =  lc.App:getRedirectGameServer()
    if #redirectGameServer ~= 0 then
        channelName = channelName..'_'..redirectGameServer
    end
    req.channel = channelName 

    if ClientData._needSendBattleDebugLog and ClientData._battleDebugLog then
        msg.Extensions[Battle_pb.SglBattleMsg.battle_log_req] = ClientData._battleDebugLog
        ClientData._needSendBattleDebugLog = false
    end

    _M.sendProtoMsg(msg)
end

function _M.sendUserLogin(userId)
    local uid = lc.App:loadUserId()
    local rid = _M._userRegion._id
    local deviceInfo = lc.getDeviceInfo()
	local version = _M.getVersion()
    local binVersion = _M.getBinVersion()
    local channelName = lc.App:getChannelName()
    local alias = lc.App:bindAlias(channelName..uid..rid)

    if channelName == 'APPSTORE' then
        alias = ClientData.getAppId().."."..alias
    elseif channelName == 'FACEBOOK' then
        alias = ClientData.getAppId().."."..alias
    elseif channelName == 'ASDK' then
        local subChannelName = ClientData.getSubChannelName()
        local appId = ClientData.getAppId()
        alias = subChannelName.."."..appId.."."..alias
    end

    lc.log("login to game server: %s with (userId: %s, rid: %d, alias: %s, device_info: %s, version: %s)", _M._userRegion._ip, userId, rid, alias, deviceInfo, version)

    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_LOGIN
    local req = msg.Extensions[User_pb.SglUserMsg.user_login_req]
    req.user_id = userId
    req.cid = alias
    req.device_info = deviceInfo
    req.version = version
    req.binary_version = binVersion

    if ClientData._needSendBattleDebugLog and ClientData._battleDebugLog then
        msg.Extensions[Battle_pb.SglBattleMsg.battle_log_req] = ClientData._battleDebugLog
        ClientData._needSendBattleDebugLog = false
    end

    _M.sendProtoMsg(msg)
end

function _M.sendUserVisit(userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_VISIT
    msg.Extensions[User_pb.SglUserMsg.user_visit_req] = userId
    _M.sendProtoMsg(msg)
end

-- User

function _M.sendChangeName(name)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_NAME 
    msg.Extensions[User_pb.SglUserMsg.user_set_name_req] = name
    _M.sendProtoMsg(msg)
end

function _M.sendChangeNameGuide(name)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_NAME_GUIDE 
    msg.Extensions[User_pb.SglUserMsg.user_set_name_req] = name
    
    _M.sendProtoMsg(msg)
end

function _M.sendSetAvatar(infoId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_AVATAR
    msg.Extensions[User_pb.SglUserMsg.user_set_avatar_req] = infoId
    _M.sendProtoMsg(msg)     
end

function _M.sendSetAvatarFrame(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_AVATAR_FRAME
    msg.Extensions[User_pb.SglUserMsg.user_set_avatar_frame_req] = id
    _M.sendProtoMsg(msg)  
end

function _M.sendSetAvatarImage(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_AVATAR_IMAGE
    msg.Extensions[User_pb.SglUserMsg.user_set_avatar_image_req] = id
    _M.sendProtoMsg(msg)  
end


function _M.sendSetCardBack(id)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_CARD_BACK
    msg.Extensions[User_pb.SglUserMsg.user_set_card_back_req] = id
    _M.sendProtoMsg(msg)  
end

function _M.sendUserGiftExchange(codeId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_CLAIM_GIFT 
    msg.Extensions[User_pb.SglUserMsg.user_claim_gift_req] = codeId
    _M.sendProtoMsg(msg)
end

function _M.sendChatBan(userId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_BAN_CHAT
    msg.Extensions[User_pb.SglUserMsg.user_ban_chat_req] = userId
    _M.sendProtoMsg(msg)
end

function _M.sendUnlockCharacter(characterId, isUseIngot)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_UNLOCK_CHARACTER
    local req = msg.Extensions[User_pb.SglUserMsg.user_unlock_character_req]
    req.char_id = characterId
    req.use_ingot = isUseIngot
    _M.sendProtoMsg(msg)
end

function _M.sendSetCharacter(characterId, isGuide)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_CHARACTER
    msg.Extensions[User_pb.SglUserMsg.user_set_character_req] = characterId

    if isGuide then
        _M.appendGuideIdIfNeed(msg)
    end
    _M.sendProtoMsg(msg)
end
