local _M = class("CheckinForm", require("BaseForm"))

local FORM_SIZE = cc.size(1024, 720)
local TAB_BUTTON_AREA_SIZE = cc.size(940, 176)

_M.CheckinTypes = {
    Data.CheckinType.month_checkin,
    Data.CheckinType.week_checkin,
    Data.CheckinType.month_card,
    Data.CheckinType.novice,
    Data.CheckinType.online,
}

function _M.create(tabIndex)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(tabIndex)
    
    return panel
end

function _M:init(tabIndex)
    _M.super.init(self, FORM_SIZE, Str(STR.CHECKIN_CENTER), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

    self._resNames = ClientData.loadLCRes("res/activity.lcres")

    local buttonBG = lc.createSprite{_name = "img_blank", _crect = cc.rect(1, 1, 1, 1), _size = TAB_BUTTON_AREA_SIZE}    
    lc.addChildToPos(self._form, buttonBG, cc.p(lc.w(self._form) / 2, lc.h(buttonBG) / 2 + 10), 1)
    self._buttonBG = buttonBG

    local items = {}
    self._buttons = {}    
    for i = 1, #_M.CheckinTypes do
        local checkinType = _M.CheckinTypes[i]

        local item = ccui.Widget:create()
        item:setContentSize(124, 128)
        table.insert(items, item)

        local button = V.createShaderButton('checkin_button_unfocus',
            function(sender) self:showTab(i) end)
        lc.addChildToPos(item, button, cc.p(lc.w(item) / 2, lc.h(button) / 2))
        table.insert(self._buttons, button)

        local icon = lc.createSprite(string.format("checkin_button%d", checkinType))
        lc.addChildToPos(button, icon, cc.p(lc.w(button) / 2, lc.h(button) / 2 + 4))

        local label = V.createBMFont(V.BMFont.huali_26, Str(STR.CHECKIN_MONTH + checkinType - 1))
        label:setColor(lc.Color3B.yellow)
        lc.addChildToPos(button, label, cc.p(lc.w(button) / 2, 20))
    end

    lc.addNodesToCenterH(buttonBG, items, 20)

    self._focusTabIndex = tabIndex or 1

    self:showTab(self._focusTabIndex)

    return true
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}

    local listener = lc.addEventListener(Data.Event.bonus_dirty, function(event)
        local bonus = event._data
        local type = bonus._type
        if type == Data.BonusType.vip_daily then
            self:updateTabFlag(Data.CheckinType.vip)
        elseif type == Data.BonusType.month_card then
            self:updateTabFlag(Data.CheckinType.month_card)
        elseif type == Data.BonusType.week_checkin then
            self:updateTabFlag(Data.CheckinType.week_checkin)
        elseif type == Data.BonusType.month_checkin then            
            self:updateTabFlag(Data.CheckinType.month_checkin)
        elseif type == Data.BonusType.login then
            self:updateTabFlag(Data.CheckinType.novice)
        elseif type == Data.BonusType.online then
            self:updateTabFlag(Data.CheckinType.online)
        end
    end)
    table.insert(self._listeners, listener)

    self:updateTabFlag(Data.CheckinType.vip)     
    self:updateTabFlag(Data.CheckinType.month_card)        
    self:updateTabFlag(Data.CheckinType.week_checkin)                    
    self:updateTabFlag(Data.CheckinType.month_checkin)        
    self:updateTabFlag(Data.CheckinType.novice) 
    self:updateTabFlag(Data.CheckinType.online)
    
    listener = lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end) 
    table.insert(self._listeners, listener)
    
    ClientData.addMsgListener(self, function(msg) self:onMsg(msg) end, 0)
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
    ClientData.removeMsgListener(self)
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    ClientData.unloadLCRes(self._resNames)
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_common_bg.jpg"))    
end

function _M:show()
    _M.super.show(self)
    
    V._checkinForm = self
    ClientData.setActivityShowed(Data.PurchaseType.checkin)
end

function _M:hide()
    _M.super.hide(self)
    
    V._checkinForm = nil
end

function _M:showTab(tabIndex)
    local newBgName = self:getBgName(tabIndex)
    if self._focusTabIndex ~= nil then
        self._buttons[self._focusTabIndex]:setEnabled(true)
        self._buttons[self._focusTabIndex]:loadTextureNormal('checkin_button_unfocus', ccui.TextureResType.plistType)

        if self._activityPanel ~= nil then
            self._activityPanel:removeFromParent()
            self._activityPanel = nil
        end             

        local oldBgName = self:getBgName(self._focusTabIndex)        
        if oldBgName ~= newBgName then
            lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename(oldBgName))            
        end
    end

    self._buttons[tabIndex]:setEnabled(false)
    self._buttons[tabIndex]:loadTextureNormal('checkin_button_focus', ccui.TextureResType.plistType)

    local checkinType = _M.CheckinTypes[tabIndex]
    self._activityPanel = require(self:getPanelName(checkinType)).create(newBgName, cc.size(lc.w(self._form) - _M.LEFT_MARGIN - _M.RIGHT_MARGIN, 512))
    lc.addChildToPos(self._frame, self._activityPanel, cc.p(lc.w(self._frame) / 2, lc.h(self._frame) - lc.h(self._activityPanel) / 2 - _M.TOP_MARGIN), -1)

    self._focusTabIndex = tabIndex
end

function _M:updateTabFlag(checkinType)
    local playerBonus = ClientData._player._playerBonus

    local number = 0
    if checkinType == Data.CheckinType.vip then
        number = playerBonus:getVipDailyBonusFlag()
    elseif checkinType == Data.CheckinType.month_card then
        number = playerBonus:getMonthCardBonusFlag()
    elseif checkinType == Data.CheckinType.week_checkin then
        number = playerBonus:getWeekCheckinBonusFlag()
    elseif checkinType == Data.CheckinType.month_checkin then
        number = playerBonus:getMonthCheckinBonusFlag()
    elseif checkinType == Data.CheckinType.novice then
        number = playerBonus:getLoginBonusFlag()
    elseif checkinType == Data.CheckinType.online then
        number = playerBonus:getOnlineTaskBonusFlag()
    end

    local tabIndex = 0
    for i = 1, #_M.CheckinTypes do
        if _M.CheckinTypes[i] == checkinType then
            tabIndex = i
        end
    end
    if tabIndex > 0 then
        local button = self._buttons[tabIndex]
        V.checkNewFlag(button, number, 24)
    end
end

function _M:getPanelName(index)
    if index == Data.CheckinType.vip then
        return "VIPPanel"
    elseif index == Data.CheckinType.month_card then
        return "MonthCardPanel"
    elseif index == Data.CheckinType.week_checkin then  
        return "WeekCheckinPanel"
    elseif index == Data.CheckinType.month_checkin then
        return "MonthCheckinPanel"
    elseif index == Data.CheckinType.novice then
        return "NovicePanel"
    elseif index == Data.CheckinType.online then
        return "OnlinePanel"
    end    
end

function _M:getBgName(index)
    return "res/jpg/activity_common_bg.jpg"
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == SglMsgType_pb.PB_TYPE_USER_CLAIM_GIFT then 
        V.getActiveIndicator():hide()
        require("RewardPanel").create(msg.Extensions[User_pb.SglUserMsg.user_claim_gift_resp]):show()

        return true
    end

    return false 
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "show tab novice" then
        GuideManager.setOperateLayer(self._buttons[Data.CheckinType.novice])
    elseif curStep == "leave giftcenter" then
        GuideManager.setOperateLayer(self._btnBack)
    else
        return
    end    
    event:stopPropagation()
end

return _M