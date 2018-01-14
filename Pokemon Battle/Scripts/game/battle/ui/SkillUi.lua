local _M = PlayerUi

local COIN_ANIMATION_TIME = 3.0

function _M:castSkillAction(pCard, type, skill, mode)
    local id = skill._id
    local info = Data._skillInfo[id]
    local time = {0.4, 0.4}

    if pCard == nil then return time[1], time[2] end

    local skillType = math.floor(id / Data.INFO_ID_GROUP_SIZE)
    local card = pCard._card
    local targets = {}
    local actionCard = self._player:getActionCard()
    
    if type == BattleData.Status.after_spell or type == BattleData.Status.after_attack then
        targets = self._player:getUnderChangedCards()
    else
        targets = self._player:getUnderSkillCards(card._id, id)
    end

    self._battleUi:hideCardAttack()
    self:updateBoardCardsActive()

    ---------------------- show skill label -------------------------------
    if type == BattleData.Status.spelling then
        self:efcSkillShow(pCard)
    elseif type == BattleData.Status.under_spell or 
        type == BattleData.Status.under_defend_spell or 
        type == BattleData.Status.under_spell_damage or 
        type == BattleData.Status.under_counter_spell or 
        type == BattleData.Status.under_attack or 
        type == BattleData.Status.under_defend_attack or
        type == BattleData.Status.under_attack_damage or 
        type == BattleData.Status.under_counter_attack or
        type == BattleData.Status.ac_under_attack_damage or 
        type == BattleData.Status.after_spell or
        type == BattleData.Status.after_attack then
        --self:efcCardSkill(pCard, skillId)
        self:efcSkillShow(pCard)
    end
    
    ----------------------- skills action ----------------------------
    ---------------- attack skills -----------------

    if id == 1102 or id == 1111 then
        local count = card:getBuffValue(true, BattleData.PositiveType.powerMark)
        if count > 0 then
            time = self:throwCoinEffect(card, count)
        end

    elseif info._coinCount >= 1 then
        time = self:throwCoinEffect(card, info._coinCount)

    


    --[[
    if skillId == 1001 then
        for i = 1, #targets do
            local targetCard = self:getCardSprite(targets[i]) or self._opponentUi:getCardSprite(targets[i])
            if targetCard ~= nil then
                self:efcDragonBones3("jdgj", "effect", 2.0, true, targetCard, false, cc.p(0, 20))
            end
        end

    
    elseif skillId == 2002 or skillId == 2006 then
        self:efcDragonBones3("wlfy", "effect", 2.4, true, pCard, false, cc.p(0, -10))

    elseif skillId == 3002 or skillId == 3003 or skillId == 3016 or skillId == 3129 then
        for i = 1, #targets do
            local targetCard = self:getCardSprite(targets[i]) or self._opponentUi:getCardSprite(targets[i])
            if targetCard ~= nil then 
                self:efcDragonBones3("tsgf", "effect", 1.0, true, targetCard, false, cc.p(0, 80))
            end
        end

    elseif skillId == 3004 or skillId == 3027 then
        for i = 1, #targets do
            local targetCard =self:getCardSprite(targets[i]) or self._opponentUi:getCardSprite(targets[i])
            if targetCard ~= nil then 
                self:efcDragonBones3("jdgj", "effect", 2.0, true, targetCard, false, cc.p(0, 0))
            end
        end

    elseif skillId == 3007 or skillId == 4058 or skillId == 4068 or skillId == 7063 then
        self:updateCardsActive()
    
    elseif skillId == 3015 then
        local startPos = self._battleUi._layer:convertToNodeSpace(pCard:convertToWorldSpace(cc.p(0, 0)))
        local endPos = cc.p(self._avatarFrame:getPosition())
        endPos = cc.p(endPos.x + (self._isController and 50 or -50), endPos.y + (self._isController and 50 or -50))
        
        local len, rot = self:calLengthAndAngle(startPos, endPos)
        rot = 270 - rot

        local node = cc.Node:create()
        lc.addChildToPos(self._battleUi._layer, node, startPos, 4)
        node:setRotation(rot)

        local par = Particle.create("par_liziqiu")
        lc.addChildToCenter(node, par)

        node:runAction(lc.sequence(
            lc.delay(0.6),
            lc.moveTo(0.8, endPos),
            function () 
                node:removeFromParent() 

                local par = Particle.create("par_liziqiu_jz")
                lc.addChildToPos(self._battleUi._layer, par, endPos, 4)
            end))

        time = {1.4, 0.6}

    elseif skillId == 3036 then
        local delay = 0
        for i = 1, #targets do
            local targetCard = self:getCardSprite(targets[i]) or self._opponentUi:getCardSprite(targets[i])
            if targetCard ~= nil and targets[i]._owner ~= card._owner then
                local startPos = cc.p(pCard:getPosition())
                local endPos = cc.p(targetCard:getPosition())
                endPos = cc.p(endPos.x, endPos.y > startPos.y and (endPos.y - 30) or (endPos.y + 20))
                local len, angle = self:calLengthAndAngle(startPos, endPos)
                local rot = 90 - angle
                delay = math.sqrt(len) / 90
                
                local bones = self:efcDragonBones(pCard, "gqbb", cc.p(0, -10), true, false, "atk", 2.6)
                bones:setRotation(rot)
                
                local spr = self:efcCamera3DSprite("efc_gqbb", startPos, rot, false)
                spr:runAction(lc.sequence(0.7, lc.show(), lc.moveTo(delay, endPos), lc.remove()))
                self._battleUi:runAction(lc.sequence(0.7 + delay - 0.1, 
                    function ()
                        local bones = self:efcDragonBones(nil, "gqbb", cc.p(endPos.x, endPos.y - 10), true, false, "def", 2.6)
                        bones:setRotation(rot)
                    end
                ))
            end
        end
        time = {delay + 0.7, 0.7}

    elseif skillId == 3136 or skillId == 3138 then
        if ClientData.isYYB() then
            local bones = self:efcDragonBones2("shendeng", "effect1", 1.0, true)
            lc.addChildToCenter(self._battleUi:getParent(), bones, BattleUi.ZOrder.effect)
        else
            local par = Particle.create("xuwang1")
            lc.addChildToCenter(self._battleUi._layer, par, CardSprite.ZOrder.efc)
            local par = Particle.create("xuwang2")
            lc.addChildToCenter(self._battleUi._layer, par, CardSprite.ZOrder.efc)
        end

    elseif skillId == 4004 then
        local targetSprite = self:getCardSprite(card._magicTarget)
        if targetSprite then
            local startPos = cc.p(targetSprite:getPosition())
            local endPos = cc.p(V.SCR_CW, self._isController and _M.Pos.defender_board_y[1] or _M.Pos.attacker_board_y[1])

            local bullet = lc.createSprite("efc_cmdlbz")
            lc.addChildToPos(self._battleUi, bullet, startPos, BattleUi.ZOrder.effect)

            self:efcDragonBones(nil, "cmdlbz", startPos, true, false, "effect01", 5)

            bullet:setVisible(false)
            bullet:runAction(lc.sequence(
                lc.delay(0.8),
                lc.show(),
                lc.moveTo(0.2, endPos),
                lc.call(function () 
                    self:efcDragonBones(nil, "cmdlbz", endPos, true, false, "effect02", 5)
                end),
                lc.remove()
                ))
        end

        time = {1.2, 0.6}

    elseif skillId == 4043 then
        local bones = self:efcDragonBones2("qbd", "effect", 1.0, true)
        lc.addChildToCenter(self._battleUi, bones)
        bones:setRotation(self._isController and 0 or 180)

    elseif skillId == 4048 then
        local node = cc.Node:create()
        lc.addChildToCenter(self._battleUi, node, BattleUi.ZOrder.effect)
        node:runAction(lc.sequence(lc.delay(3.0), lc.remove()))
        node:setScale(3.0)

        local par = Particle.create("par_ronghe01")
        lc.addChildToCenter(node, par)

        local par = Particle.create("par_ronghe02")
        lc.addChildToCenter(self._battleUi, par, BattleUi.ZOrder.effect)

        local par = Particle.create("par_ronghe03")
        lc.addChildToCenter(self._battleUi, par, BattleUi.ZOrder.effect)

        time = {0.2, 0}

    elseif skillId == 3077 or skillId == 3193 or skillId == 3194 or skillId == 4066 or skillId == 4121 or skillId == 5080 then
        local ani1, ani2 = "effect", ''..card._lastCount
        local bones = self:efcDragonBones(nil, "yaosaizi", cc.p(V.SCR_CW, lc.h(self._battleUi) / 2), false, false, ani1, 1.0)
        local duration1 = bones:getAnimationDuration(ani1)
        local duration2 = bones:getAnimationDuration(ani2)
        bones:runAction(lc.sequence(duration1, function() bones:gotoAndPlay(ani2) end, duration2, lc.remove()))
        time = {duration1 + duration2, 0} 
        
    elseif skillId == 3201 then
        

    elseif skillId == 3103 then
        for i = 1, #targets do
            local targetCard = self:getCardSprite(targets[i]) or self._opponentUi:getCardSprite(targets[i])
            if targetCard ~= nil then 
                self:efcDragonBones3("tsgj", "effect", 2.4, true, targetCard, false, cc.p(0, 20))
            end
        end

    elseif skillId == 3042 or skillId == 4003 then
        local startPos
        if skillId == 3042 then 
            startPos = self._opponentUi._avatarFrame:convertToNodeSpace(pCard:getParent():convertToWorldSpace(cc.p(pCard:getPosition())))
        else
            startPos = self._opponentUi._avatarFrame:convertToNodeSpace(self._avatarFrame:convertToWorldSpace(self._avatarFrame._avatarPos))
        end
        local endPos = cc.p(lc.w(self._opponentUi._avatarFrame) / 2, lc.h(self._opponentUi._avatarFrame) / 2)
        
        local len, rot = self:calLengthAndAngle(startPos, endPos)
        rot = 270 - rot

        local node = cc.Node:create()
        lc.addChildToPos(self._opponentUi._avatarFrame, node, startPos, 4)
        node:setRotation(rot)

        local par = Particle.create("par_huoqiu")
        lc.addChildToCenter(node, par)

        node:runAction(lc.sequence(
            lc.delay(0.6),
            lc.moveTo(1.0, endPos),
            function () 
                node:removeFromParent() 

                local par = Particle.create("par_huoqiu_jz")
                lc.addChildToPos(self._opponentUi._avatarFrame, par, endPos, 4)

                self._audioEngine:playEffect("e_fireball_hit")
            end))

        time = {1.6, 0.6}

    elseif skillId == 4064 then
        self:updateBoardCardsActive()
        
    elseif skillId == 11011 or skillId == 12011 then
        self:playAction(pCard, _M.Action.avoid_attack, 0)
    ]]

    end
    
    -- play audio
    self._audioEngine:playSkillAudio(skillId, pCard._card, time[1])
    
    return time[1], time[2]
