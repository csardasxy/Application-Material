--- Base class of all top most panel
-- @class TopMostPanel

local _Base = class("TopMostPanel", BasePanel)

_Base.FRAME_THICK = 8
_Base.FRAME_THICK_BOTH = _Base.FRAME_THICK + _Base.FRAME_THICK

_Base.SHADOW_L = 10
_Base.SHADOW_R = 10
_Base.SHADOW_H = _Base.SHADOW_L + _Base.SHADOW_R
_Base.SHADOW_T = 8
_Base.SHADOW_B = 12
_Base.SHADOW_V = _Base.SHADOW_T + _Base.SHADOW_B

function _Base.create(size)
    if not _Base.canCreate() then return nil end

    local panel = _Base.new(lc.EXTEND_WIDGET)
    panel:init(size)
    return panel
end

function _Base.canCreate()
    if _Base._touchLayer and _Base._touchLayer._isTouchOnLinkNode then
        return false
    else
        return true
    end
end

function _Base:init(size)
    _Base.super.init(self, true, true)

    self._isNeedTransparent = true

    if _Base._touchLayer == nil then
        local checkTouchOnLinkNodes = function(gPos)
            if _Base._touchLayer._linkNodes then
                for _, node in ipairs(_Base._touchLayer._linkNodes) do
                    if lc.contain(node, gPos) then
                        return true
                    end
                end
            end

            return false
        end

        local layer = V.createTouchLayer()
        layer:retain()
        layer._touchHandler = function(evt, gx, gy)
            local gPos = cc.p(gx, gy)

            if evt == "began" then
                local panel = BasePanel._topMostPanel
                if panel then
                    if not lc.contain(panel, gPos) then
                        if checkTouchOnLinkNodes(gPos) then
                            _Base._touchLayer._isTouchOnLinkNode = true
                        end

                        panel:hide()
                    end
                else
                    _Base._touchLayer._isTouchOnLinkNode = false
                end

                return 0
            end
        end
        _Base._touchLayer = layer
    end

    self:setContentSize(size)
end

--- Set the link node
-- @description Link node is treated as the trigger node to show the top most panel. The panel can be linked to multiple nodes.
-- @param node              The linked node
function _Base:linkNode(node)
    local touchLayer = _Base._touchLayer
    touchLayer._linkNodes = touchLayer._linkNodes or {}
    table.insert(touchLayer._linkNodes, node)
end

--- Overload the show panel function
-- @param zOrder            The zorder of the panel. Ususally this value does not need be set.
function _Base:show(zOrder)
    _Base.super.show(self, zOrder)
    BasePanel._topMostPanel = self
end

--- Overload the hide panel function
function _Base:hide()
    if _Base._touchLayer then
        _Base._touchLayer._linkNodes = nil
    end

    _Base.super.hide(self)
    BasePanel._topMostPanel = nil
end

--- Defines the panel only contains button list
-- @class ButtonList

local ButtonList = class("ButtonList", _Base)

ButtonList.MARGIN = 6
ButtonList.GAP = 4

function ButtonList.create(size, titleStr)
    if not _Base.canCreate() then return nil end

    local panel = ButtonList.new(lc.EXTEND_WIDGET)
    panel._titleStr = titleStr
    panel:init(size)
    return panel
end

function ButtonList:init(size)
    -- Overload setContentSize()
    local superSetContentSize = self.setContentSize
    self.setContentSize = function(self, w, h)
        if type(w) == "table" then
            h = w.height
            w = w.width
        end

        superSetContentSize(self, w, h)

        self._bg:setContentSize(w, h)
        self._bg:setPosition(w / 2, h / 2)
    end

    local bg = V.createFramedShadowColorBg(size, color or cc.c3b(40, 50, 60))
    self._bg = bg
    self:addChild(bg)

    ButtonList.super.init(self, size)
end

