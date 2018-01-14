local _M = class("InRoomScene", BaseUIScene)

local BOTTOM_HEIGHT = 150

local COUNTDOWN_START_NUM = 5


function _M.create()
    return lc.createScene(_M)
end

function _M:init()
    if not _M.super.init(self, ClientData.SceneId.in_room, STR.HALL, BaseUIScene.STYLE_EMPTY, true) then return false end

    self:createBgs()

    self:initBottomArea()

    self._titleArea._btnBack._callback = function()
        self:onExitRoom()
    end
    
    return true
end

function _M:createBgs()
    lc.TextureCache:addImage("res/jpg/in_room_bg.jpg")
    self._bg:setTexture("res/jpg/in_room_bg.jpg")

    local topBg = lc.createSprite({_name = "room_top_bg", _crect=cc.rect(165, 0, 1, 1)})
    topBg:setContentSize(cc.size(700, lc.h(topBg)))
    topBg:setAnchorPoint(0.5, 0.5)
    local topUser = UserWidget.create(nil, bor(UserWidget.Flag.LEVEL_NAME, UserWidget.Flag.UNION, UserWidget.Flag.REGION), 1.2)
    self:adjustUserWidget(topUser)
    lc.addChildToPos(topBg, topUser, cc.p(lc.cw(topBg), lc.ch(topBg) + 10))

    local unknownUser = lc.createSprite("room_player_unknown")
    lc.addChildToCenter(topBg, unknownUser)
    topUser._unknownUser = unknownUser

    lc.addChildToPos(self, topBg, cc.p(lc.cw(self), lc.bottom(self._titleArea) - lc.ch(topBg)))
    local jobNode = lc.createNode()
    lc.addChildToPos(topBg, jobNode, cc.p(lc.cw(topBg), 25))
    topUser._jobNode = jobNode

    local roomId = V.createBMFont(V.BMFont.huali_32, "", cc.TEXT_ALIGNMENT_CENTER, 700)
    roomId:setColor(V.COLOR_TEXT_INGOT)
