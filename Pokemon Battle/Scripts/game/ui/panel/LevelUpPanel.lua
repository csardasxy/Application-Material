local _M = class("LevelUpPanel", require("BasePanel"))

_M.Type = {
    lord            = 1,
    vip             = 2,
    union           = 3
}

function _M.createLord(preLevel, curLevel)
    return _M.create(_M.Type.lord, preLevel, curLevel)
end

function _M.createVip(preLevel, curLevel)
    return _M.create(_M.Type.vip, preLevel, curLevel)
end

function _M.createUnion(preLevel, curLevel)
    return _M.create(_M.Type.union, preLevel, curLevel)
end

function _M.create(upType, preLevel, curLevel)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(upType, preLevel, curLevel)
    return panel
end

function _M:init(upType, preLevel, curLevel)
    self._type = upType

    _M.super.init(self, true, true)

    self._curLevel = curLevel
    self._preLevel = preLevel
    
    -- Create common stuffs
    local bg = lc.createSpriteWithMask("res/jpg/img_word_level_bg.jpg")
    lc.addChildToCenter(self, bg)
    self._bg = bg

    local glow = lc.createSprite("img_glow")
    glow:setScale(1.5)
    glow:setColor(V.COLOR_GLOW_BLUE)
    glow:runAction(lc.rep(lc.rotateBy(1, 10)))
    lc.addChildToPos(bg, glow, cc.p(lc.cw(bg), lc.h(bg) - 40))

    local preLevel = V.createBMFont(V.BMFont.num_48, tostring(preLevel))
    preLevel:setColor(lc.Color4B.white)
    local curLevel = V.createBMFont(V.BMFont.num_48, tostring(curLevel))
    curLevel:setColor(lc.Color4B.green)
    local arrow = lc.createSprite("img_arrow_right")
    arrow:setColor(lc.Color4B.green)
    lc.addNodesToCenterH(bg, {preLevel, arrow, curLevel}, 20, lc.h(bg) - 130)
    
    local btnBack = V.createScale9ShaderButton("img_btn_1_s", function() self:hide() end, V.CRECT_BUTTON_S, 200)
    btnBack:addLabel(Str(STR.BACK))
    btnBack:setPosition(V.SCR_CW, lc.bottom(bg) + 80)
    self:addChild(btnBack)
    self._btnBack = btnBack

    -- Create specified stuffs
    if upType == _M.Type.lord then
        self:initLord()
    elseif upType == _M.Type.vip then
        self:initVip()
    elseif upType == _M.Type.union then
        self:initUnion()
    end
end

function _M:initLord()
    local lord = lc.createSpriteWithMask("res/jpg/img_word_lord.jpg")
    lc.addChildToPos(self._bg, lord, cc.p(lc.cw(self._bg), lc.h(self._bg) - 30))

    local player, preL, curL = ClientData._player, self._preLevel, self._curLevel

    local lines = {}
    local tryAddLine = function(label, iconName, v1, v2)
        if v1 ~= v2 then
            local line = self:createUpdateLine(label, iconName, v1, v2)
            table.insert(lines, line)
        end
    end

    --[[
    local characterId = P:getCharacterId()
    local bones = DragonBones.create(Data.CharacterNames[characterId])
    bones:gotoAndPlay(string.format("effect_%02d", characterId))
    bones:setScale(0.4)
    ]]

    local userArea = UserWidget.create(P, bor(UserWidget.Flag.LEVEL_NAME, UserWidget.Flag.VIP, UserWidget.Flag.CLICKABLE), 1.0, false, true)
    userArea:setName(Str(Data._characterInfo[P:getCharacterId()]._nameSid))
    lc.addChildToCenter(self._bg, userArea)
    lc.offset(userArea, 0, -10)
    

    --[[

    local defaultY = lc.h(self._bg) - 190
    local x, y = lc.cw(self._bg), lc.h(self._bg) - 190

    local levelupGrain = player:getLevelupGrain(preL, curL)

    tryAddLine(Str(STR.LEVEL_UP_HP), "img_icon_res7", player:getHp(preL), player:getHp(curL))
    tryAddLine(Str(STR.LEVEL_UP_TROOP), "img_icon_cardnum", player:getUnlockTroopNumber(preL), player:getUnlockTroopNumber(curL))
    tryAddLine(Str(STR.LEVEL_UP_GRAIN), "img_icon_res2_s", player._grain - levelupGrain, player._grain)
    tryAddLine(Str(STR.LEVEL_UP_GRAIN_MAX), "img_icon_res14_s", player:getGrainCapacity(preL), player:getGrainCapacity(curL))
    

    
    for _, line in ipairs(lines) do
        local lineH = lc.h(line)

        lc.addChildToPos(self._bg, line, cc.p(x, y - lc.h(line) / 2), 1)
        y = y - 20 - lineH
    end

    local sprite = lc.createSprite({_name = "img_com_bg_36", _crect = V.CRECT_COM_BG36, _size = cc.size(540, math.max(110, defaultY + 20 - y))})
    lc.addChildToPos(self._bg, sprite, cc.p(x, y + (defaultY + 20 - y) / 2))
    ]]
