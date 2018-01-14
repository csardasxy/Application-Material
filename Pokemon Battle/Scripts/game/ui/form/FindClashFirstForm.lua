local _M = class("FindClashFirstForm", BaseForm)

local FORM_SIZE = cc.size(620, 364)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))
    
    local form, data = self._form, P._playerFindClash
    local cx = lc.w(form) / 2    

    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(form, titleBg, cc.p(cx, lc.h(form) - 10 - lc.h(titleBg) / 2))

    local gradeStr = Str(Data._ladderInfo[data._grade]._nameSid)
    local title = V.createTTFStroke(gradeStr..Str(STR.FIND_CLASH_FIELD), V.FontSize.S1)
    lc.addChildToCenter(titleBg, title)

    local tip1 = V.createBoldRichText(Str(STR.FIND_CLASH_FIRST_TIP1), V.RICHTEXT_PARAM_LIGHT_S1, 500)
    lc.addChildToPos(form, tip1, cc.p(cx, lc.bottom(titleBg) - 20 - lc.h(tip1) / 2))

    local tipStr = string.format(Str(STR.FIND_CLASH_FIRST_TIP2), P._level, data._trophy, gradeStr)
    local tip2 = V.createBoldRichTextWithIcons(tipStr, V.RICHTEXT_PARAM_LIGHT_S1, 500)
    lc.addChildToPos(form, tip2, cc.p(cx, lc.bottom(tip1) - 20 - lc.h(tip2) / 2))    

    local btnOk = V.createScale9ShaderButton("img_btn_1_s", function() self:hide() end, V.CRECT_BUTTON_S, 140)
    btnOk:addLabel(Str(STR.OK))
    lc.addChildToPos(form, btnOk, cc.p(cx, lc.bottom(tip2) - 32 - lc.h(btnOk) / 2))
end

return _M