--    local roomId = V.createBm("", V.FontSize.M2, V.COLOR_TEXT_WHITE, cc.size(700, 50), cc.TEXT_ALIGNMENT_CENTER)
    lc.addChildToPos(topBg, roomId, cc.p(lc.cw(topBg), lc.h(topBg) - 30))
    self._roomId = roomId

    local shareBtn = V.createShaderButton("img_icon_share", function(sender) self:onShare(sender) end)
    lc.addChildToPos(topBg, shareBtn, cc.p(lc.w(topBg) - 100, lc.h(topBg) - 30))
    self._shareBtn = shareBtn

    local leftBg = lc.createSprite({_name = "room_left_bg", _crect=cc.rect(10, 10, 1, 1)})
    leftBg:setContentSize(cc.size(lc.cw(self) - 20, lc.h(leftBg)))
    leftBg:setAnchorPoint(0.5, 0.5)
    local leftUser = UserWidget.create(nil, bor(UserWidget.Flag.LEVEL_NAME, UserWidget.Flag.UNION, UserWidget.Flag.REGION), 1.2)
    self:adjustUserWidget(leftUser)
    lc.addChildToPos(leftBg, leftUser, cc.p(lc.cw(leftBg) - 10, lc.ch(leftBg) - 10))
    local leftWinNode = lc.createNode()
    lc.addChildToPos(leftBg, leftWinNode, cc.p(lc.cw(leftBg), lc.h(leftBg) + 20))
    local leftWinLabel = V.createBMFont(V.BMFont.huali_32, Str(STR.WIN_S))
    leftWinLabel:setColor(V.COLOR_TEXT_INGOT)
    local leftWinNum = V.createBMFont(V.BMFont.huali_32, "0")
    leftWinNum:setColor(V.COLOR_TEXT_WHITE)
    lc.addNodesToCenterH(leftWinNode, {leftWinLabel, leftWinNum}, 10)
    leftWinNode._winNum = leftWinNum
    leftUser._winNode = leftWinNode
    
    local unknownUser = lc.createSprite("room_player_unknown")
    lc.addChildToPos(leftBg, unknownUser, cc.p(lc.cw(leftBg) - 10, lc.ch(leftBg) - 20))
    leftUser._unknownUser = unknownUser

    lc.addChildToPos(self, leftBg, cc.p(lc.cw(leftBg), BOTTOM_HEIGHT + lc.ch(leftBg)))
    local jobNode = lc.createNode()
    lc.addChildToPos(leftBg, jobNode, cc.p(lc.cw(leftBg), lc.h(leftBg) - 25))
    leftUser._jobNode = jobNode

    local rightBg = lc.createSprite({_name = "room_right_bg", _crect=cc.rect(110, 10, 1, 1)})
    rightBg:setContentSize(cc.size(lc.cw(self) - 20, lc.h(rightBg)))
    rightBg:setAnchorPoint(0.5, 0.5)
    local rightUser = UserWidget.create(nil, bor(UserWidget.Flag.LEVEL_NAME, UserWidget.Flag.UNION, UserWidget.Flag.REGION), 1.2)
    self:adjustUserWidget(rightUser, true)
    lc.addChildToPos(rightBg, rightUser, cc.p(lc.cw(rightBg) + 10, lc.ch(rightBg) - 10))

    local rightWinNode = lc.createNode()
    lc.addChildToPos(rightBg, rightWinNode, cc.p(lc.cw(rightBg), lc.h(rightBg) + 20))
    local rightWinLabel = V.createBMFont(V.BMFont.huali_32, Str(STR.WIN_S))
    rightWinLabel:setColor(V.COLOR_TEXT_INGOT)
    local rightWinNum = V.createBMFont(V.BMFont.huali_32, "0")
    rightWinNum:setColor(V.COLOR_TEXT_WHITE)
    lc.addNodesToCenterH(rightWinNode, {rightWinLabel, rightWinNum}, 10)
    rightWinNode._winNum = rightWinNum
    rightUser._winNode = rightWinNode
    
    local unknownUser = lc.createSprite("room_player_unknown")
    lc.addChildToPos(rightBg, unknownUser, cc.p(lc.cw(rightBg) + 10, lc.ch(rightBg) - 20))
    rightUser._unknownUser = unknownUser

    lc.addChildToPos(self, rightBg, cc.p(lc.w(self) - lc.cw(rightBg), BOTTOM_HEIGHT + lc.ch(rightBg)))
    local jobNode = lc.createNode()
    lc.addChildToPos(rightBg, jobNode, cc.p(lc.cw(rightBg), lc.h(rightBg) - 25))
    rightUser._jobNode = jobNode

    self._bgs = {topBg, leftBg, rightBg}
    self._users = {topUser, leftUser, rightUser}

    local vsSpr = lc.createSprite("img_vs")
    lc.addChildToCenter(self, vsSpr)
    self._vsSpr = vsSpr
end

function _M:initBottomArea()
    local tipBg = lc.createSprite("wait_text_bg")
    tipBg:setScale(600 / lc.w(tipBg), 41 / lc.h(tipBg))
    lc.addChildToPos(self, tipBg, cc.p(lc.cw(self), BOTTOM_HEIGHT - lc.ch(tipBg) - 10))
    local tip = V.createTTF(Str(STR.WAITING)..Str(STR.LORD)..Str(STR.JOIN), V.FontSize.S1, V.COLOR_TEXT_WHITE, cc.size(600, 0), cc.TEXT_ALIGNMENT_CENTER)
    lc.addChildToPos(self, tip, cc.p(lc.x(tipBg), lc.y(tipBg)))
    self._tip = tip

    local btnNode = lc.createNode()
    lc.addChildToPos(self, btnNode, cc.p(lc.cw(self), lc.bottom(tipBg) / 2))

    local btn = V.createScale9ShaderButton("img_btn_1", function(sender) end, V.CRECT_BUTTON, 200)
    btn:addLabel(Str(STR.JOIN)..Str(STR.CAPTURE))
    btn:setDisabledShader(V.SHADER_DISABLE)
    lc.addChildToPos(self, btn, cc.p(lc.cw(self) - 100, lc.bottom(tipBg) / 2))
    self._joinBtn = btn

    local startBtn = V.createScale9ShaderButton("img_btn_1", function(sender) self:startRoomMatch() end, V.CRECT_BUTTON, 200)
    startBtn:addLabel(Str(STR.START))
    startBtn:setDisabledShader(V.SHADER_DISABLE)
    lc.addChildToPos(self, startBtn, cc.p(lc.cw(self) + 100, lc.bottom(tipBg) / 2))
    self._startBtn = startBtn

end

