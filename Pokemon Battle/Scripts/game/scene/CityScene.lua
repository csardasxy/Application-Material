require("TavernScene")
require("CardBoxScene")
require("HeroCenterScene")

local _M = class("CityScene", require("BaseScene"))

local ARROW_COUNT           = 4
local ELEMENT_BG_INDEX_MAX  = 100
local MOVE_SPEED            = 600

local BASE_SCALE            = 1.25          -- Scale down the source images by 0.8333 to save memory

local MAP_ELE_X_OFFSET, MAP_ELE_Y_OFFSET    -- Set in init() according to the map type

local BUTTON_PANEL_SIZE = cc.size(550, 768)

local BTN_FIXITY = 
{
    Data.FixityId.depot,
    --Data.FixityId.union,
    Data.FixityId.manage_troop,
    Data.FixityId.tavern,
    Data.FixityId.duel,
    --Data.FixityId.skin_shop,
}

local BTN_IMAGE = 
{
    'city_btn_depot',
    --'city_btn_union',
    'city_btn_troop',
    'city_btn_tavern',
    --{_bones = 'juedou', _size = cc.size(180, 180)},
    'city_btn_battle',
    --'city_btn_skin',
}


function _M.create()
    return lc.createScene(_M)
end

function _M:init()
    if not _M.super.init(self, ClientData.SceneId.city) then return false end
    
    local visibleSize = lc.Director:getVisibleSize()

    MAP_ELE_X_OFFSET, MAP_ELE_Y_OFFSET = 0, 0

    local bg = lc.createSprite("res/jpg/city_bg_01.jpg")
    --bg:setAnchorPoint(1 - lc.w(self) / 2 / lc.w(bg), 0.5)
    print(bg:getAnchorPoint().x)
    lc.addChildToPos(self, bg, cc.p(lc.w(self) / 2, lc.h(self) / 2))
    self._bg = bg

    self._btnNode = lc.createNode(BUTTON_PANEL_SIZE)
    lc.addChildToPos(self, self._btnNode, cc.p(27 * (lc.w(self))/ 36, lc.ch(self)))

    self:initCharacters()
    self:initButtons()
    
    self:updateButtonFlags()

    bg:setScale(1.5)     -- for enter animation

    return true
end

function _M:initButtons()
    self._btns = {}
    for i = 1, #BTN_FIXITY do
        local btn = ClientView.createShaderButton('city_btn_'..BTN_FIXITY[i], function(sender) self:onButton(BTN_FIXITY[i]) end)
        --btn:setZoomScale(0)
        
        lc.addChildToCenter(self._btnNode, btn, 2)

        if BTN_FIXITY[i] == Data.FixityId.skin_shop or BTN_FIXITY[i] == Data.FixityId.duel then
            btn:setLocalZOrder(1)
        end
        local spriteFrame = lc.FrameCache:getSpriteFrame('city_btn_'..BTN_FIXITY[i])
        local offset = spriteFrame:getOffsetInPixels()
        local rect = spriteFrame:getRectInPixels()
        local w, h = rect.width, rect.height
        btn:setTouchRect(cc.rect(lc.cw(self._btnNode) + offset.x - math.floor(w / 2), lc.ch(self._btnNode) + offset.y - math.floor(h/ 2), w, h))      
        self._btns[i] = btn
    end
end

function _M:initCharacters()
    -- dragon bones to remove
    local pos = cc.p((V.SCR_W - 600) / 2 + 50, 250)

    self:updateCharacter()
end

function _M:updateCharacter()
    if self._spine ~= nil then
        self._spine:removeFromParent()
    end
    
    if ClientData.isAppStoreReviewing() then characterId = 12 end
    local spine = V.createSpine((string.format("renwu_%02d", P:getCharacterId())))
    lc.addChildToPos(self, spine, cc.p((lc.w(self) - 550) / 2, 0))
    self._spine = spine
    self:runAction(
        lc.sequence(
            function()
                spine:setAnimation(0, "animation", true)
            end
        )
    )
end

