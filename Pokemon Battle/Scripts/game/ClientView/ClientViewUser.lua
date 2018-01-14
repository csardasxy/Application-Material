local _M = ClientView



function _M.operateUser(user, item)
    if user._id == P._id or user._id == 0 then return end

    local buttonDefs = {}
    --TODO
    table.insert(buttonDefs, {_str = Str(STR.INFO), _handler = function() _M.visitUser(user) end})
    --if lc._runningScene._sceneId ~= ClientData.SceneId.battle then
    --    table.insert(buttonDefs, {_str = Str(STR.COMPARE), _handler = function() _M.compareUser(user) end})
    --end
    table.insert(buttonDefs, {_str = Str(STR.LEAVE_MESSAGE), _handler = function() _M.mailUser(user) end})

    if user._unionId == nil or user._unionId == 0 then
        local playerUnion = P._playerUnion
        if playerUnion:canOperate(playerUnion.Operate.invite_user) == Data.ErrorType.ok then
            local union = playerUnion:getMyUnion()
            if user._level >= union._reqLevel then
                table.insert(buttonDefs, {_isSeparator = true}) 

                table.insert(buttonDefs, {_str = Str(STR.UNION_INVITE), _handler = function()
                    ToastManager.push(Str(STR.UNION_INVITE_SEND))
                    ClientData.sendUnionInvite(user._id, string.format(Str(STR.UNION_INVITE_MSG), P._unionName))    
                end}) 
            end
        end
    elseif user._unionId ~= P._unionId then
        table.insert(buttonDefs, {_isSeparator = true})
        table.insert(buttonDefs, {_str = Str(STR.UNION)..Str(STR.DETAIL), _handler = function()
            require("UnionDetailForm").create(user._unionId):show()
        end})
    end

    if ClientData.isActivityValid(ClientData.getActivityByType(803)) then
        table.insert(buttonDefs, {_isSeparator = true})
        table.insert(buttonDefs, {_str = Str(STR.SEND_GIFT), _handler = function()
            require("GivePropForm").create(user, 803):show()
        end})
    end

    if P:hasPrivilege(Data.Privilege.chat_ban) then
        table.insert(buttonDefs, {_isSeparator = true})
        table.insert(buttonDefs, {_str = Str(STR.CHAT_BAN), _handler = function()
            _M.doPrivilege(Data.Privilege.chat_ban, user)
        end, _onButtonCreate = function(button)
            if P._chatBanList[user._id] then
                button:setEnabled(false)
            else
                button:setDisplayFrame("img_btn_3")
            end
        end})
    end

    _M.showOperateTopMostPanel(user._name, buttonDefs, item)
end

function _M.visitUser(user)
    if user._id == P._id then return end

    require("VisitForm").create(user._id):show()
end

function _M.compareUser(user)
    if user._id == P._id then return end

    _M.getActiveIndicator():show(Str(STR.WAITING))    
    ClientData.startFriendBattle(user._id)
    
    local eventCustom = cc.EventCustom:new(Data.Event.pk_join)    
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M.mailUser(user)
    if user._id == P._id then return end

    if not P:hasPrivilege(Data.Privilege.mail_free) then
        if P:getMaxCharacterLevel() < Data._globalInfo._unlockSendMail then
            ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockSendMail))
            return
        end

        if Data._globalInfo._dailySendMailCount - P._dailySendMail <= 0 then
            ToastManager.push(Str(STR.DAILY_CANNOT_SEND_MAIL))
            return
        end
    end

    require("SendMailForm").create(user):show()
end

function _M.openUserProtocol()    
    local channelName, url = lc.App:getChannelName()
    local redirectChannelName = lc.App:getRedirectGameServer()
    local appId = ClientData.getAppId()
    --url = ""
    --lc.App:openURL(url)
end
