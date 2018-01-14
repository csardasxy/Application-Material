local _M = ClientView


function _M.createBoldRichText(str, param, width)
    param = param or {}

    local text = ccui.RichTextEx:create()
    _M.appendBoldRichText(text, str, param)

    width = param._width or width
    if width then
        text:setMaxWidth(width)
    end

    text:setTouchEnabled(false)
    text:formatText()
    text:setCascadeOpacityEnabled(true)
    return text
end

function _M.appendBoldRichText(text, str, param)
    param = param or {}

    local normalClr = param._normalClr or _M.COLOR_TEXT_LIGHT
    local fontSize = param._fontSize or _M.FontSize.S2

    local lastPos, strLen = 1, string.len(str)
    if strLen == 0 then
        text:insertElement(ccui.RichItemNewLine:create(0))
    else
        while lastPos <= strLen do
            local pos1, pos2 = string.find(str, param._beginTag or '|', lastPos)
            if pos1 == nil then
                text:insertElement(ccui.RichItemLabel:create(0, normalClr, 255, string.sub(str, lastPos, strLen), _M.TTF_FONT, fontSize))
                lastPos = strLen + 1
            else
                text:insertElement(ccui.RichItemLabel:create(0, normalClr, 255, string.sub(str, lastPos, pos1 - 1), _M.TTF_FONT, fontSize))

                -- Get bold color information
                if str[pos1 + 1] == '\\' then
                    pos2 = string.find(str, '\\', pos1 + 2)
                    local clrStr = string.sub(str, pos1 + 2, pos2 - 1)
                    if clrStr[1] == "#" then
                        local r = tonumber("0x"..string.sub(clrStr, 2, 3))
                        local g = tonumber("0x"..string.sub(clrStr, 4, 5))
                        local b = tonumber("0x"..string.sub(clrStr, 6, 7))
                        local boldClr = cc.c3b(r, g, b)
                    else
                        local clrParts = string.splitByChar(clrStr, '.')
                        if #clrParts == 1 then
                            boldClr = lc.Color3B[clrParts[1]]
                        else
                            boldClr = cc.c3b(clrParts[1], clrParts[2], clrParts[3])
                        end
                    end
                else
                    boldClr = param._boldClr or _M.COLOR_TEXT_PURPLE
                end
                                
                lastPos = pos2 + 1
                pos1, pos2 = string.find(str, param._endTag or '|', lastPos)
                if pos1 == nil then
                    pos1, pos2 = strLen + 1, strLen
                end

                text:insertElement(ccui.RichItemLabel:create(0, boldClr, 255, string.sub(str, lastPos, pos1 - 1), _M.TTF_FONT, fontSize))
                lastPos = pos2 + 1
            end
        end
    end
end

function _M.createBoldRichTextMultiLine(str, param, width)
    local text = ccui.RichTextEx:create()
    
    width = param._width or width
    if width then
        text:setMaxWidth(width)
    end

    local strParts = string.split(str, '\n')
    for i, part in ipairs(strParts) do
        _M.appendBoldRichText(text, part, param)
        if i < #strParts then
            text:insertElement(ccui.RichItemNewLine:create(0))
        end
    end
    text:formatText()
    return text
end

function _M.updateBoldRichTextMultiLine(text, str, param)
    text:removeAllElements()

    local strParts = string.split(str, '\n')
    for i, part in ipairs(strParts) do
        _M.appendBoldRichText(text, part, param)
        if i < #strParts then
            text:insertElement(ccui.RichItemNewLine:create(0))
        end
    end
    text:formatText()
end

function _M.createBoldRichTextWithIcons(str, param, width)
    local text = ccui.RichTextEx:create()

    width = param._width or width
    if width then
        text:setMaxWidth(width)
    end

    local len, pos1 = #str, 0
    while pos1 < len do
        local pos2 = string.find(str, '%[', pos1 + 1)
        if pos2 then
            if pos2 > pos1 + 1 then
                _M.appendBoldRichText(text, string.sub(str, pos1 + 1, pos2 - 1), param)
            end

            pos1 = pos2
            pos2 = string.find(str, '%]', pos1 + 1)
            text:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, lc.createSprite(string.sub(str, pos1 + 1, pos2 - 1))))

            pos1 = pos2
        else
            if pos1 + 1 < len then
                _M.appendBoldRichText(text, string.sub(str, pos1 + 1, len), param)
                pos1 = len
            end
        end
    end
    
    text:setTouchEnabled(false)
    text:formatText()
    return text
end

function _M.showResChangeText(parent, resType, resDelta, offX, offY, scale)
    local icoName = string.format("img_icon_res%d_s", resType)
    if lc.FrameCache:getSpriteFrame(icoName) == nil then
        icoName = ClientData.getPropIconName(resType)
    end

    local ico = lc.createSprite(icoName)
    local value = _M.createBMFont(_M.BMFont.huali_26, resDelta > 0 and string.format("+ %d", resDelta) or string.format("- %d", -resDelta))
    local width = lc.w(ico) + lc.w(value) + 20
    
    ico:setPosition(lc.w(parent) / 2 - width / 2 + lc.w(ico) / 2 + (offX or 0), lc.h(parent) / 2 + (offY or 0))
    ico:runAction(lc.spawn({1.5, lc.fadeOut(0.5), lc.remove()}, lc.moveBy(1.5, 0, 50)))

    value:setColor(resType == Data.ResType.ingot and _M.COLOR_TEXT_INGOT or _M.COLOR_TEXT_WHITE)
    value:setPosition(lc.w(parent) / 2 + width / 2 - lc.w(value) / 2 + (offX or 0), lc.y(ico))
    value:runAction(lc.spawn({1.5, lc.fadeOut(0.5), lc.remove()}, lc.moveBy(1.5, 0, 50)))
    
    if scale then
        ico:setScale(scale)
        value:setScale(scale)
    end

    parent:addChild(ico, ClientData.ZOrder.toast)
    parent:addChild(value, ClientData.ZOrder.toast)
end