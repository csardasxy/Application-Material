local _M = class("BattleDialog", function() return cc.Node:create() end)
BattleDialog = _M

_M.Type = 
    {
        -- main instance, in the middle of screen
        your_round = 1,
        oppo_round = 2,
        remain_round = 3,
        initial_deal = 4,
        inning = 5,

        -- attention, about using card error
        dialog_start = 100,
        defender_hand_cards = 101,
        not_enough_gem = 102,
        board_card_full = 103,
        not_your_round = 104,
        card_need_aim = 105,
        card_need_target = 106,
        special_summon_invalid = 107,
        adding_board_card = 108,
        cannot_effect = 109,
        trap_existed = 110,
        target_unattackable = 111,
        cannot_attack = 112,
        attacker_hand_cards = 114,
        dialog_end = 200,

        -- help labels
        tip_start = 200,
        your_card_pile = 201,
        oppo_card_pile = 202,
        your_gem = 203,
        oppo_gem = 204,
        your_grave = 205,
        oppo_grave = 206,
        round_info = 207,
        tip_start = 300,

        -- chat dialog
        chat_dialog = 31,
        oppo_chat_dialog = 32,

        -- fortress skill
        fortress_skill = 41,

        -- exchage
        exchange = 51,

    }

function _M.create(battleUi, type, val)
    local node = _M.new()
    node:init(battleUi, type, val)
    return node
end

