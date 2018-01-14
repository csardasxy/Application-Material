local _M = class("PackageDetailForm", BaseForm)

local FORM_SIZE = cc.size(700, 360)
local GIFT_AREA_SIZE = cc.size(560, 180)

function _M.create(bonusInfo, title, tip, callback)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(bonusInfo, title, tip, callback)
    return panel
end

function _M:init(bonusInfo, title, tip, callback)
    _M.super.init(self, FORM_SIZE, title, bor(BaseForm.FLAG.ADVANCE_TITLE_BG, BaseForm.FLAG.PAPER_BG))

    local icons = {}
    for i = 1, #bonusInfo._rid do
        local icon = IconWidget.create{_infoId = bonusInfo._rid[i], _count = bonusInfo._count[i]}
        icon._name:setColor(V.COLOR_TEXT_LIGHT)
        table.insert(icons, icon)
    end
    P:sortResultItems(icons)

    local gap = 20
    local w = (104 + gap) * #icons - gap
    local listW = lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT

    local list = lc.List.createH(cc.size(listW, 130), (listW - w) / 2, gap)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self._frame, list)
    
    for _, icon in ipairs(icons) do
        list:pushBackCustomItem(icon)
    end
end

return _M