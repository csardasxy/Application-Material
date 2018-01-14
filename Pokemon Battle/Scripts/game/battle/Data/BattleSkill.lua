local _M = PlayerBattle

-----------------------------------
-- skill
-----------------------------------

function _M:castSkill(fromCard, skill, mode)
    -- is skill frozen
    local skillType = Data.getSkillType(skill._id)
    local skillOwner = skill._owner or fromCard
    
    local fortressSkill = fromCard._owner._opponent._fortressSkill
    
    local actionCard = self:getActionCard()
    local cid = skillOwner._id
    local id = skill._id
    local info = Data._skillInfo[id]
    local val, val2, val3 = info._val[1], info._val[2], info._val[3]
    local opponent = self._opponent
    local atkTarget = opponent._boardCards[1]
    local monsterTarget = fromCard._monsterTarget
    local magicTarget = fromCard._magicTarget
    local trapTarget = fromCard._trapTarget
    local casted = false

    -- cal probability
    if info._decrease[1] ~= 0 then
        if mode ~= Data.SkillMode.halo then
            skill._castTimes = skill._castTimes + 1
        end
        local decrease = info._decrease[skill._castTimes]
        if decrease ~= nil and val < 100 then
            val = math.floor(val * decrease / 100)
        end
    end
    
    ------------- attack -------------
    if B.isDamageSkill(skill) then
        if atkTarget ~= nil then
            if val > 0 then
                self:decHp(atkTarget, val, false, cid, id, mode)
            end
            self:incNegativeStatus(atkTarget, info._refSkills, false, cid, id, mode)
            casted = true
        end

    elseif id == 1008 then
        local cards = self:getBattleCards('B')
        for i = 1, #cards do
            self:recHp(cards[i], val, false, cid, id, mode)
            casted = true
        end

    elseif id == 1009 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            local card = self:randomOne(opponent:getBattleCards('B', Data.CARD_MAX_LEVEL, atkTarget))
            if card ~= nil then
                self:setCardPosChange(atkTarget, BattleData.CardPosChange.swap, cid, id, mode)
                self:setCardPosChange(card, BattleData.CardPosChange.swap, cid, id, mode)
            end
            casted  = true
        end

    elseif id == 1012 then
        self._extraPowerCost[self._round + 1] = self._extraPowerCost[self._round + 1] or 0 - val
        casted = true

    elseif id == 1014 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val + fromCard._maxHp - fromCard._hp, false, cid, id, mode)
            casted = true
        end

    elseif id == 1015 then
        for i = 1, 2 do
            local cardId = fromCard._ids[2 + i]
            local card = self:getCardById(cardId)
            if card ~= nil then
                self:decHp(card, val, false, cid, id, mode)
                casted = true
            end
        end

    elseif id == 1016 or id == 1055 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            local count = id == 1016 and fromCard:getBuffValue(true, BattleData.PositiveType.powerMark) or val2
            fromCard:removeMark(BattleData.PositiveType.powerMark, count)
            casted  = true
        end

    elseif id == 1017 or id == 1025 or id == 1049 or id == 1105 or id == 1116 then
        if atkTarget ~= nil then
            fromCard._lastCount = B.throwCoin(fromCard)
            self:decHp(atkTarget, val + (fromCard._lastCount == 1 and val2 or 0), false, cid, id, mode)
            casted  = true
        end

    elseif id == 1018 or id == 1030 or id == 1095 then
        fromCard._lastCount = B.throwCoin(fromCard)
        if fromCard._lastCount == 1 then
            self:incPositiveStatus(fromCard, BattleData.PositiveType.ignoreOppoMonsterSkillDamageHalo, true, cid, id, mode)
        end
        casted = true

    elseif id == 1037 or id == 1099 then
        fromCard._lastCount = B.throwCoin(fromCard)
        if fromCard._lastCount == 1 then
            self:incPositiveStatus(fromCard, BattleData.PositiveType.ignoreOppoMonsterSkillHalo, true, cid, id, mode)
        end
        casted = true

    elseif id == 1020 or id == 1060 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val + fromCard:getBuffValue(true, BattleData.PositiveType.waterMark) * val2, false, cid, id, mode)
            casted  = true
        end

    elseif id == 1023 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            opponent._extraPowerCost[opponent._round + 1] = opponent._extraPowerCost[opponent._round + 1] or 0 + val2
            casted  = true
        end

    elseif id == 1026 or id == 1048 or id == 1071 or id == 1094 or id == 1117 
        or id == 1042 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            fromCard._lastCount = B.throwCoin(fromCard)
            if fromCard._lastCount == 1 then
                if id == 1042 then
                    self:incNegativeStatus(atkTarget, self:randomOne(info._refSkills), false, cid, id, mode)
                else
                    self:incNegativeStatus(atkTarget, info._refSkills, false, cid, id, mode)
                end
            end
            casted  = true
        end

    elseif id == 1027 or id == 1032 or id == 1036 or id == 1075 or id == 1098 or id == 1115 then
        if atkTarget ~= nil then
            fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
            self:decHp(atkTarget, val * B.getCoinFaceCount(fromCard._lastCount), false, cid, id, mode)
            casted  = true
        end

    elseif id == 1034 then
       local card = self:getCardById(fromCard._ids[3])
       if card ~= nil then
           self:setCardStatus(card, BattleData.CardStatus.hand, cid, id, mode)
           self:randomPile()
           casted = true
       end

    elseif id == 1038 then
        if atkTarget ~= nil then
            if self._hp == self._maxHp then
                self:decHp(atkTarget, val + val2, false, cid, id, mode)
                self:incNegativeStatus(atkTarget, info._refSkills, false, cid, id, mode)
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
            end
            casted  = true
        end

    elseif id == 1041 then
       local card = self:getCardById(fromCard._ids[3])
       if card ~= nil then
           self:setCardStatus(card, BattleData.CardStatus.hand, cid, id, mode)
           self:randomPile()
           casted = true
       end
    
    elseif id == 1043 then
       if atkTarget ~= nil then
            fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
            if fromCard._lastCount == 1 then
                self:decHp(atkTarget, val + val2, false, cid, id, mode)
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
                self:incNegativeStatus(atkTarget, info._refSkills, false, cid, id, mode)
            end
            casted  = true
        end
    
    elseif id == 1045 then
       if atkTarget ~= nil then
            fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
            local faceCount = B.getCoinFaceCount(fromCard._lastCount)
            if faceCount > 0 then
                self:decHp(atkTarget, val + info._val[faceCount + 1], false, cid, id, mode)
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
            end
            casted  = true
        end

    elseif id == 1047 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            self:recHp(fromCard, math.min(atkTarget._hp, B.getDamageByMonster(fromCard, atkTarget, id, val)), false, cid, id, mode)
            casted = true
        end

    elseif id == 1050 then
        if atkTarget ~= nil then
            if atkTarget._info._nature == info._refCards[1] or atkTarget._info._nature == info._refCards[2] then
                self:decHp(atkTarget, val + val2, false, cid, id, mode)
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
            end
            casted = true
        end

    elseif id == 1056 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            self:incNegativeStatus(atkTarget, info._refSkills, false, cid, id, mode)
            opponent._fortress._disableDrawbackRounds[opponent._round + 1] = true
            casted = true
        end

    elseif id == 1057 then
        if atkTarget ~= nil then
            local cards = {self._pilecards[1], opponent._pilecards[1]}
            local count = 0
            for i = 1, 2 do
                local card = cards[i]
                if card ~= nil then
                    self:setCardStatus(card, BattleData.CardStatus.grave, cid, id, mode)
                    count = count + 1
                end
            end
            if count > 0 then
                self:decHp(atkTarget, val * count, false, cid, id, mode)
                casted = true
            end
        end

    elseif id == 1059 then
        fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
        local card = nil
        if fromCard._lastCount == 1 then card = self:randomOne(opponent:getBattleCards('B'))
        else card = self:randomOne(self:getBattleCards('B'))
        end
        if card ~= nil then
            self:decHp(card, val * count, false, cid, id, mode)
            casted = true
        end

    elseif id == 1061 then
       local card = self:getCardById(fromCard._ids[3])
       if card ~= nil then
           self:setCardStatus(card, BattleData.CardStatus.board, cid, id, mode)
           self:randomPile()
           casted = true
       end

    elseif id == 1065 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            local card = self:randomOne(opponent:getBattleCards('B', Data.CARD_MAX_LEVEL, atkTarget))
            if card ~= nil then
                self:decHp(card, val2, false, cid, id, mode)
            end
            casted = true
        end

    elseif id == 1066 then
        if atkTarget ~= nil then
            fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
            if fromCard._lastCount == 1 then
                self:decHp(atkTarget, val + val2, false, cid, id, mode)
                self:incNegativeStatus(atkTarget, info._refSkills, false, cid, id, mode)
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
            end
            casted  = true
        end

    elseif id == 1067 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            opponent._fortress._disableDrawbackRounds[opponent._round + 1] = true
            casted = true
        end

    elseif id == 1068 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            if fromCard._summonRound == self._round then
                self:incNegativeStatus(atkTarget, info._refSkills, false, cid, id, mode)
            end
            casted = true
        end

    elseif id == 1069 then
        if atkTarget ~= nil then
            fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
            self:decHp(atkTarget, val, false, cid, id, mode)
            if fromCard._lastCount == 1 then
                --self:incNegativeStatus(opponent._fortress, BattleData.NegativeType.powerLock, false, cid, id, mode)
                --self:incNegativeValue(opponent._fortress, BattleData.NegativeType.powerLock, val2, Data.AggregateType.sum, cid, id, mode)
                atkTarget:removeMark(BattleData.PositiveType.powerMark, val2)
            end
            casted = true
        end

    elseif id == 1072 then
        local card = self:getCardById(fromCard._ids[3])
        if card ~= nil then
            self:changeCardPos(fromCard, BattleData.CardPosChange.swap)
            self:changeCardPos(card, BattleData.CardPosChange.swap)
            casted = true
        end

    elseif id == 1076 then
        if atkTarget ~= nil then
            fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
            if fromCard._lastCount == 1 then
                self:decHp(atkTarget, val + val2, false, cid, id, mode)
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
                self:decHp(fromCard, val3, false, cid, id, mode)
            end
            casted  = true
        end

    elseif id == 1078 then 
        if atkTarget ~= nil then
            if fromCard._ids[3] == 1 then
                self:decHp(atkTarget, val + val2, false, cid, id, mode)
                --self:incNegativeStatus(self._fortress, BattleData.NegativeType.powerLock, false, cid, id, mode)
                --self:incNegativeValue(self._fortress, BattleData.NegativeType.powerLock, self._round, Data.AggregateType.sum, cid, id, mode)
                fromCard:removeMark(BattleData.PositiveType.powerMark, formCard:getBuffValue(true, BattleData.PositiveType.powerMark))
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
            end
            casted = true
        end

    elseif id == 1081 then
        if atkTarget ~= nil then
            fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
            self:decHp(atkTarget, val, false, cid, id, mode)
            if fromCard._lastCount == 0 then
                --self:incNegativeStatus(self._fortress, BattleData.NegativeType.powerLock, false, cid, id, mode)
                --self:incNegativeValue(self._fortress, BattleData.NegativeType.powerLock, self._round, Data.AggregateType.sum, cid, id, mode)
                fromCard:removeMark(BattleData.PositiveType.powerMark, formCard:getBuffValue(true, BattleData.PositiveType.powerMark))
            end
            casted = true
        end

    elseif id == 1083 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            opponent._disableMainMonsterAbilityRounds[opponent._round + 1] = true
            casted = true
        end

    elseif id == 1085 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            self:recHp(fromCard, val2, false, cid, id, mode)
            casted = true
        end

    elseif id == 1087 then
       if atkTarget ~= nil then
            fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
            local faceCount = B.getCoinFaceCount(fromCard._lastCount)
            if faceCount > 0 then
                self:decHp(atkTarget, val + val2 * faceCount, false, cid, id, mode)
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
            end
            casted  = true
        end

    elseif id == 1088 or id == 1089 then
        local card = self:getCardById(fromCard._ids[3])
        if card ~= nil then
            self:addDamageMark(card, val, false, cid, id, mode)
            casted = true
        end

    elseif id == 1091 then
        local card = self:randomOne(opponent:getBattleCards('H'))
        if card ~= nil then
            self:setCardStatus(card, BattleData.CardStatus.leave, cid, id, mode)
            casted = true
        end

    elseif id == 1092 then
        local cards = opponent:getBattleCards('B')
        for i = 1, #cards do
            self:addDamageMark(cards[i], val, false, cid, id, mode)
            casted = true
        end

    elseif id == 1093 or id == 7007 then
        casted = self:swapHandPileCards(self:getBattleCards('H', Data.CARD_MAX_LEVEL, fromCard), #opponent:getBattleCards('H'), cid, id, mode)

    elseif id == 1100 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            local cards = self:getBattleCards('B')
            for i = 1, #cards do
                self:decHp(cards[i], val2, false, cid, id, mode)
                casted = true
            end 
        end

    elseif id == 1102 or id == 1111 then
       if atkTarget ~= nil then
            local count = fromCard:getBuffValue(true, BattleData.PositiveType.powerMark)
            local faceCount = 0
            if count > 0 then
                fromCard._lastCount = B.throwCoins(fromCard, count)
                faceCount = B.getCoinFaceCount(fromCard._lastCount)
            end
            if faceCount > 0 then
                self:decHp(atkTarget, val + val2 * faceCount, false, cid, id, mode)
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
            end
            casted  = true
        end

    elseif id == 1104 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, math.max(0, val + fromCard._hp - fromCard._maxHp), false, cid, id, mode)
            casted = true
        end

    elseif id == 1107 then
        if atkTarget ~= nil then
            self:addDamageMark(atkTarget, val, false, cid, id, mode)
            casted = true
        end

    elseif id == 1109 then 
        if atkTarget ~= nil then
            if fromCard._ids[3] == 1 then
                self:decHp(atkTarget, val + val2, false, cid, id, mode)
                self:decHp(fromCard, val3, false, cid, id, mode)
            else
                self:decHp(atkTarget, val, false, cid, id, mode)
            end
            casted = true
        end

    elseif id == 1112 then
        self:recHp(fromCard, val, false, cid, id, mode)
        self._disableDrawbackRounds[self._round + 1] = true
        casted = true

    elseif id == 1118 then
        self:recHp(fromCard, fromCard._maxHp - fromCard._hp, false, cid, id, mode)
        self._disable1118Rounds[self._round + 1] = true
        casted = true

    elseif id == 119 then
        if atkTarget ~= nil then
            self:decHp(atkTarget, val, false, cid, id, mode)
            self._destroyedPower = self._destroyedPower + val2
            self:incPower(-val2, cid, id, mode)
            casted = true
        end
        
    elseif id == 2001 then
        if fromCard._pos ~= 1 then
            self:incPositiveStatus(fromCard, BattleData.PositiveType.ignoreOppoMonsterSkillDamageHalo, true, cid, id, mode)
            casted = true
        end

    elseif id == 2004 then
        casted = fromCard:disableUnderSkillByBuff(false, BattleData.NegativeType.chaos)

    elseif id == 2005 then
        fromCard:addMark(BattleData.PositiveType.waterMark, val, cid, id, mode)
        self:recHp(fromCard, math.min(3, fromCard:getBuffValue(true, BattleData.PositiveType.waterMark) + val) * val2, false, cid, id, mode)
        casted = true

    elseif id == 4001 then
        local card = self:getCardById(fromCard._ids[3])
        if card ~= nil then
            self:setCardStatus(card, BattleData.CardStatus.hand, cid, id, mode, BattleData.CardStatusVal.p2h_show)
            self:randomPile()
            casted = true
        end
        
    elseif id == 4002 then
        casted = fromCard:addMark(BattleData.PositiveType.waterMark, val, cid, id, mode)

    elseif id == 4003 then
        fromCard._lastCount = B.throwCoin(fromCard)
        if fromCard._lastCount == 1 then
            self:incNegativeStatus(atkTarget, BattleData.NegativeType.poison, false, cid, id, mode)
        else
            self:incNegativeStatus(fromCard, BattleData.NegativeType.poison, false, cid, id, mode)
        end
        casted = true

    elseif id == 4004 then
        local card = self:getCardById(fromCard._ids[3])
        if card ~= nil then
            self:setCardStatus(card, BattleData.CardStatus.hand, cid, id, mode, BattleData.CardStatusVal.p2h_show)
            local handCard = self:randomOne(self:getBattleCards('H', Data.CARD_MAX_LEVEL, fromCard))
            if handCard ~= nil then
                self:setCardStatus(handCard, BattleData.CardStatus.grave, cid, id, mode)
            end
            casted = true
        end

    elseif id == 5001  then
        local card = self:getCardById(fromCard._ids[3])
        if card ~= nil then
            self:recHp(card, val, false, cid, id, mode)
            casted = true
        end

    elseif id == 5002 then
        local card = self:getCardById(fromCard._ids[3])
        if card ~= nil then
            self:recHp(card, card._maxHp - card._hp, false, cid, id, mode)
            --[[
            if card._pos == 1 then
                self:incNegativeStatus(card, BattleData.NegativeType.sleepOneRound, false, cid, id, mode)
            else
                self:incNegativeStatus(opponent._fortress, BattleData.NegativeType.powerLock, false, cid, id, mode)
                self:incNegativeValue(opponent._fortress, BattleData.NegativeType.powerLock, val, Data.AggregateType.sum, cid, id, mode)
            end
            ]]
            fromCard:removeMark(BattleData.PositiveType.powerMark, formCard:getBuffValue(true, BattleData.PositiveType.powerMark))
            casted = true
        end

    elseif id == 5003 then
        local card = self._boardCards[1]
        if card ~= nil then
            self:decNegativeStatus(card, BattleData.NEGATIVE_COMMON, false, cid, id, mode)
            casted = true
        end

    elseif id == 5005 then
        self._extraMonsterDamageToAll = val
        casted = true

    elseif id == 5006 then
        

    elseif skillType == Data.SkillType.magic_equip then
        if mode == Data.SkillMode.magic then
            local card = self:getCardById(fromCard._ids[3])
            if id == 6007 then
                card:addMark(BattleData.PositiveType.powerMark, 1, cid, id, mode)
                self._powerUsedCount = self._powerUsedCount + 1
                casted = true
            else
                if #card._binds == 0 then
                    self:bindCard(fromCard, card, cid, id, mode)
                    casted = true
                end
            end
        elseif mode == Data.SkillMode.under_spell_damage then
            if id == 6001 then
                if actionCard._owner ~= fromCard._owner and fromCard:hasUnderSkillByDamageFrom(actionCard) then
                    self:addDamageMark(actionCard, val, false, cid, id, mode)
                    casted = true
                end
            elseif id == 6005 then
                self:incNegativeStatus(actionCard, BattleData.NegativeType.poison, false, cid, id, mode)
                casted = true
            end
        elseif mode == Data.SkillMode.bcs2gl then
            if id == 6004 then
                self:setCardStatus(fromCard, BattleData.CardStatus.hand, cid, id, mode)
                casted = true
            elseif id == 6006 then
                --self:incNegativeStatus(opponent._fortress, BattleData.NegativeType.powerLock, false, cid, id, mode)
                --self:incNegativeValue(opponent._fortress, BattleData.NegativeType.powerLock, val, Data.AggregateType.sum, cid, id, mode)
                if opponent._boardCards[1] ~= nil then
                    opponent._boardCards[1]:removeMark(BattleData.PositiveType.powerMark, val)
                end
                casted = true
            end
        end

    elseif id == 7001 then
        fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
        local faceCount = B.getCoinFaceCount(fromCard._lastCount)
        if faceCount > 0 then
            local cards = self:filterCanChangeToHandCards(self._pileCards)
            for i = 1, faceCount do
                local card = cards[i]
                if card ~= nil then
                    self:setCardStatus(card, BattleData.CardStatus.hand, cid, id, mode)
                end
            end
        end
        casted = true
        
    elseif id == 7002 then
       local card = self:getCardById(fromCard._ids[3])
       if card ~= nil then
           self:setCardStatus(card, BattleData.CardStatus.hand, cid, id, mode, BattleData.CardStatusVal.p2h_show)
           self:randomPile()
           casted = true
       end

    elseif id == 7003 then
        fromCard._lastCount = B.throwCoins(fromCard, info._coinCount)
        if fromCard._lastCount == 1 or fromCard._lastCount == 3 then
            local card = opponent._pileCards[1]
            if card ~= nil then
                self:setCardStatus(card, BattleData.CardStatus.grave, cid, id, mode)
            end
        end
        if fromCard._lastCount == 2 or fromCard._lastCount == 3 then
            local card = opponent._pileCards[2]
            if card ~= nil then
                self:setCardStatus(card, BattleData.CardStatus.grave, cid, id, mode)
            end
        end
        casted = true

    elseif id == 7004 then
        self._extraMonsterDamageToMain = val
        casted = true

    elseif id == 7005 then
        local card = self:getCardById(fromCard._ids[3])
        if card ~= nil then
            local cards = B.filterFirstCards(self:filterCanChangeToHandCards(self:getBattleCards('P')), val)
            for i = 1, val do
                local pileCard = cards[i]
                if pileCard ~= nil then
                    if pileCard == card then
                        self:setCardStatus(pileCard, BattleData.CardStatus.hand, cid, id, mode)
                    else
                        self:setCardStatus(pileCard, BattleData.CardStatus.grave, cid, id, mode)
                    end
                    casted = true
                end
            end
        end

    elseif id == 7006 then
        local cards = self:filterCanChangeToHandCards(self:getBattleCards('P'))
        for i = 1, math.min(val, #cards) do
            local card = cards[i]
            self:setCardStatus(card, BattleData.CardStatus.hand, cid, id, mode, BattleData.CardStatusVal.p2h_show)
            casted = true
        end

    elseif id == 7008 then
        if self:swapHandPileCards(self:getBattleCards('H', Data.CARD_MAX_LEVEL, fromCard), val, cid, id, mode) then casted = true end
        if opponent:swapHandPileCards(opponent:getBattleCards('H'), val, cid, id, mode) then casted = true end

    elseif id == 7009 then
        local cards = self:filterCanChangeToHandCards(self._pileCards)
        for i = 1, 2 do
            local card = cards[i]
            if card ~= nil then
                self:setCardStatus(card, BattleData.CardStatus.hand, cid, id, mode)
                casted = true
            end
        end

    elseif id == 50001 then
        fromCard._lastCount = B.throwCoin(fromCard)
        if fromCard._lastCount == 1 then
            self:decNegativeStatus(fromCard, BattleData.NegativeType.sleep, false, cid, id, mode)
        end
        casted = true

    elseif id == 50002 then
        if fromCard._pos == 1 then
            self:addDamageMark(fromCard, val, false, cid, id, mode)
            casted = true
        end

    elseif id == 50003 then
        self:decNegativeStatus(fromCard, BattleData.NegativeType.numb, false, cid, id, mode)
        casted = true

    elseif id == 50004 then
        self:incPower(-self._fortress:getBuffValue(false, BattleData.NegativeType.powerLock), false, cid, id, mode)
        self:decNegativeStatus(self._fortress, BattleData.NegativeType.powerLock, false, cid, id, mode)
        casted = true

    elseif id == 50005 then
        fromCard._lastCount = B.throwCoin(fromCard)
        if fromCard._lastCount == 0 then
            self._isMonsterActioned = true
            self:addDamageMark(fromCard, val, false, cid, id, mode)
        end
        self:decNegativeStatus(fromCard, BattleData.NegativeType.chaos, false, cid, id, mode)
        casted = true

    elseif id == 51001 then
        if fromCard:disableUnderSkillByOppoMonsterDamage(cid, id, mode) then
            casted = true
        end

    elseif id == 51002 then
        if fromCard:disableUnderSkillByOppoMonster(cid, id, mode) then
            casted = true
        end

    end

    if casted then
        if skillType == Data.SkillType.magic_item or skillType == Data.SkillType.magic_special then
            self:setCardStatus(fromCard, BattleData.CardStatus.grave, cid, id, mode)
        elseif skillType == Data.SkillType.magic_equip then
            self:setCardStatus(fromCard, BattleData.CardStatus.leave, cid, id, mode)
        end

        --[[
        if info._power > 0 then
            self:incPower(-self:getSkillPowerCost(info._power), cid, sid, mode)
        end
        ]]
        if skillType == Data.SkillType.monster_attack then
            self._isMonsterActioned = true
        end

        skill._totalCastedTimes = skill._totalCastedTimes + 1
        if B.isSkillModeCastedByOwner(mode) then
            self:skillCasted(skill._owner, skill, mode)
        else
            self:skillCasted(fromCard, skill, mode)
        end
    else
        if mode ~= Data.SkillMode.halo then
            skill._castTimes = 0
        end
    end
end

function _M:skillCasted(fromCard, skill, mode)
    -- log
    self:battleLog("[BATTLE] %s\t%s", Str(fromCard._type ~= Data.CardType.fortress and fromCard._info._nameSid or STR.FORTRESS), Str(Data._skillInfo[skill._id]._nameSid))

    local actionCard = self:getActionCard()
    
    actionCard._needAccount = true
    if mode ~= Data.SkillMode.halo then
        table.insert(fromCard._castedSkills, skill)
        self._castedSkillCounts[skill._id] = (self._castedSkillCounts[skill._id] or 0) + 1
        local skillType = Data.getSkillType(skill._id)
        if skillType == Data.SkillType.magic_special then
            self._specialMagicUsed = true
        end
    end
end

-----------------------------------
-- monster skill
-----------------------------------

function _M:canUseMonster(card, isAi)
    if self._battleType == Data.BattleType.PVP_room and self._round == 1 and card._infoId ~= 20236 then return false end

    if self._isSummonDisabled then return false end
    if self._isSummonDisabledBySelfStar[card._info._star] or self._isSummonDisabledByOppoStar[card._info._star] then return false end
    
    --[[ TODO
    local canUse, target, choice = self:canUseMonsterSpecific(card, isAi)
    if canUse then return canUse, target, choice end

    if card:hasSkillInMode(Data.SkillMode.use_disable) then return false end
    ]]
    
    local canUse, ids = self:canUseMonsterNormal(card, isAi)

    --[[ TODO
    if not canUse then
        canUse, target, choice = self:canUseMonsterSpecial(card, isAi)
    end
    ]]

    return canUse, ids
end

function _M:canUseMonsterNormal(card, isAi, isTestShowSelect)
    if card._info._level == 0 then
        if self:getEmptyBackupPos(card) ~= nil then
            return true, {card._id}
        end
    else
        local cards = self:filterCanEvolveCards(self:getBattleCardsByOriginId('B', card._info._evoBase), card)
        if #cards > 0 then
            return true, {card._id, cards[1]._id}
        end
    end

    return false

    --[[
    if self._isSummonDisabled or self._isNormalSummoned then return false end
    if self._isSummonDisabledBySelfStar[card._info._star] or self._isSummonDisabledByOppoStar[card._info._star] then return false end
    
    if card:hasSkillInMode(Data.SkillMode.use_normal_disable) or card:hasSkillInMode(Data.SkillMode.use_specific_by_condition) or card:hasSkillInMode(Data.SkillMode.use_specific_by_another_card) then return false end
    if card:hasSkills{3246} and #self:getBattleCards('B') ~= 0 then return false end

    if not isAi then return true end

    
    local hasTargetUsingSkill, skill = card:hasTargetUsingSkill()
    if not hasTargetUsingSkill then return true, nil, choice end

    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0
    
    local opponent = self._opponent
    local boardCards = self:getBattleCards('B')
    local oppoBoardCards = opponent:getBattleCards('B')

    if id == 3002 or id == 3124 then
        local cards = self:getBattleCardsByInfoId('B', info._refCards[1])
        return true, cards[1], choice
    elseif id == 3003 then
        local cards = B.mergeTable({self:getBattleCardsByInfoId('B', info._refCards[1]),  self:getBattleCardsByInfoId('B', info._refCards[2])})
        return true, cards[1], choice
    elseif id == 3005 then
        local oppoBoardCardsCanAtk = {}
        for i = 1, #oppoBoardCards do
            local oppoCard = oppoBoardCards[i]
            if oppoCard:canAttack(false) then
                oppoBoardCardsCanAtk[#oppoBoardCardsCanAtk + 1] = oppoCard
            end
        end
        return true, B.getMaxAtkCard(oppoBoardCardsCanAtk) or B.getMaxAtkCard(oppoBoardCards), choice
    elseif id == 3012 then
        return true, B.getMaxHpCard(oppoBoardCards), choice
    elseif id == 3024 then
        return true, B.getMaxHpCard(oppoBoardCards), choice
    else
        print ('@@@@@@@@@@@@@@@@ unimplemented ai magic!', id)
    end

    return false
    ]]
end

function _M:canUseMonsterSpecial(card, isAi)
    if self:getEmptyBoardPos(card) == nil or not self:canSpecialSummon(card) then return false end

    if card:hasSkills({3149}) and self._castedSkillCounts[3149] ~= nil then return false end
    if card:hasSkills({3188}) and self._castedSkillCounts[3188] ~= nil then return false end
    if card:hasSkills({3244}) and self._castedSkillCounts[3244] ~= nil then return false end
    if card:hasSkills({3250}) and self._castedSkillCounts[3250] ~= nil then return false end

    local choice = 2

    --1. 3026, 3054, 3068, 3092, 3217, 3244
    if card:hasSkills({3026}) and #self:getBattleCards('B') == 0 then
        return true, nil, choice, card._skills[1]
    elseif card:hasSkills({3054}) and #self:getBattleCards('B') + 2 <= #self._opponent:getBattleCards('B') then
        return true, nil, choice, card._skills[1]
    elseif card:hasSkills({3068}) and #self:getBattleCards('H') == 1 then
        return true, nil, choice, card._skills[1]
    elseif card:hasSkills({3092}) and #B.filterNoSkillCards(self:getBattleCardsByNature('B', Data._skillInfo[3092]._refCards[1])) > 0 then
        return true, nil, choice, card._skills[1]
    elseif card:hasSkills({3217}) and #self:getBattleCardsByCategory('B', Data._skillInfo[3217]._refCards[1]) > 0 then
        return true, nil, choice, card._skills[1]
    elseif card:hasSkills({3244}) and #self._opponent:getBattleCards('CS') >= Data._skillInfo[3244]._val[1] then
        return true, nil, choice, card._skills[1]
    
    end

    --2. choice
    local hasSkill, skill = card:hasNoGemSkill()
    if hasSkill then
        if skill._id == 3009 or skill._id == 3149 then return #self:getBattleCards('H', Data.CARD_MAX_LEVEL, card) > 0, nil, choice, skill
        elseif skill._id == 3016 then return #self:getBattleCardsByCategory('H', Data.CardCategory.dragon, Data.CARD_MAX_LEVEL, card) > 0, nil, choice, skill
        elseif skill._id == 3177 then 
            local cards = B.filterNoShieldCards(self._opponent:getBattleCards('B'), BattleData.PositiveType.shieldMonster)
            if #cards >= 2 then
                local sortedCards = B.sortCardsByAtk(cards)
                return true, nil, choice, skill
            else
                return false
            end
        elseif skill._id == 3188 then
            local cards = B.filterCanActionCards(B.filterNormalSummonCards(self:getBattleCardsByMinStar('B', 5), true))
            if #cards > 0 and not isAi then return true
            else return false
            end
        elseif skill._id == 3250 then   
            local cards = self:filterCanChangeToHandCards(B.filterInKeywordCards(self:getBattleCardsByType('P', Data.CardType.magic), Data._skillInfo[3250]._refCards[1]))
            if #cards > 0 and not isAi then return true
            else return false
            end
        end
    end

    --3. gemUnderSkill
    for i = 1, #self._gemUnderSkills do
        local underSkill = self._gemUnderSkills[i]
        if underSkill._sid == 3007 then
            if card:getStar() <= underSkill._val then
                return true, nil, choice, underSkill
            end
        elseif underSkill._sid == 3144 then
            if card._info._keyword == underSkill._val then
                return true, nil, choice, underSkill
            end
        elseif underSkill._sid == 3161 or underSkill._sid == 4058 then
            if card._info._category == underSkill._val then
                return true, nil, choice, underSkill
            end
        elseif underSkill._sid == 4068 then
            return true, nil, choice, underSkill
        elseif underSkill._sid == 7063 then
            if card._info._category == underSkill._val and #self:getBattleCards('B') == 0 then
                return true, nil, choice, underSkill
            end
   
        end
    end
    
    return false     
end

function _M:canUseMonsterSpecific(card, isAi)
    if self:getEmptyBoardPos(card) == nil or not self:canSpecialSummon(card, false, true) then return false end

    --1. 3019
    if card:hasSkills({3019}) then 
        return true, nil, 3

    -- 2. 3033
    elseif card:hasSkills({3033}) then
        local info = Data._skillInfo[3033]
        local cards = B.filterCanActionCards(self:getBattleCardsByInfoId('B', info._refCards[1]))
        if #cards > 0 then return true, cards[1], 3 end

    -- 3. 3110, 3207
    elseif card:hasSkills({3110}) then
        local info = Data._skillInfo[3110]
        local cards = self:getBattleCardsByNature('G', info._refCards[1])
        if self._summonedMonsterCounts[card._infoId] == nil and #cards == info._val[1]  then return true, nil, 3 end
    elseif card:hasSkills({3207}) then
        local info = Data._skillInfo[3207]
        local cards = self:getBattleCardsByNature('G', info._refCards[1])
        if self._summonedMonsterCounts[card._infoId] == nil and #cards == info._val[1]  then return true, nil, 3 end

    -- 4. 3164
    elseif card:hasSkills({3164}) then
        local info = Data._skillInfo[3164]
        local cards = self:getBattleCardsByCategory('G', info._refCards[1])
        if #cards >= info._val[1] then return true, nil, 3 end
        
    -- 5. 3199
    elseif card:hasSkills({3199}) then
        local info = Data._skillInfo[3199]
        local cards = self:getBattleCardsByNature('G', info._refCards[1])
        if #cards >= info._val[1] then return true, nil, 3 end

    -- 7. 3225
    elseif card:hasSkills({3225}) then
        local info = Data._skillInfo[3225]
        local cards1 = self:getBattleCardsByInfoId('G', info._refCards[1])
        local cards2 = self:getBattleCardsByInfoId('G', info._refCards[2])
        local cards3 = self:getBattleCardsByInfoId('G', info._refCards[3])
        if #cards1 > 0 and #cards2 > 0 and #cards3 > 0 then return true, nil, 3 end

    end


    return false
end

function _M:canUseMonsterSpell(card, skill, isAi)
    if self ~= self:getActionPlayer() then return false end

    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0
    local skillType = Data.getSkillType(id)

    local opponent = self._opponent
    local atkTarget = opponent._boardCards[1]

    if card:getBuffValue(true, BattleData.PositiveType.powerMark) < self:getSkillPowerCost(info._power) then return false end
    if skillType == Data.SkillType.monster_attack then 
        if card._owner._round == 1 then return false end
        if card._pos ~= 1 then return false end
        if card:hasBuff(false, BattleData.NegativeType.sleep) 
            or card:hasBuff(false, BattleData.NegativeType.sleepOneRound) 
            or card:hasBuff(false, BattleData.NegativeType.numb) then return false end
    else
        if card._pos == 1 and self._disableMainMonsterAbilityRounds[self._round] then return false end
    end

    -- 1. need atkTarget
    if B.isDamageSkill(skill)
    or id == 1009 
    or id == 1014 
    or id == 1016 or id == 1055 
    or id == 1017 or id == 1025 or id == 1049 or id == 1105 or id == 1116
    or id == 1020 or id == 1060
    or id == 1023
    or id == 1026 or id == 1048 or id == 1071 or id == 1094 or id == 1117
    or id == 1027 or id == 1032 or id == 1036 or id == 1075 or id == 1098 or id == 1115
    or id == 1038
    or id == 1042
    or id == 1043
    or id == 1045
    or id == 1047
    or id == 1050
    or id == 1056
    or id == 1065
    or id == 1066
    or id == 1067
    or id == 1068
    or id == 1069
    or id == 1076
    or id == 1078
    or id == 1081
    or id == 1083
    or id == 1085
    or id == 1087
    or id == 1100
    or id == 1102 or id == 1111
    or id == 1104
    or id == 1107
    or id == 1109
    or id == 1119
    then
        if atkTarget ~= nil then
            return true, {card._id, id}
        end

    -- 2. need no target
    elseif id == 1008 
    or id == 1012 
    or id == 1018 or id == 1030 or id == 1095
    or id == 1037 or id == 1099
    then
        return true, {card._id, id}
    elseif id == 1112 then
        if card._hp < card._maxHp then
            return true, {card._id, id}
        end
    elseif id == 1118 then
        if card._hp < card._maxHp and self._disable1118Rounds[self._round] ~= true then
            return true, {card._id, id}
        end

    -- 31. need oppo board cards
    elseif id == 1015 
    or id == 1059 
    or id == 1088 or id == 1089 
    or id == 1092 then
        local cards = opponent:getBattleCards('B')
        if #cards > 0 then
            return true, {card._id, id, cards[1]._id, cards[2] and cards[2]._id}
        end

    -- 32. need self board cards
    elseif id == 1072 then
        local cards = self:getBattleCards('B', Data.CARD_MAX_LEVEL, self._boardCards[1])
        if #cards > 0 then
            local maxHpCard = B.getMaxHpCard(cards) or cards[1]
            return true, {card._id, id, maxHpCard._id}
        end
    
    -- 4. need self pile
    elseif id == 1034 then
        local cards = self:filterCanChangeToHandCards(self:getBattleCards('P'))
        if #cards > 0 then
            local maxHpCard = B.getMaxHpCard(cards) or cards[1]
            return true, {card._id, id, maxHpCard._id}
        end
    elseif id == 1041 then
        local cards = self:filterCanChangeToHandCards(self:getBattleCardsByNature('P', info._refCards[1]))
        if #cards > 0 then
            local maxHpCard = B.getMaxHpCard(cards) or cards[1]
            return true, {card._id, id, maxHpCard._id}
        end
    elseif id == 1061 then
        local cards = self:filterCanChangeToBoardCards(self:getBattleCardsByLevel('P', 0))
        if #cards > 0 then
            local maxHpCard = B.getMaxHpCard(cards) or cards[1]
            return true, {card._id, id, maxHpCard._id}
        end

    -- 5. need self or oppo pile
    elseif id == 1057 then
        if atkTarget ~= nil and (#self._pileCards + #opponent._pileCards) > 0 then
            return true, {card._id, id}
        end

    -- 6. need oppo hand
    elseif id == 1091 then
        local cards = opponent:getBattleCards('H')
        if #cards > 0 then
            return true, {card._id, id}
        end

    -- other
    elseif id == 1093 then
        local cards1 = self:filterCanChangeToHandCards(self:getBattleCards('P'))
        local cards2 = opponent:getBattleCards('H')
        if #cards1 > 0 and #cards2 > 0 then
            return true, {card._id, id}
        end
    
    elseif id == 4001 then
        if self._castedSkillCounts[id] ~= nil then return false end
        local cards = self:filterCanChangeToHandCards(self:getBattleCardsByType('P', Data.CardType.monster))
        if #cards > 0 then
            local maxHpCard = B.getMaxHpCard(cards) or cards[1]
            return true, {card._id, id, maxHpCard._id}
        end

    elseif id == 4002 then
        if self._castedSkillCounts[id] ~= nil then return false end
        return true, {card._id, id}

    elseif id == 4003 then
        if self._castedSkillCounts[id] ~= nil then return false end
        if atkTarget ~= nil and not atkTarget:hasBuff(false, BattleData.NegativeType.poison) and not card:hasBuff(false) then
            return true, {card._id, id}
        end

    elseif id == 4004 then
        if self._castedSkillCounts[id] ~= nil then return false end
        local cards1 = self:getBattleCards('H', Data.CARD_MAX_LEVEL, card)
        local cards2 = self:filterCanChangeToHandCards(self:getBattleCardsByNature('G', info._refCards[1]))
        if #cards1 > 0 and #cards2 > 0 then
            local maxHpCard = B.getMaxHpCard(cards2) or cards1[2]
            return true, {card._id, id, maxHpCard._id}
        end
        
    
    end



    return false
end

function _M:canUseAnyMonsterSpell(card)
    if self ~= self:getActionPlayer() then return false end

    for i = 1, #card._skills do
        if self:canUseMonsterSpell(card, card._skills[i]) then
            return true
        end
    end
end

function _M:canEvolveCard(card, baseCard)
    if self ~= self:getActionPlayer() then return false end

    if card._owner._round == 1 then return false end
    if baseCard._isEvolved then return false end

    return baseCard._info._originId == card._info._evoBase
end

function _M:canDrawbackCard(card)
    if self ~= self:getActionPlayer() then return false end
    if self._disableDrawbackRounds[self._round] == true then return false end

    local info = card._info
    if card:getBuffValue(true, BattleData.PositiveType.powerMark) < info._retreatCost then return false end
    if card:hasBuff(false, BattleData.NegativeType.sleep) or card:hasBuff(false, BattleData.NegativeType.sleepOneRound) then return false end
    if #self:getBattleCards('B', Data.CARD_MAX_LEVEL, self._boardCards[1]) == 0 then return false end

    return true
end

-----------------------------------
-- magic skill
-----------------------------------

function _M:canUseMagic(card, isAi)
    if self._isMagicTrapDisabled then return false end

    local skill = card._skills[1]
    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0
    local mainCard = self._boardCards[1]
    local skillType = Data.getSkillType(id)

    local opponent = self._opponent
    local atkTarget = opponent._boardCards[1]

    -- 00. check available
    if card._info._type == Data.MagicTrapType.item then
        if #self:getBattleCardsBySkills('B', {2003}) + #opponent:getBattleCardsBySkills('B', {2003}) > 0 then return false end    
    elseif card._info._type == Data.MagicTrapType.special then
        if self._specialMagicUsed then return false end
    elseif card._info._type == Data.MagicTrapType.power then
        if self._powerUsedCount >= Data.POWER_CAN_USE_COUNT then return false end
    end

    -- 01. equip magic

    -- 02. item, special magic
    
    if id == 5001 or id == 5002 then
        local cards = self:getBattleCardsByHurt('B')
        if #cards > 0 then 
            return true, {card._id, id, B.getMinHpCard(cards)._id} 
        end

    elseif id == 5003 then
        if mainCard ~= nil and mainCard:hasBuffGroup(false, BattleData.NEGATIVE_COMMON) then 
            return true, {card._id, id} 
        end 

    elseif id == 5005 then
        return true, {card._id, id}

    elseif id == 6007 then
        if not isAi then return true, {card._id, id} end
        local targetCard = self:getBattleCardsByNotEnoughCards('B')[1]
        if targetCard ~= nil then return true, {card._id, id, targetCard._id}
        else return fasle 
        end

    elseif skillType == Data.SkillType.magic_equip then
        local cards = self:filterCanEquipCards(self:getBattleCards('B'), card)
        if #cards > 0 then 
            return true, {card._id, id, cards[1]._id} 
        end

    elseif id == 7001 then
        if #self:filterCanChangeToHandCards(self._pileCards) > 0 then 
            return true, {card._id, id} 
        end 
    
    elseif id == 7002 then
        local cards = self:filterCanChangeToHandCards(B.filterInMagicTrapTypeCards(self:getBattleCardsByType('P', Data.CardType.magic), Data.MagicTrapType.equip))
        if #cards > 0 then
            local maxHpCard = B.getMaxHpCard(cards) or cards[1]
            return true, {card._id, id, maxHpCard._id}
        end

    elseif id == 7003 then
        local cards = opponent._pileCards
        if #cards > 0 then 
            return true, {card._id, id}
        end

    elseif id == 7004 then
        if self._ball < opponent._ball and atkTarget ~= nil then
            return true, {card._id, id}
        end

    elseif id == 7005 then  
        local cards = B.filterFirstCards(self:filterCanChangeToHandCards(self:getBattleCards('P')), val)
        if #cards > 0 then 
            local maxHpCard = B.getMaxHpCard(cards) or cards[1]
            return true, {card._id, id, maxHpCard._id}
        end

    elseif id == 7006 then
        if self._ball > opponent._ball then return false end
        local cards = self:filterCanChangeToHandCards(self:getBattleCards('P'))
        if #cards > 0 then
            return true, {card._id, id}
        end

    elseif id == 7007 then
        local cards1 = self:filterCanChangeToHandCards(self:getBattleCards('P'))
        local cards2 = opponent:getBattleCards('H')
        if #cards1 > 0 and #cards2 > 0 then
            return true, {card._id, id}
        end

    elseif id == 7008 then
        return true, {card._id, id}
    
    elseif id == 7009 then
        if #self:filterCanChangeToHandCards(self._pileCards) > 0 then 
            return true, {card._id, id} 
        end 
    
    else
        print ('@@@@@@@@@@@@@@@@ unimplemented ai magic!', id)
        return false
    end

end

function _M:canEquipCard(fromCard, targetCard)
    local skill = fromCard._skills[1]
    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0
    local skillType = Data.getSkillType(id)

    local opponent = self._opponent

    if targetCard == nil then return false end
    
    --  monster
    if skillType == Data.SkillType.magic_equip then
        if id == 6007 then return true end
        return #targetCard._binds == 0
    end

    --[[
    -- monster
        return targetCard:isMonster()

    -- monster with infoId
    elseif id == 4051 or id == 7035 then  
        return targetCard._infoId == info._refCards[1]

    -- monster with infoId2
    elseif id == 4084 then  
        return targetCard._infoId == info._refCards[2]

    -- monster with infoId and can action
    elseif id == 4065 or id == 4069 or id == 4107 then  
        return targetCard._infoId == info._refCards[1] and targetCard:canAction()

    -- monster with multiple infoIds
    elseif id == 7017 then  
       return (targetCard._infoId == info._refCards[1] or targetCard._infoId == info._refCards[2]) 

    -- monster with category
    elseif id == 4044 or id == 4060 or id == 4081 or id == 4118 or id == 4134 or id == 7010 or id == 7023 or id == 7034 or id == 7040 or id == 7041 or id == 7049 or id == 7054 or id == 7060 or id == 7061 or id == 7067 or id == 7068 then
        return targetCard._info._category == info._refCards[1]

    -- monster without category


    -- monter with keyword
    elseif id == 4082 or id == 7002 then
        return targetCard._info._keyword == info._refCards[1]

    -- monster with nature
    elseif id == 7016 or id == 7019 or id == 7020 or id == 7021 or id == 7022 or id == 7039 or id == 7051 or id == 7066 or id == 7069 then
        return targetCard._info._nature == info._refCards[1]

    -- monster with category and nature
    elseif id == 4115 then
        return targetCard._info._category == info._refCards[1] and targetCard._info._nature == info._refCards[2]

    -- monster with min star
    elseif id == 4050 then
        return targetCard._info._star ~= nil and targetCard._info._star >= val

        
    elseif id == 4004 then
        return self._fortress._hp > val and targetCard._info._category == info._refCards[1] and #opponent:getBattleCards('B') > 0

    elseif id == 4064 then
        return targetCard._infoId == info._refCards[1] or targetCard._info._category == info._refCards[2]

    elseif id == 4078 then
        return targetCard._info._category == info._refCards[1] and #self:filterCanChangeToBoardCards(B.filterInCategoryCards(self:getBattleCardsByStar('P', targetCard._info._star), info._refCards[1])) > 0

    elseif id == 4108 then
        return targetCard._info._category == info._refCards[1] and targetCard._info._star >= val

    elseif id == 4113 then
       return ((targetCard._infoId == info._refCards[1]) or (targetCard._infoId == info._refCards[3] and self:hasRareCard(info._refCards[4], true)))

    
    elseif id == 7026 or id == 7046 then
        return #B.filterNotBindedCards({targetCard}, fromCard._infoId, true) > 0

    ]]

    return false
end

function _M:bindMagicTarget(fromCard, magicTarget, cid, id, mode)
    if #fromCard._binds == 0 and magicTarget ~= nil then
        self:bindCard(fromCard, magicTarget, cid, id, mode)
        return true
    end
    return false
end

------------------------------

function _M:canUseTrap(card, isAi)
    if self._battleType == Data.BattleType.PVP_room and self._round == 1 and card._infoId ~= 20236 then return false end

    if self._isMagicTrapDisabled then return false end
    
    local skill = card._skills[1]
    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0
    local opponent = self._opponent

    if not self:canTrapEffect(card) then return false end

    --[[
    if id == 5004 then
        return #self:filterCanChangeToHandCards(self:getBattleCards('P')) > 0

    elseif id == 5005 then
        return #self:filterCanChangeToBoardCards(B.filterInTypeCards(self:getBattleCardsByKeyword('G', info._refCards[1]), Data.CardType.monster)) > 0

    elseif id == 5006 then
        local cards = B.filterNoSkillCards(self:getBattleCardsByKeyword('B', info._refCards[1]), info._refSkills[1])
        return #cards > 0, B.getMaxAtkCard(cards)

    
    elseif id == 5012 then
        return #B.mergeTable({self:getBattleCards('B'), opponent:getBattleCards('B')}) > 0

    elseif id == 5016 then
        return #self:getBattleCards('H', Data.CARD_MAX_LEVEL, card) > 0 and #B.mergeTable({self:getBattleCardsByType('S', Data.CardType.magic), opponent:getBattleCardsByType('S', Data.CardType.magic)}) > 0

    elseif id == 5027 then
        return self._fortress._hp > val and #self:getBattleCards('G') >= 15

    elseif id == 5028 then
        
    elseif id == 5030 then
        if self._castedSkillCounts[id] ~= nil then return false end
        return true

    elseif id == 5031 then
        if not self:canSpecialSummonAnyCard() then return false end
        local cards = self:getBattleCardsByKeyword('B', info._refCards[1])
        if not isAi then return #cards > 0 end
        return #opponent:getBattleCards('B') == 0 and #cards > 0 and #B.filterCanActionCards(cards) == 0

    elseif id == 5034 then
        return #opponent:getBattleCards('CS') == Data.MAX_CARD_COUNT_ON_COVER

    elseif id == 5036 then
        if self._castedSkillCounts[id] ~= nil then return false end
        return self._fortress._hp <= opponent._fortress._hp - val 

    elseif id == 5037 then
        local cards = self:filterCanChangeToBoardCards(self:getBattleCardsByKeyword('G', info._refCards[1]))

    elseif id == 5039 then
        if self._castedSkillCounts[id] ~= nil then return false end
        return opponent:getEmptyBoardPosCount() >= val
        
    elseif id == 5080 then
        return #opponent:getBattleCards('B') > 0

    elseif id == 5091 then
        local card = self:getBattleCardsByInfoId('H', info._refCards[1])[1]
        return card ~= nil and self:getEmptyBoardPos(card) ~= nil and self:canSpecialSummon(card)

    elseif id == 5135 then
        return #opponent:getBattleCards('G') > 0 

    elseif id == 5136 then
        local cards = B.filterInCategoryCards(self:getBattleCardsByMinAtk('B', val), info._refCards[1])
        if #cards > 0 then
            if not isAi then return true
            else
                local oppoCards = opponent:getBattleCards('B')
                return #oppoCards > 0 and B.getMaxAtkCard(oppoCards)._atk > B.getMinAtkCard(cards)._atk
            end
        end

    elseif id == 5141 then
        return #self:getBattleCardsByCategory('G', info._refCards[1]) > 0

    elseif id == 5147 then
        return #B.filterInNatureCards(self:getBattleCardsByMaxStar('B', val), info._refCards[1]) > 0
        
    end
    ]]

    return false
end

function _M:canUseTrapOnTarget(fromCard, targetCard)
    local skill = fromCard._skills[1]
    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[math.min(skill._level, #info._val)] or 0

    local opponent = self._opponent

    if info._targetType == 0 then return targetCard == nil
    elseif info._targetType == 1 and fromCard._owner ~= targetCard._owner then return false 
    elseif info._targetType == 2 and fromCard._owner == targetCard._owner then return false 
    end

    if targetCard == nil then return false end
    
    -- monter with category
    if id == 5143 or id == 5144 then
        return targetCard._info._category == info._refCards[1]

    elseif id == 5145 then
        return targetCard._info._category == info._refCards[1] and targetCard._info._star >= 4

    -- monter with keyword
    elseif id == 5006 then
        return targetCard._info._keyword == info._refCards[1] and not targetCard:hasSkills(info._refSkills)
        

    end

    return false
end

function _M:canUseTrapLater(card)
    local skill = card._skills[1]
    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0

    local opponent = self._opponent

    if self._player == BattleData.PlayerType.ai then return false end
    
    return true
end

function _M:canTrapEffect(trapCard)
    if self._disableTrapBy4127 then return false end
    if #trapCard._owner:getBattleCardsBySkills('S', {7035}) > 0 then return true end
    return #trapCard._owner:getBattleCardsBySkills('B', {6008}) + #trapCard._owner._opponent:getBattleCardsBySkills('B', {6008}) == 0
end

function _M:canTriggerTrap(trapCard)
    if trapCard._owner._isTrapTriggerDisabled then return false end
    return self:canTrapEffect(trapCard)
end

function _M:canTriggerTrapWhenStatusChange(trapCard, actionCard)
    --[[
    if self._saved._normalStatus == BattleData.Status.claim_attack then
        if id == 12001 then return card:isMonster() 
        end
    else
    ]]

    if not self:canTriggerTrap(trapCard) then return false end

    local skill = trapCard._skills[1]
    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0
    local opponent = self._opponent

    -----------------------------
    -- 11. oppo summon monster
    if id == 5029 or id == 5099 then 
        return B.isOppoSummon(trapCard, actionCard)

    -- 11_01
    elseif id == 5013 then 
        return B.isOppoSummon(trapCard, actionCard) and actionCard._atk <= val and #actionCard._owner:getBattleCardsByInfoId('HP', actionCard._infoId) > 0

    -- 11_02
    elseif id == 5085 then 
        return B.isOppoSummon(trapCard, actionCard) and #self:filterCanChangeToBoardCards(self:getBattleCardsByCategoryAndNature('G', info._refCards[1], info._refCards[2])) > 0
    
    -----------------------------
    -- 12. oppo special summon monster
    elseif id == 5076 then
        return B.isOppoSpecialSummon(trapCard, actionCard)

    -- 12_01
    elseif id == 5092 then 
        return B.isOppoSpecialSummon(trapCard, actionCard) and actionCard._atk >= val

    -- 12_02
    elseif id == 5139 then 
        return B.isOppoSpecialSummon(trapCard, actionCard) and #self:filterCanChangeToBoardCards(self:getBattleCardsByCategory('H', info._refCards[1])) > 0

    -----------------------------
    -- 13. oppo normal summon monster
    elseif id == 5033 then
        return B.isOppoNormalSummon(trapCard, actionCard)

    -- 13_01
    elseif id == 5023 then 
        return B.isOppoNormalSummon(trapCard, actionCard) and #self:filterCanChangeToBoardCards(B.filterInNatureCards(self:getBattleCardsByMaxStar('H', val), info._refCards[1])) > 0

    -- 13_02
    elseif id == 5078 then 
        return B.isOppoNormalSummon(trapCard, actionCard) and #self:filterCanChangeToBoardCards({actionCard}) > 0

    -----------------------------
    -- 21. oppo trap triggering
    elseif id == 5002 or id == 5098 then 
        return B.isOppoTrapTriggering(trapCard, actionCard)

    -- 21_01
    elseif id == 5019 then 
        
    -- 21_02
    elseif id == 5132 then 
        return B.isOppoTrapTriggering(trapCard, actionCard) and self._fortress._hp > val

    -----------------------------
    -- 22. oppo magic casting
    elseif id == 5077 then 
        return B.isOppoMagicCasting(trapCard, actionCard)

    -- 22_01. oppo magic casting on self monster
    elseif id == 5022 then
        return B.isOppoMagicCastingOnSelfMonster(trapCard, actionCard)

    -- 22_03
    elseif id == 5095 then 
        return B.isOppoMagicCasting(trapCard, actionCard) and actionCard._infoId == info._refCards[1]

    -----------------------------
    -- 23. oppo trap or magic
    elseif id == 5020 then 
        return B.isOppoTrapTriggering(trapCard, actionCard) or B.isOppoMagicCasting(trapCard, actionCard)

    -- 23_01. oppo trap or magic on self monster
    elseif id == 5086 then
        return (actionCard._info and actionCard._info._targetType == 1 and B.isOppoTrapTriggeringOnSelfMonster(trapCard, actionCard)) or B.isOppoMagicCastingOnSelfMonster(trapCard, actionCard)

    -----------------------------
    -- 31. self monster destroyed

    -- 31_01
    elseif id == 5017 then 
        return B.isSelfMonsterDestroyed(trapCard, actionCard) and actionCard._destStatus == BattleData.CardStatus.grave and actionCard._dieByEffect and #self:filterCanChangeToBoardCards(self:getBattleCardsByMaxStar('P', val)) > 0

    -- 31_02
    elseif id == 5096 then 
        return B.isSelfMonsterDestroyed(trapCard, actionCard) and actionCard._owner:canSpecialSummon(actionCard)
        
    -- 31_03
    elseif id == 5097 then 
        if B.isSelfMonsterDestroyed(trapCard, actionCard) and actionCard._destStatus == BattleData.CardStatus.grave then
            local card = self:randomOne(B.filterToOppoBoardCards(B.filterDyingCards(opponent:getBattleCards('B'), false), false))
            if card ~= nil then
                trapCard._trapTarget2 = card
                return true    
            end
        end

    -- 31_04
    elseif id == 5140 then 
        return B.isSelfMonsterDestroyed(trapCard, actionCard) and actionCard._info._category == info._refCards[1] and #self:filterCanChangeToBoardCards(B.filterInCategoryCards(self:getBattleCardsByMaxStar('P', val), info._refCards[1])) > 0

            
    -- 32. self card destoryed
    
    -- 32_01
    elseif id == 5094 then 
        if B.isSelfCardDestroyed(trapCard, actionCard) and actionCard._dieByEffect then

        end

    -- 33. self card left board
    
    -- 33_01
    elseif id == 5148 then
        return B.isSelfMonsterLeftBoard(trapCard, actionCard) and actionCard._destStatus == BattleData.CardStatus.leave 
            and (actionCard._info._category == info._refCards[1] or actionCard._info._category == info._refCards[2] or actionCard._info._category == info._refCards[3])
            and #self:getBattleCardsByType('P', Data.CardType.monster) > 0

    -----------------------------
    -- 41. self fortress damaged
    elseif id == 5035 then 
        return B.isSelfFortressDamaged(trapCard, actionCard) and #self:filterCanChangeToBoardCards(B.filterAtkLessThanCards(self:getBattleCardsByCategoryAndNature('P', info._refCards[1], info._refCards[2]), self._fortress._lastDamage)) > 0

    -----------------------------
    -- 51. self & opponent summon
    elseif id == 8003 then 
        return B.isSummon(actionCard) and #self:getSameNameBoardCards() > 0

    -- 51_01
    elseif id == 8035 then 
        return B.isSummon(actionCard) and actionCard._info._nature ~= info._refCards[1] and #self:getBattleCardsByNature('B', info._refCards[1]) > 0

    -- 61. self & opponent trap triggering

    -- 61_01. self & opponent trap triggering with trap type
    elseif id == 8032 then 
        
    -- 71. opponent deal
    elseif id == 5083 then 
        return B.isOppoDeal(trapCard, actionCard)

    -- 71_01. opponent deal in deal macrostatus
    elseif id == 5138 then 
        return B.isOppoDeal(trapCard, actionCard) and actionCard._owner._macroStatus == BattleData.Status.deal

    -- 71_02. opponent deal not in deal macrostatus
    elseif id == 5142 then 
        return B.isOppoDeal(trapCard, actionCard) and actionCard._owner._macroStatus ~= BattleData.Status.deal and (actionCard._sourceStatus == BattleData.CardStatus.pile or actionCard._sourceStatus == BattleData.CardStatus.grave) and #self._pileCards > 0

    end

    return false
end

function _M:canTriggerTrapWhenRoundBegin(trapCard)
    if not self:canTriggerTrap(trapCard) then return false end

    local skill = trapCard._skills[1]
    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0
    local opponent = self._opponent

    if skill._id == 8004 then return false 

    end

    if B.skillHasMode(skill, Data.SkillMode.round_begin) then return true end

    return false
end

function _M:canTriggerTrapWhenOppoRoundBegin(trapCard)
    if not self:canTriggerTrap(trapCard) then return false end
    
    local skill = trapCard._skills[1]
    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0
    local opponent = self._opponent

    if skill._id == 5084 then return #trapCard._owner:getBattleCardsByCategoryAndNature('B', info._refCards[1], info._refCards[2]) > 0
    end

    if B.skillHasMode(skill, Data.SkillMode.oppo_round_begin) then return true end

    return false
end

function _M:addMultiCardsToBoard(cards, cid, sid, mode, statusVal)
    local casted = false
    local dirtyPos = {}
    for i = 1, #cards do
        local card = cards[i]
        if card ~= nil then
            local pos = self:getEmptyBoardPos(card)
            if pos == nil then break end
            if self:canSpecialSummon(card) then
                self:setCardStatus(card, BattleData.CardStatus.board, cid, sid, mode, statusVal)
                dirtyPos[pos] = card._status
                self._boardCards[pos] = card
                card._status = BattleData.CardStatus.board
                casted = true
             end
        end
    end
    for k, v in pairs(dirtyPos) do local card = self._boardCards[k] self._boardCards[k] = nil card._status = v end
    return casted
end

function _M:swapHandPileCards(handCards, returnCount, cid, sid, mode, statusVal)
    local casted = false
    local pileCards = self:getBattleCards('P')
    local returnCards = self:randomTable(self:filterCanChangeToHandCards(B.mergeTable({handCards, pileCards})), returnCount)
    for i = 1, #returnCards do returnCards[i]._markTemp = true end
    for i = 1, #handCards do
        local card = handCards[i]
        self:setCardStatus(card, BattleData.CardStatus.pile, cid, sid, mode)
        if card._markTemp then
            self:setCardStatus(card, BattleData.CardStatus.hand, cid, sid, mode, nil, BattleData.CardStatus.pile)
            card._markTemp = nil
        end
        casted = true
    end
    for i = 1, #returnCards do
        local card = returnCards[i]
        if card._markTemp then
            self:setCardStatus(card, BattleData.CardStatus.hand, cid, sid, mode)
            card._markTemp = nil
            casted = true
        end
    end
    return casted
end

return _M