local _M = class("GroupInfoForm", BaseForm)

local FORM_SIZE = cc.size(710, 600)
local RANK_AREA_SIZE = cc.size(570, 310)

function _M.create(group)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(group)
    return panel
end

function _M:init(group)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))
    local form = self._form

    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(form, titleBg, cc.p(lc.w(form) / 2, lc.h(form) - lc.h(titleBg) / 2))

    local title = V.createTTFStroke(Str(STR.GROUP_INFO), V.FontSize.M2)
    lc.addChildToCenter(titleBg, title)
    
    -- user icon and server
    local GroupWidget = require("GroupWidget")
    local groupWidget = GroupWidget.create(group, bor(GroupWidget.Flag.NAME, GroupWidget.Flag.REGION), 1.0)
    lc.addChildToPos(form, groupWidget, cc.p(lc.cw(self._form), lc.bottom(titleBg) - 30 - lc.h(groupWidget) / 2))
--    lc.addChildToPos(form, groupWidget, cc.p(_M.FRAME_THICK_LEFT + 40 + lc.w(groupWidget) / 2, lc.bottom(titleBg) - 30 - lc.h(groupWidget) / 2))

    -- detail info
    local area = lc.createSprite({_name = "group_avatars_bg", _crect = cc.rect(1, 1, 2, 2), _size = cc.size(lc.w(form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, 200)})
    lc.addChildToPos(form, area, cc.p(lc.cw(form), 50 + lc.ch(area) + V.FRAME_INNER_BOTTOM))
    local listTitle = V.createTTF(Str(STR.GROUP)..Str(STR.UNION_MEMBER), V.FontSize.S1)
    lc.addChildToPos(form, listTitle, cc.p(lc.cw(form), lc.top(area) + lc.ch(listTitle) + 10))

    local startX = 0
    local members = group._members
    for i = 1, Data.GROUP_NUM do
        local item = V.createUnionGroupMemItem(group._id ,members[i], false, false)
        item._canOperate = false
        lc.addChildToPos(area, item, cc.p(startX + i * 120 - 30, lc.ch(area)))
    end

    for i = Data.GROUP_NUM + 1, 5 do
        local lockedSpr = lc.createSprite("group_mem_lock")
        lc.addChildToPos(area, lockedSpr, cc.p(startX + i * 120 - 30, lc.ch(area) + 5))
    end

end

function _M:onEnter()
    _M.super.onEnter(self)
end

function _M:onExit()
    _M.super.onExit(self)
end

return _M