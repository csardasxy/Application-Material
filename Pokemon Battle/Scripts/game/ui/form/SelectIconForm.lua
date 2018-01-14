local _M = class("SelectIconForm", BaseForm)

local FORM_SIZE = cc.size(740, 640)

local ICON_COUNT_IN_ROW = 5
local BOTTOM_H = 80

function _M.create(func, selectedInfoId)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(func, selectedInfoId)
    return panel
end

function _M:init(func, selectedInfoId)
    _M.super.init(self, FORM_SIZE, Str(STR.SELECT)..Str(STR.PROPS), 0)
    
    self._func = func
    self._selectedInfoId = selectedInfoId
    
    local list = lc.List.createV(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM - BOTTOM_H), 32, 20)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._frame, list, cc.p(lc.w(self._frame) / 2, lc.h(self._frame) / 2 + BOTTOM_H  / 2))
    self._list = list

    self._infoIds = {}
    for k, v in pairs(Data._propsInfo) do
        if k >= 7300 and k < 7400 then
            self._infoIds[#self._infoIds + 1] = k
        end
    end
    table.sort(self._infoIds, function(a, b) return a < b end)

    self:createBottomArea()
    self:createIconList()
end

function _M:createBottomArea()
    local bottomArea = V.createLineSprite("img_bottom_bg", lc.w(self._list))
    bottomArea:setAnchorPoint(0.5, 0)
    lc.addChildToPos(self._frame, bottomArea, cc.p(lc.w(self._frame) / 2, V.FRAME_INNER_BOTTOM - 12), -1)
    self._bottomArea = bottomArea

    local btnConfirm = V.createScale9ShaderButton("img_btn_1_s", 
        function() 
            if self._func then self._func(self._curBtn and self._curBtn._infoId or nil) end
            self:hide() 
        end, V.CRECT_BUTTON, 100, V.CRECT_BUTTON_S.height)
    btnConfirm:addLabel(Str(STR.OK))
    lc.addChildToPos(self._bottomArea, btnConfirm, cc.p(lc.w(self._bottomArea) - lc.w(btnConfirm) / 2 - 20, lc.h(self._bottomArea) / 2))
    self._btnConfirm = btnConfirm
end

function _M:createIconList()
    local listData, rowData = {}, {}
    
    local addIcon = function(info)
        table.insert(rowData, info)
        if #rowData == ICON_COUNT_IN_ROW then
            table.insert(listData, rowData)
            rowData = {}
        end
    end

    for i = 1, #self._infoIds do
        local infoId = self._infoIds[i]
        local info = Data.getInfo(infoId)
        addIcon(info)
    end
    
    local list = self._list
    list:bindData(listData, function(item, data) self:setOrCreateItem(item, data) end, math.min(8, #listData), 1)

    for i = 1, list._cacheCount do
        local data = listData[i]
        local item = self:setOrCreateItem(nil, data)
        list:pushBackCustomItem(item)
    end

    list:jumpToTop()
end

function _M:setOrCreateItem(item, data)
    if item == nil then
        item = ccui.Widget:create()
    end

    item:removeAllChildren()

    local iconD, iconGap = 100, 26
    local width = (iconD + iconGap) * ICON_COUNT_IN_ROW - iconGap

    item:setContentSize(width, 180)

    local pos = cc.p(iconD / 2, lc.h(item) / 2)
    for _, info in ipairs(data) do
        local icon = IconWidget.create({_infoId = info._id, _count = P._propBag._props[info._id]._num}, IconWidget.DisplayFlag.ITEM)
        icon._name:setColor(lc.Color3B.white)
        lc.addChildToPos(item, icon, pos)
        pos.x = pos.x + lc.w(icon) + iconGap

        local buttonCheck = ccui.ShaderButton:create("img_btn_check_bg", ccui.TextureResType.plistType)
        buttonCheck:setTouchRect(cc.rect(-10, -10, lc.w(buttonCheck) + 20, lc.h(buttonCheck) + 20)) 
        buttonCheck:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
        buttonCheck._infoId = info._id
        lc.addChildToPos(icon, buttonCheck, cc.p(lc.w(icon) / 2, -30)) 

        buttonCheck:addTouchEventListener(function(sender, type)
            if type == ccui.TouchEventType.ended then
                lc.Audio.playAudio(AUDIO.E_BUTTON_DEFAULT)
                self:selectBtn(sender)
            end
        end)     
        
        if info._id == self._selectedInfoId then
            self:selectBtn(buttonCheck) 
        end       
    end

    return item
end

function _M:selectBtn(sender)
    local infoId = sender._infoId
    if not P._propBag._props[infoId] or P._propBag._props[infoId]._num <= 0 then
        return
    end

    if self._curBtn ~= nil then
        self._curBtn:removeAllChildren()
    end 

    if self._curBtn == sender then
        self._curBtn = nil 
    else
        self._curBtn = sender   
        local sprite = lc.createSprite('img_icon_check')
        lc.addChildToCenter(sender, sprite)
    end
end

return _M