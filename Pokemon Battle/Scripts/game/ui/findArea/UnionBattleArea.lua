local _M = class("UnionBattleArea", lc.ExtendCCNode)

local TOP_HEIGHT = 300
local BOTTOM_HEIGHT = 100
local MY_GROUP_HEIGHT = 260
local RANK_WIDTH = 380
local RANK_HEIGHT = 75

local TAG_CUSTOM_ITEM = 100

_M.AreaType = 
{
    default = 1,
    my_group = 2,
    game_info = 3,
}

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
        elseif evtName == "cleanup" then
            area:onCleanup()
        end
    end)

    return area
end

function _M:init()

    local bg = lc.createSprite("res/jpg/union_battle_bg.jpg")
    lc.addChildToCenter(self, bg)

    self._areaNode = lc.createNode()
    self._areaNode:setContentSize(self:getContentSize())
    lc.addChildToCenter(self, self._areaNode)

    
    self._listeners = {}
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    table.insert(self._listeners, lc.addEventListener(Data.Event.union_group_dirty, function()
        if self:isDataReady() then
            if self._indicator then
                self._indicator:removeFromParent()
                self._indicator = nil
            end
        
            self:updateView()
        end
    end))

    table.insert(self._listeners, lc.addEventListener(Data.Event.group_cards_dirty, function()
        if self._areaType == _M.AreaType.my_group then
            lc.pushScene(require("HeroCenterScene").create(Data.TroopIndex.union_battle1))
        end
    end))

    table.insert(self._listeners, lc.addEventListener(Data.Event.rank_list_dirty, function(event)
        if self._areaType == _M.AreaType.game_info then
            if event._type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP then
                self:refreshMVPRankList()
            end
            if event._type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM then
                self:refreshGroupRankList()
            end
        end
        if event._type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM or event._type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_MVP then
            if self:isDataReady() then
                if self._indicator then
                    self._indicator:removeFromParent()
                    self._indicator = nil
                end
        
                self:updateView()
            end
        end
    end))
    
end

function _M:initTopArea()
    local topArea = lc.createNode()
    topArea:setContentSize(self:getContentSize())
    lc.addChildToCenter(self, topArea)
    self._topArea = topArea

    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(topArea, titleBg, cc.p(lc.w(self) / 2, lc.h(self) - lc.h(titleBg) / 2 + 5))

    local title = V.createTTFStroke(Str(STR.UNION_BATTLE_CHAMPION), V.FontSize.S1)
    lc.addChildToCenter(titleBg, title)

    local createStage = function(level)

        local stage = ccui.Widget:create()
        stage:setContentSize(250, 236)

        local cx = lc.w(stage) / 2

        local ranks = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM)
        local group
        if ranks and ranks[level] then
            group = ranks[level]._group
        end

        if group then
            stage:setTouchEnabled(true)        
            stage:addTouchEventListener(function(sender, evt)
                if evt == ccui.TouchEventType.ended then
                    require("GroupInfoForm").create(group):show()
                end
            end)
        end

        local bottom = cc.ShaderSprite:createWithFramename("img_stage_gold")
        lc.addChildToPos(stage, bottom, cc.p(cx, lc.h(bottom) / 2))

        local glow = cc.ShaderSprite:createWithFramename("img_stage_gold_light")
        glow:setScale(2)
        lc.addChildToPos(bottom, glow, cc.p(lc.w(bottom) / 2, lc.h(bottom) + 40))

--        local avatar = V.createGroupAvatar(group._avatar)
        local GroupWidget = require("GroupWidget")
        local avatar = V.createGroupAvatar(group and group._avatar or 1)
        lc.addChildToPos(stage, avatar, cc.p(cx, lc.h(stage) - lc.h(avatar) / 2))
        stage._avatar = avatar

--        local region = V.createTTF(group and ClientData.genChannelRegionName(group._members[1]._regionId) or "", V.FontSize.S3)
--        lc.addChildToPos(stage, region, cc.p(cx, 82))
        local trophyNum = 0
        if group then
            for _, mem in ipairs(group:getMembers()) do
                trophyNum = trophyNum + mem._massWarScore
            end
        end
        local trophy = V.createIconLabelArea("img_icon_res15_s", trophyNum, 150)
        trophy._valBg:setScale(0.84)
        trophy._icon:setScale(0.84)
        lc.offset(trophy._icon, 10)
        lc.offset(trophy._label, - 10)
        lc.addChildToPos(stage, trophy, cc.p(cx, 85))
        stage._trophy = trophy._label

        local name = V.createTTF(group and group._name or string.format(Str(STR.LIST_EMPTY_NO_X), Str(STR.GROUP)), V.FontSize.S2)
        lc.addChildToPos(stage, name, cc.p(cx, 24))
        stage._name = name

        if level == 1 then
        else
            bottom:setScaleY(0.9)
            lc.offset(avatar, 0, -4)
