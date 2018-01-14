local _M = class("PlayerMail")

local Mail = require("Mail")

_M.Event = 
{
    send_ok                 = "send ok",
    
    mail_list_dirty         = "mail list dirty",
    mail_dirty              = "mail dirty",
}

function _M:ctor()
    self._mails = {}

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    self._mails = {}
end

function _M:refreshMails(pbMails)
    self._mails = {}
       
    for i = 1, #pbMails do
        local mail = Mail.create(pbMails[i])
        self:addMail(mail)
    end
       
    self:sendMailEvent(self.Event.mail_list_dirty)
end

function _M:addMail(mail)
    self._mails[mail._id] = mail
end

function _M:sendMailEvent(event)
    local eventCustom = cc.EventCustom:new(Data.Event.mail)
    eventCustom._event = event
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:getMailList(type, type1)
    local mails = {}
    if self._mails then
        for k, v in pairs(self._mails) do
            if v._type == type or v._type == type1 then
                if self:isMailVisible(v) then
                    table.insert(mails, v)
                end
            end        
        end
    end
    table.sort(mails, function(a, b) return a._timestamp > b._timestamp end)
    
    return mails
end

function _M:isMailVisible(mail)
    local isIgnore = mail._isIgnore
    if mail._type == Mail_pb.PB_MAIL_UNION and not isIgnore then
        local playerUnion = P._playerUnion
        if mail._applyStatus and playerUnion:canOperate(playerUnion.Operate.agree_user) ~= Data.ErrorType.ok then
            isIgnore = true
        end
    end

    return not isIgnore
end

function _M:acceptMail(mail)
    if mail._type == Mail_pb.PB_MAIL_FRIEND then
        if mail._inviteStatus then
            ClientData.sendUnionAcceptInvite(mail._id, true)
        end

    elseif mail._type == Mail_pb.PB_MAIL_UNION then
        if mail._applyStatus then
            ClientData.sendUnionAcceptApply(mail._id, true)
        end
    end    
end

function _M:refuseMail(mail)
    if mail._type == Mail_pb.PB_MAIL_FRIEND then
        if mail._inviteStatus then
            mail._inviteStatus = SglMsg_pb.PB_INVITE_REFUSED
            ClientData.sendUnionAcceptInvite(mail._id, false)
        end

    elseif mail._type == Mail_pb.PB_MAIL_UNION then
        if mail._applyStatus then
            mail._applyStatus = SglMsg_pb.PB_INVITE_REFUSED
            ClientData.sendUnionAcceptApply(mail._id, false)
        end        
    end

    mail:sendMailDirty()
end

function _M:getNewUnionMails()
    local timestamp = lc.readConfig(ClientData.ConfigKey.new_union_mail, 0)
    local number = 0
    if self._mails then
        for id, mail in pairs(self._mails) do
            if mail._type == Mail_pb.PB_MAIL_UNION and self:isMailVisible(mail) and math.floor(mail._timestamp) > math.floor(timestamp) then
                number = number + 1
            end
        end
    end

    return number
end

function _M:clearNewUnionMails()
    lc.writeConfig(ClientData.ConfigKey.new_union_mail, ClientData.getCurrentTime())
end

function _M:getNewMsgMails()
    local timestamp = lc.readConfig(ClientData.ConfigKey.new_friend_mail, 0)
    local number = 0
    if self._mails ~= nil then
        for id, mail in pairs(self._mails) do
            if mail._type == Mail_pb.PB_MAIL_FRIEND and math.floor(mail._timestamp) > math.floor(timestamp) then
                number = number + 1
            end
        end
    end
    
    return number
end

function _M:clearNewMsgMails()
    lc.writeConfig(ClientData.ConfigKey.new_friend_mail, ClientData.getCurrentTime())
end

function _M:getNewSystemMails()
    return self:getNewAnnouncements() + self:getNewNoticeMails() + P._playerBonus:getClaimCenterBonusFlag() + P._playerBonus:getSendBonusFlag()
end

function _M:getNewAnnouncements()
    local timestamp = lc.readConfig(ClientData.ConfigKey.new_announce, 0)
    local number = 0
    for _, mail in ipairs(ClientData._player._systemAnnouncement) do
        if math.floor(mail._timestamp) > math.floor(timestamp) then
            number = number + 1
        end
    end

    return number
end

function _M:getNewNoticeMails()
    local timestamp = lc.readConfig(ClientData.ConfigKey.new_notice_mail, 0)
    local number = 0
    if self._mails then
        for id, mail in pairs(self._mails) do
            if mail._type == Mail_pb.PB_MAIL_SYSTEM and math.floor(mail._timestamp) > math.floor(timestamp) then
                number = number + 1
            end
        end
    end

    return number
end

function _M:clearNewAnnouncements()
    lc.writeConfig(ClientData.ConfigKey.new_announce, ClientData.getCurrentTime())
end

function _M:clearNewNoticeMails()
    lc.writeConfig(ClientData.ConfigKey.new_notice_mail, ClientData.getCurrentTime())
end

----------------------------- socket receive --------------------------------------
function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == SglMsgType_pb.PB_TYPE_MAIL_SEND then
        self:sendMailEvent(self.Event.send_ok)
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_MAIL_LIST then
        local mails = msg.Extensions[Mail_pb.SglMailMsg.mail_list_resp]
        self:refreshMails(mails)           
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_MAIL_RECEIVE then
        local pbMail = msg.Extensions[Mail_pb.SglMailMsg.mail_receive_resp]
        local mail = Mail.create(pbMail)
        self:addMail(mail)
        
        self:sendMailEvent(self.Event.mail_list_dirty)
        
        if mail._type == Mail_pb.PB_MAIL_SYSTEM then
            local eventCustom = cc.EventCustom:new(Data.Event.push_notice)
            eventCustom._title = Str(STR.NEW_SYS_MAIL)
            eventCustom._content = mail._title
            eventCustom._isImportant = mail._isImportant
            lc.Dispatcher:dispatchEvent(eventCustom)
        end    
        
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_ACCEPT_INVITE then
        local mailId = msg.Extensions[Union_pb.SglUnionMsg.union_accept_resp]
        local mail = self._mails[mailId]
        if mail._inviteStatus == SglMsg_pb.PB_INVITE_INVITED then
            mail._inviteStatus = SglMsg_pb.PB_INVITE_ACCEPTED
            mail:sendMailDirty()
        end

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_UNION_ACCEPT_APPLY then
        local mailId = msg.Extensions[Union_pb.SglUnionMsg.union_accept_resp]
        local mail = self._mails[mailId]
        if mail._applyStatus == SglMsg_pb.PB_APPLY_APPLIED then
            mail._applyStatus = SglMsg_pb.PB_APPLY_ACCEPTED
            mail:sendMailDirty()
        end
    end    
    
    return false
end
----------------------------- socket receive --------------------------------------

return _M