-----------------------------------------
-- init
-----------------------------------------
function _M:init(battleUi, type, val)
    self._battleUi = battleUi

    local centerPos = cc.p(V.SCR_CW, V.SCR_CH)

    if type == _M.Type.your_round or 
        type == _M.Type.oppo_round or 
        type == _M.Type.remain_round or
        type == _M.Type.initial_deal or
        type == _M.Type.inning then
        
        local par = Particle.create("par_round_explode")
        par:setPosition(centerPos.x, centerPos.y + 60)
        self:addChild(par, -2)

        local effectName = ""
        if type == _M.Type.your_round then effectName = 'wofang'
        elseif type == _M.Type.oppo_round then effectName = 'difang'
        elseif type == _M.Type.remain_round then effectName = 'shengyu'..val
        elseif type == _M.Type.initial_deal then effectName = 'chushi'
        elseif type == _M.Type.inning then effectName = 'dijiju'..val end

        local spine = V.createSpine('huihe')
        spine:setAnimation(0, effectName, false)
        spine:setAutoRemoveAnimation()
        lc.addChildToPos(self, spine, cc.p(centerPos.x, centerPos.y + 50), BattleScene.ZOrder.dialog + 1)
        
        self._battleUi._audioEngine:playEffect("e_round")
      
    elseif type > _M.Type.dialog_start and type < _M.Type.dialog_end then
        
        local str = ""
        local pos = cc.p(V.SCR_CW + 180, V.SCR_CH - 100)

        if type == _M.Type.defender_hand_cards then 
            str = string.format(Str(STR.BATTLE_DIALOG_HAND_CARDS), #self._battleUi._opponentUi._pHandCards)
            pos.y = V.SCR_CH + (battleUi._isReverse and -150 or 340)
        elseif type == _M.Type.attacker_hand_cards then 
            str = string.format(Str(STR.BATTLE_DIALOG_HAND_CARDS), #self._battleUi._opponentUi._pHandCards)
            pos.y = V.SCR_CH + (battleUi._isReverse and 340 or -150)
        elseif type == _M.Type.not_enough_gem then 
            str = Str(STR.BATTLE_DIALOG_NOT_ENOUGH_GEM)
        elseif type == _M.Type.board_card_full then 
            str = string.format(Str(STR.BATTLE_DIALOG_BOARD_FULL), Data.MAX_CARD_COUNT_ON_BOARD)
        elseif type == _M.Type.adding_board_card then
             str = Str(STR.BATTLE_DIALOG_ADDING_CARD)
        elseif type == _M.Type.card_need_aim then 
            str = Str(val == 0 and STR.BATTLE_DIALOG_CARD_NEED_AIM or STR.BATTLE_DIALOG_CARD_NEED_JCTQ_TARGET)
        elseif type == _M.Type.card_need_target then 
            str = Str(STR.BATTLE_DIALOG_CARD_NEED_TARGET)
        elseif type == _M.Type.special_summon_invalid then 
            str = Str(STR.BATTLE_DIALOG_SPECIAL_SUMMON_INVALID)
        elseif type == _M.Type.not_your_round then 
            str = Str(STR.BATTLE_DIALOG_NOT_YOUR_ROUND)
        elseif type == _M.Type.cannot_effect then 
            str = string.format(Str(STR.BATTLE_DIALOG_CANNOT_EFFECT), ClientData.getStrByCardType(val))
        elseif type == _M.Type.trap_existed then 
            str = Str(STR.BATTLE_DIALOG_TRAP_EXISTED)
        elseif type == _M.Type.target_unattackable then 
            str = Str(STR.BATTLE_DIALOG_TARGET_UNATTACKABLE)
        elseif type == _M.Type.cannot_attack then 
            str = Str(STR.BATTLE_DIALOG_CANNOT_ATTACK)
        end

        local pSpr9 = ccui.Scale9Sprite:createWithSpriteFrameName("bat_dlg_bg2", cc.rect(42, 26, 1, 1))
        pSpr9:setContentSize(cc.size(string.len(str) / 3 * 24 + 70, 60))
        pSpr9:setPosition(pos)
        pSpr9:setCascadeOpacityEnabled(true)
        self:addChild(pSpr9)
        
        local text = cc.Label:createWithTTF(str, V.TTF_FONT, V.FontSize.S1)
        text:setColor(lc.Color3B.black)
        text:setAnchorPoint(0, 0.5)
        text:setPosition(50, 30)
        pSpr9:addChild(text)
        pSpr9:setContentSize(cc.size(text:getContentSize().width + 70, 60))
        
        pSpr9:runAction(cc.Sequence:create(
            cc.ScaleTo:create(lc.absTime(0.1), 1.2),
            cc.ScaleTo:create(lc.absTime(0.1), 1.0),
            cc.DelayTime:create(lc.absTime(1.5)),
            cc.FadeOut:create(lc.absTime(1.0)),
            cc.CallFunc:create(function () self:hide() end)
        ))

        self._battleUi._audioEngine:playEffect("e_dialog")

    elseif type > _M.Type.tip_start and type < _M.Type.tip_end then
        
        local str = ""; local pos = cc.p(centerPos.x, centerPos.y)
        if type == _M.Type.your_card_pile then str = string.format(Str(STR.BATTLE_DIALOG_CARD_PILE), self._battleUi._atkPile._label:getString()); pos = cc.p(V.SCR_W - 280, 60)
        elseif type == _M.Type.oppo_card_pile then str = string.format(Str(STR.BATTLE_DIALOG_CARD_PILE), self._battleUi._defPile._label:getString()); pos = cc.p(V.SCR_W - 280, V.SCR_H - 60)
        elseif type == _M.Type.round_info then str = string.format(Str(STR.BATTLE_DIALOG_ROUND), self._battleUi._pRoundLabel:getString()); pos = cc.p(pos.x + 320, pos.y + 60)
        elseif type == _M.Type.your_gem then str = string.format(Str(STR.BATTLE_DIALOG_GEM), self._battleUi._player._gem or 0); pos = cc.p(pos.x + 290, pos.y + (battleUi._isReverse and 250 or -100))
        elseif type == _M.Type.oppo_gem then str = string.format(Str(STR.BATTLE_DIALOG_GEM), self._battleUi._opponent._gem or 0); pos = cc.p(pos.x + 290, pos.y + (battleUi._isReverse and -100 or 250))
        elseif type == _M.Type.your_grave then str = string.format(Str(STR.BATTLE_DIALOG_GRAVE), self._battleUi._atkGraveLabel:getString()); pos = cc.p(pos.x - 330, pos.y + (battleUi._isReverse and 240 or -100))
        elseif type == _M.Type.oppo_grave then str = string.format(Str(STR.BATTLE_DIALOG_GRAVE), self._battleUi._defGraveLabel:getString()); pos = cc.p(pos.x - 330, pos.y + (battleUi._isReverse and -100 or 240))
        end

        local pSpr9 = ccui.Scale9Sprite:createWithSpriteFrameName("bat_dlg_bg3", cc.rect(26, 22, 1, 1))
        pSpr9:setPosition(pos)
        pSpr9:setCascadeOpacityEnabled(true)
        self:addChild(pSpr9)

        local text = cc.Label:createWithTTF(str, V.TTF_FONT, V.FontSize.S1)
        --text:enableShadow(lc.Color4B.black)
        text:setAnchorPoint(0, 0.5)
        text:setPosition(25, 30)
        pSpr9:addChild(text)
        pSpr9:setContentSize(cc.size(text:getContentSize().width + 50, 60))
        pSpr9:runAction(cc.Sequence:create(
            cc.ScaleTo:create(lc.absTime(0.1), 1.2),
            cc.ScaleTo:create(lc.absTime(0.1), 1.0),
            cc.DelayTime:create(lc.absTime(1.5)),
            cc.FadeOut:create(lc.absTime(1.0)),
            cc.CallFunc:create(function () self:hide() end)
        ))

    elseif type == _M.Type.chat_dialog or type == _M.Type.oppo_chat_dialog then

        local isOppo = type == _M.Type.oppo_chat_dialog

        local node = cc.Node:create()
        if battleUi._isReverse then
            lc.addChildToPos(self, node, cc.p(not isOppo and V.SCR_W - 150 or 150, V.SCR_CH + (not isOppo and 200 or -200)))
        else
            lc.addChildToPos(self, node, cc.p(isOppo and V.SCR_W - 150 or 150, V.SCR_CH + (isOppo and 200 or -200)))
        end

        local label = V.createTTF(val, V.FontSize.M1, V.COLOR_TEXT_DARK)
        lc.addChildToCenter(node, label) 
           
        local bg = ccui.Scale9Sprite:createWithSpriteFrameName("img_tip_bg", V.CRECT_TIP_BG)
        bg:setContentSize(cc.size(math.max(250, lc.w(label) + 100), 130))
        if not battleUi._isReverse then
            bg:setFlippedY(isOppo)
            bg:setFlippedX(not isOppo)
            lc.addChildToPos(node, bg, cc.p(0, isOppo and 15 or -20), -1)
        else
            bg:setFlippedY(not isOppo)
            bg:setFlippedX(isOppo)
            lc.addChildToPos(node, bg, cc.p(0, not isOppo and 15 or -20), -1)
        end
        
        node:setScale(0.2)
        node:runAction(lc.sequence(
            lc.ease(lc.scaleTo(lc.absTime(0.4), 1.0), 'BackO'),
            lc.delay(lc.absTime(2.0)),
            lc.scaleTo(lc.absTime(0.3), 0),
            lc.remove()
        ))

    elseif type == _M.Type.fortress_skill then
        if val._player._fortressSkill then
            if not battleUi._isReverse then
                self:addSkillItem(val._player, val._player._fortressSkill, cc.p(centerPos.x + 240, val._isController and (centerPos.y - 36) or (centerPos.y + 180)))
            else
                self:addSkillItem(val._player, val._player._fortressSkill, cc.p(centerPos.x + 240, not val._isController and (centerPos.y - 36) or (centerPos.y + 180)))
            end
        end

    elseif type == _M.Type.exchange then
        local str = Str(STR.BATTLE_DIALOG_EXCHANGE_TIP)
        local pos = cc.p(V.SCR_CW, V.SCR_CH - 100)

        local pSpr9 = ccui.Scale9Sprite:createWithSpriteFrameName("bat_dlg_bg2", cc.rect(42, 26, 1, 1))
        pSpr9:setContentSize(cc.size(string.len(str) / 3 * 24 + 70, 60))
        pSpr9:setPosition(pos)
        pSpr9:setCascadeOpacityEnabled(true)
        self:addChild(pSpr9)
        
        local text = cc.Label:createWithTTF(str, V.TTF_FONT, V.FontSize.S1)
        text:setColor(lc.Color3B.black)
        text:setAnchorPoint(0, 0.5)
        text:setPosition(50, 30)
        pSpr9:addChild(text)
        pSpr9:setContentSize(cc.size(text:getContentSize().width + 70, 60))
        
        pSpr9:runAction(cc.Sequence:create(
            cc.ScaleTo:create(lc.absTime(0.1), 1.2),
            cc.ScaleTo:create(lc.absTime(0.1), 1.0))
        )

    end
end

function _M:hide()
    self:removeFromParent()
end

function _M:addSkillItem(player, skill, pos)
    local item = V.createBattleSkillItem(player, skill, pos)
    self:addChild(item)

    -- skill from
    local fromSpr = cc.Sprite:createWithSpriteFrameName("card_dl_from_5")
    lc.addChildToPos(item, fromSpr, cc.p(lc.w(item) - lc.w(fromSpr) / 2 - 16, lc.h(item) - lc.h(fromSpr) / 2 - 16))

    item:runAction(cc.Sequence:create(
            cc.ScaleTo:create(lc.absTime(0.1), 1.2),
            cc.ScaleTo:create(lc.absTime(0.1), 1.0),
            cc.DelayTime:create(lc.absTime(2)),
            cc.FadeOut:create(lc.absTime(1.0)),
            cc.CallFunc:create(function () self:hide() end)
        ))
end

return _M