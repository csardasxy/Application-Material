local _M = {}

_M.DEBUG_GUIDE_ID = nil
if lc.PLATFORM == cc.PLATFORM_OS_WINDOWS then
    -- Try to read config
    local data = lc.readFile("config.json")
    if data and data ~= "" then
        _M._cfg = json.decode(data).init_cfg
    else
        _M._cfg = {}
    end

    _M.DEBUG_USER_ID = _M._cfg.userId
    if _M.DEBUG_USER_ID == 0 then _M.DEBUG_USER_ID = nil end
else
    _M._cfg = {}
    _M.DEBUG_USER_ID = nil
end
_M.DEBUG_UNION = false

----------------- Constant ----------------- 

--[[--
camera
--]]--
_M.CAMERA_2D_FLAG           = 1
_M.CAMERA_3D_FLAG           = 2
_M.BIRDVIEW_ANGLE           = 10

--[[--
data
--]]--
_M.MAX_INPUT_LEN            = 50
_M.MAX_NAME_DISPLAY_LEN     = 190
_M.MAX_GROUP_NAME_DISPLAY_LEN     = 170
_M.MAX_MSG_COUNT            = 100
_M.MAX_UNION_MSG_COUNT      = 30

_M.CARDS_IMG_COUNT          = 3

-----------------  Enum ----------------- 

_M.ConfigKey = 
{
    -- global user default
    gexin_push_id = "GEXIN_PUSH_ID",    -- do not change this name since used in LuaGame
    music_on = "MUSIC_ON",              -- do not change this name since used in LuaGame
    effect_on = "EFFECT_ON",
    video_played = "VIDEO_PLAYED",
    region_info = "REGION_INFO",
    agreement = "AGREEMENT",

    -- push setting
    push_grain_noon = "PUSH_GRAIN_NOON",
    push_grain_night = "PUSH_GRAIN_NIGHT",
    push_reward_send = "PUSH_REWARD_SEND",
    push_copy_pvp = "PUSH_COPY_PVP",
    push_copy_pvp_unlock = "PUSH_COPY_PVP_UNLOCK",
    push_union_help = "PUSH_UNION_HELP",
    push_grain_full = "PUSH_GRAIN_FULL",
    push_gold_full = "PUSH_GOLD_FULL",
    push_guard_fragment = "PUSH_GUARD_FRAGMENT",
    
    -- each region user
    last_login = "LAST_LOGIN",
    cur_troop = "CUR_TROOP",
    new_friend = "NEW_FRIEND",
    new_section = "NEW_SECTION",
    
    new_card = "NEW_CARD",

    new_world_msg = "NEW_WORLD_MSG",
    new_union_msg = "NEW_UNION_MSG",
    new_bulletin_msg = "NEW_NEWS_MSG",
    new_battle_msg = "NEW_BATTLE_MSG",
    
    new_union_mail = "NEW_UNION_MAIL",
    new_friend_mail = "NEW_FRIEND_MAIL",
    new_announce = "NEW_ANNOUNCE",
    new_notice_mail = "NEW_NOTICE_MAIL",
    
    new_attack_log = "NEW_ATTACK_LOG",
    new_defense_log = "NEW_DEFENSE_LOG",
    new_union_attack_log = "NEW_UNION_ATTACK_LOG",
    new_union_defense_log = "NEW_UNION_DEFENSE_LOG",
    new_clash_log = "NEW_CLASH_LOG",
    new_ladder_log = "NEW_LADDER_LOG",
    
    lock_level_city = "LOCK_LEVEL_CITY",    
    lock_level_split = "LOCK_LEVEL_SPLIT",
    lock_level_equip = "LOCK_LEVEL_EQUIP",
    lock_level_herocenter = "LOCK_LEVEL_HEROCENTER",
    lock_level_battle = "LOCK_LEVEL_BATTLE",
    lock_level_vip = "LOCK_LEVEL_VIP",
    
    -- battle relative
    battle_speed = "BATTLE_SPEED",    

    -- prompt rate game
    prompt_rate_game = "PROMPT_RATE_GAME",

    last_level = "LAST_LEVEL",

    activity_show_day = "ACTIVITY_SHOW_DAY",
}

