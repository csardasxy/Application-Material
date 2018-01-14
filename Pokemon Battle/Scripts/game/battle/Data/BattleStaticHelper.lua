local _M = PlayerBattle

-----------------------------------
-- create card
-----------------------------------

function _M.createCard(infoId, level)
    local card = BattleCard.new(infoId, level)

    card:resetOnce()
    
    card._status = BattleData.CardStatus.leave
    
    return card
end

function _M.createCardByEvent(vals)
    local card = _M.createCard(vals.c.id, 1)
    return card
end


-----------------------------------
-- create skill
-----------------------------------

function _M.createSkill(infoId, level, owner)
    local info = Data._skillInfo[infoId]
    return 
    { 
        _id = infoId, 
        _level = level, 
        _maxLevel = math.min(level, CardHelper.getSkillMaxLevel(infoId)), 
        _modes = info._modes, 
        _priority = info._priority,
        _count = info._count,
        _owner = owner,
        _castTimes = 0,
        _totalCastedTimes = 0,
    }
end


-----------------------------------
-- skill helper functions
-----------------------------------

function _M.skillHasMode(skill, mode)
    for i = 1, #skill._modes do
        if skill._modes[i] == mode then
            return true
        end
    end
    if mode == Data.SkillMode.bcs2gl then
        return _M.skillHasMode(skill, Data.SkillMode.bcs2_)
    elseif mode == Data.SkillMode.g2b then
        return _M.skillHasMode(skill, Data.SkillMode.using)
    else
        return false
    end
end

function _M.skillInfoHasRemoveMode(skillInfo, removeMode)
    for i = 1, #skillInfo._removeMode do
        if skillInfo._removeMode[i] == removeMode then
            return true
        end
    end
    return false
end

function _M.isMergeSkill(skill)
    return skill._id == 4048
end

function _M.isDamageSkill(skill)
    local info = Data._skillInfo[skill._id]
    if info == nil then return false end
    return info._damageEffect[1] == 1
end

function _M.isSkillChoiceSkill(skill)
    if skill._id == 3208 then
        return #skill._owner._owner._opponent:getBattleCards('B') > 0   
    end

    return skill._id == 3037 or skill._id == 3098 or skill._id == 3108 or skill._id == 3119 or skill._id == 4007 or skill._id == 4081 or skill._id == 5081
end

function _M.isMonsterSkill(id)
    return id < 5000 
end

function _M.isEffectSkill(id)
    return id >= 50000 and id < 51000
end

function _M.isSkillModeCastedByOwner(mode)
    return mode >= Data.SkillMode.fortress_damaged
end

-----------------------------------
-- coin helper functions
-----------------------------------

function _M.throwCoin(fromCard)
    local player = fromCard._owner
    local p = 0.5
    --[[
    if player._status ~= BattleData.Status.round_end and #player:getBattleCardsBySkills('S', {7078}) > 0 then
        p = 0.75
    end
    ]]
    return player:getRandom() <= p and 1 or 0
end

function _M.throwCoins(fromCard, count)
    local result = 0
    for i = 1, count do
        result = result * 2 + B.throwCoin(fromCard)
    end
    return result
end

function _M.getCoinFaceCount(result)
    local count = 0
    for i = 1, 0xFF do
        local v = 2 ^ (i - 1)
        if band(result, v) ~= 0 then count = count + 1 end
        if v > result then break end
    end
    return count
end

-----------------------------------
-- damage helper functions
-----------------------------------

