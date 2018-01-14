local BasePanel = require("BasePanel")

local _M = class("TravelPanel", BasePanel)

local CHAPTER_WIDTH = 224
local SUBITEM_WIDTH = 1140
local SUBITEM_HEIGHT= 538

local CHAPTER_CRECTS = {cc.rect(26, 36, 1, 1), cc.rect(109, 78, 2, 1), cc.rect(109, 105, 1, 2)}
local LEVEL_POS = {cc.p(144, 269), cc.p(416, 269), cc.p(720, 269), cc.p(996, 269)}

local CHAPTER_FRAME_SHADER_INDEX = {2, 3, 5}

function _M.create(focusLevelId)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(focusLevelId)

    return panel    
end

function _M:init(focusLevelId)  
    _M.super.init(self, true)

    ClientData.loadLCRes("res/travel.lcres")
    self._panelName = "TravelPanel"

    self._focusLevelId = focusLevelId

    self._difficulty = 1

    local topArea = V.createTitleArea(Str(STR.TRAVEL), function()
        if self._floatChapter then
            self:onUnselectChapter(self._floatChapter)
        else
            self:hide()
        end
    end)
    self:addChild(topArea)

    local bottomBg = lc.createNode()
    local travelBottom = lc.createSprite("img_travel_bottom")
    travelBottom:setAnchorPoint(1, 0.5)
    bottomBg:setContentSize(cc.size(lc.w(travelBottom) * 2, lc.h(travelBottom)))
    local travelBottom2 = lc.createSprite("img_travel_bottom")
    travelBottom2:setAnchorPoint(0, 0.5)
    travelBottom2:setScaleX(-1)
    lc.addChildToPos(bottomBg, travelBottom, cc.p(lc.cw(bottomBg), lc.ch(bottomBg)))
    lc.addChildToPos(bottomBg, travelBottom2, cc.p(lc.w(bottomBg), lc.ch(bottomBg)))
    lc.addChildToPos(self, bottomBg, cc.p(lc.w(self) / 2, lc.h(bottomBg) / 2))
    self._difficultyBtns = {}
    for i = 1, 3 do
        local btn = V.createShaderButton('img_travel_0'..i, function(sender) self:onSelectDifficulty(sender) end)
        btn._index = i
        lc.addChildToPos(bottomBg, btn, cc.p(lc.w(bottomBg) / 2 + 192 * (-2 + i), 58), 1)
        self._difficultyBtns[#self._difficultyBtns + 1] = btn
    end
    local btnFocus = lc.createSprite('img_travel_focus')
    lc.addChildToPos(bottomBg, btnFocus, cc.p(self._difficultyBtns[1]:getPosition()))
    self._btnFocus = btnFocus

    local list = lc.List.createH(cc.size(lc.w(self), lc.bottom(topArea) - 108), 50, 100)
    lc.addChildToPos(self, list, cc.p(0, 108))
    self._chapterList = list
    self:updateChapterList()

    local maskLayer = lc.createMaskLayer(255, lc.Color3B.black, cc.size(lc.w(self), lc.h(list)))
    maskLayer:setVisible(false)
    maskLayer:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self, maskLayer, cc.p(lc.w(maskLayer) / 2, lc.bottom(list) + lc.h(list) / 2))
    self._maskLayer = maskLayer

    list = lc.List.createH(cc.size(lc.w(self), lc.bottom(topArea) - 108), -10, 0)
    list:setVisible(false)
    list:setBounceEnabled(false)
    lc.addChildToPos(self, list, cc.p(0, lc.y(self._chapterList)))
    self._levelList = list

    return true
end

