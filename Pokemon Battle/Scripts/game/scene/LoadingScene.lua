local Socket_pb = require "Socket_pb"

local _M = class("LoadingScene", require("BaseScene"))

local LOAD_RES_TICK_TIME = 0.02

function _M.create()
    return lc.createScene(_M)
end

function _M:init()
    if not _M.super.init(self, ClientData.SceneId.loading) then return false end

    lc.FrameCache:addSpriteFrames("res/updater/loading.plist", "res/updater/loading.pvr.ccz")

    lc.UserDefault:setBoolForKey(ClientData.ConfigKey.agreement, true)
  
    --local version = V.createBMFont(V.BMFont.huali_20, Str(STR.VERSION)..ClientData.getDisplayVersion()..(lc.PLATFORM == cc.PLATFORM_OS_ANDROID and ('    '..Str(STR.ISBN)) or ''))
    local version = V.createBMFont(V.BMFont.huali_20, Str(STR.VERSION)..ClientData.getDisplayVersion())
    version:setScale(0.8)
    lc.addChildToPos(self, version, cc.p(V.SCR_CW, 20), 2)

    local bg = V.createLoadingBg()
    bg:setPosition(V.SCR_CW, V.SCR_CH)
    self:addChild(bg)

    local hintBg = ccui.Scale9Sprite:createWithSpriteFrameName("load_bar_shade", cc.rect(11, 11, 1, 1))
    hintBg:setPosition(V.SCR_CW, 110)
    hintBg:setContentSize(cc.size(600, 48))
    hintBg:setColor(cc.c3b(12, 15, 30))
    hintBg:setOpacity(0x80)
    self:addChild(hintBg, 1)
    
    self._hintPrefix = ClientData._userRegion._name..": "
    local hint = cc.Label:createWithTTF(self._hintPrefix..Str(STR.CONNECTING), V.TTF_FONT, V.FontSize.S1)
    hint:setPosition(V.SCR_CW, 110)
    self:addChild(hint, 2)
    self._hint = hint
    
    local loadingBarBg = ccui.Scale9Sprite:createWithSpriteFrameName("load_bar_bg", cc.rect(96, 0, 4, 58))    
    loadingBarBg:setPosition(V.SCR_CW, 60)
    loadingBarBg:setContentSize(cc.size(624, 58))
    self:addChild(loadingBarBg, 1)
     
    local loadingBar = ccui.LoadingBar:create()
    loadingBar:loadTexture("load_bar_fg", ccui.TextureResType.plistType)
    loadingBar:setPosition(V.SCR_CW, 54)
    loadingBar:setScale9Enabled(true)
    loadingBar:setCapInsets(cc.rect(10, 0, 2, 24))
    loadingBar:setContentSize(cc.size(592, 24))
    self:addChild(loadingBar, 2)
    self._loadingBar = loadingBar

    local titleSpr = lc.createSprite('load_bar_title')
    titleSpr:setPosition(V.SCR_CW, 64)
    self:addChild(titleSpr, 2)
    
    --[[
    if lc.FrameCache:getSpriteFrame("load_bar_head") then
        local loadingBarHead = lc.createSprite("load_bar_head")
        lc.addChildToPos(self, loadingBarHead, cc.p(0, lc.y(loadingBar) - 1), 2)
        self._loadingBarHead = loadingBarHead
    end
    ]]
    
    self._loadingPercentage = 5
    self:updateLoadingBar()
    
    --[[
    for i = 1, 2 do
        local edge = cc.Sprite:createWithSpriteFrameName("load_bar_edge")
        edge:setPosition(V.SCR_CW + (i == 1 and -300 or 300), 65)
        if i == 2 then edge:setFlippedX(true) end
        self:addChild(edge, 4)
    end
    ]]

    --[[
    local gameAnnounce = V.createTTF(Str(STR.GAME_ANNOUNCE, true), 18)
    gameAnnounce:setColor(cc.c3b(80, 100, 180))
    lc.addChildToPos(self, gameAnnounce, cc.p(V.SCR_CW, V.SCR_H - 28))
    ]]

    lc.TextureCache:addImageWithMask("res/jpg/load_btn_agreement.jpg")
    lc.TextureCache:addImageWithMask("res/jpg/load_btn_server.jpg")

    if ClientData.isShowAgreement() then
        local btnAgreement = V.createShaderButton("res/jpg/load_btn_agreement.jpg", V.openUserProtocol)
        lc.addChildToPos(btnAgreement, V.createBMFont(V.BMFont.huali_26, Str(STR.AGREEMENT)), cc.p(lc.w(btnAgreement) / 2, 20))
        lc.addChildToPos(self, btnAgreement, cc.p(V.SCR_W - 12 - lc.w(btnAgreement) / 2, V.SCR_H - 20 - lc.h(btnAgreement) / 2))
    end

    local btnServer = V.createShaderButton("res/jpg/load_btn_server.jpg", function(sender)
        sender:setEnabled(false)
        ClientData.switchToRegionScene()
    end)
    lc.addChildToPos(btnServer, V.createBMFont(V.BMFont.huali_26, Str(STR.SELECT_SERVER)), cc.p(lc.w(btnServer) / 2, 20))
    lc.addChildToPos(self, btnServer, cc.p(V.SCR_W - 12 - lc.w(btnServer) / 2, V.SCR_H - 20 - lc.h(btnServer) / 2 - (ClientData.isShowAgreement() and lc.h(btnServer) or 0)))
    
    -- Make sure guide dialogs are closed
    GuideManager.stopGuide()
    self._isGuideOnEnter = false
    
    -- init notice
    NoticeManager.init()

    return true