function _M:findFixityEntry(infoId)
    return BTN_POS[1]
end

function _M:setUiVisible(visible)
    V.getMenuUI():setVisible(visible)
    V.getResourceUI():setVisible(visible)
    V.getChatPanel()._btnPop:setVisible(visible)
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    local newFixity = 0

    self:setAllBtnsEnabled(true)

    if not P._hasEnterCity then
        P._hasEnterCity = true

        local enterCity = function(duration)
            -- Scale down the city when enter the city the first time
            self._bg._touchEnabled = false
            self:setAllBtnsEnabled(false)

            local enableTouch = function() 
                if table.maxn(P._playerBonus._changedFundTasks) > 0 then
                    require("FundTasksPanel").create(P._playerBonus._changedFundTasks, Str(STR.FUND_TASKS)):show()
                    P._playerBonus._changedFundTasks = {}
                end

                self._bg._touchEnabled = true 
                self:setAllBtnsEnabled(true)
            end
            duration = duration / 3
            self._bg:runAction(lc.sequence(lc.scaleTo(duration, 1), enableTouch))
            return duration
        end

        if GuideManager.isGuideInCity() then

			self._bg:setScale(1)

			self:setUiVisible(true)

        else
            if not GuideManager.isGuideEnabled() and newFixity == 0 then
                enterCity(1.5)
            else
                self._bg:setScale(1)
            end

            self:setUiVisible(true)   
        end
    else
        self._bg:setScale(1)
    end

    
    self._listeners = {}
        
    self._listeners.guide_finish = lc.addEventListener(GuideManager.Event.finish, function(event) self:onGuideFinish(event) end)
    
    local onGestureFunc = function(event) if self:onGesture(event) then event:stopPropagation() end end
    self._listeners.gesturePan = lc.addEventListener(lc.Gesture.GestureEvent.pan, onGestureFunc, -1)
    self._listeners.touchBegan = lc.addEventListener(lc.Gesture.TouchEvent.began, onGestureFunc, -1)
    self._listeners.touchEnded = lc.addEventListener(lc.Gesture.TouchEvent.ended, onGestureFunc, -1)
    self._listeners.touchCancelled = lc.addEventListener(lc.Gesture.TouchEvent.cancelled, onGestureFunc, -1)

    self._listeners.character = lc.addEventListener(Data.Event.character_dirty, function(event)
        self:updateCharacter()            
    end)

    -- event
    self._listeners.cardFlag = lc.addEventListener(Data.Event.card_flag_dirty, function(event) self:updateButtonFlags() end)

    --self:loadTimer()

    -- Using 3D camera to see the map and all map elements
    -- This is must be called after all map elements have been added to the map. Otherwise, you have to "seenByCamera3D" the children manually.
    self:seenByCamera3D(self._bg)
    
    lc.Audio.playAudio(AUDIO.M_CITY)
    

    self._scene:addChild(V.getChatPanel(), ClientData.ZOrder.side)

    local menu = V.getMenuUI()
    self._scene:addChild(menu, ClientData.ZOrder.ui)

    local resource = V.getResourceUI()
    resource:setMode(Data.ResType.gold)
    --resource:setPositionX(lc.w(self) - lc.w(resource) / 2 - 40)
    self._scene:addChild(resource, math.max(resource:getLocalZOrder(), ClientData.ZOrder.ui), 2)
    
    -- Rate game after enter unoin the first time    
    if BaseScene._lastSceneId == ClientData.SceneId.union then
        if ClientData.isRateValid() then
            local promptRate = lc.UserDefault:getBoolForKey(ClientData.ConfigKey.prompt_rate_game, false)
            if not promptRate then
                require("RateForm").create():show()
                lc.UserDefault:setBoolForKey(ClientData.ConfigKey.prompt_rate_game, true)
            end
        end
    end

    local curStep = GuideManager.getCurStepName()
    if P._guideID == 101 then 
        local dialog = require("ChangeCharacterPanel").create(true)
        dialog:show()
    elseif curStep == "win battle" then
        if P._hasEnterCity then
            GuideManager.finishStepLater()
        end
    end

    if newFixity > 0 then
        self:runAction(lc.sequence(0, function() 
            GuideManager.showOperateLayer() 
            local layer = GuideManager.createNpcTipLayer(Data._guideInfo[newFixity == 5 and P._guideDifficultyID or P._guideRecruiteID], false, true, false, 0)
            GuideManager.addContainerLayer(layer)
            GuideManager.setOperateLayer(self._btns[newFixity])
        end))
    end

    self:updateButtonFlags()

