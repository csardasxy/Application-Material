local _M = class("MenuPanel", lc.ExtendUIWidget)

local UnionWidget = require("UnionWidget")

local TROPHY_SIZE = cc.size(130, 30)
local SHIELD_SIZE = cc.size(130, 30)

function _M.create()
    local menu = _M.new(lc.EXTEND_LAYOUT)
    menu:setContentSize(lc.Director:getVisibleSize())
    menu:init()

    return menu
end

function _M:onRelease()
    self:removeAllChildren() 
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
    self._listeners = {}
end

function _M:onEvent(event)
    if event == Data.Event.level_dirty or event == Data.Event.login or event == Data.Event.character_dirty then
        self._userArea:setLevel(P._characters[P:getCharacterId()]._level)
    end
    
    if event == Data.Event.vip_dirty or event == Data.Event.login then
        self._userArea:setAvatar(P)
        self._userArea:setVip(P._vip)

        --self:checkActivityButtons()
    end
    
    if event == Data.Event.name_dirty or event == Data.Event.login then
        self._userArea:setName(P._name)
    end
    
    if event == Data.Event.icon_dirty or event == Data.Event.login or event == Data.Event.avatar_frame_dirty or event == Data.Event.crown_dirty then
        self._userArea:setAvatar(P)

        if event == Data.Event.avatar_frame_dirty then
            self._userArea:setVip(P._vip)
        end
    end 
    
    if event == Data.Event.login then
        self:updateButtonFlags()

        self:checkActScore()
        --self:checkActivityButtons()
    end
end

