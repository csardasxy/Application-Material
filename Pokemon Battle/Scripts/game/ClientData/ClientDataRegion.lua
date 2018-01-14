local _M = ClientData

-- region

function _M.sendRegionListReq()
    local uid = lc.App:loadUserId()
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

    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_REGION_LIST
    local req = msg.Extensions[Region_pb.SglRegionMsg.region_list_req]
    req.uid = uid
    if channelName == "OFFICIAL" or channelName == "APPSTORE" or channelName == "FACEBOOK"  then 
        if gcid ~= nil then
            req.gcid = gcid
        end
    end

    local redirectGameServer =  lc.App:getRedirectGameServer()
    if #redirectGameServer ~= 0 then
        channelName = channelName..'_'..redirectGameServer
    end
    req.channel = channelName
    
    lc.log("Region List UID:%s, GCID:%s", req.uid, req.gcid)

    _M.sendProtoMsg(msg)
end

-- skin

function _M.sendSetSkin(infoId, skinId)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_USER_SET_SKIN
    local req = msg.Extensions[User_pb.SglUserMsg.user_set_skin_req]
    req.info_id = infoId    
    req.skin_id = skinId
    _M.sendProtoMsg(msg)    
end

function _M.sendBuySkin(skinId, day)
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_SHOP_SKIN
    msg.Extensions[Shop_pb.SglShopMsg.shop_buy_req] = skinId
    msg.Extensions[Shop_pb.SglShopMsg.shop_buy_type_req] = day
    _M.sendProtoMsg(msg)    
end

-- update, region

function _M.switchToUpdateScene()
    _M.disconnect(false)
    lc.App:switchToUpdateScene()
    
    _M.switchSchedulerID = lc.Scheduler:scheduleScriptFunc(function(dt)
        require("CardThumbnail").releasePool()
        lc.Pool.clear("IconWidget")
        lc.App:unloadRes("extend.lan")
        TextureManager.clear()

        -- remove all listeners
        for _, listener in ipairs(_M._evtListeners) do
            lc.Dispatcher:removeEventListener(listener)
        end
        _M._evtListeners = {}

        _M.unloadCityUnionRes()
        _M.unloadBattleRes()

        ClientData.unloadLCRes({"cards_back.jpm", "cards_back.png.sfb"})
        ClientData.unloadLCRes({"general.jpm", "general.png.sfb"})
        ClientData.unloadLCRes({"avatar.jpm", "avatar.png.sfb"})

        for i = 1, ClientData.CARDS_IMG_COUNT do
            local name = "cards_img_"..i
            ClientData.unloadLCRes({name..".jpm", name..".png.sfb"})
        end

        lc.FrameCache:removeSpriteFrames();
        lc.TextureCache:removeAllTextures();
        lc.Director:purgeCachedData();

        lc.Scheduler:unscheduleScriptEntry(_M.switchSchedulerID)
    end, 0, false)
end

function _M.switchToRegionScene()
    _M.disconnect(false)
    _M._regions = {}
    _M.saveUserRegion()
    lc.replaceScene(require("RegionScene").create())
end

function _M.saveUserRegion()
    local region = nil
    if _M._userRegion ~= nil and _M._userRegion._id ~= nil then
        region = _M._regions[_M._userRegion._id]
    end
    if region ~= nil then
        local str = string.format("%d:%s:%s", region._id, region._host, region._name)
        lc.UserDefault:setStringForKey(_M.ConfigKey.region_info, str)
    else
        lc.UserDefault:setStringForKey(_M.ConfigKey.region_info, "")
    end 
end

function _M.loadUserRegion()
    _M._userRegion = {}
    local str = lc.UserDefault:getStringForKey(_M.ConfigKey.region_info, "")
    if #str ~= 0 then
        local parts = string.splitByChar(str, ':')
        if #parts == 4 then
            _M._userRegion._id = tonumber(parts[1])
            _M._userRegion._ip = parts[2]
            _M._userRegion._port = parts[3]
            _M._userRegion._name = parts[4]
        end
    end

    if lc.PLATFORM == cc.PLATFORM_OS_WINDOWS then
        if false then
            _M._userRegion._id = 3002
            _M._userRegion._ip = "192.168.1.109"
            _M._userRegion._port = 9191
            _M._userRegion._name = "TEST"
        end
    end
    
    print ("User Region info: ", _M._userRegion._id, _M._userRegion._ip, _M._userRegion._port, _M._userRegion._name)
end

function _M.hasUserRegion()
    return _M._userRegion._id ~= nil and _M._userRegion._ip ~= nil and _M._userRegion._port ~= nil and _M._userRegion._name ~= nil
end