end
    

function _M:onExit()
    _M.super.onExit(self)
    
    if self._bg.stopAnimation then
        self._bg:stopAnimation()
        self._bg._touchEnabled = true
    end    
    
    for k, v in pairs(self._listeners) do
        lc.Dispatcher:removeEventListener(v)
    end
    self:unscheduleUpdate()

	--self:unloadTimer()

    V.removeResourceFromParent()
    V.removeMenuFromParent()
    V.removeChatPanelFromParent()
end

function _M:onCleanup()
    _M.super.onCleanup(self)

end

function _M:onGesture(event)
    if not ClientData._isWorking or not self._bg._touchEnabled then return end

    local touch = event.touch
    local evtName = event:getEventName()
    if evtName == lc.Gesture.TouchEvent.began then
        if self._bg.stopAnimation then
            self._bg:stopAnimation()
        end
    
        
    elseif evtName == lc.Gesture.TouchEvent.ended then        
        

    elseif evtName == lc.Gesture.TouchEvent.cancelled then
        
    end
    
    return false
end

function _M:clearCity()
    --self:removeAllChildren()
end

function _M:checkUnlockModule()
    local curLevel = P._level
    local prevLevel = lc.readConfig(ClientData.ConfigKey.lock_level_city, curLevel)

    local blacksmith, stable, library, union
    for k, fixity in pairs(P._playerCity._fixities) do
        if fixity._infoId == Data.FixityId.blacksmith then
            --blacksmith = fixity
        elseif fixity._infoId == Data.FixityId.stable then
            --stable = fixity            
        elseif fixity._infoId == Data.FixityId.library then
            --library = fixity
        elseif fixity._infoId == Data.FixityId.union then
            --union = fixity
        end
    end

    local strs = {}
    if blacksmith ~= nil then
        local level = P._playerCity:getUnlockLevel(blacksmith)
        if prevLevel < level and curLevel >= level then
            table.insert(strs, Str(blacksmith._info._nameSid)..Str(STR.UNLOCKED))
        end
    end
    if stable ~= nil then
        local level = P._playerCity:getUnlockLevel(stable)
        if prevLevel < level and curLevel >= level then
            table.insert(strs, Str(stable._info._nameSid)..Str(STR.UNLOCKED))
        end        
    end
    if library ~= nil then
        local level = P._playerCity:getUnlockLevel(library)
        if prevLevel < level and curLevel >= level then
            table.insert(strs, Str(library._info._nameSid)..Str(STR.UNLOCKED))
        end        
    end
    if union ~= nil then
        local level = P._playerCity:getUnlockLevel(union)
        if prevLevel < level and curLevel >= level then
            table.insert(strs, Str(union._info._nameSid)..Str(STR.UNLOCKED))
        end
    end

    if #strs > 0 then
        ToastManager.pushArray(strs)
        lc.writeConfig(ClientData.ConfigKey.lock_level_city, curLevel)
    end   
end

function _M:syncData()
    _M.super.syncData(self)

    --self:loadTimer()

    self:seenByCamera3D(self._bg)

    -- Check guide
    self._bg._touchEnabled = (P._guideID >= 103)

    -- Update MenuPanel (to avoid under attack ui)
    local menu = V.getMenuUI()
    
    self:updateButtonFlags()
end

function _M:seenByCamera3D(node)
    
end

