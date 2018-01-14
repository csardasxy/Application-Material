local _M = class("Dialog", BaseForm)

local DIALOG_WIDTH = 700

local CONTENT_MARGIN = 40
local CONTENT_MARGIN_B = 80
local CONTENT_WIDTH = DIALOG_WIDTH - _M.FRAME_THICK_H - CONTENT_MARGIN_B

local BUTTON_W = 140

function _M.showDialog(content, okHandler, noCancel)
    local dlg = _M.new(lc.EXTEND_LAYOUT_MASK)
    dlg:init(content, okHandler, noCancel)
    dlg:show()
    return dlg
end

function _M:init(content, okHandler, noCancel)
    -- Make sure general.lcres is loaded
    ClientData.loadLCRes("res/general.lcres")

    local content = V.createBoldRichTextMultiLine(content, V.RICHTEXT_PARAM_LIGHT_S1, CONTENT_WIDTH)
    local btnOk = V.createScale9ShaderButton("img_btn_1_s", function() self:close(true) end, V.CRECT_BUTTON_1_S, BUTTON_W)
    btnOk:addLabel(Str(STR.OK))
    self._btnOk = btnOk
    self._okHandler = okHandler
    
    local height = _M.FRAME_THICK_V + CONTENT_MARGIN_B + lc.h(content) + CONTENT_MARGIN + lc.h(btnOk)

    _M.super.init(self, cc.size(DIALOG_WIDTH, height), nil, bor(BaseForm.FLAG.PAPER_BG))

    self._hideBg = true
    self._btnBack:setVisible(false)

    lc.addChildToPos(self._form, content, cc.p(lc.w(self._form) / 2, lc.h(self._form) - _M.TOP_MARGIN - CONTENT_MARGIN - 10 - lc.h(content) / 2))
    lc.addChildToPos(self._form, btnOk, cc.p(0, _M.BOTTOM_MARGIN + CONTENT_MARGIN + lc.h(btnOk) / 2 - 10))

    if noCancel then
        btnOk:setPositionX(lc.x(content))
        
        -- Do not close the form, remove old listeners and add a empty listener
        self:addTouchEventListener(function() end)
    else
        btnOk:setPositionX(lc.x(content) + 20 + BUTTON_W / 2)

        local btnCancel = V.createScale9ShaderButton("img_btn_2_s", function() self:close() end, V.CRECT_BUTTON_1_S, BUTTON_W)
        btnCancel:addLabel(Str(STR.CANCEL))
        lc.addChildToPos(self._form, btnCancel, cc.p(lc.x(content) - 20 - BUTTON_W / 2, lc.y(btnOk)))
        self._btnCancel = btnCancel        
    end
end

function _M:show(isForce)
    _M.super.show(self, isForce)

    self:setLocalZOrder(ClientData.ZOrder.dialog)
end

function _M:hide()
    _M.super.hide(self)

    if self._cancelHandler then
        self._cancelHandler()
    end
end

function _M:close(isOk)
    self._btnOk:setEnabled(false)
    if self._btnCancel then self._btnCancel:setEnabled(false) end

    self:hide()
    
    if isOk then
        if self._okHandler then
            self._okHandler()
        end
    end
end

return _M