--------------------------System Mail Item ------------------------------------------------------
local SystemMailItem = class("SystemMailItem", lc.ExtendUIWidget)

function SystemMailItem.create(width, mail, isShowTime)
    local item = SystemMailItem.new(lc.EXTEND_IMAGE, "img_troop_bg_6", ccui.TextureResType.plistType)
    item:setScale9Enabled(true)
    item:setCapInsets(V.CRECT_TROOP_BG)

    item:setContentSize(cc.size(width, 190))
    item:setAnchorPoint(0.5, 0.5)
    item:init(mail, isShowTime)
    return item
end

function SystemMailItem:init(mail, isShowTime)
    local content = mail._content
   
    local titleBg = lc.createNode(cc.size(670, 45))
    lc.addChildToPos(self, titleBg, cc.p(lc.w(titleBg) / 2, lc.h(self) - lc.h(titleBg) / 2 - 20))

    local title = cc.Label:createWithTTF("", V.TTF_FONT, V.FontSize.S2)
    title:setAnchorPoint(0, 0.5)
    title:setColor(V.COLOR_TEXT_LIGHT)
    lc.addChildToPos(titleBg, title, cc.p(40, lc.h(titleBg) / 2))
    self._title = title

    if isShowTime then
        local time = V.createTTF("", V.FontSize.S2, V.COLOR_TEXT_TITLE)
        time:setAnchorPoint(1, 0.5)
        lc.addChildToPos(titleBg, time, cc.p(lc.w(titleBg) - 62, lc.h(titleBg) / 2))
        self._time = time
    end

    local content = cc.Label:createWithTTF("", V.TTF_FONT, V.FontSize.S2, cc.size(lc.w(self) - 248, 66))
    content:setAnchorPoint(0, 1)
    lc.addChildToPos(self, content, cc.p(50, lc.bottom(titleBg) - 20))
    self._content = content
    
    local showDetail = function()
        require("MailDetailForm").create(self._title:getString(), self._mail._content, self._mail._timestamp):show()
    end

    local btn = V.createScale9ShaderButton("img_btn_1_s", showDetail, V.CRECT_BUTTON_1_S, 120)
    btn:addLabel(Str(STR.DETAIL))
    lc.addChildToPos(self, btn, cc.p(lc.w(self) - 50 - lc.w(btn) / 2, lc.top(content) - lc.h(btn) / 2))

    self:setTouchEnabled(true)
    self:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    self:addTouchEventListener(function(sender, type)
        if type == ccui.TouchEventType.ended then
            showDetail()
        end
    end)

    self:setMail(mail)
end

function SystemMailItem:setMail(mail)
    self._mail = mail
    self._title:setString(mail._title or Str(STR.NO_TITLE))

    if self._time then
        self._time:setString(ClientData.getTimeAgo(mail._timestamp))
    end

    local rawStr = string.gsub(mail._content, "|", "")
    self._content:setString(rawStr)
end

--<< CLASS Msg Mail Item >>--

local MsgMailItem = class("MsgMailItem", lc.ExtendUIWidget)

function MsgMailItem.create(width, mail)
    local item = MsgMailItem.new(lc.EXTEND_IMAGE, "img_troop_bg_6", ccui.TextureResType.plistType)
    item:init(width, mail)
    return item
end

function MsgMailItem:onEnter()
    self._listener = lc.addEventListener(Data.Event.mail, function(event) 
        local PlayerMail = require("PlayerMail")
        if event._event == PlayerMail.Event.mail_dirty and event._data == self._mail then
            V.getActiveIndicator():hide()
            self:updateView()
        end
    end)
    self:updateView()
end

function MsgMailItem:onExit()
    lc.Dispatcher:removeEventListener(self._listener)
end

