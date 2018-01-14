local _M = class("BaseScene", lc.ExtendCCNode)

local MarqueeManager = require("MarqueeManager")

_M._sceneList = {}

function _M:init(sceneId)
    if lc._runningScene ~= nil and lc._runningScene._sceneId == sceneId then return false end

    if sceneId == ClientData.SceneId.city then
        V._cityScene = self            -- for future use
    elseif sceneId == ClientData.SceneId.world then
        V._worldScene = self
    end

    self._sceneId = sceneId
    self._needSyncData = false

    lc._runningScene = self
    table.insert(_M._sceneList, self)

    self._isGuideOnEnter = true        
    
    return true
end

function _M:onEnter()
    lc._runningScene = self

    local userData = {sceneId = self._sceneId, sync = self._needSyncData}

    if GuideManager.isGuideEnabled() then
        GuideManager.showOperateLayer(false)        -- Block all touches at the beginning

        userData.guideId = P._guideID
    end

    ClientData.sendUserEvent(userData)
    
    --print ("@@@@ Scene onEnter", self._sceneId)
    
    -- Attach marquee
    if self._sceneId == ClientData.SceneId.city or self._sceneId == ClientData.SceneId.world then
        MarqueeManager.attach(self)        
    else
        MarqueeManager.stop()
    end

    if self._needSyncData then
        self._needSyncData = false
        self:syncData()
    end
    
    self:checkUnlockModule()

    -- Guide step
    if self._isGuideOnEnter and GuideManager.isGuideEnabled() then
        if self._needGuideStartStep then
            GuideManager.startStepLater()
            self._needGuideStartStep = false
        else
            GuideManager.finishStepLater()
        end
    end

    NoticeManager.bindToRunningScene()
end

function _M:onExit()
    _M._lastSceneId = self._sceneId

    for _, v in pairs(ToastManager.Toasts) do
        v:removeFromParent()
    end

    MarqueeManager.unattach()
    NoticeManager.unbindFromRunningScene()

    local indicator = V.getActiveIndicator()
    if indicator._isShowing then
        indicator:hide()
    end
end

function _M:onCleanup()
    --print ("@@@@ Scene cleanup", self._sceneId)
    for i = 1, #_M._sceneList do
        if _M._sceneList[i] == self then
            table.remove(_M._sceneList, i)
            break
        end
    end

    if sceneId == ClientData.SceneId.city then
        V._cityScene = nil
    end
end

function _M:syncData()
    -- override in inherited scene
    --print ("@@@@ sync data", self._sceneId)
end

function _M:checkUnlockModule()
    -- override in inherited scene
end

function _M:reconnect(msg)
    if self._reloadDialog ~= nil then
        return
    end

    lc.log("[NETWORK] reconnect~~")

    -- show notice message and hide previous ones
    if msg ~= nil then
        if ClientData._heartbeatGapNoticeId ~= nil then
            NoticeManager.hide(ClientData._heartbeatGapNoticeId)
            ClientData._heartbeatGapNoticeId = nil
        end

        local richText = ccui.RichTextEx:create()
        richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_DARK, 255, msg, V.TTF_FONT, V.FontSize.S1))
        ClientData._heartbeatLostNoticeId = NoticeManager.show(richText, nil, ClientData._heartbeatLostNoticeId)
    end

    if self._sceneId == ClientData.SceneId.region then
        -- region scene, reconnect
        ClientData.reconnectRegionServer()
    elseif self._sceneId == ClientData.SceneId.loading then
        -- loading scene, goto region scene
        ClientData.switchToRegionScene()
    else
        -- if in battle scene, call battleScene:pause here
        if self._sceneId == ClientData.SceneId.battle then self:pause() end
        
        -- reconnect game server
        ClientData.reconnectGameServer()
        V.getActiveIndicator():show(Str(STR.CONNECTING))
    end        
end

function _M:reload(msgStatus)
    if msgStatus == SglMsg_pb.PB_STATUS_INVALID_VERSION then
        ClientData.switchToUpdateScene()
    else
        self:reconnect()
    end
end

