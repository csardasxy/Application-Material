local _M = class("FindClashArea", lc.ExtendCCNode)

local PromptForm = require("PromptForm")

function _M.create(w, h)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(w, h)
    area:init()

    area:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            area:onEnter()
        elseif evtName == "exit" then
            area:onExit()
        end
    end)

    return area
end

function _M:init()
    if P._playerFindClash._isSyncData then
        self:initAreas()
    else
        self._indicator = V.showPanelActiveIndicator(self)
        ClientData.sendClashSync()

        --performWithDelay(self, function() P._playerFindClash:simulate() end, 0.5)
    end
end

function _M:initAreas()
    self:initLeftArea()
    self:initFieldArea()
    --self:initChests()
    --self:initBottomArea()
end

function _M:initLeftArea()
    local frame = V.createFrameBox(cc.size(525, lc.h(self)))
    lc.addChildToPos(self, frame, cc.p(lc.cw(frame), lc.ch(frame)), 2)
    self._frame = frame
    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(frame, titleBg, cc.p(lc.cw(frame), lc.h(frame) - lc.ch(titleBg) - 9))

    --local title = V.createTTF(Str(STR.FIND_CLASH_LAST_CHAMPION), V.FontSize.S1)
    local title = V.createTTFStroke(Str(STR.FIND_CLASH_LAST_CHAMPION), V.FontSize.S2)
    lc.addChildToPos(titleBg, title, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2))

    local btnRank = V.createShaderButton("img_btn_rank", function() require("RankForm").create(Data.RankRange.lord):show() end)
    lc.addChildToPos(frame, btnRank, cc.p(30 + lc.w(btnRank) / 2, lc.bottom(titleBg) - 15 - lc.ch(btnRank)))

    local btnReward = V.createShaderButton("img_btn_reward", function() require("ClashChestBonusForm").create(1, P._playerFindClash._grade):show() end)
    lc.addChildToPos(frame, btnReward, cc.p(lc.right(frame) - lc.cw(btnReward) - 30, lc.y(btnRank)))

    local createStage = function(level)
        local stage = ccui.Widget:create()

        local cx = lc.w(stage) / 2

        local ranks = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_PRE, 0)
        local user
        if ranks and ranks[level] then
            user = ranks[level]._user
        end

        if user then
            stage:setTouchEnabled(true)        
            stage:addTouchEventListener(function(sender, evt)
                if evt == ccui.TouchEventType.ended then
                    require("ClashUserInfoForm").create(user._id, true):show()
                end
            end)
        end
        --[[
        local bottom = cc.ShaderSprite:createWithFramename("img_stage_gold")
        lc.addChildToPos(stage, bottom, cc.p(cx, lc.h(bottom) / 2))

        local glow = cc.ShaderSprite:createWithFramename("img_stage_gold_light")
        glow:setScale(2)
        lc.addChildToPos(bottom, glow, cc.p(lc.w(bottom) / 2, lc.h(bottom) + 40))
        
        -- create avatar
        local avatar = require("UserWidget").create()
        lc.addChildToPos(stage, avatar, cc.p(cx, lc.h(stage) - lc.h(avatar) / 2 - 24))
        stage._avatar = avatar
        -- create trophy
        
        local trophy = V.createIconLabelArea("img_icon_res6_s", user and user._trophy or 0, 150)
        trophy._valBg:setScale(0.84)
        trophy._icon:setScale(0.84)
        lc.offset(trophy._icon, 10)
        lc.offset(trophy._label, - 10)
        lc.addChildToPos(stage, trophy, cc.p(cx, 88))
        stage._trophy = trophy._label
        ]]

        
        local avatar
        --local userClone = {_avatar = user and user._avatar, _vip = user and user._vip or 0}
        if level == 1 then
            avatar = lc.createSprite('res/jpg/rank1.png')
            local medal = lc.createSprite("img_medal_1")
            medal:setScale(1.4)
            lc.addChildToPos(avatar, medal, cc.p(lc.cw(avatar), lc.h(avatar) - 34 - 25))
        elseif level == 2 then
            avatar = lc.createSprite('res/jpg/rank2.png')
            local medal = lc.createSprite("img_medal_2")
            lc.addChildToPos(avatar, medal, cc.p(lc.cw(avatar), lc.h(avatar) - 24 - 18 - 25))
        elseif level == 3 then
            avatar = lc.createSprite('res/jpg/rank3.png')
            local medal = lc.createSprite("img_medal_3")
            lc.addChildToPos(avatar, medal, cc.p(lc.cw(avatar), lc.h(avatar) - 24 - 18 - 25))
        end

        stage:setContentSize(cc.size(lc.w(avatar), lc.h(avatar)))
        lc.addChildToPos(stage, avatar, cc.p(cx, lc.h(stage) - lc.h(avatar) / 2 - 24))

        --avatar:setUser(userClone)
        --[[
        local clipNode = cc.ClippingNode:create()
        local stencil = cc.LayerColor:create(lc.Color4B.white, lc.w(avatar) - 14, lc.h(avatar) - 14)
        stencil:setPosition(0, 0)
        clipNode:setStencil(stencil)]]
        local cNode = lc.createNode(cc.size(lc.w(avatar) - 14, lc.h(avatar) - 14))
        local clipNode = V.createClipNode(cNode, cc.rect( 0, 6, (lc.w(avatar) - 14), lc.h(avatar) - 24), false)
    
        local characterImg = lc.createSprite(user._avatarImage > 100 and string.format("res/jpg/avatar_image_%04d.jpg", user._avatarImage) or "res/jpg/avatar_image_0201.jpg")
        characterImg:setScale(lc.h(clipNode) / lc.h(characterImg))
        lc.addChildToCenter(clipNode, characterImg)
        lc.addChildToCenter(avatar, clipNode, -1)

        local name = V.createTTFStroke(user and user._name or string.format(Str(STR.LIST_EMPTY_NO_X), Str(STR.LORD)), V.FontSize.S3)
        lc.addChildToPos(stage, name, cc.p(cx, -8 + lc.ch(name)), 2)
        stage._name = name

        return stage
    end

    local stage2 = createStage(2)
    lc.addChildToPos(frame, stage2, cc.p(lc.cw(frame) - 12 + 117 + 6, lc.bottom(btnRank) + 16 - lc.ch(stage2)), 1)

    local stage1 = createStage(1)
    lc.addChildToPos(frame, stage1, cc.p(lc.left(stage2) - lc.cw(stage1) + 30, lc.y(stage2)))

    local stage3 = createStage(3)
    lc.addChildToPos(frame, stage3, cc.p(lc.right(stage2) + lc.cw(stage3) - 6, lc.y(stage2)))

    self._stages = {stage1, stage2, stage3}

    local crect = cc.rect(V.CRECT_COM_BG5.x, 0, V.CRECT_COM_BG5.width, lc.frameSize("img_com_bg_5").height)

    local preRanks = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_PRE, 0)
    if preRanks._count > 0 then
        local btnRank = V.createScale9ShaderButton("img_com_bg_5", function() require("RankForm").create(Data.RankRange.region, 1, 100, true):show() end, crect, 160)
        btnRank:addLabel(Str(STR.SEASON_LAST_RANK))
        lc.addChildToPos(self, btnRank, cc.p(lc.right(stage3) - lc.w(btnRank) / 2, lc.y(titleBg)))

        --TODO--
        btnRank:setVisible(false)
    end