function _M:onExitRoom()
    if P._roomJob == Data.RoomJob.leader then
        require("Dialog").showDialog(Str(STR.CONFIRM_CLOSE_ROOM), function()
            P._playerRoom:exitMyRoom()
            self:hide()
        end)
    else
        P._playerRoom:exitMyRoom()
        self:hide()
    end
end

function _M:onChangeToBattle()
    ClientData.sendToggleRoomMatch()
end

function _M:startRoomMatch()
    ClientData.sendStartRoomMatch()
    V.getActiveIndicator():show(Str(STR.PREPARE_LIVE_BATTLE), nil)
end

function _M:syncData()
    _M.super.syncData(self)
    if not P._roomId then self:hide() end
end

function _M:reload(msgStatus)
    _M.super:reload(msgStatus)
    if not P._roomId then self:hide() end
end

function _M:onEnterRoom()
    self:refreshView()
end

function _M:onChangeToObserve()
    ClientData.sendToggleRoomMatch()
end

function _M:adjustUserWidget(user, fllipX)
    user._nameArea._level:setVisible(true)
    user._nameArea:setPosition(cc.p(lc.right(user._frame) - 5, lc.y(user._frame)))
    user._unionArea:setPosition(cc.p(lc.right(user._frame) + lc.cw(user._unionArea) + 5, lc.y(user._frame) - lc.ch(user._unionArea) - 10))
    user._unionArea._name:setColor(V.COLOR_TEXT_WHITE)
    user._regionArea:setPositionY(lc.bottom(user._frame) - 20)
    user._regionArea:setColor(V.COLOR_TEXT_WHITE)

    if fllipX then
        user:setScaleX(-user:getScaleX())
        user._frame:setScaleX(-user._frame:getScaleX())
        user._nameArea._name:setScaleX(-user._nameArea._name:getScaleX())
        user._nameArea._name:setAnchorPoint(1, 0.5)
        user._nameArea._level._level:setScaleX(-user._nameArea._level._level:getScaleX())
--        user._nameArea._level._level:setAnchorPoint(1, 0.5)
        user._unionArea._name:setScaleX(-user._unionArea._name:getScaleX())
        user._unionArea._name:setAnchorPoint(1, 0.5)
        user._unionArea._word:setScaleX(-user._unionArea._word:getScaleX())
--        user._unionArea._word:setAnchorPoint(1, 0.5)
        user._regionArea:setScaleX(-user._regionArea:getScaleX())
        user._regionArea:setAnchorPoint(1, 0)
    end
end

function _M:refreshView()
    self._room = P._playerRoom:getMyRoom()
    local id = P._roomId
    self._roomId:setString(Str(STR.ROOM_ID).." "..id)
    self:refreshPlayers()
    local members = self._room._members
    self._pos = nil
    if members[2] and members[3] then
        self._tip:setString(Str(STR.WAITING)..Str(STR.CREATOR)..Str(STR.START)..Str(STR.COMPETITION))
    else
        self._tip:setString(Str(STR.WAITING)..Str(STR.LORD)..Str(STR.JOIN))
    end
    for i = 1, 3 do
        local user = members[i]
        if user and P._playerRoom._myIdInRoom == user._idInRoom then
            self._pos = i
            break
        end
    end
    if P._roomJob == Data.RoomJob.leader then
        if P:hasUnion() then
            self._shareBtn:setVisible(true)
        else
            self._shareBtn:setVisible(false)
        end
        self._startBtn:setVisible(true)
        self._joinBtn:setPositionX(lc.cw(self) - 100)
        if members[1] and members[2] and members[3] then
            self._joinBtn:setEnabled(false)
        else
            self._joinBtn:setEnabled(true)
        end

        if members[2] and members[3] then
            self._startBtn:setEnabled(true)
        else
            self._startBtn:setEnabled(false)
        end
        if self._pos == 1 then
            self._joinBtn._label:setString(Str(STR.JOIN)..Str(STR.CAPTURE))
            self._joinBtn._callback = function(sender) self:onChangeToBattle() end
        else
            self._joinBtn._label:setString(Str(STR.OBSERVE))
            self._joinBtn._callback = function(sender) self:onChangeToObserve() end
        end
    else
        self._shareBtn:setVisible(false)
        self._startBtn:setVisible(false)
        self._joinBtn:setPositionX(lc.cw(self))
        self._joinBtn._label:setString(Str(STR.EXIT))
        self._joinBtn._callback = function(sender) self:onExitRoom() end
    end
end