--            lc.offset(region, 0, 2)
            lc.offset(name, 0, 4)

            if level == 2 then
                bottom:setEffect(V.SHADER_COLOR_STAGE_SILVER)
                glow:setEffect(V.SHADER_COLOR_STAGE_SILVER)

            elseif level == 3 then
                bottom:setEffect(V.SHADER_COLOR_STAGE_BRONZE)
                glow:setEffect(V.SHADER_COLOR_STAGE_BRONZE)
            end
        end

        return stage
    end

    local stage1 = createStage(1)
    lc.addChildToPos(topArea, stage1, cc.p(lc.w(self) / 2, lc.bottom(titleBg) + 8 - lc.h(stage1) / 2), 1)

    local stage2 = createStage(2)
    lc.addChildToPos(topArea, stage2, cc.p(math.max(lc.left(stage1) - 30 - lc.w(stage2), 0) + lc.w(stage2) / 2, lc.y(stage1)))

    local stage3 = createStage(3)
    lc.addChildToPos(topArea, stage3, cc.p(math.min(lc.right(stage1) + 30 + lc.w(stage2), lc.w(self)) - lc.w(stage3) / 2, lc.y(stage1)))

    topArea._stages = {stage1, stage2, stage3}

--    local crect = cc.rect(V.CRECT_COM_BG5.x, 0, V.CRECT_COM_BG5.width, lc.frameSize("img_com_bg_5").height)

--    local preRanks = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM, nil)
--    if preRanks and preRanks._count > 0 then
--        local btnRank = V.createScale9ShaderButton("img_com_bg_5", function() require("RankForm").create(Data.RankRange.region, 1, 100, true):show() end, crect, 160)
--        btnRank:addLabel(Str(STR.SEASON_LAST_RANK))
--        lc.addChildToPos(topArea, btnRank, cc.p(lc.right(stage3) - lc.w(btnRank) / 2, lc.y(titleBg)))

--        --TODO--
--        btnRank:setVisible(false)
--    end
end

function _M:enterDefultArea()
    
    if self._areaType and self._areaType == _M.AreaType.default then
        self._areaNode:update()
        return 
    else
        self._areaType = _M.AreaType.default
    end

    self._areaType = _M.AreaType.default
    self._topArea:setVisible(true)

    local layout = self._areaNode
    layout:removeAllChildren()

    local mvpNode = lc.createNode()
    lc.addChildToPos(layout, mvpNode, cc.p(lc.cw(layout), lc.h(layout) - TOP_HEIGHT - 70))

    local mvpBg = lc.createSpriteWithMask("res/jpg/my_group_bg.jpg")
    mvpBg:setScale(lc.w(layout) / lc.w(mvpBg), 130 / lc.h(mvpBg))
    mvpBg:setPositionY(-5)
    mvpNode:addChild(mvpBg)

    local mvpRanks, mvpUser = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_MVP)
    if mvpRanks and #mvpRanks > 0 then
        mvpUser = mvpRanks[1]._user
    end
    local mvpTitleArea = lc.createNode()
    local mvpTitleSpr = lc.createSprite("img_medal_mvp")
    local mvpTitleLabel = V.createBMFont(V.BMFont.huali_26, Str(STR.LAST_SEASON))
    mvpTitleArea:setContentSize(cc.size(lc.w(mvpTitleSpr), lc.h(mvpTitleSpr) + 40))
    lc.addChildToPos(mvpTitleArea, mvpTitleSpr, cc.p(lc.cw(mvpTitleArea), lc.ch(mvpTitleSpr)))
    lc.addChildToPos(mvpTitleArea, mvpTitleLabel, cc.p(lc.cw(mvpTitleArea), lc.top(mvpTitleSpr) + lc.ch(mvpTitleLabel) + 10))
    local user = UserWidget.create(mvpUser, mvpUser and bor(UserWidget.Flag.NAME_UNION) or 0, 1.0)
    if mvpUser then
        user._unionArea._name:setColor(V.COLOR_TEXT_WHITE)
    end
    lc.addNodesToCenterH(mvpNode, {mvpTitleArea, user}, 10)



--    local flag = lc.createSpriteWithMask("res/jpg/grade_flag.jpg")
--    lc.addChildToPos(layout, flag, cc.p(lc.cw(self) + lc.cw(flag) + 150, lc.h(self) - lc.ch(flag) - 20))

--    local gradeBg = lc.createSpriteWithMask("res/jpg/grade_bg.jpg")
--    lc.addChildToPos(flag, gradeBg, cc.p(lc.cw(flag), lc.h(flag) - lc.ch(gradeBg) - 20))

--    local curGradeLabel = V.createBMFont(V.BMFont.huali_20, Str(STR.CURRENT)..Str(STR.GRADE))
--    curGradeLabel:setColor(V.COLOR_TEXT_INGOT)
--    curGradeLabel:setScale(0.8)
--    lc.addChildToPos(gradeBg, curGradeLabel, cc.p(lc.cw(gradeBg), lc.ch(curGradeLabel) + 40))