function _M:showReloadDialog(str, msgStatus)
    if self._reloadDialog == nil then
        ClientData._isWorking = false

        self._reloadDialog = require("Dialog").showDialog(str, function()
            self._reloadDialog = nil
            self:reload(msgStatus)
        end, true)
    end
    
    -- If during guidance, pause it
    GuideManager.stopGuide()
end

-- msg & error --

function _M:onMsgErrorStatus(msg, msgStatus)
    local message = nil
    local msgType = msg.type
    local isSerious = false

    local userData = V.getActiveIndicator():hide()
    
    if msgStatus == SglMsg_pb.PB_STATUS_AUTHENTICATION_FAIL then
        message = Str(STR.AUTHENTICATION_FAIL)
        isSerious = true
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_INVALID_ARG then
        message = Str(STR.INVALID_ARG)
        isSerious = true
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_LOGIN_FAIL then
        message = Str(STR.LOGIN_FAIL)
        isSerious = true
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_USER_BAN_LOGIN then
        local timestamp = msg.Extensions[User_pb.SglUserMsg.user_ban_login_resp] / 1000
        if timestamp == 0 then
            message = Str(STR.BAN_LOGIN_FOREVER)
        else
            local date = os.date("*t", timestamp)
            message = string.format(Str(STR.BAN_LOGIN), string.format(Str(STR.DATE_FORMAT), date.year, date.month, date.day, date.hour))
        end
        isSerious = true

    elseif msgStatus == SglMsg_pb.PB_STATUS_SERVER_ERROR then
        message = Str(STR.SERVER_ERROR)
        isSerious = true
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_DATA_ERROR then
        message = Str(STR.DATA_ERROR)
        isSerious = true
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_OUT_OF_SYNC then
        message = Str(STR.OUT_OF_SYNC)
        if self._sceneId == ClientData.SceneId.battle then
            ClientData._needSendBattleDebugLog = true
        end
        isSerious = true
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_LOGIN_ELSEWHERE then
        message = Str(STR.LOGIN_ELSEWHERE)
        isSerious = true
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_BATTLE_ALREADY_SHARED then
        local pbShares = msg.Extensions[Battle_pb.SglBattleMsg.battle_share_resp]
        for _, pbShare in ipairs(pbShares) do
            P._playerLog:sendLogShared(pbShare.log.id)
        end

    elseif msgStatus == SglMsg_pb.PB_STATUS_USER_OFFLINE then
        message = Str(STR.OPPOSITE_OFFLINE)
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_OPPONENT_NOT_FOUND then
        local pbReward = msg.Extensions[World_pb.SglWorldMsg.world_opponent_not_found_resp]
        if self.onOpponentNotFound then self:onOpponentNotFound(pbReward) end
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_SERVER_MAINTENANCE then
        message = msg.Extensions[News_pb.SglNewsMsg.news_maintenance_resp] or Str(STR.SERVER_MAINTENANCE)
        isSerious = true
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_USER_UNDER_ATTACK then
        local resp = msg.Extensions[User_pb.SglUserMsg.user_under_attack_resp]
        if msgType == SglMsgType_pb.PB_TYPE_USER_LOGIN or msgType == SglMsgType_pb.PB_TYPE_USER_REGISTER then
            local nameStr = string.format(Str(STR.UNDER_ATTACKING), resp.name)
            V.getActiveIndicator():show(nameStr)
        else
            message = Str(STR.OPPONENT)..string.format(Str(STR.UNDER_ATTACKING), resp.name)
        end
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_BATTLE_WAIT then
        if ClientData._socketStatus == ClientData.SocketStatus.login then
            lc._runningScene:onBattleWait()
        else
            message = Str(STR.WAIT_BATTLE_RESULT_RETRY)
            isSerious = true
        end
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_BATTLE_TIMEOUT then
        message = Str(STR.BATTLE_ACTION_TIMEOUT)
        isSerious = true

    elseif msgStatus == SglMsg_pb.PB_STATUS_USER_ONLINE then
        message = Str(STR.OPPOSITE_ONLINE)
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_USER_SHILED then
        message = Str(STR.OPPOSITE_SHIELD)
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_ILLEGAL_NAME then
        local str = msg.Extensions[User_pb.SglUserMsg.user_illegal_input_resp]
        message = string.format(Str(STR.CONTAIN_ILLEGAL_NAME), str)

        local eventCustom = cc.EventCustom:new(Data.Event.invalid_input)
        lc.Dispatcher:dispatchEvent(eventCustom)
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_NAME_EXISTS then
        message = Str(STR.NICKNAME_EXISTED)  

        local eventCustom = cc.EventCustom:new(Data.Event.invalid_input)
        lc.Dispatcher:dispatchEvent(eventCustom)
            
    elseif msgStatus == SglMsg_pb.PB_STATUS_INVALID_VERSION then
        message = Str(STR.NEW_VERSION_AVAILABLE)    
        isSerious = true
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_OPPONENT_NOT_FOUND then
        message = Str(STR.OPPOSITE_NOT_FOUND)        
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_BATTLE_JOIN_NOT_ALLOWED then
        message = Str(STR.BATTLE_JOIN_NOT_ALLOWED)
        if msgType == SglMsgType_pb.PB_TYPE_USER_LOGIN or msgType == SglMsgType_pb.PB_TYPE_USER_REGISTER then
            -- in reconnect mode
            isSerious = true
        end
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_CITY_FOCUSED then
        local focusData = msg.Extensions[World_pb.SglWorldMsg.world_focus_resp]

        local userName = focusData.info.name            -- user_info
        local status = focusData.status
        if status == SglMsg_pb.PB_FOCUS_RESCUE then
            message = string.format(Str(STR.UNION_HELPING_BY), userName)

        elseif status == SglMsg_pb.PB_FOCUS_ATTACK or status == SglMsg_pb.PB_FOCUS_CHALLENGE then
            message = string.format(Str(STR.UNION_ATTACKING_BY), userName)

        else
            message = Str(STR.CITY_IS_FOCUSED)
        end

    elseif msgStatus == SglMsg_pb.PB_STATUS_INVALID_RESCUE then
        message = Str(STR.INVALID_RESCUE)

        local mail = userData
        mail._sosStatus = SglMsg_pb.PB_SOS_INVALID
        mail:sendMailDirty()
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_ALREADY_IN_UNION then
        message = Str(STR.UNION_ALREADY_IN)
            
    elseif msgStatus == SglMsg_pb.PB_STATUS_NOT_IN_UNION then
        message = Str(STR.UNION_NOT_IN)

    elseif msgStatus == SglMsg_pb.PB_STATUS_PRIVILEGE_ERROR then
        message = Str(STR.UNION_PRIVILEGE_ERROR)
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_GIFT_CLAIMED then
        message = Str(STR.EXCHANGE_CODE_CLAIMED)

    elseif msgStatus == SglMsg_pb.PB_STATUS_GIFT_DUPLICATE then
        message = Str(STR.EXCHANGE_CODE_DUPLICATE)
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_GIFT_EXPIRED then
        message = Str(STR.EXCHANGE_CODE_EXPIRED)
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_GIFT_INVALID then
        message = Str(STR.EXCHANGE_CODE_INVALID)

    elseif msgStatus == SglMsg_pb.PB_STATUS_ILLEGAL_INVITE_CODE then
        message = Str(STR.INVITE_CODE_INVALID)
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_CLOSED then
        message = Str(STR.INVALID_UNION)
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_EXCEEDED then
        message = Str(STR.UNION_EXCEEDED)
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_APPLY_NOT_ALLOWED then
        message = Str(STR.UNION_CANT_APPLY)

    elseif msgStatus == SglMsg_pb.PB_STATUS_CO_LEADER_EXCEEDED then
        message = string.format(Str(STR.UNION_ELDER_MAX), 2)

    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_TAG_EXISTS then
        message = Str(STR.UNION_FLAG_EXISTS)
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_NAME_EXISTS then
        message = Str(STR.UNION_NAME_EXISTS)

    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_KICKOUT_FAILED then
        message = Str(STR.UNION_KICKOUT_FAILED)

    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_BOSS_LOCKED then
        message = Str(STR.UNION_BOSS_LOCKED)

    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_BOSS_UNLOCKED then
        message = Str(STR.UNION_BOSS_UNLOCKED)

    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_BOSS_FOCUSED then
        message = Str(STR.UNION_BOSS_FOCUSED)
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_FUND_OWNED then
        message = Str(STR.FUND_OWNED)

    elseif msgStatus == SglMsg_pb.PB_STATUS_LET_NOT_FOUND then
        message = Str(STR.HIRE_NOT_FOUND)

    elseif msgStatus == SglMsg_pb.PB_STATUS_UNION_JOIN_CD then
        local time = msg.Extensions[Union_pb.SglUnionMsg.union_join_cd_resp] / 1000
        message = string.format(Str(STR.UNION_JOIN_CD), ClientData.formatPeriod(time))

    elseif msgStatus == SglMsg_pb.PB_STATUS_WAR_NOT_STARTED then
        message = Str(STR.UNION_WAR_NOT_STARTED)
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_WAR_ENDED then
        message = Str(STR.UNION_WAR_ENDED)
    
    elseif msgStatus == SglMsg_pb.PB_STATUS_CAMP_DEFEATED then
        message = Str(STR.UNION_OPPONENT)..Str(STR.UNION_CAMP)..Str(STR.UNION_DEFEATED)

	elseif msgStatus == SglMsg_pb.PB_STATUS_BATTLE_NOT_ENDED then
		message = Str(STR.UNION_WAR_BATTLE_NOT_ENDED)
        
    elseif msgStatus == SglMsg_pb.PB_STATUS_ERROR_CONNECT_BATTLE_SERVER then
        message = Str(STR.FIND_MATCH_NO_OPPONENT)
        if ClientData._findMatchPanel then
            ClientData._findMatchPanel:hide()
        end

    elseif msgStatus == SglMsg_pb.PB_STATUS_BATTLE_NOT_ALLOWED then
        ToastManager.push(Str(STR.BATTLE_NOT_ALLOWED))
        if ClientData._findMatchPanel then
            ClientData._findMatchPanel:hide()
        end

    elseif msgStatus == SglMsg_pb.PB_STATUS_MATCH_JOIN_NOT_ALLOWED then
        P._playerRoom:sendExitRoomDirty()
        P._playerRoom:clear()
        message = Str(STR.MATCH_JOIN_NOT_ALLOWED)

    elseif msgStatus == SglMsg_pb.PB_STATUS_MATCH_START_NOT_ALLOWED then
        message = Str(STR.MATCH_START_NOT_ALLOWED)
        V.getActiveIndicator():hide()

    elseif msgStatus == SglMsg_pb.PB_STATUS_ERROR_CREATE_MATCH then
        message = Str(STR.ERROR_CREATE_MATCH)

    elseif msgStatus == SglMsg_pb.PB_STATUS_MASSWAR_JOIN_NOT_ALLOWED then
        message = Str(STR.GROUP_JOIN_NOT_ALLOWED)

    elseif msgStatus == SglMsg_pb.PB_STATUS_MASSWAR_KICKOUT_NOT_ALLOWED then
        message = Str(STR.GROUP_KICKOUT_NOT_ALLOWED)

    elseif msgStatus == SglMsg_pb.PB_STATUS_MASSWAR_TEAM_TROOP_LOCKED then
        if self._sceneId == ClientData.SceneId.manage_troop then
            self:hide()
        end
        message = Str(STR.MANAGING_CARDS)

    elseif msgStatus == SglMsg_pb.PB_STATUS_MASSWAR_ALREADY_IN_TEAM then
        message = Str(STR.ALREADY_IN_TEAM)

    elseif msgStatus == SglMsg_pb.PB_STATUS_MASSWAR_NOT_IN_TEAM then
        message = Str(STR.NOT_IN_TEAM)

    elseif msgStatus == SglMsg_pb.PB_STATUS_MASSWAR_TEAM_NOT_FULL then
        message = Str(STR.CANNOT_START_UNION_BATTLE)

    elseif msgStatus == SglMsg_pb.PB_STATUS_MASSWAR_TROOP_NOT_FULL then
        message = Str(STR.TROOP_NOT_FULL)

    elseif msgStatus == SglMsg_pb.PB_STATUS_MASSWAR_CANNOT_LEAVE_TEAM then
        message = Str(STR.CANNOT_LEAVE_TEAM)

    elseif msgStatus == SglMsg_pb.PB_STATUS_INVALID_TUTORIAL then
        message = Str(STR.INVALID_REPLAY)
        lc.sendEvent(Data.Event.invalid_tutorial)

    elseif msgStatus == SglMsg_pb.PB_STATUS_DARK_DUEL_NOT_STARTED then
        message = Str(STR.DARK_DUEL_NOT_STARTED)
        lc.sendEvent(Data.Event.invalid_tutorial)

    end
    
    if message ~= nil then                 
        if isSerious then 
            if self._reloadDialog == nil then
                self:showReloadDialog(message, msgStatus)
            end
        else
            ToastManager.push(message)
        end
        return true
    end 
    
    return false
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == SglMsgType_pb.PB_TYPE_IAP_START then
        local resp = msg.Extensions[Buy_pb.SglBuyMsg.iap_start_resp]
        print ('#### iap start resp: ', resp.purchase_id, resp.type)
        ClientData.pay(resp.type, resp.purchase_id)
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_IAP_FINISH then
        local resp = msg.Extensions[Buy_pb.SglBuyMsg.iap_finish_resp]
        print ('#### iap finish resp: ', resp.purchase_id, resp.type, resp.is_success, resp.fail_desc)
        V.iapFinish()
        
        if resp.is_success then
            local type, prevVip = resp.type, P._vip
            
            local price = ClientData.getPrice(type)
            local buyIngot, giftIngot = ClientData.getIngot(type)

            local isChargedBefore = ClientData.isRecharged(type)
            ClientData.setRecharged(type)

            if type == Data.PurchaseType.month_card_1 or type == Data.PurchaseType.month_card_2 then         
                if ClientData.isAppStoreReviewing() then
                    local gold = (type == Data.PurchaseType.month_card_1 and 4000 or 10000)
                    P:changeResource(Data.ResType.gold, gold)
                    V.showResChangeText(self._scene, Data.ResType.gold, gold)
                    ToastManager.push(string.format(Str(STR.BUY_GOLD_SUCCESS), gold))
                else
                    --P:changeResource(Data.ResType.ingot, buyIngot)
                    P:changeVIPExp(buyIngot)

                    local startId = type == Data.PurchaseType.month_card_1 and 9003 or 9015
                    local _, _, month, _ = ClientData.getServerDate()
                    local bonusInfo = Data._bonusInfo[startId + month - 1]
                    local RewardPanel = require("RewardPanel")
                    local data = {}
                    for i = 1, #bonusInfo._rid do
                        data[#data + 1] = {info_id = bonusInfo._rid[i], num = bonusInfo._count[i]}
                    end

                    local index = type - Data.PurchaseType.month_card_1 + 1
                    local value = P._playerBonus._bonusMonthCardBought[index]._value
                    if value == 0 then
                        if index == 1 then
                            P._monthCardDay1 = P._monthCardDay1 + 30
                        else
                            P._monthCardDay2 = P._monthCardDay2 + 30
                        end
                    elseif value == 1 or value == 2 then
                        bonusInfo = P._playerBonus._bonusMonthCardPackage[(index - 1) * 2 + value]._info
                        for i = 1, #bonusInfo._rid do
                            data[#data + 1] = {info_id = bonusInfo._rid[i], num = bonusInfo._count[i]}
                        end
                    end
                    P._playerBonus._bonusMonthCardBought[index]._value = P._playerBonus._bonusMonthCardBought[index]._value + 1

                    RewardPanel.create(data, RewardPanel.MODE_BUY):show()
    
                    ToastManager.push(Str(STR.BUY_MONTH_CARD_SUCCESS))
                end
                P:sendMonthCardDirty()

            elseif type == Data.PurchaseType.fund then
                if ClientData.isAppStoreReviewing() then
                    local gold = 14000
                    P:changeResource(Data.ResType.gold, gold)
                    V.showResChangeText(self._scene, Data.ResType.gold, gold)
                    ToastManager.push(string.format(Str(STR.BUY_GOLD_SUCCESS), gold))
                else
                    if isChargedBefore then
                        -- Add union fund properties
                        local RewardPanel = require("RewardPanel")
                        RewardPanel.create({{info_id = Data.PropsId.union_fund, num = 1}}, RewardPanel.MODE_BUY):show()
                    else
                        ToastManager.push(Str(STR.BUY_FUND_SUCCESS))
                    end

                    --P:changeResource(Data.ResType.ingot, buyIngot)
                    P:changeVIPExp(buyIngot)

                    P._playerBonus:onFundLevelDirty(true)
                end
                P:sendFundDirty()

            elseif type == Data.PurchaseType.daily_1 or type == Data.PurchaseType.daily_2 then
                local bonus = P._playerBonus._packageBonus[type - Data.PurchaseType.daily_1 + 1304]
                local RewardPanel = require("RewardPanel")
                local data = {}
                for i = 1, #bonus._info._rid do
                    data[#data + 1] = {info_id = bonus._info._rid[i], num = bonus._info._count[i]}
                end
                RewardPanel.create(data, RewardPanel.MODE_BUY):show()

                P:changeVIPExp(buyIngot)

                bonus._isClaimed = true

                bonus = P._playerBonus._packageBonus[1306]
                bonus._value = bonus._value + 1

                P:sendPackageDirty()

            elseif type >= Data.PurchaseType.package_1 and  type < Data.PurchaseType.limit_1 then
                local bonus = P._playerBonus._packageBonus[type - Data.PurchaseType.package_1 + 1121]
                local RewardPanel = require("RewardPanel")
                local data = {}
                for i = 1, #bonus._info._rid do
                    data[#data + 1] = {info_id = bonus._info._rid[i], num = bonus._info._count[i]}
                end
                RewardPanel.create(data, RewardPanel.MODE_BUY):show()

                P:changeVIPExp(buyIngot)

                bonus._isClaimed = true
                P:sendPackageDirty()

            elseif type >= Data.PurchaseType.limit_1 then
                local bonus = P._playerBonus._limitBonus[type - Data.PurchaseType.limit_1 + 1401]
                local RewardPanel = require("RewardPanel")
                local data = {}
                for i = 1, #bonus._info._rid do
                    data[#data + 1] = {info_id = bonus._info._rid[i], num = bonus._info._count[i]}
                end
                RewardPanel.create(data, RewardPanel.MODE_BUY):show()

                P:changeVIPExp(buyIngot)

                bonus._isClaimed = true
                P:sendPackageDirty()

            else
                P:changeResource(Data.ResType.ingot, buyIngot + giftIngot)
                P:changeVIPExp(buyIngot)
                V.showResChangeText(self._scene, Data.ResType.ingot, buyIngot + giftIngot)
                
                P._playerActivity:checkChargeDays()

                local str
                if giftIngot > 0 then
                    str = string.format(Str(STR.BUY_INGOT_SUCCESS), buyIngot)..string.format(Str(STR.CHARGE_BONUS_INGOT), giftIngot)                    
                else
                    str = string.format(Str(STR.BUY_INGOT_SUCCESS), buyIngot)
                end
                print(str)
                ToastManager.push(str)
            end

            if P._vip > prevVip then
                require("LevelUpPanel").createVip(prevVip, P._vip):show()
            end

            if P._playerActivity._actCharge then
                P._playerActivity._chargeIngot = P._playerActivity._chargeIngot + buyIngot
            end

            if P._playerActivity._actRebate then
                P._playerActivity._rebateIngot = P._playerActivity._rebateIngot + buyIngot
            end

            if P._playerActivity._actDailyChargeTimes then
                P._ingotDailyRecharge = P._ingotDailyRecharge + 1
            end
            
            local eventCustom = cc.EventCustom:new(Data.Event.recharge_success)
            eventCustom._type = type
            lc.Dispatcher:dispatchEvent(eventCustom)
        else
            local str = Str(STR.BUYFAIL)
            print(str)
            ToastManager.push(str)            
        end 
    
        return true

    end
    
    return false
end

function _M:onError(error)
    self:showReloadDialog(Str(STR.CRC_ERROR))
    return true
end

-- events --

function _M:onConnectFailEvent(event)
    if event._socket ~= ClientData._socket then return end
    
    self:showReloadDialog(Str(STR.DISCONNECT))

    ClientData.writeSocketLog(ClientData.SocketLog.disconnect)
end

function _M:onDisconnectEvent(event)
    if event._socket ~= ClientData._socket then return end
    
    self:showReloadDialog(Str(STR.HEARTBEAT_LOST))
end

function _M:onIdle()
    ClientData.disconnect(false)
    self:showReloadDialog(Str(STR.IDLE))
end

function _M:onReachabilityChanged()
    --self:reconnect(Str(STR.REACHABILITY_CHANGED))
end

function _M:onGameCenterIdChanged()
    ClientData.disconnect(false)
    self:showReloadDialog(Str(STR.GAMECENTER_ID_CHANGED), SglMsg_pb.PB_STATUS_INVALID_VERSION)
end

function _M:onLogin()
    V.getActiveIndicator():hide()

    if GuideManager.isGuideEnabled() then
        V.popScene(true)
        lc.replaceScene(require("LoadingScene").create())
        return true
    end
        
    if lc._runningScene._sceneId ~= ClientData.SceneId.loading 
        and lc._runningScene._sceneId ~= ClientData.SceneId.res_switch
        and lc._runningScene._sceneId ~= ClientData.SceneId.battle then
        
        self:clearPanels()
        
        for i = 1, #_M._sceneList do
            if _M._sceneList[i] ~= self then
                _M._sceneList[i]._needSyncData = true
            end
        end
        self:syncData()
    end    
    
    return false
end

function _M:onMail(event)
    local PlayerMail = require("PlayerMail")
    if event == PlayerMail.Event.send_ok then
        ToastManager.push(Str(STR.SEND_SUCCESS))
    end
end

-- battle

function _M:onAttack(input)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function() 
        ClientView.popScene(true)
        lc.replaceScene(require("ResSwitchScene").create(self._sceneId, ClientData.SceneId.battle, input))
    end)))
    
    if input._battleType == Data.BattleType.task then
        --TOOD--
        --ClientData._focusCityId = input._levelId
    end
end

function _M:onEnterRoom()
    if self._sceneId == ClientData.SceneId.battle then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function() 
            lc.replaceScene(require("ResSwitchScene").create(self._sceneId, ClientData.SceneId.in_room))
        end)))
    else
        lc.pushScene(require("InRoomScene").create())
    end