_M.SceneId = 
{
    loading                 = 1,
    city                    = 2,
    world                   = 3,
    battle                  = 4,
    tavern                  = 5,
    
    factory_monster         = 7,
    factory_magic           = 8,
    factory_trap            = 9,
    factory_rare            = 10,
    --barrack                 = 11,
    market                  = 12,
    store                   = 14,
    pawnshops               = 15,
    illustrations           = 16,
    manage_troop            = 17,
    res_switch              = 18,
    expedition              = 19,
    race                    = 20,
    train                   = 21,
    region                  = 22,
    visit                   = 23,
    activity                = 24,
    
    union                   = 26,
    union_world             = 27,
    union_war               = 28,
    guard                   = 29,
    crusade                 = 30,
    checkin                 = 32,    
    find                    = 33,
    depot                   = 34,
    transfer                = 35,
    recharge                = 36,
    activity                = 37,
    lottery                 = 38,
    skin_shop               = 39,
    room                    =40,
    in_room             = 41,
    union_battle        = 50,
    union_battle_group = 51,
}

_M.ZOrder = 
{
    ui                      = 10,
    side                    = 20,
    form                    = 30,
    effect                  = 40,
    guide                   = 50,
    indicator               = 60,
    dialog                  = 70,
    toast                   = 80,
}

_M.OnMsgPriority = 
{
    before_scene            = 0,
    scene                   = 100,
    after_scene             = 200,
}

_M.SocketStatus = 
{
    disconnected            = 1,
    connected               = 2,
    login                   = 3
}

_M.LCResType = 
{
    texture                 = 0x00000001,
    sprite_frame            = 0x00000002,
    sprite_frames           = 0x00000004 
}

_M.SocketLog =
{
    unstable                = "unstable",
    recover                 = "recover",
    reconnect               = "reconnect",
    disconnect              = "disconnect",
    reachability_changed    = "reachability_changed"
}

_M._lcres = {}

-----------------  Local -----------------

local LC_RES_CRYPT_LEN          = 0x1000

-- init and events

function _M.init()
    --[[
    -- Create card get path related data
    for k, v in pairs(Data._levelInfo) do
        for i = 1, #v._pid do
            local info = Data.getInfo(v._pid[i])
            if info then
                if info._chapters == nil then info._chapters = {} end
                table.insert(info._chapters, v)
            end
        end
    end
    ]]
    
    _M._msgListeners = {}
    _M._errorListeners = {}
    
    _M._evtListeners = {}
    table.insert(_M._evtListeners, lc.addEventListener(Data.Event.application, function(event) _M.onApplicationEvent(event) end))
    
    table.insert(_M._evtListeners, lc.addEventListener(require("Socket_pb").Event.connect_fail, function(event) _M.onConnectFail() lc._runningScene:onConnectFailEvent(event) end))
    table.insert(_M._evtListeners, lc.addEventListener(require("Socket_pb").Event.disconnect, function(event) _M.onDisconnect() lc._runningScene:onDisconnectEvent(event) end))
    table.insert(_M._evtListeners, lc.addEventListener(GuideManager.Event.seek, function(event) lc._runningScene:onGuide(event) end))
    table.insert(_M._evtListeners, lc.addEventListener(Data.Event.friend, function(event) lc._runningScene:onFriend(event._event) end))
    table.insert(_M._evtListeners, lc.addEventListener(Data.Event.mail, function(event) lc._runningScene:onMail(event._event) end))
    
    _M.addMsgListener(_M, function(msg) return _M.onMsgBeforeScene(msg) end, _M.OnMsgPriority.before_scene)

    _M.addMsgListener(_M, function(msg)
        local rs = lc._runningScene
        if rs and rs.onMsg then
            return rs:onMsg(msg)
        end
    end, _M.OnMsgPriority.scene)

    _M.addMsgListener(_M, function(msg) return _M.onMsgAfterScene(msg) end, _M.OnMsgPriority.after_scene)
    
    _M.addErrorListener(_M, function(error)
        local rs = lc._runningScene
        if rs and rs.onError then
            return rs:onError(error)
        end
    end, 0)
    
    _M.toggleAudio(lc.Audio.Behavior.music, lc.UserDefault:getBoolForKey(_M.ConfigKey.music_on, true))
    _M.toggleAudio(lc.Audio.Behavior.effect, lc.UserDefault:getBoolForKey(_M.ConfigKey.effect_on, true))
    
    lc.Director:setIdleTime(180)
    lc.Director:setBlurParam(512, 384, "res/shader/blur_gaussian_x.fsh", "res/shader/blur_gaussian_y.fsh")
   
    _M.initCamera3D()

    _M._player = require("Player").new()
    P = _M._player

	--if _M._unionWorld == nil then _M._unionWorld = require("UnionWorld").new() end
    _M._savedUnionData = {}

    -- option: bit flag
    -- bit 1: under appstore review
    -- bit 2: ...
    _M._option = lc.App.getOption and lc.App:getOption() or 0
    
	_M._socketStatus = _M.SocketStatus.disconnected
	
    local now = os.time()
    _M._timezone = os.difftime(now, os.time(os.date("!*t", now)))

    _M._btnClickTime = 0