--- Defines the panel only contains button list
-- @param buttonDefs        A table to define all button parameters. DEF = {_str|_sid|_area, _handler, _focus, _w, _h}
function ButtonList:setButtonDefs(buttonDefs)
    local defWidth = lc.w(self) - 40

    self._buttons = {}
    local buttonsHeight = 0

    for _, def in ipairs(buttonDefs) do
        local width = def._w or defWidth
        if def._isSeparator then
            local separator = lc.createImageView("img_divide_line_5")
            separator:setScaleX((width + 10) / lc.w(separator))
            separator:setOpacity(100)

            buttonsHeight = buttonsHeight + lc.h(separator) + ButtonList.GAP
            table.insert(self._buttons, separator)
        else
            local height = def._h or V.CRECT_BUTTON_S.height

            local button = V.createShaderButton(nil, 
                function()
                    if def._handler then
                        def._handler()
                    end
                    BasePanel.hideTopMost()
                end)
            button:setContentSize(cc.size(width, height))

            button:setDisabledShader(V.SHADER_DISABLE)
            button:setEnabled(def._handler ~= nil)

            if def._onButtonCreate then
                def._onButtonCreate(button)
            end

            if def._area then
                button._labelArea = def._area
                lc.addChildToPos(button, def._area, cc.p(width / 2, height / 2 + 1))
            else
                local labelStr = (def._str or Str(def._sid))
                local label = V.createTTF(labelStr, V.FontSize.S1, V.COLOR_TEXT_MENU_WHITE)
                lc.addChildToPos(button, label, cc.p(lc.w(button) / 2, lc.h(button) / 2 + 1))
                button._label = label
            end

            buttonsHeight = buttonsHeight + height + ButtonList.GAP
            table.insert(self._buttons, button)
        end
    end

    local totalHeight = buttonsHeight - ButtonList.GAP + ButtonList.MARGIN + ButtonList.MARGIN + _Base.FRAME_THICK_BOTH

    local titleW, titleH = 0, 0
    if self._titleStr then
        local title = V.createTTF(self._titleStr)
        titleW = lc.w(title)
        titleH = lc.h(title) + 8

        totalHeight = totalHeight + titleH
        lc.addChildToPos(self._bg, title, cc.p(lc.w(self._bg) / 2, totalHeight - lc.h(title) / 2 - 16))

        self._title = title
    end
    
    local listNeedBounce = true
    if totalHeight < lc.h(self) then
        -- Adjust the panel height if the buttons are not enough to fill, or width if title is more widen
        local width = lc.w(self)
        if lc.w(self) < titleW + 30 then
            width = titleW + 30
            self._title:setPositionX(width / 2)
        end

        self:setContentSize(width, totalHeight)
        listNeedBounce = false
    end

    local list = lc.List.createV(cc.size(lc.w(self), lc.h(self) - 12 - titleH), ButtonList.MARGIN, ButtonList.GAP)
    list:setBounceEnabled(listNeedBounce)
    for _, button in ipairs(self._buttons) do
        list:pushBackCustomItem(button)
    end
    
    lc.addChildToPos(self._bg, list, cc.p(0, 6))
end

--- Defines the panel only contains troop list
-- @class TroopList

local TroopList = class("TroopList", ButtonList)

TroopList.WIDTH = 310
TroopList.GAP = 6

function TroopList.create()
    if not _Base.canCreate() then return nil end

    local panel = TroopList.new(lc.EXTEND_WIDGET)
    panel:init(cc.size(TroopList.WIDTH, 0))
    return panel
end

