local _M = ClientView

function _M.createCardFrame(infoId, backId, skinId)
    local info, cardType = Data.getInfo(infoId)

    local notify = lc.File:isPopupNotify()
    lc.File:setPopupNotify(false)

    -- 0. container --
    local frame = cc.ShaderSprite:createWithFramename(_M.getCardFrameName(cardType, info._nature))
    local node = lc.createNode(frame:getContentSize())
    node._showFg = true
    node._showInBattle = false
    node._infoId = infoId
    node._backId = backId
    node._skinId = skinId
    node:setCascadeOpacityEnabled(true)

    -- 1. frame
    lc.addChildToCenter(node, frame, 1)
    node._frame = frame
    
    -- 2. evolution / magic
    local evolutionValue = cc.ShaderSprite:createWithFramename('card_monster_lv0')
    lc.addChildToCenter(node, evolutionValue, 3)
    node._evolutionValue = evolutionValue

    local evolutionBg = cc.ShaderSprite:createWithFramename('card_frame_stage')
    evolutionBg:setAnchorPoint(1, 1)
    lc.addChildToPos(node, evolutionBg, cc.p(lc.w(node) + 10, lc.h(node) + 10), 2)
    node._evolutionBg = evolutionBg

    local evolutionIcon = cc.ShaderSprite:createWithFramename(_M.getCardIconName(10001, true))
    lc.addChildToCenter(evolutionBg, evolutionIcon)
    node._evolutionIcon = evolutionIcon
    
    -- 3.1 hp, weakness
    local hpLabel = V.createTTFBold("HP:", _M.FontSize.S2, _M.COLOR_TEXT_DARK)
    hpLabel:setAnchorPoint(0, 0)
    lc.addChildToPos(node, hpLabel, cc.p(lc.w(node) - 240 + 72 + 18, 26 + 11), 2)
    node._hpLabel = hpLabel;
    local hpValue = V.createTTFBold(0, _M.FontSize.M1, _M.COLOR_TEXT_DARK)
    hpValue:enableOutline(cc.c4b(233, 233, 233, 256), 1)
    hpValue:setAnchorPoint(0, 0)
    lc.addChildToPos(node, hpValue, cc.p(lc.right(hpLabel), lc.y(hpLabel) - 3), 2)
    node._hpValue = hpValue

    -- 3.2 weakness
    local weaknessBg = lc.createSprite('card_frame_weak_resist')
    lc.addChildToCenter(node, weaknessBg, 2)
    node._weaknessBg = weaknessBg

    local weaknessIcon = cc.ShaderSprite:createWithFramename('card_nature_01_s')
    lc.addChildToPos(weaknessBg, weaknessIcon, cc.p(96, 114))
    node._weaknessIcon = weaknessIcon

    local weaknessValue = V.createTTFBold('x1', _M.FontSize.S3, _M.COLOR_TEXT_DARK)
    weaknessValue:setAnchorPoint(0, 0.5)
    lc.addChildToPos(weaknessBg, weaknessValue, cc.p(lc.right(weaknessIcon) + 2, lc.y(weaknessIcon)))
    node._weaknessValue = weaknessValue
    
    -- 3.3 resist
    local resistIcon = cc.ShaderSprite:createWithFramename('card_nature_01_s')
    lc.addChildToPos(weaknessBg, resistIcon, cc.p(236, lc.y(weaknessIcon)))
    node._resistIcon = resistIcon
    
    local resistValue = V.createTTFBold('-1', _M.FontSize.S3, _M.COLOR_TEXT_DARK)
    resistValue:setAnchorPoint(0, 0.5)
    lc.addChildToPos(weaknessBg, resistValue, cc.p(lc.right(resistIcon), lc.y(weaknessIcon)))
    node._resistValue = resistValue

    -- 3.4 drawback
    local drawBackBg = lc.createSprite('card_frame_db')
    lc.addChildToCenter(node, drawBackBg, 2)
    node._drawBackBg = drawBackBg

    local drawBackValue = V.createTTFBold('0', _M.FontSize.S3, _M.COLOR_TEXT_DARK)
    lc.addChildToPos(drawBackBg, drawBackValue, cc.p(431, lc.y(weaknessIcon)))
    node._drawBackValue = drawBackValue
    
    -- 4 nature
    local natureValue = cc.ShaderSprite:createWithFramename('card_nature_01')
    lc.addChildToPos(node, natureValue, cc.p(lc.cw(natureValue), lc.h(node) - lc.ch(natureValue)), 2)
    node._natureValue = natureValue

    -- 5. name
    local nameValue = V.createTTFBold(Str(info._nameSid), _M.FontSize.B2, _M.COLOR_TEXT_DARK)
    nameValue:setAnchorPoint(0, 0.5)
    lc.addChildToPos(node, nameValue, cc.p(80, lc.h(node) - 40), 2)
    node._nameValue = nameValue

    -- 6. quality
    --[[
    local qualityBg = lc.createSprite('card_quality_bg')
    qualityBg:setCascadeOpacityEnabled(true)
    lc.addChildToCenter(node, qualityBg, 3)]]

    local quality = cc.ShaderSprite:createWithFramename('card_quality_01')
    lc.addChildToCenter(node, quality, 2)
    --node._qualityBg = qualityBg
    node._quality = quality

    -- 7. image --
    local image = cc.ShaderSprite:createWithFilename(_M.getCardImageName(infoId, skinId))
    if image == nil then image = cc.ShaderSprite:createWithFilename(_M.getCardImageName(10001, skinId)) end
    lc.addChildToPos(node, image, cc.p(lc.cw(node), lc.h(node) - lc.ch(image) - 68))
    node._image = image

    -- 8.1 monster skill
    node._monsterSkills = {}
    for i = 1, 3 do
        local skill = V.createMonsterSkill(1001, cc.size(416, 90), false, true)
        lc.addChildToPos(node, skill, cc.p(lc.cw(node), lc.bottom(image) - 24 - lc.ch(skill) - (lc.h(skill) + 8) * (i - 1)), 2)
        node._monsterSkills[i] = skill
    end
    -- 8.2 magic skill
    local skill = V.createMagicSkill(1001, cc.size(416, 230), false, true)
    lc.addChildToPos(node, skill, cc.p(lc.cw(node), lc.bottom(image) - 36 - lc.ch(skill)), 2)
    node._magicSkill = skill
    
    node.update = function(self, infoId, skinId)
        self._infoId = infoId
        self._skinId = skinId
        local info, cardType = Data.getInfo(infoId)
        local skinInfo = skinId and Data._skinInfo[skinId]
        
        local isMonster = cardType == Data.CardType.monster
        local hasBones = (self._showInBattle and skinInfo and skinInfo._effect ~= 0) and true or false
        local monsterShowFg = self._showFg and isMonster
        
        -- 1. frame
        self._frame:setSpriteFrame(self._showFg and _M.getCardFrameName(cardType, info._nature) or V.getCardBackName(self._backId, self._showInBattle))
        
        -- 2. center
        self._frame:setEffect(nil)

        -- 2. evolve stage
        self._evolutionValue:setVisible(self._showFg)
        if self._showFg then
            if cardType == Data.CardType.monster then
                self._evolutionValue:setSpriteFrame('card_monster_lv'..info._level)
            elseif cardType == Data.CardType.magic then
                self._evolutionValue:setSpriteFrame('card_magic_'..info._type)
            end
        end

        self._evolutionBg:setVisible(monsterShowFg and info._level > 0)
        if self._evolutionBg:isVisible() then
            self._evolutionIcon:setSpriteFrame(_M.getCardIconName(info._evoBase, true))
        end
        
        -- 3.1 hp
        self._hpValue:setVisible(monsterShowFg)
        local option = info._option
        self._hpValue:setString(((option ~= nil and band(option, Data.CardOption.hide_def) > 0) and '?' or ClientData.formatNum(info._hp, 99999)))
        --self._hpValue:enableOutline(lc.Color4B.red, 2)

        -- 3.2 weakness, resist, drawback
        self._weaknessBg:setVisible(monsterShowFg)
        self._drawBackBg:setVisible(monsterShowFg)
        if monsterShowFg then
            if info._weakness == 0 then
                self._weaknessIcon:setVisible(false)
                self._weaknessValue:setVisible(false)
            else
                self._weaknessIcon:setSpriteFrame(string.format('card_nature_%02d_s', info._weakness))
                self._weaknessValue:setString('x'..info._weaknessFactor)
            end
            if info._resist == 0 then
                self._resistIcon:setVisible(false)
                self._resistValue:setVisible(false)
            else
                self._resistIcon:setVisible(true)
                self._resistValue:setVisible(true)
                self._resistIcon:setSpriteFrame(string.format('card_nature_%02d_s', info._resist))
                self._resistValue:setString('-'..info._resistFactor)
            end
            self._drawBackValue:setString('x'..info._retreatCost)
        end

        -- 4 nature  
        self._natureValue:setVisible(self._showFg)
        if isMonster then self._natureValue:setSpriteFrame(string.format('card_nature_%02d', info._nature))
        else self._natureValue:setSpriteFrame(cardType == Data.CardType.magic and 'card_nature_magic' or 'card_nature_trap')
        end
        
        -- 5. name
        self._nameValue:setVisible(self._showFg)
        self._nameValue:setString(Str(info._nameSid))
        self._nameValue:setScale(math.min(1, 240 / lc.w(self._nameValue)))

        -- 6. quality
        self._quality:setVisible(self._showFg)
        self._quality:setSpriteFrame('card_quality_0'..info._quality)

        -- 7. image
        self._image:setOpacity((self._showFg and not hasBones) and 255 or 0)
        self._image:stopAllActions()
        if self._bones ~= nil then self._bones:removeFromParent() self._bones = nil end
        if self._showFg then
            local notify = lc.File:isPopupNotify()
            lc.File:setPopupNotify(false)
            self._image:setTexture(lc.TextureCache:addImage(_M.getCardImageName(infoId, skinId)))
            lc.File:setPopupNotify(notify)
        end
        if self._showFg and self._showInBattle then
            if hasBones then
                self._bones = DragonBones.create(skinInfo._effect)
                self._bones:gotoAndPlay('effect')
                self._bones:setScale(1.3)
                lc.addChildToCenter(self._image, self._bones)
            end
        end

        -- 8.1 monster skill
        for i = 1, 3 do
            node._monsterSkills[i]:setVisible(monsterShowFg)
            if monsterShowFg then node._monsterSkills[i]:update(info._skillId[i]) end
        end

        if isMonster then 
            if self._line == nil then
                local line = lc.createSprite("card_split_line")
                lc.addChildToPos(node, line, cc.p(lc.cw(node), lc.bottom(node._monsterSkills[1]) - 1), 2)
                self._line = line
            else 
                self._line:setVisible(true)
            end
            self._hpLabel:setVisible(true)
        else
            if self._line then
                self._line:setVisible(false)
            end
            self._hpLabel:setVisible(false)
        end
        
       

        -- 8.2 magic skill
        node._magicSkill:setVisible(not isMonster and self._showFg)
        if not isMonster and self._showFg then node._magicSkill:update(info._skillId[1]) end
    end

    node.setEffect = function(self, effect)
        self._image:setEffect(effect)
        self._natureValue:setEffect(effect)
        --self._starArea:setEffect(effect)
    end
    
    node.setStatus = function(self, showFg, showInBattle)
        if self._showFg ~= showFg or self._showInBattle ~= showInBattle then
            self._showFg = showFg
            self._showInBattle = showInBattle
            self:update(self._infoId, self._skinId)
        end
    end

    node:update(infoId, skinId) 

    lc.File:setPopupNotify(notify)
    

    return node
