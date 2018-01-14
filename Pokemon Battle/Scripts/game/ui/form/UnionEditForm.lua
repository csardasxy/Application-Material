local _M = class("UnionEditForm", BaseForm)

local CreateArea = require("UnionCreateArea")

local FORM_SIZE = cc.size(960, 720)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.CHANGE)..Str(STR.UNION)..Str(STR.INFO), 0)

    local contentArea = CreateArea.create(CreateArea.Mode.edit, lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT)
    lc.addChildToCenter(self._frame, contentArea, -1)
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listener = lc.addEventListener(Data.Event.union_edit_dirty, function()        
        self:hide()
    end)
end

function _M:onExit()
    _M.super.onExit(self)

    lc.Dispatcher:removeEventListener(self._listener)
end

return _M