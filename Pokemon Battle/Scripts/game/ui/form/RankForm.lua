local _M = class("RankForm", BaseForm)

local FORM_SIZE = cc.size(960, 660)

local SELF_AREA_HEIGHT = 110
local ITEM_HEIGHT = 120
local ITEM_HEIGHT_UNION = 140

local TIME_POS = cc.p(420, 25)
local TIME_SIZE = cc.size(280, 34)

local FIRST_RANK_POS = cc.p(700, 78)
local SECOND_RANK_POS = cc.p(700, 48)
local THIRD_RANK_POS = cc.p(700, 20)

local TAG_CUSTOM_ITEM = 100     -- Used to find the custom items in the self area

local CLASH_BASE = 100

local RANK_TROPHY_VISIBLE_LEVEL = 30

function _M.create(range, tab, subTab, isPre)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(range, tab, subTab, isPre)
    return panel
end

function _M:init(range, tab, subTab, isPre)
    _M.super.init(self, FORM_SIZE, Str(STR.BILLBOARD), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))  
    
    self:inittabArea()
    self:initSelfArea()
    self:initTop3Panel()
    self:initMainList()

    self._isPre = isPre

    --self:addTabs({Str(STR.LORD_RANK), Str(STR.UNION_RANK), Str(STR.REGION_RANK)}, range)

    self._initTabIndex = tab or 1
    self._initSubTab = subTab
    if range == Data.RankRange.lord and self._initTabIndex == 1 then
        self._initSubTab = self._initSubTab or 21
    end

    self._range = range
    self:refreshRank()
end

function _M:inittabArea()
    local tabArea = V.createHorizontalTabListArea2(lc.w(self._form) - 40, nil, function(tab) self:showSubTab(tab) end)
    lc.addChildToPos(self._form, tabArea, cc.p(_M.LEFT_MARGIN + lc.w(tabArea) / 2 - 12, lc.h(self._form) - 100 + 10), 3)
    self._tabArea = tabArea
    local bgPanel = lc.createSprite{_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._frame) - V.FRAME_INNER_RIGHT - V.FRAME_INNER_LEFT, lc.bottom(self._tabArea) - 10)}
    lc.addChildToPos(self._frame, bgPanel, cc.p(lc.cw(self._frame), lc.bottom(self._tabArea) - lc.ch(bgPanel) + 4))
    self._bgPanel = bgPanel
end

function _M:initSelfArea()
    local selfAreaBg = ccui.Scale9Sprite:createWithSpriteFrameName("img_troop_bg_6", V.CRECT_TROOP_BG)
    selfAreaBg:setContentSize(lc.w(self._form) - _M.LEFT_MARGIN - _M.RIGHT_MARGIN - 10, SELF_AREA_HEIGHT)
    lc.addChildToPos(self._form, selfAreaBg, cc.p(lc.w(self._form) - _M.RIGHT_MARGIN - lc.cw(selfAreaBg), lc.bottom(self._tabArea) - lc.h(selfAreaBg) / 2 - 6), 1)
    local bar = lc.createSprite('img_bg_deco_35')
    bar:setColor(cc.c3b(164, 240, 205))
    lc.addChildToPos(selfAreaBg, bar, cc.p(lc.w(bar) / 2 + 1, lc.h(selfAreaBg) / 2))

    local selfArea = ccui.Widget:create()
    selfArea._bar = bar
    selfArea:setAnchorPoint(0.5, 0.5)
    selfArea:setContentSize(selfAreaBg:getContentSize())
    lc.addChildToCenter(selfAreaBg, selfArea)
    self._selfArea = selfArea
    selfArea:setVisible(false)
    --[[
    local rankValueBg = lc.createSprite("img_glow")
    rankValueBg:setScale(0.5)
    lc.addChildToPos(selfArea, rankValueBg, cc.p(22 + lc.sw(rankValueBg) / 2, lc.h(selfArea) / 2))
    ]]
    local rankValue = V.createTTFStroke("0", V.FontSize.B1)
    lc.addChildToPos(selfArea, rankValue, cc.p(lc.x(bar) - 2, lc.y(bar)))
    selfArea._rank = rankValue
end

