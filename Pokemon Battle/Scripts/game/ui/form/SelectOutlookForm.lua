local _M = class("SelectOutlookForm", BaseForm)

local FORM_SIZE = cc.size(840, 640)


local TAB = {
    avatar = 1,
    rect = 2, 
    image = 3,
}


function _M.create(tanIndex)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init(tanIndex)
    _M.super.init(self, FORM_SIZE, Str(STR.CHANGE_OUTLOOK), 0)
    self._initTabIndex = tabIndex

    local tabArea = V.createHorizontalTabListArea2(lc.w(self._form) - 40, nil, function(tab) self:showTab(tab) end)
    lc.addChildToPos(self._form, tabArea, cc.p(_M.LEFT_MARGIN + lc.w(tabArea) / 2 - 12, lc.h(self._form) - 104), 3)
    self._tabArea = tabArea
    local bgPanel = lc.createSprite{_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._frame) - V.FRAME_INNER_RIGHT - V.FRAME_INNER_LEFT, lc.bottom(self._tabArea) - 10)}
    lc.addChildToPos(self._frame, bgPanel, cc.p(lc.cw(self._frame), lc.bottom(self._tabArea) - lc.ch(bgPanel) + 5))
    self._bgPanel = bgPanel

    local areas = {}
    local areaW, areaH = lc.w(self._bgPanel), lc.h(self._bgPanel)
    
    areas[TAB.rect] = require("SelectAvatarFrameArea").create(areaW, areaH)
    areas[TAB.avatar] = require("SelectAvatarArea").create(areaW, areaH)
    areas[TAB.image] = require("SelectAvatarImageArea").create(areaW, areaH)

    for _, area in ipairs(areas) do
        lc.addChildToCenter(bgPanel, area)
        area:setVisible(false)
    end

    self._areas = areas

    local tabs = {
        {_str = Str(STR.CHANGE_ICON), _index = TAB.avatar},
        {_str = Str(STR.CHANGE_RECT), _index = TAB.rect},
        {_str = Str(STR.CHANGE_IMAGE), _index = TAB.image},
    }
    
    self._tabArea:resetTabs(tabs)
    self:updateTabs()
end

function _M:updateTabs()
    local tabArea, focusedIndex = self._tabArea
    if tabArea._focusedTab then
        focusedIndex = tabArea._focusedTab._index
    else
        focusedIndex = TAB.avatar
    end

    tabArea:showTab(focusedIndex, true)
end

function _M:showTab(tab)
    for i, area in ipairs(self._areas) do
        if i == tab._index then
            area:updateList()
            area:setVisible(true)
        else 
            area:setVisible(false)
        end
    end
end

return _M