end

function _M:onExpeditionEx(input)
    self:runAction(lc.sequence(0.5, function() 
        V.popScene(true)
        lc.replaceScene(require("ResSwitchScene").create(self._sceneId, ClientData.SceneId.battle, input))
    end))
end

function _M:onReplay(input)
    V.getActiveIndicator():hide()

    V.popScene(true)
    lc.replaceScene(require("ResSwitchScene").create(self._sceneId, ClientData.SceneId.battle, input))
end

function _M:onFriendBattle(input)
    V.getActiveIndicator():hide()

    V.popScene(true)
    lc.replaceScene(require("ResSwitchScene").create(self._sceneId, ClientData.SceneId.battle, input))
end

function _M:onBattleRecover(input)
    V.getActiveIndicator():hide()

    V.popScene(true)
    lc._runningScene = nil -- always replace with ResSwitchScene, even in ResSwitchScene
    lc.replaceScene(require("ResSwitchScene").create(self._sceneId, ClientData.SceneId.battle, input))
end

function _M:onBattleEnd(resp)
    self:reconnect()
end

function _M:onBattleWait()
    V.getActiveIndicator():show(Str(STR.WAIT_BATTLE_RESULT))
end

-- union battle

function _M:onUnionAttack(input)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function() 
        V.popScene(true)
        lc.replaceScene(require("ResSwitchScene").create(self._sceneId, ClientData.SceneId.battle, input))            
    end)))
end


function _M:onGuide(event)
    -- override in inherited scene
end

function _M:onHelp()
    -- override in inherited scene
end

function _M:seenByCamera3D(node)
    local cam = ClientData._camera3D
    if cam:getParent() ~= self then
        if cam:getParent() then
            cam:removeFromParent()
        end
        self:addChild(cam)
    end

    node:setCameraMask(ClientData.CAMERA_3D_FLAG)
end

function _M:clearPanels()
    local deletePanels = {}
    local Panel = require("BasePanel")
    for i = 1, #Panel.Panels do
        table.insert(deletePanels, Panel.Panels[i])
    end
    for i = 1, #deletePanels do
        deletePanels[i]:hide(true)
    end 
end

BaseScene = _M
return _M