end

function _M:efcCyclone(targetCard, delay)
    targetCard:runAction(lc.sequence(delay or 0,
        function()
            self:efcDragonBones(targetCard, "jufeng2", cc.p(-30, 0), true, false, "single", 2.4)            
        end, 0.4,
        lc.moveBy(0.04, 10, 0), lc.moveBy(0.06, -10, 10), lc.moveBy(0.08, 20, -20),
        lc.moveBy(0.08, -20, 20), lc.moveBy(0.06, 10, -10), lc.moveBy(0.04, -10, 0)
    ))
end

function _M:efcFortressDieRemove()
    if self._finishEfcLayer ~= nil then
        self._finishEfcLayer:removeFromParent()
        self._finishEfcLayer = nil
    end
end

function _M:efcFortressDie()
    if self._player._opponent._winBy3190 then
        local bones = DragonBones.create('aikezuodiya')
        lc.addChildToCenter(self._scene, bones, BattleUi.ZOrder.effect)
        lc.offset(bones, 0, 16)
        local time1 = bones:getAnimationDuration("effect1")
        local time2 = bones:getAnimationDuration("effect2")
        local time3 = bones:getAnimationDuration("effect3")
        bones:gotoAndPlay("effect1")
        bones:runAction(lc.sequence(time1, function() bones:gotoAndPlay("effect2") end, time2, function() bones:gotoAndPlay("effect3") end, time3, lc.remove()))
    end

    local pos = cc.p(V.SCR_CW,  V.SCR_CH + (self._isController and -150 or 150))

    local spine = V.createSpine('ds')
    lc.addChildToPos(self._battleUi, spine, pos, BattleUi.ZOrder.effect, BattleUi.Tag.remove_when_reset)
    --spine:setRotation3D({x = V.BATTLE_ROTATION_X, y = 0, z = 0})
    
    spine:setAnimation(0, 'animation', false)
    if self._isController then
        --spine:setRotation(180)
    end

    self._finishEfcLayer = bones

    self._scene:seenByCamera3D(spine)
    self:sendEvent(_M.EventType.efc_screen_fortress_die)
    
    -- audio
    self._audioEngine:playEffect("e_fortress_explode")