--function _M:startCountDown()
--    self._joinBtn:setEnabled(false)
----    self._titleArea._btnBack:setEnabled(false)
----    self._titleArea:setEnabled(false)
--    self._tip._countDownNum = COUNTDOWN_START_NUM
--    self._countDownSchedule = lc.Scheduler:scheduleScriptFunc(function(dt)
--        self._tip:setString(self._tip._countDownNum)
--        if self._tip._countDownNum == 0 then
--            lc.Scheduler:unscheduleScriptEntry(self._countDownSchedule)
--            self._countDownSchedule = nil
--        end
--        self._tip._countDownNum = self._tip._countDownNum - 1
--    end, 1, false)
--end

function _M:refreshPlayers()
    local room = P._playerRoom:getMyRoom()
    local members = room._members

    for i=1, 3 do
        local user = members[i]
        self._users[i]._jobNode:removeAllChildren()
        if user then
            self._users[i]:setVisible(true)
            self._users[i]._unknownUser:setVisible(false)
            self._users[i]._jobNode:addChild(lc.createSprite(user._roomJob == Data.RoomJob.leader and "img_room_leader" or "img_room_rookie"))
            self._users[i]:setUser(user)
            if i > 1 then
                self._users[i]._winNode:setVisible(true)
                self._users[i]._winNode._winNum:setString(user._win)
            end
            if i == 3 then self._users[i]._nameArea._name:setScaleX(-self._users[i]._nameArea._name:getScaleX()) end
        else
            self._users[i]:setVisible(false)
            self._users[i]._unknownUser:setVisible(true)
            if i > 1 then
                self._users[i]._winNode:setVisible(false)
            end
        end
    end
    
end

function _M:runActionEnterRoom()
    local topBg = self._bgs[1]
    topBg:setPositionY(lc.y(topBg) + lc.h(topBg))
    topBg:runAction(lc.ease(lc.moveBy(0.5, cc.p(0, -lc.h(topBg))), "SineIO"))

    local leftBg = self._bgs[2]
    leftBg:setPositionX(lc.x(leftBg) - lc.w(leftBg))
    leftBg:runAction(lc.ease(lc.moveBy(0.5, cc.p(lc.w(leftBg), 0)), "SineIO"))

    local rightBg = self._bgs[3]
    rightBg:setPositionX(lc.x(rightBg) + lc.w(rightBg))
    rightBg:runAction(lc.ease(lc.moveBy(0.5, cc.p(-lc.w(rightBg), 0)), "SineIO"))

    local vsSpr = self._vsSpr
    vsSpr:setOpacity(0)
    vsSpr:setScale(0.5)
    vsSpr:runAction(lc.sequence(0.4, lc.fadeIn(0.1), lc.ease(lc.scaleTo(0.2, 1), "BackO")))
end

function _M:onEnter()
    _M.super.onEnter(self)

    local resPanel = V.getResourceUI()
    resPanel:setVisible(false)

    if not P._playerRoom:getMyRoom() then
        self:hide()
    end

    self:refreshView()

    self:runActionEnterRoom()

    local listeners = {}
    table.insert(listeners, lc.addEventListener(Data.Event.room_dirty, function(evt) self:refreshView() end))
    table.insert(listeners, lc.addEventListener(Data.Event.room_exit_dirty, function(evt) self:hide() end))
    self._listeners = listeners
end

function _M:onExit()
    _M.super.onExit(self)

    local resPanel = V.getResourceUI()
    resPanel:setVisible(true)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    if self._countDownSchedule then
        lc.Scheduler:unscheduleScriptEntry(self._countDownSchedule)
    end

    lc.TextureCache:removeTextureForKey("res/jpg/in_room_bg.jpg")
end

function _M:onShare(sender)
    sender:setEnabled(false)
    local playerUnion = P._playerUnion
    local result = playerUnion:canOperate(playerUnion.Operate.send_message)
    if result == Data.ErrorType.ok then
--        ClientData.sendChat(Chat_pb.PB_CHAT_UNION, P._unionId, text)
        ClientData.sendChat(Chat_pb.PB_CHAT_UNION, P._unionId, string.format(Str(STR.ROOM_SHARE), P._roomId))
        ToastManager.push(Str(STR.ROOM_SHARE_SUCCESS))
    else
        ToastManager.push(ClientData.getUnionErrorStr(result))
    end
end

function _M:onCleanup()
    
    _M.super.onCleanup(self)
end
return _M