lc = lc or {}

local _M = class("LC_UI_List", lc.ExtendUIWidget)

_M.DEFAULT_CACHE_COUNT = 10
_M.TAG_EMPTY_LABEL = 1000

function _M.createH(size, boundMargin, itemMargin)
    return _M.create(size, lc.Dir.horizontal, boundMargin, itemMargin)
end

function _M.createV(size, boundMargin, itemMargin)
    return _M.create(size, lc.Dir.vertical, boundMargin, itemMargin)
end

function _M.create(size, dir, boundMargin, itemMargin)
    local list = _M.new(lc.EXTEND_LIST)

    if dir == lc.Dir.horizontal then
        list:setDirection(ccui.ScrollViewDir.horizontal)
        list:setGravity(ccui.ListViewGravity.centerVertical)
    else
        list:setDirection(ccui.ScrollViewDir.vertical)
        list:setGravity(ccui.ListViewGravity.centerHorizontal)
    end

    list:setContentSize(size)
    list:setBoundMargin(boundMargin or 20)
    list:setItemsMargin(itemMargin or 20)
    list:setBounceEnabled(true)
    list:setCascadeOpacityEnabled(true)

    return list
end

-- @info Bind data to the list which is used to fill new items during scrolling
-- @param   data                data table
-- @param   dataFunc            function to set the specified data to the item. prototype is func(item, data[i])
-- @param   cacheCount          specified cache count
-- @param   keepCount           when the list is scroll to the edge, treat some oob items as not out of bound.
--                              This feature is useful if the size of the items in the list may be changed.
--                              But the size delta should not bigger than the total height of specified count(keepCount) of items

function _M:bindData(data, dataFunc, cacheCount, keepCount)
    self:removeAllItems()
    self._data = data

    if data then
        self._keepCount = keepCount or 0
        self._cacheCount = (cacheCount or _M.DEFAULT_CACHE_COUNT)
        self._dataFunc = dataFunc
        self._indexBegin = 1
        self._indexEnd = self._cacheCount

        self:addScrollViewEventListener(function(sender, type) self:onScroll(type) end)
    else
        self:addScrollViewEventListener(function() end)
    end
end

-- @info Check whether the list is empty

function _M:checkEmpty(emptyLabel)
    if #self:getItems() == 0 then
        if emptyLabel then
            local label
            if type(emptyLabel) == "string" then
                label = V.createTTF(emptyLabel, V.FontSize.S1, V.COLOR_TEXT_LIGHT)
            else
                label = emptyLabel
            end

            self:removeChildByTag(_M.TAG_EMPTY_LABEL)
            lc.addChildToCenter(self, label, 0, _M.TAG_EMPTY_LABEL)

            self:runAction(lc.sequence(0, function() 
                self:getInnerContainer():setContentSize(self:getContentSize())
                self:getInnerContainer():setPosition(0, 0)
            end))
        end
        return true
    end

    return false
end

-- @info Get items which are out of the bounds
-- @param   type                list scrool event type
-- @return  dir                 list moving direction
--          oobItems            out of bound items
--          refItem             the reference item which is closed to the out of bound items

