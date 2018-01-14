local Monster = require("Monster")
local _M = class("HireHero", Hero)

function _M:ctor(pbHire)
    if pbHire then
        self._guid = pbHire.id
        self._ownerId = pbHire.owner_id

        local weapon, armor
        for _, card in ipairs(pbHire.cards) do
            local cardType = Data.getType(card.info_id)
            if cardType == Data.CardType.monster then
                _M.super.ctor(self, card.info_id, card)
            elseif cardType == Data.CardType.weapon then
                weapon = require("EquipCard").create(card.info_id, card)
            elseif cardType == Data.CardType.armor then
                armor = require("EquipCard").create(card.info_id, card)
            end
        end

        self._weapon = weapon
        self._armor = armor

        local timestamp
        if pbHire.timestamp then
            timestamp = pbHire.timestamp / 1000
        end

        self:init(self._ownerId == P._id, timestamp)
    end

    self:dirtyFightingValue()
end

function _M.addHire(hero)
    local hire = _M.new()
    hire._infoId = hero._infoId

    hero:clone(nil, hire)

    hire:init(true)
    return hire
end

function _M:init(isMyHire, timestamp)
    self._info = Data.getInfo(self._infoId)
    self._type = Data.CardType.monster

    self._isMyHire = isMyHire
    self._timestamp = timestamp or ClientData.getCurrentTime()

    -- Use weapon and armor instead of ids
    self._weaponId = 0
    self._armorId = 0
    
    self._troopPos = {}
    for i = 1, Data.TroopIndex.num do
        self._troopPos[i] = 0
    end
end

function _M:calcMyHireRewards()
    local fight = self:getFightingValue()
    local hour = (ClientData.getCurrentTime() - self._timestamp) / 3600
    return math.min(math.floor(fight * 25 * hour / 24), 500000)
end

function _M:calcHireCost()
    local fight = self:getFightingValue()
    return math.floor(fight * 10)
end

function _M:isNew()
    return false
end

function _M:isHired()
    if self._isHired == nil then
        self._isHired = false

        local hires = P._playerUnion._hireMembers
        for _, hire in ipairs(hires) do
            if hire == self._ownerId then
                self._isHired = true
                break
            end
        end
    end

    return self._isHired
end

function _M:claimReward()
    local curTime = ClientData.getCurrentTime()
    local hour = (curTime - self._timestamp) / 3600
    if hour < 1 then
        return 0
    else
        local gold = self:calcMyHireRewards()
        P:changeResource(Data.ResType.gold, gold)

        self._timestamp = curTime

        return gold
    end
end

return _M