end

function _M:initFieldArea()

    local area = V.createClashFieldArea(P._playerFindClash._grade)
    lc.addChildToPos(self, area, cc.p((V.SCR_W + lc.right(self._frame)) / 2, lc.ch(self)), 1)
    self._fieldArea = area

    --area._bones:setPositionY(lc.ch(area) + 30)
    --area._bones:setScale(0.75)

    local btnBattle = V.createShaderButton("img_battle_start", function() self:find() end)    
    lc.addChildToPos(area, btnBattle, cc.p(lc.w(area) / 2 + 1, lc.ch(area) - 16), 1)

    local targetBg = lc.createSprite{_name = "img_com_bg_22", _crect = V.CRECT_COM_BG22, _size = cc.size(220, 30)}
    targetBg:setColor(lc.Color3B.black)
    targetBg:setOpacity(0)
    lc.addChildToPos(area, targetBg, cc.p(lc.w(area) / 2, lc.top(area) - lc.ch(targetBg) - 42))
    self._targetBg = targetBg

    local targetLabel = V.createTTFStroke(Str(STR.FIND_CLASH_NEXT_TARGET), V.FontSize.S2)
    lc.addChildToPos(targetBg, targetLabel, cc.p(lc.cw(targetBg), lc.ch(targetBg)))
    --[[
    local targetIcon = lc.createSprite("img_icon_res6_s")
    targetIcon:setScale(0.7)
    lc.addChildToPos(targetBg, targetIcon, cc.p(lc.cw(targetLabel), lc.y(targetLabel) - 10))
    ]]
