local _M = ClientView


function _M.createUpgradableDesc(info, curLevel, nextLevel, w, param)
    local fontSize = param and param._fontSize or _M.FontSize.S2
    local curClr = param and param._curColor or _M.COLOR_TEXT_LIGHT

    local str = Str(info._descSid)
    str = string.gsub(str, '#', '')

    if info._val[1] > 0 then
        local nextClr = param and param._nextColor or _M.COLOR_TEXT_GREEN
        str = string.gsub(str, "%[%d+%]", '|')

        local desc = ccui.RichTextEx:create()
        desc:setCascadeOpacityEnabled(true)
        desc:setMaxWidth(w)

        local parts, index = string.splitByChar(str, '|'), 2
        if str[1] == '|' then
            table.insert(parts, 1, "")
        elseif str[#str] == '|' then
            table.insert(parts, "")
        end

        desc:insertElement(ccui.RichItemLabel:create(0, curClr, 255, parts[1], _M.TTF_FONT, fontSize))

        while index <= #parts do
            if nextLevel and nextLevel > curLevel then
                desc:insertElement(ccui.RichItemLabel:create(0, curClr, 255, string.format("%d ", info._val[curLevel]), _M.TTF_FONT, fontSize))

                local arrow = lc.createSprite("img_arrow_right")
                arrow:setScale(0.5)
                arrow:setColor(nextClr)
                local arrowNode = lc.createNode(cc.size(lc.makeEven(lc.sw(arrow)), fontSize + 2))
                lc.addChildToCenter(arrowNode, arrow)

                desc:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, arrowNode))
                desc:insertElement(ccui.RichItemLabel:create(0, nextClr, 255, string.format(" %d", info._val[nextLevel]), _M.TTF_FONT, fontSize))
            else
            
                desc:insertElement(ccui.RichItemLabel:create(0, nextClr, 255, tonumber(info._val[curLevel]), _M.TTF_FONT, fontSize))
            end

            desc:insertElement(ccui.RichItemLabel:create(0, curClr, 255, parts[index], _M.TTF_FONT, fontSize))
            index = index + 1
        end

        desc:formatText()
        return desc
    else
        local desc = _M.createTTF(str, fontSize, curClr, cc.size(w, 0))
        return desc
    end
end

function _M.createSkillDesc(skill, curLevel, nextLevel, w, param)
    local skillInfo = (type(skill) == "table" and skill or Data._skillInfo[skill])
    return _M.createUpgradableDesc(skillInfo, curLevel, nextLevel, w, param)    
end

function _M.createUnionTechDesc(tech, curLevel, nextLevel, w, param)
    local techInfo = (type(tech) == "table" and tech or Data._unionTechInfo[tech])
    return _M.createUpgradableDesc(techInfo, curLevel, nextLevel, w, param)   
end