--    local highestGradeLabel = V.createBMFont(V.BMFont.huali_20, Str(STR.HIGHEST)..Str(STR.GRADE))
--    highestGradeLabel:setScale(0.7)
--    highestGradeLabel:setAnchorPoint(0, 0.5)
--    lc.addChildToPos(flag, highestGradeLabel, cc.p(20, lc.bottom(gradeBg) - lc.ch(highestGradeLabel) - 10))

--    local lastGradeLabel = V.createBMFont(V.BMFont.huali_20, Str(STR.SEASON_LAST)..Str(STR.GRADE))
--    lastGradeLabel:setScale(0.7)
--    lastGradeLabel:setAnchorPoint(0, 0.5)
--    lc.addChildToPos(flag, lastGradeLabel, cc.p(20, lc.bottom(highestGradeLabel) - lc.ch(lastGradeLabel) - 40))
    
    lc.TextureCache:addImageWithMask("res/jpg/create_group.jpg")
    local createBtn = V.createShaderButton("res/jpg/create_group.jpg", function(sender)
        if not P._playerUnion:getMyUnion() then 
            return ToastManager.push(Str(STR.NOT_JOIN_ANY_UNION))
        end
        require("CreateGroupForm").create():show()
    end)
    lc.addChildToPos(layout, createBtn, cc.p(lc.cw(self) - 200, lc.ch(createBtn) + 20))

    lc.TextureCache:addImageWithMask("res/jpg/join_group.jpg")
    local groupBtn = V.createShaderButton("res/jpg/join_group.jpg", function(sender)
        if not P._playerUnion:getMyUnion() then 
            return ToastManager.push(Str(STR.NOT_JOIN_ANY_UNION))
        end
        require("GroupForm").create():show()
        end)
    lc.addChildToPos(self._areaNode, groupBtn, cc.p(lc.cw(self) + 200, lc.y(createBtn)))

--    local msgBtn = V.createScale9ShaderButton("img_btn_2_s", function(sender)  end, V.CRECT_BUTTON_S, 120)
--    msgBtn:addLabel(Str(STR.INVITE)..Str(STR.MESSAGE))
--    lc.addChildToPos(self._areaNode, msgBtn, cc.p(lc.cw(self) + 200, BOTTOM_HEIGHT / 2))

--    local btnTroop = V.createScale9ShaderButton("img_btn_2_s",
--        function()
--            self._ignoreSync = true
--            lc.pushScene(require("HeroCenterScene").create())
--        end,
--    V.CRECT_BUTTON_S, 120)
--    btnTroop:addLabel("0")
--    lc.addChildToPos(self._areaNode, btnTroop, cc.p(lc.cw(self) - 200, BOTTOM_HEIGHT / 2))
--    self._btnTroop = btnTroop

    function layout:update()
    
    end

end

function _M:enterMyGroupArea()

    if self._areaType and self._areaType == _M.AreaType.my_group then
        self._areaNode:update()
        return 
    end

    self._areaType = _M.AreaType.my_group
    self._topArea:setVisible(true)

    local layout = self._areaNode
    layout:removeAllChildren()
--    local bg = lc.createSprite{_name = "img_com_bg_35", _crect = V.CRECT_COM_BG35, _size = layout:getContentSize()}
--    lc.addChildToCenter(layout, bg, -1)
--    layout._bg = bg

    local myGroupArea = self:createMyGroupArea(MY_GROUP_HEIGHT, false, true)
    lc.addChildToPos(layout, myGroupArea, cc.p(lc.cw(layout), lc.h(layout) - TOP_HEIGHT - MY_GROUP_HEIGHT))

    local timeBg = lc.createSprite("wait_text_bg")
    timeBg:setScale(lc.w(layout) / lc.w(timeBg), 41 / lc.h(timeBg))
    lc.addChildToPos(layout, timeBg, cc.p(lc.cw(layout), lc.bottom(myGroupArea) - 20))

    local timeLabel = V.createTTF(P._playerFindUnionBattle:getStartTimeTip(), V.FontSize.S2)
    lc.addChildToPos(layout, timeLabel, cc.p(lc.cw(layout), lc.bottom(myGroupArea) - 20))
--    timeLabel:runAction(lc.rep(lc.sequence(
--            function ()
--                if P._playerFindUnionBattle:getIsValidTime() == 0 then
--                    timeLabel:setString(Str(STR.END_COUNTDOWN).."  "..P._playerFindUnionBattle:getEndTimeTip())
--                elseif P._playerFindUnionBattle:getIsValidTime() == -1 then
--                    timeLabel:stopAllActions()
--                    timeLabel:setString(Str(STR.UNION_BATTLE_ENDED))
--                elseif P._playerFindUnionBattle:getIsValidTime() == 1 then
--                    timeLabel:setString(Str(STR.UNION_BATTLE_COUNTDOWN).."  "..P._playerFindUnionBattle:getStartTimeTip())
--                end
--            end
--            ,lc.delay(1.0)
--        )))

    local startBtn = V.createScale9ShaderButton("img_btn_1", function(sender) self:onStartBtn() end, V.CRECT_BUTTON, 150)
    startBtn:addLabel(Str(STR.ENTER_GROUP_BATTLE))
    lc.addChildToPos(layout, startBtn, cc.p(lc.cw(layout), 50))

    local quitBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onExitGroup() end, V.CRECT_BUTTON_S, 150)
    quitBtn:addLabel(Str(STR.EXIT_GROUP))
    lc.addChildToPos(layout, quitBtn, cc.p(lc.cw(layout) + 200, 50))

    local troopBtn = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onTroopBtn() end, V.CRECT_BUTTON_S, 150)
    troopBtn:addLabel(Str(STR.MANAGE_CARDS))
    lc.addChildToPos(layout, troopBtn, cc.p(lc.cw(layout) - 200, 50))

