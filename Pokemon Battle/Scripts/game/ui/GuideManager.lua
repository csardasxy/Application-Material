local _M = {}

_M.StepType = 
{    
    dialog                  = 1,
    operation               = 2,
    tip                     = 3,
    other                   = 4                     
}

_M.OperateType = 
{
    tap                     = 1,
    move                    = 2,
}

_M.HighlightType =
{
    battle_gem              = 1,
    battle_atk_hp           = 2,
    battle_atk              = 3,
    battle_round_btn        = 4,
    battle_skill            = 5,
    battle_fortress         = 6,
    battle_empty_pos        = 7,
    battle_setting_btn      = 8,
    battle_atk_hp_2         = 9,

    herocenter_troop        = 100
}

_M.Event = 
{
    seek                    = "guide seek",  
    finish                  = "guide finished"
}

_M.GUIDE_ID_GROUP_SIZE                      = 100

function _M.checkStartNewGuideByLevel()
   local curLevel, playerCity = P._level, P._playerCity
   local guideLevels = 
   {
       --playerCity:getBlacksmithUnlockLevel(),
       --Data._globalInfo._unlockRobExp,
       --P._playerCity:getMarketUnlockLevel(),
       Data._globalInfo._unlockFindMatch,
       --Data._globalInfo._unlockRobGold,
       --Data._globalInfo._unlockFindMatch,
       --P._playerCity:getGuardUnlockLevel(),
       --Data._globalInfo._unlockCommander,
       --P._playerCity:getUnionUnlockLevel(),
       Data._globalInfo._unlockExpedition,
       --P._playerCity:getLibraryUnlockLevel(),
       --Data._globalInfo._unlockLadder
   }
   
   local guideTypes = 
   {
        --Data.UnlockGuideType.equip,
        --Data.UnlockGuideType.rob_exp,
        --Data.UnlockGuideType.market,
        Data.UnlockGuideType.find_match,
        --Data.UnlockGuideType.rob_gold,
        --Data.UnlockGuideType.find_match,
        --Data.UnlockGuideType.guard,
        --Data.UnlockGuideType.rob_horse,
        --Data.UnlockGuideType.union,
        Data.UnlockGuideType.expedition,
        --Data.UnlockGuideType.library,
        --Data.UnlockGuideType.ladder,
   }
   
   for i = 1, #guideLevels do
        if curLevel >= guideLevels[i] and (P._guideID < 500 or P._guideID % _M.GUIDE_ID_GROUP_SIZE == 0)
        and math.floor(P._guideID / _M.GUIDE_ID_GROUP_SIZE) < guideTypes[i] then
            local newGuideId = guideTypes[i] * _M.GUIDE_ID_GROUP_SIZE + 1
            _M.setGuideIDandSave(newGuideId)
            
            local info = Data._guideInfo[newGuideId]
            if info._sceneId == ClientData.SceneId.world then
                _M._hasNewWorldGuide = true
            else
                _M._hasNewCityGuide = true
            end

            break
        end  
   end
end

function _M.getGuideStepType(info)
    return info._stepType01
end

function _M.startStepLater(delay)
    -- Call this function instead of startStep() when the next guide depends on the new event listener
    lc._runningScene:runAction(lc.sequence(delay or 0.1, function() _M.startStep() end))
end

function _M.startStep()
    if lc._runningScene._reloadDialog ~= nil then
        return
    end

    local guideID = P._guideID
    local info = Data._guideInfo[guideID]
    if info ~= nil then
        local mainType = math.floor(_M.getGuideStepType(info) / 10)
        lc.log("startStep %d, mainType = %d", P._guideID, mainType)

        _M._hasNewWorldGuide = false
        _M._hasNewCityGuide = false

        if mainType == 0 then
            if _M.getGuideStepType(info) ~= 0 then
                _M.showOperateLayer(true)
            end
        elseif mainType == _M.StepType.dialog then
            _M.showStoryDialog()
        elseif mainType == _M.StepType.operation then
            _M.showOperateLayer(true)
        elseif mainType == _M.StepType.tip then
            _M.showNpcTipLayer()
        else
            _M.showOperateLayer(false)
        end
        return true
    end
    
    return false
end

function _M.finishStepLater(delay)
    -- Call this function instead of finishStep() when the next guide depends on the new event listener
    if _M._layer then
        _M._layer._blockTouch = true
    end

    lc._runningScene:runAction(lc.sequence(delay or 0.1, function() _M.finishStep() end))
end

