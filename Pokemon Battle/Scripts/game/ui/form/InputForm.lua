local _M = class("InputForm", BaseForm)

local FORM_SIZE = cc.size(720, 280)

_M.Type = {
    FEEDBACK        = 1,
    TROOP_REMARK    = 2,
    UNION_CHAT      = 3,
}

local TITLE_STR = {Str(STR.RATE_ADVICE), Str(STR.CHANGE)..Str(STR.REMARK), Str(STR.SEND), Str(STR.INPUT_MESSAGE)}
local BTN_STR = {Str(STR.SEND), Str(STR.CHANGE), Str(STR.SEND)}

function _M.create(type, param, callback)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(type, param, callback)
    return panel
end

function _M:init(type, param, callback)
    _M.super.init(self, FORM_SIZE, TITLE_STR[type], 0)

    self._type = type
    self._param = param
    self._callback = callback

    local form = self._form

    -- edit box
    local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), cc.size(600, 60), Str(STR.INPUT_SHARE_TEXT))
    lc.addChildToPos(form, editor, cc.p(lc.w(form) / 2, lc.bottom(self._titleFrame) - 20 - lc.h(editor) / 2))
    self._editor = editor

    local btnSend = V.createScale9ShaderButton("img_btn_1_s", function() self:send() end, V.CRECT_BUTTON_1_S, 120)
    btnSend:addLabel(BTN_STR[type])
    lc.addChildToPos(form, btnSend, cc.p(lc.right(editor) - lc.w(btnSend) / 2, 80))
    self._btnSend = btnSend
end

function _M:send()
    local text = self._editor:getText()

    local type = self._type
    if type == _M.Type.FEEDBACK then
        if lc.utf8len(text) > 400  then
            ToastManager.push(Str(STR.MESSAGE)..string.format(Str(STR.CANNOT_MORE_THAN), 400))
            return

        elseif lc.utf8len(text) == 0 then
            ToastManager.push(Str(STR.INPUT_MESSAGE))
            return

        else
            ClientData.sendFeedback(Feedback_pb.PB_FEEDBACK_SUGGESTION, text)
            ToastManager.push(Str(STR.FEEDBACK_THANKS))

            self:hide()
        end

    elseif type == _M.Type.TROOP_REMARK then
        local ttf = V.createTTF(text, V.FontSize.S2)
        if text == "" or lc.w(ttf) > 200 then
            ToastManager.push(Str(STR.REMARK_INVALID))
            return

        else
            local troopIndex = self._param
            P._troopRemarks[troopIndex] = text

            ClientData.sendTroopRemark(troopIndex, text)
            self:hide()
        end

    elseif type == _M.Type.UNION_CHAT then
        if lc.utf8len(text) > ClientData.MAX_INPUT_LEN  then
            ToastManager.push(Str(STR.MESSAGE)..string.format(Str(STR.CANNOT_MORE_THAN), ClientData.MAX_INPUT_LEN))
            return

        elseif lc.utf8len(text) == 0 then
            ToastManager.push(Str(STR.INPUT_MESSAGE))
            return

        else
            local playerUnion = P._playerUnion
            local result = playerUnion:canOperate(playerUnion.Operate.send_message)
            if result == Data.ErrorType.ok then
                ClientData.sendChat(Chat_pb.PB_CHAT_UNION, P._unionId, text)
            else
                ToastManager.push(ClientData.getUnionErrorStr(result))
            end
            self:hide()
        end

    end
end

function _M:hide(isForce)
    _M.super.hide(self, isForce)

    if self._callback then
        self._callback()
    end
end

return _M