--    local flag = lc.createSpriteWithMask("res/jpg/grade_flag.jpg")
--    lc.addChildToPos(self._areaNode, flag, cc.p(lc.cw(self) + lc.cw(flag) + 150, lc.h(self) - lc.ch(flag) - 20))

--    local gradeBg = lc.createSpriteWithMask("res/jpg/grade_bg.jpg")
--    lc.addChildToPos(flag, gradeBg, cc.p(lc.cw(flag), lc.h(flag) - lc.ch(gradeBg) - 20))

--    local curGradeLabel = V.createBMFont(V.BMFont.huali_20, Str(STR.CURRENT)..Str(STR.GRADE))
--    curGradeLabel:setColor(V.COLOR_TEXT_INGOT)
--    curGradeLabel:setScale(0.8)
--    lc.addChildToPos(gradeBg, curGradeLabel, cc.p(lc.cw(gradeBg), lc.ch(curGradeLabel) + 40))

--    local highestGradeLabel = V.createBMFont(V.BMFont.huali_20, Str(STR.HIGHEST)..Str(STR.GRADE))
--    highestGradeLabel:setScale(0.7)
--    highestGradeLabel:setAnchorPoint(0, 0.5)
--    lc.addChildToPos(flag, highestGradeLabel, cc.p(20, lc.bottom(gradeBg) - lc.ch(highestGradeLabel) - 10))

--    local lastGradeLabel = V.createBMFont(V.BMFont.huali_20, Str(STR.SEASON_LAST)..Str(STR.GRADE))
--    lastGradeLabel:setScale(0.7)
--    lastGradeLabel:setAnchorPoint(0, 0.5)
--    lc.addChildToPos(flag, lastGradeLabel, cc.p(20, lc.bottom(highestGradeLabel) - lc.ch(lastGradeLabel) - 40))

    layout.update = function()
        myGroupArea.update()
--        startBtn:setVisible(P._playerUnion._groupJob and P._playerUnion._groupJob == Data.GroupJob.leader)
    end

    layout.update()
end

function _M:onStartBtn()
    if P._playerFindUnionBattle:getIsValidTime() ~= 0 then
            return ToastManager.push(Str(STR.DARK_BATTLE_NOT_STARTED))
    end
    local myGroup = P._playerUnion:getMyGroup()
    if #myGroup._members ~= Data.GROUP_NUM then
        return ToastManager.push(Str(STR.CANNOT_START_UNION_BATTLE))
    end
    V.getActiveIndicator():show(Str(STR.WAITING))
--    self:enterGameInfoArea()
    ClientData.sendStartUnionBattle()
end

function _M:createMyGroupArea(height, showDetail, canOperate)
    local layout = lc.createNode()
    layout:setContentSize(cc.size(lc.w(self, height)))
    layout:setAnchorPoint(0.5, 0.5)
    
    local myGroupBg = lc.createSpriteWithMask("res/jpg/my_group_bg.jpg")
    myGroupBg:setScale(lc.w(layout) / lc.w(myGroupBg), height / lc.h(myGroupBg))
    lc.addChildToPos(layout, myGroupBg, cc.p(lc.cw(layout), height / 2))

    local avatarSpr = V.createGroupAvatar(1)
    lc.addChildToPos(layout, avatarSpr, cc.p(lc.cw(layout) - 310, lc.y(myGroupBg) + 20))

    local groupNameBg = lc.createSprite("group_name_bg")
    lc.addChildToPos(layout, groupNameBg, cc.p(lc.x(avatarSpr), lc.bottom(avatarSpr) - 20))

    local groupNameLabel = V.createTTF("", V.FontSize.S3)
    lc.addChildToCenter(groupNameBg, groupNameLabel)

    local splitLine = lc.createSprite("my_split_line")
    splitLine:setScaleY( (height - 3) / lc.h(splitLine))
    lc.addChildToPos(layout, splitLine, cc.p(lc.right(avatarSpr) + 20, lc.y(myGroupBg) + 1))
    
    local startX = lc.right(splitLine) - 10
    local members, memItems = {}, {}
    for i = 1, Data.GROUP_NUM do
        local item = V.createUnionGroupMemItem(nil, members[i], false, showDetail)
        item._canOperate = canOperate
        item._addFunc = function(sender)
            self:onInvite()
        end
        lc.addChildToPos(layout, item, cc.p(startX + i * 120 - 30, lc.y(myGroupBg)))
        table.insert(memItems, item)
    end

    for i = Data.GROUP_NUM + 1, 5 do
        local lockedSpr = lc.createSprite("group_mem_lock")
        lc.addChildToPos(layout, lockedSpr, cc.p(startX + i * 120 - 30, lc.y(myGroupBg) + (showDetail and 25 or 5)))
    end

    layout.update = function()
        local myGroup = P._playerUnion:getMyGroup()
        avatarSpr.update(myGroup._avatar)
        groupNameLabel:setString(myGroup._name)
        local members = myGroup._members
        for i = 1, Data.GROUP_NUM do
            memItems[i]:update(myGroup._id, members[i], false, showDetail)
            memItems[i]._nameLabel:setColor(members[i] and V.COLOR_TEXT_WHITE or V.COLOR_TEXT_BLUE)
        end
    end

    return layout