--    local step = P:getClashTargetStep()
    self:updateClashTarget()

    local cdBg = lc.createSprite{_name = "img_card_count_bg", _crect = cc.rect(26, 20, 1, 1), _size = cc.size(120, 44)}
    lc.addChildToPos(area, cdBg, cc.p(lc.cw(area), -42 - 34))

    local cd1 = V.createTTF("0", V.FontSize.S3)
    lc.addChildToPos(cdBg, cd1, cc.p(lc.cw(cdBg), lc.ch(cdBg) + 34))

    local cd2 = V.createTTF("0", V.FontSize.S3)
    lc.addChildToPos(cdBg, cd2, cc.p(lc.cw(cdBg), lc.ch(cdBg)))

    self:scheduleUpdateWithPriorityLua(function(dt)
        local sec = P._playerFindClash._endTime - ClientData.getCurrentTime()
        if sec > 0 then
            cd1:setString(Str(STR.FIND_CLASH_SEASON_CD))
            cd2:setString(ClientData.formatPeriod(sec))
        else
            cd1:setString(Str(STR.FIND_CLASH_SEASON_REVIEWING_1))
            cd2:setString(Str(STR.FIND_CLASH_SEASON_REVIEWING_2))
       end
    end, 0)

    local frameNode = lc.createNode(cc.size(V.SCR_W - lc.right(self._frame), lc.h(area._bg)))
    lc.addChildToCenter(area, frameNode)

    local winBg = lc.createSprite("img_win_daily_count_bg")
    lc.addChildToPos(frameNode, winBg, cc.p(lc.w(frameNode) * 4 / 5, lc.h(frameNode) - lc.h(winBg) / 2 - 57))

    local win = V.createTTFStroke(P._ladderContLose == 1 and 0 or P._dailyClashWin, V.FontSize.M1)
    win:setColor(lc.Color3B.white)
    lc.addChildToPos(winBg, win, cc.p(lc.w(winBg) / 2, 18))
    self._dailyWin = win

    local winBg2 = lc.createSprite("img_win_all_count_bg")
    lc.addChildToPos(frameNode, winBg2, cc.p(lc.w(frameNode) * 1 / 5, lc.h(frameNode) - lc.h(winBg2) / 2 - 57))
    
    local win2 = V.createTTFStroke(P._ladderContLose == 1 and 0 or P._ladderContWin, V.FontSize.M1)
    win2:setColor(lc.Color3B.white)
    lc.addChildToPos(winBg2, win2, cc.p(lc.w(winBg2) / 2, 18))
    self._allWin = win2

    local btnInfo = V.createScale9ShaderButton("img_btn_1_s", function()
        require("ClashUserInfoForm").create(P._playerFindClash._clashId, true):show()
    end, V.CRECT_BUTTON_S, 120)
    btnInfo:addLabel(Str(STR.RANK_HISTORY))
    lc.addChildToPos(frameNode, btnInfo, cc.p(lc.x(winBg2), 22 + lc.ch(btnInfo)))
    

    local btnTroop = V.createScale9ShaderButton("img_btn_1_s",
        function()
            self._ignoreSync = true
            lc.pushScene(require("HeroCenterScene").create())
        end,
    V.CRECT_BUTTON_S, 120)
    btnTroop:addLabel("0")
    lc.addChildToPos(frameNode, btnTroop, cc.p(lc.x(winBg), lc.y(btnInfo)))
    self._btnTroop = btnTroop

    if P._ladderContWin > 0 and P._ladderContLose == 1 then
        --self:initResetArea()
    end
    
