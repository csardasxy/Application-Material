local _M = class("BattleAi")
BattleAi = _M

function _M:ctor(player)
    self._player = player
end

------------------------------------------------------------------------------
-- use card function
------------------------------------------------------------------------------

function _M:aiUseCard()
    local player = self._player

    -- 1. actioned
    if player._isMonsterActioned then
        return BattleData.UseCardType.round, {player._round}
    end

    -- 2. swap when round begin
    if player._boardCards[1] == nil then
        local card = player:getBattleCards('B')[1]
        return BattleData.UseCardType.swap, {card._id}
    end

    -- 11. level up monster
    for i = 1, #player._handCards do
        local card = player._handCards[i]
        if card:isMonster() and card._info._level > 0 then
            local canUse, ids = player:canUseMonster(card, true)
            if canUse then return BattleData.UseCardType.h2b, ids end 
        end
    end

    -- 12. base monster
    for i = 1, #player._handCards do
        local card = player._handCards[i]
        if card:isMonster() and card._info._level == 0 then
            local canUse, ids = player:canUseMonster(card, true)
            if canUse then return BattleData.UseCardType.h2b, ids end 
        end
    end

    -- 21. magic power
    for i = 1, #player._handCards do
        local card = player._handCards[i]
        if card._type == Data.CardType.magic and card._info._type == Data.MagicTrapType.power then
            local canUse, ids = player:canUseMagic(card, true)
            if canUse then return BattleData.UseCardType.spell, ids end 
        end
    end

    -- 22. magic other
    

    -- 31. power-free spells
    local boardCards = player:getBattleCards('B')
    table.sort(boardCards, function(a, b) 
        if a._pos == 1 then return false
        elseif b._pos == 1 then return true
        else return a._pos < b._pos
        end
    end)
    for i = 1, #boardCards do
        local card = boardCards[i]
        for j = 1, #card._skills do
            local skill = card._skills[j]
            local skillType = Data.getSkillType(skill._id)
            if skillType ~= Data.SkillType.monster_attack then
                local canUse, ids = player:canUseMonsterSpell(card, skill)
                if canUse then return BattleData.UseCardType.spell, ids end 
            end
        end
    end

    -- 41. main monster
    local card = player._boardCards[1]
    if card ~= nil then
        for j = #card._skills, 1, -1 do
            local skill = card._skills[j]
            local skillType = Data.getSkillType(skill._id)
            if skillType == Data.SkillType.monster_attack then
                local canUse, ids = player:canUseMonsterSpell(card, skill)
                if canUse then return BattleData.UseCardType.spell, ids end 
            end
        end
    end

    -- 51. drop card
    if player:isNeedDrop() then
        return self:aiDropCard()
    end

    -- 61. round end
    return BattleData.UseCardType.round, {player._round}
end

function _M:aiChooseMainWhenInitialDeal()
    local card = B.getMaxHpCard(self._player:getBattleCardsByLevel('H', 0))
    return BattleData.UseCardType.init_b1, {card._id}
end

function _M:aiChooseBackupWhenInitialDeal()
    local cards = self._player:getBattleCardsByLevel('H', 0, Data.CARD_MAX_LEVEL, self._player._boardCards[1])
    local ids = {}
    for i = 1, #cards do
        ids[#ids + 1] = cards[i]._id
    end
    return BattleData.UseCardType.init_bx, ids
end

function _M:aiChooseMainWhenRoundEnd()
    local card = B.getMaxHpCard(self._player:getBattleCards('B'))
    return BattleData.UseCardType.swap, {card._id}
end

function _M:aiDropCard()
    return BattleData.UseCardType.drop, {self._player._handCards[#self._player._handCards]}
end

return _M