end

function _M:onTroopBtn()
    local myGroup = P._playerUnion:getMyGroup()

    if not myGroup then return self:updateView() end

    if #myGroup:getMembers() < Data.GROUP_NUM then
        ToastManager.push(Str(STR.CANNOT_MANAGE_CARDS))
    else
        V.getActiveIndicator():show(Str(STR.WAITING))
        ClientData.sendGetGroupCards()
        
    end
end

function _M:onExitGroup()
    require("Dialog").showDialog(Str(STR.EXIT_GROUP_CONFIRM), function()
        if P._playerUnion:getMyGroup() then
            P._playerUnion:exitGroup()
        end
    end)
end

function _M:getRanks()
--    P._playerRank:sendRankRequest(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP)
--    P._playerRank:sendRankRequest(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM)
    if self._areaType ~= _M.AreaType.game_info and self._rankUpdateSchedule then
        return lc.Scheduler:unscheduleScriptEntry(self._rankUpdateSchedule)
    end
    ClientData.sendRankRequest(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP)
    ClientData.sendRankRequest(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM)
end

function _M:enterGameInfoArea()
    if self._areaType and self._areaType == _M.AreaType.game_info then
        self._areaNode:update()
        return 
    end
    self._areaType = _M.AreaType.game_info
    self._topArea:setVisible(false)

    local layout = self._areaNode
    layout:removeAllChildren()

    self._rankUpdateSchedule = lc.Scheduler:scheduleScriptFunc(function(dt) self:getRanks()  end, 60, false)

    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(layout, titleBg, cc.p(lc.w(self) / 2, lc.h(self) - lc.h(titleBg) / 2 + 5))

    local title = V.createTTFStroke(Str(STR.UNION_BATTLE_ARENA), V.FontSize.S1)
    lc.addChildToPos(titleBg, title, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2))

    local timeLabel = V.createTTF("", V.FontSize.S2, V.COLOR_TEXT_INGOT)
    lc.addChildToPos(layout, timeLabel, cc.p(lc.cw(layout), lc.bottom(titleBg) - 15))
    timeLabel:runAction(lc.rep(lc.sequence(
            function ()
                if P._playerFindUnionBattle:getIsValidTime() == 0 then
                    timeLabel:setString(Str(STR.END_COUNTDOWN).."  "..P._playerFindUnionBattle:getEndTimeTip())
                elseif P._playerFindUnionBattle:getIsValidTime() == -1 then
                    timeLabel:stopAllActions()
                    timeLabel:setString(Str(STR.UNION_BATTLE_ENDED))
                    ToastManager.push(Str(STR.UNION_BATTLE_ENDED))
                    P._playerUnion:getMyGroup()._gameStarted = false
                    P._playerRank:clearPreRank(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_MVP)
                    P._playerRank:clearPreRank(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM)
                    self._topArea:removeFromParent()
                    self._topArea = nil
                    self:updateView()
                elseif P._playerFindUnionBattle:getIsValidTime() == 1 then
                    timeLabel:setString(P._playerFindUnionBattle:getStartTimeTip())
                end
            end
            ,lc.delay(1.0)
        )))

    local myGroupArea = self:createMyGroupArea(MY_GROUP_HEIGHT - 80, true)
    lc.addChildToPos(layout, myGroupArea, cc.p(lc.cw(layout), lc.h(layout) - MY_GROUP_HEIGHT - 10))
    myGroupArea.update()

    local rankTilteBg = lc.createSprite("rank_bg")
    rankTilteBg:setScaleX(lc.w(layout) / lc.w(rankTilteBg))
    lc.addChildToPos(layout, rankTilteBg, cc.p(lc.cw(layout), lc.bottom(myGroupArea) - lc.ch(rankTilteBg)))

    local groupRankTitle = V.createTTF(Str(STR.GROUP_RANK), V.FontSize.S3)
    lc.addChildToPos(layout, groupRankTitle, cc.p(lc.cw(layout) - 200, lc.y(rankTilteBg)))

    local mvpRankTitle = V.createTTF(Str(STR.MVP_RANK), V.FontSize.S3)
    lc.addChildToPos(layout, mvpRankTitle, cc.p(lc.cw(layout) + 200, lc.y(rankTilteBg)))

    self:addRankLists(lc.bottom(rankTilteBg))

    local startBtn = V.createScale9ShaderButton("img_btn_1", function(sender)
        if P._playerFindUnionBattle:getIsValidTime() ~= 0 then
            return ToastManager.push(Str(STR.DARK_BATTLE_NOT_STARTED))
        end
        self:find()
    end, V.CRECT_BUTTON, 150)
    startBtn:addLabel(Str(STR.SEEK_OPPONENT))
    lc.addChildToPos(layout, startBtn, cc.p(lc.cw(layout), 50))

    P._playerRank:sendRankRequest(SglMsgType_pb.PB_TYPE_RANK_TROPHY)
    
    self:getRanks()

    function layout:update()
        myGroupArea.update()
    end

