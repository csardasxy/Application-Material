local _M = class("ClaimForm", BaseForm)

local BONUS_AREA_SIZE = cc.size(560, 180)

function _M.create(bonus, title, tip, callback)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(bonus, title, tip, callback)
    return panel
end

function _M:init(bonus, title, tip, callback)
    local info = (type(bonus) == "number" and Data._bonusInfo[bonus] or bonus._info)
        
    local bg = lc.createSprite{_name = "img_com_bg_10", _crect = V.CRECT_COM_BG10, _size = BONUS_AREA_SIZE}
    local btnClaim = V.createScale9ShaderButton("img_btn_1", function() if callback then callback() end self:hide() end, V.CRECT_BUTTON, 140)
    btnClaim:addLabel(Str(STR.CLAIM))
    btnClaim:setDisabledShader(V.SHADER_DISABLE)
    btnClaim:setEnabled(callback ~= nil)

    local w, h = BONUS_AREA_SIZE.width + 40 + _M.FRAME_THICK_H, BONUS_AREA_SIZE.height + 60 + _M.FRAME_THICK_V + lc.h(btnClaim)
    if tip then
        h = h + 50
    end

    _M.super.init(self, cc.size(w, h), title, bor(BaseForm.FLAG.ADVANCE_TITLE_BG, BaseForm.FLAG.PAPER_BG))
    
    local form = self._form
    lc.addChildToPos(form, bg, cc.p(lc.w(form) / 2, h - _M.FRAME_THICK_TOP - 20 - lc.h(bg) / 2))
    lc.addChildToPos(form, btnClaim, cc.p(lc.w(form) / 2, _M.FRAME_THICK_BOTTOM + 20 + lc.h(btnClaim) / 2))
    
    self._btnClaim = btnClaim

    local icons = {}
    for i = 1, #info._rid do
        local icon = IconWidget.create{_infoId = info._rid[i], _level = info._level[i], _count = info._count[i], _isFragment = info._isFragment[i] > 0}
        table.insert(icons, icon)
    end
    P:sortResultItems(icons)

    local gap = 20
    local listW = math.min(lc.w(bg) - 30, (IconWidget.SIZE + gap) * #icons + gap)

    local list = lc.List.createH(cc.size(listW, 130), gap, gap)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(bg, list)

    for _, icon in ipairs(icons) do
        list:pushBackCustomItem(icon)
    end

    list:setBounceEnabled(#icons > 5)

    if tip then
        self:updateTip(tip)
    end
end

function _M:updateTip(tip)
    if self._tip then
        self._tip:removeFromParent()
        self._tip = nil
    end

    local tipLabel = V.createBoldRichText(tip, V.RICHTEXT_PARAM_DARK_S1)
    lc.addChildToPos(self._form, tipLabel, cc.p(lc.w(self._form) / 2, lc.top(self._btnClaim) + 10 + lc.h(tipLabel) / 2))
    self._tip = tipLabel
end

return _M