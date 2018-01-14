local _M = class("PlayerExpedition")

function _M:ctor()
    self._troopInfos = {}
    self._chests = {}  
    self._isRefreshed = false  
end

function _M:clear()
    self._isRefreshed = false
end

function _M:refresh(pbExpedition)
    self._players = {}
    self._troopInfos = {}
    self._chests = {}
    self._isRefreshed = true

    self._reliveTimes = pbExpedition.recover_count
    self._chapter = pbExpedition.chapter
    self._sweepChapter = pbExpedition.sweep_chapter

    for _, troop in ipairs(pbExpedition.troops) do
        local troopInfo = ClientData.pbTroopToTroop(troop)
        table.insert(self._troopInfos, troopInfo)
        table.insert(self._players, require("User").create(troop.info))
    end  
    
    for _, chest in ipairs(pbExpedition.chests) do  
        table.insert(self._chests, {_id = chest.id, _opened = chest.opened})
    end   
end

function _M:setCardDead(troopIndex, cardId, cardType)
    local troopInfo = self._troopInfos[troopIndex]
    if troopInfo ~= nil then
        for i = 1, #troopInfo do
            local card = troopInfo[i]
            if card._id == cardId and card._type == cardType then
                card._isDead = true
                return
            end
        end
    end
end

function _M:getDropDetail(type)
    local value = self._chests[type]._id

    local dropDetail
    for k, v in pairs(Data._dropInfo) do
        if v._type == 1007 and v._value == value then
            dropDetail = v
            break
        end
    end
    
    return dropDetail
end

function _M:getReliveIngot()
    return math.floor((self._reliveTimes + 1) / 2) * 10
end

return _M
