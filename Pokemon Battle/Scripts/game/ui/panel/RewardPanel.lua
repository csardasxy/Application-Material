local _M = class("RewardPanel", require("BasePanel"))

local MAX_ITEM_NUM = 8
local MAX_ITEMS_HEIGHT = 140

local ITEM_SPACE = 16

_M.MODE_CHEST = 1
_M.MODE_SPLIT = 2
_M.MODE_CLAIM = 3
_M.MODE_MIX_FRAGMENT = 4
_M.MODE_CLAIM_ALL = 5
_M.MODE_BUY = 6
_M.MODE_LOTTERY = 7
_M.MODE_UNION_CONTRIBUTE = 8
_M.MODE_EXCHANGE = 9

function _M.create(data, mode)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)

    local bonuses = {}
    if mode == _M.MODE_CLAIM then
        if data._info then
            local bonusIds = data._info._rid
            local bonusLevels = data._info._level
            local bonusCounts = data._info._count
            local isFragment = data._info._isFragment
            for i = 1, #bonusIds do
                local bonus = {
                    _infoId = bonusIds[i],
                    _count = bonusCounts[i] * (data._multiple or 1),
                    _isFragment = isFragment[i] > 0,
                    _level = bonusLevels[i],
                }

                table.insert(bonuses, bonus)
            end

            _M.tryAddBonusExtra(data._info._id, bonuses)
        else
            bonuses = data._extraBonus
        end

    elseif mode == _M.MODE_CLAIM_ALL then
        bonuses = data

    elseif mode == _M.MODE_SPLIT then
        bonuses = data

    elseif mode == _M.MODE_MIX_FRAGMENT then
        bonuses = data

    elseif mode == _M.MODE_UNION_CONTRIBUTE then
        bonuses = data

    else
        for i = 1, #data do
            local bonus = {
                _infoId = data[i].info_id,
                _count = data[i].num,
                _isFragment = data[i].is_fragment,
                _level = data[i].level,
            }
            table.insert(bonuses, bonus)
        end

        if mode ~= _M.MODE_EXCHANGE then

            local character = P._characters[P:getCharacterId()]
            local preLevel = character._level   

            P:addResourcesData(bonuses)

            local newLevel = character._level
            if newLevel > preLevel then
                require("LevelUpPanel").createLord(preLevel, newLevel):show()
            end
        end
    end

    P:sortResultItems(bonuses)
    panel._bonuses = bonuses

    panel:init(mode)
    
    return panel
end