end

function _M.createMonsterSkill(skillId, size, needFrame)
    local frame
    if needFrame then
        --frame = lc.createSprite({_name = "card_split_line", _crect = cc.rect(2, 4, 410, 2), _size = size})
        frame = lc.createNode(size)
    else
        frame = lc.createNode(size)
    end
    
    local iconName, nameStr, descStr, damageStr, powerStr = V.getSkillDisplayInfo(skillId)
    --[[
    if skill._provider == BattleData.SkillProvider.extra or skill._provider == BattleData.SkillProvider.given then
        nameStr = nameStr..' ('..Str(STR.BATTLE_CARD_EXTRA_SKILL)..')'
    end
    ]]
  
    local name = V.createTTFBold(nameStr, V.FontSize.S1, V.COLOR_TEXT_DARK)
    name:setAnchorPoint(0, 0.5)
    lc.addChildToPos(frame, name, cc.p(124, lc.h(frame) - lc.ch(name) - 2))
    frame._name = name

    local desc = V.createTTF(descStr, V.FontSize.S3, V.COLOR_TEXT_DARK)
    desc:setDimensions(lc.w(frame) - 40, lc.bottom(name) - 4)
    lc.addChildToPos(frame, desc, cc.p(lc.cw(frame), lc.ch(desc) - 2))
    frame._desc = desc

    local icon = lc.createSprite(iconName)
    lc.addChildToPos(frame, icon, cc.p(35, lc.y(name)))
    frame._icon = icon

    local label = V.createTTFBold(powerStr, V.FontSize.S2, V.COLOR_TEXT_DARK)
    --label:enableOutline(lc.Color4B.black, 2)
    label:setVisible(powerStr ~= '')
    lc.addChildToCenter(icon, label)
    lc.offset(label, 34)
    frame._powerLabel = label 

    local damage = V.createTTFBold(damageStr, V.FontSize.S1, V.COLOR_TEXT_DARK)
    --damage:enableOutline(lc.Color4B.black, 2)
    damage:setAnchorPoint(0, 0.5)
    lc.addChildToPos(frame, damage, cc.p(lc.w(frame) - lc.cw(damage) - 6 - 38, lc.y(name)))
    frame._damage = damage

    frame.update = function(self, skillId) 
        if skillId == nil or skillId == 0 then 
            self:setVisible(false)
            return
        end

        self:setVisible(true)
        local iconName, nameStr, descStr, damageStr, powerStr = V.getSkillDisplayInfo(skillId)
        self._icon:setSpriteFrame(iconName)
        self._name:setString(nameStr)
        self._desc:setString(descStr)
        self._damage:setString(damageStr)

        self._powerLabel:setString('x'..powerStr)
        self._powerLabel:setVisible(powerStr ~= '')
    end

    return frame