function _M:init()
    self:initUser()
    self:initButtons()

    self:updateButtonFlags()

    self._listeners = {}

    local events = 
    {
        Data.Event.level_dirty,
        Data.Event.vip_exp_dirty,
        Data.Event.name_dirty,
        Data.Event.exp_dirty,
        Data.Event.icon_dirty,
        Data.Event.avatar_frame_dirty,
        Data.Event.login,
        Data.Event.character_dirty,
        Data.Event.crown_dirty,
    }
    for i = 1, #events do
        local listener = lc.addEventListener(events[i], function(event) 
            self:onEvent(events[i])
        end)
        table.insert(self._listeners, listener)
    end 
    
    local listener = lc.addEventListener(Data.Event.mail, function(event)
        local PlayerMail = require("PlayerMail")
        if event._event == PlayerMail.Event.mail_list_dirty then
            self:updateMailFlag()            
        end
    end)
    table.insert(self._listeners, listener) 

    local scoreEvents = {
        Data.Event.ghost_dirty,
        Data.Event.blood_jade_dirty
    }
    for _, evt in ipairs(scoreEvents) do
        listener = lc.addEventListener(evt, function(event)
            if self._actScoreArea then
                local resId = (P._playerActivity._actScore._type % 100)
                self._actScoreArea._label:setString(P:getItemCount(resId))
            end
        end)
        table.insert(self._listeners, listener)
    end
    
    listener = lc.addEventListener(Data.Event.bonus_dirty, function(event)
        local bonus = event._data
        local type = bonus._type      
        if type == Data.BonusType.vip_daily
        or type == Data.BonusType.month_card
        or type == Data.BonusType.week_checkin
        or type == Data.BonusType.month_checkin
        or type == Data.BonusType.online
        or type == Data.BonusType.login then
           -- self:updateCheckinBonusFlag()
            
        elseif type == Data.BonusType.fund_level or type == Data.BonusType.fund_all then
            self:updateActivityFlag()

        elseif type == Data.BonusType.fund_task then
            self:updateDailyActiveFlag()

        else
--            self:updateAchieveFlag()
        end
    end)
    table.insert(self._listeners, listener)

    --listener = lc.addEventListener(Data.Event.union_fund_dirty, function() self:updateFundBonusFlag() end)
    --table.insert(self._listeners, listener)
    
    listener = lc.addEventListener(Data.Event.server_bonus_list_dirty, function(event) 
        self:updateMailFlag()
    end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(Data.Event.daily_active_dirty, function(event) 
        self:updateDailyActiveFlag()
    end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(Data.Event.fund_task_dirty, function(event) 
        self:updateDailyActiveFlag()
    end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(Data.Event.log_dirty, function(event)
        local PlayerLog = require("PlayerLog")
        if event._event == PlayerLog.Event.defense_log_dirty then
            self:updateBattleFlag()
        end
    end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end)  
    table.insert(self._listeners, listener)

    table.insert(self._listeners, lc.addEventListener(Data.Event.time_hour_changed, function(event) self:onTimeHourChanged() end))
    table.insert(self._listeners, lc.addEventListener(GuideManager.Event.finish, function(event) self:onGuideFinish(event) end))

    --table.insert(self._listeners, lc.addEventListener(Data.Event.gift_open, function(event) self:checkActivityButtons() end))
    --table.insert(self._listeners, lc.addEventListener(Data.Event.gift_closed, function(event) self:checkActivityButtons() end))

    self:setMode()

    
end

function _M:initUser()
    local userArea = UserWidget.create(P, bor(UserWidget.Flag.LEVEL_NAME, UserWidget.Flag.VIP, UserWidget.Flag.CLICKABLE), 1.0, false, true)
    userArea._nameArea._level:setVisible(true)
    userArea._nameArea._level:setString('Lv.'..P._characters[P:getCharacterId()]._level)
    lc.addChildToPos(self, userArea, cc.p(lc.w(userArea) / 2 + 12, lc.h(self) - lc.h(userArea) / 2 - 12))
    self._userArea = userArea

    self:checkActScore()
end

function _M:initButtons()
    local resourcePanel = V.getResourceUI()

    local btnSize = lc.frameSize("img_icon_checkin")
    local y, margin = lc.bottom(resourcePanel) - 12 - btnSize.height / 2, 8
    local color = V.COLOR_BUTTON_TITLE

    local x = V.SCR_W - btnSize.width / 2 - 12

    local bgTop = lc.createSprite{_name = "main_bg_top", _crect = cc.rect(8, 0, 2, 62), _size = cc.size(V.SCR_W, 62)}
    lc.addChildToPos(self, bgTop, cc.p(lc.cw(self), lc.h(self) - lc.ch(bgTop)), -2)

    self._btnActivity = self:addButton("img_icon_activity", true, cc.p(x, lc.bottom(resourcePanel) - 130))

    self._btnIllustration = self:addButton("img_icon_illustration", false, cc.p(ClientView.SCR_W - btnSize.width / 2 - 12, y))
    
    self._btnMail = self:addButton("img_icon_mail", {str = Str(STR.MAIL), clr = color}, cc.p(lc.x(self._btnIllustration) - btnSize.width - 24, y))
    
    self._btnCheckin = self:addButton("img_icon_checkin", {str = Str(STR.CHECKIN), clr = color}, cc.p(lc.x(self._btnMail) - btnSize.width - 24, y))
    
    self:updateDateDisplay()

    self._btnRank = self:addButton("img_icon_rank", {str = Str(STR.RANK), clr = color}, cc.p(lc.x(self._btnCheckin) - btnSize.width - 24, y))
    
    --self._btnHelp = self:addButton("img_icon_activity", {str = Str(STR.HELP), clr = color}, cc.p(lc.x(self._btnDailyActive) - btnSize.width - 4, y))
    
    if ClientData.isYYBNew() then
        self._btnQQBBS = self:addButton("img_icon_qq_bbs", cc.p(lc.x(self._btnDailyActive) - btnSize.width - 4, y))
        if ClientData.isYYBLoginByQQ() then
            self._btnQQVPLUS = self:addButton("img_icon_qq_vplus", cc.p(lc.x(self._btnQQBBS) - btnSize.width - 4, y))
            self._btnLeague = self:addButton("img_icon_league", cc.p(lc.x(self._btnQQVPLUS) - btnSize.width - 8, y - 8))
        else
            self._btnLeague = self:addButton("img_icon_league", cc.p(lc.x(self._btnQQBBS) - btnSize.width - 8, y - 8))
        end

        --self._btnHelp:setVisible(false)
    
    elseif lc.PLATFORM == cc.PLATFORM_OS_IPHONE or lc.PLATFORM == cc.PLATFORM_OS_IPAD then
        --self._btnLive = self:addButton("img_icon_live", {str = '', clr = color}, cc.p(lc.x(self._btnDailyActive) - btnSize.width - 4, y - 8))
        self._btnLeague = self:addButton("img_icon_league", cc.p(lc.x(self._btnDailyActive) - btnSize.width - 8, y - 8))
    end

    self._btnFirstCharge = V.createShaderButton(nil, function(sender) self:onButtonClick(sender) end)   
    self._btnFirstCharge:setContentSize(cc.size(120, 120))
    lc.addChildToPos(self, self._btnFirstCharge, cc.p(lc.right(self._userArea) + lc.cw(self._btnFirstCharge) + 10, lc.y(self._userArea))) 

    labelStr = V.createBMFont(V.BMFont.huali_26, Str(STR.FIRST_RECHARGE_BONUS))
    lc.addChildToPos(self._btnFirstCharge, labelStr, cc.p(lc.cw(self._btnFirstCharge), 20), 1)
    labelStr:setColor(V.COLOR_BUTTON_TITLE)
    self._btnFirstCharge._label = labelStr

    self._btnCumulativeRecharge = V.createShaderButton(nil, function(sender) self:onButtonClick(sender) end)
    self._btnCumulativeRecharge:setContentSize(cc.size(120, 120))
    lc.addChildToPos(self, self._btnCumulativeRecharge, cc.p(lc.right(self._btnFirstCharge) + lc.cw(self._btnCumulativeRecharge) + 10, lc.y(self._userArea)))

    local activityInfo = ClientData.getActivityByType(603)
    labelStr = V.createBMFont(V.BMFont.huali_26, activityInfo and Str(activityInfo._nameSid) or '')
    lc.addChildToPos(self._btnCumulativeRecharge, labelStr, cc.p(lc.cw(self._btnCumulativeRecharge), 20), 1)
    labelStr:setColor(V.COLOR_BUTTON_TITLE)
    self._btnCumulativeRecharge._label = labelStr

    local bgBottom = lc.createSprite{_name = "main_bg_bottom", _crect = cc.rect(18, 0, 2, 68), _size = cc.size(V.SCR_W, 68)}
    lc.addChildToPos(self, bgBottom, cc.p(lc.cw(self), lc.ch(bgBottom)))


    self._btnShop = self:addButton("img_icon_shop", false, cc.p(x - 10, btnSize.height - 20 ))
    self._btnBackPack = self:addButton("img_icon_bag", false, cc.p(lc.x(self._btnShop) - btnSize.width - 50, lc.y(self._btnShop)))
    self._btnUnion = self:addButton("img_icon_union", false, cc.p(lc.x(self._btnBackPack) - btnSize.width - 50, lc.y(self._btnShop)))
    self._btnDailyActive = self:addButton("img_icon_task", false, cc.p(lc.x(self._btnUnion) - btnSize.width - 50, lc.y(self._btnShop)))
    self._btnGuidance = self:addButton("img_icon_guide", false, cc.p(lc.x(self._btnDailyActive) - btnSize.width - 50, lc.y(self._btnShop)))
    
    self._btnTask = V.createShaderButton("img_btn_achievement", function(sender) self:onButtonClick(sender) end)
    self._btnTask:setAnchorPoint(cc.p(0, 0))
    self._btnTask:setPosition(10, 0)
    self:addChild(self._btnTask)
    self._btnTask:setDisabledShader(V.SHADER_DISABLE)
    self._btnTask:setEnabled(false)

    self._btnCharacter = self:addButton("img_btn_character", {str = Str(STR.CHARACTER), offY = 10}, cc.p(lc.right(self._btnTask) + 10 + btnSize.width, lc.y(self._btnShop)))

    if P._playerActivity._actFestivalTask and Data._activityTaskInfo._pvp then
        local matchType, btn = Data._activityTaskInfo._pvp._param[1][1]
        local label = {str = Str(STR.SNOWBALL_FIGHT + matchType - 1), offY = 10}
        if matchType == 1 then
            btn = self:addButton("img_btn_snowball", label)
        end

        if btn then
            btn:setPosition(lc.w(self) - lc.w(btn) / 2 - 14, lc.top(self._btnCopy) + lc.h(btn) / 2 + 6)
            btn._matchType = matchType
            self._btnActivityPvp = btn
        end
    end
    
    -- activity related buttons
    --self:checkActivityButtons()


    --TODO
    self._btnGuidance:setVisible(false)
    
    self._btnShop:setDisabledShader(V.SHADER_DISABLE)
    self._btnShop:setEnabled(false)
    
    self._btnCheckin:setDisabledShader(V.SHADER_DISABLE)
    self._btnCheckin:setEnabled(false)
    self._btnActivity:setVisible(false)
end

function _M:checkActScore()
    if self._actScoreArea then
        self._actScoreArea:getParent():removeFromParent()
        self._actScoreArea = nil
    end

    -- Check activity score resources
    local actInfo = P._playerActivity._actScore
    if actInfo then
        local mainType, resType = actInfo:getTypes()
        local btn = V.createShaderButton(nil, function() require("DescForm").create({_infoId = resType, _count = P:getItemCount(resType)}):show() end)

        local area = V.createResIconLabel(150, string.format("img_icon_res%d_s", resType))
        area._label:setString(P:getItemCount(resType))
        self._actScoreArea = area

        local btnInfo = V.createShaderButton("img_btn_squarel_s_1")
        btnInfo:addIcon("img_icon_i")
        btnInfo:setTouchEnabled(false)
        lc.addChildToPos(area, btnInfo, cc.p(lc.w(area), lc.h(area) / 2))

        btn:setContentSize(lc.right(btnInfo), lc.h(area))
        lc.addChildToPos(btn, area, cc.p(lc.w(area) / 2, lc.h(area) / 2))
        lc.addChildToPos(self._userArea, btn, cc.p(lc.right(self._userArea._avatar) + 42 + lc.w(btn) / 2, lc.bottom(self._userArea._nameArea) - 10 - lc.h(btn) / 2))
    end
end

function _M:checkActivityButtons()
    if ClientData.isAppStoreReviewing() then return end

    local addActivityButton = function(str, y, effectName)
        local btn, size = V.createShaderButton(nil, function(sender) self:onButtonClick(sender) end), cc.size(90, 90)
        btn:setContentSize(size)
        btn:setTouchRect(cc.rect(-10, -10, size.width + 20, size.height + 20))

        local label = V.createBMFont(V.BMFont.huali_20, str)
        label:setScale(0.8)
        label:setColor(lc.Color3B.yellow)
        lc.addChildToPos(btn, label, cc.p(lc.w(btn) / 2, 20))
        btn._label = label
        
        btn.createBones = function(btn)
            if btn._bones == nil then
                local bones = cc.DragonBonesNode:createWithDecrypt("res/effects/huodong.lcres", "huodong", "huodong")
                bones:gotoAndPlay(effectName)
                lc.addChildToCenter(btn, bones, -1)
                btn._bones = bones
            end
        end

        btn.removeBones = function(btn)
            if btn._bones then
                btn._bones:removeFromParent()
                btn._bones = nil
            end
        end

        btn:createBones()

        lc.addChildToPos(self, btn, cc.p(60, y))
        return btn
    end

    --TODO--
    --local bonus = P._playerBonus._cardBonus
    --if not bonus._isClaimed then
    if false then
        if self._btnCardBonus == nil then
            local btnCardBonus = addActivityButton("", 0, "effect1")
            self._btnCardBonus = btnCardBonus
        end

        local btn = self._btnCardBonus
        if bonus._value < bonus._info._val then
            btn:scheduleUpdateWithPriorityLua(function(dt)
                local timeRemain = bonus._info._val * 3600 - (ClientData.getCurrentTime() - P._regTime)
                if timeRemain < 0 then
                    btn._label:setString(Str(STR.CLAIM_DAQIAO))
                    V.checkNewFlag(btn, true, 6, 6)
                    btn:unscheduleUpdate()
                else
                    btn._label:setString(ClientData.formatTime(timeRemain))
                end

                if timeRemain < 0 then
                    btn:unscheduleUpdate()
                end
            end, 0)
        else
            btn:unscheduleUpdate()
            btn._label:setString(Str(STR.CLAIM_DAQIAO))
        end

        V.checkNewFlag(btn, bonus._value >= bonus._info._val, 6, 6)
        btn:setVisible(P._guideID >= 500)

    else
        if self._btnCardBonus then
            self._btnCardBonus:removeFromParent()
            self._btnCardBonus = nil
        end
    end
    
end

function _M:onScheduler()
    self:updateDepotFlag()
end

function _M:onEnter()

    local bones = cc.DragonBonesNode:createWithDecrypt("res/effects/huodong.lcres", "huodong", "huodong")
    bones:gotoAndPlay("effect1")
    lc.addChildToCenter(self._btnFirstCharge, bones)
    self._btnFirstCharge._bones = bones

    local bones = cc.DragonBonesNode:createWithDecrypt("res/effects/huodong.lcres", "huodong", "huodong")
    bones:gotoAndPlay("effect4")
    lc.addChildToCenter(self._btnCumulativeRecharge, bones)
    self._btnCumulativeRecharge._bones = bones
    self._btnCumulativeRecharge:setVisible(ClientData.isActivityValid(ClientData.getActivityByType(603)))
    
--    self._btnActivityExchange:setVisible(false)
    self:scheduleUpdateWithPriorityLua(function(dt) self:onScheduler() end, 0)
    self:updateActivityFlag()
    
    self._listeners = {}
    self._listeners.unionFlag = lc.addEventListener(Data.Event.message, function(event) 
        if event._event == P._playerMessage.Event.msg_new then
            self:updateUnionFlag() 
        end
    end)

    if self._btnCardBonus then
        self._btnCardBonus:createBones()
    end

end

function _M:onExit()
    --self._btnBattle._bones:removeFromParent()
    --self._btnTask._bones:removeFromParent()
    --self._btnActivity._bones:removeFromParent()
    self._btnFirstCharge._bones:removeFromParent()
    self._btnFirstCharge._bones = nil
    self._btnCumulativeRecharge._bones:removeFromParent()
    self._btnCumulativeRecharge._bones = nil

    if self._btnCardBonus then
        self._btnCardBonus:removeBones()
    end

end

function _M:addButton(btnName, isPanel, pos)
    local button = V.createShaderButton(btnName, function(sender) self:onButtonClick(sender) end, pos.x, pos.y)
    
    if isPanel then
        --button:setTouchRect(cc.rect(-18, -12, lc.w(button) + 36, lc.h(button) + 38))
        --lc.addChildToCenter(button, lc.createSprite('img_btn_panel'), -1)
    end
    self:addChild(button)
    return button
end

function _M:updateButtonFlags()
    self:updateMailFlag()
    self:updateAchieveFlag(P._playerBonus._bonusCount)
    self:updateBattleFlag()
    self:updateActivityFlag()
    self:updateCheckinBonusFlag()
    self:updateDailyActiveFlag()
    self:updateTeachFlag()
    self:updateUnionFlag()
    self:updateDepotFlag()
end

function _M:updateMailFlag()
    local number = P._playerMail:getNewMsgMails() + P._playerMail:getNewSystemMails() + P._playerMail:getNewUnionMails()
    if number > 0 then
        if self._btnMail._flag == nil then
            self._btnMail._flag = cc.Sprite:createWithSpriteFrameName("img_new")
            self._btnMail._flag:setPosition(lc.w(self._btnMail) - 12, lc.h(self._btnMail) - 8)            
            self._btnMail:addChild(self._btnMail._flag)
        
            self._btnMail._flag._value = V.createBMFont(V.BMFont.huali_20, "")
            self._btnMail._flag._value:setScale(0.8)
            lc.addChildToCenter(self._btnMail._flag, self._btnMail._flag._value)
        end
        self._btnMail._flag._value:setString(string.format("%d", number))
    else
        if self._btnMail._flag ~= nil then
            self._btnMail._flag:removeFromParent()
            self._btnMail._flag = nil
        end    
    end
end

function _M:updateDailyActiveFlag()
    local number = P._playerBonus:getDailyActiveBonusFlag() + P._playerBonus:getFundTasksFlag()
    V.checkNewFlag(self._btnDailyActive, number, 32)
end

function _M:updateAchieveFlag(count)
    local number = count or P._playerBonus:getAchieveBonusFlag()
    V.checkNewFlag(self._btnTask, number, 28, -18)
end

function _M:updateBattleFlag()
    local number = P._playerLog:getNewDefenseLogCount()
    --V.checkNewFlag(self._btnBattle, number, -8, -30)
end

function _M:updateActivityFlag()
--temperary

self._btnFirstCharge:setVisible(false)

    local firstNumner =  P._playerBonus:getFirstRechargeFlag() + P._playerBonus:getRecharge7Flag()
    local number = firstNumner + P._playerBonus:getFundBonusFlag() + P._playerBonus:getInviteBonusFlag() + P._playerBonus:getReturnPackageFlag()
    
    V.checkNewFlag(self._btnActivity, number, 20, -20)

    if not ClientData.isGemRecharged() or P._playerBonus:getFirstRechargeFlag() > 0 then
        self._btnFirstCharge._label:setString(Str(STR.FIRST_RECHARGE_BONUS))
        if self._btnFirstCharge._bones then
            self._btnFirstCharge._bones:gotoAndPlay("effect2")
        end
        V.checkNewFlag(self._btnFirstCharge, firstNumner, 20, -20)

    elseif not ClientData.isRecharged(Data.PurchaseType.package_6) then
        self._btnFirstCharge._label:setString(Str(STR.RECHARGE_PACKAGE))
        if self._btnFirstCharge._bones then
            self._btnFirstCharge._bones:gotoAndPlay("effect3")
        end
        V.checkNewFlag(self._btnFirstCharge, 0, 20, -20)

    elseif P._playerBonus:getRecharge7Flag() > 0 or (not ClientData.isRecharged(Data.PurchaseType.daily_1) and not ClientData.isRecharged(Data.PurchaseType.daily_2)) then
        self._btnFirstCharge._label:setString(Str(STR.FIRST_RECHARGE_BONUS_2))
        if self._btnFirstCharge._bones then
            self._btnFirstCharge._bones:gotoAndPlay("effect2")
        end
        V.checkNewFlag(self._btnFirstCharge, firstNumner, 20, -20)

    else
        self._btnFirstCharge:setVisible(false)
        self._btnCumulativeRecharge:setPosition(cc.p(self._btnFirstCharge:getPosition()))
    end
end

function _M:updateCheckinBonusFlag()
    --local number = P._playerBonus:getCheckinBonusFlag()
    --V.checkNewFlag(self._btnCheckin, number, 50)
end

function _M:updateDateDisplay()
    --[[
    local btnCheckin = self._btnCheckin
    if btnCheckin._date == nil then
        local date = cc.Label:createWithTTF("0", V.TTF_FONT, V.FontSize.S2)
        date:setRotation(20)
        date:setColor(V.COLOR_TEXT_DARK)
        lc.addChildToPos(btnCheckin, date, cc.p(38, 35))

        btnCheckin._date = date
    end

    local date = os.date("*t", ClientData.getCurrentTime())
    btnCheckin._date:setString(string.format("%d", date.day))
    ]]
end

function _M:updateUnionFlag()
    local number = P._playerMessage:getNewUnion()
    V.checkNewFlag(self._btnUnion, number, 32)
end

function _M:updateDepotFlag()
    --[[
    local number = P:getDailyGoldFlag()
    V.checkNewFlag(self._btns[1], number, -2, -124)
    ]]

    -- props    
    local count = 0
    for _, v in pairs(P._propBag._props) do
        if v._info._id == 7001 or v._info._id == 7003 then
            count = v._num + count
        end
    end
    V.checkNewFlag(self._btnBackPack, count, 32)
end

function _M:updateTeachFlag()
    local number = 0
    for i = 1, 4 do number = number + ClientData.getUnpassTeachCount(i) end
    local flagBg = V.checkNewFlag(self._btnGuidance, number, 25, 0)
    if flagBg ~= nil then flagBg:setSpriteFrame('img_new') end
end

function _M:setMode(mode)
    self._mode = mode

    if ClientData.isAppStoreReviewing() then
        self._btnCharacter:setVisible(false)
        self._btnBattle:setVisible(false)
        self._btnGuidance:setVisible(false)
        self._btnIllustration:setVisible(false)
        --self._btnHelp:setVisible(false)
        self._btnActivity:setVisible(false)
        self._btnFirstCharge:setVisible(false)
        self._btnCumulativeRecharge:setVisible(false)
        self._btnCheckin:setVisible(false)
        self._btnCopy:setVisible(false)
        self._btnTask:setVisible(false)
        self._btnDailyActive:setVisible(false)
        if self._btnLive then self._btnLive:setVisible(false) end
        if self._btnLeague then self._btnLeague:setVisible(false) end
        self._btnRank:setPosition(self._btnCheckin:getPosition())
    end 

    --[[
    if P:getMaxCharacterLevel() > 15 then
        self._btnHelp:setVisible(false)
    end
    ]]
    
    --self:checkActivityButtons()
end

function _M:onButtonClick(sender)
    if P._guideID < 103 then return end

    if not ClientData.checkBtnClick() then return end
    
    if sender == self._btnMail then
       require("MailForm").create():show()

    elseif sender == self._btnDailyActive then
        require("DailyActiveForm").create():show()
   
    elseif sender == self._btnBattle then
        --[[
        if P._level < Data._globalInfo._unlockFindMatch then
            V.showHelpForm(Str(STR.FIND_TITLE)..string.format(Str(STR.BRACKETS_S), string.format(Str(STR.UNLOCK_LEVEL), Data._globalInfo._unlockFindMatch)), Data.HelpType.seek)            
            return
        end

        lc.pushScene(require("FindScene").create(sender._index))
        sender._index = nil
        ]]
        require("TravelPanel").create():show()

    elseif sender == self._btnCity then
        if lc._runningScene._sceneId == ClientData.SceneId.union_world then
            lc.replaceScene(require("ResSwitchScene").create(self._sceneId, ClientData.SceneId.union))
        else
            ClientData._worldDisplay = ClientData._worldDisplayCity
            V.popScene()
        end

    elseif sender == self._btnCrusade then
        
    elseif sender == self._btnCopy then
        --require("CopySelectPanel").create():show()
        --[[
            
        end]]
        --[[
        if GuideManager.isGuideEnabled() then
            GuideManager.finishStep()
        end
        ]]
        V.tryGotoExpedition(true)
        
    elseif sender == self._btnGuidance then
        require("TeachingForm").create():show()

    elseif sender == self._btnActivityExchange then
        require("ActivityExchangeForm").create():show()

    elseif sender == self._btnTask then
        if lc._runningScene._sceneId == ClientData.SceneId.world then
            lc._runningScene:hideTab() 
        end

        require("AchieveForm").create():show()

    elseif sender == self._btnCharacter then
        require("ChangeCharacterPanel").create(false):show()
                
    elseif sender == self._btnActivity then
        lc.pushScene(require("ActivityScene").create())

    elseif sender == self._btnFirstCharge then
        local activityScene = require("ActivityScene")
        if not ClientData.isGemRecharged() or P._playerBonus:getFirstRechargeFlag() > 0 then
            lc.pushScene(activityScene.create(activityScene.Tab.first_recharge))
        elseif not ClientData.isRecharged(Data.PurchaseType.package_6) then
            lc.pushScene(activityScene.create(activityScene.Tab.package))
        else
            lc.pushScene(activityScene.create(activityScene.Tab.first_recharge))
        end

    elseif sender == self._btnCheckin then
        require("CheckinForm").create():show()

    elseif sender == self._btnRank then
        require("RankForm").create(Data.RankRange.lord):show()

    elseif sender == self._btnIllustration then
        require("IllustrationForm").create():show()

    --[[
    elseif sender == self._btnHelp then
        require("BattleHelpForm").create():show()
    ]]

    elseif sender == self._btnCardBonus then
        local bonus = P._playerBonus._cardBonus
        local canClaim, tip = bonus._value >= bonus._info._val
        if not canClaim then tip = "" end

        local form = require("ClaimForm").create(bonus, Str(bonus._info._nameSid), tip, function()
            local result = ClientData.claimBonus(bonus)
            V.showClaimBonusResult(bonus, result)
            --self:checkActivityButtons()
        end)

        form._btnClaim:setEnabled(canClaim)
        if not canClaim then
            form:scheduleUpdateWithPriorityLua(function(dt)
                local timeRemain = bonus._info._val * 3600 - (ClientData.getCurrentTime() - P._regTime)
                if timeRemain < 0 then
                    form:updateTip("")
                    form._btnClaim:setEnabled(true)
                    form:unscheduleUpdate()
                else
                    local tip = string.format(Str(STR.CLAIM_AFTER1), ClientData.formatPeriod(timeRemain, 3))
                    form:updateTip(tip)
                end
            end, 0)
        end
        form:show()

    elseif sender == self._btnActivityPvp then
        if P._level < Data._globalInfo._unlockFindMatch then
            V.showHelpForm(Str(STR.SNOWBALL_FIGHT)..string.format(Str(STR.BRACKETS_S), string.format(Str(STR.UNLOCK_LEVEL), Data._globalInfo._unlockFindMatch)), Data.HelpType.activity_pvp)            
            return
        end

        require("FindMatchForm").create(sender._matchType):show()
		
    elseif sender == self._btnLive then
        lc.App:openUrl("http://jdzc.smbbgo.com/jdzc_hy/index.html")

    elseif sender == self._btnLeague then
        lc.App:openUrl("http://jdzc.smbbgo.com/jddy_new/index.html")

    elseif sender == self._btnCumulativeRecharge then
        require("CumulativeRechargeForm").create():show()

    elseif sender == self._btnBackPack then
        require("DepotForm").create():show()

    elseif sender == self._btnShop then
        --require("DepotForm").create():show()

    elseif sender == self._btnUnion then
        local level = P._playerCity:getUnionUnlockLevel() 
        if P:getMaxCharacterLevel() < level then
            ToastManager.push(string.format(Str(STR.UNIONSCENE_LOCKED), level))
            return
        end--[[
        local curStep = GuideManager.getCurRecruiteStepName()
        if curStep == 'select union' then
            P._guideRecruiteID = P._guideRecruiteID + 1
            ClientData.sendGuideID(P._guideRecruiteID)
            GuideManager.stopGuide()
        end]]
        lc.pushScene(require("UnionScene").create())
    end

    -- Only remove soft guide finger
    if sender._softGuideFinger then
        GuideManager.releaseFinger()
    end
end

function _M:onTimeHourChanged()
    if self._btnCheckin then
        self:updateDateDisplay()
    end
end

function _M:onGuideFinish(event)
    if P._guideID == 500 then
        --self:checkActivityButtons()
    end
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "enter world" or curStep == "enter world first" then
        GuideManager.setOperateLayer(self._btnCrusade)
    elseif curStep == "leave world" then
        GuideManager.setOperateLayer(self._btnCity)
    elseif curStep == "enter select copy" then
        GuideManager.setOperateLayer(self._btnCopy)
    elseif string.find(curStep, "enter crusade") then
        local index = tonumber(curStep:split(' ')[3])
        self._btnBattle._index = index
        GuideManager.setOperateLayer(self._btnBattle)
    elseif curStep == "enter giftcenter" then
        GuideManager.setOperateLayer(self._btnCheckin)
    elseif curStep == "enter task" then
        GuideManager.setOperateLayer(self._btnTask)
    else
        return
    end
    
    event:stopPropagation()
end

return _M