end

function _M.loadLCRes(fileName)
    print (fileName)

    if ClientData.isAppStoreReviewing() and fileName == 'res/city.lcres' then
        _M.loadLCRes('res/city_2.lcres')
    end

    local binVersion = _M.getBinVersion()
    if binVersion == "1.5.0" then
        local data = lc.readFile(fileName, 0, 44)
        local dataLen = #data
       
        if string.sub(data, 1, 3) ~= "LCR" then return resNames end
        local n, version, serial, step = string.unpack(string.sub(data, 4, 12), "b<i<i")
        local pos = 44
    
        local resCheckMap = {jpg = nil, mask = nil, sfb = nil}
        local resNames = {}

        local checkResReady = function(res)
            local jpg, mask, sfb = res.jpg, res.mask, res.sfb
            if jpg and mask and sfb then
                local texture = lc.TextureCache:addImageWithMask(jpg.data, jpg.len, mask.data, mask.len, jpg.name)
                _M._lcres[jpg.name] = texture

                local sfbName = sfb.name
                lc.FrameCache:addSpriteFramesWithData(sfb.data, sfb.len, texture)
                _M._lcres[sfbName] = _M.LCResType.sprite_frames

                resCheckMap = {jpg = nil, mask = nil, sfb = nil}
                       
                local evt = cc.EventCustom:new(Data.Event.resource)
                evt:setUserString(sfbName)
                lc.Dispatcher:dispatchEvent(evt)
            end
        end

        while true do
            data = lc.readFile(fileName, pos, 256)
            if data == nil then break end
    
            local n, isCompress, isCryptAll, oriLen, nameLen = string.unpack(data, "bb<Ib")
            local name = string.sub(data, 8, 7 + nameLen)
            name = _M.decrypt(name, serial, 1)
            serial = bit.band(serial + step, 0xFFFFFFFF)
            local n, resLen = string.unpack(string.sub(data, 8 + nameLen), "<I")
            --print (name, oriLen, resLen)
            pos = pos + 11 + nameLen

            if _M._lcres[name] == nil then
                local resData = lc.readFile(fileName, pos, resLen)

                if string.hasSuffix(name, ".jpm") then
                    resData = _M.decrypt(resData, serial, isCryptAll)

                    local _, jpgLen, maskLen  = string.unpack(string.sub(resData, 5, 12), "<I<I")

                    local jpgData = string.sub(resData, 13, 12 + jpgLen)
                    resCheckMap.jpg = {name = name, data = jpgData, len = jpgLen}

                    local maskData = string.sub(resData, 13 + jpgLen, 12 + jpgLen + maskLen)
                    resCheckMap.mask = {data = maskData, len = maskLen}

                    checkResReady(resCheckMap)

                    table.insert(resNames, name)

                elseif string.hasSuffix(name, ".sfb") then
                    resData = _M.decrypt(resData, serial, isCryptAll)

                    resCheckMap.sfb = {name = name, data = resData, len = resLen}
                    checkResReady(resCheckMap)

                    table.insert(resNames, name)

                elseif (string.hasSuffix(name, ".lan")) then
                    resData = _M.decrypt(resData, serial, isCryptAll)
                    _M.addLanguage(resData)
                end
            else
                local evt = cc.EventCustom:new(Data.Event.resource)
                evt:setUserString(name)
                lc.Dispatcher:dispatchEvent(evt) 
            end

            serial = bit.band(serial + step, 0xFFFFFFFF)
            pos = pos + resLen
        end
    
        data = nil
        return resNames
    else
        return lc.App:loadRes(fileName)
    end
