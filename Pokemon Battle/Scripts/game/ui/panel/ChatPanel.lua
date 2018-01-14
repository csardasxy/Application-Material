local _M = class("ChatPanel", lc.ExtendUIWidget)

local TAB = {
    world           = Data.MsgType.world,
    bulletin        = Data.MsgType.bulletin,
    battle          = Data.MsgType.battle
}

local PANEL_SIZE = cc.size(624, lc.Director:getVisibleSize().height - 10)

local TAB_WIDTH = 140
local TAB_MARGIN_TOP = 20
local TAB_MARGIN_LEFT = 0

local LIST_CACHE_SIZE = {10, 10, 10, 6}
local TAG_CUSTOM = 100

local WORLD_CHAT_LEVEL = 12

function _M.create()
    local panel = _M.new(lc.EXTEND_WIDGET)
    panel:setAnchorPoint(0, 0)
    panel:setContentSize(PANEL_SIZE)
    panel:init()

    panel._listener = lc.addEventListener(Data.Event.message, function(event)
        panel:onMessageEvent(event)
    end)

    return panel
end

function _M:init()    
    -- Create tabs
    local tabStrs, tabs = { Str(STR.WORLD), Str(STR.BULLETIN), Str(STR.BATTLE) }, {}
    for i, str in ipairs(tabStrs) do
        local tab = {
            _tag = i,
            _left = 62,
            _labelStr = tabStrs[i],
            _width = TAB_WIDTH,
            _handler = function(tag) self:showTab(tag) end,
            _checkHandler = function(newTag, isUserBehavior) return self:checkShowTab(newTag, isUserBehavior) end
        }

        table.insert(tabs, tab)
    end

    local contentBg = V.createHorizontalContentTab(cc.size(PANEL_SIZE.width, PANEL_SIZE.height - 60), tabs)
    lc.addChildToPos(self, contentBg, cc.p(lc.w(self) / 2, lc.h(contentBg) / 2), -1)
    self._contentBg = contentBg

    -- Create message list
    local list = lc.List.createV(cc.size(lc.w(contentBg) - 32, lc.h(contentBg) - 4), 16, 16)
    list:setAnchorPoint(0.5, 0)
    list._originH = lc.h(list)
    lc.addChildToPos(contentBg, list, cc.p(lc.w(contentBg) / 2, 0))
    self._list = list

    -- Create input box
    local btnSend = V.createScale9ShaderButton("img_btn_2_s", function() end, V.CRECT_BUTTON_S, 100)
    btnSend:addLabel(Str(STR.SEND))

    local inputArea = ccui.Layout:create()
    inputArea:setContentSize(cc.size(lc.w(list), lc.h(btnSend)))
    inputArea:setAnchorPoint(0.5, 1)
    lc.addChildToPos(contentBg, inputArea, cc.p(lc.w(contentBg) / 2, lc.h(contentBg) - V.FRAME_INNER_TOP - 16))
    self._inputArea = inputArea

    lc.addChildToPos(inputArea, btnSend, cc.p(lc.w(inputArea) - lc.w(btnSend) / 2, lc.h(inputArea) / 2), 1)
    self._btnSend = btnSend
    
    local input = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), cc.size(lc.w(inputArea) - lc.w(btnSend) - 8, lc.h(btnSend)), Str(STR.INPUT_SHARE_TEXT), true)
    input:setFontColor(lc.Color4B.white)
    lc.addChildToPos(inputArea, input, cc.p(lc.w(input) / 2, lc.y(btnSend)))
    self._iptSend = input

    -- Add pop button
    local btnImage = lc.createSprite("img_btn_pop")
    local btnPop = V.createShaderButton(nil, function(sender)
        if self._isPop then
            self:push()
        else
            self:pop()
        end
    end)
    btnPop:setContentSize(cc.size(lc.w(btnImage), lc.h(btnImage)))
    lc.addChildToCenter(btnPop, btnImage)
    btnPop:setAnchorPoint(0, 0.5)
    lc.addChildToPos(self, btnPop, cc.p(PANEL_SIZE.width + 10, lc.h(self) / 2), -2)
    btnImage:setScaleX(-1)
    self._btnPop = btnPop
    self._btnImage = btnImage
    
    local arrowPop = lc.createSprite("img_icon_chat")
    lc.addChildToPos(btnPop, arrowPop, cc.p(24, lc.h(btnPop) / 2 + 1))
    self._arrowPop = arrowPop
    
    -- Push the panel
    self._isPop = false
    self:setPosition(-PANEL_SIZE.width, 0)
    self._contentBg:setVisible(false)
