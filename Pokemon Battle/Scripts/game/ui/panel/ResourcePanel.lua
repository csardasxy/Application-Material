local _M = class("ResourcePanel", lc.ExtendCCNode)

local AREA_SIZE = cc.size(200, 46)
local INGOT_VALUE_SIZE = cc.size(172, AREA_SIZE.height)
local AREA_GAP = 16

_M.PropId = 
{
    Data.PropsId.yubi,

    Data.ResType.clash_trophy,
    Data.ResType.ladder_trophy,
    Data.ResType.union_battle_trophy,
    Data.ResType.dark_trophy,
    Data.PropsId.ladder_ticket,

    Data.PropsId.lottery_token,
    Data.PropsId.rare_package_ticket,
    Data.PropsId.character_package_ticket,
    
    Data.PropsId.skin_crystal,
    Data.PropsId.rare_coin,
    Data.PropsId.void_diamond,

    Data.PropsId.obelisk_badge,
    Data.PropsId.common_fragment,
}

_M.PropId2 = 
{
    Data.PropsId.rare_silver_coin,
    Data.PropsId.magic_dust,
    Data.PropsId.times_package_ticket,
}

function _M.create()
    local res = _M.new(lc.EXTEND_NODE)
    res:setAnchorPoint(0.5, 0.5)
    res:init()

    res:registerScriptHandler(function(evtName)
        if evtName == "enter" then
            res:onEnter()
        elseif evtName == "exit" then
            res:onExit()
        end
    end)

    return res
end

function _M:init()
    -- Set panel content size and position
    local panelSize = cc.size(AREA_SIZE.width * 3 + AREA_GAP + AREA_GAP, AREA_SIZE.height)
    self:setContentSize(panelSize)
    
    self:setPosition(V.SCR_W - panelSize.width / 2, V.SCR_H - panelSize.height / 2 - 8)

    self._areas = {}

    -- Create areas
    self._areaProps = {}
    for i = 1, #_M.PropId do
        local infoId = _M.PropId[i]
        self._areaProps[infoId] = self:createArea(infoId, AREA_SIZE, AREA_SIZE.width / 2)
    end

    self._areaProps2 = {}
    for i = 1, #_M.PropId2 do
        local infoId = _M.PropId2[i]
        self._areaProps2[infoId] = self:createArea(infoId, AREA_SIZE, lc.right(self._areas[1]) + AREA_GAP + AREA_SIZE.width / 2)
    end

    self._areaGold = self:createArea(Data.ResType.gold, AREA_SIZE, lc.right(self._areas[1]) + AREA_GAP + AREA_SIZE.width / 2)
    self._areaIngot = self:createArea(Data.ResType.ingot, INGOT_VALUE_SIZE, lc.right(self._areaGold) + AREA_GAP + INGOT_VALUE_SIZE.width / 2)
   
    self:setMode(Data.ResType.gold)
end

