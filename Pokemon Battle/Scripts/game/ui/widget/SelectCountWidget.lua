local _M = class("SelectCountWidget", lc.ExtendCCNode)

_M.HEIGHT = 56

local GAP = 6
local BUTTON_TOTAL_W = 100 * 2 + 60 * 2 + GAP * 4

function _M.create(callback, countW, max, min)
    local widget = _M.new(lc.EXTEND_NODE)
    widget:setAnchorPoint(0.5, 0.5)
    widget:init(callback, countW, max, min)
    return widget
end

function _M:init(callback, countW, max, min)
    countW = countW or 100
    local size = cc.size(BUTTON_TOTAL_W + countW, _M.HEIGHT)
    self:setContentSize(size)

    self._max = max
    self._min = min or 1
    self._callback = callback

    local y = _M.HEIGHT / 2
    
    local countBg = lc.createSprite{_name = "img_com_bg_3", _crect = V.CRECT_COM_BG3, _size = cc.size(countW, _M.HEIGHT)}
    lc.addChildToPos(self, countBg, cc.p(lc.w(self) / 2, y))
    
    local countVal = V.createTTF("1", V.FontSize.M1, V.COLOR_TEXT_DARK)
    lc.addChildToPos(countBg, countVal, cc.p(lc.w(countBg) / 2, lc.h(countBg) / 2 + 2))    
    self._countVal = countVal
    
    local appendNum = function(btn, val)
        local icon = btn._icon
        lc.offset(icon, -18)
        local value = V.createBMFont(V.BMFont.huali_32, tostring(val))
        lc.addChildToPos(btn, value, cc.p(lc.right(icon) + 2 + lc.w(value) / 2, lc.y(icon) + 2))
    end

    local btnReduceTen = V.createScale9ShaderButton("img_btn_1_s", function() self:changeCount(-10) end, V.CRECT_BUTTON_S, 100)
    btnReduceTen:addIcon("img_icon_minus")
    lc.addChildToPos(self, btnReduceTen, cc.p(lc.w(btnReduceTen) / 2, y))
    appendNum(btnReduceTen, 10)
    self._btnReduceTen = btnReduceTen

    local btnReduceOne = V.createScale9ShaderButton("img_btn_1_s", function() self:changeCount(-1) end, V.CRECT_BUTTON_S, 60)
    btnReduceOne:addIcon("img_icon_minus")
    lc.addChildToPos(self, btnReduceOne, cc.p(lc.right(btnReduceTen) + 6 + lc.w(btnReduceOne) / 2, y))
    self._btnReduceOne = btnReduceOne
    
    local btnAddOne = V.createScale9ShaderButton("img_btn_1_s", function() self:changeCount(1) end, V.CRECT_BUTTON_S, 60)
    btnAddOne:addIcon("img_icon_add")
    lc.addChildToPos(self, btnAddOne, cc.p(lc.right(countBg) + 6 + lc.w(btnAddOne) / 2, y))
    self._btnAddOne = btnAddOne
    
    local btnAddTen = V.createScale9ShaderButton("img_btn_1_s", function() self:changeCount(10) end, V.CRECT_BUTTON_S, 100)
    btnAddTen:addIcon("img_icon_add")
    lc.addChildToPos(self, btnAddTen, cc.p(lc.right(btnAddOne) + 6 + lc.w(btnAddTen) / 2, y))
    appendNum(btnAddTen, 10)
    self._btnAddTen = btnAddTen
end

function _M:changeCount(delta)
    local count = tonumber(self._countVal:getString())
    count = count + delta

    if count < self._min then
        count = self._min
    else
        if self._max and count > self._max then count = self._max end
    end

    self._countVal:setString(tostring(count))

    if self._callback then
        self._callback(count)
    end
end

function _M:getCount()
    return tonumber(self._countVal:getString())
end

return _M