function _M:onEnter() 
    _M.super.onEnter(self)

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.copy_times_dirty, function(event) end))

    local curStep = GuideManager.getCurDifficultyStepName()
    if string.sub(curStep, 1, 16) == 'check difficulty' then
        local difficulty = tonumber(string.sub(curStep, 18, 18)) + 1
        local newDifficulty = false
        if difficulty == 2 and not Data.isLevelLock(20101) then 
            newDifficulty = true
        elseif difficulty == 3 and not Data.isLevelLock(30101) then 
            newDifficulty = true
        end
        if newDifficulty then
            P._guideDifficultyID = P._guideDifficultyID + 1
            self:runAction(lc.sequence(0, function() 
                GuideManager.showOperateLayer() 
                local layer = GuideManager.createNpcTipLayer(Data._guideInfo[P._guideDifficultyID], false, true, false, 0)
                layer:setScale(0.8)
                GuideManager.addContainerLayer(layer)
                GuideManager.setOperateLayer(self._difficultyBtns[difficulty])
            end))
            return
        end
    end

    if self._focusLevelId then
        local difficulty = math.floor(self._focusLevelId / 10000)
        self:onSelectDifficulty(self._difficultyBtns[difficulty])

        if P._playerWorld._curLevel[difficulty] > self._focusLevelId then
            local nextLevelId = self._focusLevelId + 1
            if Data._levelInfo[nextLevelId] == nil then
                nextLevelId = (math.floor(self._focusLevelId / 100) + 1) * 100 + 1
            end
            self._focusLevelId = nextLevelId
        end

        local chapterId = math.floor(self._focusLevelId / 100) % 100
        local chapterItem = self._chapterItems[chapterId]
        self:gotoChapter(chapterItem)
        --GuideManager.showSoftGuideFinger(chapterItem)
        self:onSelectChapter(chapterItem)

        local levelId = self._focusLevelId % 100
        self:gotoLevel(levelId)

        self._focusLevelId = nil
    elseif not GuideManager.isGuideEnabled() then
        local lastLevelId = lc.UserDefault:getIntegerForKey(ClientData.ConfigKey.last_level, 10101)
        local difficulty = math.floor(lastLevelId / 10000)
        if difficulty ~= 1 then
            self:onSelectDifficulty(self._difficultyBtns[difficulty])
        end
    end
    
    if GuideManager.isGuideEnabled() then
        GuideManager.finishStepLater()
    end
end

function _M:onExit()
    _M.super.onExit(self)
    
    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    ClientData.unloadLCRes({"travel.jpm", "travel.png.sfb"})
    for i = 1, #self._chapterItems do
        print (string.format("chapter_%02d.jpm", i))
        ClientData.unloadLCRes({string.format("chapter_%02d.jpm", i), string.format("chapter_%02d.png.sfb", i)})
    end
end

function _M:onSelectDifficulty(difficultyBtn)
    if difficultyBtn._index == 2 and Data.isLevelLock(20101) then
        ToastManager.push(lc.str(STR.DIFFICULTY_NOT_UNLOCKED), 3)
        return
    elseif difficultyBtn._index == 3 and Data.isLevelLock(30101) then
        ToastManager.push(lc.str(STR.DIFFICULTY_NOT_UNLOCKED), 3)
        return
    end

    local curStep = GuideManager.getCurDifficultyStepName()
    if string.sub(curStep, 1, 17) == 'select difficulty' then
        P._guideDifficultyID = P._guideDifficultyID + 1
        ClientData.sendGuideID(P._guideDifficultyID)
        GuideManager.stopGuide()
    end

    self._difficulty = difficultyBtn._index
    self._btnFocus:setPosition(cc.p(self._difficultyBtns[self._difficulty]:getPosition()))
    self:updateChapterList()

    if self._floatChapter ~= nil then
        self._maskLayer:setVisible(false)
        self._levelList:setVisible(false)
        self._levelList:scrollToLeft(0.1, true)
        self._floatChapter:removeFromParent()
        self._floatChapter = nil
    end
end

