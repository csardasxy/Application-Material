local _M = class("SendMailForm", BaseForm)

local FORM_SIZE = cc.size(640, 440)

function _M.create(user)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(user)
    return panel
end

function _M:init(user)
    local size = cc.size(FORM_SIZE.width, FORM_SIZE.height)
    if user == nil then
        size.height = 320
    end

    _M.super.init(self, size, user and Str(STR.LEAVE_MESSAGE) or Str(STR.SEND_GROUP)..Str(STR.MAIL), 0)
    
    local form = self._form
    self._user = user

    local y
    if user then
        local userArea = UserWidget.create(user, UserWidget.Flag.NAME_UNION)
        userArea._unionArea._name:setColor(V.COLOR_TEXT_ORANGE)
        lc.addChildToPos(form, userArea, cc.p(260, lc.bottom(self._titleFrame) - 70))

        y = lc.bottom(userArea)

        if not P:hasPrivilege(Data.Privilege.mail_free) then
            local totalTimes = Data._globalInfo._dailySendMailCount
            local remainTimes = V.createBoldRichText(string.format(Str(STR.DAILY_SEND_MAILS), totalTimes - P._dailySendMail, totalTimes), V.RICHTEXT_PARAM_LIGHT_S1)
            remainTimes:setAnchorPoint(cc.p(0, 1))
            lc.addChildToPos(form, remainTimes, cc.p(lc.left(userArea), lc.bottom(userArea) - 10))

            y = lc.bottom(remainTimes)
        end

        
    else
        y = lc.bottom(self._titleFrame) - 10
    end

    local size = cc.size(500, 60)
    local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), size, nil, true)
    lc.addChildToPos(form, editor, cc.p(70 + size.width / 2, y - size.height / 2 - 10))    
    self._editor = editor

    local button = V.createScale9ShaderButton("img_btn_1_s", function() self:sendMail() end, V.CRECT_BUTTON_1_S, 140)
    button:addLabel(Str(STR.SEND))
    lc.addChildToPos(form, button, cc.p(lc.w(form) / 2, _M.BOTTOM_MARGIN + lc.h(button) / 2 + 30))
end

function _M:sendMail()
    local msg = self._editor:getText()
    if msg == "" then
        ToastManager.push(Str(STR.INPUT_MESSAGE))

    elseif lc.utf8len(msg) > ClientData.MAX_INPUT_LEN then
        ToastManager.push(Str(STR.MAIL)..string.format(Str(STR.CANNOT_MORE_THAN), ClientData.MAX_INPUT_LEN))

    else
        if self._user then
            P._dailySendMail = P._dailySendMail + 1
            ClientData.sendMailSend(msg, self._user._id)
        else
            ClientData.sendMailSend(msg)
        end

        self:hide()
    end
end

return _M