end

function _M:initResetArea()
    local size = cc.size(388, 96)
    local propId = Data.PropsId.dimension_bottle
    local propName = Str(Data._propsInfo[propId]._nameSid)

    local area = V.createShaderButton(nil, function(sender) 
        if P._propBag._props[propId]._num == 0 then
            ToastManager.push(string.format(Str(STR.NOT_ENOUGH), propName))
            require("ExchangeResForm").create(propId):show()
            return    
        end

        require("Dialog").showDialog(string.format(Str(STR.LADDER_RESET_LOSE_CONFIRM, true), propName, P._propBag._props[propId]._num, P._ladderContWin), function() 
            ClientData.sendClashResetLadderLose()
            P._ladderContLose = 0
            P._propBag:changeProps(propId, -1)
            self._dailyWin:setString(P._dailyClashWin)
            self._allWin:setString(P._ladderContWin)
            ToastManager.push(Str(STR.LADDER_RESET_LOSE_DONE))
            self._resetLadderLoseArea:setVisible(false)
        end)
    end)
    area:setContentSize(size)
    lc.addChildToPos(self, area, cc.p(lc.w(self) / 2, 272), 1)

    local areaBg = V.createFramedShadowColorBg(size, color or cc.c3b(40, 50, 60))
    lc.addChildToCenter(area, areaBg)

    local icon = IconWidget.create({_infoId = propId}, 0)
    icon:setScale(0.7)
    lc.addChildToPos(areaBg, icon, cc.p(lc.cw(icon) - 4, lc.ch(areaBg)))

    local light1 = lc.createSprite('img_light_3')
    light1:setColor(cc.c3b(0, 255, 12))
    light1:setScale(1.5)
    lc.addChildToCenter(icon, light1, -2)

    local light2 = lc.createSprite('img_light_2')
    light2:setColor(cc.c3b(0, 255, 12))
    light2:setScale(3)
    light2:runAction(lc.rep(lc.rotateBy(4, 360)))
    lc.addChildToCenter(icon, light2, -1)

    local tip1 = V.createBoldRichTextWithIcons(string.format(Str(STR.LADDER_RESET_LOSE_TIP1), P._ladderContWin), {_width = 600, _fontSize = V.FontSize.S3, _boldClr = V.COLOR_TEXT_GREEN})
    lc.addChildToPos(areaBg, tip1, cc.p(lc.cw(area) + 40, lc.ch(areaBg) + 18))

    local tip2 = V.createBoldRichTextWithIcons(string.format(Str(STR.LADDER_RESET_LOSE_TIP2), propName), {_width = 600, _fontSize = V.FontSize.S3, _boldClr = V.COLOR_TEXT_GREEN})
    lc.addChildToPos(areaBg, tip2, cc.p(lc.cw(area) + 40, lc.ch(areaBg) - 18))

    self._resetLadderLoseArea = area
end

function _M:initChests()
    local fieldArea = self._fieldArea
    if not fieldArea then return end