function _M.getDamageByMonster(fromCard, targetCard, skillId, val)
    val = val + (fromCard._owner._extraMonsterDamageToAll or 0)
    if targetCard._pos == 1 then
        val = val + (fromCard._owner._extraMonsterDamageToMain or 0)
    end

    if targetCard._pos == 1 then
        if not (targetCard._info._nature == Data._skillInfo[2002]._refCards[1] and #targetCard._owner:getBattleCardsBySkills('B', {2002}) > 0) then
            if targetCard._info._weakness == fromCard._info._nature then
                val = val * targetCard._info._weaknessFactor
            end
        end
        if targetCard._info._resist == fromCard._info._nature then
            if skillId ~= 1031 then
                val = math.max(0, val - targetCard._info._resistFactor)
            end
        end
    end

    local bindCard = fromCard._binds[1]
    local skill = bindCard and bindCard._skills[1]
    if skill ~= nil then
        local id = skill._id
        local info = Data._skillInfo[id]
        local val1 = info._val[1] or 0
        if id == 6002 then val = val + val1 end
    end

    local bindCard = targetCard._binds[1]
    local skill = bindCard and bindCard._skills[1]
    if skill ~= nil then
        local id = skill._id
        local info = Data._skillInfo[id]
        local val1 = info._val[1] or 0
        if id == 6003 then val = math.max(0, val - val1) end
    end

    return val
end

function _M.getDamageByEffect(fromCard, targetCard, skillId, val)
    return val
end

-----------------------------------
-- card helper functions
-----------------------------------

function _M.isAlive(card)
    return card ~= nil and card:isAlive() or false
end

function _M.getMaxHpCard(boardCards)
    local maxHpCard, maxHp = nil, -1
    for i = 1, #boardCards do
        local boardCard = boardCards[i]
        if boardCard._hp ~= nil and boardCard._hp > maxHp then
            maxHpCard = boardCard
            maxHp = boardCard._hp
        end
    end
    return maxHpCard
end

function _M.getMinHpCard(boardCards, isHurt)
    local minHpCard, minHp = nil, 0x7FFFFFFF
    for i = 1, #boardCards do
        local boardCard = boardCards[i]
        if boardCard._hp ~= nil and boardCard._hp < minHp and ((not isHurt) or (boardCard._hp < (boardCard._maxHp + boardCard._haloedMaxHpInc)))then
            minHpCard = boardCard
            minHp = boardCard._hp
        end
    end
    return minHpCard
end

function _M.getMaxAtkCard(boardCards)
    local maxAtkCard, maxAtk = nil, -1
    for i = 1, #boardCards do
        local boardCard = boardCards[i]
        if boardCard._atk ~= nil and boardCard._atk > maxAtk then
            maxAtkCard = boardCard
            maxAtk = boardCard._atk
        end
    end
    return maxAtkCard
end

function _M.getMinAtkCard(boardCards)
    local minAtkCard, minAtk = nil, 0x7FFFFFFF
    for i = 1, #boardCards do
        local boardCard = boardCards[i]
        if boardCard._atk ~= nil and boardCard._atk < minAtk then
            minAtkCard = boardCard
            minAtk = boardCard._atk
        end
    end
    return minAtkCard
end

function _M.getMaxPositiveCard(boardCards)
    local maxPositiveCard, maxPositiveValue = nil, 0
    for i = 1, #boardCards do
        local boardCard = boardCards[i]
        local positiveValue = math.max(0, math.max(boardCard._maxHpInc, boardCard._maxAtkInc))
        for i = BattleData.PositiveType.shieldBegin, BattleData.PositiveType.shieldEnd do
            positiveValue = math.max(positiveValue, boardCard:getBuffValue(true, i) * 10)
        end
        if positiveValue > maxPositiveValue then
            maxPositiveCard = boardCard
            maxPositiveValue = positiveValue
        end
    end
    return maxPositiveCard, maxPositiveValue
end

-----------------------------------
-- sort helper functions
-----------------------------------

function _M.sortCardsByAtk(cards)
    local sortedCards = {}
    for i = 1, #cards do
        sortedCards[#sortedCards + 1] = cards[i]
    end
    table.sort(sortedCards, function(a, b) 
        if a._atk ~= nil and b._atk == nil then return true
        elseif a._atk == nil and b._atk ~= nil then return false
        elseif a._atk == nil and b._atk == nil then return a._id < b._id
        elseif a._atk > b._atk then return true
        elseif a._atk < b._atk then return false
        elseif a._hp > b._hp then return true
        elseif a._hp < b._hp then return false
        else return a._id < b._id
        end
    end)
    return sortedCards
end

function _M.sortCardsByStar(cards)
    local sortedCards = {}
    for i = 1, #cards do
        if cards[i]._info._star ~= nil then
            sortedCards[#sortedCards + 1] = cards[i]
        end
    end
    table.sort(sortedCards, function(a, b) 
        if a._info._star > b._info._star then return true
        elseif a._info._star < b._info._star then return false
        elseif a._atk > b._atk then return true
        elseif a._atk < b._atk then return false
        elseif a._hp > b._hp then return true
        elseif a._hp < b._hp then return false
        else return a._id < b._id
        end
    end)
    return sortedCards
end

-----------------------------------
-- split helper functions
-----------------------------------

function _M.splitCardsByCategory(cards)
    local categoryCards = {}
    for i = 1, #cards do
        local card = cards[i]
        local category = card._info._category
        if categoryCards[category] ~= nil then
            categoryCards[category][#categoryCards[category] + 1] = card
        else
            categoryCards[category] = {card}
        end
    end
    return categoryCards
end

-----------------------------------
-- filter helper functions
-----------------------------------

function _M.filterInTypeCards(cards, cardType)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._type == cardType then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterInCategoryCards(cards, category)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._info._category == category then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterNotInCategoryCards(cards, category)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._info._category ~= category then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterInNatureCards(cards, nature)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._info._nature == nature then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterNotInNatureCards(cards, nature)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._info._nature ~= nature then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterInKeywordCards(cards, keyword)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._info._keyword == keyword then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterInStatusCards(cards, status)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._status == status then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterAtkEqualCards(cards, atk)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._atk == atk then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterDefEqualCards(cards, def)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._hp == def then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterAtkLessThanCards(cards, atk)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._atk ~= nil and card._atk <= atk then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterDefLessThanCards(cards, def)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._hp ~= nil and card._hp <= def then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterOriginAtkLessThanCards(cards, atk)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if not card:isAtkHide() and card._maxAtk ~= nil and card._maxAtk <= atk then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterOriginDefLessThanCards(cards, def)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if not card:isDefHide() and card._maxHp ~= nil and card._maxHp <= def then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterBindedCards(cards)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if #card._binds > 0 then 
            filteredCards[#filteredCards + 1] = card 
        end
    end
    return filteredCards
end

function _M.filterNotBindedCards(cards, infoId, isAi)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if ((not isAi) or (not card:hasShieldInType(BattleData.PositiveType.shieldMagic) and not card:hasSkills({6009}))) 
            and not card:isBinded(infoId) then 
            filteredCards[#filteredCards + 1] = card 
        end
    end
    return filteredCards
end

function _M.filterCanActionCards(cards)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card:canAction() then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterCannotActionCards(cards)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if not card:canAction() then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterHasSameInGraveCards(cards)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if #card._owner:getBattleCards('G', card._infoId) + #card._owner._opponent:getBattleCards('G', card._infoId) > 0 then 
            filteredCards[#filteredCards + 1] = card 
        end
    end
    return filteredCards
end

function _M.filterInMagicTrapTypeCards(cards, magicTrapType)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._info._type == magicTrapType then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterAtkBiggerCards(cards, isAtkBigger)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if (isAtkBigger and (card._atk > card._hp)) or (not isAtkBigger and (card._atk < card._hp)) then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterCanSpecialSummonCards(cards, ignoreByAnotherCard)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._owner:canSpecialSummon(card, ignoreByAnotherCard) then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterNormalSummonCards(cards, isNormal)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if (isNormal and card._summonStatusVal == BattleData.CardStatusVal.h2b_normal) or (not isNormal and card._summonStatusVal ~= BattleData.CardStatusVal.h2b_normal) then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterTrapInTypeCards(cards, trapType)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        local info = Data._trapInfo[card._infoId]
        if info._type == trapType then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterTrapNotInTypeCards(cards, trapType)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        local info = Data._trapInfo[card._infoId]
        if info._type ~= trapType then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end


function _M.filterDyingCards(cards, isDying)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card:isDying() == isDying then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterUsingCards(cards, isUsing)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card:isUsing() == isUsing then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterToOppoBoardCards(cards, isToOppoBoard)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card:isToOppoBoard() == isToOppoBoard then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterNoSkillCards(cards, skillId)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if skillId ~= nil then
            if not card:hasSkills({skillId}) then filteredCards[#filteredCards + 1] = card end
        else
            if #card._skills == 0 then filteredCards[#filteredCards + 1] = card end
        end
    end
    return filteredCards
end

function _M.filterNotEqualInfoIdCards(cards, infoId)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._infoId ~= infoId then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterNoShieldCards(cards, shieldType)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if not card:hasShieldInType(shieldType) then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterNoShieldExCards(cards, shieldType)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if not card:hasShieldExInType(shieldType) then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterEffectCards(cards, isEffectMonster)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if (isEffectMonster and #card._skills > 0) or (not isEffectMonster and #card._skills == 0) then 
            filteredCards[#filteredCards + 1] = card 
        end
    end
    return filteredCards
end

function _M.filterNotViewedCards(cards)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if not card._trapViewed then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterSameAtkCards(cards)
    local filteredCards = {}
    local atkCards = {}
    for i = 1, #cards do
        local card = cards[i]
        local atk = card._atk
        if atk ~= nil then
            if atkCards[atk] == nil then atkCards[atk] = {card}
            else atkCards[atk][#atkCards[atk] + 1] = card
            end
        end
    end
    for k, v in pairs(atkCards) do
        if #v > 1 then
            for i = 1, #v do
                filteredCards[#filteredCards + 1] = v[i]
            end
        end
    end
    return filteredCards
end

function _M.filterTokenCards(cards)
    local filteredCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if card._info._option ~= nil and band(card._info._option, Data.CardOption.is_token) > 0 then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterStarLessThanSumOfOthers(cards1, cards2)
    local filteredCards = {}
    for i = 1, #cards1 do
        local card = cards1[i]
        local star = 0
        for i = 1, #cards2 do
            if cards2[i] ~= card then
                star = star + (cards2[i]._info._star or 0)
            end
        end
        if star >= card._info._star then filteredCards[#filteredCards + 1] = card end
    end
    return filteredCards
end

function _M.filterFirstCards(cards, count)
    local filteredCards = {}
    for i = 1, math.min(count, #cards) do
        local card = cards[i]
        filteredCards[#filteredCards + 1] = card
    end
    return filteredCards
end

-----------------------------------
-- trap helper functions
-----------------------------------

function _M.isSummon(actionCard)
    return actionCard:isMonster() and actionCard._destStatus == BattleData.CardStatus.board and actionCard._statusVal ~= BattleData.CardStatusVal.b2b_oppo_forever and actionCard._statusVal ~= BattleData.CardStatusVal.e2b_5039
end

function _M.isNormalSummon(actionCard)
    return B.isSummon(actionCard) and actionCard._statusVal == BattleData.CardStatusVal.h2b_normal
end

function _M.isSpecialSummon(actionCard)
    return B.isSummon(actionCard) and actionCard._statusVal ~= BattleData.CardStatusVal.h2b_normal
end

--

function _M.isOppoSummon(trapCard, actionCard)
    return trapCard._owner ~= actionCard._owner and B.isSummon(actionCard) 
end

function _M.isOppoNormalSummon(trapCard, actionCard)
    return trapCard._owner ~= actionCard._owner and B.isNormalSummon(actionCard) 
end

function _M.isOppoSpecialSummon(trapCard, actionCard)
    return trapCard._owner ~= actionCard._owner and B.isSpecialSummon(actionCard) 
end

--

function _M.isDeal(actionCard)
    return actionCard._sourceStatus == BattleData.CardStatus.pile and actionCard._destStatus == BattleData.CardStatus.hand
end

function _M.isOppoDeal(trapCard, actionCard)
    return trapCard._owner ~= actionCard._owner and B.isDeal(actionCard)
end

--

function _M.isTrapTriggering(actionCard)
    return actionCard._type == Data.CardType.trap and (actionCard._destStatus == BattleData.CardStatus.show or actionCard._statusVal == BattleData.CardStatusVal.h2g_trap)
end

function _M.isOppoTrapTriggering(trapCard, actionCard)
    return trapCard._owner ~= actionCard._owner and B.isTrapTriggering(actionCard)
end

function _M.isOppoTrapTriggeringOnSelfMonster(trapCard, actionCard)
    if not B.isOppoTrapTriggering(trapCard, actionCard) then return false end
    local trapTarget = actionCard:hasSkills({5094, 5097}) and actionCard._trapTarget2 or actionCard._trapTarget
    return trapTarget ~= nil and trapTarget:isMonster() and trapTarget._owner == trapCard._owner
end

function _M.isOppoTrapTriggeringOnOppoMonster(trapCard, actionCard)
    if not B.isOppoTrapTriggering(trapCard, actionCard) then return false end
    local trapTarget = actionCard:hasSkills({5094, 5097}) and actionCard._trapTarget2 or actionCard._trapTarget
    return trapTarget ~= nil and trapTarget:isMonster() and trapTarget._owner == actionCard._owner
end

--

function _M.isMagicCasting(actionCard)
    return actionCard._type == Data.CardType.magic and (actionCard._destStatus == BattleData.CardStatus.show or actionCard._statusVal == BattleData.CardStatusVal.h2g_magic)
end

function _M.isOppoMagicCasting(trapCard, actionCard)
    return trapCard._owner ~= actionCard._owner and B.isMagicCasting(actionCard) and Data._skillInfo[actionCard._skills[1]._id]._isIgnoreDefend ~= 2 
end

function _M.isOppoMagicCastingOnSelfMonster(trapCard, actionCard)
    if not B.isOppoMagicCasting(trapCard, actionCard) then return false end
    if actionCard:hasSkills({4129, 7057}) then return true end
    return actionCard._magicTarget ~= nil and actionCard._magicTarget:isMonster() and actionCard._magicTarget._owner == trapCard._owner
end

function _M.isOppoMagicCastingOnOppoMonster(trapCard, actionCard)
    return B.isOppoMagicCasting(trapCard, actionCard) and actionCard._magicTarget ~= nil and actionCard._magicTarget:isMonster() and actionCard._magicTarget._owner == actionCard._owner
end

--

function _M.isMonsterLeftBoard(actionCard)
    return actionCard:isMonster() and actionCard._sourceStatus == BattleData.CardStatus.board and actionCard._destStatus ~= BattleData.CardStatus.board
end

function _M.isSelfMonsterLeftBoard(trapCard, actionCard)
    return trapCard._owner == actionCard._owner and B.isMonsterLeftBoard(actionCard)
end

function _M.isMonsterDestroyed(actionCard)
    return B.isMonsterLeftBoard(actionCard) and actionCard._statusVal ~= BattleData.CardStatusVal.b2g_sacrifice
        and ((actionCard._destStatus == BattleData.CardStatus.grave or actionCard._destStatus == BattleData.CardStatus.leave))
end

function _M.isSelfMonsterDestroyed(trapCard, actionCard)
    return trapCard._owner == actionCard._owner and B.isMonsterDestroyed(actionCard)
end

--

function _M.isMagicLeftBoard(actionCard)
    return actionCard._type == Data.CardType.magic and actionCard._sourceStatus == BattleData.CardStatus.show and actionCard._destStatus ~= BattleData.CardStatus.show
end

function _M.isMagicDestroyed(actionCard)
    return B.isMagicLeftBoard(actionCard) and (actionCard._destStatus == BattleData.CardStatus.grave or actionCard._destStatus == BattleData.CardStatus.leave)
end

--

function _M.isTrapLeftBoard(actionCard)
    return false
end

function _M.isTrapDestroyed(actionCard)
    return false
end

-- 

function _M.isCardLeftBoard(actionCard)
    return B.isMonsterLeftBoard(actionCard) or B.isMagicLeftBoard(actionCard) or B.isTrapLeftBoard(actionCard)
end

function _M.isCardDestroyed(actionCard)
    return B.isMonsterDestroyed(actionCard) or B.isMagicDestroyed(actionCard) or B.isTrapDestroyed(actionCard)
end

function _M.isSelfCardDestroyed(trapCard, actionCard)
    return trapCard._owner == actionCard._owner and B.isCardDestroyed(actionCard) 
end

--

function _M.isFortressDamaged(actionCard)
    return actionCard._type == Data.CardType.fortress and actionCard._sourceStatus == BattleData.CardStatus.fortress and actionCard._destStatus == BattleData.CardStatus.fortress and actionCard._statusVal == BattleData.CardStatusVal.f2f_fortress_damaged
end

function _M.isSelfFortressDamaged(trapCard, actionCard)
    return trapCard._owner == actionCard._owner and B.isFortressDamaged(actionCard)
end

-----------------------------------
-- table helper functions
-----------------------------------

function _M.mergeTable(tables)
    local mergeTable = {}
    for i = 1, #tables do
        for j = 1, #tables[i] do
            mergeTable[#mergeTable + 1] = tables[i][j]
        end
    end
    return mergeTable
end 

function _M.reverseTable(table)
    local reverseTable = {}
    for i = #table, 1, -1 do
        reverseTable[#reverseTable + 1] = table[i]
    end
    return reverseTable
end

function sub(head, index, r, k, a)
    for i = head, #a + index - k do
        if(index < k) then    
            r[index] = a[i]
            sub(i + 1, index + 1, r, k, a)
        elseif (index == k) then
            r[index ] = a[i]
            fullPermutation(r)
        end
    end 
end 

function fullsub(t, start, end1, r)
    r = {}
    start = start or 1
    end1 = end1 or #t
    for tmpi = start, end1 do
        sub(1, 1, r, tmpi, t)
    end
end

function isSwap(fullArray, start, end1)
    for tmpi = start, end1 - 1 do 
        if fullArray[tmpi] == fullArray[end1] then    
            return false
        end
    end
    return true
end

function fullPermutation(fullArray, start, end1, permutatedTables)
    local ret = ""
    if start >= end1 then
        local permutatedTable = {}
        for tmpii = 1, #fullArray do 
            permutatedTable[#permutatedTable + 1] = fullArray[tmpii]
        end 
        permutatedTables[#permutatedTables + 1] = permutatedTable
        return  
    end
    for tmpi = start, end1 do 
        if isSwap(fullArray, start, tmpi) then
            fullArray[tmpi], fullArray[start] = fullArray[start], fullArray[tmpi] 
            fullPermutation(fullArray, start + 1, end1, permutatedTables)
            fullArray[tmpi] ,fullArray[start]=fullArray[start],fullArray[tmpi]
        end
    end
end

function _M.permutateTable(table)
    local permutatedTables = {}
    fullPermutation(table, 1, #table, permutatedTables)
    return permutatedTables
end


-----------------------------------
-- other helper functions
-----------------------------------

function _M.isStatusChange(count, status, value, oldStatus, oldValue)
    for i = 1, count do
        if status[i] ~= oldStatus[i] then return true end
        if type(value[i]) ~= type(oldValue[i]) then return true end
        if type(value[i]) == 'number' and value[i] ~= oldValue[i] then return true end
        if type(value[i]) == 'table' then    
            if #value[i] ~= #oldValue[i] then return true end
            local sum, oldSum = 0, 0
            for j = 1, #value[i] do
                sum = sum + value[i][j]
                oldSum = oldSum + oldValue[i][j]
            end
            if sum ~= oldSum then return true end
        end
    end
    return false
end

function _M.parseOperations(opIds, ignoreTimestamp)
    local ops = {}
    local i = 1
    while true do
        local op = {}

        if not ignoreTimestamp then
            op._timestamp = opIds[i] or 0
            i = i + 1
        end

        op._type = opIds[i] or 0
        i = i + 1
        if op._type == 0 then break end
        
        op._ids = {}
        local idCount = opIds[i] or 0
        if idCount > 0 then
            for j = 1, idCount do
                op._ids[j] = opIds[i + j]
            end
        end
        i = i + idCount + 1

        ops[#ops + 1] = op
    end

    return ops
end