function _M:initMainList()
    local tabArea = self._tabArea
    local selfArea = self._selfArea

    local list = lc.List.createV(cc.size(lc.w(self._bgPanel) - 40, lc.h(self._bgPanel) - lc.h(self._selfArea) - 20), 10, 10)
    list:setAnchorPoint(1, 0.5)
    lc.addChildToPos(self._bgPanel, list, cc.p(lc.w(self._bgPanel) - 20, 10 + lc.ch(list)))

    self._list = list
end

function _M:initTop3Panel()
    local panel = lc.createNode(cc.size(430, lc.h(self._bgPanel) - lc.h(self._selfArea) - 20))
    lc.addChildToPos(self._bgPanel, panel, cc.p(20 + lc.cw(panel), 10 + lc.ch(panel)))
    local rankScale = 0.88
    local bottomMargin = 28 
    local ranks = {}
    for i = 1, 3 do
        ranks[i] = lc.createSprite("res/jpg/rank"..i..".png")
        ranks[i]:setScale(rankScale)
        ranks[i]._name = V.createTTFStroke("", V.FontSize.S2)
        lc.addChildToPos(ranks[i], ranks[i]._name, cc.p(lc.cw(ranks[i]), bottomMargin + lc.ch(ranks[i]._name)))
        ranks[i]._rankNum = lc.createSprite("img_medal_"..i)
        if i == 1 then
            ranks[i]._rankNum:setScale(1.4)
            lc.addChildToPos(ranks[i], ranks[i]._rankNum, cc.p(lc.cw(ranks[i]), lc.h(ranks[i]) - 34 - 25))
        else
            lc.addChildToPos(ranks[i], ranks[i]._rankNum, cc.p(lc.cw(ranks[i]), lc.h(ranks[i]) - 24 - 18 - 25))
        end
        local touchArea = ccui.Widget:create()
        touchArea:setTouchEnabled(true)
        touchArea:setContentSize(cc.size(lc.w(ranks[i]), lc.h(ranks[i])))
        lc.addChildToCenter(ranks[i], touchArea, 3)
        ranks[i]._touchArea = touchArea
    end

    lc.addChildToPos(panel, ranks[2], cc.p(lc.cw(panel) + 31, lc.ch(panel)))
    lc.addChildToPos(panel, ranks[1], cc.p(lc.left(ranks[2]) - lc.cw(ranks[1]) + 16, lc.y(ranks[2])))
    lc.addChildToPos(panel, ranks[3], cc.p(lc.right(ranks[2]) + lc.cw(ranks[3]) - 6, lc.y(ranks[2])))
    
    panel._ranks = ranks
    self._top3Panel = panel
end