end

function _M:find()
    if V._findMatchPanel then return end

    -- check time
--    local hour, period, isInTime = (ClientData.getServerDate() + P._timeOffset / 3600) % 24, P._playerFindClash._period
--    for i = 1, #period, 2 do
--        if hour >= period[i] and hour < period[i + 1] then
--            isInTime = true
--            break
--        end
--    end

--    if not isInTime then
--        local str = string.format(Str(STR.START_END_TIME), Str(STR.FIND_CLASH_TITLE), period[1], period[2])
--        for i = 3, #period, 2 do
--            str = str..string.format(Str(STR.START_END_TIME_MORE), period[i], period[i + 1])
--        end

--        ToastManager.push(str)
--        return
--    end

--    local isTroopValid, msg = P._playerCard:checkTroop(P._curTroopIndex)
--    if not isTroopValid then
--        ToastManager.push(msg)
--        return
--    end

    require("FindMatchPanel").create(Data.FindMatchType.union_battle):show()
end

function _M:addRankLists(startY)
    local layout = self._areaNode

    local mvpRanks = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP)
    local selfMvpRank = mvpRanks and mvpRanks._selfRank
    if not selfMvpRank then
        selfMvpRank = {}
        selfMvpRank._user = P
        selfMvpRank._value = P._playerUnion._battleTrophy
        selfMvpRank._rank = 0
    end

    local groupRanks = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM)
    local selfgroupRank = groupranks and groupRanks._selfRank
    if not selfgroupRank then
        selfgroupRank = {}
        local myGroup = P._playerUnion:getMyGroup()
        selfgroupRank._group = myGroup
        local value = 0
        for _, mem in ipairs(myGroup:getMembers()) do
            value = value + mem._massWarScore
        end
        selfgroupRank._value = value
        selfgroupRank._rank = 0
    end

    local myMvpRankItem = self:setOrCreateItem(nil, selfMvpRank, SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP)
    myMvpRankItem._item._bar:setVisible(false)
    myMvpRankItem._item:setSpriteFrame("img_com_bg_4")
--    myMvpRankItem._item:setColor(V.COLOR_TEXT_BLUE)
    lc.addChildToPos(layout, myMvpRankItem, cc.p(lc.cw(layout) + 203, startY - RANK_HEIGHT / 2))
    self._myMvpRankItem = myMvpRankItem

    local myGroupRankItem = self:setOrCreateItem(nil, selfgroupRank, SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM)
    myGroupRankItem._item._bar:setVisible(false)
    lc.addChildToPos(layout, myGroupRankItem, cc.p(lc.cw(layout) - 195, startY - RANK_HEIGHT / 2))
    self._myGroupRankItem = myGroupRankItem

    startY = startY - RANK_HEIGHT
    
    local groupList = lc.List.createV(cc.size(RANK_WIDTH, startY - 100), 6, 0)
    groupList:setAnchorPoint(0.5, 0.5)
    groupList._rankType = SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM
    lc.addChildToPos(layout, groupList, cc.p(lc.cw(layout) - 195, startY - lc.ch(groupList) ))
    self._groupList = groupList

    local mvpList = lc.List.createV(cc.size(RANK_WIDTH, startY - 100), 6, 0)
    mvpList:setAnchorPoint(0.5, 0.5)
    mvpList._rankType = SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP
    lc.addChildToPos(layout, mvpList, cc.p(lc.cw(layout) + 203, startY - lc.ch(mvpList) ))
    self._mvpList = mvpList

end

function _M:refreshMVPRankList()
    local list = self._mvpList
    
    local ranks = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP)

    if ranks == nil then return end

    local selfRank = ranks._selfRank
    if selfRank then
        self._myMvpRankItem.update(selfRank, SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP)
        self._myMvpRankItem._item:setSpriteFrame("img_com_bg_4")
--        self._myMvpRankItem._item:setColor(V.COLOR_TEXT_BLUE)
    end

    -- Create items
    list:bindData(ranks, function(item, rank) self:setOrCreateItem(item, rank, SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP) end, math.min(4, ranks._count))

    for i = 1, list._cacheCount do
        local rank = ranks[i]
        local item = self:setOrCreateItem(nil, rank, SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP)
        list:pushBackCustomItem(item)
    end

    list:checkEmpty(Str(STR.LIST_EMPTY_RANK_MVP))

    list:refreshView()
    list:gotoTop()