end

function _M.createMagicSkill(skillId, size)
    local frame = lc.createNode(size)
    
    local iconName, nameStr, descStr, damageStr, powerStr = V.getSkillDisplayInfo(skillId)
    
    local name = V.createTTFBold(nameStr, V.FontSize.S1, V.COLOR_TEXT_DARK)
    lc.addChildToPos(frame, name, cc.p(lc.cw(frame), lc.h(frame) - lc.ch(name) - 8))
    frame._name = name

    local desc = V.createTTF(descStr, V.FontSize.S3, V.COLOR_TEXT_DARK)
    desc:setDimensions(lc.w(frame) - 20, lc.bottom(name) - 8)
    lc.addChildToPos(frame, desc, cc.p(lc.cw(frame), lc.ch(desc) + 4))
    frame._desc = desc

    frame.update = function(self, skillId) 
        local iconName, nameStr, descStr, damageStr, powerStr = V.getSkillDisplayInfo(skillId)
        self._name:setString(nameStr)
        self._desc:setString(descStr)
    end

    return frame
end

function _M.createCardShadow(infoId, scaleFactor, x, y)
    local shadow = lc.createSprite(_M.getCardShadowFrameName(card))
    
    shadow.update = function(self, infoId)
        self:setSpriteFrame(_M.getCardShadowFrameName(infoId))
        self:setScale(4 * (scaleFactor or 1))
        --self:setOpacity(V.isInBattleScene() and 50 or 120)

        if infoId then
            x, y = x or _M.CARD_SIZE.width / 2, y or _M.CARD_SIZE.height / 2
            self:setPosition(x + 8, y - 8)
        end
    end
       
    shadow:update(infoId)
    return shadow