end

function _M:onEnter()
    _M.super.onEnter(self)

    GuideManager.releaseLayer()

    self._listener = lc.addEventListener(Data.Event.resource, function(event) self:onResourceEvent(event) end)

    self._isInBattle = false
    self._isInRoom = false
    
    lc.Audio.playAudio(AUDIO.M_LOADING)
    
    ClientData.reconnectGameServer()
end

function _M:onExit()
    _M.super.onExit(self)

    lc.Dispatcher:removeEventListener(self._listener)
end

function _M:onCleanup()  
    _M.super.onCleanup(self)
    
    if lc._runningScene._sceneId == ClientData.SceneId.city or lc._runningScene._sceneId == ClientData.SceneId.battle then
        self:removeAllChildren()
        ClientData.unloadLoadingRes()
    end
end

function _M:onMsgErrorStatus(msg, msgStatus)
    local msgType = msg.type

    lc.log("msgType:%d msgStatus:%d", msgType, msgStatus)

    if msgType ~= SglMsgType_pb.PB_TYPE_USER_LOGIN or msgType == SglMsgType_pb.PB_TYPE_USER_REGISTER or msgType == SglMsgType_pb.PB_TYPE_HEART_BEAT then
        if msgStatus == SglMsg_pb.PB_STATUS_USER_UNDER_ATTACK then
            self._isInBattle = true
            local resp = msg.Extensions[User_pb.SglUserMsg.user_under_attack_resp]
            local message = string.format(Str(STR.UNDER_ATTACKING), resp.name)
            self._hint:setString(self._hintPrefix..message)
            return true
        elseif msgStatus == SglMsg_pb.PB_STATUS_BATTLE_RECOVER then
            self._isInBattle = true
            self._hint:setString(self._hintPrefix..Str(STR.RECOVER_BATTLE))
            return true
        elseif msgStatus == SglMsg_pb.PB_STATUS_BATTLE_JOIN_NOT_ALLOWED then
            self._isInBattle = false
            self._hint:setString(self._hintPrefix..Str(STR.LOADING_DATA))
            self:loadResStart()
            return true
        elseif msgStatus == SglMsg_pb.PB_STATUS_MATCH_JOIN_NOT_ALLOWED then
            self._isInRoom = false
            self._hint:setString(self._hintPrefix..Str(STR.LOADING_DATA))
            self:loadResStart()
            return true
        end
    end

    return _M.super.onMsgErrorStatus(self, msg, msgStatus)
end

function _M:onLogin()
    if P._guideID < 100 then
        -- Check guide input
        local guideGroup = math.floor(P._guideID / 10)
        if guideGroup == 0 then
            guideGroup = 1
        end
        P._guideID = guideGroup * 10 + 1
        
        self._isInBattle = true
        self._input = ClientData.genInputFromGuidance(guideGroup)
    end

    self._hint:setString(self._hintPrefix..Str(STR.LOADING_DATA))
    self:loadResStart()