end

function _M:initVip()
    local lord = lc.createSpriteWithMask("res/jpg/img_word_vip.jpg")
    lc.addChildToPos(self._bg, lord, cc.p(lc.cw(self._bg), lc.h(self._bg) - 30))

    local btnVipDetail = V.createScale9ShaderButton("img_btn_1_s", nil, V.CRECT_BUTTON_S, 200)
    btnVipDetail:addLabel(Str(STR.LOOK_OVER)..' VIP '..Str(STR.PRIVILEGE))
    btnVipDetail._callback = function()
        self:hide()
        require("VIPInfoForm").create():show()
    end
    lc.addChildToPos(self._bg, btnVipDetail, cc.p(lc.cw(self._bg), lc.ch(self._bg)))

    lc.offset(self._btnBack, 0, 40)
end

function _M:initUnion()
    local lord = lc.createSpriteWithMask("res/jpg/img_word_union.jpg")
    lc.addChildToPos(self._bg, lord, cc.p(lc.cw(self._bg), lc.h(self._bg) - 30))
end

function _M:createUpdateLine(label, iconName, v1, v2)
    local line = lc.createNode(cc.size(450, 32))
    
    local icon = lc.createSprite(iconName)
    lc.addChildToPos(line, icon, cc.p(lc.w(icon) / 2, lc.h(line) / 2))

    local label = V.createKeyValueLabel(label, tostring(v1), V.FontSize.M2, true)
    label:addToParent(line, cc.p(lc.right(icon) + 10, lc.h(line) / 2))
    label:setColor(lc.Color4B.white)

    local arrow = lc.createSprite("img_arrow_right")
    arrow:setScale(0.8)
    arrow:setColor(lc.Color4B.green)
    lc.addChildToPos(line, arrow, cc.p(320, lc.h(line) / 2))

    label._value:setPositionX(lc.left(arrow) - 20 - lc.w(label._value))

    local curVal = V.createTTF(tostring(v2), V.FontSize.M2, lc.Color4B.green)
    lc.addChildToPos(line, curVal, cc.p(lc.right(arrow) + 20 + lc.w(curVal) / 2, lc.h(line) / 2))

    line._hasValue = true
    return line
end

function _M:onEnter()
    _M.super.onEnter(self)

    lc.Audio.playAudio(AUDIO.E_PLAYER_UPGRADE)
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    if self._cleanupHandler then
        self._cleanupHandler()
    end

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_word_level.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_word_level_bg.jpg"))

    if self._type == _M.Type.lord then
        lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_word_lord.jpg"))
    elseif self._type == _M.Type.vip then
        lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_word_vip.jpg"))
    elseif self._type == _M.Type.union then
        lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_word_union.jpg"))
    end
end

return _M