end

function _M.unloadLCRes(resNames)
    local binVersion = _M.getBinVersion()
    if binVersion == "1.5.0" then
        if #resNames == 0 then return end

        for _, name in ipairs(resNames) do
            print ("unload res", name)
        
            local res = _M._lcres[name]
            if type(res) == "userdata" then
                lc.TextureCache:removeTextureForKey(name)
                lc.FrameCache:removeSpriteFramesFromTexture(res)
            end
        
            _M._lcres[name] = nil
        end
    else
        lc.App:unloadRes(resNames)
    end
end

function _M.str(id, isMultiLine)
    local binVersion, str = _M.getBinVersion()
    if binVersion == "1.5.0" then
        str = _M._language[id]
        if str and isMultiLine then
            str = string.gsub(str, "\\n", "\n")
        end        
    else
        str = lc.str(id, isMultiLine)
    end

    if str == nil or str == "" then
        local info = string.format("region:%s, id:%s", _M._userRegion and _M._userRegion._id or "NA", P and P._id or "NA")
        local trace = string.format("[LUA ERROR]: <SceneId:%s> %s\n%s ", lc._runningScene and lc._runningScene._sceneId or "NA", string.format("Faild to get string id = %s", tostring(id)), debug.traceback())
        print (trace)

        if lc.PLATFORM ~= cc.PLATFORM_OS_WINDOWS then
            onLuaException(info, trace)
        end
    end

    return str
end

