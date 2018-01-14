local _M = class("InputNumberForm", BaseForm)

local FORM_SIZE = cc.size(720, 550)

local NUM_POS = {
    cc.p(100, 330),
    cc.p(230, 330),
    cc.p(360, 330),
    cc.p(490, 330),
    cc.p(620, 330),
    cc.p(100, 200),
    cc.p(230, 200),
    cc.p(360, 200),
    cc.p(490, 200),
    cc.p(620, 200),
}

function _M.create(defaultStr, defaultInputStr, confirmHandle)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(defaultStr, defaultInputStr, confirmHandle)
    
    return panel    
end

function _M:init(defaultStr, defaultInputStr, confirmHandle)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))
    self._confirmHandle = confirmHandle
--    local label = cc.Label:createWithTTF(Str(STR.INPUT_ROOM_PASSWORD)..":", V.TTF_FONT, V.FontSize.S1)
--    label:setColor(V.COLOR_TEXT_LIGHT)
--    label:setPosition(_M.LEFT_MARGIN + lc.w(label) / 2 + 60, lc.h(self._form) - _M.TOP_MARGIN - 50)
--    self._form:addChild(label)
--    self._label = label
    local size = cc.size(580, 60)
    local editor = V.createEditBox("img_com_bg_5", V.CRECT_COM_BG3, size, defaultStr, true)
    editor:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
    editor:setFontColor(lc.Color4B.white)
    editor:setEnabled(false)
    editor:setPosition(_M.LEFT_MARGIN + 30 + size.width / 2, lc.h(self._form) - _M.TOP_MARGIN - 60)
    if defaultInputStr then
        editor:setText(defaultInputStr)
    end
    self._form:addChild(editor)
    self._editor = editor

    local clearBtn = V.createShaderButton(nil, function(sender) self._editor:setText("") end)
    clearBtn:setContentSize(cc.size(60, 60))
    lc.addChildToPos(self._form, clearBtn, cc.p(lc.right(editor) - lc.cw(clearBtn), lc.y(editor)))
    local spr = lc.createSprite("img_troop_x")
    lc.addChildToCenter(clearBtn, spr)


    local btnOk = V.createScale9ShaderButton("img_btn_1", function(sender) self:onConfirm() end, V.CRECT_BUTTON, V.PANEL_BTN_WIDTH)
    btnOk:addLabel(Str(STR.OK))
    lc.addChildToPos(self._form, btnOk, cc.p(lc.cw(self._form), lc.ch(btnOk) + 40))
    self._btnOk = btnOk

    local y = _M.BOTTOM_MARGIN + lc.h(btnOk) / 2 + 10

    self:initNumbers()
end

function _M:onConfirm()
    if self._confirmHandle then
        local text = self._editor:getText()
        self._confirmHandle(self, text)
    end
end

function registerConfirmHandle(handle)
    self._confirmHandle = handle
end

function _M:initNumbers()
    for i = 1,10 do
        local numBtn = self:createNumberButton(i)
        lc.addChildToPos(self._frame, numBtn, NUM_POS[i])
    end
end

function _M:createNumberButton(num)
    local button = V.createShaderButton("room_number_btn", function(sender) self._editor:setText(self._editor:getText()..num % 10) end)
    local label = V.createTTF(num % 10, V.FontSize.B2)
    lc.addChildToCenter(button, label)
    label:setColor(V.COLOR_TEXT_DARK)
    return button
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

return _M