end

function _M:refreshGroupRankList()
    local list = self._groupList

    local ranks = P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM)

    if ranks == nil then return end

    local selfRank = ranks._selfRank
    if selfRank then
        self._myGroupRankItem.update(selfRank, SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM)
    end

    -- Create items
    list:bindData(ranks, function(item, rank) self:setOrCreateItem(item, rank, SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM) end, math.min(4, ranks._count or 0))

    for i = 1, list._cacheCount do
        local rank = ranks[i]
        local item = self:setOrCreateItem(nil, rank, SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM)
        list:pushBackCustomItem(item)
    end

    list:checkEmpty(Str(STR.LIST_EMPTY_RANK_GROUP))

    list:refreshView()
    list:gotoTop()
end

function _M:setOrCreateItem(layout, rank, type)
    local range = self._range

    

    if layout == nil then
        layout = ccui.Widget:create()
        layout:setContentSize(cc.size(RANK_WIDTH, RANK_HEIGHT))
        item = lc.createImageView{_name = "img_com_bg_35", _crect = V.CRECT_COM_BG35}
        item:setContentSize(RANK_WIDTH * 108 / lc.h(layout), (range == Data.RankRange.lord and range == Data.RankRange.region) and 108  or 108)
        item:setScale(lc.h(layout) / 108)
        
        item:setTouchEnabled(true)
        item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

        lc.addChildToCenter(layout, item)
        layout._item = item

        local bar = lc.createSprite('img_bg_deco_35')
        local scale = 150 / lc.w(bar)
        bar:setScaleX(scale)
        lc.addChildToPos(item, bar, cc.p(lc.cw(bar) * scale, lc.ch(item) + 3))
        item._bar = bar
        
        local valueArea
        if type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP then
--            item:addTouchEventListener(function(sender, type)
--                if type == ccui.TouchEventType.ended then
--                    if sender._rank and self._mvpList then
--                        if sender._rank._user._id ~= self._mvpList._data._rankId then
--                            V.operateUser(sender._rank._user, sender)
----                            require("ClashUserInfoForm").create(sender._rank._user._id):show()
--                        end
--                    end
--                end
--            end)

            local userArea = UserWidget.create(nil, UserWidget.Flag.NAME_UNION, 1.2)
            userArea:setScale(0.7)
            lc.addChildToPos(item, userArea, cc.p(85 + lc.w(userArea) / 2 + 10, lc.h(item) / 2 + 4))
            item._avatarArea = userArea
        
            valueArea = self:addValueArea(item, "img_icon_res15_s", "")
        elseif type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM then
            item:addTouchEventListener(function(sender, evt)
                if evt == ccui.TouchEventType.ended then
                    local rankGroup = sender._rank._group
                    if rankGroup._id ~= P._playerUnion._groupId then
                        require("GroupInfoForm").create(rankGroup):show()
                    end
                end
            end)

            local GroupWidget = require("GroupWidget")
            local groupArea = GroupWidget.create(nil, bor(GroupWidget.Flag.NAME, GroupWidget.Flag.REGION), 0.8)
            groupArea:setScale(0.9)
            lc.addChildToPos(item, groupArea, cc.p(120 + lc.w(groupArea) / 2, lc.h(item) / 2 + 5))
            groupArea._regionLabel:setColor(V.COLOR_TEXT_DARK)
            item._avatarArea = groupArea

            valueArea = self:addValueArea(item, "img_icon_res15_s", "")
        end

        if valueArea then
            valueArea:setPosition(lc.w(item) - 5 - lc.cw(valueArea), lc.y(item._avatarArea))
            item._valueArea = valueArea
        end
        layout.update = function(rank, type)
    --        if type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM and rank and not rank._group then
    --            rank._group = P._playerUnion:getMyGroup()
    --        end
            if rank then
                local item = layout._item
                item:removeChildrenByTag(TAG_CUSTOM_ITEM)
                item._rank = rank
                item._rankType = type

                local rankNum = rank._rank
                if rankNum <= 3 and rankNum > 0 then
                    local medalStr = string.format("img_medal_%d", rankNum)
                    if type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP and rankNum == 1 then
                        medalStr = "img_medal_mvp"
                    end
                    medal = lc.createSprite(medalStr)
                    medal:setPosition(lc.w(medal) / 2 + 5, lc.h(item) / 2 + 5)
                    item:addChild(medal, 0, TAG_CUSTOM_ITEM)
                    item._bar:setColor(rankNum == 1 and cc.c3b(250, 64, 0) or (rankNum == 2 and cc.c3b(0, 144, 250) or cc.c3b(166, 128, 136)))
                elseif rankNum == 0 then
                    local title = V.createBMFont(V.BMFont.huali_32, Str(STR.NOT_IN_RANK))
                    title:setPosition(50, lc.h(item) / 2 + 2)
                    item:addChild(title, 0, TAG_CUSTOM_ITEM)
                    item._bar:setColor(lc.Color3B.white)
                else
                    local number = V.createBMFont(V.BMFont.huali_32, tostring(rankNum))
                    number:setScale(1.5)
                    number:setPosition(65, lc.h(item) / 2 + 2)
                    item:addChild(number, 0, TAG_CUSTOM_ITEM)
                    item._bar:setColor(lc.Color3B.white)
                end

                if type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_MVP then
                    if self._mvpList and self._mvpList._data and self._mvpList._data._rankId and rank._user._id == self._mvpList._data._rankId then
                        item:setSpriteFrame("img_com_bg_4")
