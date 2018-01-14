local _M = class("FindTrophyArea", lc.ExtendCCNode)

local CONTENT_WIDTH = 960

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
    self:initTopArea()    
    self:initBottomArea()

    self._opponentArea = {}
    self:findMatch()
end

function _M:initTopArea()
    local bg = lc.createSprite{_name = "img_com_bg_4", _crect = V.CRECT_COM_BG4, _size = cc.size(math.min(lc.w(self), CONTENT_WIDTH), 110)}
    lc.addChildToPos(self, bg, cc.p(lc.w(self) / 2, lc.h(self) - 40), 1)
    self._topArea = bg

    -- init search area
    local btnSearch = V.createScale9ShaderButton("img_btn_1", function() self:findMatch() end, V.CRECT_BUTTON, 150)
    btnSearch:addLabel(Str(STR.SEARCH))
    btnSearch:addIcon("img_icon_search")
    lc.addChildToPos(bg, btnSearch, cc.p(lc.w(bg) - 22 - lc.w(btnSearch) / 2, 56))
    self._btnSearch = btnSearch

    -- init unlock area
    local unlockArea = V.createResConsumeButtonArea({140, 150}, "img_icon_lock", lc.Color3B.black, "", Str(STR.COPY_PVP_UNLOCK), "img_btn_2")
    unlockArea._resArea._ico:setScale(0.6)
    lc.addChildToPos(bg, unlockArea, cc.p(lc.w(bg) - 22 - lc.w(unlockArea) / 2, lc.y(btnSearch)))
    self._unlockArea = unlockArea    
    unlockArea._btn._callback = function()
        local ingotNeed = lc.arrayAt(Data._globalInfo._buyRefreshFindCost, P._unlockCopyPvpTimes + 1)
        require("Dialog").showDialog(string.format(Str(STR.CONFIRM_UNLOCK_COPY_PVP), ingotNeed), function()
            if V.checkIngot(ingotNeed) then
                self:unlockFind()
            end
        end)
    end

    self:checkUnlockState()

    -- init rank
    local glow = lc.createSprite("img_glow")
    glow:setScale(0.65, 0.5)
    lc.addChildToPos(bg, glow, cc.p(80, lc.y(btnSearch)))

    local gx, gy = glow:getPosition()
    local rankLabel = V.createTTF(Str(STR.BATTLE_CUR_RANK), V.FontSize.S3, V.COLOR_LABEL_DARK)
    lc.addChildToPos(bg, rankLabel, cc.p(gx, gy + 24))

    local rank = V.createBMFont(V.BMFont.num_48, "?")
    lc.addChildToPos(bg, rank, cc.p(gx, gy - 6))
    self._rank = rank

    self:updateRemainTimes()
end