end

function _M:pop()
    if self._isPop then return end

    self._isPop = true
    
    self._arrowPop:setSpriteFrame("img_btn_pop_arrow")
    self._arrowPop:setPositionX(40)
    self._btnImage:setScaleX(1)
    self._contentBg:setVisible(true)
    self:stopAllActions()
    self:runAction(lc.ease(lc.moveTo(0.35, cc.p(0, lc.y(self))), "SineO"))
    
    local index
    if P:getMaxCharacterLevel() >= WORLD_CHAT_LEVEL and P._playerMessage:getNewWorld() > 0 then
        index = TAB.world
    elseif P._playerMessage:getNewBulletin() > 0 then
        index = TAB.bulletin
    elseif P._playerMessage:getNewBattle() > 0 then
        index = TAB.battle
    end

    self._contentBg:showTab(index or (P:getMaxCharacterLevel() < WORLD_CHAT_LEVEL and TAB.bulletin or TAB.world), true)
    
    if lc._runningScene._sceneId == ClientData.SceneId.world then
        lc._runningScene:hideTab() 
    end
end

function _M:push()
    if not self._isPop then return end

    self._isPop = false
    self._arrowPop:setSpriteFrame("img_icon_chat")
    self._btnImage:setScaleX(-1)
    self._arrowPop:setPositionX(24)
    self:stopAllActions()
    self:runAction(lc.sequence(lc.ease(lc.moveTo(0.2, cc.p(-PANEL_SIZE.width, lc.y(self))), "SineI"), function() self._contentBg:setVisible(false) end))
end

function _M:checkShowTab(tabTag, isUserBehavior)
    if tabTag == TAB.union then
        if not P:hasUnion() then
            ToastManager.push(Str(STR.UNION_CHAT_TIP))
            return false
        end
    elseif tabTag == TAB.world then
        if P:getMaxCharacterLevel() < WORLD_CHAT_LEVEL then
            ToastManager.push(string.format(Str(STR.WORLD_CHAT_TIP), WORLD_CHAT_LEVEL))
            return false
        end
    end

    return true
end

function _M:showTab(tabIndex)
    local canSend, btnSend = (tabIndex == TAB.world or tabIndex == TAB.union), self._btnSend
    self._inputArea:setVisible(canSend)

    btnSend._callback = function()
        if tabIndex == TAB.world then
            self:send2World()
        else
            self:send2Union()
        end
    end

    self:resetList()

    if self._isPop then
        local focusIndex = self._contentBg._focusTabIndex
        P._playerMessage:clearNew(focusIndex)
    end

    self:showTabFlag()
end

function _M:showTabFlag()
    local total = 0
    for i, tab in ipairs(self._contentBg._tabs) do
        local number = P._playerMessage:getNew(i)
        V.checkNewFlag(tab, number, 30, 4)
        total = total + number
    end

    V.checkNewFlag(self._btnPop, total, 37, -27)
end

