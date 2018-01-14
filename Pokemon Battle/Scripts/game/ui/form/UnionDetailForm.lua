local _M = class("UnionDetailForm", BaseForm)

local FORM_SIZE = cc.size(870, 720)

function _M.create(unionId)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(unionId)
    return panel 
end

function _M:init(unionId)
    _M.super.init(self, FORM_SIZE, Str(STR.UNION)..Str(STR.DETAIL), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))
    
    local form = self._form
    local contentArea = require("UnionUnionArea").create(unionId, FORM_SIZE.width, FORM_SIZE.height - _M.FRAME_THICK_V, true)
    lc.addChildToCenter(form, contentArea)

    contentArea._callback = function()
        self:hide()
        ToastManager.push(Str(STR.INVALID_UNION))
    end
end

return _M