function _M:farmerWork(farmer, startIndex, endIndex)
    farmer:gotoAndPlay("labor2")
    farmer:runAction(cc.Sequence:create(cc.DelayTime:create(math.random(5, 8)), cc.CallFunc:create(function() 
        self:farmerWalk(farmer, startIndex, endIndex, false)    
    end)))
end

function _M:farmerSleep(farmer)
    farmer:setVisible(false)    
end

function _M:farmerWalk(farmer, startIndex, endIndex, isGoWork)    
    local speed = 50
    if isGoWork then
        farmer:gotoAndPlay("walk2")   
        
        local pos1 = self._startPos[startIndex]
        local pos2 = self._endPos[endIndex]
        local pos3 = cc.p(lc.x(self._farmlands[endIndex]) + 30, lc.y(self._farmlands[endIndex]) + 30)
        
        local distance1 = cc.pGetDistance(cc.p(lc.x(farmer), lc.y(farmer)), pos1)
        local distance2 = cc.pGetDistance(pos1, pos2)
        local distance3 = cc.pGetDistance(pos2, pos3)     
        farmer:runAction(cc.Sequence:create(cc.MoveTo:create(distance1 / speed, pos1), cc.MoveTo:create(distance2 / speed, pos2), 
            cc.CallFunc:create(function() farmer:setLocalZOrder(self._endZOrder) end), 
            cc.MoveTo:create(distance3 / speed, pos3),
            cc.CallFunc:create(function() self:farmerWork(farmer, startIndex, endIndex) end)))
    else
        farmer:gotoAndPlay("walk1")
        
        local pos1 = self._endPos[endIndex]
        local pos2 = self._startPos[startIndex]
        local pos3 = cc.p(lc.x(self._residences[startIndex]), lc.y(self._residences[startIndex]))
        
        local distance1 = cc.pGetDistance(cc.p(lc.x(farmer), lc.y(farmer)), pos1)
        local distance2 = cc.pGetDistance(pos1, pos2)
        local distance3 = cc.pGetDistance(pos2, pos3)    
        farmer:runAction(cc.Sequence:create(cc.MoveTo:create(distance1 / speed, pos1), cc.CallFunc:create(function() farmer:setLocalZOrder(self._startZOrder) end),
            cc.MoveTo:create(distance2 / speed, pos2),             
            cc.MoveTo:create(distance3 / speed, pos3),
            cc.CallFunc:create(function() self:farmerSleep(farmer) end)))
    end
end

