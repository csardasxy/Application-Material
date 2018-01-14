local _M = class("ItemList", lc.ExtendUIWidget)

_M.ModeType = 
{
    skin = 1,
}

function _M.create(size, itemSize, emptyTip, createItemFunc, updateItemFunc)
    local list = _M.new(lc.EXTEND_LAYOUT)
    list:setTouchEnabled(not GuideManager.isGuideEnabled())    
    list:setContentSize(size)
    list:setCascadeOpacityEnabled(true)

    list._itemSize = itemSize
    list._emptyTip = emptyTip
    list._createItemFunc = createItemFunc
    list._updateItemFunc = updateItemFunc   
    
    list:initPage()
    
    return list
end

function _M:initPage()
    local w = self._itemSize.width
    local h = self._itemSize.height
    local r, c = 2, 5
    local gapH = (lc.h(self) - r * h) / (r + 1)
    local gapW = (lc.w(self) - c * w) / (c + 1)
    while true do
        if gapW < 10 then 
            c = c - 1
            gapW = (lc.w(self) - c * w) / (c + 1)
        else
            break
        end
    end
    self._row, self._col = r, c
    local x = gapW + w / 2
    local y = gapH + h / 2
    self._itemRow, self._itemCol = r, c
    self._curPage = 1
    self._totalPage = 1

    self._items = {{}, {}}
    for i = 1, r do
        for j = 1, c do
            local item = self._createItemFunc()
            lc.addChildToPos(self, item, cc.p(x + (j - 1) * (w + gapW), y + (2 - i) * (h + gapH)))
            self._items[i][j] = item
        end
    end

    local pos = cc.p(self._items[1][1]:getPositionX() - V.CARD_SIZE.width / 2 - 10, lc.h(self) / 2)
    self._pageLeft = V.createPageArrow(true, pos, function() 
        if self._curPage > 1 then self._curPage = self._curPage - 1 end
        self:updatePage(false)
    end)
    lc.addChildToPos(self, self._pageLeft, pos)

    pos = cc.p(self._items[1][self._itemCol]:getPositionX() + V.CARD_SIZE.width / 2 + 10, lc.h(self) / 2)
    self._pageRight = V.createPageArrow(false, pos, function()
        if self._curPage < self._totalPage then self._curPage = self._curPage + 1 end
        self:updatePage(false)
    end)
    lc.addChildToPos(self, self._pageRight, pos)
    
    local pageLabel = V.createBMFont(V.BMFont.huali_26, "1/1")
    lc.addChildToPos(self, pageLabel, cc.p(lc.w(self) - 64, lc.h(self) + 20))
    self._pageLabel = pageLabel

    local tip = cc.Label:createWithTTF(self._emptyTip, V.TTF_FONT, V.FontSize.S1)
    tip:setPosition(lc.cw(self), lc.ch(self))
    tip:setColor(V.COLOR_LABEL_LIGHT)
    self:addProtectedChild(tip)
    self._tip = tip
end  

function _M:updatePage(isReset)
    self._totalPage = (#self._data == 0) and 1 or (math.floor((#self._data - 1) / (self._row * self._col)) + 1)
    if isReset then
        self._curPage = 1
    end

     for i = 1, self._row do
        for j = 1, self._col do
            local item = self._items[i][j]
            local data = self._data[(self._curPage - 1) * self._row * self._col + (i - 1) * self._col + j]
            self._updateItemFunc(item, data)
        end
    end

    self._pageLabel:setString(string.format("%s%d/%d%s", lc.str(STR.PAGE_PREFIX), self._curPage, self._totalPage, lc.str(STR.PAGE_SUFFIX)))

    self._pageLeft:setVisible(self._curPage > 1)
    self._pageLeft:float()
    
    self._pageRight:setVisible(self._curPage < self._totalPage)
    self._pageRight:float()

    self._tip:setVisible(#self._data == 0)
end

function _M:setData(data)
    self._data = data
end

function _M:onEnter()
    self._listeners = {}

    self:updatePage(true)

    --[[
    local listener = lc.addEventListener(Data.Event.card_list_dirty, function(event)
        if self._type == event._type then
            self:refresh(false)
        end
    end)
    table.insert(self._listeners, listener)
    ]]
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
    self._listeners = {}
end

function _M:onCleanup()
    
end

return _M