function _M:initOpponentArea(pbData)
    local createArea = function()
        local area = lc.createSprite{_name = "img_com_bg_16", _crect = V.CRECT_COM_BG16, _size = cc.size(lc.w(self._topArea), 260)}

        local UserWidget = require("UserWidget")
        local userArea = UserWidget.create(nil, UserWidget.Flag.NAME_UNION, 0.5)
        userArea:setAnchorPoint(0, 1)
        userArea._nameArea:setAnchorPoint(0, 0.5)
        userArea._nameArea:setPosition(0, lc.y(userArea._frame))
        userArea._unionArea:setAnchorPoint(0, 0.5)
        userArea._unionArea._name:setVisible(false)
        userArea._unionArea:setPosition(math.floor(lc.right(userArea._frame) + 10), lc.y(userArea._frame))
        lc.addChildToPos(area, userArea, cc.p(34, lc.h(area) - 30))
        area._userArea = userArea

        local glow = lc.createSprite("img_glow")
        glow:setScale(0.6, 0.4)
        glow:setOpacity(150)
        lc.addChildToPos(area, glow, cc.p(lc.w(area) - 100, lc.h(area) - 54))

        local rank = V.createBMFont(V.BMFont.num_48, tostring(200))
        rank:setScale(0.8)
        lc.addChildToPos(area, rank, cc.p(glow:getPosition()))
        area._rank = rank

        local list = lc.List.createH(cc.size(lc.w(area) - 18, 100), 16, -6)
        lc.addChildToPos(area, list, cc.p(8, lc.bottom(userArea) - lc.h(list) - 4))
        area._list = list

        local btnAttack = V.createScale9ShaderButton("img_btn_1", function() self:attack(area) end, V.CRECT_BUTTON, 150)
        btnAttack:addLabel(Str(STR.COPY_PVP))
        btnAttack:addIcon("img_icon_battle")
        lc.addChildToPos(area, btnAttack, cc.p(lc.w(area) - lc.w(btnAttack) / 2 - 30, 50))

        area._fightVal = V.addIconValue(area, "img_icon_power", 0, 50, lc.y(btnAttack), nil, V.COLOR_TEXT_DARK)
        area._cardNum = V.addIconValue(area, "img_icon_cardnum", 0, 200, lc.y(btnAttack), nil, V.COLOR_TEXT_DARK)
        area._trophyNum = V.addIconValue(area, "img_icon_res5_s", 0, 350, lc.y(btnAttack), nil, V.COLOR_TEXT_DARK)

        area.update = function(area, pbTroopData, rank)
            local user = require("User").create(pbTroopData.info)
            area._user = user

            -- update user
            userArea:setUser(user)

            local hasUnion = user._unionId and user._unionId > 0
            userArea._nameArea:setPositionX(hasUnion and 110 or 72)

            if userArea._vip then
                userArea._vip:setVisible(false)
            end

            -- update troop
            local cards, fightValue = ClientData.pbTroopToTroop(pbTroopData.cards), 0
            for _, card in ipairs(cards) do
                fightValue = fightValue + card:getFightingValue()
            end

            list:bindData(cards, function(item, card) item:resetData(card) end, math.min(#cards, 13))

            for i = 1, list._cacheCount do
                local icon = IconWidget.create(cards[i], IconWidget.DisplayFlag.CARD_TROOP)
                icon:setScale(0.8)
                list:pushBackCustomItem(icon)
            end

            -- update values
            area._fightVal:setString(fightValue)
            area._cardNum:setString(#cards)
            area._trophyNum:setString(user._trophy)

            area._rankVal = rank
            area._rank:setString(rank)
        end

        return area
    end
    
    local area1, area2 = createArea(), createArea()
    area1:setVisible(false)
    area2:setVisible(false)
    self._opponentArea = {area1, area2}

    lc.addChildToPos(self, area1, cc.p(lc.w(self) / 2, lc.bottom(self._topArea) - lc.h(area1) / 2 + 8))
    lc.addChildToPos(self, area2, cc.p(lc.w(self) / 2, lc.bottom(area1) - lc.h(area2) / 2 + 4))

    local oppoCount = #pbData.opponents
    if oppoCount == 0 then
        
        
    else
        if oppoCount >= 1 then
            area1:update(pbData.opponents[1], pbData.opponent_ranks[1])
            area1:setVisible(true)
        end

        if oppoCount == 2 then
            area2:update(pbData.opponents[2], pbData.opponent_ranks[2])
            area2:setVisible(true)
        end
    end
end

function _M:initBottomArea()
    local area = lc.createNode(cc.size(lc.w(self), 80))
    lc.addChildToPos(self, area, cc.p(lc.w(self) / 2, lc.h(area) / 2))
    self._bottomArea = area

    local bottomBg = lc.createSprite("img_com_bg_8")
    bottomBg:setScaleX(lc.w(area) / lc.w(bottomBg) + 0.1)
    bottomBg:setScaleY(lc.h(area) / lc.h(bottomBg))
    lc.addChildToPos(area, bottomBg, cc.p(lc.w(area) / 2, lc.h(area) / 2))

    local bottomLine = V.createLineSprite("img_divide_line_4", lc.w(area) + 20)
    bottomLine:setRotation(180)
    lc.addChildToPos(area, bottomLine, cc.p(lc.w(area) / 2, 4))

    local topLine = V.createLineSprite("img_divide_line_1", lc.w(area) + 20)
    lc.addChildToPos(area, topLine, cc.p(lc.w(area) / 2, lc.h(area)))

    -- Add buttons
    local btnRank = V.createScale9ShaderButton("img_btn_1", function() require("RankForm").create(Data.RankRange.lord, 4):show() end, V.CRECT_BUTTON, 140)
    btnRank:addLabel(Str(STR.RANK))
    btnRank:addIcon("img_icon_res5_s")
    lc.addChildToPos(area, btnRank, cc.p(6 + lc.w(btnRank) / 2, 42))

    local btnLog = V.createScale9ShaderButton("img_btn_1", function() require("LogForm").create(Battle_pb.PB_BATTLE_PLAYER):show() end, V.CRECT_BUTTON, 140)
    btnLog:addLabel(Str(STR.LOG))    
    lc.addChildToPos(area, btnLog, cc.p(lc.w(area) - 6 - lc.w(btnLog) / 2, lc.y(btnRank)))
    self._btnLog = btnLog

    local btnTroop = V.createScale9ShaderButton("img_btn_2",
        function()
            self._ignoreSync = true
            lc.pushScene(require("HeroCenterScene").create())
        end,
    V.CRECT_BUTTON, 140)
    btnTroop:addLabel("0")
    lc.addChildToPos(area, btnTroop, cc.p(lc.left(btnLog) - 10 - lc.w(btnTroop) / 2, lc.y(btnRank)))
    self._btnTroop = btnTroop
end

function _M:checkUnlockState()
    local isLock = (P._nextCopyPvp > ClientData.getCurrentTime() and Data._globalInfo._maxAtkPlayer > P._dailyCopyPvpTimes)
    self._btnSearch:setVisible(not isLock)
    self._unlockArea:setVisible(isLock)

    if isLock then
        self._unlockArea:scheduleUpdateWithPriorityLua(function(dt)
            local remainTime = P._nextCopyPvp - ClientData.getCurrentTime()
            if remainTime > 0 then
                self._unlockArea._resLabel:setString(ClientData.formatPeriod(remainTime))
            else
                self:checkUnlockState()
            end
        end, 0)
    else
        self._unlockArea:unscheduleUpdate()
    end
end

function _M:updateRemainTimes()
    local remainTimes = self._remainTimes
    if remainTimes then
        remainTimes:removeFromParent()
    end

    remainTimes = V.createBoldRichText(string.format(Str(STR.FIND_TROPHY_REMAIN), Data._globalInfo._maxAtkPlayer - P._dailyCopyPvpTimes, Data._globalInfo._maxAtkPlayer), V.RICHTEXT_PARAM_DARK_S1)
    lc.addChildToPos(self._topArea, remainTimes, cc.p(280, lc.y(self._btnSearch)))
    self._remainTimes = remainTimes
end

function _M:updateLogFlag()
    local number = P._playerLog:getNewDefenseLogCount()
    V.checkNewFlag(self._btnLog, number)
end

function _M:findMatch()
    if self._indicator then return end

    for _, area in ipairs(self._opponentArea) do
        area:removeFromParent()
    end
    self._opponentArea = {}
        
    self._indicator = V.showPanelActiveIndicator(self)
    ClientData.sendWorldFind()
end

function _M:unlockFind()
    local isLock = (P._nextCopyPvp > ClientData.getCurrentTime())
    if isLock then
        P._nextCopyPvp = ClientData.getCurrentTime()
        self:checkUnlockState()

        P._unlockCopyPvpTimes = P._unlockCopyPvpTimes + 1

        local ingotNeed = lc.arrayAt(Data._globalInfo._buyRefreshFindCost, P._unlockCopyPvpTimes)
        P:changeResource(Data.ResType.ingot, -ingotNeed)

        ClientData.sendCopyPvpUnlock()
    end
end

function _M:attack(area)
    if Data._globalInfo._maxAtkPlayer <= P._dailyCopyPvpTimes then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH_BUY_TIMES), Str(STR.COPY_PVP)))
        return
    end

    local curTime = ClientData.getCurrentTime()
    if curTime < P._nextCopyPvp then
        ToastManager.push(string.format(Str(STR.FIND_TROPHY_COOLDOWN), ClientData.formatPeriod(P._nextCopyPvp - curTime)))
        return
    end

    local isTroopValid, msg = P._playerCard:checkTroop(P._curTroopIndex)
    if not isTroopValid then
        ToastManager.push(msg)
        return
    end

    P._nextCopyPvp = curTime + Data._globalInfo._findCD * 60

    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendWorldFindStart(P._curTroopIndex, area == self._opponentArea[1] and 0 or 1)
end

function _M:onEnter()
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    self._listeners = {}

    self._btnTroop._label:setString(string.format("%s %d", Str(STR.TROOP), P._curTroopIndex))
    self:updateLogFlag()
end

function _M:onExit()
    ClientData.removeMsgListener(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onMsg(msg)
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_WORLD_FIND then
        if self._indicator then
            self._indicator:removeFromParent()
            self._indicator = nil
        end

        local resp = msg.Extensions[World_pb.SglWorldMsg.world_find_resp]
        self:initOpponentArea(resp)

        self._rankVal = resp.rank
        self._rank:setString(resp.rank)

        return true
    end

    return false
end

return _M