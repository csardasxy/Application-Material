local _M = class("RenameForm", BaseForm)

local FORM_SIZE = cc.size(640, 360)

local MAX_CODE_LEN = 12

function _M.create(isGuide)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(isGuide)
    return panel    
end

function _M:init(isGuide)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local label = cc.Label:createWithTTF(Str(STR.INPUT_EXCHANGE_CODE)..":", V.TTF_FONT, V.FontSize.S1)
    label:setColor(V.COLOR_TEXT_LIGHT)
    label:setPosition(_M.LEFT_MARGIN + lc.w(label) / 2 + 60, lc.h(self._form) - _M.TOP_MARGIN - 70)
    self._form:addChild(label)
    self._label = label
    
    local size = cc.size(440, 60)
    local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), size, nil, true)
    editor:setPosition(lc.left(label) + size.width / 2, lc.bottom(label) - size.height / 2 - 20)
    self._form:addChild(editor)
    self._editor = editor
        
    local btnExchange = V.createScale9ShaderButton("img_btn_1", function(sender) self:onExchange() end, V.CRECT_BUTTON, V.PANEL_BTN_WIDTH)
    btnExchange:addLabel(Str(STR.EXCHANGE))
    lc.addChildToPos(self._form, btnExchange, cc.p(lc.w(self._form) / 2, _M.FRAME_THICK_BOTTOM + 30 + lc.h(btnExchange) / 2))
end

function _M:onEnter()
    _M.super.onEnter(self)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:onExit()
    _M.super.onExit(self)

    ClientData.removeMsgListener(self)
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

function _M:onExchange()
    local code = self._editor:getText()
    if code == "" then
        ToastManager.push(Str(STR.INPUT_EXCHANGE_CODE))
    elseif #code > MAX_CODE_LEN then
        ToastManager.push(string.format(Str(STR.CANNOT_MORE_THAN), MAX_CODE_LEN)) 
    else
        self._editor:setText("")
        V.getActiveIndicator():show(Str(STR.WAITING))
        ClientData.sendUserGiftExchange(code)
    end
end

return _M