local _M = class("ResSwitchScene", require("BaseScene"))

function _M.create(...)
    return lc.createScene(_M, ...)
end

-----------------------------------------------
-- init
-----------------------------------------------

function _M:init(fromSceneId, toSceneId, input)
    if not _M.super.init(self, ClientData.SceneId.res_switch) then return false end

    self._fromSceneId = fromSceneId
    self._toSceneId = toSceneId
    self._input = input
    
    if toSceneId == ClientData.SceneId.battle then
        ClientData._fromSceneId = fromSceneId
    end

    if toSceneId ~= ClientData.SceneId.battle and P._playerFindDark:isInDarkBattle() then
        if fromSceneId == ClientData.SceneId.find then
            return
        else
            toSceneId = ClientData.SceneId.find
            ClientData._battleFromFindIndex = Data.FindMatchType.dark
        end
    end
    
    ClientData.loadLCRes("res/bat_loading/bat_loading.lcres")
    self:initBackGround()
    
    -- Make sure guide dialogs are closed
    GuideManager.stopGuide()
    self._isGuideOnEnter = false

    return true
end

function _M:initBackGround()
    -- init background
    local spr = nil
    self._isAd = false
    while true do
        local hour, day, month, year = ClientData.getServerDate()
        if lc.PLATFORM == cc.PLATFORM_OS_IPHONE or lc.PLATFORM == cc.PLATFORM_OS_IPAD then
            spr, self._bgStr = V.createLoadingBg()
            break
        end

        if _M.batLoadBgIndex ~= nil then 
            _M.batLoadBgIndex = _M.batLoadBgIndex < 5 and (_M.batLoadBgIndex + 1) or 1
        else 
            _M.batLoadBgIndex = math.random(1, 5)
        end
        self._bgStr = string.format("res/bat_loading/bat_loading_bg%d.jpg", _M.batLoadBgIndex)
        spr = cc.Sprite:create(self._bgStr)
        break
    end       

    spr:setScale(V.SCR_W / spr:getContentSize().width)
    spr:setPosition(V.SCR_CW, V.SCR_CH)
    self:addChild(spr)
    
    local len = (V.SCR_W / spr:getContentSize().width * spr:getContentSize().height) / 2
    for i = 1, 4 do
        local aPoint = cc.p(math.floor((i - 1) / 2), i % 2)
        local frame = cc.Sprite:create("res/bat_loading/bat_loading_frame.jpg")
        frame:setAnchorPoint(aPoint)
        frame:setFlippedX(aPoint.x == 0)
        frame:setFlippedY(aPoint.y == 0)
        frame:setPosition(V.SCR_CW, V.SCR_CH + len * (aPoint.y == 0 and 1 or -1))
        frame:setScale(V.SCR_W / frame:getContentSize().width / 2)
        self:addChild(frame)
    end
    
    -- init hint
    local hintBg = ccui.Scale9Sprite:createWithSpriteFrameName("bat_load_bar_shade", cc.rect(11, 11, 1, 1))
    hintBg:setPosition(V.SCR_CW, 110)
    hintBg:setContentSize(cc.size(600, 48))
    hintBg:setColor(cc.c3b(12, 15, 30))
    hintBg:setOpacity(0xA0)
    self:addChild(hintBg, 1)
    
    local strIds = {}
    for k, v in pairs(Data._tipInfo) do
        table.insert(strIds, v._nameSid)
    end    
    local str = Str(strIds[math.random(1, #strIds)])
    local hint = cc.Label:createWithTTF(str, V.TTF_FONT, V.FontSize.S1)
    hint:setPosition(V.SCR_CW, 110)
    self:addChild(hint, 2)
    self._hint = hint
    
    if hint:getContentSize().width > hintBg:getContentSize().width - 40 then
        hintBg:setContentSize(cc.size(hint:getContentSize().width + 40, hintBg:getContentSize().height))
    end
    
    -- loading bar
    local loadingBarBg = ccui.Scale9Sprite:createWithSpriteFrameName("bat_load_bar_bg", cc.rect(96, 0, 4, 36))    
    loadingBarBg:setPosition(V.SCR_CW, 60)
    loadingBarBg:setContentSize(cc.size(624, 36))
    self:addChild(loadingBarBg, 1)
     
    local loadingBar = ccui.LoadingBar:create()
    loadingBar:loadTexture("bat_load_bar_fg", ccui.TextureResType.plistType)
    loadingBar:setPosition(V.SCR_CW, 60)
    loadingBar:setScale9Enabled(true)
    loadingBar:setCapInsets(cc.rect(21, 0, 2, 24))
    loadingBar:setContentSize(cc.size(600, 24))
    self:addChild(loadingBar, 2)
    self._loadingBar = loadingBar
    
    self._loadingPercentage = 0
    self:updateLoadingBar()    
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listener = lc.addEventListener(Data.Event.resource, function(event) self:onResourceEvent(event) end)

    -- start loading  
    if self._toSceneId == ClientData.SceneId.battle then
        self:loadBattleRes()
    else
        self:loadCityUnionRes()
    end
end

function _M:onExit()
    _M.super.onExit(self)

    lc.Dispatcher:removeEventListener(self._listener)
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    if lc._runningScene._sceneId ~= ClientData.SceneId.res_switch then
        ClientData.unloadLCRes({"bat_loading.jpm", "bat_loading.png.sfb"})
        lc.TextureCache:removeTextureForKey("res/bat_loading/bat_loading_frame.jpg")
        lc.TextureCache:removeTextureForKey(self._bgStr)
    end
end


-----------------------------------------------
-- resource
-----------------------------------------------
function _M:updateLoadingBar()    
    self._loadingBar:setPercent(self._loadingPercentage)
end

function _M:loadBattleRes()
    self._loadingPercentage = 50
    self:updateLoadingBar()

    ClientData.unloadCityUnionRes()
    ClientData.loadLCRes("res/battle.lcres")
end

function _M:loadCityUnionRes()
    self._loadingPercentage = 50    
    self:updateLoadingBar()

    if self._fromSceneId == ClientData.SceneId.battle then
        ClientData.unloadBattleRes()

    elseif self._toSceneId == ClientData.SceneId.union_world or self._toSceneId == ClientData.SceneId.union_war then
        ClientData.unloadCityRes()

    else
        ClientData.unloadUnionRes()
    end

    ClientData.loadLCRes("res/city.lcres")
end

function _M:onResourceEvent(event)
    if not ClientData._isWorking then return end

    local name = event:getUserString()
    if not self:updateLoadResProgress(name) then
        return
    end

    performWithDelay(self, function()
        if self._toSceneId == ClientData.SceneId.battle then
            if self._loadingPercentage == 60 then
                self:preloadBattleScene()

            elseif self._loadingPercentage == 70 then
                self._loadingPercentage = 100

                ClientData.preloadFonts(true)
                self:preloadBattleAudio()
                self:preloadBattleDragonBones()
            end
        else
            if self._loadingPercentage == 55 then
                if self._toSceneId == ClientData.SceneId.union_world or self._toSceneId == ClientData.SceneId.union_war then
                    ClientData.loadLCRes("res/union_war.lcres")
                else
                    ClientData.loadLCRes("res/city.lcres")
                end
            elseif self._loadingPercentage == 90 then
                if self._toSceneId == ClientData.SceneId.union_world or self._toSceneId == ClientData.SceneId.union_war then
                    lc.TextureCache:addImage("res/jpg/union_world_bg.jpg")
                    lc.TextureCache:addImage("res/jpg/union_war_bg.jpg")
                else
                    lc.TextureCache:addImage("res/jpg/world_bg.jpg")
                    lc.TextureCache:addImage("res/jpg/legend_bg.jpg")
                end   
                self._loadingPercentage = 100
            end
        end

        self:updateLoadingBar()
        self:checkLoadResFinished()
    end, 0.01)
end

function _M:updateLoadResProgress(name)
    if name == "city.png.sfb" or name == "city_2.png.sfb" then
        self._loadingPercentage = 90
        return true
    elseif name == "battle.png.sfb" then
        self._loadingPercentage = 70
        return true
    --[[
    elseif string.match(name, "bat_scene_%d+.png.sfb") then
        self._loadingPercentage = 70
        return true
    ]]
    end

    return false
end

function _M:checkLoadResFinished()
    if self._loadingPercentage == 100 then
        if self._fromSceneId == ClientData.SceneId.battle then
            ClientData.preloadFonts(false)
        end
        
        performWithDelay(self, function() self:switchScene() end, self._isAd and 2 or 0.1)
    end
end

-----------------------------------------------
-- function
-----------------------------------------------

function _M:preloadBattleScene()
    local index = self._input._sceneType
    if index < 11 or index > 15 then index = 1 end
    local spr = cc.Sprite:create(string.format("res/bat_scene/bat_scene_%d_bg.jpg", index))
    --ClientData.loadLCRes(string.format("res/bat_scene_%d.lcres", index))
end

function _M:preloadBattleAudio()
    if not lc.readConfig(ClientData.USER_CONFIG_EFFECT_KEY, ClientData.USER_CONFIG_EFFECT_DEFAULT) then
        return
    end

    local loadRes = {"e_card_deal", "e_card_using", "e_card_board", "e_card_hurt", "e_card_die", "e_book_equip", "e_horse_equip"}
    for _, str in ipairs(loadRes) do
        cc.SimpleAudioEngine:getInstance():preloadEffect("res/bat_audio/"..str..".mp3")
    end

    lc.log("preload audio")
end

function _M:preloadBattleDragonBones()
    local loadRes = {"xuanzhong", "kapaisiwang", "beiji"}
    for _, str in ipairs(loadRes) do
        local bones = cc.DragonBonesNode:createWithDecrypt(string.format("res/effects/%s.lcres", str), str, str)
        ClientData._dragonBonesTexture[str] = 1
    end

    lc.log("preload dragonbones")
end

-----------------------------------------------
-- scene
-----------------------------------------------
function _M:switchScene()
    self:unscheduleUpdate()
    
    if not ClientData._isWorking then return end
    
    if self._toSceneId == ClientData.SceneId.battle then
        lc.replaceScene(require("BattleScene").create(self._input))

        -- Notify server loading done
        ClientData.sendBattleLoadingDone()
    else
        V.getMenuUI()
        V.getResourceUI()
        V.getChatPanel()    
    
        local isCityOrWorld
        if self._toSceneId == ClientData.SceneId.world then
            ClientData.replaceCityScene()
            lc.pushScene(require("WorldScene").create())

            isCityOrWorld = true
        else
            if self._toSceneId == ClientData.SceneId.factory_monster 
                or self._toSceneId == ClientData.SceneId.factory_magic
                or self._toSceneId == ClientData.SceneId.factory_trap
                or self._toSceneId == ClientData.SceneId.factory_rare then
                ClientData.replaceCityScene()
                lc.pushScene(require("CardBoxScene").create(self._toSceneId))
            elseif self._toSceneId == ClientData.SceneId.manage_troop then
                ClientData.replaceCityScene()
                lc.pushScene(require("HeroCenterScene").create())
            elseif self._toSceneId == ClientData.SceneId.union then
                ClientData.replaceCityScene()
                lc.pushScene(require("UnionScene").create())
            elseif self._toSceneId == ClientData.SceneId.find then
                ClientData.replaceCityScene()
                lc.pushScene(require("FindScene").create(ClientData._battleFromFindIndex))
            elseif self._toSceneId == ClientData.SceneId.in_room then
                ClientData.replaceCityScene()
                lc.pushScene(require("FindScene").create(Data.FindMatchType.clash))
                lc.pushScene(require("InRoomScene").create())
            elseif self._toSceneId == ClientData.SceneId.union_world then
                lc.replaceScene(require("UnionWorldScene").create())
            elseif self._toSceneId == ClientData.SceneId.union_war then
                lc.replaceScene(require("UnionWorldScene").create())
                lc.pushScene(require("UnionWarScene").create(ClientData._savedUnionData._city, ClientData._savedUnionData._isAttacking))
            elseif self._toSceneId == ClientData.SceneId.tavern then
                ClientData.replaceCityScene()
                lc.pushScene(require("TavernScene").create())
            else    -- default
                ClientData.replaceCityScene()
                isCityOrWorld = true
            end
        end

        if isCityOrWorld then
            if GuideManager.isGuideEnabled() then
                lc._runningScene._needGuideStartStep = true
            else
                local info = ClientData._battleFromCopy
                if info then
                    lc.pushScene(require("ExpeditionScene").create())
                else
                    info = ClientData._battleFromTravel
                    if info 
                        and not (GuideManager.getCurDifficultyStepName() == 'check duel' and P:checkFindClash()) 
                        and not (GuideManager.getCurRecruiteStepName() == 'check union' and P:getMaxCharacterLevel() >= P._playerCity:getUnionUnlockLevel()) then
                        require("TravelPanel").create(info._id):show()
                    else
                        info = ClientData._battleFromTeach
                        if info 
                            and not (GuideManager.getCurDifficultyStepName() == 'check duel' and P:checkFindClash()) 
                            and not (GuideManager.getCurRecruiteStepName() == 'check union' and P:getMaxCharacterLevel() >= P._playerCity:getUnionUnlockLevel()) then
                            require("TeachingForm").create(info):show()
                        end
                    end
                end
            end
        end

        ClientData._battleFromCopy = nil
        ClientData._battleFromTravel = nil
        ClientData._battleFromTeach = nil
    end    
end

function _M:onLogin()
    if _M.super.onLogin(self) then return true end

    lc.replaceScene(require("LoadingScene").create())
    return true  
end

return _M