function _M.finishStep(isManualStep)
    lc.log("finish step id: %d, name: %s, isMaualStep = %s", P._guideID, _M.getCurStepName(), isManualStep and "true" or "false")

    local guideID = P._guideID
    local info = Data._guideInfo[guideID]
    if info == nil then return end

    if _M.getGuideStepType(info) ~= 33 and _M.getGuideStepType(info) ~= 34 then
        _M.closeNpcTipLayer()
    end
    
    _M.releaseLayer()
    _M.releaseFinger()
    
    -- Check save step
    local saveStep = info._saveStep
    if (guideID < 200 and saveStep > 0) or (guideID >= 200 and saveStep >= 500 and saveStep % _M.GUIDE_ID_GROUP_SIZE == 0)  then
        if saveStep < 10000 then
            --P._guideID = saveStep
            ClientData.sendGuideID(saveStep)

            local eventCustom = cc.EventCustom:new(_M.Event.finish)
            eventCustom._guideId = saveStep
            lc.Dispatcher:dispatchEvent(eventCustom)
        else
            P._guideID = GuideManager._savedGuideId
            _M._savedGuideId = nil

            if _M.isGuideEnabled() then
                _M.startStep()
            end 
            return 
        end
    end

    local finishSceneId = info._sceneId

    P._guideID = guideID + 1
    info = Data._guideInfo[P._guideID]
    if info == nil then
        --local group = _M.getGroup()
        --P._guideID = (group + 1) * _M.GUIDE_ID_GROUP_SIZE + 1
        --info = Data._guideInfo[P._guideID]         
        if info == nil then 
            return      
        end
    end

    -- If the scene id of guide steps are different, we should save the step to server
    if finishSceneId ~= info._sceneId and saveStep > 0 then
        ClientData.sendGuideID(saveStep)
    end
    
    if lc._runningScene._reloadDialog == nil then
        if isManualStep then
            _M.showOperateLayer(false)  
        else
            _M.startStep()
        end
    end
end

function _M.pauseGuide()
    if _M._layer == nil and _M._storyLayer == nil and _M._tipLayer == nil then
        return
    end

    if _M._layer then
        _M._layer:setVisible(false)
        _M._layer._ignoreTouch = true       -- For operate layer
    end

    if _M._storyLayer then _M._storyLayer:setVisible(false) end
    if _M._tipLayer then _M._tipLayer:setVisible(false) end
    if _M._finger then _M._finger:setVisible(false) end
end

function _M.resumeGuide()
    if _M._layer then
        _M._layer:setVisible(true)
        _M._layer._ignoreTouch = false      -- For operate layer
    end

    if _M._storyLayer then _M._storyLayer:setVisible(true) end
    if _M._tipLayer then _M._tipLayer:setVisible(true) end
    if _M._finger then _M._finger:setVisible(true) end
end

function _M.stopGuide()
    _M.closeStoryDialog()
    _M.closeNpcTipLayer()
    _M.releaseLayer()
    _M.releaseFinger()
end

function _M.addContainerLayer(child, zorder, clipRect)
    local container
    if clipRect then
        container = V.createClipNode(child, clipRect, true)
    else
        container = cc.Node:create()
        container:addChild(child)
    end

    container:setContentSize(lc._runningScene._scene:getContentSize())
    lc._runningScene._scene:addChild(container, zorder or ClientData.ZOrder.guide)

    child._guideContainer = container
    return container
end

function _M.removeContainerLayer(child)
    if child._guideContainer then
        child._guideContainer:removeFromParent()
        child._guideContainer = nil
    else
        child:removeFromParent()
    end
end