function MsgMailItem:init(width, mail)
    self:setScale9Enabled(true)
    self:setCapInsets(V.CRECT_TROOP_BG)
    self:setContentSize(cc.size(width, 160))
    self:setAnchorPoint(0.5, 0.5)

    self:setTouchEnabled(true)
    self:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            V.operateUser(self._mail._user, self)
        end
    end)

    self._mail = mail
    
    local userArea = UserWidget.create(mail._user, UserWidget.Flag.NAME_UNION)
    userArea:setScale(0.95)
    lc.addChildToPos(self, userArea, cc.p(lc.w(userArea) / 2 + 28, lc.h(self) / 2 + 4))
    self._userArea = userArea

    local content = V.createTTF("0", nil, V.COLOR_TEXT_WHITE, cc.size(292, 100), cc.TEXT_ALIGNMENT_LEFT, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    content:setAnchorPoint(0, 1)
    lc.addChildToPos(self, content, cc.p(lc.w(self) - lc.w(content) - 16, lc.top(userArea) + 8))
    self._content = content

    local time = V.createTTF("", nil, V.COLOR_LABEL_LIGHT)
    time:setAnchorPoint(1, 0.5)
    lc.addChildToPos(self, time, cc.p(lc.right(content), 32 + lc.h(time) / 2))
    self._time = time
end

function MsgMailItem:updateView()
    local mail = self._mail
    self._userArea:setUser(mail._user, true)
    self._time:setString(ClientData.getTimeAgo(mail._timestamp))

    self._content:setDimensions(292, 100)
    self._content:setString(mail._title or mail._content)

    local tag = 1000
    local addButtons = function(btn1, btn1Label, btn2, btn2Label)
        self._content:setDimensions(292, 54)

        btn1:addLabel(btn1Label)
        lc.addChildToPos(self, btn1, cc.p(lc.left(self._content) + lc.w(btn1) / 2, lc.bottom(self._time) + lc.h(btn1) / 2), 0, tag)

        if btn2 then
            btn2:addLabel(btn2Label)
            lc.addChildToPos(self, btn2, cc.p(lc.right(btn1) + 10 + lc.w(btn2) / 2, lc.y(btn1)), 0, tag)
        end
    end

    local addStatus = function(labelStr, clr)
        self._content:setDimensions(292, 54)

        local img = lc.createSprite("img_status_rect")
        img:setColor(clr)
        img:setScale(0.8)
        lc.addChildToCenter(img, V.createTTF(labelStr, V.FontSize.S1, clr))
        lc.addChildToPos(self, img, cc.p(lc.left(self._content) + lc.sw(img) / 2, lc.bottom(self._time) + lc.sh(img) / 2), 0, tag)
    end
    
    self:removeChildrenByTag(tag)

    if mail._title then
        local btnDetail = V.createScale9ShaderButton("img_btn_1_s", function()
            require("MailDetailForm").create(mail._title, mail._content, mail._timestamp):show()
        end, V.CRECT_BUTTON_1_S, 100)
        addButtons(btnDetail, Str(STR.DETAIL))

    else
        local status = mail._inviteStatus or mail._applyStatus or mail._sosStatus
        if mail._inviteStatus or mail._applyStatus then
            if status == SglMsg_pb.PB_INVITE_INVITED or status == SglMsg_pb.PB_APPLY_APPLIED then
                local btnRefuse = V.createScale9ShaderButton("img_btn_2_s", function()
                    P._playerMail:refuseMail(mail)
                end, V.CRECT_BUTTON_S, 100)

                local btnAccept = V.createScale9ShaderButton("img_btn_1_s", function()
                    P._playerMail:acceptMail(mail)
                end, V.CRECT_BUTTON_1_S, 100)

                addButtons(btnRefuse, Str(STR.REFUSE), btnAccept, Str(STR.ACCEPT))
            else
                if status == SglMsg_pb.PB_INVITE_ACCEPTED or status == SglMsg_pb.PB_APPLY_ACCEPTED then
                    addStatus(Str(STR.ACCEPTED), V.COLOR_TEXT_GREEN)
                else
                    addStatus(Str(STR.REFUSED), V.COLOR_TEXT_RED)
                end
            end
        elseif mail._sosStatus then
            if status == SglMsg_pb.PB_SOS_ISSUED then
                local btnAttack = V.createShaderButton("img_btn_2", function(sender)
                    if mail._opponentId == P._id then
                        ToastManager.push(Str(STR.CANT_RESCUE))
                    else
                        local isTroopValid, msg = P._playerCard:checkTroop(P._curTroopIndex)
                        if not isTroopValid then
                            ToastManager.push(msg)
                            return
                        end

                        V.getActiveIndicator():show(Str(STR.WAITING), nil, mail)
                        ClientData.sendWorldCityRescue(P._curTroopIndex, mail._id)
                    end
                end)

                local btnTroop = V.createShaderButton("img_btn_1", function(sender)
                    require("VisitForm").create(mail._opponentId):show()
                end)

                addButtons(btnAttack, Str(STR.UNION_HELP), btnTroop, Str(STR.INFO))
            else
                addStatus(Str(STR.RESCUED), V.COLOR_TEXT_GREEN)
            end
        end
    end
end

function MsgMailItem:updateMail(mail)
    self._mail = mail
    self:updateView()
end

local _M = class("MailForm", BaseForm)

local FORM_SIZE = cc.size(980, 640)

_M.SystemMail = 
{
    announce = 1,
    notice = 2,
    bonus = 3,
    union = 4, 
    leave_message = 5,
    send = 6,
}

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
        
    return panel 
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.MAIL), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))
    
    self._form:setTouchEnabled(false)
    self:createSystemMailArea()