end

function _M:efcCardDie(cardSprite)
    local card = cardSprite._card
    
    if card:isMonster() then
        local pos = cardSprite._default._position
        local str, ani = "kapaisiwang", "effect_monster"
        if card._type == Data.CardType.trap then
            ani = "effect_trap"
        end
        
        cardSprite:runAction(cc.Sequence:create(
            cc.MoveBy:create(0.03, cc.p(0, 5)),
            cc.MoveBy:create(0.03, cc.p(5, -10)),
            cc.MoveBy:create(0.06, cc.p(-10, 10)),
            cc.MoveBy:create(0.03, cc.p(10, 0)),
            cc.MoveBy:create(0.03, cc.p(-5, -5)),
            cc.CallFunc:create(function ()
                                    cardSprite:removeAllStatus()
                                    cardSprite:setOpacity(0)
                                    
                                    self:efcDragonBones(cardSprite, str, cc.p(0, 0), true, false, ani, CardSprite.Scale.normal * 4.0)
                                    self:efcParticle("par_kapaisiwang_1", pos, false, true)
                                    self:efcParticle("par_kapaisiwang_2", pos, false, true)
                                    self._audioEngine:playEffect("e_card_die")
                                end)
        ))
        
        -- audio
        self._audioEngine:playHeroAudio(card._infoId, true)

    elseif card._type == Data.CardType.magic or card._type == Data.CardType.trap then
        local pos = cardSprite._default._position
        local str, ani = "kapaisiwang", "effect_trap"
        self:efcDragonBones(cardSprite, str, cc.p(0, 0), true, false, ani, 2.0)
        self:efcParticle("par_kapaisiwang_1", pos, false, true)
        self:efcParticle("par_kapaisiwang_2", pos, false, true)
        
    end