--    local genChestParam = function(index)
--        return P._playerFindClash:getChestGrade(index), index, index <= 3 and Data.CardQuality.R or (index <= 5 and Data.CardQuality.SR or Data.CardQuality.UR)
--    end
    if self._chests then
        for _,chest in ipairs(self._chests) do
            chest:removeFromParent()
        end
    end

    local genChestParam = function(i)
        return P._playerFindClash:getChestGrade(i), i, Data.CardQuality.UR
    end

    local index = #P._playerFindClash._chests
    local chestInfo = P._playerFindClash._chests[index]
    for i, info in ipairs(P._playerFindClash._chests) do
        if not info._prop._isOpened then
            index = i
            chestInfo = info
            break
        end
    end

    local chestBg = lc.createSprite('img_slot')
    chestBg:setScale(1.3)
    lc.addChildToPos(self, chestBg, cc.p(lc.left(fieldArea) - 8 - lc.cw(chestBg), 200))

    local offsetx = {12, 12, 12, 10, 8}

    local chest1
    if index == 0 or (chestInfo._prop._isOpened and index < 5) then
        index = index + 1
        chest1 = V.createClashFieldChest(genChestParam(index))
    else
        chest1 = V.createClashFieldChest(chestInfo._grade, index, Data.CardQuality.UR)
    end
    chest1._callback = function (sender)
        require("ClashChestBonusForm").create(1):show()
    end
    lc.addChildToPos(self, chest1, cc.p(lc.left(fieldArea) - 24 - lc.cw(chest1) + offsetx[index], 200))
    local label = V.createTTFStroke(Str(STR.DAILY_TARGET), V.FontSize.S1)
    lc.addChildToPos(self, label, cc.p(lc.x(chestBg), lc.bottom(chestBg) - 16))
    
    offsetx = {14, 14, 14, 14, 18, 18}
    chestBg = lc.createSprite('img_slot')
    chestBg:setScale(1.3)
    lc.addChildToPos(self, chestBg, cc.p(lc.right(fieldArea) + 8 + lc.cw(chestBg), 200))
    local index = P:getClashTargetStep()
    local chest2 = V.createClashTargetChest(index)
    chest2._callback = function (sender)
        require("ClashChestBonusForm").create(2):show()
    end
    lc.addChildToPos(self, chest2, cc.p(lc.right(fieldArea) + 24 + lc.cw(chest2) - offsetx[index], 200))
    local label = V.createTTFStroke(Str(STR.SEASON_TARGET), V.FontSize.S1)
    lc.addChildToPos(self, label, cc.p(lc.x(chestBg), lc.bottom(chestBg) - 16))
    
--    local frame2, chest2 = V.createClashFieldChest(genChestParam(2))
--    lc.addChildToPos(self, frame2, cc.p(lc.x(frame1), 250))

--    local frame3, chest3 = V.createClashFieldChest(genChestParam(3))
--    lc.addChildToPos(self, frame3, cc.p(lc.x(frame1), 140))

--    local frame4, chest4 = V.createClashFieldChest(genChestParam(4))
--    lc.addChildToPos(self, frame4, cc.p(lc.right(fieldArea) + 24 + lc.w(frame4) / 2, lc.y(frame1)))

--    local frame5, chest5 = V.createClashFieldChest(genChestParam(5))
--    lc.addChildToPos(self, frame5, cc.p(lc.right(fieldArea) + 24 + lc.w(frame5) / 2, lc.y(frame2)))

--    local frame6, chest6 = V.createClashFieldChest(genChestParam(6))
--    lc.addChildToPos(self, frame6, cc.p(lc.right(fieldArea) + 24 + lc.w(frame6) / 2, lc.y(frame3)))
    self:updateClashTarget()
    self._chests = {chest1, chest2}
end