end

function _M:createSystemMailArea()
    local tabs = {
        {_str = Str(STR.ANNOUNCEMENT)},
        {_str = Str(STR.NOTICE)},
        {_str = Str(STR.BONUS)},
        {_str = Str(STR.UNION)},
        {_str = Str(STR.LEAVE_MESSAGE)},
        {_str = Str(STR.SEND_GIFT)}
    }

    local tabArea = V.createHorizontalTabListArea3(lc.w(self._frame) - 40, tabs, function(tab, isSameTab, isUserBehavior) self:showSystemTab(tab._index, not isSameTab, isUserBehavior) end)
    lc.addChildToPos(self._frame, tabArea, cc.p(V.FRAME_INNER_LEFT + lc.w(tabArea) / 2, lc.h(self._frame) - 95), 3)
    self._tabArea = tabArea

    local bgPanel = lc.createSprite{_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._frame) - V.FRAME_INNER_RIGHT - V.FRAME_INNER_LEFT, lc.bottom(self._tabArea) - 10)}
    lc.addChildToPos(self._frame, bgPanel, cc.p(lc.cw(self._frame), lc.bottom(self._tabArea) - lc.ch(bgPanel) + 5))
    local list = lc.List.createV(cc.size(lc.w(bgPanel) - 20, lc.h(bgPanel) - 20), 10, 10)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(bgPanel, list)
    self._list = list

    self._tabArea:showTab(1)
end

function _M:showSystemTab(tabIndex, isForce)
    if not isForce then return end

    self._focusTabIndex = tabIndex
    self:refreshSystemMails()
end

function _M:showSystemTabFlag()
    local tabs = self._tabArea._list:getItems()

    for i = 1, #tabs do
        local number = 0
        if i == _M.SystemMail.bonus then
            number = P._playerBonus:getClaimCenterBonusFlag()
        elseif i == _M.SystemMail.announce then
            number = P._playerMail:getNewAnnouncements()
        elseif i == _M.SystemMail.notice then
            number = P._playerMail:getNewNoticeMails()
        elseif i == _M.SystemMail.union then
            number = P._playerMail:getNewUnionMails()
        elseif i == _M.SystemMail.leave_message then
            number = P._playerMail:getNewMsgMails()
        elseif i == _M.SystemMail.send then
            number = P._playerBonus:getSendBonusFlag()
        end
        
        local tab = tabs[i]
        V.checkNewFlag(tab, number, 32, -4)
    end
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    self._listeners = {}
    
    local listener = lc.addEventListener(Data.Event.mail, function(event)
        self:onMail(event._event) 
    end)  
    table.insert(self._listeners, listener)
    
    listener = lc.addEventListener(Data.Event.server_bonus_list_dirty, function(event)
        self:onServerBonus()
    end)
    table.insert(self._listeners, listener)
end

function _M:onExit()
    _M.super.onExit(self)
    
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    V.getMenuUI():updateMailFlag()
end

function _M:onCleanup()
    _M.super.onCleanup(self)
end

