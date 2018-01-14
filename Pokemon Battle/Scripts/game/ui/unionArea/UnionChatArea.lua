local _M = class("UnionChatArea", lc.ExtendCCNode)
PlayerMessage = require("PlayerMessage")

local AREA_WIDTH_MAX = 550

function _M.create(unionId, w, h)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(math.min(w, AREA_WIDTH_MAX), h)
    area:init(unionId)

    area:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            area:onEnter()
        elseif evtName == "exit" then
            area:onExit()
        end
    end)

    return area
end

function _M:init(unionId)
    self._unionId = unionId

    self._isBattleWaiting = false

    self:initBottomArea()
    self:initChatList()
end

function _M:onEnter()
    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.message, function (event) self:onEvent(event) end))

    --self:updateBottom()
    self:updateList()

    P._playerMessage:clearNew(Data.MsgType.union)
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:initBottomArea()
    local bottomBg = lc.createNode(cc.size(lc.w(self) - 12, 60))--{_name = "img_com_bg_4", _crect = V.CRECT_COM_BG4, _size = cc.size(lc.w(self) - 12, 180)}
    lc.addChildToPos(self, bottomBg, cc.p(lc.w(self) / 2, lc.ch(bottomBg)), 1)
    self._topArea = bottomBg

    local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 1, 1), cc.size(286, 56), Str(STR.INPUT_SHARE_TEXT))
    lc.addChildToPos(bottomBg, editor, cc.p(lc.w(bottomBg) / 2 + 2, lc.ch(bottomBg) + 25))
    self._editor = editor

    local btnSend = V.createScale9ShaderButton("img_btn_1_s", function() self:send() end, V.CRECT_BUTTON_1_S, 120)
    btnSend:addLabel(Str(STR.SEND))
    lc.addChildToPos(bottomBg, btnSend, cc.p(lc.right(editor) + lc.w(btnSend) / 2 + 6, lc.y(editor)))
    self._btnSend = btnSend

    local btnPvp = V.createScale9ShaderButton("img_btn_1_s", function(sender) 
        self:onBattleCreate()
    end, V.CRECT_BUTTON_1_S, 120)
    btnPvp:setDisabledShader(V.SHADER_DISABLE)
    btnPvp:setEnabled(false)
    lc.addChildToPos(bottomBg, btnPvp, cc.p(lc.left(editor) - lc.cw(btnPvp) - 4, lc.y(editor)))
    btnPvp:addLabel(lc.str(STR.FRIEND_BATTLE))
end

function _M:initChatList()
    local chatList = lc.List.createV(cc.size(lc.w(self) - 12, lc.h(self) - 108), 6, 0)
    lc.addChildToPos(self, chatList, cc.p(10, 80))
    self._chatList = chatList
end

