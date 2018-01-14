local _M = {}

_M.Toasts = {}
_M.DURATION_LONG = 4.0

function _M.push(text, duration)
    if _M.Toasts[text] then
        _M.Toasts[text]:removeFromParent()
    end

    local msg = V.createBoldRichText(text, {_fontSize = V.FontSize.M1, _normalClr = V.COLOR_TEXT_LIGHT, _boldClr = V.COLOR_TEXT_GREEN})
    
    local bg = lc.createSprite{_name = "img_toast_bg", _crect = V.CRECT_TOAST_BG}
    bg:setContentSize(cc.size(lc.w(msg) + 80, lc.h(msg) + 80))
    
    msg:setPosition(lc.w(bg) / 2, lc.h(bg) / 2)
    bg:addChild(msg)
    
    _M.Toasts[text] = bg
    _M.runBgAction(text, duration)
end

function _M.pushArray(texts, duration, delay)
    local width = 0
    local height = 0
    local spaceH = 5
    local labels = {}
    for i = 1, #texts do
        local label = cc.Label:createWithTTF(texts[i], V.TTF_FONT, V.FontSize.M1)
        table.insert(labels, label)
        
        width = math.max(width, lc.w(label))
        height = height + lc.h(label) + spaceH
    end
    height = height - spaceH
    
    local bg = lc.createSprite{_name = "img_toast_bg", _crect = V.CRECT_TOAST_BG}
    bg:setContentSize(cc.size(width + 80, height + 80))
    
    local marginTop = 40
    for i = 1, #labels do
        labels[i]:setPosition(lc.w(bg) / 2, lc.h(bg) - marginTop - lc.h(labels[i]) / 2)
        bg:addChild(labels[i])
        
        marginTop = marginTop + lc.h(labels[i]) + spaceH
    end 
    
    _M.Toasts[bg] = bg
    _M.runBgAction(bg, duration)
end

function _M.runBgAction(key, duration)
    local bg = _M.Toasts[key]

    local scene = lc._runningScene
    bg:setCascadeOpacityEnabled(true)
    bg:setPosition(lc.w(scene) / 2, lc.h(scene) / 2 + 150)
    bg:registerScriptHandler(function(evt) 
        if evt == "cleanup" then
            _M.Toasts[key] = nil
        end
    end)    
    scene._scene:addChild(bg, ClientData.ZOrder.toast)

    local distance = (lc.h(scene) - lc.y(bg)) / 2

    local action1 = lc.sequence(lc.ease(lc.scaleTo(lc.absTime(0.2), 1.0), "BackO"), lc.absTime(0.3), lc.moveBy(lc.absTime(2), 0, distance), {lc.moveBy(lc.absTime(2), 0, distance), lc.fadeOut(lc.absTime(1.5))})
    local action2 = lc.sequence(lc.absTime(duration or _M.DURATION_LONG), lc.remove())
    bg:setScale(0)
    bg:runAction(action1)
    bg:runAction(action2)
end

ToastManager = _M
return _M