function _M.addHighlightEffect(hlType, param)
    local rx, ry = V.SCR_CW, V.SCR_CH

    local createTextPointer = function(rect, text, isFlip)
        pointer = lc.createSprite("img_arrow_right")
        pointer:setColor(lc.Color3B.yellow)
        pointer:setPosition(rect.x - 40, rect.y + 70)
        pointer:runAction(lc.rep(lc.sequence(lc.moveBy(0.5, -10, 0), lc.moveBy(0.5, 10, 0))))

        if isFlip then pointer:setFlippedX(isFlip) end

        if text then
            text = V.createTTF(text, V.FontSize.S1, lc.Color3B.yellow)
        end
        
        return text, pointer
    end

    local parent = _M._tipLayer or _M._storyDialog
    local rect, pointer, text, rect2, pointer2, text2
    if hlType == _M.HighlightType.battle_gem then
        local battleScene = lc._runningScene
        local battleUi = battleScene._battleUi
        local playerUi = battleUi._playerUi
        local cardSprite = playerUi._pHandCards[1]
        
        local cw, ch = 70 * battleUi._scale, 8 * battleUi._scale
        local pos = parent:convertToNodeSpace(cardSprite._pFrame._starArea:getParent():convertToWorldSpace(cc.p(cardSprite._pFrame._starArea:getPosition())))
        pos.x = pos.x
        pos.y = pos.y - 40
        rect = cc.rect(pos.x - cw, pos.y - ch, cw * 2, ch * 2)
        text, pointer = createTextPointer(rect, Str(STR.MONSTER_STAR))
        pointer:setPosition(rect.x - 30, rect.y + ch)
        text:setPosition(lc.right(pointer) - lc.w(text) / 2, lc.top(pointer) + lc.h(text) / 2)

    elseif hlType == _M.HighlightType.battle_atk_hp or hlType == _M.HighlightType.battle_atk_hp_2 then
        local battleScene = lc._runningScene
        local battleUi = battleScene._battleUi
        local playerUi = battleUi._playerUi
        local cardSprite = playerUi._pBoardCards[1]
        pos = parent:convertToNodeSpace(cardSprite:getParent():convertToWorldSpace(cc.p(cardSprite:getPosition())))
        pos.y = pos.y - 40 * battleUi:getScale()

        local cw, ch = 80 * battleUi:getScale(), 18 * battleUi:getScale()
        rect = cc.rect(pos.x - cw, pos.y - ch, cw * 2, ch * 2)
        text, pointer = createTextPointer(rect, Str(hlType == _M.HighlightType.battle_atk_hp and STR.ATK_VALUE or STR.HP_VALUE))
        pointer:setPosition(rect.x - 30, rect.y + ch)
        text:setPosition(lc.right(pointer) - lc.w(text) / 2, lc.top(pointer) + lc.h(text) / 2)

        --[[
        local addTip = function(str, isFlipX, pos)
            local node = cc.Node:create()
            node:setAnchorPoint(isFlipX and 1 or 0, 0.5)

            local atk = V.createTTF(str, V.FontSize.S1, V.COLOR_TEXT_DARK)
            local size = cc.size(150, 70)
            node:setContentSize(size)

            local bg = lc.createSprite{_name = "bat_dlg_bg2", _crect = cc.rect(70, 25, 1, 1), _size = size}
            bg:setFlippedY(true)
            if isFlipX then bg:setFlippedX(isFlipX) end
            bg:setCascadeOpacityEnabled(true)
            lc.addChildToCenter(node, bg)
            lc.addChildToPos(node, atk, cc.p(isFlipX and 60 or 90, 28))

            table.insert(parent._highlightObjs, node)
            lc.addChildToPos(lc._runningScene._scene, node, pos, ClientData.ZOrder.guide)
        end
        
        addTip(Str(STR.ATK_VALUE), true, cc.p(rect.x + 40, rect.y + 10))
        addTip(Str(STR.HP_VALUE), false, cc.p(rect.x + rect.width - 40, rect.y + 10))
        ]]

    elseif hlType == _M.HighlightType.battle_atk then
        local battleScene = lc._runningScene
        local battleUi = battleScene._battleUi
        local playerUi = battleUi._playerUi
        local cardSprite = playerUi._pBoardCards[1]
        
        pos = cc.p(V.SCR_CW - 30, lc.y(battleUi))
        local cw, ch = 76 * battleUi:getScale(), 240 * battleUi:getScale()
        rect = cc.rect(pos.x - cw, pos.y - ch, cw * 2, ch * 2)

        local arrow = lc.createSprite{_name = "img_arrow_up_3", _crect = V.CRECT_ARROW_3, _size = cc.size(40, 300)}
        arrow:setOpacity(230)
        local label = V.createBMFont(V.BMFont.huali_32, Str(STR.POWER))
        label:setColor(cc.c3b(255, 150, 150))
        lc.addChildToCenter(arrow, label)
        table.insert(parent._highlightObjs, arrow)
        lc.addChildToPos(lc._runningScene._scene, arrow, cc.p(rx - 30, ry + 60), ClientData.ZOrder.guide)

    elseif hlType == _M.HighlightType.battle_round_btn then
        local battleScene = lc._runningScene
        local battleUi = battleScene._battleUi
        local playerUi = battleUi._playerUi
        
        pos = parent:convertToNodeSpace(battleUi._btnEndRound:getParent():convertToWorldSpace(cc.p(battleUi._btnEndRound:getPosition())))
        pos.x = pos.x - 16
        pos.y = pos.y - 6
        local cw, ch = 60 * battleUi:getScale(), 64 * battleUi:getScale()
        rect = cc.rect(pos.x - cw, pos.y - ch, cw * 2, ch * 2)

        _, pointer = createTextPointer(rect)
        pointer:setPosition(rect.x - 40, rect.y + 35)

        battleUi._btnEndRound:loadTextureNormal("bat_btn_5", ccui.TextureResType.plistType)
        battleUi._pRoundTitle:setSpriteFrame("bat_label_end_2")

    elseif hlType == _M.HighlightType.battle_skill then
        rect = cc.rect(rx - 452, ry - 76, 320, 160)
    
    elseif hlType == _M.HighlightType.battle_fortress then
        rect = cc.rect(rx - 105, ry + 256, 210, 80)

        text, pointer = createTextPointer(rect, string.format("%s%s", Str(STR.LEVEL_UP_HP), string.format(Str(STR.BRACKETS_S), Str(STR.LIFE))))
        pointer:setPosition(rect.x - 40, rect.y + 30)
        text:setPosition(lc.right(pointer) - lc.w(text) / 2, lc.top(pointer) + lc.h(text) / 2)

    elseif hlType == _M.HighlightType.battle_empty_pos then
        rect = cc.rect(rx + 80, ry - 130, 160, 400)

        local arrow = lc.createSprite{_name = "img_arrow_up_3", _crect = V.CRECT_ARROW_3, _size = cc.size(40, 340)}
        arrow:setOpacity(230)
        arrow:setRotation(-20)
        local label = V.createBMFont(V.BMFont.huali_32, Str(STR.POWER)..Str(STR.FORTRESS))
        label:setColor(cc.c3b(255, 150, 150))
        lc.addChildToCenter(arrow, label)
        table.insert(parent._highlightObjs, arrow)
        lc.addChildToPos(lc._runningScene._scene, arrow, cc.p(rx + 90, ry + 140), ClientData.ZOrder.guide)

    elseif hlType == _M.HighlightType.battle_setting_btn then
        local x, y, w, h = lc.x(param), lc.y(param), lc.w(param), lc.h(param)
        rect = cc.rect(x - w / 2, y - h / 2 + 3,  w, h)

        text, pointer = createTextPointer(rect, Str(STR.BATTLE_SETTING_BUTTON), true)
        pointer:setPosition(x + 80, y - 12)
        text:setPosition(lc.left(pointer) + lc.w(text) / 2, lc.top(pointer) + lc.h(text) / 2)

    elseif hlType == _M.HighlightType.herocenter_troop then
        local scrWidth = V.SCR_W
        rect = cc.rect(scrWidth - 212, 4, 208, 104)

    end

    if rect then
        local highlight = lc.createSprite{_name = "img_highlight_rect", _crect = cc.rect(21, 21, 1, 1), _size = cc.size(rect.width + 20, rect.height + 20)}
        highlight:setColor(lc.Color3B.yellow)
        table.insert(parent._highlightObjs, highlight)
        lc.addChildToPos(parent, highlight, cc.p(rect.x + rect.width / 2, rect.y + rect.height / 2))

        if pointer then
            table.insert(parent._highlightObjs, pointer)
            parent:addChild(pointer)
        end 

        if text then
            table.insert(parent._highlightObjs, text)
            parent:addChild(text)
        end
    end

    return rect
