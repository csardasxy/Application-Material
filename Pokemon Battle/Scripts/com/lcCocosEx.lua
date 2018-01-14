lc = lc or {}

--[[--
Cocos2dx class extension
--]]--

lc.EXTEND_NODE              = 0
lc.EXTEND_LAYER             = 1
lc.EXTEND_SPRITE            = 2
lc.EXTEND_SHADERSPRITE      = 3
lc.EXTEND_LAYERCOLOR        = 4
lc.EXTEND_SCALE9            = 5

lc.EXTEND_WIDGET            = 0
lc.EXTEND_LAYOUT            = 1
lc.EXTEND_LAYOUT_MASK       = 2
lc.EXTEND_LIST              = 3
lc.EXTEND_IMAGE             = 4
lc.EXTEND_BUTTON            = 5

lc.ExtendUIWidget = function(extType, ...)
    local widget
    if extType == lc.EXTEND_WIDGET then
        widget = ccui.Widget:create(...)
    elseif extType == lc.EXTEND_LAYOUT then
        widget = ccui.Layout:create(...)
    elseif extType == lc.EXTEND_LAYOUT_MASK then
        widget = ccui.Layout:create()
        lc.initMaskLayer(widget, ...)
    elseif extType == lc.EXTEND_LIST then
        widget = ccui.ListView:create(...)
    elseif extType == lc.EXTEND_IMAGE then
        widget = ccui.ImageView:create(...)
    elseif extType == lc.EXTEND_BUTTON then
        widget = V.createShaderButton(...)
    end
    
    widget.__index = widget
    
    widget:registerScriptHandler(function(evt) 
        if evt == "enter" then
            if widget.onEnter then widget:onEnter() end
        elseif evt == "exit" then
            if widget.onExit then widget:onExit() end
        elseif evt == "enterTransitionFinish" then
            if widget.onEnterTransitionFinish then widget:onEnterTransitionFinish() end
        elseif evt == "exitTransitionStart" then
            if widget.onExitTransitionStart then widget:onExitTransitionStart() end
        elseif evt == "cleanup" then            
            if widget.onCleanup then widget:onCleanup() end
        end
    end)
    
    return widget
end

lc.ExtendCCNode = function(extType, ...)
    local node
    if (extType == lc.EXTEND_NODE) then
        node = cc.Node:create(...)
    elseif (extType == lc.EXTEND_LAYER) then
        node = cc.Layer:create(...)
    elseif (extType == lc.EXTEND_SPRITE) then
        node = cc.Sprite:create(...)
    elseif (extType == lc.EXTEND_SHADERSPRITE) then
        node = cc.ShaderSprite:create(...)
    elseif (extType == lc.EXTEND_LAYERCOLOR) then
        node = cc.LayerColor:create(...)
    elseif (extType == lc.EXTEND_SCALE9) then
        node = ccui.Scale9Sprite:createWithSpriteFrameName(...)
    end
    
    node.__index = node
    return node
end