-- @param buttonDefs        A table to define all button parameters. DEF = {_str, _remark, _isDef, _handler}
function TroopList:setButtonDefs(buttonDefs)
    local defWidth = TroopList.WIDTH - ButtonList.MARGIN - ButtonList.MARGIN - _Base.FRAME_THICK_BOTH

    self._items = {}
    local totalHeight = ButtonList.MARGIN + ButtonList.MARGIN + _Base.FRAME_THICK_BOTH - TroopList.GAP

    for _, def in ipairs(buttonDefs) do
        local isUnlocked = (def._handler ~= nil)
        local height = V.CRECT_BUTTON_1_S.height -- + (isUnlocked and 40 or 0)

        local item = ccui.Widget:create()
        item:setContentSize(defWidth, height)

        if isUnlocked then
            --[[
            local remarkBg = lc.createSprite{_name = "img_com_bg_7", _crect = V.CRECT_COM_BG7, _size = cc.size(defWidth - 12, 62)}
            remarkBg:setColor(cc.c3b(140, 120, 80))
            remarkBg:setOpacity(200)
            lc.addChildToPos(item, remarkBg, cc.p(defWidth / 2, lc.h(remarkBg) / 2))

            local remarkStr, remarkClr
            if def._remark == nil or def._remark == "" then
                remarkStr, remarkClr = Str(STR.REMARK_NONE), V.COLOR_TEXT_DARK
            else
                remarkStr, remarkClr = def._remark, V.COLOR_TEXT_LIGHT
            end

            local remark = V.createTTF(remarkStr, V.FontSize.S2, remarkClr)
            lc.addChildToPos(remarkBg, remark, cc.p(lc.w(remarkBg) / 2, 26))
            ]]
        end

        local btnTroop = V.createScale9ShaderButton("img_btn_2_s", 
            function()
                def._handler(1)
                BasePanel.hideTopMost()
            end,
        V.CRECT_BUTTON_1_S, isUnlocked and 204 or (defWidth + _Base.FRAME_THICK_BOTH))

        if isUnlocked and not def._hideRemark then
            local remarkStr = def._remark
            if remarkStr == nil or remarkStr == '' then remarkStr = def._str end
            local remark = V.createTTF(remarkStr, V.FontSize.S2, remarkClr)
            remark:setScale(math.min(1, (lc.w(btnTroop) - 16) / lc.w(remark)))
            lc.addChildToCenter(btnTroop, remark)
        else
            local label = V.createBoldRichTextMultiLine(def._str, V.RICHTEXT_PARAM_LIGHT_S2)
            lc.addChildToCenter(btnTroop, label)
        end

        btnTroop:setDisabledShader(V.SHADER_DISABLE)
        btnTroop:setEnabled(def._handler ~= nil)
        lc.addChildToPos(item, btnTroop, cc.p(def._hideRemark and lc.cw(item) or lc.cw(btnTroop), lc.h(item) - lc.ch(btnTroop)))

        if isUnlocked then
            --[[local btnDef = V.createScale9ShaderButton("img_btn_1", function() 
                def._handler(2)
            end, V.CRECT_BUTTON, 80)
            btnDef:setDisabledShader(V.SHADER_DISABLE)
            btnDef:setEnabled(btnTroop:isEnabled())
            lc.addChildToPos(item, btnDef, cc.p(lc.right(btnTroop) + lc.cw(btnDef) - 2, lc.y(btnTroop)))

            if def._isDef then
                local tag = lc.createSprite("img_troop_defend")
                lc.addChildToCenter(btnDef, tag)
                btnDef:setTouchEnabled(false)
            else
                local title = V.createBMFont(V.BMFont.huali_26, Str(STR.SET_DEF), cc.TEXT_ALIGNMENT_CENTER, 52)
                lc.addChildToCenter(btnDef, title)
                title:setScale(0.9)
            end]]
            if not def._hideRemark then
                local btnRemark = V.createScale9ShaderButton("img_btn_1_s", function() def._handler(3) end, V.CRECT_BUTTON_1_S, 82)
                btnRemark:setDisabledShader(V.SHADER_DISABLE)
                btnRemark:setEnabled(btnTroop:isEnabled())
                lc.addChildToPos(item, btnRemark, cc.p(lc.right(btnTroop) + lc.cw(btnRemark), lc.y(btnTroop)))
                local title = V.createBMFont(V.BMFont.huali_26, Str(STR.REMARK))
                lc.addChildToCenter(btnRemark, title)
                title:setScale(0.9)
            end
        end

        totalHeight = totalHeight + height + TroopList.GAP
        table.insert(self._items, item)
    end

    self:setContentSize(TroopList.WIDTH, totalHeight)

    local list = lc.List.createV(cc.size(lc.w(self) - _Base.FRAME_THICK_BOTH, totalHeight - _Base.FRAME_THICK_BOTH), ButtonList.MARGIN / 2, TroopList.GAP)
    list:setBounceEnabled(false)
    list:setAnchorPoint(0.5, 0.5)
    for _, item in ipairs(self._items) do
        list:pushBackCustomItem(item)
    end
    lc.addChildToCenter(self._bg, list)
end

--- Defines the panel to show description of items
-- @class DescPanel

local DescPanel = class("DescPanel", _Base)

DescPanel.WIDTH = 400
DescPanel.MARGIN = 30

function DescPanel.create(descStr)
    local panel = DescPanel.new(lc.EXTEND_WIDGET)    
    if panel:init(descStr) then
        return panel
    end
end

