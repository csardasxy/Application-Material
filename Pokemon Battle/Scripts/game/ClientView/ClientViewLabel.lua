
local _M = ClientView


function _M.createKeyValueLabel(keyStr, valueStr, fontSize, isColorLight, iconName)
    local labelKey = _M.createTTF(keyStr..": ", fontSize)
    --labelKey:setColor(isColorLight and _M.COLOR_LABEL_LIGHT or _M.COLOR_LABEL_LIGHT)
    labelKey:setAnchorPoint(0, 0.5)

    if valueStr then
        local labelValue = _M.createTTF(valueStr, fontSize)
        --labelValue:setColor(isColorLight and _M.COLOR_TEXT_LIGHT or _M.COLOR_TEXT_LIGHT)
        labelValue:setAnchorPoint(0, 0.5)
        labelKey._value = labelValue
        labelValue._key = labelKey
    end

    if iconName then
        local icon = cc.Sprite:createWithSpriteFrameName(iconName)
        labelKey._icon = icon
    end

    labelKey.addToParent = function(self, parent, pos, zorder, tag)
        parent:addChild(self)
        if self._icon then
            parent:addChild(self._icon)
        end
        if self._value then
            parent:addChild(self._value)
        end
        self:setPosition(pos.x, pos.y)
    end

    local superSetPosition = labelKey.setPosition
    labelKey.setPosition = function(self, x, y)
        if type(x) == "table" then
            y = x.y
            x = x.x
        end

        superSetPosition(self, x, y)
        if self._icon then
            self._icon:setPosition(lc.right(self) + lc.w(self._icon) / 2 + 2, y)
            if self._value then
                self._value:setPosition(lc.right(self._icon) + 8, y)
            end
        else
            if self._value then
                self._value:setPosition(lc.right(self), y)
            end
        end
    end

    local superRemoveFromParent = labelKey.removeFromParent
    labelKey.removeFromParent = function(self, isCleanup)
        if self._value then
            self._value:removeFromParent()
        end
        if self._icon then
            self._icon:removeFromParent()
        end
        superRemoveFromParent(self, isCleanup)
    end

    labelKey.getTotalWidth = function(self)
        return lc.w(self) + (iconName and lc.w(self._icon) + 10 or 0) + (self._value and lc.w(self._value) or 0)
    end
    labelKey.getTotalHeight = function(self)
        return lc.h(labelKey._icon)
    end

    return labelKey, labelKey._value, labelKey._icon
end

function _M.createResIconLabel(w, icoName, bgColor)
    local h = _M.CRECT_COM_BG2.height

    local bg = ccui.Scale9Sprite:createWithSpriteFrameName("img_com_bg_2", _M.CRECT_COM_BG2)
    bg:setContentSize(w, h)
    bg:setOpacity(120)
    bg:setColor(bgColor or lc.Color3B.black)
    
    if icoName then
        local ico = cc.Sprite:createWithSpriteFrameName(icoName)
        ico:setScale(0.8)
        ico:setPosition(0, h / 2)
        bg:addChild(ico)
        bg._ico = ico
    end
    
    local label = _M.createBMFont(V.BMFont.huali_26, "")
    label:setAnchorPoint(cc.p(0, 0.5))
    
    label:setPosition(18, h / 2)
    lc.offset(label, 0, 3)
    bg:addChild(label)
    bg._label = label
    
    return bg
end

function _M.createNameLabel(name, color, hAlign, callback)
    if callback ~= nil then
        local nameBtn = _M.createShaderButton(nil, callback)
        local nameLabel = cc.Label:createWithTTF(name, _M.TTF_FONT, _M.FontSize.S2)
        nameLabel:setColor(color)
        nameBtn:setContentSize(nameLabel:getContentSize())
        lc.addChildToCenter(nameBtn, nameLabel)
        nameBtn:setZoomScale(0)
        if hAlign == nil or hAlign == cc.TEXT_ALIGNMENT_LEFT then
            nameBtn:setAnchorPoint(0, 0.5)
        elseif hAlign == cc.TEXT_ALIGNMENT_CENTER then
            nameBtn:setAnchorPoint(0.5, 0.5)
        else
             nameBtn:setAnchorPoint(1, 0.5)
        end
        return nameBtn
    else
        local nameLabel = cc.Label:createWithTTF(name, _M.TTF_FONT, _M.FontSize.S2, cc.size(220, 30), hAlign or cc.TEXT_ALIGNMENT_LEFT, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        nameLabel:setColor(color)
        return nameLabel
    end
end

function _M.createStatusLabel(str, color, rotation)
    local mark = lc.createSprite("img_status_rect")
    mark:setColor(color)
    if rotation then mark:setRotation(rotation) end

    local label = _M.createTTF(str, _M.FontSize.S1, color)
    lc.addChildToCenter(mark, label)
    mark._label = label

    return mark
end

function _M.addDecoratedLabel(parent, str, pos, gap, zorder)
    local labelBg = lc.createSprite({_name = "img_blank", _crect = cc.rect(1, 1, 1, 1), _size = cc.size(lc.w(parent) - gap * 2, 36)})
    lc.addChildToPos(parent, labelBg, pos, zorder)

    local label = V.createTTFBold(str, _M.FontSize.S2, _M.COLOR_TEXT_ORANGE)
    label:enableOutline(lc.Color4B.black, 1)
    local labelSize = label:getContentSize()
    lc.addChildToPos(labelBg, label, cc.p(lc.w(label) / 2 + 12, lc.h(label) / 2 + 4))
    
    return label
end

function _M.setValueLabel(label, value, formatter)
    label:stopActionByTag(1)
    label:setString(formatter ~= nil and formatter(value) or value)
    label._value = value
end

function _M.updateValueLabel(label, value, formatter, changeScale)
    if label._value ~= nil then
        if label._value == value or (formatter and formatter(label._value) == formatter(value)) then
            return label:stopActionByTag(1)
        end
    else
        label:setString(formatter ~= nil and formatter(value) or value)
        label._value = value
        return
    end

    local interval = 0.05
    local action = lc.rep( lc.sequence(interval, lc.call(function () 
        local isStop = true
        if value ~= label._value and (formatter == nil or formatter(label._value) ~= formatter(value)) then
            isStop = false
                
            local delta = (value - label._value) / 2
            if delta > 0 then
                delta = math.ceil(delta)
            else
                delta = math.floor(delta)
            end
            label._value = label._value + delta
            if (value - label._value) * delta < 0 then
                label._value = value
            end
            
            label:setString(formatter and formatter(label._value) or label._value)

            if not label:getActionByTag(2) then                
                local scale = cc.EaseSineInOut:create(cc.ScaleBy:create(0.05, changeScale or 1.2))
                local action = cc.Sequence:create(scale, scale:reverse())
                action:setTag(2)
                label:runAction(action)
            end
        end
        
        if isStop then
            label._value = value
            label:stopActionByTag(1)
        end
    end) ))
    action:setTag(1)
    label:stopActionByTag(1)
    label:runAction(action)
end