end

function _M:efcCardEmpty(cardSprite)
    self:efcDragonBones(cardSprite, "kapaisiwang", cc.p(0, 0), true, false, "effect_monster", CardSprite.Scale.normal * 2.0)
    self._audioEngine:playEffect("e_card_leave")
end

function _M:efcCardLeave(cardSprite)
    self:efcDragonBones(cardSprite, "kapaisiwang", cc.p(0, 0), true, false, "effect_monster", CardSprite.Scale.normal * 2.0)
    self._audioEngine:playEffect("e_card_die")
end

function _M:efcNormalCardDie(cardSprite, toGrave)
    self:efcDragonBones(cardSprite, "spsw", cc.p(0, 0), true, false, "effect", CardSprite.Scale.normal * 2.0)
    self._audioEngine:playEffect(toGrave and "e_card_die" or "e_card_board")
end

function _M:efcCardFlip(cardSprite)
    local card = cardSprite._card
    
    if card._type == Data.CardType.trap then
        local scale = cardSprite:getScaleY()
        cardSprite:runAction(cc.Sequence:create(
            lc.scaleTo(0.2, 0, scale),
            lc.call(function() cardSprite:initShow() cardSprite:setRotation3D({x = 0, y = 0, z = 0}) end),
            lc.scaleTo(0.2, scale, scale)
        ))
    end