function _M:checkOutOfBoundItems(type)
    local items = self:getItems()
    local oobItems, refItem, dir = {}

    if type == ccui.ScrollviewEventType.scrollToRight then
        local bound = lc.w(self)
        local innerW = self:getInnerContainerSize().width

        for i = 1, #items do
            local item = items[i]
            if innerW - lc.right(item) > bound then
                table.insert(oobItems, item)
            else
                break
            end
        end

        refItem = items[#items]
        dir = lc.Dir.left

    elseif type == ccui.ScrollviewEventType.scrollToLeft then
        local bound = lc.w(self)
        
        for i = #items, 1, -1 do
            local item = items[i]
            if lc.left(item) > bound then
                table.insert(oobItems, item)
            else
                break
            end
        end

        refItem = items[1]
        dir = lc.Dir.right

    elseif type == ccui.ScrollviewEventType.scrollToBottom then
        local bound = lc.h(self)

        for i = 1, #items do
            local item = items[i]
            if lc.bottom(item) > bound then
                table.insert(oobItems, item)
            else
                break
            end
        end

        refItem = items[#items]
        dir = lc.Dir.top

    elseif type == ccui.ScrollviewEventType.scrollToTop then
        local bound = lc.h(self)
        local innerH = self:getInnerContainerSize().height

        for i = #items, 1, -1 do
            local item = items[i]
            if innerH - lc.top(item) > bound then
                table.insert(oobItems, item)
            else
                break
            end
        end

        refItem = items[1]
        dir = lc.Dir.bottom
    end

    -- Keep items as not out of bound
    for i = 1, self._keepCount do
        table.remove(oobItems)
    end

    return dir, oobItems, refItem
end

-- @info List scroll event handler
-- @param type                  scroll type to indicate

function _M:onScroll(type)
    if self._data == nil or self._dataFunc == nil then return end

    local dir, oobItems, refItem = self:checkOutOfBoundItems(type)

    -- Do not need to do anything
    if dir == nil or refItem == nil then return end

    -- Process all out of bound items
    local dataCount = (self._data._count or #self._data)
    if dir == lc.Dir.top or dir == lc.Dir.left then
        local remain = dataCount - self._indexEnd
        if remain < #oobItems then
            for i = 1, #oobItems - remain do
                table.remove(oobItems)
            end
        end

        for _, item in ipairs(oobItems) do
            self._indexEnd = self._indexEnd + 1
            self._dataFunc(item, self._data[self._indexEnd])
        end
        self._indexBegin = self._indexEnd - self._cacheCount + 1

    elseif dir == lc.Dir.bottom or dir == lc.Dir.right then
        local remain = self._indexBegin - 1
        if remain < #oobItems then
            for i = 1, #oobItems - remain do
                table.remove(oobItems)
            end
        end

        for _, item in ipairs(oobItems) do
            self._indexBegin = self._indexBegin - 1
            self._dataFunc(item, self._data[self._indexBegin])
        end
        self._indexEnd = self._indexBegin + self._cacheCount - 1
    end 

    -- Update the position of internal container
    if #oobItems > 0 then
        -- Append all edited oobItems to the specified edge
        local isAddToBegin = (refItem == self:getItem(0))
        for _, item in ipairs(oobItems) do
            item:retain()
            self:removeItemWithCleanup(item, false)
            if isAddToBegin then
                self:insertCustomItem(item, 0)
            else
                self:pushBackCustomItem(item)
            end
            item:release()
        end

        -- Force update inner container's position
        local inner = self:getInnerContainer()
        if dir == lc.Dir.left then
            self:forceDoLayout()
            lc.offset(inner, lc.w(inner) - lc.right(refItem) - self:getEndMargin())

        elseif dir == lc.Dir.right then
            self:forceDoLayout()
            lc.offset(inner, -lc.left(refItem) + self:getStartMargin())

        elseif dir == lc.Dir.top then
            local oldH = lc.h(inner)
            self:forceDoLayout()
            lc.offset(inner, 0, -lc.bottom(refItem) + math.max(0, lc.h(inner) - oldH) + self:getEndMargin())

        elseif dir == lc.Dir.bottom then
            self:forceDoLayout()
            lc.offset(inner, 0, lc.h(inner) - lc.top(refItem) - self:getStartMargin())
        end
    end
end

function _M:setDataToItems(isFromBegin)
    if self._data == nil or self._dataFunc == nil then return end

    if isFromBegin then
        self._indexBegin = 1
        self._indexEnd = self._cacheCount
    else
        local dataCount = (self._data._count or #self._data)
        self._indexBegin = dataCount - self._cacheCount + 1
        self._indexEnd = dataCount
    end
    
    local items = self:getItems()
    local index = self._indexBegin
    for _, item in ipairs(items) do
        self._dataFunc(item, self._data[index])
        index = index + 1
    end
end

-- @info Scroll the list directly to the left

function _M:gotoLeft()
    if self:getDirection() ~= ccui.ScrollViewDir.horizontal then return end

    self:setDataToItems(true)
    self:jumpToLeft()
end

-- @info Scroll the list directly to the right

function _M:gotoRight()
    if self:getDirection() ~= ccui.ScrollViewDir.horizontal then return end

    self:setDataToItems(false)
    self:jumpToRight()
end

-- @info Scroll the list directly to the top

function _M:gotoTop()
    if self:getDirection() ~= ccui.ScrollViewDir.vertical then return end

    self:setDataToItems(true)
    self:jumpToTop()
end

-- @info Scroll the list directly to the bottom

function _M:gotoBottom()
    if self:getDirection() ~= ccui.ScrollViewDir.vertical then return end

    self:setDataToItems(false)
    self:jumpToBottom()
end

-- @info Scroll the list directly to the pos relative to the inner container

function _M:gotoPos(pos)
    pos = (pos >= 0 and pos or 0)

    self:setDataToItems(false)

    local inner = self:getInnerContainer()
    local innerSize = inner:getContentSize()

    if self:getDirection() == ccui.ScrollViewDir.vertical then
        local h = innerSize.height - lc.h(self)
        if h > 0 then
            self:jumpToPercentVertical(pos * 100 / h)
        end
    else
        local w = innerSize.width - lc.w(self)
        if w > 0 then
            self:jumpToPercentHorizontal(pos * 100 / w)
        end
    end
end

function _M:isAtBegin()
    local inner = self:getInnerContainer()
    local x, y = inner:getPosition()
    local listSize, innerSize = self:getContentSize(), inner:getContentSize()
    if self:getDirection() == ccui.ScrollViewDir.vertical then
        return math.abs(y - (listSize.height - innerSize.height)) < 1
    else
        return math.abs(x) < 1
    end
end

function _M:isAtEnd()
    local inner = self:getInnerContainer()
    local x, y = inner:getPosition()
    if self:getDirection() == ccui.ScrollViewDir.vertical then
        return math.abs(y) < 1
    else
        return math.abs(x - (listSize.width - innerSize.width)) < 1
    end
end

lc.List = _M
return _M
