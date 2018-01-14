local _M = class("ImpeachForm", BaseForm)

local FORM_SIZE = cc.size(640, 580)

function _M.create(leader)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(leader)
    return panel
end

function _M:init(leader)
    _M.super.init(self, FORM_SIZE, Str(STR.UNION_IMPEACH)..Str(STR.LEADER), bor(_M.FLAG.PAPER_BG, _M.FLAG.BASE_TITLE_BG))

    self._leader = leader

    local form = self._form
    local cx = lc.w(form) / 2

    local tip = V.createBoldRichText(Str(STR.UNION_IMPEACH_TIP), V.RICHTEXT_PARAM_DARK_S1, 500)
    lc.addChildToPos(form, tip, cc.p(cx, lc.bottom(self._titleFrame) - 50))

    local bg = lc.createSprite{_name = "img_com_bg_10", _crect = V.CRECT_COM_BG10, _size = cc.size(500, 270)}
    lc.addChildToPos(form, bg, cc.p(cx, lc.bottom(tip) - 20 - lc.h(bg) / 2))

    local bgTitle = V.addDecoratedLabel(bg, Str(STR.UNION_IMPEACH_MEMBERS), cc.p(lc.w(bg) / 2, lc.h(bg) - 40), 26)

    local union, impeachNum, isImpeached = P._playerUnion:getMyUnion(), 0
    if union then
        local members, y = union._members, lc.bottom(bgTitle) - 16
        if next(union._impeach) then
            for id in pairs(union._impeach) do
                local mem = members[id]
                if mem then
                    local line = V.createLevelNameArea(mem._level, mem._name)
                    lc.addChildToPos(bg, line, cc.p(130, y - lc.h(line) / 2))
                    y = y - lc.h(line) - 10

                    impeachNum = impeachNum + 1
                end
            end

            isImpeached = (union._impeach[P._id] ~= nil)
        else
            local line = V.createTTF(string.format(Str(STR.LIST_EMPTY_NO_X), Str(STR.UNION_MEMBER)), V.FontSize.S2, V.COLOR_TEXT_DARK)
            lc.addChildToPos(bg, line, cc.p(lc.w(bg) / 2, y - lc.h(line) / 2))
        end
    end

    self._impeachNum = impeachNum

    local btnBack = V.createScale9ShaderButton("img_btn_2", function() self:hide() end, V.CRECT_BUTTON, 140)
    btnBack:addLabel(Str(STR.BACK))
    lc.addChildToPos(form, btnBack, cc.p(cx - 10 - lc.w(btnBack) / 2, 30 + lc.h(btnBack)))

    local btnImpeach = V.createScale9ShaderButton("img_btn_1", function() self:impeach(isImpeached) end, V.CRECT_BUTTON, 140)
    btnImpeach:addLabel(isImpeached and Str(STR.CANCEL)..Str(STR.UNION_IMPEACH) or Str(STR.UNION_IMPEACH))
    lc.addChildToPos(form, btnImpeach, cc.p(cx + 10 + lc.w(btnImpeach) / 2, lc.y(btnBack)))
end

function _M:impeach(isImpeached, isForce)
    if not isForce then
        if self._impeachNum == 4 then
            require("Dialog").showDialog(Str(STR.UNION_IMPEACH_LAST), function() self:impeach(isImpeached, true) end)
            return
        end
    end

    -- Send packet
    ClientData.sendUnionImpeach(self._leader._id, isImpeached)

    self:hide()
end

return _M