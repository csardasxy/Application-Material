local _M = class("InvitePanel", lc.ExtendUIWidget)

function _M.create(...)
    local panel = _M.new(lc.EXTEND_LAYOUT)
    panel:init(...)
    return panel
end

function _M:init(size)
    self:setContentSize(size)
    self:setAnchorPoint(cc.p(0.5, 0.5))

    local area = lc.createNode(size)
    lc.addChildToCenter(self, area)
    self._contentArea = area

    local tab
    if P._invitedCode then tab = 2 end

    local nameArr
    if P:getMaxCharacterLevel() >= Data._globalInfo._inviteLevelUpperLimit then
        nameArr =  {Str(STR.MY)..Str(STR.INVITE)}
    else
        nameArr = {Str(STR.ACCEPT)..Str(STR.INVITE), Str(STR.MY)..Str(STR.INVITE)}
    end

    self:addTabs(nameArr, tab)
end

function _M:addTabs(nameArr, focusTab)
    if nameArr == nil or #nameArr == 0 then return end

    if self._tabs then
        for i = 1, #self._tabs do
            self._tabs[i]:removeFromParent(true)
        end
    end
    
    self._tabs = {}
    for i = 1, #nameArr do
        local tab = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:showTab(nameArr[i], false) end, V.CRECT_BUTTON_1_S, 240)
        lc.addChildToPos(self, tab, cc.p(lc.cw(self) + 360 * (i - (#nameArr + 1) / 2), 46))
        tab:addLabel(nameArr[i])
        self._tabs[nameArr[i]] = tab
    end
    
    self:showTab(nameArr[focusTab or 1], true)
end

function _M:showTab(name, isForce)
    local tab = self._tabs[name]
    if tab == nil or (self._focusTab == tab and (not isForce)) then return false end

    local isSelfInvite = (string.find(name, Str(STR.MY)) ~= nil)
    --[[if isSelfInvite then
        if P._level < Data._globalInfo._unlockInvite then
            ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockInvite))
            return false
        end
    end]]

    self._focusTab = tab
    self._isSelfInvite = isSelfInvite

    -- refresh
    for _, tab in pairs(self._tabs) do
        if tab == self._focusTab then
            tab:setColor(lc.Color3B.white)
            tab._label:setColor(lc.Color3B.white)
        else
            tab:setColor(cc.c3b(100, 100, 100))
            tab._label:setColor(cc.c3b(110, 170, 60))
        end
    end

    self:refreshContent()
    return true
end

function _M:refreshContent()
    self._contentArea:removeAllChildren()

    if self._isSelfInvite then
        self:initSelf()
    else
        self:initAccpet()
    end
end

function _M:initAccpet()
    local layer = self._contentArea

    local bg = lc.createSprite("res/jpg/activity_invite_1.jpg")
    lc.addChildToCenter(layer, bg)

    if P._invitedCode then
        local userInfo = self._inviteInfo
        if userInfo then
            local tip = V.createTTF(Str(STR.INVITED_WITH_PLAYER), V.FontSize.S1, V.COLOR_TEXT_ORANGE)
            lc.addChildToPos(layer, tip, cc.p(lc.cw(layer) + 110, lc.ch(layer) - 34))

            local userWidget = UserWidget.create(userInfo, UserWidget.Flag.REGION_NAME_UNION)
            lc.addChildToPos(layer, userWidget, cc.p(lc.x(tip), lc.bottom(tip) - lc.ch(userWidget) - 50))

            userWidget._regionArea:setColor(V.COLOR_TEXT_LIGHT)
            if userWidget._unionArea then
                userWidget._unionArea._name:setColor(lc.Color3B.yellow)
            end

        else
            self._indicator = V.showPanelActiveIndicator(layer)
            ClientData.sendGetInviteInfo(P._invitedCode)
        end

    else
        local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), cc.size(380, 60), Str(STR.INVITE_CODE), true)
        lc.addChildToPos(layer, editor, cc.p(lc.cw(layer) + 110, lc.ch(layer) - 34))
        self._editor = editor

        local btnAccept = V.createShaderButton("img_btn_recharge_3", function() self:acceptInvite() end)
        btnAccept:addLabel(Str(STR.ACCEPT)..Str(STR.INVITE))
        lc.addChildToPos(layer, btnAccept, cc.p(lc.x(editor), lc.ch(layer) - 150))
    end
end