function _M:refreshRank()
    local range = self._range

    local type = (self._isPre and SglMsgType_pb.PB_TYPE_RANK_PRE or SglMsgType_pb.PB_TYPE_RANK_LADDER)

    -- refresh left area
    local tabs
    if range == Data.RankRange.lord then
        local characterTabs = {
            {_str = Str(Data._characterInfo[2]._nameSid), _subIndex = 12, _isSub = true, _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_CHAR_LEVEL, _subType = 2}},
            {_str = Str(Data._characterInfo[3]._nameSid), _subIndex = 13, _isSub = true, _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_CHAR_LEVEL, _subType = 3}},
            {_str = Str(Data._characterInfo[4]._nameSid), _subIndex = 14, _isSub = true, _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_CHAR_LEVEL, _subType = 4}},
        }

        local pvpTabs = {
            {_str = Str(STR.TROPHY_RANK_ZONE), _subIndex = 22, _isSub = true, _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_LADDER, _subType = 0}},
            {_str = Str(STR.TROPHY_RANK_REGION), _subIndex = 21, _isSub = true, _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_TROPHY}},
        }

        if ClientData.isAppStoreReviewing() then
            tabs = {
                --{_str = Str(STR.LORD_LEVEL), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_LEVEL}},
                {_str = Str(STR.FIND_CLASH_TITLE), _tabs = pvpTabs},
                --{_str = Str(STR.HIGHEST_FIGHT_VALUE), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_POWER}},
                --{_str = Str(STR.WORLD_STARS), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_STAR}},
                --{_str = Str(STR.FIND_TROPHY_TITLE), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_TROPHY}},
                {_str = Str(STR.UNION_RANK), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY}},
            }
            self._unionIndex = 2
        else
            tabs = {
                --{_str = Str(STR.LORD_LEVEL), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_LEVEL}},
                {_str = Str(STR.FIND_CLASH_TITLE), _tabs = pvpTabs},
                --{_str = Str(STR.FIND_ARENA_TITLE), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_LADDER_EX}},
                {_str = Str(STR.CHARACTER_LEVEL), _tabs = characterTabs},
                --{_str = Str(STR.HIGHEST_FIGHT_VALUE), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_POWER}},
                --{_str = Str(STR.WORLD_STARS), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_STAR}},
                --{_str = Str(STR.FIND_TROPHY_TITLE), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_TROPHY}},
                {_str = Str(STR.UNION_RANK), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY}},
            }
            self._unionIndex = 3
        end
    elseif range == Data.RankRange.union then
        tabs = {
            {_str = Str(STR.UNION)..Str(STR.LEVEL), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_UNION_LEVEL}},
        }
    elseif range == Data.RankRange.dark then
        tabs = {
            {_str = Str(STR.DARK_BATTLE), _userData = {_type = SglMsgType_pb.PB_TYPE_RANK_DARK}},
        }
    else
        local type = (self._isPre and SglMsgType_pb.PB_TYPE_RANK_PRE or SglMsgType_pb.PB_TYPE_RANK_LADDER)
        local clashTabs, gInfo = {}, Data._globalInfo._ladderStage
        for i = 1, #gInfo - 1 do
            local title = string.format("%d%s-%d%s", gInfo[i], Str(STR.LEVEL_S), gInfo[i + 1] - 1, Str(STR.LEVEL_S))
            table.insert(clashTabs, {_str = title, _subIndex = CLASH_BASE + i, _isSub = true, _userData = {_type = type, _subType = i}})
        end
        
        table.insert(clashTabs, {_str = string.format(Str(STR.LEVEL_ABOVE), lc.arrayAt(gInfo, -1)), _subIndex = CLASH_BASE + #gInfo, _isSub = true, _userData = {_type = type, _subType = #gInfo}})
        table.insert(clashTabs, {_str = Str(STR.TOTAL_RANK), _subIndex = CLASH_BASE, _isSub = true, _userData = {_type = type, _subType = 0}})

        tabs = {
            {_str = Str(STR.FIND_CLASH_TITLE), _tabs = clashTabs}
        }
    end

    --[[
    local isUnionUnlock = (P._level >= P._playerCity:getUnionUnlockLevel())
    if isUnionUnlock then
        if range ~= Data.RankRange.region then        
            local unionChallengeTabs = {}
            table.sort(unionChallengeTabs, function(a, b) return a._userData._subType > b._userData._subType end)

            table.insert(tabs, {_str = Str(STR.UNION_CHALLENGE), _tabs = unionChallengeTabs})
        end
    end
    ]]

    self._tabArea:resetTabs(tabs)
end

function _M:onEnter()
    _M.super.onEnter(self)

    local listeners = {}
    table.insert(listeners, lc.addEventListener(Data.Event.rank_list_dirty, function(event)
        if event._type == self._list._rankType then
            self:refreshItemList()
        end
    end))

    table.insert(listeners, lc.addEventListener(Data.Event.union_enter_dirty, function(event)
        if self._list._rankType == SglMsgType_pb.PB_TYPE_RANK_UNION_LEVEL then
            self:refreshCurrentTab()
        end
    end))

    table.insert(listeners, lc.addEventListener(Data.Event.union_exit_dirty, function(event)
        if self._list._rankType == SglMsgType_pb.PB_TYPE_RANK_UNION_LEVEL then
            self:refreshCurrentTab()
        end
    end))

    self._listeners = listeners
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

function _M:onShowActionFinished()
    self._isShown = true

    self._tabArea:showTab(self._initTabIndex)
    self._tabArea._list:getItem(0)._tabArea:showTab(self._initTabIndex)
    --[[
    if self._initSubTab then
        self._tabArea:showTab(self._initSubTab)
    end]]
end

function _M:showSubTab(tab)
    local list = self._list
    list:bindData()
    self._selfArea:setVisible(false)

    self:refreshSelfArea()

    local rankType = tab._userData._type or tab._tabArea._focusedTab._userArea._type
    list._rankType, list._rankSubType = rankType, tab._userData._subType

    local showUnlockTip = function(tipStr)
        local selfArea = self._selfArea
        selfArea:removeChildrenByTag(TAG_CUSTOM_ITEM)
        selfArea:setVisible(true)

        self:addSelfRankAreas()
            
        selfArea._rank:setString("?")

        local tip = V.createBoldRichTextMultiLine(tipStr, V.RICHTEXT_PARAM_LIGHT_S1, 600)
        local tipNode = lc.createNode(tip:getContentSize())
        lc.addChildToCenter(tipNode, tip)

        list:checkEmpty(tipNode)
        list:refreshView()
        list:jumpToTop()
    end

    if rankType == SglMsgType_pb.PB_TYPE_RANK_TROPHY then
        if not P:checkFindClash() then
            showUnlockTip(string.format(Str(STR.UNLOCK_RANK_CLASH_TROPHY_TIP, true), Str(Data._chapterInfo[1]._nameSid)))
            return
        end
    elseif rankType == SglMsgType_pb.PB_TYPE_RANK_LADDER then
        if not P:checkFindClash() then
            showUnlockTip(string.format(Str(STR.UNLOCK_RANK_TROPHY_TIP1), Str(Data._chapterInfo[1]._nameSid), RANK_TROPHY_VISIBLE_LEVEL))
            return
        end
        if not P:checkCrossFindClash() then
            showUnlockTip(string.format(Str(STR.UNLOCK_RANK_TROPHY_TIP2), RANK_TROPHY_VISIBLE_LEVEL))
            return
        end
    elseif rankType == SglMsgType_pb.PB_TYPE_RANK_LADDER_EX then
        if P:getMaxCharacterLevel() < Data._globalInfo._unlockLadder then
            showUnlockTip(string.format(Str(STR.UNLOCK_RANK_LADDER_EX_TIP, true), Data._globalInfo._unlockLadder))
            return
        end
        
    end

    if self._indicator then
        self._indicator:removeFromParent()
        self._indicator = nil
    end

    if P._playerRank:sendRankRequest(rankType, list._rankSubType) then
        self._indicator = V.showPanelActiveIndicator(self._form, lc.bound(self._list))
        lc.offset(self._indicator, 0, 20)
    end
end

function _M:refreshCurrentTab()
    local focusedIndex = self._tabArea._focusedTab._index
    self:refreshRank()
    if focusedIndex then
        self._tabArea:showTab(focusedIndex)
    end
end

function _M:refreshSelfArea()
    local selfArea = self._selfArea
    local avatar = selfArea._avatar
    if avatar then
        avatar:removeFromParent()
    end

    --if range == Data.RankRange.lord or range == Data.RankRange.region then
    --local index = self._tabArea._focusedTab and self._tabArea._focusedTab._index or self._tabArea._tabArea._focusedTab._index
    selfArea._bar:setColor(cc.c3b(164, 240, 205))
    if self._tabArea._focusedTab._index ~= self._unionIndex then
        avatar = UserWidget.create(P, UserWidget.Flag.NAME_UNION)
        avatar:setScale(0.8)
        lc.addChildToPos(selfArea, avatar, cc.p(175 + lc.w(avatar) / 2 - 6, lc.h(selfArea) / 2))
    else
        if P:hasUnion() then
            avatar = require("UnionWidget").create(P._playerUnion:getMyUnion(), false)
            avatar:setScale(0.62)
            lc.addChildToPos(selfArea, avatar, cc.p(100 + lc.w(avatar) / 2 - 6, lc.h(selfArea) / 2))
        else
            avatar = V.createTTF(Str(STR.NOT_JOIN_ANY_UNION), V.FontSize.S1, V.COLOR_TEXT_ORANGE)
            lc.addChildToPos(selfArea, avatar, cc.p(100 + lc.w(avatar) / 2 - 6, lc.h(selfArea) / 2))
            lc.offset(avatar, 120)
        end
        
    end
    
    selfArea._avatar = avatar
end

function _M:refreshItemList()
    if self._indicator then
        self._indicator:removeFromParent()
        self._indicator = nil
    end

    self:refreshSelfArea()

    local list = self._list
    
    local ranks = P._playerRank:getRanks(list._rankType, list._rankSubType)

    if ranks == nil then return end

    -- Update self data
    local selfArea = self._selfArea
    selfArea:removeChildrenByTag(TAG_CUSTOM_ITEM)
    selfArea:setVisible(true)

    self:addSelfRankAreas()

    -- Create items
    list:bindData(ranks, function(item, rank) self:setOrCreateItem(item, rank, list._rankType) end, math.min(10, ranks._count or 0))
    if self._tabArea._focusedTab._index ~= self._unionIndex then
        self._top3Panel:setVisible(true)
        local w = lc.w(self._bgPanel) - lc.w(self._top3Panel) - 40 + 170
        local scale = (lc.w(self._bgPanel) - lc.w(self._top3Panel) - 40) / w
        self._list:setContentSize(cc.size(w, (lc.h(self._bgPanel) - lc.h(self._selfArea) - 20) / scale))
        self._list:setScale(scale)
        for i = 1, 3 do
            local nameItem = self._top3Panel._ranks[i]._name
            if ranks[i]._user ~= nil then
                nameItem:setString(ranks[i]._user._name)        
                nameItem:setScale(math.min(1, 113 / lc.w(nameItem)))
                self._top3Panel._ranks[i]._touchArea:addTouchEventListener(function(sender, type)
                    if type == ccui.TouchEventType.ended then
                        if ranks[i] then
                            --if range == Data.RankRange.region then
                            if list._rankType ~= SglMsgType_pb.PB_TYPE_RANK_LADDER and list._rankType ~= SglMsgType_pb.PB_TYPE_RANK_LADDER_EX then
                                V.operateUser(ranks[i]._user, self._top3Panel._ranks[i]._touchArea)
                            else
                                if ranks[i]._user._id ~= self._list._data._rankId then
                                    require("ClashUserInfoForm").create(ranks[i]._user._id):show()
                                end
                            end
                        end
                    end
                end)
            else
                nameItem:setString("")  
            end
            
            local cNode = lc.createNode(cc.size(lc.w(self._top3Panel._ranks[i]) - 14, lc.h(self._top3Panel._ranks[i]) - 14))
            local clipNode = V.createClipNode(cNode, cc.rect( 0, 5, (lc.w(self._top3Panel._ranks[i]) - 15), lc.h(self._top3Panel._ranks[i]) - 24), false)
            local characterImg
            if ranks[i]._user ~= nil then
                characterImg = lc.createSprite((ranks[i]._user._avatarImage and ranks[i]._user._avatarImage > 100) and string.format("res/jpg/avatar_image_%04d.jpg", ranks[i]._user._avatarImage) or "res/jpg/avatar_image_0201.jpg")
            else
                characterImg = lc.createSprite("res/jpg/avatar_image_0201.jpg")
            end
            characterImg:setScale(lc.h(clipNode) / lc.h(characterImg))
            lc.addChildToCenter(clipNode, characterImg)
            lc.addChildToCenter(self._top3Panel._ranks[i], clipNode, -1)
        end
        for i = 1, list._cacheCount do
            local rank = ranks[i]
            local item = self:setOrCreateItem(nil, rank, list._rankType)
            list:pushBackCustomItem(item)
        end
    else
        self._top3Panel:setVisible(false)
        local w = lc.w(self._bgPanel) - 40
        self._list:setContentSize(cc.size(w, lc.h(self._list)))
        self._list:setScale(1)
        self._list:setContentSize(cc.size(lc.w(self._bgPanel) - 40, lc.h(self._bgPanel) - lc.h(self._selfArea) - 20))
        for i = 1, list._cacheCount do
            local rank = ranks[i]
            local item = self:setOrCreateItem(nil, rank, list._rankType)
            list:pushBackCustomItem(item)
        end
    end
    
    if list._rankType == SglMsgType_pb.PB_TYPE_RANK_UNION_LEVEL then
        list:checkEmpty(Str(STR.LIST_EMPTY_UNION))

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_UBOSS_SCORE then
        list:checkEmpty(Str(STR.LIST_EMPTY_BOSS))

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_UBOSS_TIME then
        list:checkEmpty(Str(STR.LIST_EMPTY_BOSS_UNION))

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_LADDER or list._rankType == SglMsgType_pb.PB_TYPE_RANK_LADDER_EX or list._rankType == SglMsgType_pb.PB_TYPE_RANK_PRE or list._rankType == SglMsgType_pb.PB_TYPE_RANK_TROPHY then
        list:checkEmpty(Str(STR.LIST_EMPTY_RANK))

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_DARK then
        list:checkEmpty(Str(STR.LIST_EMPTY_RANK))

    end

    list:refreshView()
    list:jumpToTop()
end

function _M:setOrCreateItem(item, rank, type)
    local range = self._range
    if item == nil then
        item = lc.createImageView{_name = "img_troop_bg_6", _crect = V.CRECT_TROOP_BG}
        item:setContentSize(lc.w(self._list), (range == Data.RankRange.lord and range == Data.RankRange.region) and 110  or 110)
        --item:setScale(lc.w(self._list) / lc.w(item))
        item:setTouchEnabled(true)
        item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

        local bar = lc.createSprite('img_bg_deco_35')
        bar:setColor(cc.c3b(164, 240, 205))
        lc.addChildToPos(item, bar, cc.p(lc.w(bar) / 2 + 1, lc.h(item) / 2))
        item._bar = bar
        
        local valueArea
        if self._tabArea._focusedTab._index ~= self._unionIndex then
        --if range == Data.RankRange.lord or range == Data.RankRange.region then
            item:addTouchEventListener(function(sender, type)
                if type == ccui.TouchEventType.ended then
                    if item._rank then
                        --if range == Data.RankRange.region then
                        if item._rankType ~= SglMsgType_pb.PB_TYPE_RANK_LADDER and item._rankType ~= SglMsgType_pb.PB_TYPE_RANK_LADDER_EX then
                            V.operateUser(item._rank._user, item)
                        else
                            if item._rank._user._id ~= self._list._data._rankId then
                                require("ClashUserInfoForm").create(item._rank._user._id):show()
                            end
                        end
                    end
                end
            end)

            local userArea = UserWidget.create(rank._user, UserWidget.Flag.NAME_UNION)
            item._userArea = userArea
            userArea:setScale(0.8)
            --userArea._level:setVisible(true)
            lc.addChildToPos(item, userArea, cc.p(134 + lc.w(userArea) / 2 + 10, lc.h(item) / 2 + 4))
            item._avatarArea = userArea
            if type == SglMsgType_pb.PB_TYPE_RANK_POWER then
                valueArea = self:addValueArea(item, "img_icon_power", rank._value)

            elseif type == SglMsgType_pb.PB_TYPE_RANK_STAR then
                valueArea = self:addValueArea(item, "world_city_star_focus3", rank._value)

            elseif type == SglMsgType_pb.PB_TYPE_RANK_TROPHY then
                valueArea = self:addValueArea(item, "img_icon_res6_s", rank._value)

            elseif type == SglMsgType_pb.PB_TYPE_RANK_BOSS or type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_SCORE then
                valueArea = self:addValueArea(item, "img_icon_score", rank._value, 160)

            elseif type == SglMsgType_pb.PB_TYPE_RANK_LADDER or type == SglMsgType_pb.PB_TYPE_RANK_PRE then
                valueArea = self:addValueArea(item, "img_icon_res6_s", rank._value)

            elseif type == SglMsgType_pb.PB_TYPE_RANK_LADDER_EX then
                valueArea = self:addValueArea(item, "img_icon_res5_s", rank._value)
                
            elseif type == SglMsgType_pb.PB_TYPE_RANK_DARK then
                valueArea = self:addValueArea(item, "img_icon_res16_s", rank._value)
                
            end
        else
            item:addTouchEventListener(function(sender, evt)
                if evt == ccui.TouchEventType.ended then
                    local rankUnion = item._rank._union
                    if P:hasUnion() then
                        if rankUnion._id ~= P._unionId then
                            require("UnionDetailForm").create(rankUnion._id):show()
                        end
                    else
                        V.operateUnion(rankUnion, item)
                    end
                end
            end)

            local unionArea = require("UnionWidget").create(nil, true)
            unionArea:setScale(0.62)
            lc.addChildToPos(item, unionArea, cc.p(100 + lc.w(unionArea) / 2, lc.h(item) / 2))
            item._avatarArea = unionArea

            if type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_TIME then
                valueArea = self:addUBossKillValueArea(item)
            elseif type == SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY then
                valueArea = self:addValueArea(item, "img_icon_res6_s", rank._value)
            end
        end

        if valueArea then
            valueArea:setPosition(lc.w(item) - 20 - lc.w(valueArea) / 2, lc.y(item._avatarArea))
            item._valueArea = valueArea
            if type == SglMsgType_pb.PB_TYPE_RANK_LADDER or type == SglMsgType_pb.PB_TYPE_RANK_LADDER_EX or type == SglMsgType_pb.PB_TYPE_RANK_PRE  or type == SglMsgType_pb.PB_TYPE_RANK_TROPHY then
                lc.offset(valueArea, 0, -20)

                local region = V.createTTF("", 18)
                lc.addChildToPos(item, region, cc.p(lc.x(valueArea), lc.y(item._userArea._nameArea) - 2 --[[or lc.ch(item)]]))
                valueArea._region = region
            end
        end
    end
    
    item:removeChildrenByTag(TAG_CUSTOM_ITEM)
    item._rank = rank
    item._rankType = type

    local rankNum = rank._rank
    if rankNum <= 3 then
        local medal = lc.createSprite(string.format("img_medal_%d", rankNum))
        medal:setPosition(lc.w(medal) / 2 + 20, lc.h(item) / 2 + 5)
        item:addChild(medal, 0, TAG_CUSTOM_ITEM)
        item._bar:setColor(rankNum == 1 and cc.c3b(250, 64, 0) or (rankNum == 2 and cc.c3b(0, 144, 250) or cc.c3b(166, 128, 136)))
    else
        local number = V.createTTFStroke(string.format("%d", rankNum), V.FontSize.B1)        
        number:setPosition(70, lc.h(item) / 2 + 2)
        item:addChild(number, 0, TAG_CUSTOM_ITEM)
        item._bar:setColor(cc.c3b(164, 240, 205))
    end

    --if range == Data.RankRange.lord or range == Data.RankRange.region then
    if self._tabArea._focusedTab._index ~= self._unionIndex then
        local selfRankId = self._list._data._rankId
        if rank._id == selfRankId then
            item:setColor(V.COLOR_TEXT_GREEN)
        else
            item:setColor(lc.Color3B.white)
        end

        item._avatarArea:setUser(rank._user, true)
    else
        if rank._id == P._unionId then 
            item:setColor(V.COLOR_TEXT_GREEN)
        else
            item:setColor(lc.Color3B.white)
        end

        item._avatarArea:setUnion(rank._union)
    end
    
    local valArea = item._valueArea
    if valArea then
        if type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_TIME then
            valArea:updateTime(rank._value)
        elseif type == SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY then
            valArea._label:setString(string.format("%d", rank._value))
        else 
            if type == SglMsgType_pb.PB_TYPE_RANK_LADDER or type == SglMsgType_pb.PB_TYPE_RANK_LADDER_EX or type == SglMsgType_pb.PB_TYPE_RANK_PRE then
                valArea._region:setString(ClientData.genChannelRegionName(rank._user._regionId))
            end

            valArea._label:setString(string.format("%d", rank._value))
        end
    end

    return item
end

function _M:addValueArea(parent, iconName, val, width)
    local area = V.createIconLabelArea(iconName, tostring(val), width or 110)
    area:setAnchorPoint(0.5, 0.5)
    parent:addChild(area)
    return area
end

function _M:addUBossKillValueArea(parent)
    local area = lc.createNode(cc.size(140, 80))
    parent:addChild(area)

    local label = V.createTTF(Str(STR.KILL_DURATION), V.FontSize.S2, V.COLOR_LABEL_DARK)
    label:setAnchorPoint(1, 0.5)
    lc.addChildToPos(area, label, cc.p(lc.w(area) - 2, lc.h(area) - 10 - lc.h(label) / 2))

    local time = V.createTTF("0", V.FontSize.S1, V.COLOR_TEXT_RED_DARK)
    time:setAnchorPoint(1, 0.5)
    lc.addChildToPos(area, time, cc.p(lc.x(label), 10 + lc.h(time) / 2))

    area.updateTime = function(area, t)
        if t > 0 then
            t = t / 1000
            local day, str = math.floor(t / Data.DAY_SECONDS)

            t = t % Data.DAY_SECONDS
            local hour = math.floor(t / 3600)
            local minute = math.floor(t % 3600 / 60)
            local second = math.floor(t % 3600 % 60)

            if day > 0 then
                str = string.format("%d%s %02d:%02d:%02d", day, Str(STR.DAY), hour, minute, second)
            else
                str = string.format("%02d:%02d:%02d", hour, minute, second)
            end

            time:setString(str)

        else
            time:setString(Str(STR.VOID))
        end
    end

    return area
end

function _M:addSelfRankAreas()
    -- Update self data
    local selfArea, list = self._selfArea, self._list

    local ranks = P._playerRank:getRanks(list._rankType, list._rankSubType)
    local selfRank = ranks and ranks._selfRank

    selfArea._rank:setString(selfRank and tostring(selfRank._rank) or "?")
    if selfRank ~= nil then
        selfArea._bar:setColor(selfRank._rank == 1 and cc.c3b(255, 77, 59) or (selfRank._rank == 2 and cc.c3b(149, 223, 246) or cc.c3b(251, 203, 126)))
        if selfRank._rank <= 3 then
            selfArea._rank:setScale(1.2)
        else
            selfArea._rank:setScale(1)
        end
    end
    
    local addOneValueArea = function(iconName, width)
        if selfArea._avatar and selfArea._avatar._nameArea then
            local pos = lc.convertPos(cc.p(0, lc.h(selfArea._avatar._nameArea) / 2), selfArea._avatar._nameArea, selfArea)

            local starArea = self:addValueArea(selfArea, iconName, selfRank and selfRank._value or 0, width)
            starArea:setTag(TAG_CUSTOM_ITEM)
            starArea:setPosition(lc.w(selfArea) - 24 - lc.w(starArea) / 2, pos.y)
        end
    end

    local addOneValueAreaWithRule = function(iconName, rank, width)
        local area = self:addValueArea(selfArea, iconName, selfRank and selfRank._value or 0, width)
        area:setTag(TAG_CUSTOM_ITEM)
        area:setPosition(lc.w(selfArea) - 24 - lc.w(area) / 2, lc.h(selfArea) / 2)

        local btnBonus = V.createShaderButton("img_btn_bonus", function()
            if list._rankType == SglMsgType_pb.PB_TYPE_RANK_LADDER or list._rankType == SglMsgType_pb.PB_TYPE_RANK_LADDER_EX or list._rankType == SglMsgType_pb.PB_TYPE_RANK_PRE then
                require("RankBonusForm").createClash(list._rankType, 0):show()
            else
                require("RankBonusForm").create(rank, list._rankType):show()
            end
        end)
        btnBonus:setDisabledShader(V.SHADER_DISABLE)
        --btnBonus:setEnabled(false)
        lc.addChildToPos(selfArea, btnBonus, cc.p(lc.x(area) - 172, lc.y(area)), 0, TAG_CUSTOM_ITEM)
    end

    if list._rankType == SglMsgType_pb.PB_TYPE_RANK_POWER then
        addOneValueArea("img_icon_power")

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_STAR then
        addOneValueArea("world_city_star_focus3")

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_TROPHY then
        local rank
        if P:getMaxCharacterLevel() >= RANK_TROPHY_VISIBLE_LEVEL and selfRank then
            rank = selfRank._rank
        end

        addOneValueAreaWithRule("img_icon_res6_s", rank)

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_LADDER or list._rankType == SglMsgType_pb.PB_TYPE_RANK_PRE then
        addOneValueAreaWithRule("img_icon_res6_s", rank)

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_LADDER_EX then
        addOneValueAreaWithRule("img_icon_res5_s", rank)

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_DARK then
        addOneValueAreaWithRule("img_icon_res16_s", rank)

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_BOSS or list._rankType == SglMsgType_pb.PB_TYPE_RANK_UBOSS_SCORE then
        addOneValueArea("img_icon_score", 160)

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_UBOSS_TIME then
        local area = self:addUBossKillValueArea(selfArea)
        area:setTag(TAG_CUSTOM_ITEM)
        area:setPosition(lc.w(selfArea) - 34 - lc.w(area) / 2, lc.h(selfArea) / 2)
        area:updateTime(selfRank and selfRank._value or 0)

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_CHAR_LEVEL then
        selfArea._avatar._nameArea._level:setVisible(true)
        --selfArea._avatar._nameArea._level:setString(selfRank and selfRank._value or 0)

    elseif list._rankType == SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY then
        addOneValueAreaWithRule("img_icon_res6_s", 160)

    end
end

return _M