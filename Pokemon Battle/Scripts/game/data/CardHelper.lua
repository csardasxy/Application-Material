local _M = {}

-- The "Card" structure passed here must contain the following fields
-- @field       _type               indicates the card type
-- @field       _info               indicates the card info structure
-- @field       _level              indicates the card level
-- @field       _evolution          indicates evolution level for hero and equipment card
--

function _M.getCardQuality(card)
    return card._info._quality or -1
end

function _M.getCardReputation(card)
    if card._type == Data.CardType.weapon or card._type == Data.CardType.armor then
        return 0
    end

    return card._info._reputation
end

function _M.getCardCost(card)
    if card:isMonster() then
        return card._info._cost
    else
        return 0
    end
end

function _M.getCardStar(card, star)
    if star == nil then
        star = card._info._star or 0
    end

    return star
end

function _M.getSkillFightingFactor(id, level, maxLevel, cardType, cardQuality)
    local info = Data._skillInfo[id]

    level = level or 1
    level = info._val[level] > 0 and level or 1

    maxLevel = info._val[level] > 0 and maxLevel or 2

    if cardType == Data.CardType.monster then
        return Data.SkillOutputParam * Data.SkillQualityParam[info._quality] / 5 * (level / maxLevel)
    else
        return Data.SkillOutputParam * Data.CardQualityParam[cardQuality] * (level / maxLevel)
    end
end

function _M.getSkillMaxLevel(infoId)
    local info = Data._skillInfo[infoId]
    for i = 1, #info._val do
        if info._val[i] == 0 then
            return math.max(1, i - 1)
        end
    end

    return #info._val
end

function _M.getCardsTotalCount(cards)
    local count = 0
    for i = 1, #cards do
        count = count + cards[i]._num
    end
    return count
end

CardHelper = _M
return _M