function _M:updateList()
    local msgAll = P._playerMessage._msgAll[Data.MsgType.union]
    local msgIndex, itemIndex = 1, 1

    

    while true do
        local msg = msgAll[#msgAll - msgIndex + 1]
        local listItem = self._chatList:getItems()[itemIndex]

        if not msg then
            break
        else
            if (not listItem) then
                if self:getIsInvalidBattle(msg) then
                    msgIndex = msgIndex + 1
                else
                    self:addNewMessage(msg)
                    msgIndex = msgIndex + 1
                    itemIndex = itemIndex + 1
                end
            elseif self:getIsInvalidBattle(msg) then
                self._chatList:removeItem(itemIndex - 1)
                msgIndex = msgIndex + 1
            else 
                msgIndex = msgIndex + 1
                itemIndex = itemIndex + 1
            end
        end
    end

    self._chatList:stopAllActions()
    self._chatList:scrollToBottom(0.2, false)
end

function _M:getIsInvalidBattle(message)
    if message._type == Data.MsgType.union and message._battleId then
        if (not message._isValid) and (not message._opponent) then 
            return true
        end
    end

    return false
end

function _M:addNewMessage(message)
    local layout = nil

    if message._type == Data.MsgType.union then
        if message._battleId == nil then
            layout = self:addChatItem(message) 
        else
            layout = self:addBattleItem(message)
        end
    end

    if layout then
        self._chatList:pushBackCustomItem(layout)
    end
end

function _M:addChatItem(message)
    local isSelf = message._user._id == P._id

    local layout = ccui.Layout:create()
    layout._message = message

    local clr = message._clr and lc.Color3B.orange or lc.Color3B.white

    -- chat
    --local label = V.createBoldRichText(message._content, V.FontSize.S1, lc.Color3B.black, cc.size(lc.w(self._chatList) - 150, 0))
    local label = V.createBoldRichText(message._content, {_normalClr = clr, _boldClr = clr, _width = lc.w(self._chatList) - 150})

    local bgHeight = math.max(lc.h(label) + 30 , 50)
    local itemHeight = 100 + bgHeight 

    layout:setContentSize(cc.size(lc.w(self._chatList), itemHeight))
    layout:setAnchorPoint(cc.p(0.5, 0.5))

    local chatBg = lc.createSprite({_name = "img_com_bg_58", _size = cc.size(lc.w(self._chatList) - 115, bgHeight), _crect = cc.rect(57, 14, 1, 1)})

    local chatPosX = isSelf and lc.cw(chatBg) or (lc.cw(chatBg) + 115)
    lc.addChildToPos(layout, chatBg, cc.p(chatPosX, lc.h(layout) - lc.ch(chatBg) - 55))

    local labelPosX = isSelf and (lc.cw(label) + 10) or (lc.cw(label) + 10)
    lc.addChildToPos(chatBg, label, cc.p(labelPosX, lc.ch(chatBg)))
    
    -- avator
    local avatar = UserWidget.create(message._user, 0)
    avatar:setScale(0.8)
    local avatarPosX = isSelf and (lc.w(layout) - lc.cw(avatar)) or lc.cw(avatar)
    lc.addChildToPos(layout, avatar, cc.p(avatarPosX, lc.h(layout) - lc.ch(avatar) - 20))

    local name = V.createTTF(message._user._name, V.FontSize.S2)
    local namePosX = isSelf and (lc.left(avatar) - lc.cw(name) - 8) or (lc.right(avatar) + lc.cw(name) + 8)
    lc.addChildToPos(layout, name, cc.p(namePosX, lc.h(layout) - lc.ch(name) - 26))

    -- time
    local str = string.format("%d%s", "0", lc.str(STR.SECOND_AGO))
    local time = V.createTTF(str, V.FontSize.S2)
    local timePosX = isSelf and 0 or (lc.w(layout))
    time:setAnchorPoint(isSelf and cc.p(0, 0.5) or cc.p(1, 0.5))
    lc.addChildToPos(layout, time, cc.p(timePosX, lc.h(layout) - lc.ch(time) - 26))
    layout._time = time

    -- update
    layout.update = function (self)
        self._time:setString(ClientData.getTimeAgo(self._message._timestamp))
    end
    local separator = lc.createImageView("img_divide_line_5")
    separator:setScaleX((lc.w(layout)) / lc.w(separator))
    lc.addChildToPos(layout, separator, cc.p(lc.cw(layout), 0))
    layout:update(self)

    return layout
end

function _M:addBattleItem(message)
    local isSelf = message._user._id == P._id

    local layout = ccui.Layout:create()
    layout:setContentSize(cc.size(lc.w(self._chatList), 200))
    layout:setAnchorPoint(cc.p(0.5, 0.5))
    layout._message = message

    local itemBg = lc.createSprite({_name = "img_com_bg_30", _crect = V.CRECT_COM_BG30, _size = cc.size(lc.w(self._chatList), 180)})
    lc.addChildToCenter(layout, itemBg)
    itemBg:setColor(cc.c3b(219, 253, 169))

    local userAvatar = UserWidget.create(message._user, UserWidget.Flag.LEVEL_NAME, 0.8, false)
    lc.addChildToPos(layout, userAvatar, cc.p(lc.cw(userAvatar) + 20, lc.h(layout) - lc.ch(userAvatar) - 25))

    local oppoAvatar = UserWidget.create(message._user, UserWidget.Flag.LEVEL_NAME, 0.8, true)
    lc.addChildToPos(layout, oppoAvatar, cc.p(lc.w(layout) - lc.cw(oppoAvatar) - 20, lc.y(userAvatar)))

    local vsSpr = lc.createSprite("img_vs_s")
    lc.addChildToPos(layout, vsSpr, cc.p(lc.cw(layout), lc.y(userAvatar) + 20))

    local timeLabel = V.createTTF("", V.FontSize.S3)
    lc.addChildToPos(vsSpr, timeLabel, cc.p(lc.cw(vsSpr), lc.ch(vsSpr) - 50))

    if isSelf then
        local btn = V.createScale9ShaderButton("img_btn_2_s", function(sender) 
            self:onBattleCancel()
        end, V.CRECT_BUTTON_S, 140)
        lc.addChildToPos(layout, btn, cc.p(lc.cw(layout), lc.ch(btn) + 30))
        btn:addLabel(lc.str(STR.CANCEL))
        layout._btnCancel = btn
    else
        local btn = V.createScale9ShaderButton("img_btn_1_s", function(sender) 
            self:onBattleJoin(message)
        end, V.CRECT_BUTTON_S, 140)
        lc.addChildToPos(layout, btn, cc.p(lc.cw(layout), lc.ch(btn) + 30))
        btn:addLabel(lc.str(STR.JOIN))
        layout._btnJoin = btn
    end

    local btn = V.createScale9ShaderButton("img_btn_1_s", function(sender) 
        self:onBattleReplay(message)
    end, V.CRECT_BUTTON_S, 140)
    lc.addChildToPos(layout, btn, cc.p(lc.cw(layout), lc.ch(btn) + 30))
    btn:addLabel(lc.str(STR.REPLAY))
    layout._btnReplay = btn

    local leftTip = V.createTTF(lc.str(STR.FRIEND_BATTLE_SEARCH), V.FontSize.M2)
    lc.addChildToPos(layout, leftTip, cc.p(lc.cw(layout) + lc.cw(leftTip) + 30, lc.y(userAvatar)))

    local bottomTip = V.createTTF(lc.str(STR.DISABLED), V.FontSize.M1)
    lc.addChildToPos(layout, bottomTip, cc.p(lc.cw(layout), lc.y(btn)))

    -- update
    layout.update = function (self, unionChatArea)
        -- wait fro battle
        if self._message._isValid then
            if self._btnCancel then self._btnCancel:setVisible(true)
            elseif self._btnJoin then self._btnJoin:setVisible(true) end
            self._btnReplay:setVisible(false)

            bottomTip:setVisible(false)
            leftTip:setVisible(true)

            oppoAvatar:setVisible(false)
            vsSpr:setVisible(false)

        -- cancel
        elseif not self._message._opponent then
            if self._btnCancel then self._btnCancel:setVisible(false)
            elseif self._btnJoin then self._btnJoin:setVisible(false) end
            self._btnReplay:setVisible(false)

            bottomTip:setVisible(true)
            bottomTip:setString(lc.str(STR.DISABLED))
            leftTip:setVisible(true)

            oppoAvatar:setVisible(false)
            vsSpr:setVisible(false)

        -- battleing
        elseif not self._message._resultType then
            if self._btnCancel then self._btnCancel:setVisible(false)
            elseif self._btnJoin then self._btnJoin:setVisible(false) end
            self._btnReplay:setVisible(false)

            bottomTip:setVisible(true)
            bottomTip:setString(lc.str(STR.FRIEND_BATTLE_UNDER))
            leftTip:setVisible(false)

            oppoAvatar:setVisible(true)
            oppoAvatar:setUser(self._message._opponent)
            vsSpr:setVisible(true)
            timeLabel:setString(ClientData.getTimeAgo(self._message._timestamp))

        -- replay
        else
            if self._btnCancel then self._btnCancel:setVisible(false)
            elseif self._btnJoin then self._btnJoin:setVisible(false) end
            self._btnReplay:setVisible(self._message._replayId ~= nil)

            bottomTip:setVisible(false)
            leftTip:setVisible(false)

            oppoAvatar:setVisible(true)
            oppoAvatar:setUser(self._message._opponent)
            vsSpr:setVisible(true)
            timeLabel:setString(ClientData.getTimeAgo(self._message._timestamp))
        end
    end

    layout:update(self)

    return layout
end

function _M:onBattleCreate()
    if self._isBattleWaiting then
        ToastManager.push(lc.str(STR.FRIEND_BATTLE_SEARCHING))
    else
        self._isBattleWaiting = true

        ClientData.sendUnionFriendBattle(P._curTroopIndex)
    end
end

function _M:onBattleCancel(isSkipToast)
    if self._isBattleWaiting then
        self._isBattleWaiting = false
        if not isSkipToast then
            ToastManager.push(lc.str(STR.FRIEND_BATTLE_CANCEL))
        end

        ClientData.sendUnionFriendBattleCancel()
    end
end

function _M:onBattleJoin(message)
    if self._isBattleWaiting then
        self:onBattleCancel()
    end

    ClientData.sendUnionFriendBattleJoin(P._curTroopIndex, message._battleId, message._user._id)
end

function _M:onBattleReplay(message)
    if self._isBattleWaiting then
        self:onBattleCancel()
    end

    ClientData.sendBattleReplay(message._replayId, true)
end

function _M:onEvent(event)
    if event._event == PlayerMessage.Event.msg_new then
        if event._param > 0 then
            self:updateList()
        end

    elseif event._event == PlayerMessage.Event.msg_update then
        self:updateList()
    end
end

function _M:send()
    local text = self._editor:getText()

        if lc.utf8len(text) > ClientData.MAX_INPUT_LEN  then
            ToastManager.push(Str(STR.MESSAGE)..string.format(Str(STR.CANNOT_MORE_THAN), ClientData.MAX_INPUT_LEN))
            return

        elseif lc.utf8len(text) == 0 then
            ToastManager.push(Str(STR.INPUT_MESSAGE))
            return

        else
            local playerUnion = P._playerUnion
            local result = playerUnion:canOperate(playerUnion.Operate.send_message)
            if result == Data.ErrorType.ok then
                ClientData.sendChat(Chat_pb.PB_CHAT_UNION, P._unionId, text)
            else
                ToastManager.push(ClientData.getUnionErrorStr(result))
            end
        end
        self._editor:setText("")
end

return _M