function _M.decrypt(data, serial, cryptAll)
    local decryptedData = ""
    if cryptAll == 1 or (#data <= LC_RES_CRYPT_LEN) then
        decryptedData = string.decrypt(data, serial)
    else
        decryptedData = string.decrypt(string.sub(data, 1, LC_RES_CRYPT_LEN), serial)..string.sub(data, LC_RES_CRYPT_LEN + 1)
    end
    return decryptedData
end

function _M.addLanguage(data)
    _M._language = {}
    local lines = string.splitByChar(data, '\n')
    for i = 1, #lines do
        local lang
        local parts = string.splitByChar(lines[i], ',')
        local j = 1
        local len = #parts
        while true do
            local part = parts[j]
            if part[1] == '"' then
                while true do
                    if j < #parts then
                        j = j + 1
                        part = part..parts[j]
                    end
                    if part[-1] == '"' then break end
                end
                part = string.sub(part, 2, #part - 1) 
            end
            
            lang = part
            -- only read first col in Chinese
            break
        end
        _M._language[#_M._language + 1] = lang
    end
end

function _M.getAppId()
    return lc.App.getAppId and lc.App:getAppId() or ""
end

function _M.getAppName()    
    local channelName = lc.App:getChannelName()
    local redirectChannelName = lc.App:getRedirectGameServer()
    if channelName == "ASDK" then
        local appId = ClientData.getAppId()
        -- 1, 8, 12, 13, 14, 18, 27
        if appId == '1223968820' or appId == '1233056141' or appId == '1238592436' or appId == '1253377972' or appId == '1258093284' or appId == '1266610857' or appId == '1279610129' then return Str(STR.APP_NAME_JDZC)
        -- 2, 9, 23
        elseif appId == '1224018227' or appId == '1233068376' or appId == '1276986300' then return Str(STR.APP_NAME_JDXY)
        -- 3
        elseif appId == '1224451743' then return Str(STR.APP_NAME_JDWG)
        -- 4, 21
        elseif appId == '1226367282' or appId == '1268939521' then return Str(STR.APP_NAME_YXJDW)
        -- 5
        elseif appId == '1245141618' then return Str(STR.APP_NAME_JDGS)
        -- 6, 29
        elseif appId == '1227413760' or appId == '1286948701' then return Str(STR.APP_NAME_JDW)
        -- 7
        elseif appId == '1227583177' then return Str(STR.APP_NAME_ZQJDW)
        -- 10, 24
        elseif appId == '1233975630' or appId == '1271285460' then return Str(STR.APP_NAME_JDYXW)
        -- 11
        elseif appId == '1243370767' then return Str(STR.APP_NAME_YXWDM)
        -- 15
        elseif appId == '1263797229' then return Str(STR.APP_NAME_HDLL)
        -- 16
        elseif appId == '1248760084' then return Str(STR.APP_NAME_JDZC)..'OL'
        -- 17
        elseif appId == '1249631440' then return Str(STR.APP_NAME_YXS)
        -- 19
        elseif appId == '1263901941' then return Str(STR.APP_NAME_JDXSD)
        -- 20, 26
        elseif appId == '1268933253' or appId == '1278820492' or appId == '10037' then return Str(STR.APP_NAME_DJLX)
        -- 22
        elseif appId == '1270144966' then return Str(STR.APP_NAME_KZCS)
        -- 25
        elseif appId == '1274926810' then return Str(STR.APP_NAME_YXKPW)
        -- 28
        elseif appId == '1282829449' then return Str(STR.APP_NAME_YXZC)
        
        else return Str(STR.APP_NAME_JDZC) 

        end
    else
        return Str(STR.APP_NAME_JDZC)
    end
end

function _M.getSubChannelName()
    local channelName = lc.App:getChannelName()
    local subChannelName = ''
    if lc.PLATFORM == cc.PLATFORM_OS_WINDOWS then
        local appId = ClientData.getAppId();
		if appId == "10006" or appId == "10018"	then subChannelName = 'yyb'
		elseif #appId == 5 then subChannelName = 'uc'
		else subChannelName = 'appstore'
        end
    else
        if channelName == 'ASDK' then 
            if lc.PLATFORM == cc.PLATFORM_OS_IPHONE or lc.PLATFORM == cc.PLATFORM_OS_IPAD then
                subChannelName = 'appstore'
            elseif lc.PLATFORM == cc.PLATFORM_OS_ANDROID then
                subChannelName = lc.File:getDataFromFile('AsdkChannel.txt') or 'android'
            end
        elseif channelName == 'OFFICIAL' then 
            if lc.PLATFORM == cc.PLATFORM_OS_IPHONE or lc.PLATFORM == cc.PLATFORM_OS_IPAD then
                subChannelName = 'appstore'
            elseif lc.PLATFORM == cc.PLATFORM_OS_ANDROID then
                subChannelName = 'uc'
            end
        end
    end
    return subChannelName
end

function _M.getSubChannelType()
    local subChannelName = ClientData.getSubChannelName()
    if subChannelName == 'appstore' then return 1
    elseif subChannelName == 'yyb' then return 3
    elseif subChannelName ~= '' then return 0
    else return -1
    end
end

function _M.initCamera3D()
    local size = lc.Director:getWinSize()
    local zeye = lc.Director:getZEye()

    local cam = cc.Camera:createPerspective(60, size.width / size.height, 10, zeye + size.height / 2)
    cam:setPosition3D{x = size.width / 2, y = size.height / 2, z = zeye}
    cam:lookAt({x = size.width / 2, y = size.height / 2, z = 0}, {x = 0, y = 1, z = 0})
    cam:setCameraFlag(_M.CAMERA_3D_FLAG)
    cam:retain()
    
    _M._camera3D = cam
end

function _M.addNotification(key, sid, t)
    if t > 0 and lc.UserDefault:getBoolForKey(key, true) then
        lc.App:addNotification(sid, Str(sid), t)
        lc.log("AddNotification key:%s, time:%s", key, _M.formatPeriod(t))
    end
end

function _M.isLogin()
    return _M._socketStatus == _M.SocketStatus.login
end

function _M.onApplicationEvent(event)
    local str = event:getUserString()
    if str == "ENTER_BACKGROUND" then
        local scene = lc._runningScene
        if scene then
            --[[
            _M.addNotification(_M.ConfigKey.push_reward_send, STR.PUSH_TIP_REWARD_SEND, _M.getServerDayTimeRemain(21))

            if P._id then
                _M.addNotification(_M.ConfigKey.push_copy_pvp_unlock, STR.PUSH_TIP_COPY_PVP_UNLOCK, P._nextCopyPvp - _M.getCurrentTime())
                _M.addNotification(_M.ConfigKey.push_grain_full, STR.PUSH_TIP_GRAIN_FULL, P._playerCity:getGrainTime())
                _M.addNotification(_M.ConfigKey.push_gold_full, STR.PUSH_TIP_GOLD_FULL, P._playerCity:getGoldTime())
            end

            if lc.PLATFORM ~= cc.PLATFORM_OS_IPHONE and lc.PLATFORM ~= cc.PLATFORM_OS_IPAD then
                _M.sendUserEvent{sceneId = scene._sceneId, sync = scene._needSyncData, act = "Enter Background"}
            end
            ]]
        end

        return true

    elseif str == "ENTER_FOREGROUND" then
        local scene = lc._runningScene
        if scene then
            --[[
            lc.App:removeNotification(STR.PUSH_TIP_GRAIN_NOON)
            lc.App:removeNotification(STR.PUSH_TIP_GRAIN_NIGHT)
            lc.App:removeNotification(STR.PUSH_TIP_REWARD_SEND)
            lc.App:removeNotification(STR.PUSH_TIP_COPY_PVP_UNLOCK)
            lc.App:removeNotification(STR.PUSH_TIP_GRAIN_FULL)
            lc.App:removeNotification(STR.PUSH_TIP_GOLD_FULL)
            lc.App:removeNotification(STR.PUSH_TIP_GURAD_FRAGMENT)
            if lc.PLATFORM ~= cc.PLATFORM_OS_IPHONE and lc.PLATFORM ~= cc.PLATFORM_OS_IPAD then
                _M.sendUserEvent{sceneId = scene._sceneId, sync = scene._needSyncData, act = "Enter Foreground"}
            end
            ]]
        end

        return true

    elseif str == "IDLE" then
        --lc._runningScene:onIdle()
        return true

    elseif str == "REACHABILITY_CHANGED" then
        --lc._runningScene:onReachabilityChanged()
        _M.writeSocketLog(ClientData.SocketLog.reachability_changed)
        return true

    elseif string.hasPrefix(str, "GAMECENTERID_CHANGED") then
        local gcid = string.sub(str, 21)
        if _M.isLogin() then
            _M.sendQueryGcid(gcid)
        elseif _M._socketStatus == _M.SocketStatus.connected and lc._runningScene ~= nil and lc._runningScene._sceneId == ClientData.SceneId.region then
            _M.sendRegionListReq()
        end
        return true

    elseif str == "USER_LOGOUT" then
        print ('#### '..str)        
        lc._runningScene:runAction(cc.CallFunc:create(function()
            V.getActiveIndicator():hide()
            local runningScene = lc._runningScene
            if runningScene._sceneId == ClientData.SceneId.city then
                runningScene:clearCity()
            end
            _M.switchToUpdateScene() 
        end))
        return true

    elseif str == "PAY_FAILED" then
        print ('#### '..str)
        V.getActiveIndicator():hide()
        local str = Str(STR.BUYFAIL)
        ToastManager.push(str) 
        _M.sendIAPFinishReq()
        return true

    elseif str == "PAY_SESSION_EXPIRE" then
        print ('#### '..str)
        V.getActiveIndicator():hide()
        local str = Str(STR.BUY_SESSION_EXPIRE)
        ToastManager.push(str) 
        _M.sendIAPFinishReq()
        return true

    elseif str == "PAY_SUCCESS" then
        V.iapPaySuccess()
        return true

    elseif str == "PAY_CANCEL" then
        print ('#### '..str)
        V.getActiveIndicator():hide()
        _M.sendIAPFinishReq()
        return true     
        
    elseif string.hasPrefix(str, "FACEBOOK_LOGGEDIN") then
        print ('#### '..str)
        local facebookId = string.sub(str, 19)
        print ('#### facebook id:', facebookId)
        if facebookId == '' then
            V.getActiveIndicator():hide()
            ToastManager.push(Str(STR.BIND_GCID_FAILED_ID_EMPTY)) 
            return true
        end
        ClientData.sendQueryGcid(facebookId)
        return true
        
    elseif str == "FACEBOOK_LIKED" then
        print ('#### '..str)
        ToastManager.push(Str(STR.FACEBOOK_TASK_FINISHED)) 
        ClientData.sendUserFacebook(2402)
        P._playerBonus:onFacebookTaskDirty(2402)

    elseif str == "FACEBOOK_INVITED" then
        print ('#### '..str)
        ToastManager.push(Str(STR.FACEBOOK_TASK_FINISHED)) 
        ClientData.sendUserFacebook(2403)
        P._playerBonus:onFacebookTaskDirty(2403)
           
    end

    return false
end



Str = _M.str
ClientData = _M