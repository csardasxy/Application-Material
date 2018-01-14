local function prepareGC()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
end

local function sendInitProgressEvent(percent, nextFunc)
    local event = cc.EventCustom:new(Data.Event.application)
    event:setUserString("INIT_PROGRESS_"..percent)
    lc.Dispatcher:dispatchEvent(event)

    performWithDelay(lc.Director:getRunningScene(), nextFunc, 0.01)
end

local function swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
end

local function shuffle(array)
    local counter = #array
    while counter > 1 do
        local index = math.random(counter)
        swap(array, index, counter)
        counter = counter - 1
    end
end

local function initClientView()
    V.init()

    -- TODO
    -- switch to the first scene
    local scene
    --TEST_BATTLE_MODE = Data.BattleType.test
    if TEST_BATTLE_MODE then
        local battleType = tonumber(TEST_BATTLE_MODE)

        ClientData.loadLCRes("res/avatar.lcres")
        ClientData.loadLCRes("res/general.lcres")
        ClientData.loadLCRes("res/battle.lcres")
        for i = 1, ClientData.CARDS_IMG_COUNT do
            ClientData.loadLCRes("res/cards_img_"..i..".lcres")
        end
        ClientData.loadLCRes("res/cards_back.lcres")

        require ("IconWidget")

        ClientData._dragonBonesTexture = {}
        local loadRes = {"xuanzhong", "kapaisiwang", "beiji"}
        for _, str in ipairs(loadRes) do
            ClientData._dragonBonesTexture[str] = 1
        end
        
        P._id = 0
        P._level = 50
        P._vip = 4
        P._guideID = 20000
        P._cardBackId = 7601
        P._avatar = 1
        
        local testRes = lc.App:loadRes("res/test.lcres")
        local getTestBin = function(name)
            local bin = lc.App:getBinData(name)
            if bin == nil then
                bin = lc.readFile(name)
            end

            return bin
        end

        if TEST_BATTLE_PARAM == "auto" then
            ClientData._isAutoTesting = true
            ClientData._infoIds = {}
            --[[
            for k, v in pairs(Data._monsterInfo) do
                if v._isHide == 0 then ClientData._infoIds[#ClientData._infoIds + 1] = k end
            end
            for k, v in pairs(Data._magicInfo) do
                if v._isHide == 0 then ClientData._infoIds[#ClientData._infoIds + 1] = k end
            end
            for k, v in pairs(Data._trapInfo) do
                if v._isHide == 0 then ClientData._infoIds[#ClientData._infoIds + 1] = k end
            end
            ]]
            shuffle(ClientData._infoIds)
            ClientData._infoIdIndex = 1

            Data._testInfo = dataparser.parseData(getTestBin("test.bin"), false)
        else
            if battleType == Data.BattleType.replay then
                local pb = Data_pb.BattleSpot()
                pb:ParseFromString(getTestBin(TEST_BATTLE_PARAM or "replay.bin"))
                Data._testInfo = pb
            elseif battleType == Data.BattleType.test then
                if TEST_BATTLE_PARAM == nil or TEST_BATTLE_PARAM == "" then TEST_BATTLE_PARAM = "test.bin" end
                Data._testInfo = dataparser.parseData(getTestBin(TEST_BATTLE_PARAM), false)
            end
        end
        
        local input
        if battleType == Data.BattleType.guidance then
            input = ClientData.genInputFromGuidance(1)
        elseif battleType == Data.BattleType.test then
            input = ClientData.genInputFromTest(battleType)
        elseif battleType == Data.BattleType.unittest then
            input = ClientData.genInputFromUnitTest()
        elseif battleType == Data.BattleType.replay then
            input = ClientData.genInputFromReplayResp(Data._testInfo)
        end
        
        local index = input._sceneType
        ClientData.loadLCRes(string.format("res/bat_scene_%d.lcres", index))
        
        ClientData._userRegion = {_id = 8001}
        ClientData._isTesting = true
        input._isTesting = true
        input._speedFactor = 1
        scene = require("BattleScene").create(input)
    else
        local isVideoPlayed = true  --lc.UserDefault:getBoolForKey(ClientData.ConfigKey.video_played, false)
        if isVideoPlayed then
            if not (lc.PLATFORM == cc.PLATFORM_OS_WINDOWS and lc.App:getRedirectGameServer() == 'DEV') then
                ClientData._regions = {}
                ClientData.saveUserRegion()
            end
            ClientData.loadUserRegion()
            
            -- Release loading image, because it may be updated
            ClientData.unloadLoadingRes(true)
            lc.File:purgeCachedEntries()

            if ClientData.hasUserRegion() then
                scene = require("LoadingScene").create()
            else
                scene = require("RegionScene").create()
            end
        else
            ClientData._regions = {}
            ClientData.saveUserRegion()
            scene = require("VideoScene").create()
        end  
    end
    scene:retain()
    V._scene = scene

    sendInitProgressEvent(100, function() lc.replaceScene(V._scene) V._scene:release() end)
end

local function initClientData()
    lc.Audio.loadAudioConfig("res/audio/audioInfo.plist")

    -- init random seed (ref: http://lua-users.org/wiki/MathLibraryTutorial)
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))

    -- init client data & view
    ClientData.init()

    sendInitProgressEvent(80, function() initClientView() end)
end

local function initLan()
    lc.App:loadRes("res/lan.lcres")

    sendInitProgressEvent(60, function() initClientData() end)
end


local function initData()
    -- Parse all data
    local dataRes = lc.App:loadRes("res/data.lcres")
    for i = 1, #dataRes do
        local resName = dataRes[i]
        if string.hasSuffix(resName, ".bin") then
            Data.parseData(resName, lc.App:getBinData(resName))
            lc.App:unloadRes(resName)
        end
    end
    -- Merge activity info
    for k, v in pairs(Data._activityNewInfo) do
        Data._activityInfo[k] = v
    end
    Data._activityNewInfo = nil

    sendInitProgressEvent(50, function() initLan() end)
end


local function main()
    require "Cocos2d"
    require "Cocos2dConstants"
    require "OpenglConstants"
    require "GuiConstants"
    require "experimentalConstants"
    require "json"
    
    require "leocool"
    
    require "SglMsgType_pb"
    require "SglMsg_pb"
    require "Auth_pb"
    require "User_pb"
    require "City_pb"
    require "World_pb"
    require "Battle_pb"
    require "Troop_pb"
    require "Card_pb"
    require "Friend_pb"
    require "Mail_pb"
    require "Chat_pb"
    require "Buy_pb"
    require "Shop_pb"
    require "Bonus_pb"
    require "News_pb"
    require "Rank_pb"
    require "Feedback_pb"
    require "Region_pb"
    require "Union_pb"
    require "UnionWar_pb"
    require "Socket_pb"
   
    require "Data"
    require "ClientData"
    require "ClientDataHelper"
    require "ClientDataConnect"
    require "ClientDataMsg"
    require "ClientDataBattle"
    require "ClientDataCard"
    require "ClientDataGroup"
    require "ClientDataMarket"
    require "ClientDataMatcher"
    require "ClientDataRegion"
    require "ClientDataSender"
    require "ClientDataSocial"
    require "ClientDataTroop"
    require "ClientDataUnion"
    require "ClientDataUser"
    require "ClientDataWorld"

    require "ClientView"
    require "ClientViewArea"
    require "ClientViewBar"
    require "ClientViewBg"
    require "ClientViewButton"
    require "ClientViewCard"
    require "ClientViewChest"
    require "ClientViewDesc"
    require "ClientViewFlag"
    require "ClientViewItem"
    require "ClientViewLabel"
    require "ClientViewPanel"
    require "ClientViewScene"
    require "ClientViewText"
    require "ClientViewUser"


    require "TextureManager"
    require "ToastManager"
    require "GuideManager"
    require "NoticeManager"

    require "AudioEnums"
    require "StringEnums"
    
    require "UserWidget"
    require "CardHelper"

    require "BattleData"
    require "PlayerBattle"
    require "BattleHelper"
    require "BattleStaticHelper"
    require "BattleSkill"
    require "BattleStep"
    require "BattleCondition"
    require "BattleCard"
    require "BattleCardStatus"
    require "BattleEvent"
    require "BattleAi"
    require "BattleTestData"

    require "BattleScene"
    require "BattleUi"
    require "BattleUiTouch"
    require "BattleUiView"
    require "PlayerUi"
    require "SkillUi"
    require "StatusUi"
    require "CardSprite"
    require "BattleAudio"
    require "BattleLine"
    require "GuideUi"
    require "Particle"
    require "DragonBones"

    require "BattleDialog"
    require "BattleCardInfoDialog"
    require "BattleChatDialog"
    require "BattleEventDialog"
    require "BattleHelpDialog"
    require "BattlePVPDialog"
    require "BattleSettingDialog"
    require "BattleTaskDialog"
    require "BattleResultDialog"
    require "BattleListDialog"

    sendInitProgressEvent(40, function() initData() end)
end


prepareGC()

-- Call main() and set global error track functions which may be called from lua engine
-- The name of "__G__TRACKBACK__" can't be changed
local errMsgs, errMsgsCount = {}, 3
function __G__TRACKBACK__(msg)
    local errMsg = string.format("[LUA ERROR]: <Sid:%s V:%s T:%s> %s\n%s ", lc._runningScene and lc._runningScene._sceneId or "NA", ClientData.getDisplayVersion(), os.date(), tostring(msg), debug.traceback())
    lc.log(errMsg)

    if #errMsgs == errMsgsCount then
        table.remove(errMsgs, 1)
    end
    table.insert(errMsgs, errMsg)

    local trace = ""
    for _, msg in ipairs(errMsgs) do
        trace = trace .. "\n" .. msg
    end

    local info = string.format("region:%s, id:%s", ClientData._userRegion and ClientData._userRegion._id or "NA", P and P._id or "NA")
    lc.log(info .. "\n" .. trace)
    
    if lc.PLATFORM ~= cc.PLATFORM_OS_WINDOWS then
        onLuaException(info, trace)
    end

    if ClientData._reportBattleDebugLog then
        if V.isInBattleScene() then           
            local log = errMsg
            log = string.gsub(log, "'", "")
            log = string.gsub(log, "\"", "")
            log = string.gsub(log, "\n", " ")
            log = string.gsub(log, "\t", " ")

            ClientData.sendUserEvent({battleDebugLog = log})
            ClientData.sendBattleDebugLog()
        end

        ClientData._reportBattleDebugLog = false
    end
end

xpcall(main, __G__TRACKBACK__)