function _M:init(mode)
    _M.super.init(self, true)

    self._mode = mode

    --[[
    local glow = cc.Sprite:createWithSpriteFrameName("img_glow")
    glow:setScale(2.5)
    glow:setColor(V.COLOR_GLOW)
    glow:runAction(lc.rep(lc.rotateBy(1, 10)))
    lc.addChildToPos(self, glow, cc.p(lc.w(self) / 2, 0))

    local titleBg = lc.createSprite{_name = "img_title_bg", _crect = V.CRECT_TITLE_BG}
    titleBg:setContentSize(700, V.CRECT_TITLE_BG.height)
    lc.addChildToPos(self, titleBg, cc.p(lc.w(self) / 2, 0))
    
    local title
    if mode == _M.MODE_CHEST then
        title = lc.createSpriteWithMask("res/jpg/img_word_open_box.jpg")
    elseif mode == _M.MODE_SPLIT then
        title = lc.createSpriteWithMask("res/jpg/img_word_split_card.jpg")
    elseif mode == _M.MODE_MIX_FRAGMENT then
        title = lc.createSpriteWithMask("res/jpg/img_word_mix_frag.jpg")
    elseif mode == _M.MODE_BUY then
        title = lc.createSpriteWithMask("res/jpg/img_word_buy_success.jpg")
    else
        title = lc.createSpriteWithMask("res/jpg/img_word_claim_reward.jpg")
    end
    lc.addChildToPos(titleBg, title, cc.p(lc.w(titleBg) / 2, 100))
    ]]
    --[[
    local bone = cc.DragonBonesNode:createWithDecrypt("res/effects/lingjiang.lcres", "lingjiang", "lingjiang")
    bone:gotoAndPlay(mode == _M.MODE_BUY and "effect3" or (mode == _M.MODE_SPLIT and "effect5" or "effect"))
    lc.addChildToCenter(self, bone)

    bone:runAction(lc.sequence(
        bone:getAnimationDuration(mode == _M.MODE_BUY and "effect3" or (mode == _M.MODE_SPLIT and "effect5" or "effect")),
        function() bone:gotoAndPlay(mode == _M.MODE_BUY and "effect4" or (mode == _M.MODE_SPLIT and "effect6" or "effect2")) end
    ))

    ]]

    local spine = V.createSpine("lingjiangchenggong")
    lc.addChildToCenter(self, spine)
    self._spine = spine
    self:runAction(
        lc.sequence(
            function()
                spine:setAnimation(0, "animation", false)
            end, 0.2,
            function()
                spine:setAnimation(0, "animation2", true)
            end
        )
    )
    local bonuses = self._bonuses

    local list = lc.List.createV(cc.size(), 10, 10)
    self:addChild(list)
    
    local maxWidth = 0
    local width, height = 0, 0
    local item = ccui.Widget:create()

    local bigCards = {}
    for i, bonus in ipairs(bonuses) do
        if bonus._infoId == Data.ResType.clash_trophy or bonus._infoId == Data.ResType.ladder_trophy or bonus._infoId == Data.ResType.union_battle_trophy or bonus._infoId == Data.ResType.dark_trophy then
            ToastManager.push(ClientData.getNameByInfoId(bonus._infoId).." "..(bonus._count > 0 and "+" or "")..bonus._count)
        elseif item:getChildrenCount() == MAX_ITEM_NUM then
            item:setContentSize(width - ITEM_SPACE, height)
            list:pushBackCustomItem(item)
            
            maxWidth = math.max(lc.w(item), maxWidth)
            
            width, height = 0, 0
            item = ccui.Widget:create()
        end
    
        if bonus._count > 0 then
            local childItem = IconWidget.create(bonus)
            childItem:setAnchorPoint(0, 0)
            childItem:setPosition(width, 0)
            childItem:setVisible(false)
            childItem:runAction(lc.sequence(
                0.3 + i * 0.2,
                function() childItem:setVisible(true) end,
                lc.scaleTo(0.1, 1.2),
                lc.scaleTo(0.1, 1.0)
            ))
            item:addChild(childItem)
            
            --[[
            if Data.isUnionRes(bonus._infoId) then
                childItem._name:setString(childItem._name:getString()..string.format(Str(STR.BRACKETS_S), Str(STR.UNION)))
                width = width + 20
            end
            ]]
            
            width = width + lc.w(childItem) + ITEM_SPACE
            height = math.max(height, lc.h(childItem))
        end

        if Data.hasBigCard(bonus._infoId) and bonus._count > 0 then
            table.insert(bigCards, {_infoId = bonus._infoId, _num = bonus._count})
        end
    end
    
    if item:getChildrenCount() > 0 then
        item:setContentSize(width - ITEM_SPACE, height)
        list:pushBackCustomItem(item)                  
        
        maxWidth = math.max(lc.w(item), maxWidth)
    end
    list:refreshView()
    
    local scrH = lc.Director:getVisibleSize().height
    local titleH, itemsH = scrH - MAX_ITEMS_HEIGHT, math.min(MAX_ITEMS_HEIGHT, list:getInnerContainerSize().height)
    list:setContentSize(maxWidth + 20, itemsH)
    list:setAnchorPoint(0.5, 0.5)
    list:setPosition(lc.w(self) / 2, scrH / 2 - 50)

    --glow:setPositionY(lc.top(list) + titleH / 2)
    --titleBg:setPositionY(lc.y(glow) - 24)
    
    self._item = item
    self:addBackButton()

    if #bigCards > 0 then
        self._bigCards = bigCards
    end

    lc.Audio.playAudio(AUDIO.E_CLAIM)
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listener = lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end)

    if self._bigCards then
        require("RewardCardPanel").create(Str(STR.GET)..Str(STR.CARD), self._bigCards):show()
    end
end

function _M:onExit()
    _M.super.onExit(self)
    self._spine:removeFromParent()
    lc.Dispatcher:removeEventListener(self._listener)
end

function _M:onCleanup()
    _M.super.onCleanup(self)
    
    local mode, name = self._mode
    if mode == _M.MODE_CHEST or mode == _M.MODE_LOTTERY then
        name = "res/jpg/img_word_open_box.jpg"
    elseif mode == _M.MODE_SPLIT then
        name = "res/jpg/img_word_split_card.jpg"
    elseif mode == _M.MODE_MIX_FRAGMENT then
        name = "res/jpg/img_word_mix_frag.jpg"
    elseif mode == _M.MODE_BUY then
        name = "res/jpg/img_word_buy_success.jpg"
    else
        name = "res/jpg/img_word_claim_reward.jpg"
    end

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename(name))
end

function _M:hide()
    _M.super.hide(self)

    local curStep = GuideManager.getCurStepName()
    if curStep == "leave claim 2" then
        GuideManager.finishStep()
    end
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "leave claim 2" then
        GuideManager.setOperateLayer(self._btnBack, nil, {self})
    else
        return
    end
    event:stopPropagation()
end

function _M.tryAddBonusExtra(infoId, bonuses)
    local activityInfo, pos = ClientData.getValidActivityByTypeAndParam(525, infoId)
    if activityInfo == nil then return end
    local extraBonusId = activityInfo._bonusId[pos]
    local info = Data._bonusInfo[extraBonusId]
    if info == nil then return end

    local bonusIds = info._rid
    local bonusLevels = info._level
    local bonusCounts = info._count
    local isFragment = info._isFragment
    for i = 1, #bonusIds do
        local bonus = nil
        for j = 1, #bonuses do
            if bonuses[j]._infoId == bonusIds[i] then
                bonus = bonuses[j]
                break
            end
        end
        if bonus ~= nil then
            bonus._count = bonus._count + bonusCounts[i]
        else
            local bonus = {
                _infoId = bonusIds[i],
                _count = bonusCounts[i],
                _isFragment = isFragment[i] > 0,
                _level = bonusLevels[i],
            }
            table.insert(bonuses, bonus)
        end
    end
end

return _M