--                        item:setColor(V.COLOR_TEXT_BLUE)
                    else
                        item:setSpriteFrame("img_com_bg_35")
--                        item:setColor(lc.Color3B.white)
                    end

                    item._avatarArea:setUser(rank._user, true)
                    item._valueArea._label:setString(rank._value)
                elseif type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM then
                    if rank._group._id == P._playerUnion:getMyGroup()._id then
                        item:setSpriteFrame("img_com_bg_4")
--                        item:setColor(V.COLOR_TEXT_BLUE)
                    else
                        item:setSpriteFrame("img_com_bg_35")
--                        item:setColor(lc.Color3B.white)
                    end

                    item._avatarArea:setGroup(rank._group)
                    item._valueArea._label:setString(rank._value)
                end
            end
        end
    end
    

    layout.update(rank, type)
    
    return layout
end

function _M:addValueArea(parent, iconName, val, width)
    local area = V.createIconLabelArea(iconName, tostring(val), width or 140)
    area:setAnchorPoint(0.5, 0.5)
    parent:addChild(area)
    return area
end

function _M:onInvite()
--    require("UnionMemberForm").createSelect(4, function(sender)
--        local members = sender._members
--        local str = ""
--        for _, member in pairs(members) do
--            if member._isSelected then
--                str = str..member._name
--            end
--        end
--        sender:hide()
--        ToastManager.push(str)
--    end):show()
    ToastManager.push(Str(STR.WAIT_MEMBER))
end

function _M:onEnter()
    P._playerRank:clearPreRank(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_MVP)
    P._playerRank:clearPreRank(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM)
    
    self:updateView()
    

--    self:updateTroopButton()

--    -- Send packet
--    if P._unionId == self._unionId then
--        local myUnion = P._playerUnion:getMyUnion()
--        if myUnion then
--            self:updateView(myUnion)
--        end
--    else
--        self._indicator = V.showPanelActiveIndicator(self)
--        self._topArea:setVisible(false)
--        performWithDelay(self, function() ClientData.sendGetUnionDetail(self._unionId) end, BaseForm.ACTION_DURATION)
--    end
end

function _M:isDataReady()
    return not (P._playerUnion._groupId and not P._playerUnion:getMyGroup()) and P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_MVP) and P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM)
end

function _M:updateView()
    if P._playerUnion._groupId and not P._playerUnion:getMyGroup() then
        if not self._indicator then
            self._indicator = V.showPanelActiveIndicator(self)
        end
        ClientData.sendGetGroups()
    end
    
    if not P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_MVP) or not P._playerRank:getRanks(SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM) then
        if not self._indicator then
            self._indicator = V.showPanelActiveIndicator(self)
        end
        ClientData.sendGetPreRanks()
    end

    if not self:isDataReady() then return end

    if not self._topArea then
        self:initTopArea()
    end

    
    if P._playerUnion:getMyGroup() and P._playerUnion:getMyGroup()._gameStarted and P._playerFindUnionBattle:getIsValidTime() then
        self:enterGameInfoArea()
    elseif P._playerUnion:getMyGroup() then
        self:enterMyGroupArea()
    else
        self:enterDefultArea()
    end
end

function _M:onExit()
    
    
    ClientData.removeMsgListener(self)
end

function _M:onMsg(msg)
    local msgType = msg.type

--    if msgType == SglMsgType_pb.PB_TYPE_UNION_DETAIL then
--        local resp = msg.Extensions[Union_pb.SglUnionMsg.union_detail_resp]
--        if resp.union_info.id == self._unionId then
--            local union = require("Union").create(resp.union_info, resp.group_info)
--            if self._indicator then
--                self._indicator:removeFromParent()
--                self._indicator = nil
--            end

--            if union then
--                self:updateView(union)
--                self._topArea:setVisible(true)
--            else
--                if self._callback then
--                    self._callback()
--                end
--            end
--        end
--    end
    
    return false
end

function _M:onCleanup()
    lc.TextureCache:removeTextureForKey("res/jpg/union_battle_bg.jpg")
    lc.TextureCache:removeTextureForKey("res/jpg/create_group.jpg")
    lc.TextureCache:removeTextureForKey("res/jpg/join_group.jpg")
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    if self._areaType == _M.AreaType.game_info then
--        ClientData.sendQuitUnionBattle()
    end

    if self._rankUpdateSchedule then
        lc.Scheduler:unscheduleScriptEntry(self._rankUpdateSchedule)
        self._rankUpdateSchedule = nil
    end
end

return _M