end

function _M.getCardFrameName(cardType, nature)
    if cardType == Data.CardType.monster then
        return string.format('card_frame_nature_%02d', nature or 0)
    elseif cardType == Data.CardType.magic then 
        return 'card_frame_nature_magic'
    end
end

function _M.getCardBackName(infoId, isSquare)
    local name = isSquare and 'card_back_square' or 'card_back'
    name = name..'_'..(infoId and (infoId - 7600) or 0)
    local subChannelName = name..'_'..ClientData.getSubChannelName()
    if lc.FrameCache:getSpriteFrame(subChannelName) then name = subChannelName end
    return name
end

function _M.getCardLevelName(level)
    return 'card_frame_level_0'..level
end

function _M.getCardImageName(infoId, skinId)
    local frameName = (skinId and skinId > 0) and skinId or ClientData.getPicIdByInfoId(infoId)
    local fileName = ''
    local cardType = Data.getType(tonumber(frameName))

    if cardType == Data.CardType.monster or cardType == Data.CardType.monster_skin then fileName = 'res/thumb_monster/'..frameName..'.lcres'
    elseif cardType == Data.CardType.magic then fileName = 'res/thumb_magic/'..frameName..'.lcres'
    elseif cardType == Data.CardType.trap then fileName = 'res/thumb_trap/'..frameName..'.lcres'
    end
    frameName = frameName..((cardType == Data.CardType.magic or cardType == Data.CardType.trap) and '.jpg' or '.jpg')
    TextureManager.loadTexture(frameName, fileName)

    return frameName