end

function _M.getCurSaveGuideId()
    local guideId = P._guideID
    if guideId == nil then return nil end

    local info = Data._guideInfo[guideId]
    if info == nil or info._saveStep == 0 then return nil end

    return info._saveStep
end

function _M.getGroup()
    return math.floor(P._guideID / _M.GUIDE_ID_GROUP_SIZE)
end

function _M.isGuideEnabled()
    local guideId = P._guideID
    if guideId == nil then return false end
    
    return Data._guideInfo[guideId] ~= nil or P._guideID < 100
end

function _M.isGuideInCity()
    local info = Data._guideInfo[P._guideID]
    if info == nil then return false end

    return info._sceneId == ClientData.SceneId.city and _M.isGuideEnabled()
end

function _M.isGuideInWorld()
    local info = Data._guideInfo[P._guideID]
    if info == nil then return false end

    return info._sceneId == ClientData.SceneId.world and _M.isGuideEnabled()
end

function _M.setGuideIDandSave(guideID, isIgnoreInfo)
    if P._guideID == guideID then return end

    lc.log("Set guide id = %d", guideID)

    if isIgnoreInfo or Data._guideInfo[guideID] then
        P._guideID = guideID
        ClientData.sendGuideID(guideID) 
    end
end

function _M.showStoryDialog()
    local info = Data._guideInfo[P._guideID]
    
    _M.releaseLayer()

    -- Create container
    local maskLayer = lc.createMaskLayer(V.MASK_OPACITY_LIGHT)
    _M.addContainerLayer(maskLayer)

    local dlg = _M.createStoryDialog({_nameSid = info._nameSid, _stepType = _M.getGuideStepType(info), _roleId = info._param}, function()
        _M.finishStep()
        maskLayer:removeFromParent()
    end)
    maskLayer:addChild(dlg)
end

