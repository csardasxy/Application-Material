local _M = class("MailDetailForm", BaseForm)

local FORM_SIZE = cc.size(700, 540)

function _M.create(title, content, timestamp)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(title, content, timestamp)
    
    return panel
end

function _M:init(title, content, timestamp)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local form = self._form

    local ico = lc.createSprite("img_icon_mail")
    lc.addChildToPos(form, ico, cc.p(_M.LEFT_MARGIN + lc.w(ico) / 2 + 30, lc.h(form) - lc.h(ico) / 2 - _M.TOP_MARGIN - 20), 1)
    
    local titleBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(500, 40)}
    titleBg:setColor(lc.Color3B.black)
    titleBg:setOpacity(100)
    lc.addChildToPos(form, titleBg, cc.p(lc.x(ico) + lc.w(titleBg) / 2, lc.y(ico)))

    local title = V.createTTF(title, V.FontSize.S1)
    lc.addChildToPos(titleBg, title, cc.p(lc.w(title) / 2 + 40, lc.h(titleBg) / 2))

    local listBG = ccui.Scale9Sprite:createWithSpriteFrameName("img_com_bg_10", V.CRECT_COM_BG10)
    listBG:setContentSize(cc.size(lc.w(self._form) - _M.LEFT_MARGIN - _M.RIGHT_MARGIN - 60, lc.bottom(ico) - _M.BOTTOM_MARGIN - 50))
    lc.addChildToPos(self._form, listBG, cc.p(lc.w(self._form) / 2, lc.h(listBG) / 2 + _M.BOTTOM_MARGIN + 30))
    
    local list = lc.List.createV(cc.size(lc.w(listBG) - 40, lc.h(listBG) - 36), 10)
    list:setTouchEnabled(true)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(listBG, list, cc.p(lc.w(listBG) / 2, lc.h(listBG) / 2 + 2))    
    
    local label = V.createBoldRichTextMultiLine(content, V.RICHTEXT_PARAM_LIGHT_S2, lc.w(list) - 30)
    local item = ccui.Widget:create()
    item:setContentSize(label:getContentSize())
    lc.addChildToCenter(item, label)
    
    list:pushBackCustomItem(item)
end

return _M