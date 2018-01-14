local _M = class("HelpForm", BaseForm)

function _M.create(title, texts)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(title, texts)
    
    return panel    
end

function _M:init(title, texts)
    _M.super.init(self, cc.size(800, 600), title or Str(STR.HELP), 0)
    
    local list = lc.List.createV(cc.size(lc.w(self._form) - _M.LEFT_MARGIN - _M.RIGHT_MARGIN, lc.bottom(self._titleFrame) - _M.BOTTOM_MARGIN + 10), 20, 30)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._form, list, cc.p(lc.w(self._form) / 2, lc.bottom(self._titleFrame) - lc.h(list) / 2 + 8))
    
    for i = 1, #texts do
        local item = ccui.Widget:create()
        item:setContentSize(lc.w(list) - 80, 0)
            
        local num = cc.Label:createWithTTF(string.format("%d.", i), V.TTF_FONT, V.FontSize.S1)
        num:setColor(V.COLOR_TEXT_LIGHT)
        item:addChild(num)
        
        local label
        if string.find(texts[i], '|') then
            label = ccui.RichTextEx:create()
            label:setMaxWidth(lc.w(item) - 60)

            local strs = string.splitByChar(texts[i], '|')
            local skillIndex, skillIcons = 1, {}
            for i = 1, #strs do
                local start = string.find(strs[i], "%[")
                local finish = string.find(strs[i], "%]")
                if start and finish then
                    local s = string.sub(strs[i], start + 1, finish - 1)
                    local icon = lc.createSprite(s)
                    table.insert(skillIcons, icon)
                    label:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, icon))
                    label:insertElement(ccui.RichItemLabel:create(0, V.COLOR_TEXT_LIGHT, 255, Str(STR[string.format("SKILL_TYPE_%d", tonumber(s[#s]))]).."          ", V.TTF_FONT, V.FontSize.S1))    
                    if skillIndex % 2 == 0 then
                        label:insertNewLine()
                    end
                    skillIndex = skillIndex + 1
                else
                    label:insertElement(ccui.RichItemLabel:create(0, V.COLOR_TEXT_LIGHT, 255, strs[i], V.TTF_FONT, V.FontSize.S1))
                    label:insertNewLine()
                end
            end
            label:formatText()

            for _, icon in ipairs(skillIcons) do
                lc.offset(icon, 0, -10)
            end
        else
            label = V.createTTF(texts[i]..'\n', V.FontSize.S1, V.COLOR_TEXT_LIGHT, cc.size(lc.w(item) - 60, 0))
        end
        item:addChild(label)
        
        item:setContentSize(lc.w(item), lc.h(label))
        num:setPosition(lc.w(num) / 2, lc.h(item) - lc.h(num) / 2)
        label:setPosition(lc.w(label) / 2 + 40, lc.h(item) / 2)
        
        if i < #texts then
            local line = V.createDividingLine(lc.w(item), V.COLOR_DIVIDING_LINE_LIGHT)
            line:setPosition(lc.w(item) / 2, -12)
            line:setOpacity(128)
            item:addChild(line)
        end
        
        list:pushBackCustomItem(item)        
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    if GuideManager.isGuideEnabled() then
        GuideManager.pauseGuide()
    end
end

function _M:onExit()
    _M.super.onExit(self)

    if GuideManager.isGuideEnabled() then
        GuideManager.resumeGuide()
    end
end

return _M