function _M:initSelf()
    local layer = self._contentArea

    local bg = lc.createSprite("res/jpg/activity_invite_2.jpg")
    lc.addChildToCenter(layer, bg)

    local girl = lc.createSpriteWithMask("res/jpg/girl_invite.jpg")
    lc.addChildToPos(layer, girl, cc.p(lc.cw(layer) - 240, lc.ch(layer) - 80), 10)

    if P._inviteCode then
        local myCode = V.createTTF(P._inviteCode, V.FontSize.B2)
        lc.addChildToPos(layer, myCode, cc.p(lc.cw(layer) - 250, lc.ch(layer) + 236))

        local count = V.createBMFont(V.BMFont.num_48, P._inviteCount)
        lc.addChildToPos(layer, count, cc.p(lc.cw(layer) - 250, lc.ch(layer) + 164))
        count:setAnchorPoint(0, 0.5)
        self._inviteCount = count

        local ingotVal = V.createBMFont(V.BMFont.huali_26, P._inviteIngot)
        lc.addChildToPos(layer, ingotVal, cc.p(lc.cw(layer) - 220, lc.ch(layer) + 112))
        ingotVal:setAnchorPoint(0, 0.5)
        self._ingotVal = ingotVal

        local btnRule = V.createShaderButton("img_btn_recharge_4", function() self:showHelp() end)
        lc.addChildToPos(layer, btnRule, cc.p(lc.x(myCode), lc.y(myCode) + 90))
        btnRule:addLabel(Str(STR.INVITE_RULE))

        local list = lc.List.createV(cc.size(500, 590), 6, 0)
        lc.addChildToPos(layer, list, cc.p(lc.cw(layer) - lc.cw(list) + 134, lc.ch(layer) - lc.ch(list) + 50))

        local bonuses = {}
        for i = 1, #P._playerBonus._bonusInvite do
            table.insert(bonuses, P._playerBonus._bonusInvite[i])
        end
        table.sort(bonuses, function (a, b) return a._info._id < b._info._id end)

        for i = 1, #bonuses do
            local bonus = bonuses[i]

            local title = string.format(Str(bonus._info._nameSid), bonus._info._val)
            local bonusWidget = require("BonusWidget").create(lc.w(list), bonus, title)
            bonusWidget:registerCallback(function(bonus) self:claimBonus(bonus) end)
            list:pushBackCustomItem(bonusWidget)
        end

    else
        self._indicator = V.showPanelActiveIndicator(layer)
        ClientData.sendGetInviteCode()
    end
end

function _M:acceptInvite()
    if P:getMaxCharacterLevel() >= Data._globalInfo._inviteLevelUpperLimit then
        ToastManager.push(Str(STR.INVITE_LEVEL_OVER))
        return
    end

    V.getActiveIndicator():show()
    ClientData.sendGetInviteInfo(self._editor:getText())
end

function _M:claimBonus(bonus)
    local times = 0
    while bonus:canClaim() do
        ClientData.claimBonus(bonus)
        times = times + 1
    end

    local bonuses = {}
    for i, id in ipairs(bonus._info._rid) do
        local bonus = {_infoId = id, _count = bonus._info._count[i] * times}
        table.insert(bonuses, bonus)
    end

    local RewardPanel = require("RewardPanel")
    RewardPanel.create(bonuses, RewardPanel.MODE_CLAIM_ALL):show()
    lc.Audio.playAudio(AUDIO.E_CLAIM)
end

function _M:showHelp()
    V.showHelpForm(Str(STR.INVITE_RULE), Data.HelpType.invite)
end

function _M:hideIndicator()
    if self._indicator then
        self._indicator:removeFromParent()
        self._indicator = nil
    end

    V.getActiveIndicator():hide()
end

function _M:onEnter()
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.invite_count_dirty, function(event)
        if self._isSelfInvite then
            self._inviteCount:setString(P._inviteCount)
        end
    end))

    table.insert(self._listeners, lc.addEventListener(Data.Event.invite_ingot_dirty, function(event)
        if self._isSelfInvite then
            self._ingotVal:setString(P._inviteIngot)
        end
    end))
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    ClientData.removeMsgListener(self)
end

function _M:onMsg(msg)
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_USER_CHECK_INVITE_CODE then
        self:hideIndicator()

        local pbUserInfo = msg.Extensions[User_pb.SglUserMsg.user_check_invite_code_resp]
        self._inviteInfo = require("User").create(pbUserInfo)

        if P._invitedCode then
            if not self._isSelfInvite then
                self:refreshContent()
            end
        else
            require("PromptForm").ConfirmInvited.create(self._inviteInfo, function()
                P._invitedCode = self._editor:getText()
                ClientData.sendBindInvite(P._invitedCode)

                -- Get bonus
                local RewardPanel, bonus = require("RewardPanel"), P._playerBonus._invitedBonus
                bonus._value = bonus._info._val
                P._playerBonus:claimBonus(bonus._infoId)
                RewardPanel.create(bonus, RewardPanel.MODE_CLAIM):show()

                self:refreshContent()
            end):show()
        end
    
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_USER_GET_INVITE_CODE then
        self:hideIndicator()

        P._inviteCode = msg.Extensions[User_pb.SglUserMsg.user_get_invite_code_resp]
        if self._isSelfInvite then
            self:refreshContent()
        end

        return true

    end
    
    return false
end

return _M