end

function _M:efcSkillShow(pCard, skillId, delayOffset)
    local card = pCard._card
    local centerPos = cc.p(V.SCR_CW - 480, V.SCR_CH + 150)

    local cardSprite = CardSprite.create(card, self._isController and self or self._opponentUi)
    lc.addChildToPos(self._battleUi, cardSprite, centerPos, BattleUi.ZOrder.skill_label)
    
    cardSprite:setScale(0)
    cardSprite:runAction(lc.sequence(
        lc.ease(lc.scaleTo(0.2, 0.5 / CardSprite.Scale.normal), "BackO"),
        lc.moveBy(0.5, cc.p(3, 5)),
        lc.moveBy(0.5, cc.p(-3, -5)),
        lc.scaleTo(0.2, 0),
        lc.remove()
    ))
    cardSprite._pShadowArea:runAction(lc.spawn(
        lc.moveTo(0.2, cc.p(-100, -50)),
        lc.scaleTo(0.2, 0.6)
        ))

    local layer = lc.createNode()
    lc.addChildToCenter(cardSprite._pFrame, layer, -1)
    layer:setScale(1.0)

    --local par = Particle.create("par_kprc04")
    --lc.addChildToCenter(layer, par, -1)
    self._battleUi:createDragonBones("szkp", cc.p(5, 8), layer, "effect1", false, 1.0)

    if card:isMonster() and pCard._status == CardSprite.Status.fight then
        local par = Particle.create("par_gwsf")
        par:setPositionType(cc.POSITION_TYPE_GROUPED)
        lc.addChildToPos(pCard._pEffectArea, par, cc.p(0, -70))
    end
    
    self._scene:seenByCamera3D(cardSprite)
end

function _M:efcCardSkill(cardSprite, skillId)
    local pos = cc.p(cardSprite:getPosition())
    local card = cardSprite._card
    local skillType = math.floor(skillId / Data.INFO_ID_GROUP_SIZE) 

    local str = "efc_glow_bottom"
    local glow = cc.Sprite:createWithSpriteFrameName(str)
    glow:setScale(1.1)
    glow:setPosition(-5, 0)
    cardSprite._pBottomEffectArea:addChild(glow)
    glow:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.9),
        cc.FadeOut:create(0.3),
        cc.CallFunc:create(function () glow:removeFromParent() end)
    ))
    self._scene:seenByCamera3D(glow)

    local layer = cc.Node:create()
    local index = cardSprite._card:getUnderSkillIndex(skillId)
    layer:setPosition(0, skillType ~= Data.SkillType.fortress and (-70 - index * 30) or 20)
    cardSprite._pEffectArea:setVisible(true)
    cardSprite._pEffectArea:setOpacity(255)
    cardSprite._pEffectArea:addChild(layer, CardSprite.ZOrder.skill_label)
    
    local label = cc.Label:createWithTTF(Str(Data._skillInfo[skillId]._nameSid), V.TTF_FONT, V.FontSize.M1)
    label:enableOutline(lc.Color4B.red, 1)
    layer:addChild(label)
    label:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.9), 
        cc.FadeOut:create(0.3),
        cc.CallFunc:create(function() layer:removeFromParent() end)))
        
    self._scene:seenByCamera3D(layer)
end

function _M:efcBossCardSkill(cardSprite, skillId)
    local pos = cc.p(cardSprite:getPosition())
    local layer = cc.Node:create()
    layer:setPosition(0, -20)
    cardSprite:addChild(layer, CardSprite.ZOrder.skill_label)

    local label = cc.Label:createWithTTF(Str(Data._skillInfo[skillId]._nameSid), V.TTF_FONT, V.FontSize.M1)
    label:enableOutline(lc.Color4B.red, 1)
    layer:addChild(label)
    label:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.9), 
        cc.FadeOut:create(0.3),
        cc.CallFunc:create(function() layer:removeFromParent() end)))
        
    self._scene:seenByCamera3D(layer)
