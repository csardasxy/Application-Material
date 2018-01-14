local _M = class("BattleHelpForm", BaseForm)

local FORM_SIZE = cc.size(900, 720)

function _M.create(...)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(...)
    
    return panel    
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.HELP), 0)
    
    -- data
    self._pageContents = {
        [1] = {_title = 1, {_content = 2}},
        [2] = {_title = 3, {_content = 4, _image = "1"}, {_content = 5, _image = "2"}},
        [3] = {_title = 6, {_content = 7}},
        [4] = {_title = 8, {_content = 9}},
        [5] = {_title = 10, {_content = 11, _image = "3"}, {_content = 12, _image = "4"}},
        [6] = {_title = 13, {_content = 14}},
        [7] = {_title = 15, {_content = 16, _image = "5"}},
    }

    self._pageTexts = {}
    for id, info in ipairs(Data._helpInfo) do
        if info._type == Data.HelpType.battle then
            table.insert(self._pageTexts, Str(info._nameSid, true))
        end
    end

    self._curPage = 1
    self._totalPage = #self._pageContents

    -- ui
    local list = lc.List.createV(cc.size(lc.w(self._form) - _M.LEFT_MARGIN - _M.RIGHT_MARGIN, lc.bottom(self._titleFrame) - _M.BOTTOM_MARGIN + 10), 20, 30)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._form, list, cc.p(lc.w(self._form) / 2, lc.bottom(self._titleFrame) - lc.h(list) / 2 + 8))
    self._list = list

    local pageLeft = V.createShaderButton('img_page_right', function() 
        if self._curPage > 1 then self._curPage = self._curPage - 1 end
        self:refresh()
    end)
    pageLeft:setAnchorPoint(0, 0.5)
    pageLeft:setFlippedX(true)
    pageLeft:setTouchRect(cc.rect(-20, -20, lc.w(pageLeft) + 40, lc.h(pageLeft) + 40))
    local pos = cc.p(-10, lc.ch(self._form))
    pageLeft._pos = pos
    lc.addChildToPos(self._form, pageLeft, pos)
    pageLeft.float = function(self)
        self:stopAllActions()
        self:setPosition(self._pos)
        self:runAction(lc.rep(lc.sequence({lc.moveTo(0.8, cc.p(self._pos.x - 8, self._pos.y)), lc.moveTo(0.8, self._pos)}))) 
    end
    self._pageLeft = pageLeft

    local pageRight = V.createShaderButton('img_page_right', function() 
        if self._curPage < self._totalPage then self._curPage = self._curPage + 1 end
        self:refresh()
    end)
    pageRight:setAnchorPoint(0, 0.5)
    pageRight:setTouchRect(cc.rect(-20, -20, lc.w(pageRight) + 40, lc.h(pageRight) + 40))
    pos = cc.p(lc.w(self._form) + 10, lc.ch(self._form))
    pageRight._pos = pos
    lc.addChildToPos(self._form, pageRight, pos)
    pageRight.float = function(self)
        self:stopAllActions()
        self:setPosition(self._pos)
        self:runAction(lc.rep(lc.sequence({lc.moveTo(0.8, cc.p(self._pos.x + 8, self._pos.y)), lc.moveTo(0.8, self._pos)}))) 
    end
    self._pageRight = pageRight

    -- reset
    self:refresh()
end

function _M:refresh()
    if self._curPage == 1 then
        self._pageLeft:setVisible(false)
    else
        self._pageLeft:setVisible(true)
        self._pageLeft:float()
    end

    if self._curPage == self._totalPage then
        self._pageRight:setVisible(false)
    else
        self._pageRight:setVisible(true)
        self._pageRight:float()
    end
    
    self._list:removeAllItems()

    -- title
    local contents = self._pageContents[self._curPage]

    local str = self._pageTexts[contents._title]
    self._list:pushBackCustomItem(self:createTitle(str))

    for i = 1, #contents do
        local content = contents[i]

        if content._image then
            local dir = string.format("res/jpg/battle_help_%s.jpg", content._image)
            self._list:pushBackCustomItem(self:createImage(dir))
        end
        if content._content then
            local str = self._pageTexts[content._content]
            self._list:pushBackCustomItem(self:createText(str))
        end
    end
end

function _M:createTitle(str)
    local layout = ccui.Layout:create()
    layout:setContentSize(cc.size(lc.w(self._list), 60))
    layout:setAnchorPoint(0.5, 0.5)

    local bg = lc.createSprite({_name = "img_com_bg_49", _size = cc.size(lc.w(layout), 48), _crect = cc.rect(50, 24, 1, 1)})
    lc.addChildToPos(layout, bg, cc.p(lc.cw(bg), lc.ch(layout)))

    local title = V.createTTF(str, V.FontSize.M1)
    lc.addChildToPos(layout, title, cc.p(lc.cw(title) + 20, lc.ch(layout)))

    return layout
end

function _M:createText(str)
    local layout = ccui.Layout:create()

    local text = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S1, lc.w(self._list) - 40)
    layout:setContentSize(cc.size(lc.w(self._list), lc.h(text) + 40))
    layout:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(layout, text, cc.p(lc.cw(text) + 20, lc.ch(layout)))

    return layout
end

function _M:createImage(dir)
    local layout = ccui.Layout:create()

    local sprite = lc.createSpriteWithMask(dir)
    layout:setContentSize(lc.w(self._list), lc.h(sprite) + 20)
    layout:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(layout, sprite, cc.p(lc.cw(layout), lc.ch(layout)))

    return layout
end

function _M:onEnter()
    _M.super.onEnter(self)
end

function _M:onExit()
    _M.super.onExit(self)
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    for i = 1, #self._pageContents do
        local contents = self._pageContents[i]
        for i = 1, #contents do
            local content = contents[i]

            if content._image then
                local dir = string.format("res/jpg/battle_help_%s.jpg", content._image)
                lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename(dir))
            end
        end
    end
end

return _M