function _M:farmerAction()     
    local action = cc.Sequence:create(cc.DelayTime:create(math.random(20, 30)), cc.CallFunc:create(function() self:farmerAction() end))
    action:setTag(0xff)
    
    self:stopActionByTag(0xff)
    self:runAction(action)  
    
    local farmer = nil
    for i = 1, #self._farmers do
        if not self._farmers[i]:isVisible() then
            farmer = self._farmers[i]
            break
        end
    end
    
    if farmer == nil then return end
    
    local startIndex = math.random(1, #self._residences)
    local endIndex = math.random(1, #self._farmlands)
    farmer:setVisible(true)
    farmer:setPosition(lc.x(self._residences[startIndex]), lc.y(self._residences[startIndex]))
    farmer:setLocalZOrder(self._startZOrder)    
    self:farmerWalk(farmer, startIndex, endIndex, true)     
end

function _M:onGuideFinish(event)
    if P._guideID == 500 then
        --GuideManager.showSoftGuideFinger(V.getMenuUI()._btnCrusade)

    elseif P._guideID == 600 then
        GuideManager.showSoftGuideFinger(V.getMenuUI()._btnCrusade)

    end
end

function _M:onGuide(event)
    local isStop

    local curStep = GuideManager.getCurStepName()
    if curStep == "init troop" then
        -- Sort heroes by fighte value
        local cards = {}
        for k, v in pairs(P._playerCard._monsters) do
            table.insert(cards, {_infoId = k, _num = v})
        end
        for k, v in pairs(P._playerCard._magics) do
            table.insert(cards, {_infoId = k, _num = v})
        end
        for k, v in pairs(P._playerCard._traps) do
            table.insert(cards, {_infoId = k, _num = v})
        end
        for k, v in pairs(P._playerCard._rares) do
            table.insert(cards, {_infoId = k, _num = v})
        end
        table.sort(cards, function(a, b) 
            local infoA = Data.getInfo(a._infoId)
            local infoB = Data.getInfo(b._infoId)
            if infoA._quality > infoB._quality then return true
            elseif infoA._quality < infoB._quality then return false
            else return a._infoId < b._infoId
            end
        end)

        require("RewardCardPanel").create(Str(STR.INIT_TROOP), cards):show()
        GuideManager.finishStepLater()

    elseif curStep == "enter travel" then
        GuideManager.setOperateLayer(V.getMenuUI()._btnBattle)
        isStop = true

    elseif curStep == "enter setting" then
        GuideManager.setOperateLayer(V.getMenuUI()._userArea)
        isStop = true

    else
        for _, btn in pairs(self._btns) do
            local fixityId = BTN_FIXITY[btn:getTag()]
            if (curStep == "collect grain" and fixityId == Data.FixityId.farmland)
            or (curStep == "collect gold" and fixityId == Data.FixityId.residence)
            or (curStep == "enter tavern" and fixityId == Data.FixityId.tavern)
            or (curStep == "enter manage troop" and fixityId == Data.FixityId.manage_troop)
            or (curStep == "enter market" and fixityId == Data.FixityId.market)
            or (curStep == "enter union" and fixityId == Data.FixityId.union) 
            or (curStep == "enter duel" and fixityId == Data.FixityId.duel) then
                GuideManager.setOperateLayer(btn)
                isStop = true
                break     
            end
        end
    end

    if isStop then
        event:stopPropagation()
    end
end

function _M:onButton(fixityId)
    if P._guideID < 103 then return end

    if not ClientData.checkBtnClick() then return end

    local fixity = P._playerCity:getFixity(fixityId)

    --if fixityId == Data.FixityId.factory then require("CardFactoryPanel").create():show()
    if fixityId == Data.FixityId.factory then self:setAllBtnsEnabled(false) lc.pushScene(require("CardBoxScene").create())
    elseif fixityId == Data.FixityId.manage_troop then self:setAllBtnsEnabled(false) lc.pushScene(require("HeroCenterScene").create())
    elseif fixityId == Data.FixityId.tavern then self:setAllBtnsEnabled(false) lc.pushScene(require("TavernScene").create())
    --elseif fixityId == Data.FixityId.skin_shop then self:setAllBtnsEnabled(false) lc.pushScene(require("SkinShopScene").create())
    elseif fixityId == Data.FixityId.depot then require("TravelPanel").create():show() --self:setAllBtnsEnabled(false) lc.pushScene(require("DepotScene").create())       
    elseif fixityId == Data.FixityId.duel then 

        self:setAllBtnsEnabled(false)
        lc.pushScene(require("FindScene").create())
    elseif fixityId == Data.FixityId.union then
        local level = P._playerCity:getUnionUnlockLevel() 
        if P:getMaxCharacterLevel() < level then
            ToastManager.push(string.format(Str(STR.UNIONSCENE_LOCKED), level))
            return
        end
        local curStep = GuideManager.getCurRecruiteStepName()
        if curStep == 'select union' then
            P._guideRecruiteID = P._guideRecruiteID + 1
            ClientData.sendGuideID(P._guideRecruiteID)
            GuideManager.stopGuide()
        end
        self:setAllBtnsEnabled(false)
        lc.pushScene(require("UnionScene").create())
    end
end

function _M:updateButtonFlags()
    self:updateTroopFlags()
end

function _M:updateTroopFlags()
    local number = P._playerCard:getCardFlag()
    V.checkNewFlag(self._btns[2], number, 0 - 1004 + 613 + 156, -118 - 354 - 11)
end

function _M:setAllBtnsEnabled(isEnable)
    for i = 1, #self._btns do
        self._btns[i]:setEnabled(isEnable)
    end
end

return _M