end

function _M:efcFortressHurt(val)
    if self._player._fortressHp == 0 then val = 0 end

    local dePos = cc.p(V.SCR_CW, V.SCR_CH + (self._isController and -200 or 200))
    local centerPos = self._battleUi._layer:convertToNodeSpace(self._battleUi:convertToWorldSpace(dePos))
    local avatorPos = self._battleUi._layer:convertToNodeSpace(self._pHpLabel:convertToWorldSpace(cc.p(0, 0)))
    
    local label = cc.Label:createWithBMFont(V.BMFont.num_48, "-"..val)
    lc.addChildToPos(self._battleUi._layer, label, centerPos)
    label:setColor(lc.Color3B.red)
    label:setScale(1.4)

    label:runAction(lc.sequence(
        lc.spawn(lc.fadeIn(0.1), lc.scaleTo(0.1, 1.6)),
        lc.scaleTo(0.04, 1.0), lc.scaleTo(0.01, 1.2), 
        lc.delay(0.2), 
        lc.spawn(lc.moveTo(0.3, avatorPos), lc.rotateTo(0.3, 20)),
        lc.spawn(lc.fadeOut(0.2), lc.scaleTo(0.2, 1.5)),
        function() label:removeFromParent() end
        ))

    local bones = self:efcDragonBones(nil, val >= 2500 and "dalian01" or "dalian01", dePos, true, false, "effect", 1.33)
    bones:setRotation(self._isController and 0 or 180)

    local bones = self:efcDragonBones(nil, "dalian03", dePos, true, false, "effect", 1.33)
    bones:setRotation(self._isController and 0 or 180)
end

function _M:efcFortressHpLabel(val)
    local pos = self._isController and _M.Pos.attacker_fortress or _M.Pos.defender_fortress
    pos = self._battleUi._layer:convertToNodeSpace(self._battleUi:convertToWorldSpace(pos))

    local layer = cc.Node:create()
    lc.addChildToPos(self._battleUi._layer, layer, pos)
    
    local label = cc.Label:createWithBMFont(V.BMFont.num_48, (val > 0 and "+" or "").. val)
    layer:addChild(label)
    label:runAction(lc.sequence(
        lc.scaleTo(0.16, 0.9), lc.scaleTo(0.12, 1.2), lc.scaleTo(0.08, 1.0), lc.scaleTo(0.04, 1.1),
        lc.delay(0.4),
        lc.fadeOut(0.3), 
        lc.call(function() layer:removeFromParent() end)
        ))
end

function _M:efcFortressAtkLabel(val)
    local pos = _M.Pos.boss
    
    local layer = cc.Node:create()
    layer:setPosition(pos)
    self._battleUi:addChild(layer, BattleUi.ZOrder.label)
    
    local label = cc.Label:createWithBMFont(V.BMFont.huali_32, (val > 0 and "+" or "").. val)
    layer:addChild(label)
    label:runAction(cc.Sequence:create(
        cc.ScaleTo:create(0.16, 0.9), cc.ScaleTo:create(0.12, 1.2), cc.ScaleTo:create(0.08, 1.0), cc.ScaleTo:create(0.04, 1.1),
        cc.DelayTime:create(0.4),
        cc.FadeOut:create(0.3), cc.CallFunc:create(function() layer:removeFromParent() end)
        ))

    self._scene:seenByCamera3D(layer)
end