end

function _M:onIdle() 
    lc.Director:updateTouchTimestamp()
end

function _M:onBattleRecover(input)
    self._input = input
    self._isInBattle = true
    self._hint:setString(self._hintPrefix..Str(STR.PREPARE_LIVE_BATTLE))
    self:loadResStart()
end

function _M:onEnterRoom(input)
    self._isInRoom = true
    self._hint:setString(self._hintPrefix..Str(STR.PREPARE_ENTER_ROOM))
    self:loadResStart()
end

function _M:onBattleWait()
    self._isInBattle = true
    self._hint:setString(self._hintPrefix..Str(STR.WAIT_BATTLE_RESULT))
end

function _M:onResourceEvent(event)
    if not ClientData._isWorking then return end

    local name = event:getUserString()
    if not self:updateLoadResProgress(name) then
        return
    end

    performWithDelay(self, function()
        if self._loadingPercentage == 10 then
            ClientData.loadLCRes("res/cards_back.lcres")

        elseif self._loadingPercentage == 15 then
            ClientData.loadLCRes("res/general.lcres")

        elseif self._loadingPercentage >= 20 and self._loadingPercentage < 35 then
            local index = self._loadingPercentage - 19
            ClientData.loadLCRes("res/cards_img_"..index..".lcres")

        --elseif self._loadingPercentage >= 35 and self._loadingPercentage < 65 then
        --    local index = self._loadingPercentage - 34
        --    ClientData.loadLCRes("res/cards_"..index..".lcres")

        else
            if not self._isInBattle then
                if self._loadingPercentage == 65 then
                    if ClientData.DEBUG_UNION then
                        ClientData.loadLCRes("res/union_war.lcres")
                    else
                        ClientData.loadLCRes("res/city.lcres")
                    end
                elseif self._loadingPercentage == 90 then
                    --if ClientData.DEBUG_UNION then
                    --    lc.TextureCache:addImage("res/jpg/union_world_bg.jpg")
                    --    lc.TextureCache:addImage("res/jpg/union_war_bg.jpg")
                    --else
                    --    lc.TextureCache:addImage("res/jpg/world_bg.jpg")
                    --    lc.TextureCache:addImage("res/jpg/legend_bg.jpg")
                    --end
                    self._loadingPercentage = 100
                    self._basePercentage = self._loadingPercentage
                end
            else        
                if self._loadingPercentage == 65 then
                    ClientData.loadLCRes("res/battle.lcres")

                elseif self._loadingPercentage == 80 then
                    local index = 1
                    if self._input then
                        index = self._input._sceneType
                    end
                    local spr = cc.Sprite:create(string.format("res/bat_scene/bat_scene_%d_bg.jpg", index))
                    --ClientData.loadLCRes(string.format("res/bat_scene_%d.lcres", index))

                elseif self._loadingPercentage == 90 then
                    self._loadingPercentage = 100
                    self._basePercentage = self._loadingPercentage
                end
            end
        end

        self:updateLoadingBar()
        self:checkLoadResFinished()
    end, 0.01)
end

function _M:updateLoadingBar()    
    self._loadingBar:setPercent(self._loadingPercentage)
    if self._loadingBarHead then
        self._loadingBarHead:setPositionX(lc.x(self._loadingBar) + self._loadingPercentage * 6 - 300 - 10)
    end
end

function _M:loadResStart()
    ClientData.loadLCRes("res/avatar.lcres")
end

function _M:updateLoadResProgress(name)    
    if name == "avatar.png.sfb" then
        self._loadingPercentage = 10
        return true
    elseif name == "cards_back.png.sfb" then
        self._loadingPercentage = 15
        return true
    elseif name == "general.png.sfb" then
        self._loadingPercentage = 20
        return true
    elseif name == "cards_img_"..ClientData.CARDS_IMG_COUNT..".png.sfb" then
        self._loadingPercentage = 65--35
        return true
    elseif string.hasPrefix(name, "cards_img_") and string.hasSuffix(name, ".png.sfb") then
        self._loadingPercentage = self._loadingPercentage + 1
        return true
    --elseif name == "cards_14.png.sfb" then
    --    self._loadingPercentage = 65
    --    return true
    elseif string.hasPrefix(name, "cards_") and string.hasSuffix(name, ".png.sfb") then
        self._loadingPercentage = self._loadingPercentage + 1
        return true
	elseif name == "city.png.sfb" or name == "city_2.png.sfb" then
        self._loadingPercentage = 90
        return true
    elseif name == "battle.png.sfb" then
        self._loadingPercentage = 90
        return true
    --[[
    elseif string.match(name, "bat_scene_%d+.png.sfb") then
        self._loadingPercentage = 90
        return true
    ]]
    end

    return false
