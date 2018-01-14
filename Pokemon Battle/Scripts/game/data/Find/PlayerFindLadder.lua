local _M = class("PlayerFindLadder")

_M.MAX_TROOP_COUNT = 40
_M.MAX_BATTLE_COUNT = 12
_M.MAX_LOSE_COUNT = 3
_M.TOTAL_CARD_COUNT = 5
_M.SELECT_CARD_COUNT = 2


function _M:ctor()
    self:clear()

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    --lc.addEventListener(Data.Event.prop_dirty, function(event) self:syncChests() end)
end

function _M:clear()
    self._hasTicket = false
    self._step = 0
    self._characterId = 0

    self._cardsPool = {}
    self._characters = {}
    self._troopCards = {}
    self._selected = {}
    self._winCount = 0
    self._loseCount = 0
    self._chest = {_infoId = 0, _isOpened = false}
end

function _M:init(pbLadder)
    self._hasTicket = pbLadder.has_ticket
    self._characterId = pbLadder:HasField("char_id") and pbLadder.char_id or 0
    self._step = pbLadder.step

    self._cardsPool = {}
    for i = 1, #pbLadder.pool do
        self._cardsPool[i] = pbLadder.pool[i]
    end

    self._troopCards = {}
    for i = 1, #pbLadder.cards do
        local pb = pbLadder.cards[i]
        self._troopCards[i] = {_infoId = pb.info_id, _num = pb.num}
    end

    self._winCount = math.min(12, pbLadder.win)
    self._loseCount = pbLadder.lose

    self._chest = {_infoId = 0, _isOpened = false}
    if pbLadder:HasField("chest") then
        local pb = pbLadder.chest
        self._chest._infoId = pb.id
        self._chest._isOpened = pb.opened
    end

    self._characters = {}
    for i = 1, #pbLadder.chars do
        self._characters[i] = pbLadder.chars[i]
    end

    self._selected = {}
    for i = 1, #pbLadder.selected do
        self._selected[i] = pbLadder.selected[i] + 1
    end
end

function _M:onMsg(msg)
    local msgType = msg.type

    if msgType == SglMsgType_pb.PB_TYPE_WORLD_BUY_TICKET then
        local resp = msg.Extensions[World_pb.SglWorldMsg.world_buy_ticket_resp]

        self._characters = {}
        for i = 1, #resp do
            self._characters[i] = resp[i]
        end

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_SELECT_CHAR then
        local resp = msg.Extensions[World_pb.SglWorldMsg.world_select_char_resp]

        self._cardsPool = {}
        for i = 1, #resp do
            self._cardsPool[i] = resp[i]
        end

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_QUIT then
         local resp = msg.Extensions[World_pb.SglWorldMsg.world_quit_resp]
         for i = 1, #resp do
            self:changeChest(resp[i].info_id)
         end

    end

    return false
end

function _M:addCardToTroop(infoId, index)
    self._selected[#self._selected + 1] = index + math.floor((self._step - 1) / _M.SELECT_CARD_COUNT) * _M.TOTAL_CARD_COUNT

    local troop = self._troopCards

    for i = 1, #troop do
        local troopCard = troop[i]
        if troopCard._infoId == infoId then
            troopCard._num = troopCard._num + 1
            return
        end
    end

    troop[#troop + 1] = {_infoId = infoId, _num = 1}
end

function _M:getTroopCardCount()
    local count = 0
    local monsterCount = 0
    local magicCount = 0
    local trapCount = 0
    
    for i = 1, #self._troopCards do
        local troopCard = self._troopCards[i]
        local cardType = Data.getType(troopCard._infoId)

        count = count + troopCard._num
        if cardType == Data.CardType.monster then
            monsterCount = monsterCount + troopCard._num
        elseif cardType == Data.CardType.magic then
            magicCount = magicCount + troopCard._num
        elseif cardType == Data.CardType.trap then
            trapCount = trapCount + troopCard._num
        end
    end

    return count, monsterCount, magicCount, trapCount
end

function _M:changeChest(chestId)
    self._chest = {_infoId = chestId, _isOpened = false}
end

function _M:getSelectCards()
    local cards = {}

    -- start select on step==1
    local index = math.floor((self._step - 1) / _M.SELECT_CARD_COUNT) * _M.TOTAL_CARD_COUNT

    for i = 1, _M.TOTAL_CARD_COUNT do
        cards[i] = {
            _infoId = self._cardsPool[index + i],
            _isValid = true,
        }
    end

    for i = 1, #self._selected do
        local curIndex = self._selected[i] - index
        if curIndex > 0 and curIndex <= _M.TOTAL_CARD_COUNT then
            cards[curIndex]._isValid = false
        end
    end

    return cards
end

function _M:getSelectCardIndex(infoId)
    local cards = self:getSelectCards()

    for i = 1, #cards do
        local card = cards[i]
        if card._infoId == infoId and card._isValid then
            return i
        end
    end

    return 0
end

function _M.getLadderDuration()
    local defaultInfo, specificInfo
    for k, v in pairs(Data._activityInfo) do
        if v._type[1] == 1302 then
            if v._beginTime == '' then defaultInfo = v
            elseif ClientData.isActivityValid(v) then specificInfo = v
            end
        end  
    end
    local info = specificInfo or defaultInfo
    return info._param[1] or 0, info._param[2] or 0, info._param[3] or 0, info._param[4] or 0 
end

function _M:getIsValidTime()
    --if ClientData.isDEV() then return true end

    local hour, day, month, year = ClientData.getServerDate()
    local startHour1, finishHour1, startHour2, finishHour2 = self:getLadderDuration()
    return (hour >= startHour1 and hour < finishHour1) or ((hour >= startHour2 and hour < finishHour2))
end

function _M:getTimeTip()
    local startHour1, finishHour1, startHour2, finishHour2 = self:getLadderDuration()
    if startHour2 ~= 0 and finishHour2 ~= 0 then
        return string.format(lc.str(STR.FIND_ARENA_TIME2), startHour1, 0, finishHour1, 0, startHour2, 0, finishHour2, 0)
    else
        return string.format(lc.str(STR.FIND_ARENA_TIME), startHour1, 0, finishHour1, 0)
    end
end

return _M