function _M.createStoryDialog(story, closeHandler)
    local DIALOG_WIDTH      = 800
    local DIALOG_HEIGHT     = 240
    local CONTENT_WIDTH     = 450
    local MARGIN_TOP        = 50
    local MARGIN_LEFT       = 70

    local isSelfStory = (story._stepType < 20)
    local isLeftSide = (story._stepType % 10) == 1

    -- Close previous dialog
    _M.closeStoryDialog()

    -- Dialog container
    local dialog = ccui.Widget:create()
    dialog:setContentSize(lc.Director:getVisibleSize())
    dialog:setAnchorPoint(0, 0)
    dialog:setPosition(0, 0)
    dialog._isSelfStory = isSelfStory
    _M._storyDialog = dialog

    dialog._highlightObjs = {}

    -- Background
    local bg = lc.createSprite{_name = "img_com_bg_16", _crect = V.CRECT_COM_BG16, _size = cc.size(DIALOG_WIDTH, DIALOG_HEIGHT)}
    bg:setPosition(lc.w(dialog) / 2, lc.h(dialog) / 2 + (isSelfStory and -80 or 250))
    dialog._bg = bg
    dialog:addChild(bg)

    dialog:setTouchEnabled(false)
    dialog._closeHandler = closeHandler
    dialog:addTouchEventListener(function(sender, evt) 
        if evt == ccui.TouchEventType.ended then
            _M.closeStoryDialog()
            if dialog._closeHandler then dialog._closeHandler() end
        end
    end)

    -- Role image and name
    local roleId = story._roleId

    local img, name
    if roleId == 0 then
        img = lc.createSprite("card_thu_0")
        name = V.createBMFont(V.BMFont.huali_26, Str(STR.NPC_NAME))
    else
        img = lc.createSprite(string.format("card_thu_%d", ClientData.getPicIdByInfoId(roleId)))
        name = V.createBMFont(V.BMFont.huali_26, ClientData.getNameByInfoId(roleId))
    end
	bg:addChild(img)
    bg:addChild(name)

    -- Content text
    local text = V.createBoldRichText(Str(story._nameSid), 
        {_normalClr = V.COLOR_TEXT_DARK, _boldClr = V.COLOR_TEXT_GREEN_DARK, _fontSize = V.FontSize.S1, _width = CONTENT_WIDTH})
    text:setCascadeOpacityEnabled(true)
    bg:addChild(text)

    -- Next label
    local next = cc.Label:createWithTTF(Str(STR.CONTINUE), V.TTF_FONT, V.FontSize.S2)
    next:setPositionY(lc.h(next) / 2 + 40)
    next:setColor(V.COLOR_TEXT_DARK)
    dialog._nextLabel = next
    bg:addChild(next)

    -- Place all elements according to the role side
    local imgW, imgH = 236, 262
    if isLeftSide then
        img:setPosition(imgW / 2 + 30, imgH / 2 + 40)
        text:setPosition(MARGIN_LEFT + lc.w(text) / 2 + imgW - 30, lc.h(bg) - MARGIN_TOP - lc.h(text) / 2)
        next:setPositionX(650)
    else
        img:setPosition(lc.w(bg) - imgW / 2 - 30, imgH / 2 + 40)
        text:setPosition(MARGIN_LEFT + lc.w(text) / 2, lc.h(bg) - MARGIN_TOP - lc.h(text) / 2)
        next:setPositionX(lc.left(text) + lc.w(next) / 2)
    end
    name:setPosition(lc.x(img), 40)
    
    -- Add name decoration
    local nameDecLeft = cc.Sprite:createWithSpriteFrameName("img_title_decoration")
    nameDecLeft:setFlippedX(true)
    lc.addChildToPos(bg, nameDecLeft, cc.p(lc.left(name) - lc.w(nameDecLeft) / 2 - 10, lc.y(name)))
    
    local nameDecRight = cc.Sprite:createWithSpriteFrameName("img_title_decoration")
    lc.addChildToPos(bg, nameDecRight, cc.p(lc.right(name) + lc.w(nameDecRight) / 2 + 10, lc.y(name)))
    
    -- Hide all contents on the bg and do show animation
    for _, ele in ipairs(bg:getChildren()) do ele:setOpacity(0) end
    
    local oriSize = lc.frameSize("img_com_bg_16")
    bg:setAnchorPoint(isSelfStory and 0 or 1, 1)
    bg:setPositionX(lc.w(dialog) / 2 + (lc.ax(bg) - 0.5) * DIALOG_WIDTH)
    bg:setContentSize(oriSize)
    bg:setOpacity(0)
    bg:runAction(cc.FadeIn:create(0.3))

    local jumpDuration = 0.4

    lc.offset(text, isLeftSide and -50 or 50)
    text:runAction(lc.sequence(jumpDuration + 0.1, {lc.fadeIn(0.2), lc.moveBy(0.2, isLeftSide and 50 or -50, 0)},
        function()
            next:runAction(lc.rep(lc.sequence(lc.fadeIn(0.5), 0.5, lc.fadeOut(0.5))))
            dialog:setTouchEnabled(true)
        end
    ))

    local stepH = 7
    local stepW = (DIALOG_WIDTH - oriSize.width) * stepH / (DIALOG_HEIGHT - oriSize.height)
    bg:registerScriptHandler(function(evt)
        if evt == "enter" then
            bg:scheduleUpdateWithPriorityLua(function(dt)
                local size = bg:getContentSize()
                size.width = size.width + stepW
                size.height = size.height + stepH
                if size.height > DIALOG_HEIGHT then
                    size.width = DIALOG_WIDTH
                    size.height = DIALOG_HEIGHT
                    bg:unscheduleUpdate()

                    lc.offset(img, 0, 50)
                    img:runAction(lc.sequence(0.05, {lc.fadeIn(jumpDuration), lc.ease(lc.moveBy(jumpDuration, 0, -50), "BackO")}))

                    name:runAction(lc.fadeIn(jumpDuration))
                    nameDecLeft:runAction(lc.fadeIn(jumpDuration))
                    nameDecRight:runAction(lc.fadeIn(jumpDuration))

                    -- Play audio
                    --local audioId = AUDIO[string.format("E_STORY_%d", story._id)]
                    --if audioId then
                    --    lc.Audio.playAudio(audioId)
                    --end
                end

                bg:setContentSize(size)
            end, 0)
        elseif evt == "exit" then
            bg:unscheduleUpdate()
        end
    end)

    return dialog
end

function _M.closeStoryDialog()
    local dlg = _M._storyDialog
    if dlg then
        dlg:setTouchEnabled(false)
        dlg._nextLabel:stopAllActions()

        _M.hideHighlightObjs(dlg)

        dlg:runAction(lc.sequence({lc.fadeOut(0.4), lc.ease(lc.moveBy(0.2, 0, dlg._isSelfStory and -500 or 350), "BackI")}, function()
            _M.removeHighlightObjs(dlg)
            _M.removeContainerLayer(dlg)
        end))

        _M._storyDialog = nil
    end
end