function _M:initBottomArea()
    local area = lc.createNode(cc.size(lc.w(self) - lc.w(self._frame), 85))
    lc.addChildToPos(self, area, cc.p(lc.x(self._fieldArea), lc.ch(area) + 10), 3)
    self._bottomArea = area

    --local bottomBg = V.createLineSprite("img_bottom_bg", lc.w(area))
    --bottomBg:setScaleX(lc.w(area) / lc.w(bottomBg) + 0.1)
    --bottomBg:setScaleY(lc.h(area) / lc.h(bottomBg))
    --lc.addChildToPos(area, bottomBg, cc.p(lc.w(area) / 2, lc.h(area) / 2))

    --local bottomLine = V.createLineSprite("img_divide_line_4", lc.w(area) + 20)
    --bottomLine:setRotation(180)
    --lc.addChildToPos(area, bottomLine, cc.p(lc.w(area) / 2, 4))

    --local topLine = V.createLineSprite("img_divide_line_1", lc.w(area) + 20)
    --lc.addChildToPos(area, topLine, cc.p(lc.w(area) / 2, lc.h(area)))

    -- Add buttons

    local centerGap = 180

    local btnInfo = V.createScale9ShaderButton("img_btn_1_s", function()
        require("ClashUserInfoForm").create(P._playerFindClash._clashId, true):show()
    end, V.CRECT_BUTTON_S, 120)
    btnInfo:addLabel(Str(STR.RANK_HISTORY))
    lc.addChildToPos(area, btnInfo, cc.p(lc.cw(area) - centerGap - lc.cw(btnInfo), lc.ch(area)))
    --[[
    local btnLog = V.createScale9ShaderButton("img_btn_1_s", function() require("LogForm").create(Battle_pb.PB_BATTLE_WORLD_LADDER):show() end, V.CRECT_BUTTON_S, 120)
    btnLog:addLabel(Str(STR.LOG))    
    lc.addChildToPos(area, btnLog, cc.p(lc.w(area) - 6 - lc.w(btnLog) / 2, lc.y(btnInfo)))
    ]]
    local btnTroop = V.createScale9ShaderButton("img_btn_1_s",
        function()
            self._ignoreSync = true
            lc.pushScene(require("HeroCenterScene").create())
        end,
    V.CRECT_BUTTON_S, 120)
    btnTroop:addLabel("0")
    lc.addChildToPos(area, btnTroop, cc.p(lc.x(self._dailyWin)--[[lc.cw(area) + centerGap + lc.cw(btnTroop)]], lc.y(btnInfo)))
    self._btnTroop = btnTroop

    --[[
    local status = V.createStatusLabel(Str(STR.ALL_REGION_BATTLE), V.COLOR_TEXT_GREEN)
    lc.addChildToPos(area, status, cc.p(lc.w(area) / 2, lc.h(area) / 2 + 6))
    ]]

end

function _M:updateLogFlag()
    -- nothing to do
end

function _M:updateTroopButton()
    if self._btnTroop then
        self._btnTroop._label:setString(string.format("%s %d", Str(STR.TROOP), P._curTroopIndex))
    end
end

function _M:showFields()
    require("FindClashFieldsForm").create(P._playerFindClash._grade):show()
end

function _M:find()
    if V._findMatchPanel then return end

    -- check time
    local hour, period, isInTime = (ClientData.getServerDate() + P._timeOffset / 3600) % 24, P._playerFindClash._period
    for i = 1, #period, 2 do
        if hour >= period[i] and hour < period[i + 1] then
            isInTime = true
            break
        end
    end

    if not isInTime then
        local str = string.format(Str(STR.START_END_TIME), Str(STR.FIND_CLASH_TITLE), period[1], period[2])
        for i = 3, #period, 2 do
            str = str..string.format(Str(STR.START_END_TIME_MORE), period[i], period[i + 1])
        end

        ToastManager.push(str)
        return
    end

    local isTroopValid, msg = P._playerCard:checkTroop(P._curTroopIndex)
    if not isTroopValid then
        ToastManager.push(msg)
        return
    end

    require("FindMatchPanel").create(Data.FindMatchType.clash):show()
end

function _M:onEnter()
    self._listeners = {}

    table.insert(self._listeners, lc.addEventListener(Data.Event.clash_sync_ready, function(event)
        if self._indicator then
            self._indicator:removeFromParent()
            self._indicator = nil
        end

        self:initAreas()
        self:updateTroopButton()

        if P._playerFindClash._isFirst then
            require("FindClashFirstForm").create():show()
        end
    end))

    self:updateTroopButton()

    table.insert(self._listeners, lc.addEventListener(Data.Event.rematch_again, function(evt) self:onRematchEvent(evt) end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.rematch_npc, function(evt) self:onRematchEvent(evt) end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.rematch_hide, function(evt) self:onRematchEvent(evt) end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.trophy_dirty, function(evt) self:initChests() end))
