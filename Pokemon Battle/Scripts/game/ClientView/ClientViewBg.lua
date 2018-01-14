local _M = ClientView



function _M.createShadowColorBg(size, color)
    local bg = cc.LayerColor:create(color or _M.COLOR_SHADOW_BG_BLUE, size.width, size.height)
    bg:ignoreAnchorPointForPosition(false)

    local shadow = lc.createSprite{_name = "img_com_bg_14", _crect = _M.CRECT_COM_BG14, _size = size}
    lc.addChildToCenter(bg, shadow, 1)

    local superSetContentSize = bg.setContentSize
    bg.setContentSize = function(self, w, h)
        superSetContentSize(self, w, h)
        shadow:setContentSize(w, h)
        shadow:setPosition(w / 2, h / 2)
    end

    bg._shadow = shadow
    return bg
end

function _M.createFramedShadowColorBg(size, color)
    local frame = lc.createSprite{_name = "img_com_bg_30", _crect = _M.CRECT_COM_BG30}
    
    local superSetContentSize = frame.setContentSize
    frame.setContentSize = function(self, w, h)
        superSetContentSize(self, w, h)
    end

    frame:setContentSize(size.width, size.height)
    return frame
end

function _M.createRedFlagBg(size)
    local bg = lc.createNode()

    local right = lc.createSprite{_name = "img_com_bg_18", _crect = _M.CRECT_COM_BG18}
    local rightW = lc.w(right)
    right:setFlippedX(true)
    bg:addChild(right)

    local left = lc.createSprite{_name = "img_com_bg_18", _crect = _M.CRECT_COM_BG18}
    bg:addChild(left)

    local superSetContentSize = bg.setContentSize
    bg.setContentSize = function(self, w, h)
        superSetContentSize(self, w, h)
        
        left:setContentSize(w - rightW, h)
        left:setPosition(lc.w(left) / 2, h / 2)

        right:setContentSize(rightW, h)
        right:setPosition(w - rightW / 2, h / 2)
    end

    bg:setContentSize(size.width, size.height)
    return bg
end

function _M.createPaperBg(size, hasNipple)
    local frame = lc.createImageView{_name = "img_com_bg_21", _crect = _M.CRECT_COM_BG22}

    --local bg = cc.Sprite:createWithSpriteFrameName("img_form_bg")
    --frame:addChild(bg, -1)
    
    --[[
    if hasNipple then
        local nipple = cc.Sprite:createWithSpriteFrameName("img_nipple")
        nipple:setPosition(32, size.height - 32)
        frame:addChild(nipple)
        
        nipple = cc.Sprite:createWithSpriteFrameName("img_nipple")
        nipple:setPosition(size.width - 32, size.height - 32)
        frame:addChild(nipple)
    end
    ]]

    local superSetContentSize = frame.setContentSize
    frame.setContentSize = function(self, w, h)
        if type(w) == "table" then
            h = w.height
            w = w.width
        end

        superSetContentSize(self, w, h)
        --bg:setScale((w - 12) / lc.w(bg), (h - 10) / lc.h(bg))
        --bg:setPosition(w / 2, h / 2 + 1)
    end
    
    frame:setContentSize(size)
    return frame
end

function _M.createCardListBg(size)
    local cardArea = lc.createNode(size)

    local topLine = ccui.Scale9Sprite:createWithSpriteFrameName("img_divide_line_4", cc.rect(1, 0, 1, 24))
    topLine:setContentSize(size.width, 24)
    lc.addChildToPos(cardArea, topLine, cc.p(lc.w(cardArea) / 2, lc.h(cardArea) - lc.h(topLine) / 2))

    local bottomLine = ccui.Scale9Sprite:createWithSpriteFrameName("img_divide_line_4", cc.rect(1, 0, 1, 24))
    bottomLine:setContentSize(size.width, 24)
    lc.addChildToPos(cardArea, bottomLine, cc.p(lc.w(cardArea) / 2, lc.h(bottomLine) / 2))
    
    return cardArea
end

function _M.createLoadingBg()
    local bgStr = "res/updater/loading_"..ClientData.getAppId()..".jpg"
    local bg = cc.Sprite:create(bgStr)
    if bg == nil then
        bgStr = "res/updater/loading1.jpg"
        bg = cc.Sprite:create(bgStr)
    end
    return bg, bgStr
end