function _M:efcCardHurt(cardSprite, val)
    local player = self._player:getActionPlayer()
    local card = cardSprite._card
    
    local dir = self._isController and -1 or 1
    cardSprite:efcDragonBones("beiji", cc.p(0, 0), true, false, "effect", 1.2)
    
    local layer = cc.Node:create()
    lc.addChildToPos(self._battleUi, layer, cc.p(cardSprite:getPosition()), BattleUi.ZOrder.label)
    layer:setRotation3D({x = V.BATTLE_ROTATION_X, y = 0, z = 0})
    
    if val ~= nil and val > 0 then
        local label = cc.Label:createWithBMFont(V.BMFont.num_48, "-"..val)
        layer:addChild(label)
        label:runAction(cc.Sequence:create(
            cc.Spawn:create(cc.FadeIn:create(0.1), cc.ScaleTo:create(0.1, 1.6)),
            cc.ScaleTo:create(0.04, 0.8), cc.ScaleTo:create(0.01, 1), 
            cc.DelayTime:create(0.7),
            cc.Spawn:create(cc.FadeOut:create(0.2), cc.ScaleTo:create(0.2, 1.5)),
            cc.CallFunc:create(function() layer:removeFromParent() end)
            ))

        self._scene:seenByCamera3D(layer)
    end
end

function _M:efcCardHpLabel(cardSprite, val)
    local player = self._player:getActionPlayer()
    local pos = cc.p(0, -60)
    
    local layer = cc.Node:create()
    layer:setPosition(pos)
    cardSprite:addChild(layer, CardSprite.ZOrder.effect)
    
    local label = V.createTTFBold("HP"..(val > 0 and "+" or "").. val, V.FontSize.B1)
    label:enableOutline(lc.Color4B.black, 2)
    layer:addChild(label)
    label:runAction(lc.sequence(
        cc.ScaleTo:create(0.16, 1.8), cc.ScaleTo:create(0.12, 2.1), cc.ScaleTo:create(0.08, 1.9), cc.ScaleTo:create(0.04, 2),
        1.0,
        cc.Spawn:create(cc.MoveBy:create(0.5, cc.p(0, 15)), cc.Sequence:create(cc.DelayTime:create(0.3), cc.FadeOut:create(0.2))), 
        cc.CallFunc:create(function() layer:removeFromParent() end)
        ))

    self._scene:seenByCamera3D(layer)
end

function _M:efcCardAtkLabel(cardSprite, val)
    local player = self._player:getActionPlayer()
    local pos = cc.p(0, 0)
    
    local layer = cc.Node:create()
    layer:setPosition(pos)
    cardSprite._pEffectArea:addChild(layer, CardSprite.ZOrder.label)
    
    local label = cc.Label:createWithBMFont(V.BMFont.huali_26, "ATK"..(val > 0 and "+" or "").. val)
    layer:addChild(label)
    label:runAction(cc.Sequence:create(
        cc.ScaleTo:create(0.16, 0.8), cc.ScaleTo:create(0.12, 1.1), cc.ScaleTo:create(0.08, 0.9), cc.ScaleTo:create(0.04, 1),
        cc.DelayTime:create(0.4),
        cc.Spawn:create(cc.MoveBy:create(0.3, cc.p(0, 15)), cc.Sequence:create(cc.DelayTime:create(0.1), cc.FadeOut:create(0.2))), 
        cc.CallFunc:create(function() layer:removeFromParent() end)
        ))

    self._scene:seenByCamera3D(layer)
end

function _M:efcCamera3DSprite(str, pos, rot, visible)
    if visible == nil then visible = true end
    
    local spr = cc.Sprite:createWithSpriteFrameName(str)
    if pos then spr:setPosition(pos) end
    if rot then spr:setRotation(rot) end
    spr:setVisible(visible)
    self._battleUi:addChild(spr, BattleUi.ZOrder.effect)
    
    self._scene:seenByCamera3D(spr)
    return spr
end

function _M:efcParticle(str, posVal, isBottom, isGrouped, parent)
    local pos = cc.p(0, 0)
    if posVal ~= nil then pos = cc.p(pos.x + posVal.x, pos.y + posVal.y) end
    if isGrouped == nil then isGrouped = true end
    if parent == nil then parent = self._battleUi end
    local ZOrder = isBottom and -1 or BattleUi.ZOrder.effect
    
    local par = self._battleUi:createParticle(str, pos, parent, isGrouped, ZOrder)
    
    return par
