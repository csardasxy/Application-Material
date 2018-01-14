local _M = class("FindClashFieldsForm", BaseForm)

local FORM_SIZE = cc.size(780, 560)

function _M.create(grade)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(grade)
    return panel
end

function _M:init(grade)
    _M.super.init(self, FORM_SIZE, Str(STR.FIND_CLASH_FIELDS_TITLE), _M.FLAG.SCROLL_H)

    self._grade = grade

    local clipNode = cc.ClippingNode:create()
    clipNode:setContentSize(self._form:getContentSize())
    local stencil = cc.LayerColor:create(lc.Color4B.white, lc.w(self._form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._form))
    stencil:setPosition(V.FRAME_INNER_LEFT, 0)
    clipNode:setStencil(stencil)
    lc.addChildToCenter(self._form, clipNode)
    self._clipNode = clipNode

    local form, btnW, btnH = clipNode, 120, 430

    local btnArrowLeft = V.createArrowButton(true, cc.size(btnW, btnH), function(sender) self:onBtnArrow(sender) end)
    lc.addChildToPos(form, btnArrowLeft, cc.p(_M.FRAME_THICK_LEFT + btnW / 2 - 10, lc.h(form) / 2))
    self._btnArrowLeft = btnArrowLeft
    if grade == Data.FindClashGrade.bronze then btnArrowLeft:setVisible(false) end

    local btnArrowRight = V.createArrowButton(false, cc.size(btnW, btnH), function(sender) self:onBtnArrow(sender) end)
    lc.addChildToPos(form, btnArrowRight, cc.p(lc.w(form) - _M.FRAME_THICK_RIGHT - btnW / 2 + 10, lc.h(form) / 2))
    self._btnArrowRight = btnArrowRight
    if grade == Data.FindClashGrade.legend then btnArrowRight:setVisible(false) end
    
    local area = self:createArea(grade)
    lc.addChildToPos(form, area, cc.p(lc.w(form) / 2, _M.FRAME_THICK_BOTTOM + 30 + lc.h(area) / 2))
    self._fieldArea = area
end

function _M:createArea(grade)
    local area = lc.createNode()
    area:setCascadeOpacityEnabled(true)

    local field = V.createClashFieldArea(grade, nil, true)
    field._bg:setVisible(false)
    field:setCascadeOpacityEnabled(true)

    local chests = {}
    for i = 1, 5 do
        local chest = V.createClashFieldChest(grade, i, i <= 3 and Data.CardQuality.R or (i <= 5 and Data.CardQuality.SR or Data.CardQuality.UR), true)
        chest:setCascadeOpacityEnabled(true)
        table.insert(chests, chest)
    end

    local w, h = lc.w(field), lc.h(field) + 8 + lc.h(chests[1])
    area:setContentSize(w, h)

    lc.addChildToPos(area, field, cc.p(lc.w(area) / 2, lc.h(area) - lc.h(field) / 2))

    local x, y = -86, lc.bottom(field) - 8
    for _, chest in ipairs(chests) do
        lc.addChildToPos(area, chest, cc.p(x + lc.w(chest) / 2, y- lc.h(chest) / 2))
        x = x + lc.w(chest) + 35
    end

    return area
end

function _M:onBtnArrow(arrow)
    self._btnArrowLeft:setVisible(true)
    self._btnArrowRight:setVisible(true)

    local offset, x, y = lc.w(self._form), lc.cw(self._form), lc.y(self._fieldArea)
    local nextGrade, nextFieldArea
    if arrow == self._btnArrowLeft then
        nextGrade = self._grade - 1
    else
        nextGrade = self._grade + 1
        offset = -offset
    end

    nextFieldArea = self:createArea(nextGrade)

    self._btnArrowLeft:setVisible(nextGrade ~= Data.FindClashGrade.bronze)
    self._btnArrowRight:setVisible(nextGrade ~= Data.FindClashGrade.legend)

--    nextFieldArea:setOpacity(0)
    lc.addChildToPos(self._clipNode, nextFieldArea, cc.p(x - offset, y))

    local curFieldArea, duration = self._fieldArea, lc.absTime(0.5)
    curFieldArea:stopAllActions()
    curFieldArea:runAction(lc.sequence(lc.ease(lc.moveTo(duration, x + offset, y), "BackO"), lc.remove()))

    nextFieldArea:runAction(lc.ease(lc.moveTo(duration, x, y), "BackO"))
    self._fieldArea = nextFieldArea
    self._grade = nextGrade
end

return _M