function _M.showNpcTipLayer()
    local guideId = P._guideID
    local info = Data._guideInfo[guideId]
    
    lc.log("show Npc guideId = %d", guideId)
    _M.releaseLayer()

    local subType = (_M.getGuideStepType(info) % 10)
    local isNeedTap = (subType <= 2)
    local isLeft = (subType == 1 or subType == 3)

    local width = info._param < 5000 and info._param or 0
    local layer = _M.createNpcTipLayer(info, isNeedTap, isLeft, false, width)
    if isNeedTap then
        layer._closeHandler = function()
            _M.finishStep()
        end

        -- Check highlighted object
        if info._param > 5000 then
            local hlType = info._param - 5000
            local rect = _M.addHighlightEffect(hlType)
            _M.addContainerLayer(layer, nil, rect)
            return
        end

    else
        _M.finishStep()
    end

    _M.addContainerLayer(layer)
end

function _M.createNpcTipLayer(info, isNeedTap, isLeft, isInBattle, w)
    local infoId = info._id
    local nameSid = info._nameSid
    
    local TIP_POS_Y = 60

    local TIP_BG_FRAME_LEFT = 45
    local TIP_BG_FRAME_RIGHT = TIP_BG_FRAME_LEFT
    local TIP_BG_FRAME_H = TIP_BG_FRAME_LEFT + TIP_BG_FRAME_RIGHT
    local TIP_BG_FRAME_TOP = 30
    local TIP_BG_FRAME_BOTTOM = 70
    local TIP_BG_FRAME_V = TIP_BG_FRAME_TOP +TIP_BG_FRAME_BOTTOM

    local TIP_NEXT_POS_L = cc.p(350, 336)
    local TIP_NEXT_POS_R = cc.p(900, 336)
   
    if w == nil or w <= 0 then
        w = 320
    end

    -- Close previous dialog
    _M.closeNpcTipLayer()

    local layer = lc.createMaskLayer(isNeedTap and V.MASK_OPACITY_LIGHT or 0, nil, V.SCR_SIZE)
    layer:setTouchEnabled(isNeedTap)
    layer._canClose = false
    _M._tipLayer = layer

    layer._highlightObjs = {}

    -- Create container
    --local container = lc.createNode(cc.size(1024, 768))
    local container = lc.createNode(V.SCR_SIZE)
    lc.addChildToCenter(layer, container)

    -- NPC animation
    local npc
    if info._roleId == 1 then
        npc = cc.DragonBonesNode:createWithDecrypt("res/effects/loading.lcres", "loading", "loading")
        npc:setPosition(isLeft and 280 or lc.w(container) - 280, 130)
        npc:gotoAndPlay("effect4")
    elseif info._roleId == 2 then
        npc = cc.DragonBonesNode:createWithDecrypt("res/effects/loading.lcres", "loading", "loading")
        npc:setPosition(isLeft and 280 or lc.w(container) - 280, 130)
        npc:gotoAndPlay("effect5")
    else
        npc = cc.DragonBonesNode:createWithDecrypt("res/effects/hmssn.lcres", "hmssn", "hmssn")
        npc:setPosition(isLeft and 250 or lc.w(container) - 250, 130)
        npc:gotoAndPlay(isLeft and "effect1" or "effect2")
    end
    container:addChild(npc, 1)
    layer._npc = npc

    local next
    if isNeedTap then
        layer:addTouchEventListener(function(sender, type)
            if type == ccui.TouchEventType.ended then
                if layer._canClose then
                    _M.closeNpcTipLayer()
                    if layer._closeHandler then layer._closeHandler() end
                end
            end
        end)

        next = cc.Label:createWithTTF(Str(STR.CONTINUE), V.TTF_FONT, V.FontSize.S2)
        next:setColor(V.COLOR_TEXT_DARK)
        next:setOpacity(0)
        layer._next = next
    end

    -- Tip
    local tipParts = string.splitByChar(Str(nameSid), '/')

    local tipStr = string.gsub(tipParts[1], "USERNAME", P._name)
    local tip = V.createBoldRichText(tipStr,
        {_normalClr = V.COLOR_TEXT_DARK, _boldClr = V.COLOR_TEXT_BLUE_2, _fontSize = V.FontSize.S1, _width = w})
    tip:setCascadeOpacityEnabled(true)
    tip:setAnchorPoint(cc.p(isLeft and 0 or 1, 0))
    tip:setOpacity(0)
    layer._tip = tip

    local tipBg = ccui.Scale9Sprite:createWithSpriteFrameName("img_tip_bg", V.CRECT_TIP_BG)
    tipBg:setAnchorPoint(isLeft and 0 or 1, 0)
    tipBg:setScale(0)
    tipBg:setContentSize(cc.size(lc.w(tip) + TIP_BG_FRAME_H, lc.h(tip) + TIP_BG_FRAME_V + (next and lc.h(next) + 10 or 0)))
    tipBg:setFlippedX(isLeft)
    layer._tipBg = tipBg

    local tipPos
    if info._roleId == 1 or info._roleId == 2 then
        tipPos = cc.p(isLeft and (620 + lc.w(tipBg)) or (V.SCR_W - 450), 60)
    else
        tipPos = cc.p(isLeft and (lc.w(tipBg)) or (lc.w(container)), 360) 
    end
    lc.addChildToPos(container, tipBg, tipPos, 2)
    lc.addChildToPos(container, tip, cc.p(tipPos.x + (isLeft and -TIP_BG_FRAME_RIGHT - lc.w(tip) or -TIP_BG_FRAME_RIGHT), tipPos.y + TIP_BG_FRAME_BOTTOM + (next and lc.h(next) + 10 or 0)), 2)

    if next then
        lc.addChildToPos(container, next, cc.p(lc.right(tip) - lc.w(next) / 2, lc.bottom(tip) - 10 - lc.h(next) / 2))
    end

    lc.offset(npc, 0, -200)
    npc:runAction(lc.spawn(lc.ease(lc.moveBy(0.4, 0, 200), "BackO"), lc.sequence(0.1,
        function()
            -- play audio
            local audioId = AUDIO[string.format(isInBattle and "E_STORY_%d" or "E_GUIDE_%d", infoId)]
            if audioId then
                lc.Audio.playAudio(audioId)
            end

            tipBg:runAction(lc.sequence({lc.fadeIn(0.2), lc.ease(lc.scaleTo(0.4, 1), "BackO")}, 
                function()
                    tip:runAction(lc.sequence(lc.fadeIn(0.1), 0.5, 
                        function() 
                            layer._canClose = true
                            if layer._next then layer._next:runAction(lc.rep(lc.sequence(lc.fadeIn(0.5), 0.5, lc.fadeOut(0.5)))) end
                            if layer._canCloseHandler then layer._canCloseHandler() end
                        end
                    ))
                end
            ))
        end
    )))

    return layer