function _M:createArea(resType, valSize, areaX)
    local panelSize = self:getContentSize()
    
    local area
    local type = Data.getType(resType)
   
    if resType == Data.PropsId.skin_crystal or resType == Data.PropsId.times_package_ticket then
        area = V.createIconLabelArea(ClientData.getPropIconName(resType), nil, valSize.width, function(sender)
            V.showResExchangeForm(resType)
        end, "img_icon_add")

        area:setTouchRect(cc.rect(0, -5, lc.w(area), lc.h(area) + 20))

    elseif resType == Data.ResType.clash_trophy or resType == Data.ResType.ladder_trophy or resType == Data.ResType.union_battle_trophy or resType == Data.ResType.dark_trophy then
        area = V.createItemCountArea(resType, string.format("img_icon_res%d_s", resType), valSize.width)

    elseif type == Data.CardType.props then
        area = V.createItemCountArea(resType, ClientData.getPropIconName(resType), valSize.width)

    else
        area = V.createIconLabelArea(string.format("img_icon_res%d_s", resType), nil, valSize.width - 40, function(sender)
            V.showResExchangeForm(resType)
        end, "img_icon_add")

        area._icon:setVisible(false)
        area:setTouchRect(cc.rect(0, -5, lc.w(area), lc.h(area) + 20))
    end

    area:setAnchorPoint(0.5, 0.5)
    area:setPosition(areaX, panelSize.height / 2)
    self:addChild(area)

    local label = area._label
    label._value = -1
    lc.offset(label, 8)
    if resType == Data.ResType.ingot then
        lc.offset(label, 8)

        local btnBg = cc.Sprite:createWithSpriteFrameName("img_btn_squarel_s_2")
        local addIcon = area._btnAdd
        addIcon:setColor(lc.Color3B.white)
        addIcon:setPosition(lc.w(btnBg) / 2, lc.h(btnBg) / 2)
        lc.changeParent(addIcon, nil, btnBg)
        btnBg:setPosition(lc.w(area) - 14, lc.h(area) / 2)
        area:addChild(btnBg)
        area._btnAdd = btnBg

        area:setTouchRect(cc.rect(0, -5, lc.w(area) + lc.w(btnBg), lc.h(area) + 20))

        btnBg:setVisible(not ClientData.isHideCharge())
    end
    
    table.insert(self._areas, area)
    return area
end

function _M:setMode(mode, param)
    self._mode = mode
    self._param = param

    for _, area in ipairs(self._areas) do
        area:setVisible(false)
    end

    if mode == Data.PropsId.rare_silver_coin then
        self._areaProps2[mode]:setVisible(true)
        self._areaProps[Data.PropsId.rare_coin]:setVisible(true)
    elseif mode == Data.PropsId.magic_dust then
        self._areaProps2[mode]:setVisible(true)
        self._areaProps[Data.PropsId.obelisk_badge]:setVisible(true)
    elseif mode == Data.PropsId.times_package_ticket then
        self._areaProps2[mode]:setVisible(true)
        self._areaProps[Data.PropsId.void_diamond]:setVisible(true)
    elseif mode ~= Data.ResType.gold then
        self._areaGold:setVisible(true)
        self._areaProps[mode]:setVisible(true)
    else
        self._areaGold:setVisible(true)
    end

    self._areaIngot:setVisible(true)

    self:updateValues()
end

function _M:onEnter()
    self._listeners = {}
    local listener

    local resEvtList = {
        Data.Event.login,

        Data.Event.prop_dirty,

        Data.Event.union_res_dirty,
        Data.Event.gold_dirty,
        Data.Event.ingot_dirty,
        Data.Event.trophy_dirty,
        Data.Event.clash_trophy_dirty,
        Data.Event.union_battle_trophy_dirty,
        Data.Event.dark_trophy_dirty,
    }
    for _, evt in ipairs(resEvtList) do
        listener = lc.addEventListener(evt, function() self:updateValues() end)
        table.insert(self._listeners, listener)    
    end
    
    self._spines = {}
    local areas = {self._areaGold, self._areaIngot}
    for i = 1, #areas do
        local spine = V.createSpine('jbzstl')
        spine:setAnimation(0, i == 1 and 'animation' or 'animation2', true)
        lc.addChildToPos(areas[i], spine, cc.p(lc.x(areas[i]._icon) + 10 - (i == 1 and 4 or 12), lc.y(areas[i]._icon) - 4))
        self._spines[#self._spines + 1] = spine
    end
    
    -- Update all resource values
    self:updateValues()     
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
    
    for i = 1, #self._spines do
        self._spines[i]:removeFromParent()
    end
    self._spines = {}
end

function _M:onRelease()
    self:removeAllChildren()

    if self._schedulerID ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._schedulerID)  
        self._schedulerID = nil  
    end 
end

function _M:updateValues()
    if self._notupdate then
        self._notupdate = false
        return
    end

    self:runUpdateAction()
end

