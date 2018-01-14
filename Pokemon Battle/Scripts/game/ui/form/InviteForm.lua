local _M = class("InviteForm", BaseForm)

local FORM_SIZE = cc.size(900, 640)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init(callback)
    _M.super.init(self, FORM_SIZE, Str(STR.INVITE), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))
    
    local tab
    if P._level >= Data._globalInfo._unlockInvite then
        tab = 2
    end

    self:addTabs({Str(STR.ACCEPT)..Str(STR.INVITE), Str(STR.MY)..Str(STR.INVITE)}, tab)
end

function _M:showTab(name, isForce)
    local isSelfInvite = (string.find(name, Str(STR.MY)) ~= nil)
    if isSelfInvite then
        if P._level < Data._globalInfo._unlockInvite then
            ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockInvite))
            return false
        end
    end

    if not _M.super.showTab(self, name, isForce) then return false end    
    
    self._isSelfInvite = isSelfInvite
    self:refreshContent()
    return true
end

function _M:refreshContent()
    local area = self._contentArea
    if area then
        area:removeAllChildren()
    else
        local areaSize = cc.size(FORM_SIZE.width - _M.FRAME_THICK_H, FORM_SIZE.height - _M.FRAME_THICK_V)
        area = lc.createNode(areaSize)
        lc.addChildToPos(self._form, area, cc.p(_M.FRAME_THICK_LEFT + areaSize.width / 2, _M.FRAME_THICK_BOTTOM + areaSize.height / 2))
        self._contentArea = area
    end

    local cx = lc.w(area) / 2
    if self._isSelfInvite then
        if P._inviteCode then
            local topArea = lc.createSprite{_name = "img_com_bg_4", _crect = V.CRECT_COM_BG4, _size = cc.size(lc.w(area), 160)}            
            lc.addChildToPos(area, topArea, cc.p(cx, lc.h(area) - lc.h(topArea) / 2 - 4), 1)

            local myCode = V.createKeyValueLabel(Str(STR.MY)..Str(STR.INVITE_CODE), P._inviteCode, V.FontSize.S1)
            myCode:addToParent(topArea, cc.p(32, lc.h(topArea) - 30 - lc.h(myCode) / 2))

            local inviteIngot, ingotVal = V.createKeyValueLabel(Str(STR.INVITE_INGOT), P._inviteIngot, V.FontSize.S1, nil, "img_icon_res3_s")
            inviteIngot:addToParent(topArea, cc.p(310, lc.y(myCode)))
            self._ingotVal = ingotVal

            local btnRule = V.createScale9ShaderButton("img_btn_1", function() self:showHelp() end, V.CRECT_BUTTON, 150)
            btnRule:addLabel(Str(STR.INVITE_RULE))
            lc.addChildToPos(topArea, btnRule, cc.p(lc.left(myCode) - 4 + lc.w(btnRule) / 2, 60))

            local glow = lc.createSprite("img_glow")
            glow:setOpacity(200)
            glow:setScale(0.65)
            lc.addChildToPos(topArea, glow, cc.p(lc.w(topArea) - 100, lc.h(topArea) / 2))

            local invited = V.createTTF(Str(STR.INVITED), V.FontSize.S3, V.COLOR_LABEL_DARK)
            lc.addChildToPos(topArea, invited, cc.p(lc.x(glow), lc.y(myCode)))

            local count = V.createBMFont(V.BMFont.num_48, P._inviteCount)
            lc.addChildToPos(topArea, count, cc.p(lc.x(glow), 74))
            self._inviteCount = count

            local list = lc.List.createV(cc.size(lc.w(area) - 8, lc.h(area) - lc.h(topArea) + 10), 6, 0)
            lc.addChildToPos(area, list, cc.p(4, -4))

            for i = 1, #P._playerBonus._bonusInvite do
                local bonus = P._playerBonus._bonusInvite[i]
                local bonusWidget = require("BonusWidget").create(lc.w(list), bonus)
                bonusWidget:registerCallback(function(bonus) self:claimBonus(bonus) end)
                list:pushBackCustomItem(bonusWidget)
            end

        else
            self._indicator = V.showPanelActiveIndicator(area)
            ClientData.sendGetInviteCode()
        end

    else
        if P._invitedCode then
            local userInfo = self._inviteInfo
            if userInfo then
                local tip = V.createTTF(Str(STR.INVITED_WITH_PLAYER), V.FontSize.S1, V.COLOR_TEXT_ORANGE)
                lc.addChildToPos(area, tip, cc.p(cx, lc.h(area) - 100 - lc.h(tip) / 2))

                local userWidget = UserWidget.create(userInfo, UserWidget.Flag.REGION_NAME_UNION)
                lc.addChildToPos(area, userWidget, cc.p(cx, lc.bottom(tip) - 30 - lc.h(userWidget) / 2))

                userWidget._regionArea:setColor(V.COLOR_TEXT_LIGHT)
                if userWidget._unionArea then
                    userWidget._unionArea._name:setColor(lc.Color3B.yellow)
                end

            else
                self._indicator = V.showPanelActiveIndicator(area)
                ClientData.sendGetInviteInfo(P._invitedCode)
            end

        else
            local tip1 = V.createTTF(Str(STR.INVITED_TIP), V.FontSize.S1, nil, cc.size(700, 0))
            lc.addChildToPos(area, tip1, cc.p(cx, lc.h(area) - 50 - lc.h(tip1) / 2))
        
            local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), cc.size(400, 56), Str(STR.INVITE_CODE), true)
            lc.addChildToPos(area, editor, cc.p(cx - 90, lc.bottom(tip1) - 30 - lc.h(editor) / 2))
            self._editor = editor

            local btnAccept = V.createScale9ShaderButton("img_btn_2", function() self:acceptInvite() end, V.CRECT_BUTTON, 150)
            btnAccept:addLabel(Str(STR.ACCEPT)..Str(STR.INVITE))
            lc.addChildToPos(area, btnAccept, cc.p(lc.right(editor) + 4 + lc.w(btnAccept) / 2, lc.y(editor)))

            local tip2 = V.createTTF(Str(STR.INVITED_BONUS), V.FontSize.S1, V.COLOR_TEXT_ORANGE)
            lc.addChildToPos(area, tip2, cc.p(cx, lc.bottom(editor) - 40 - lc.h(tip2) / 2))

            local info, icons = P._playerBonus._invitedBonus._info, {}
            for i = 1, #info._rid do
                local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
                icon._name:setColor(lc.Color3B.white)
                table.insert(icons, icon)
            end
            P:sortResultItems(icons)

            lc.addNodesToCenterH(area, icons, 20, lc.bottom(tip2) - 90)
        end

        local tip3 = V.createTTF(Str(STR.INVITE_TIP), V.FontSize.S1, nil, cc.size(700, 0))
        tip3:setColor(V.COLOR_TEXT_GREEN)
        lc.addChildToPos(area, tip3, cc.p(cx, 50 + lc.h(tip3) / 2))
    end
end

function _M:acceptInvite()
    if P._level >= Data._globalInfo._unlockInvite then
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
    _M.super.onEnter(self)

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
    _M.super.onExit(self)

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