end

function _M.closeNpcTipLayer()
    local layer = _M._tipLayer
    if layer then
        layer:setTouchEnabled(false)
        layer:setOpacity(0)

        _M.hideHighlightObjs(layer)
        if layer._canCloseHandler then layer._canCloseHandler() end

        layer._tipBg:stopAllActions()
        layer._tipBg:runAction(lc.fadeOut(0.1))

        layer._tip:stopAllActions()
        layer._tip:runAction(lc.fadeOut(0.1))

        if layer._next then
            layer._next:stopAllActions()
            layer._next:runAction(lc.fadeOut(0.1))
        end

        layer._npc:stopAllActions()
        layer._npc:runAction(lc.sequence(lc.ease(lc.moveBy(0.5, 0, -600), "BackO"), 
            function()
                _M.removeHighlightObjs(layer)
                _M.removeContainerLayer(layer)
            end
        ))

        _M._tipLayer = nil
    end
end

function _M.showOperateLayer(isSeek)
    _M.releaseLayer()

    local layer = V.createTouchLayer()
    lc._runningScene._scene:addChild(layer, ClientData.ZOrder.guide)
    
    _M._layer = layer
    _M._layer:retain()

    if isSeek then
        local eventCustom = cc.EventCustom:new(_M.Event.seek)
        lc.Dispatcher:dispatchEvent(eventCustom)
    end
end

function _M.setOperateLayer(node, dstPos, linkNodes)
    local layer = _M._layer
    if layer == nil then return end

    if node.setPropagateTouchEvents then
        node:setPropagateTouchEvents(false)
    end

    layer._touchHandler = function(evt, gx, gy)
        if layer._ignoreTouch then return 0 end
        if layer._blockTouch then return 1 end

        local gPos = cc.p(gx, gy)
        if V.containPos(node, gPos) then
            return 0
        end

        if linkNodes then
            for _, linkNode in ipairs(linkNodes) do
                if lc.contain(linkNode, gPos) then
                    return 0
                end
            end
        end

        return 1
    end

    local fingerPos = lc._runningScene:convertToNodeSpace(node:convertToWorldSpace(cc.p(lc.w(node) / 2, lc.h(node) / 2)))
    local finger = _M.createFinger(node ~= _M.lastOperateNode, fingerPos, dstPos)
    _M.addContainerLayer(finger)

    _M.lastOperateNode = node
end

function _M.hideHighlightObjs(owner)
    if owner._highlightObjs then
        for _, obj in ipairs(owner._highlightObjs) do
            obj:setVisible(false)
        end
    end
end

function _M.removeHighlightObjs(owner)
    if owner._highlightObjs then
        for _, obj in ipairs(owner._highlightObjs) do
            obj:removeFromParent()
        end
        owner._highlightObjs = nil
    end
end

function _M.getCurStepName()
    local info = Data._guideInfo[P._guideID]
    if info == nil then return "" end
    
    return info._stepName    
end

function _M.getCurStepId()
    local info = Data._guideInfo[P._guideID]
    if info == nil then return -1 end
    
    return info._id
end

function _M.getNextStepName()
    local info = Data._guideInfo[P._guideID]
    if info._saveStep % _M.GUIDE_ID_GROUP_SIZE == 0 and math.floor(info._saveStep / _M.GUIDE_ID_GROUP_SIZE) == math.floor(P._guideID / _M.GUIDE_ID_GROUP_SIZE) then 
        return "" 
    end

    local guideId = P._guideID + 1    
    info = Data._guideInfo[guideId]
    if info == nil then
        local group = _M.getGroup()
        guideId = (group + 1) * _M.GUIDE_ID_GROUP_SIZE + 1
        info = Data._guideInfo[guideId]         
        if info == nil then return "" end
    end
    
    return info._stepName