function _M:updateChapterList()
    self._chapterList:removeAllItems()
    self._chapterItems = {}
    for k, v in pairs(Data._chapterInfo) do
        local item = self:createChapterItem(v, #self._chapterItems + 1, cc.size(CHAPTER_WIDTH, lc.h(self._chapterList)), false)
        self._chapterItems[#self._chapterItems + 1] = item
        --lc.addChildToCenter(chapterBg, item)
        self._chapterList:pushBackCustomItem(item)
    end
    self._chapterList:scrollToLeft(0.3, true)
end

function _M:createChapterItem(chapterInfo, index, size, isFloat)
    local item = ccui.Widget:create()

    item._info = chapterInfo
    item._index = index
    local curLevel = P._playerWorld._curLevel[self._difficulty]
    local curChapter = math.floor(curLevel / 100) % 100
    item._locked = chapterInfo._id > curChapter

    item:setContentSize(size)
    item:setTouchEnabled(true)
    item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    item:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            if not isFloat then
                self:onSelectChapter(sender)
            else
                self:onUnselectChapter(sender)
            end
            --[[
            if GuideManager.isGuideEnabled() then
                GuideManager.finishStepLater()
            end
            ]]
        end
    end)

    --local imgFrame = lc.createSprite({_name = 'travel_bg_0'..self._difficulty, _crect = CHAPTER_CRECTS[self._difficulty], _size = cc.size(lc.w(item) - (self._difficulty == 1 and 0 or 6), lc.h(item) - (self._difficulty == 1 and 6 or 12))})
    --imgFrame:setEffect(self._difficulty == 1 and V.SHADER_COLORS[CHAPTER_FRAME_SHADER_INDEX[self._difficulty]] or nil)
    --lc.addChildToCenter(item, imgFrame)
    --if self._difficulty == 2 then lc.offset(imgFrame, -4, 4) 
    --elseif self._difficulty == 3 then lc.offset(imgFrame, -6, 6) 
    --end
    
    local imgBG = cc.ShaderSprite:createWithFramename(string.format("travel_img_%02d", index))
    lc.addChildToPos(item, imgBG, cc.p(lc.w(item) / 2 - 4, lc.h(item) / 2 ), -1)
    if item._locked then 
        imgBG:setEffect(V.SHADER_DISABLE) 
        --imgFrame:setEffect(V.SHADER_DISABLE) 
    end
    --[[
    local title = cc.Label:createWithTTF(Str(chapterInfo._nameSid), V.TTF_FONT, V.FontSize.S1)
    lc.addChildToPos(item, title, cc.p(lc.w(item) / 2 - 4, 90))

    local totalCount, passedCount = P._playerWorld:getChapterProgress(self._difficulty, chapterInfo._id)
    local progress = V.createBMFont(V.BMFont.huali_26, string.format("%d/%d", passedCount, totalCount))
    lc.addChildToPos(item, progress, cc.p(lc.w(item) / 2, 60))
    ]]
    return item
end

function _M:onSelectChapter(chapterItem)
    ClientData.loadLCRes(string.format("res/chapter_%02d.lcres", chapterItem._info._id))
    if chapterItem._locked then 
        ToastManager.push(lc.str(STR.BATTLE_NOT_UNLOCKED), 3)
        return
    end

    lc.Audio.playAudio(AUDIO.E_TRAVEL_CHAPTER)

    self._chapterId = self._difficulty * 100 + chapterItem._info._id
    self:updateLevelList()

    self._maskLayer:setVisible(true)

    local floatChapter = self:createChapterItem(chapterItem._info, chapterItem._info._id, chapterItem:getContentSize(), true)
    floatChapter._chapterItem = chapterItem
    local pos = lc.convertPos(cc.p(chapterItem:getPosition()), self._chapterList, self)
    lc.addChildToPos(self, floatChapter, pos)
    floatChapter:runAction(lc.sequence(
        lc.moveTo(0.2, cc.p(lc.w(floatChapter) / 2 + 40, lc.y(floatChapter)))
    ))
    self._floatChapter = floatChapter

    --------------------------------------- Guide ------------------------------------------------------------------------
    local curStep = GuideManager.getCurStepName()
    if curStep == "select chapter 1" then
        GuideManager.finishStepLater(0.5)
    end
    --------------------------------------- Guide ------------------------------------------------------------------------ 
end

function _M:onUnselectChapter(floatChapter)
    lc.Audio.playAudio(AUDIO.E_TRAVEL_CHAPTER)

    local chapterItem = floatChapter._chapterItem
    ClientData.unloadLCRes({string.format("chapter_%02d.jpm", chapterItem._info._id), string.format("chapter_%02d.png.sfb", chapterItem._info._id)})
    local pos = lc.convertPos(cc.p(chapterItem:getPosition()), self._chapterList, self)
    self._levelList:runAction(lc.sequence(
        lc.ease(lc.moveTo(0.3, cc.p(-lc.w(self._levelList), lc.y(self._levelList))), "BackI", 0.5),
        function() self._levelList:setVisible(false) end
    ))
    floatChapter:runAction(lc.sequence(
        0.3,
        lc.moveTo(0.2, pos),
        lc.remove(),
        function() 
            self._floatChapter = nil
            self._maskLayer:setVisible(false) 
            self._levelList:scrollToLeft(0.1, true)
        end
    ))
end

function _M:gotoChapter(chapterItem)
    self._chapterList:forceDoLayout()
    self._chapterList:gotoPos(lc.right(chapterItem) + 50 - V.SCR_W)
end

function _M:updateLevelList()
    self._levelList:removeAllItems()

    local curChapter = self._chapterId % 100
    local bgItem = ccui.Layout:create()
    local chapterBg = lc.createSprite(string.format("res/jpg/img_chapter_bg_%02d.jpg", curChapter))
    bgItem:setContentSize(chapterBg:getContentSize())
    lc.addChildToCenter(bgItem, chapterBg)
    self._levelList:pushBackCustomItem(bgItem)

    local levelInfos = {}
    for _, v in pairs(Data._levelInfo) do
        if math.floor(v._id  / 100) == self._chapterId then
            levelInfos[#levelInfos + 1] = v
        end
    end
    table.sort(levelInfos, function(a, b) return a._id < b._id end)

    local focusedIndex = #levelInfos

    for i = 1, #levelInfos do
        local levelSprite, focused = self:createLevelSprite(levelInfos[i], i)
        lc.addChildToCenter(bgItem, levelSprite)

        local spriteFrame = lc.FrameCache:getSpriteFrame(string.format("chapter_%02d_%02d", self._chapterId % 100, i))
        local offset = spriteFrame:getOffsetInPixels()
        local rect = spriteFrame:getRectInPixels()
        local w, h = rect.width, rect.height
        levelSprite:setTouchRect(cc.rect(lc.cw(bgItem) + offset.x - math.floor(w / 2), lc.ch(bgItem) + offset.y - math.floor(h/ 2), w, h))  
    
        if focused then focusedIndex = i end
    end

    self._levelList:setPosition(cc.p(-lc.w(self._levelList), lc.y(self._levelList)))
    self._levelList:setVisible(true)    
    self._levelList:runAction(lc.sequence(
        0.2,
        lc.ease(lc.moveTo(0.3, cc.p(0, lc.y(self._levelList))), "BackIO", 0.5),
        function() self:gotoLevel(focusedIndex) end
    ))
end

function _M:createLevelSprite(levelInfo, index)
    local focused = false

    local levelSprite = V.createShaderButton(string.format("chapter_%02d_%02d", self._chapterId % 100, index), function(sender) self:onSelectLevel(sender) end)
    levelSprite:setZoomScale(0)
    levelSprite._info = levelInfo
    levelSprite._locked = Data.isLevelLock(levelInfo._id)

    -- fix later
    if levelSprite._locked then 
        levelSprite:setDisabledShader(V.SHADER_DISABLE) 
        levelSprite:setEnabled(false)    
    end
    --[[
    if levelInfo._id == P._playerWorld._curLevel[self._difficulty] then
        local particle = Particle.create("dangqian")
        particle:setPositionType(cc.POSITION_TYPE_GROUPED)
        lc.addChildToPos(levelSprite, particle, cc.p(lc.w(levelSprite) / 2, lc.h(levelSprite) / 2 - 20))
        focused = true
    end
    ]]
    return levelSprite, focused
end


function _M:onSelectLevel(levelSprite)
    if levelSprite._locked then
        ToastManager.push(lc.str(STR.LEVEL_NOT_UNLOCK), 3)
        return
    end

    require("LevelForm").create(levelSprite._info):show()

    --------------------------------------- Guide ------------------------------------------------------------------------
    local curStep = GuideManager.getCurStepName()
    if string.sub(curStep, 1, 12) == "select level" then
        GuideManager.finishStepLater(0.4)
    end
    --------------------------------------- Guide ------------------------------------------------------------------------ 
end

function _M:gotoLevel(levelId)
    self._levelList:forceDoLayout()
    self._levelList:gotoPos(lc.left(self._levelList:getItems()[1]:getChildren()[levelId]))
end

function _M:onGuide(event)
    local isStop

    local curStep = GuideManager.getCurStepName()
    if curStep == "select chapter 1" then
        GuideManager.setOperateLayer(self._chapterItems[1])
        isStop = true

    elseif string.sub(curStep, 1, 12) == "select level" then
        GuideManager.setOperateLayer(self._levelList:getItems()[1]:getChildren()[tonumber(string.sub(curStep, 14, 14))])
        isStop = true

    end

    if isStop then
        event:stopPropagation()
    end
end


return _M