function _M:runResAction(resType, number, pos)
    local particle
    local startPos = self:convertToNodeSpace(pos)
    local dstPos
    if resType == Data.ResType.gold then
        particle = Particle.create("feijb")
        dstPos = cc.p(lc.left(self._areaGold) + 26, lc.y(self._areaGold))
    end    
    
    if particle then
        particle:setPosition(startPos)
        local cp1 = cc.p(startPos.x, startPos.y + 200)
        local cp2 = cc.p(startPos.x, startPos.y + 200)  
        local ep = cc.p(dstPos.x, dstPos.y)
        particle:runAction(cc.Sequence:create(cc.EaseSineInOut:create(cc.BezierToEx:create(0.75, {cp1, cp2, ep})), cc.CallFunc:create(function()             
            particle:removeFromParent()
              
            local particle = Particle.create("par_res_collect3")
            particle:setPosition(dstPos)
            self:addChild(particle)
    
            self:updateValues()
        end)))
        self:addChild(particle)
    end       
end

function _M:runUpdateAction()
    local icons, labels, values, caps = {}, {}, {}, {}
    local addElements = function(area, value, cap)
        if area._label._value ~= value and value ~= nil then
            table.insert(icons, area._icon)
            table.insert(labels, area._label)
            table.insert(values, value)
            table.insert(caps, cap or 0)
        end
    end
    
    if self._mode == Data.PropsId.rare_silver_coin then
        addElements(self._areaProps2[self._mode], P:getItemCount(self._mode))
        addElements(self._areaProps[Data.PropsId.rare_coin], P:getItemCount(Data.PropsId.rare_coin))
    elseif self._mode == Data.PropsId.magic_dust then
        addElements(self._areaProps2[self._mode], P:getItemCount(self._mode))
        addElements(self._areaProps[Data.PropsId.obelisk_badge], P:getItemCount(Data.PropsId.obelisk_badge))
    elseif self._mode == Data.PropsId.times_package_ticket then
        addElements(self._areaProps2[self._mode], P:getItemCount(self._mode))
        addElements(self._areaProps[Data.PropsId.void_diamond], P:getItemCount(Data.PropsId.void_diamond))
    elseif self._mode ~= Data.ResType.gold then
        addElements(self._areaProps[self._mode], P:getItemCount(self._mode))
    end
    
    addElements(self._areaGold, P._gold)
    addElements(self._areaIngot, P._ingot)

    if #labels == 0 then return end
        
    if self._schedulerID then
        lc.Scheduler:unscheduleScriptEntry(self._schedulerID)
    end
    
    local interval = 0.05
    self._schedulerID = lc.Scheduler:scheduleScriptFunc(function(dt) 
        local isStop = true
        for i, label in ipairs(labels) do
            if values[i] ~= label._value then
                isStop = false
                
                local delta = (values[i] - label._value) / 2
                if delta > 0 then
                    delta = math.ceil(delta)
                else
                    delta = math.floor(delta)
                end
                label._value = label._value + delta
                if (values[i] - label._value) * delta < 0 then
                    label._value = values[i]
                end
                if caps[i] > 0 then
                    label:setString(string.format("%d/%d", label._value, caps[i]))

                    local color = (label._value > caps[i] and V.COLOR_TEXT_GREEN or V.COLOR_TEXT_LIGHT)
                    label:setColor(color)
                else
                    label:setString(ClientData.formatNum(label._value, 99999))
                end

                if label:getNumberOfRunningActions() == 0 then
                    local scale = cc.EaseSineInOut:create(cc.ScaleBy:create(0.1, 1.2))
                    label:runAction(cc.Sequence:create(scale, scale:reverse()))
                end

                if icons[i]:getNumberOfRunningActions() == 0 then
                    local scale = cc.EaseSineInOut:create(cc.ScaleBy:create(0.1, 1.2))
                    icons[i]:runAction(cc.Sequence:create(scale, scale:reverse()))
                end
            end
        end
        
        if isStop then
            if self._schedulerID then
                lc.Scheduler:unscheduleScriptEntry(self._schedulerID)  
                self._schedulerID = nil  
            end
        end
    end, interval, false)
end

ResPanel = _M
return _M