end

function _M.createFinger(isFromCenter, srcPos, dstPos, posFunc)
    local scene = lc._runningScene

    -- Release previous finger if exist
    _M.releaseFinger()

    -- Create finger sprite
    local finger = cc.Sprite:createWithSpriteFrameName("img_finger_01")
    finger:setCascadeOpacityEnabled(false)
    finger:setOpacity(0)
    finger:setAnchorPoint(0, 1.0)
    finger:setPosition(srcPos)
    finger._srcPos = srcPos
    _M._finger = finger
    _M._finger:retain()
    
    if lc.right(finger) > lc.w(scene) then
        finger:setFlippedX(true)
        finger:setAnchorPoint(1.0, 1.0)
    end

    -- Create circles
    local createCircle = function()
        local circle = cc.Sprite:createWithSpriteFrameName("img_circle")
        circle:setOpacity(0)
        circle:setScale(0.5)
        circle:setPosition(finger:isFlippedX() and lc.w(finger) - 5 or 5, lc.h(finger) - 5)
        return circle
    end

    local circle1 = createCircle()
    local circle2 = createCircle()
    finger:addChild(circle1, -1)
    finger:addChild(circle2, -1)
    
    local runCircleAction = function()
        local action = lc.sequence(0.1, lc.fadeIn(0.1), lc.scaleTo(0.4, 3.0), lc.fadeOut(0.1), lc.scaleTo(0, 0.5))
        circle1:runAction(action)
        circle2:runAction(lc.sequence(0.16, action:clone()))
    end

    local appearAction
    if isFromCenter then
        finger:setPosition(lc.w(lc._runningScene) / 2, lc.h(lc._runningScene) / 2)
        finger:setOpacity(255)
        
        circle1:setScale(5.0)
        circle2:setScale(5.0)
        local action = lc.sequence(lc.fadeIn(0.05), lc.scaleTo(0.3, 1.0), lc.fadeOut(0.05), lc.scaleTo(0, 0.5))
        circle1:runAction(action)
        circle2:runAction(lc.sequence(0.16, action:clone()))

        appearAction = lc.ease(lc.moveTo(0.4, srcPos.x, srcPos.y), "SineIO")
    else
        appearAction = lc.fadeIn(0.1)
    end
    
    finger:runAction(lc.sequence(appearAction, 
        function()       
            if dstPos then
                local distance = cc.pGetLength(cc.pSub(dstPos, srcPos))
                local speed = 300
                finger:runAction(lc.rep(lc.sequence(0.1, 
                    function()
                        finger:setScale(0.95 * (finger._baseScale or 1))
                        finger:setSpriteFrame("img_finger_02")
                        runCircleAction()
                    end, 0.4, lc.moveTo(distance / speed, dstPos), 
                    function()
                        if posFunc then srcPos = posFunc() end

                        finger:setPosition(srcPos)
                        finger:setScale(1 * (finger._baseScale or 1))
                        finger:setSpriteFrame("img_finger_01")
                    end
                )))    
            else
                finger:runAction(lc.rep(lc.sequence(0.1, 
                    function()
                        finger:setScale(0.95 * (finger._baseScale or 1))
                        finger:setSpriteFrame("img_finger_02")
                        runCircleAction()
                    end, 0.6, 
                    function()
                        if posFunc then
                            srcPos = posFunc()
                            finger:setPosition(srcPos)
                        end

                        finger:setScale(1 * (finger._baseScale or 1))
                        finger:setSpriteFrame("img_finger_01")
                    end
                )))
            end
        end
    ))

    return finger
end

function _M.showSoftGuideFinger(parent, times)
    local finger = _M.createFinger(false, cc.p(lc.w(parent) / 2, lc.h(parent) / 2))
    parent._softGuideFinger = finger
    parent:addChild(finger, 100)

    if times then
        finger:runAction(lc.sequence(0.7 * times, function() _M.releaseFinger() end))
    end
end

function _M.releaseLayer()
    if _M._layer then
        if _M._layer:getParent() then
            _M._layer:removeFromParent()
        end
        _M._layer:release()
        _M._layer = nil
    end
end

function _M.releaseFinger()
    local finger = _M._finger
    if finger then
        if finger:getParent() then
            _M.removeContainerLayer(finger)
        end
        finger:release()
        _M._finger = nil
    end  
end

function _M.getGuideIDByStepName(name)    
    for k, v in pairs(Data._guideInfo) do
        if v._stepName == name then
            return k
        end
    end
    
    return 0xffff
end

function _M.getCurDifficultyStepName()
    local info = Data._guideInfo[P._guideDifficultyID]
    if info == nil then return "" end
    
    return info._stepName    
end

function _M.getCurRecruiteStepName()
    local info = Data._guideInfo[P._guideRecruiteID]
    if info == nil then return "" end
    
    return info._stepName    
end

GuideManager = _M

return _M