--    table.insert(self._listeners, lc.addEventListener(Data.Event.clash_trophy_dirty, function(evt) self:initChests() end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.prop_dirty, function(evt) self:initChests() end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.bonus_dirty, function(evt)
        if evt._data._type == Data.BonusType.clash_target then     
            self:initChests()
        end
    end))
--    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    ClientData.removeMsgListener(self)
end

function _M:onMsg(msg)
--    local msgType = msg.type
--    if msgType == SglMsgType_pb.PB_TYPE_USER_OPEN_CHEST then
--        local resp = msg.Extensions[User_pb.SglUserMsg.user_open_chest_resp]

--        local chest = V.getActiveIndicator():hide()

--        local RewardPanel = require("RewardPanel")
--        RewardPanel.create(resp, RewardPanel.MODE_CHEST):show()

--        P._propBag._props[chest._infoId]._isOpened = true
--        chest:update(P._playerFindClash:getChestGrade(chest._infoId % 10))

--        --[[
--        if P._dailyResetLadder == 0 and P._playerFindClash:isAllChestsOpened() then
--            P._dailyResetLadder = 1

--            P._dailyClashWin = 0
--            self._dailyWin:setString(0)

--            P._playerFindClash:resetChests()
--            for _, chest in ipairs(self._chests) do
--                chest:update(P._playerFindClash._grade)
--            end

--            require("Dialog").showDialog(Str(STR.FIND_CLASH_CHEST_RESET_TIP), nil, true)
--        end
--        ]]

--        return true
--    end
    
    return false
end

function _M:onOpponentNotFound(pbReward)
    if V._findMatchPanel then
        V._findMatchPanel:hide()
    end

    PromptForm.ConfirmRematch.create(Data.FindMatchType.clash):show()

    if #pbReward > 0 then
        local RewardPanel = require("RewardPanel")
        RewardPanel.create(pbReward, RewardPanel.MODE_MATCH_REWARD):show()
    end
end

function _M:onRematchEvent(evt)
    local evtName = evt:getEventName()
    if evtName == Data.Event.rematch_npc then
        V.getActiveIndicator():show(Str(STR.WAITING))
        ClientData.sendWorldFindNpc(PromptForm.ConfirmRematch._troopIndex)

    elseif evtName == Data.Event.rematch_again then
        self:find()

    elseif evtName == Data.Event.rematch_hide then
        self:updateTroopButton()
    end
end

function _M:updateClashTarget()
    if self._targetCount then
        self._targetCount:removeFromParent()
        self._targetCount = nil
    end
--    if self._targetChest then
--        self._targetChest:removeFromParent()
--        self._targetChest = nil
--    end

    local step = P:getClashTargetStep()
    if step >= 1 and step <= #P._playerBonus._bonusClashTarget then
        self._targetBg:setVisible(true)

        --local targetCount = V.createTTF(P._playerBonus._bonusClashTarget[step]._info._val, V.FontSize.S3)
        local targetCount = V.createTTFStroke(P._playerBonus._bonusClashTarget[step]._info._val, V.FontSize.S1)
        lc.addChildToPos(self._targetBg, targetCount, cc.p(lc.cw(self._targetBg), lc.ch(self._targetBg) - 29))
        self._targetCount = targetCount

--        local targetChest = V.createClashTargetChest(P:getClashTargetStep(), function() self:updateClashTarget() end)
--        lc.addChildToPos(self._targetBg, targetChest, cc.p(lc.w(self._targetBg) + 60, lc.ch(self._targetBg) + 30))
--        self._targetChest = targetChest
    else
        self._targetBg:setVisible(false)
    end
    local genChestParam = function(index)
        return P._playerFindClash:getChestGrade(index), index, Data.CardQuality.UR, true
    end
    
end

return _M