function _M:resetList()
    local list, focusIndex = self._list, self._contentBg._focusTabIndex
    if focusIndex == nil then return end

    local canSend = (focusIndex == TAB.world or focusIndex == TAB.union)
    list:setContentSize(lc.w(list), list._originH - (canSend and 76 or 0))

    local msgs = P._playerMessage._msgAll[focusIndex]
    list:removeAllItems()
    list:bindData(msgs, function(item, msg) self:setOrCreateItem(item, msg) end, math.min(LIST_CACHE_SIZE[focusIndex], #msgs), focusIndex < TAB.bulletin and 2 or 0)

    for i = 1, list._cacheCount do
        local item = self:setOrCreateItem(nil, msgs[i])
        list:pushBackCustomItem(item)
    end

    list:jumpToTop()
end

function _M:updateList(param)
    local list, focusIndex = self._list, self._contentBg._focusTabIndex
    if list._data == nil then
        return
    end

    if list._cacheCount < LIST_CACHE_SIZE[focusIndex] then
        self:resetList()
    else
        if list:isAtBegin() then
            list:setDataToItems(true)
            list:refreshView()
            list:jumpToTop()
        else
            if type(param) == "number" then
                local newCount = param
                list._indexBegin = list._indexBegin + newCount
                list._indexEnd = list._indexEnd + newCount

                -- Update times
                local items = list:getItems()
                for _, item in ipairs(items) do
                    self:updateItemTime(item)
                end
            else
                self:updateListItem(msg)
            end
        end
    end
end

function _M:updateListItem(msg)
    local items = self._list:getItems()
    for _, item in ipairs(items) do
        if item._msg == msg then
            self:setOrCreateItem(item, msg)
        else
            self:updateItemTime(item)
        end
    end
end

function _M:createItem()
    local item = ccui.Widget:create()
    item:setContentSize(lc.w(self._list) - 8, h or 0)
    item:setTouchEnabled(true)
    item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

    local tab = self._contentBg._focusTabIndex

    local userArea = UserWidget.create(nil, tab == TAB.union and UserWidget.Flag.LEVEL_NAME or UserWidget.Flag.NAME_UNION, 1.0)
    userArea:setScale(0.8)
    userArea:setAnchorPoint(0, 1)
    if userArea._vip then userArea._vip:setVisible(false) end
    if userArea._unionArea then userArea._unionArea._name:setColor(V.COLOR_TEXT_ORANGE) end
    item:addChild(userArea)
    item._userArea = userArea

    local time = V.createTTF("", V.FontSize.S2, V.COLOR_LABEL_LIGHT)
    time:setAnchorPoint(1, 1)
    lc.addChildToPos(item, time, cc.p(lc.w(item), 0))
    item._time = time

    return item
end

function _M:updateItemBase(item, msg, contentW)
    item._msg = msg
    item:addTouchEventListener(function(sender, type)
        if type == ccui.TouchEventType.ended then
            if msg._log == nil then
                V.operateUser(msg._user, item)
            end
        end
    end)

    self:updateItemUser(item)
    self:updateItemTime(item)

    if item._content then
        item._content:removeFromParent()
    end

    local content = V.createBoldRichText(msg._content, {_normalClr = msg._clr or V.COLOR_TEXT_LIGHT, _boldClr = V.COLOR_TEXT_GREEN, _width = contentW or lc.w(item)})
    content:setAnchorPoint(cc.p(0, 0))
    item:addChild(content)
    item._content = content

    return lc.sh(item._userArea) + 4 + lc.h(content)
end

function _M:updateItemUser(item)
    local userArea, user = item._userArea, item._msg._user
    userArea:setUser(user, true)
end

function _M:updateItemTime(item)
    item._time:setString(ClientData.getTimeAgo(item._msg._timestamp))
end

function _M:setOrCreateItem(item, msg)
    if msg._type == Data.MsgType.world or msg._type == Data.MsgType.union then
        return self:setOrCreateChatItem(item, msg)

    elseif msg._type == Data.MsgType.bulletin then
        return self:setOrCreateBulletinItem(item, msg)

    elseif msg._type == Data.MsgType.battle then
        return self:setOrCreateBattleItem(item, msg)

    end
end

function _M:setOrCreateChatItem(item, msg)
    if item == nil then
        item = self:createItem()

        local line = lc.createSprite{_name = "img_divide_line_8", _crect = cc.rect(6, 1, 1, 1), _size = cc.size(lc.w(item) + 28, 5)} 
        lc.addChildToPos(item, line, cc.p(lc.w(item) / 2, -8))
    end

    local itemH = self:updateItemBase(item, msg)
    item:setContentSize(lc.w(item), itemH)

    item._userArea:setPosition(0, itemH)
    item._time:setPosition(lc.w(item), itemH)
    item._content:setPosition(0, 0)

    return item
end

function _M:setOrCreateBulletinItem(item, msg)
    if item == nil then
        item = self:createItem()

        local line = lc.createSprite{_name = "img_divide_line_8", _crect = cc.rect(6, 1, 1, 1), _size = cc.size(lc.w(item) + 28, 5)} 
        lc.addChildToPos(item, line, cc.p(lc.w(item) / 2, -8))
    end

    local iconSize, gap = 70, 8

    local resCount, contentW = #msg._items
    if resCount > 0 and resCount <= 3 then
        contentW = lc.w(item) - (gap + iconSize) * resCount
    end

    local baseItemH = self:updateItemBase(item, msg, contentW)
    local itemH = baseItemH + 8
    if resCount > 0 then
        if resCount > 3 then
            itemH = itemH + iconSize + gap + 8
        end
    end

    item:setContentSize(lc.w(item), itemH)

    item._userArea:setPosition(0, itemH)
    item._time:setPosition(lc.w(item), itemH)
    item._content:setPosition(0, itemH - baseItemH)

    local tag = 1000
    item:removeChildrenByTag(tag)

    if resCount > 0 then
        -- Add items
        local x, y
        if resCount > 3 then
            x, y = 0, lc.bottom(item._content) - gap
        else
            x, y = lc.w(item) - resCount * (gap + iconSize) + gap - 2, iconSize + 16
        end

        for _, data in ipairs(msg._items) do
            local icon = IconWidget.create(data, IconWidget.DisplayFlag.ITEM_NO_NAME)
            icon:setAnchorPoint(0, 1)
            icon:setScale(iconSize / IconWidget.SIZE)
            lc.addChildToPos(item, icon, cc.p(x, y), 0, tag)
            x = x + iconSize + gap
        end
    end

    return item
end

function _M:setOrCreateBattleItem(item, msg)
    if item == nil then
        item = self:createItem()

        -- create opponent area
        local oppoArea = UserWidget.create(nil, UserWidget.Flag.NAME_UNION, 1, true)
        oppoArea:setScale(0.8)
        oppoArea:setAnchorPoint(1, 1)
        if oppoArea._vipArea then oppoArea._vipArea:setVisible(false) end
        if oppoArea._unionArea then oppoArea._unionArea._name:setColor(V.COLOR_TEXT_ORANGE) end
        item:addChild(oppoArea)
        item._oppoArea = oppoArea

        local btn1 = V.createScale9ShaderButton("img_btn_1_s", function(sender) end, V.CRECT_BUTTON_S, 150)
        btn1:setDisabledShader(V.SHADER_DISABLE)
        btn1:addLabel("")
        item:addChild(btn1)
        item._btn1 = btn1

        local btn2 = V.createScale9ShaderButton("img_btn_2_s", function(sender) end, V.CRECT_BUTTON_S, 150)
        btn2:addLabel("")
        btn2:addIcon("img_icon_like")
        item:addChild(btn2)
        item._btn2 = btn2

        local infoArea = lc.createNode(cc.size(220, 40))
        local createIconValue = function(iconName, left, iconOffY)
            local icon = lc.createSprite(iconName)
            lc.addChildToPos(infoArea, icon, cc.p(left + lc.w(icon) / 2, lc.h(infoArea) / 2))

            local value = V.createTTF("0", V.FontSize.S3, V.COLOR_LABEL_LIGHT)
            value:setAnchorPoint(0, 0.5)
            lc.addChildToPos(infoArea, value, cc.p(lc.right(icon) + 6, lc.y(icon)))

            if iconOffY then
                lc.offset(icon, 0, iconOffY)
            end

            return value
        end
        
        item._roundVal = createIconValue("img_icon_clock", 0)
        item._watchVal = createIconValue("img_icon_watch", 100)
        item._likeVal = createIconValue("img_icon_like", 180, 2)

        lc.addChildToPos(item, infoArea, cc.p(lc.w(infoArea) / 2, 0))
        item._infoArea = infoArea

        local line = lc.createSprite{_name = "img_divide_line_8", _crect = cc.rect(6, 1, 1, 1), _size = cc.size(lc.w(item) + 28, 5)} 
        lc.addChildToPos(item, line, cc.p(lc.w(item) / 2, 0))
    end

    local btn1, btn2 = item._btn1, item._btn2
    local itemH = self:updateItemBase(item, msg, lc.w(item) - 100)
    itemH = itemH + lc.h(btn1) + 32

    item:setContentSize(lc.w(item), itemH)

    item._userArea:setPosition(0, itemH - lc.h(item._content) - 12)
    item._time:setPosition(lc.w(item), itemH)
    item._content:setPosition(0, itemH - lc.h(item._content))
    item._oppoArea:setPosition(cc.p(lc.w(item) + 4, lc.y(item._userArea)))

    btn1:setPosition(lc.w(item) - lc.w(btn1) / 2, 38)    
    btn2:setVisible(false)

    item._userArea:removeChildrenByTag(TAG_CUSTOM)

    if msg._log then
        local oppoArea = item._oppoArea
        oppoArea:setVisible(true)
        oppoArea:setUser(msg._opponent, true)
        
        local pos = cc.p(lc.cw(item), lc.y(item._userArea) - 70)
        if msg._watchIds[P._sid] then
            --[[
            local left = lc.createSprite(msg._resultType == Data.BattleResult.win and "img_win" or (msg._resultType == Data.BattleResult.lose and "img_lose" or "img_draw"))
            left:setScale(0.2)
            lc.addChildToPos(item, left, cc.p(pos.x - 220, pos.y), 0, TAG_CUSTOM)

            local right = lc.createSprite(msg._resultType == Data.BattleResult.win and "img_lose" or (msg._resultType == Data.BattleResult.lose and "img_win" or "img_draw"))
            right:setScale(0.2)
            lc.addChildToPos(item, right, cc.p(pos.x + 244, pos.y), 0, TAG_CUSTOM)
            ]]
        else
            --local vs = lc.createSprite("img_vs_s")
            --vs:setScale(0.8)
            --lc.addChildToPos(item, vs, cc.p(pos.x, pos.y + 50), 1, TAG_CUSTOM)
        end
       

        item._infoArea:setVisible(true)
        item._infoArea:setPositionY(lc.y(btn1))
        item._roundVal:setString(string.format(Str(STR.ROUND_N), msg._round))
        item._watchVal:setString(tostring(msg._watchIdsCount))
        item._likeVal:setString(tostring(msg._likeIdsCount))

        btn1._label:setString(Str(STR.REPLAY))
        btn1._callback = function() self:replayBattle(msg) end

        if msg._likeIds[P._sid] then
            btn2._label:setString(Str(STR.CANCEL))
            btn2._callback = function()
                ClientData.sendShareLikeCancel(msg._log._id)
            end
        else
            btn2._label:setString(Str(STR.ZAN))
            btn2._callback = function()
                ClientData.sendShareLike(msg._log._id)
            end
        end

        btn2:setVisible(true)
        btn2:setPosition(lc.left(btn1) - 6 - lc.w(btn2) / 2, lc.y(btn1))
    else
        item._oppoArea:setVisible(false)

        item._infoArea:setVisible(false)

        if msg._result then
            btn1._label:setString(Str(STR.JOIN))
            btn1:setEnabled(false)
        else            
            btn1._label:setString(Str(STR.JOIN))
            btn1._callback = function() self:joinFriendBattle(msg._battleId) end
        end
    end

    return item
end

function _M:processByWin32Cmd()
    if lc.PLATFORM == cc.PLATFORM_OS_WINDOWS then
        local msg = self._iptSend:getText()
        if string.find(msg, "CMD") == 1 or string.find(msg, "cmd") == 1 then
            local cmds = string.splitByChar(msg, ' ')
            for _, cmd in ipairs(cmds) do
                local params = string.splitByChar(cmd, ':')
                if #params == 2 then
                    local key, val = params[1], params[2]
                    if key == "replay" then
                        V.getActiveIndicator():show(Str(STR.WAITING))

                        local replayId = tonumber(val)
                        ClientData.sendBattleReplay(replayId, replayId < 0x7FFFFFFF)
                        break
                    end
                end
            end

            return true
        end
    end

    return false
end

function _M:send2World()
    if self:processByWin32Cmd() then
        return
    end

    if P:getMaxCharacterLevel() < Data._globalInfo._unlockChat then
        self._iptSend:setText("")
        ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockChat))
        return
    end

    if P._chatBanList[P._id] then
        self._iptSend:setText("")
        ToastManager.push(Str(STR.CHAT_BAN_TIP))
        return
    end

    local dt = math.ceil(P._nextChat - ClientData.getCurrentTime())
    if dt <= 0 then
        local msg = self._iptSend:getText()
        if msg == "" then return end
        
        -- Avoid invalid content
        msg = string.gsub(msg, '\n', ' ')

        if lc.utf8len(msg) > ClientData.MAX_INPUT_LEN then
            ToastManager.push(Str(STR.MESSAGE)..string.format(Str(STR.CANNOT_MORE_THAN), ClientData.MAX_INPUT_LEN))
        else
            P._nextChat = ClientData.getCurrentTime() + Data._globalInfo._chatCD * 60

            ClientData.sendChat(Chat_pb.PB_CHAT_WORLD, 0, msg)
            self._iptSend:setText("")
        end    
    else
        ToastManager.push(string.format(Str(STR.WORLD_CHAT_WAIT_TIP), ClientData.formatPeriod(dt)))
    end