end

function _M.getCardIconName(infoId, isSmall)
    local iconName = (isSmall and "ico_s_" or "ico_")..ClientData.getPicIdByInfoId(infoId)

    if lc.FrameCache:getSpriteFrame(iconName) == nil then
        local cardType = Data.getType(infoId)
		if cardType == Data.CardType.monster then iconName = "ico_monster_default"
        elseif cardType == Data.CardType.magic then iconName = "ico_magic_default"
        elseif cardType == Data.CardType.trap then iconName = "ico_trap_default"
        elseif cardType == Data.CardType.props then iconName = "ico_prop_default"
        end
    end
    return iconName
end

function _M.getCardShadowFrameName(infoId)
    return "card_shadow"
end

function _M.getCardShader(infoId)
    return nil
end

function _M.getCardQualityStrColor(quality, isDark)
    if _M.QUALITY_COLOR == nil then
        _M.QUALITY_COLOR = {
            [Data.CardQuality.HR] = _M.COLOR_TEXT_LIGHT,
            [Data.CardQuality.RR] = _M.COLOR_TEXT_LIGHT,
            [Data.CardQuality.UR] = _M.COLOR_TEXT_LIGHT,
            [Data.CardQuality.SR] = _M.COLOR_TEXT_LIGHT,
            [Data.CardQuality.R] = _M.COLOR_TEXT_LIGHT,
            [Data.CardQuality.C] = _M.COLOR_TEXT_LIGHT,
            [Data.CardQuality.U] = _M.COLOR_TEXT_LIGHT
        }
    end
    
    if isDark and _M.QUALITY_COLOR_DARK == nil then
        _M.QUALITY_COLOR_DARK = {
            [Data.CardQuality.HR] = _M.COLOR_TEXT_DARK,
            [Data.CardQuality.RR] = _M.COLOR_TEXT_DARK,
            [Data.CardQuality.UR] = _M.COLOR_TEXT_DARK,
            [Data.CardQuality.SR] = _M.COLOR_TEXT_DARK,
            [Data.CardQuality.R] = _M.COLOR_TEXT_DARK,
            [Data.CardQuality.C] = _M.COLOR_TEXT_DARK,
            [Data.CardQuality.U] = _M.COLOR_TEXT_DARK,
        }
    end

    if _M.QUALITY_STR == nil then
        _M.QUALITY_STR = {
            [Data.CardQuality.HR] = 'HR',
            [Data.CardQuality.RR] = 'RR',
            [Data.CardQuality.UR] = 'UR',
            [Data.CardQuality.SR] = 'SR',
            [Data.CardQuality.R] = 'R',
            [Data.CardQuality.C] = 'C',
            [Data.CardQuality.U] = 'U',
        }
    end

    if quality then
        return _M.QUALITY_STR[quality], isDark and _M.QUALITY_COLOR_DARK[quality] or _M.QUALITY_COLOR[quality]
    else
        return _M.QUALITY_STR, isDark and _M.QUALITY_COLOR_DARK or _M.QUALITY_COLOR
    end
end