function DescPanel.createByInfoId(infoId, isFragment)
    local descStr
    if infoId == 0 then        
        descStr = Str(STR.NPC_DESC)
    else
        local info = Data.getInfo(infoId)
        if info == nil or info._descSid == nil then
            return nil
        end

        local typeStr = ClientData.getItemTypeNameByInfoId(infoId, isFragment)
        descStr = string.format("|%s|%s", string.format(Str(STR.BRACKETS_S), typeStr), Str(info._descSid))
    end

    local panel = DescPanel.new(lc.EXTEND_WIDGET)
    if panel:init(descStr) then
        return panel
    end
end

function DescPanel:init(descStr)
    local desc = V.createBoldRichText(descStr, {_width = DescPanel.WIDTH - DescPanel.MARGIN * 2})
    local size = cc.size(DescPanel.WIDTH, lc.h(desc) + DescPanel.MARGIN * 2)

    local bg = V.createFramedShadowColorBg(size, color or cc.c3b(40, 50, 60))
    bg:setOpacity(240)
    lc.addChildToCenter(bg, desc)

    local shadow = lc.createImageView{_name = "img_com_bg_15", _crect = V.CRECT_COM_BG15}
    shadow:setContentSize(size.width + _Base.SHADOW_H, size.height + _Base.SHADOW_V)
    lc.addChildToPos(bg, shadow, cc.p(size.width / 2 - 6, size.height / 2 - 8), -1)

    DescPanel.super.init(self, size)

    lc.addChildToCenter(self, bg)

    return true
end

--- Defines the panel only contains button list
-- @class ButtonList

local FilterList = class("FilterList", _Base)

FilterList.MARGIN = 12
FilterList.GAP = 8

function FilterList.create(size, titleStr)
    if not _Base.canCreate() then return nil end

    local panel = FilterList.new(lc.EXTEND_WIDGET)
    panel._titleStr = titleStr
    panel:init(size)
    return panel
end

function FilterList:init(size)
    -- Overload setContentSize()
    local superSetContentSize = self.setContentSize
    self.setContentSize = function(self, w, h)
        if type(w) == "table" then
            h = w.height
            w = w.width
        end

        superSetContentSize(self, w, h)

        self._bg:setContentSize(w, h)
        self._bg:setPosition(w / 2, h / 2)
    end

    local bg = V.createFramedShadowColorBg(size, color or cc.c3b(40, 50, 60))
    self._bg = bg
    self:addChild(bg)

    FilterList.super.init(self, size)
end

--- Defines the panel only contains button list
-- @param buttonDefs        A table to define all button parameters. DEF = {_str|_sid|_area, _handler, _focus, _w, _h}
function FilterList:setButtonDefs(allButtonDefs)
    local defWidth = lc.w(self) - 40
    local itemWidth = 130
    local itemHeight = 50

    local node = cc.Node:create()
    local top = 0
    
    for i = 1, #allButtonDefs do
        local buttonDefs = allButtonDefs[i]
        local left = 0

        local buttons = {}

        local selectType = function (index)
            for j = 1, #buttons do
                buttons[j]:setIsSelected(j == index)
            end
        end

        -- line
        if i > 1 then
            local line = lc.createSprite({_name = "img_title_decoration", _size = cc.size(defWidth, 2), _crect = V.CRECT_LABEL_DECORATION})
            lc.addChildToPos(node, line, cc.p(defWidth / 2, top - 15))
            top = top - 30
        end

        -- title
        local label = V.createTTF(buttonDefs._titleStr, V.FontSize.S1)
        label:setColor(lc.Color3B.yellow)
        lc.addChildToPos(node, label, cc.p(lc.cw(label), top - lc.ch(label)))
        top = top - itemHeight + lc.ch(label)

        for j = 1, #buttonDefs do
            local def = buttonDefs[j]

            local btn = V.createFilterButton(def._str, function () 
                selectType(j)
                def._handler()
            end, itemWidth, itemHeight)
            if left + lc.w(btn) - 10 > defWidth then
                left = 0
                top = top - itemHeight
            end
            lc.addChildToPos(node, btn, cc.p(left + lc.cw(btn), top - lc.ch(btn)))
            buttons[j] = btn

            left = left + itemWidth
        end

        top = top - itemHeight + 10
        
        selectType(buttonDefs._curFilter)
    end

    self:setContentSize(lc.w(self), -top + 40)
    self:setTouchEnabled(true)
    lc.addChildToPos(self, node, cc.p(20, lc.h(self) - 20))
end

--- Assign components to base class
_Base.ButtonList = ButtonList
_Base.TroopList = TroopList
_Base.DescPanel = DescPanel
_Base.FilterList = FilterList


return _Base