end

function _M:send2Union()
    local playerUnion = P._playerUnion
    local result = playerUnion:canOperate(playerUnion.Operate.send_message)
    if result == Data.ErrorType.ok then
        local msg = self._iptSend:getText()
        if msg == "" then return end

        if lc.utf8len(msg) > ClientData.MAX_INPUT_LEN then
            ToastManager.push(Str(STR.MESSAGE)..string.format(Str(STR.CANNOT_MORE_THAN), ClientData.MAX_INPUT_LEN))
        else
            ClientData.sendChat(Chat_pb.PB_CHAT_UNION, P._unionId, msg)
            self._iptSend:setText("")
        end
    else
        ToastManager.push(ClientData.getUnionErrorStr(result))
    end
end

function _M:replayBattle(msg)
    V.getActiveIndicator():show(Str(STR.WAITING))

    local log = msg._log
    ClientData._replayingLog = log
    ClientData._replaySharable = false
    ClientData.sendBattleShareReplay(log._id)

    ClientData.sendUserEvent({chatReplayId = log._id})
end

function _M:joinFriendBattle(battleId)
    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendFriendBattleJoin(battleId)
end

function _M:onMessageEvent(event)  
    if self._isPop then
        local focusIndex = self._contentBg._focusTabIndex
        if event._event == P._playerMessage.Event.msg_new then
            if focusIndex == event._type then
                self:updateList(event._param)
            end

        elseif event._event == P._playerMessage.Event.msg_update then
            if focusIndex == event._type then
                self:updateListItem(event._param)
            end

        elseif event._event == P._playerMessage.Event.union_clear then
            if focusIndex == TAB.union then
                self._contentBg:showTab(TAB.world)
            end
     
        end

        P._playerMessage:clearNew(focusIndex)
    end

    self:showTabFlag()
end

function _M:onEnter()
    self:showTabFlag()

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.login, function(event)
        self:resetList()
    end))
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onRelease()
    self:removeAllChildren()
    lc.Dispatcher:removeEventListener(self._listener)
end

return _M