end

function _M:checkLoadResFinished()
    if self._loadingPercentage == 100 then


        for _, fontName in ipairs(V.BMFONTS_COMMON) do
            local label = cc.Label:createWithBMFont(fontName, "")
        end
            
        if not self._isInBattle then
            for _, fontName in ipairs(V.BMFONTS_CITY) do
                local label = cc.Label:createWithBMFont(fontName, "")
            end
        else
            for _, fontName in ipairs(V.BMFONTS_BATTLE) do
                local label = cc.Label:createWithBMFont(fontName, "")
            end

            -- preload dragon bones
            ClientData._dragonBonesTexture = {}
            local loadRes = {"xuanzhong", "kapaisiwang", "beiji"}
            for _, str in ipairs(loadRes) do
                local bones = cc.DragonBonesNode:createWithDecrypt(string.format("res/effects/%s.lcres", str), str, str)
                ClientData._dragonBonesTexture[str] = 1
            end
                
            -- preload audio
            ClientData._battleAudio = {}
            local loadRes = {"e_card_deal", "e_card_using", "e_card_board", "e_card_hurt", "e_card_die", "e_book_equip", "e_horse_equip"}
            for _, str in ipairs(loadRes) do
                local fname = "res/bat_audio/"..str..".mp3"
                cc.SimpleAudioEngine:getInstance():preloadEffect(fname)
            end
        end

        -- require UI modules
        require("ResourcePanel")
        require("IconWidget")
        require("CardThumbnail").createPool()

        if P._guideID == 11 then
            self:screenShot()
        end
        
        performWithDelay(self, function() self:switchScene() end, 0.1)
    end
end

function _M:switchScene()
    self:unscheduleUpdate()

    if not ClientData._isWorking then return end

    if self._isInBattle then
        lc.replaceScene(require("BattleScene").create(self._input))

        -- Notify server loading done
        ClientData.sendBattleLoadingDone()

    else
        local resPanel = V.getResourceUI()
        resPanel:setLocalZOrder(ClientData.ZOrder.ui)

        V.getMenuUI()
        V.getChatPanel()
    
        if ClientData.DEBUG_UNION then
            lc.replaceScene(require("UnionWorldScene").create())
        elseif P._playerFindDark:isInDarkBattle() then
            lc.pushScene(require("FindScene").create(Data.FindMatchType.dark))
            require("FindMatchPanel").create(Data.FindMatchType.dark):show()
        elseif self._isInRoom then
            ClientData.replaceCityScene()
            lc.pushScene(require("FindScene").create(Data.FindMatchType.clash))
            lc.pushScene(require("InRoomScene").create())
        else
            ClientData.replaceCityScene()
            
            -- Check guidance
            if GuideManager.isGuideInWorld() and P._guideID < 500 then
                --lc.pushScene(require("WorldScene").create())
                --lc._runningScene._needGuideStartStep = true

            elseif GuideManager.isGuideEnabled() then
                local curStep = GuideManager.getCurStepName()
                if curStep == "enter evolve card" then
                    lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.factory_monster))
                elseif curStep == "claim task" or string.find(curStep, "goto task") then
                    performWithDelay(lc._runningScene, function() require("AchieveForm").create():show() end, 0.1)
                elseif curStep == "equip important" then
                    lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.factory_trap))
                end

                lc._runningScene._needGuideStartStep = true
            end
        end
    end
    
    collectgarbage("collect")
end

function _M:screenShot()

    local rt = cc.RenderTexture:create(lc.w(self), lc.h(self))
    rt:begin()
    self:visit()
    rt:endToLua()
    rt:retain()
    V._rt = rt
end

return _M