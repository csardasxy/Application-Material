local _M = class("Mail")

_M.Mails = {}

function _M.create(pbMail)
    local mail = _M.new(pbMail.id)
    mail._timestamp = pbMail.timestamp / 1000
    mail._type = pbMail.type    
    mail._content = string.gsub(pbMail.content, "\\n", "\n")
    
    if pbMail:HasField("param") then
        local jsonNode = json.decode(pbMail.param)
        mail._title = jsonNode.title
        mail._sender = jsonNode.sender

        -- For city help
        mail._opponentId = jsonNode.opponentId
        mail._levelId = jsonNode.cityId

        if jsonNode.memberId then
            local isVisible
            for _, memId in ipairs(jsonNode.memberId) do
                if memId == P._id then
                    isVisible = true
                    break
                end
            end
            if not isVisible then mail._isIgnore = true end
        end
    end

    if pbMail:HasField("user_info") then
        mail._user = require("User").create(pbMail.user_info)
    else
        mail._user = require("User").createNpc()
    end
    mail._sender = mail._user._name

    if pbMail:HasField("invite_status") then
        mail._inviteStatus = pbMail.invite_status

    elseif pbMail:HasField("apply_status") then
        mail._applyStatus = pbMail.apply_status

    elseif pbMail:HasField("sos_status") then
        mail._sosStatus = pbMail.sos_status
    end
    
    return mail   
end

function _M:ctor(id)
    self._id = id
end

function _M:sendMailDirty()
    local PlayerMail = require("PlayerMail")
    local eventCustom = cc.EventCustom:new(Data.Event.mail)
    eventCustom._event = PlayerMail.Event.mail_dirty
    eventCustom._data = self
    lc.Dispatcher:dispatchEvent(eventCustom)        
end

return _M