end

function _M:efcDragonBones2(str, animation, scale, isRemovable)
    local bones = DragonBones.create(str)
    bones:setScale(scale)
    bones:gotoAndPlay(animation)
    if isRemovable then
        bones:runAction(lc.sequence(bones:getAnimationDuration(animation), lc.remove()))
    end
    return bones
end

function _M:efcDragonBones3(str, animation, scale, isRemovable, cardSprite, isBottom, offset)
    local bones = self:efcDragonBones2(str, animation, scale, isRemovable)
    lc.addChildToCenter(isBottom and cardSprite._pBottomEffectArea or cardSprite._pEffectArea, bones)
    lc.offset(bones, offset.x, offset.y)
    return bones
end

function _M:efcDragonBones(cardSprite, str, posVal, isRemovable, isBottom, animationName, scale)
    local pos = cc.p(0, 0)
    if cardSprite ~= nil then pos = cc.p(cardSprite:getPosition()) end
    if posVal ~= nil then pos = cc.p(pos.x + posVal.x, pos.y + posVal.y) end
    if animationName == nil then animationName = "effect" end
    if isRemovable == nil then isRemovable = true end
    if isBottom == nil then isBottom = false end
    if scale == nil then scale = 1 end
    
    local bones = self._battleUi:createDragonBones(str, pos, self._battleUi, animationName, isRemovable, scale, isBottom and -1 or BattleUi.ZOrder.effect)
    
    return bones
end

function _M:efcBossPositiveStatus(bossSprite, bossCard)
    if bossCard._positiveStatus[BattleData.PositiveType.shieldGold] then
        CardSprite.efcShieldBegin(bossSprite, "shieldAttack")
    else
        CardSprite.efcShieldEnd(bossSprite, "shieldAttack")
    end
end

function _M:efcFortressPositiveStatus(fortressSprite, bossCard)
    if bossCard:hasShieldInType(BattleData.PositiveType.shieldHp) then
        CardSprite.efcShieldBegin(fortressSprite, "shieldHp")
        local shield = fortressSprite._statusEfc["shieldHp"]
        shield:setCameraMask(1)
        shield:setPosition(fortressSprite._avatarPos)
        shield:setLocalZOrder(3)
    else
        CardSprite.efcShieldEnd(fortressSprite, "shieldHp")
    end
end

function _M:efcFortressNegativeStatus(fortressSprite, fortress)
    self:updateBoardLocks()
end

function _M:getLabelColor(curVal, maxVal)
    -- yellow -> white -> green
    if curVal == nil or maxVal == nil or curVal == maxVal then
        -- white
        return V.COLOR_TEXT_DARK
    
    elseif curVal > maxVal then
        -- green
        return cc.c3b(133, 235, 3)
        
    else
        -- red
        return V.COLOR_TEXT_RED
    end
end

function _M:efcIgnoreDefendAttack(pCard, atkTarget, initAngle)
    local startPos = cc.p(pCard:getPosition())

    targetCard = self:getBoardCardSprite(atkTarget) or self._opponentUi:getBoardCardSprite(atkTarget)
    local endPos = cc.p(targetCard:getPosition())
    
    local len, angle = self:calLengthAndAngle(startPos, endPos)
    local rot = initAngle - angle
        
    local bones = self:efcDragonBones(pCard, "wlws", cc.p(0, -10), true, false, "effect", 2.4)
    bones:setRotation(rot)
    bones:runAction(cc.MoveTo:create(0.1, endPos))
end

function _M:throwCoinEffect(card, count)
    for i = 1, count do
        if i == 1 then
            self._coin:setAnimation(0, band(card._lastCount, 2 ^ (i - 1)) == 0 and "f" or "z", false)
        else
            self._coin:runAction(lc.sequence(COIN_ANIMATION_TIME * (i - 1), function() 
                self._coin:setAnimation(0, band(card._lastCount, 2 ^ (i - 1)) == 0 and "f" or "z", false)
            end))
        end
    end
    return {COIN_ANIMATION_TIME * count, 0}
end