function _M:refreshSystemMails()
    local list = self._list

    if self._focusTabIndex == _M.SystemMail.bonus then        
        local bonuses = P._playerBonus._serverBonuses

        local setOrCreateItem = function(item, bonus)
            local title = bonus._info and string.format(Str(bonus._info._nameSid), bonus._info._val) or bonus._title
            title = string.gsub(title, Str(STR.HUAWEI), '')
            if item == nil then
                item = require("BonusWidget").create(lc.w(list), bonus, title)
            else
                item:setBonus(bonus, title)
            end
            item:registerCallback(function(bonus)
                local result = ClientData.claimBonus(bonus)
                V.showClaimBonusResult(bonus, result)
                self:showSystemTabFlag()
            end)

            return item
        end

        list:bindData(bonuses, setOrCreateItem, math.min(5, #bonuses))

        for i = 1, list._cacheCount do
            local item = setOrCreateItem(nil, bonuses[i])
            list:pushBackCustomItem(item)
        end

        list:checkEmpty(Str(STR.LIST_EMPTY_NO_BONUS))

    elseif self._focusTabIndex == _M.SystemMail.send then        
        local bonuses = P._playerBonus._sendBonuses

        local setOrCreateItem = function(item, bonus)
            local title = bonus._title or string.format(Str(bonus._info._nameSid), bonus._info._val)
            title = string.gsub(title, Str(STR.HUAWEI), '')
            if item == nil then
                item = require("BonusWidget").create(lc.w(list), bonus, title)
            else
                item:setBonus(bonus, title)
            end
            item:registerCallback(function(bonus)
                local result = ClientData.claimBonus(bonus)
                V.showClaimBonusResult(bonus, result)
                self:showSystemTabFlag()
            end)

            return item
        end

        list:bindData(bonuses, setOrCreateItem, math.min(5, #bonuses))

        for i = 1, list._cacheCount do
            local item = setOrCreateItem(nil, bonuses[i])
            list:pushBackCustomItem(item)
        end

        list:checkEmpty(Str(STR.LIST_EMPTY_NO_BONUS))

    elseif self._focusTabIndex == _M.SystemMail.announce then
        local mails = P._systemAnnouncement
        list:bindData(mails, function(item, mail) item:setMail(mail) end, math.min(5, #mails))

        for i = 1, list._cacheCount do
            local item = SystemMailItem.create(lc.w(list), mails[i])
            list:pushBackCustomItem(item)
        end
        
        P._playerMail:clearNewAnnouncements()
    elseif self._focusTabIndex == _M.SystemMail.union then
        local mails = P._playerMail:getMailList(Mail_pb.PB_MAIL_UNION)
        list:bindData(mails, function(item, mail) item:updateMail(mail) end, math.min(5, #mails))

        for i = 1, list._cacheCount do
            local item = MsgMailItem.create(lc.w(list), mails[i])
            list:pushBackCustomItem(item)
        end
        
        P._playerMail:clearNewUnionMails()   
        list:checkEmpty(Str(STR.LIST_EMPTY_NO_MAIL))
    elseif self._focusTabIndex == _M.SystemMail.leave_message then
        local mails = P._playerMail:getMailList(Mail_pb.PB_MAIL_FRIEND, Mail_pb.PB_MAIL_NOTIFY)
        list:bindData(mails, function(item, mail) item:updateMail(mail) end, math.min(5, #mails))

        for i = 1, list._cacheCount do
            local item = MsgMailItem.create(lc.w(list), mails[i])
            list:pushBackCustomItem(item)
        end
        
        P._playerMail:clearNewMsgMails()   
        list:checkEmpty(Str(STR.LIST_EMPTY_NO_MAIL))
    else
        local mails = P._playerMail:getMailList(Mail_pb.PB_MAIL_SYSTEM)
        list:bindData(mails, function(item, mail) item:setMail(mail) end, math.min(5, #mails))

        for i = 1, list._cacheCount do
            local item = SystemMailItem.create(lc.w(list), mails[i], true)
            list:pushBackCustomItem(item)
        end
        
        P._playerMail:clearNewNoticeMails()
        list:checkEmpty(Str(STR.LIST_EMPTY_NO_NOTICE))
    end
    
    --list:refreshView()
    list:gotoTop()
    
    self:showSystemTabFlag()
end

function _M:onMail(event)
    local PlayerMail = require("PlayerMail")
    if event == PlayerMail.Event.mail_list_dirty then
        self:refreshSystemMails()    
        self:showSystemTabFlag()
    end
end

function _M:onServerBonus()
    self:refreshSystemMails()    
    self:showSystemTabFlag()
end

return _M