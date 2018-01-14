local _M = BattleTestUi

-- battle test
-- dimens board
local SCALE = V.SCR_H / 768
local BATTLE_AREA_SPACING = 11 * SCALE
local BATTLE_AREA_HEIGHT = 180 * SCALE
local BATTLE_AREA_WIDTH_SPACING = 120 * SCALE
local BATTLE_AREA_WIDTH_SPACING2 = 160 * SCALE

local ATTACKER_CARD1_LEFT = ClientView.SCR_CW - 180 * SCALE
local DEFENDER_CARD1_LEFT = ClientView.SCR_CW + 20 * SCALE

local ATTACKER_BOARD_POS_X = {
    ATTACKER_CARD1_LEFT, 
    ATTACKER_CARD1_LEFT - BATTLE_AREA_WIDTH_SPACING * 2,
    ATTACKER_CARD1_LEFT - BATTLE_AREA_WIDTH_SPACING, 
    ATTACKER_CARD1_LEFT + BATTLE_AREA_WIDTH_SPACING2,
    ATTACKER_CARD1_LEFT + BATTLE_AREA_WIDTH_SPACING2 + BATTLE_AREA_WIDTH_SPACING,
    ATTACKER_CARD1_LEFT + BATTLE_AREA_WIDTH_SPACING2 + BATTLE_AREA_WIDTH_SPACING * 2,
}
local DEFENDER_BOARD_POS_X = {
    DEFENDER_CARD1_LEFT, 
    DEFENDER_CARD1_LEFT + BATTLE_AREA_WIDTH_SPACING2 + BATTLE_AREA_WIDTH_SPACING ,
    DEFENDER_CARD1_LEFT + BATTLE_AREA_WIDTH_SPACING2,
    DEFENDER_CARD1_LEFT - BATTLE_AREA_WIDTH_SPACING, 
    DEFENDER_CARD1_LEFT - BATTLE_AREA_WIDTH_SPACING * 2,
    DEFENDER_CARD1_LEFT - BATTLE_AREA_WIDTH_SPACING * 3,
}

print ('################', DEFENDER_BOARD_POS_X[1], DEFENDER_BOARD_POS_X[2], DEFENDER_BOARD_POS_X[3], DEFENDER_BOARD_POS_X[4], DEFENDER_BOARD_POS_X[5], DEFENDER_BOARD_POS_X[6])

local ATTACKER_BOARD_Y = V.SCR_CH - 22 * SCALE
local DEFENDER_BOARD_Y = V.SCR_CH + 22 * SCALE

-- dimens grave
local ATTACK_GRAVE_TOP = V.SCR_CH  - 8 * SCALE
local DEFENDER_GRAVE_TOP = V.SCR_CH + 8 * SCALE
local GRAVE_LEFT = V.SCR_CW - 458 * SCALE
local GRAVE_WIDTH = 75 * SCALE
local GRAVE_HEIGHT = 106 * SCALE

-- dimens rare area
local ATTACK_RARE_TOP = ATTACK_GRAVE_TOP - GRAVE_HEIGHT - 5 * SCALE
local DEFENDER_RARE_TOP = DEFENDER_GRAVE_TOP + GRAVE_HEIGHT + 5 * SCALE
local RARE_LEFT = GRAVE_LEFT
local RARE_WIDTH = GRAVE_WIDTH
local RARE_HEIGHT = GRAVE_HEIGHT

--dimens magic/trap area
local MAGIC_AREA_WIDTH = 60 * SCALE
local MAGIC_AREA_HEIGHT = MAGIC_AREA_WIDTH
local MAGIC_AREA_LEFT = V.SCR_CW + 338 * SCALE
local MAGIC_AREA_SPACING = 10 * SCALE
local ATTACKER_MAGIC_AREA_TOP = V.SCR_CH - 17 * SCALE
local DEFENDER_MAGIC_AREA_TOP = V.SCR_CH + 17 * SCALE
local MAGIC_AREA_X = {
    MAGIC_AREA_LEFT,
    MAGIC_AREA_LEFT + MAGIC_AREA_WIDTH + MAGIC_AREA_SPACING,
    MAGIC_AREA_LEFT,
    MAGIC_AREA_LEFT + MAGIC_AREA_WIDTH + MAGIC_AREA_SPACING,
    MAGIC_AREA_LEFT,
}
local ATTACKER_MAGIC_AREA_Y = {
    ATTACKER_MAGIC_AREA_TOP,
    ATTACKER_MAGIC_AREA_TOP,
    ATTACKER_MAGIC_AREA_TOP - MAGIC_AREA_HEIGHT - MAGIC_AREA_SPACING,
    ATTACKER_MAGIC_AREA_TOP - MAGIC_AREA_HEIGHT - MAGIC_AREA_SPACING,
    ATTACKER_MAGIC_AREA_TOP - MAGIC_AREA_HEIGHT * 2 - MAGIC_AREA_SPACING * 2,
}

local DEFENDER_MAGIC_AREA_Y = {
    DEFENDER_MAGIC_AREA_TOP,
    DEFENDER_MAGIC_AREA_TOP,
    DEFENDER_MAGIC_AREA_TOP + MAGIC_AREA_HEIGHT + MAGIC_AREA_SPACING,
    DEFENDER_MAGIC_AREA_TOP + MAGIC_AREA_HEIGHT + MAGIC_AREA_SPACING,
    DEFENDER_MAGIC_AREA_TOP + MAGIC_AREA_HEIGHT * 2 + MAGIC_AREA_SPACING * 2,
}

local DEAL_POS = {
    PLAYER_LEFT = V.SCR_CW + 575 * SCALE,
    PLAYER_RIGHT = V.SCR_CW + 670 * SCALE,
    PLAYER_TOP = V.SCR_CH - 317 * SCALE,
    PLAYER_BOTTOM = V.SCR_CH - 369 * SCALE,
    OPPONENT_RIGHT = V.SCR_CW - 575 * SCALE,
    OPPONENT_LEFT = V.SCR_CW - 670 * SCALE,
    OPPONENT_BOTTOM = V.SCR_CH + 317 * SCALE,
    OPPONENT_TOP = V.SCR_CH + 369 * SCALE,
}

local HAND_POS = {
    LEFT = V.SCR_CW - 304 * SCALE,
    RIGHT = V.SCR_CW + 308 * SCALE,
    PLAYER_TOP = 138 * SCALE,
    OPPONENT_BOTTOM = V.SCR_H - 138 * SCALE,
}

local MAX_AMOUNT_HAND_CARDS = 7

CARD_BLOCK = {
    PLAYER_BOARD = 1,
    PLAYER_GRAVE = 2,
    PLAYER_MAGIC_TRAP = 4,
    PLAYER_HAND = 5,
    PLAYER_PILE = 6,
    OPPONENT_BOARD = 11,
    OPPONENT_GRAVE = 12,
    OPPONENT_MAGIC_TRAP = 14,
    OPPONENT_HAND = 15,
    OPPONENT_PILE = 16
}

_SELECT_CARD_TYPE = {
    MONSTER = 1,
    MAGIC = 2,
    TRAP = 3,
    RARE = 4,
}

HP_OWNER = {
    PLAYER = 1,
    OPPONENT = 2
}

local touchBeganTime = 0
local beganY = 0
local endedY = 0
local isPullDownValid = true
local pull = {
    isValid = true,
    pos = 0,
    location = {
        beganY = 0,
        endedY = 0,
    },
    isPlayer = true,
    isDown = true
}

function _M:onTouchBegan(touch)
    lc.log("onTouchBegan")
    touchBeganTime = os.clock()
    pull.location.beganY = touch:getLocation().y
    if self:isInPlayerBoard(touch) ~= 0 then
        pull.isValid = true
        pull.isPlayer = true
        pull.pos = self:isInPlayerBoard(touch)
    elseif self:isInOpponentBoard(touch) ~= 0 then
        pull.isValid = true
        pull.isPlayer = false
        pull.pos = self:isInOpponentBoard(touch)
    else
        pull.isValid = false
    end

    return true
end

function _M:onTouchMoved(touch)
    lc.log("onTouchMoved")
end

function _M:onTouchEnded(touch)
    
    pull.location.endedY = touch:getLocation().y

    if self:isValidPull() then
        local cardSprite
        if pull.isPlayer then
            print("player", pull.pos)
            cardSprite = self._playerUi._pBoardCards[pull.pos]
        else
            print("opponent", pull.pos)
            cardSprite = self._opponentUi._pBoardCards[pull.pos]
        end

        if cardSprite then
            return false
        end
    end
    
    -- in board
    if self:isInPlayerBoard(touch) ~= 0 then
        local pos = self:isInPlayerBoard(touch)
        local selectTypes = {
            _SELECT_CARD_TYPE.MONSTER, _SELECT_CARD_TYPE.RARE,
        }
        if self:isLongClick() then
            if self._player._boardCards ~= nil and self._player._boardCards[pos] then
                self:removeCard(CARD_BLOCK.PLAYER_BOARD, pos)
            else
                ToastManager.push(Str(STR.SHORT_CLICK_TO_ADD_CARD), 1.0)
            end
        else 
            require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.PLAYER_BOARD, isMulti, pos) end):show()
            lc.log("isInPlayerBoard -- " .. self:isInPlayerBoard(touch))
        end
    elseif self:isInOpponentBoard(touch) ~= 0 then
        local pos = self:isInOpponentBoard(touch)
        local selectTypes = {
            _SELECT_CARD_TYPE.MONSTER, _SELECT_CARD_TYPE.RARE,
        }
        if self:isLongClick() then
            if self._opponent._boardCards ~= nil and self._opponent._boardCards[pos] then
                self:removeCard(CARD_BLOCK.OPPONENT_BOARD, pos)
            else
                ToastManager.push(Str(STR.SHORT_CLICK_TO_ADD_CARD), 1.0)
            end
        else 
            require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.OPPONENT_BOARD, isMulti, pos) end):show()
            lc.log("isInOpponentBoard -- " .. self:isInOpponentBoard(touch))
        end

    elseif self:isInPlayerGrave(touch) then
        local selectTypes = {
            _SELECT_CARD_TYPE.MONSTER, _SELECT_CARD_TYPE.MAGIC, _SELECT_CARD_TYPE.TRAP, 
        }
        if self:isLongClick() then
            if self._player._graveCards ~= nil and #self._player._graveCards > 0 then
                BattleTestListDialog.create(self, self._player._graveCards, BattleTestListDialog.Mode.single_choice, lc.str(STR.BATTLE_GRAVE), _M.TouchTarget.player_grave):show()
            else
                ToastManager.push(Str(STR.ADD_GRAVE_CARD_FIRST), 1.0)
            end
        else
            require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.PLAYER_GRAVE, isMulti) end):show()
            lc.log("isInPlayerGrave")
        end

    elseif self:isInOpponentGrave(touch) then
        local selectTypes = {
            _SELECT_CARD_TYPE.MONSTER, _SELECT_CARD_TYPE.MAGIC, _SELECT_CARD_TYPE.TRAP,
        }
        if self:isLongClick() then
            if self._opponent._graveCards ~= nil and #self._opponent._graveCards > 0 then
                BattleTestListDialog.create(self, self._opponent._graveCards, BattleTestListDialog.Mode.single_choice, lc.str(STR.BATTLE_GRAVE), _M.TouchTarget.opponent_grave):show()
            else
                ToastManager.push(Str(STR.ADD_GRAVE_CARD_FIRST), 1.0)
            end
        else 
            require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.OPPONENT_GRAVE, isMulti) end):show()
            lc.log("isInOpponentGrave")
        end

    elseif self:isInPlayerMagicArea(touch) ~= 0 then
        --[[
        local pos = self:isInPlayerMagicArea(touch)
        local selectTypes = {
            _SELECT_CARD_TYPE.MAGIC, _SELECT_CARD_TYPE.TRAP,
        }
        if self:isLongClick() then
            if self._player._showCards ~= nil and self._player._showCards[pos] then
                self:removeCard(CARD_BLOCK.PLAYER_MAGIC_TRAP, pos)
            else
                ToastManager.push(Str(STR.ADD_MAGIC_TRAP_CARD_FIRST), 1.0)
            end
        else
            require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.PLAYER_MAGIC_TRAP, isMulti, pos) end, true):show()
            lc.log("isInPlayerMagicArea -- " .. self:isInPlayerMagicArea(touch))
        end
        ]]
    elseif self:isInOpponentMagicArea(touch) ~= 0 then
        --[[
        local pos = self:isInOpponentMagicArea(touch)
        local selectTypes = {
            _SELECT_CARD_TYPE.MAGIC, _SELECT_CARD_TYPE.TRAP,
        }
        if self:isLongClick() then
            if self._opponent._showCards ~= nil and self._opponent._showCards[pos] then
                self:removeCard(CARD_BLOCK.OPPONENT_MAGIC_TRAP, pos)
            else
                ToastManager.push(Str(STR.ADD_MAGIC_TRAP_CARD_FIRST), 1.0)
            end
        else 
            require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.OPPONENT_MAGIC_TRAP, isMulti, pos) end, true):show()
            lc.log("isInOpponentMagicArea -- " .. self:isInOpponentMagicArea(touch))
        end
        ]]
    elseif self:isInPlayerPileArea(touch) then
        local selectTypes = {
            _SELECT_CARD_TYPE.MONSTER, _SELECT_CARD_TYPE.MAGIC, _SELECT_CARD_TYPE.TRAP,
        }
        if self:isLongClick() then
            if self._player._pileCards ~= nil and #self._player._pileCards > 0 then
                BattleTestListDialog.create(self, self._player._pileCards, BattleTestListDialog.Mode.single_choice, lc.str(STR.BATTLE_PILE), _M.TouchTarget.player_pile):show()
            else
                ToastManager.push(Str(STR.ADD_PILE_CARD_FIRST), 1.0)
            end
        else
            require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.PLAYER_PILE, isMulti) end):show()
            lc.log("in attackerDealArea")
        end
    elseif self:isInOpponentPileArea(touch) then
        local selectTypes = {
            _SELECT_CARD_TYPE.MONSTER, _SELECT_CARD_TYPE.MAGIC, _SELECT_CARD_TYPE.TRAP,
        }
        if self:isLongClick() then
            if self._opponent._pileCards ~= nil and #self._opponent._pileCards > 0 then
                BattleTestListDialog.create(self, self._opponent._pileCards, BattleTestListDialog.Mode.single_choice, lc.str(STR.BATTLE_PILE), _M.TouchTarget.opponent_pile):show()
            else
                ToastManager.push(Str(STR.ADD_PILE_CARD_FIRST), 1.0)
            end
        else
            require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.OPPONENT_PILE, isMulti) end):show()
            lc.log("in defenderdeal area")
        end
    elseif self:isInPlayerHpArea(touch) then
        lc.log("in palyer hp")
        local BattleTestInputForm = require("BattleTestInputForm")
        BattleTestInputForm.create(function(hp) self:onHpSet(hp, HP_OWNER.PLAYER) end, BattleTestData.OperationType._modifyHp):show()
    elseif self:isInOpponentHpArea(touch) then
        lc.log("in op hp")
        local BattleTestInputForm = require("BattleTestInputForm")
        BattleTestInputForm.create(function(hp) self:onHpSet(hp, HP_OWNER.OPPONENT) end, BattleTestData.OperationType._modifyHp):show()
    elseif self:isInPlayerHandArea(touch) then
        lc.log("isInPlayerHandArea")
        local cards = self._player._handCards
        if self:isLongClick() then
            if cards ~= nil and #cards > 0 then
                BattleTestListDialog.create(self, cards, BattleTestListDialog.Mode.single_choice, lc.str(STR.HAND_CARD), _M.TouchTarget.player_hand):show()
            else
                ToastManager.push(Str(STR.ADD_HAND_CARD_FIRST), 1.0)
            end
        else
            if cards ~= nil and #cards >= MAX_AMOUNT_HAND_CARDS then
                ToastManager.push(Str(STR.DELETE_HAND_CARDS_WHEN_MAX), 1.0)
            else
                local selectTypes = {
                    _SELECT_CARD_TYPE.MONSTER, _SELECT_CARD_TYPE.MAGIC, _SELECT_CARD_TYPE.TRAP
                }
                require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.PLAYER_HAND, isMulti) end):show()
            end
        end
    elseif self:isInOpponentHandArea(touch) then
        lc.log("isInOpponentHandArea")
        local cards = self._opponent._handCards
        if self:isLongClick() then
            if cards ~= nil and #cards > 0 then
                BattleTestListDialog.create(self, cards, BattleTestListDialog.Mode.single_choice, lc.str(STR.HAND_CARD), _M.TouchTarget.opponent_hand):show()
            else
                ToastManager.push(Str(STR.ADD_HAND_CARD_FIRST), 1.0)
            end
        else
            if cards ~= nil and #cards >= MAX_AMOUNT_HAND_CARDS then
                ToastManager.push(Str(STR.DELETE_HAND_CARDS_WHEN_MAX), 1.0)
            else
                local selectTypes = {
                    _SELECT_CARD_TYPE.MONSTER, _SELECT_CARD_TYPE.MAGIC, _SELECT_CARD_TYPE.TRAP,
                }
                require("BattleTestCardSelectForm").create(selectTypes, function(infoId, isMulti) self:onCardSelect(infoId, CARD_BLOCK.OPPONENT_HAND, isMulti) end):show()
            end
        end
    end

    return false 
end

function _M:hasCards(table)
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        if table[i] ~= nil then
            return true
        end
    end
    return false
end

--[[--
if in attack board, return true
else return false
--]]--
function _M:isInPlayerBoard(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y
    local result = 0

    for i, v in ipairs(ATTACKER_BOARD_POS_X) do
        if touchX >= v and touchX < v + (i == 1 and BATTLE_AREA_WIDTH_SPACING2 or BATTLE_AREA_WIDTH_SPACING)  then
            result = i
            break
        end
    end

    if touchY < ATTACKER_BOARD_Y and touchY > ATTACKER_BOARD_Y - BATTLE_AREA_HEIGHT then
    else 
        result = 0
    end

    return result
end

--[[--
if in defender board, renturn true
else return false
--]]--
function _M:isInOpponentBoard(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y
    local result = 0

    for i, v in ipairs(DEFENDER_BOARD_POS_X) do
        if touchX >= v and touchX < v + (i == 1 and BATTLE_AREA_WIDTH_SPACING2 or BATTLE_AREA_WIDTH_SPACING)  then
            result = i
            break
        end
    end

    if touchY > DEFENDER_BOARD_Y and touchY < DEFENDER_BOARD_Y + BATTLE_AREA_HEIGHT then
    else 
        result = 0
    end

    return result
end

--[[--
if in attack grave area, return true
else return false
--]]--
function _M:isInPlayerGrave(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    lc.log("touch:(" .. tostring(touchX) .. "," .. tostring(touchY) .. ")")
    lc.log("grave:(" .. tostring(PlayerUi.Pos.attacker_grave.x) .. "," .. tostring(PlayerUi.Pos.attacker_grave.y) .. ")")

    if touchX > GRAVE_LEFT and touchX < GRAVE_LEFT + GRAVE_WIDTH and
        touchY < ATTACK_GRAVE_TOP and touchY > ATTACK_GRAVE_TOP - GRAVE_HEIGHT then
        return true
    end
    return false
end

--[[--
if in defender grave area, return true
else return false
--]]--
function _M:isInOpponentGrave(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    lc.log("touch:(" .. tostring(touchX) .. "," .. tostring(touchY) .. ")")

    if touchX > GRAVE_LEFT and touchX < GRAVE_LEFT + GRAVE_WIDTH and
        touchY > DEFENDER_GRAVE_TOP and touchY < DEFENDER_GRAVE_TOP + GRAVE_HEIGHT then
        return true
    end
    return false
end

--[[--
if in attack rare area, return true
else return false
--]]--
function _M:isInPlayerRareArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    lc.log("touch:(" .. tostring(touchX) .. "," .. tostring(touchY) .. ")")

    if touchX > RARE_LEFT and touchX < RARE_LEFT + RARE_WIDTH and
        touchY < ATTACK_RARE_TOP and touchY > ATTACK_RARE_TOP - RARE_HEIGHT then
        return true
    end
    return false
end

--[[--
if in defender rare area, return true
else return false
--]]--
function _M:isInOpponentRareArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    lc.log("touch:(" .. tostring(touchX) .. "," .. tostring(touchY) .. ")")

    if touchX > RARE_LEFT and touchX < RARE_LEFT + RARE_WIDTH and
        touchY > DEFENDER_RARE_TOP and touchY < DEFENDER_RARE_TOP + GRAVE_HEIGHT then
        return true
    end
    return false
end

--[[--
if in attack magic/trap area, return true
else return false
--]]--
function _M:isInPlayerMagicArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y
    local result = 0

    for i = 1, 5 do
        if touchX >= MAGIC_AREA_X[i] and touchX < MAGIC_AREA_X[i] + MAGIC_AREA_WIDTH 
            and touchY <= ATTACKER_MAGIC_AREA_Y[i] and touchY > ATTACKER_MAGIC_AREA_Y[i] - MAGIC_AREA_HEIGHT then
            result = i
            break
        end
    end
    return result
end

--[[--
if in defender magic/trap area, return true
else return false
--]]--
function _M:isInOpponentMagicArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y
    local result = 0

    for i = 1, 5 do
        if touchX >= MAGIC_AREA_X[i] and touchX < MAGIC_AREA_X[i] + MAGIC_AREA_WIDTH 
            and touchY >= DEFENDER_MAGIC_AREA_Y[i] and touchY < DEFENDER_MAGIC_AREA_Y[i] + MAGIC_AREA_HEIGHT then
            result = i
            break
        end
    end
    return result
end

--[[--
if in attacker deal area, return true
else return false
--]]--
function _M:isInPlayerPileArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    lc.log("touch:(" .. tostring(touchX) .. "," .. tostring(touchY) .. ")")

    if touchX > DEAL_POS.PLAYER_LEFT and touchX < DEAL_POS.PLAYER_RIGHT and
        touchY > DEAL_POS.PLAYER_BOTTOM and touchY < DEAL_POS.PLAYER_TOP then
        return true
    end
    return false
end

--[[--
if in defender deal area, return true
else return false
--]]--
function _M:isInOpponentPileArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    lc.log("touch:(" .. tostring(touchX) .. "," .. tostring(touchY) .. ")")

    if touchX > DEAL_POS.OPPONENT_LEFT and touchX < DEAL_POS.OPPONENT_RIGHT and
        touchY > DEAL_POS.OPPONENT_BOTTOM and touchY < DEAL_POS.OPPONENT_TOP then
        return true
    end
    return false
end

function _M:isInPlayerHpArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    local tmp = 0.25 * touchX + touchY
    if tmp > 109 * SCALE and tmp < 150 * SCALE and touchX < 148 * SCALE then
        return true
    end
    return false
end

function _M:isInOpponentHpArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    touchX = 2 * V.SCR_CW - touchX
    touchY = 2 * V.SCR_CH - touchY

    local tmp = 0.25 * touchX + touchY
    if tmp > 109 and tmp < 150 and touchX < 148 then
        return true
    end
    return false
end

function _M:isInPlayerHandArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    if touchX > HAND_POS.LEFT and touchX < HAND_POS.RIGHT and touchY < HAND_POS.PLAYER_TOP then
        return true
    end
    return flase
end

function _M:isInOpponentHandArea(touch)
    local touchX = touch:getLocation().x
    local touchY = touch:getLocation().y

    if touchX > HAND_POS.LEFT and touchX < HAND_POS.RIGHT and touchY > HAND_POS.OPPONENT_BOTTOM then
        return true
    end
    return flase
end

--[[--
judge whether is double click
--]]--
function _M:isLongClick()
    local touchEndedTime = os.clock()
    local duration = touchEndedTime - touchBeganTime
    lc.log("touch duration " .. duration)
    if duration < 0.3 then
        lc.log("single click")
        return false
    else
        lc.log("isLongClick")
        return true
    end
end

function _M:isValidPull()
    if not pull.isValid then return false end

    local beganY = pull.location.beganY
    local endedY = pull.location.endedY
    local delta = beganY - endedY
    if beganY > 0 and endedY > 0 and delta > 40 then
        pull.isDown = true
        pull.isValid = true
    elseif beganY > 0 and endedY > 0 and delta < -40 then
        pull.isDown = false
        pull.isValid = true
    else 
        pull.isValid = false
    end
    return pull.isValid
end

function _M:onCardSelect(infoId, cardBlock, isMulti, pos)
    -- remove the card in the same position
    if isMulti ~= true then
        self:removeCard(cardBlock, pos)
    end

    -- add card
    if cardBlock == CARD_BLOCK.PLAYER_BOARD then
        local battleCard = B.createCard(infoId, 1)
        self._player:addCardToCards(battleCard)

        if isMulti then
            local position = 0
            for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
                if not self._player._boardCards[i] then
                    position = i
                    break
                end
            end
            if position > 0 then
                pos = position
                battleCard._pos = pos
            else
                return
            end
        elseif pos then 
            battleCard._pos = pos 
        end
        self._player._boardCards[pos] = battleCard
        
        local cardSprite = self._playerUi:createCardSprite(battleCard)
        self:addChild(cardSprite)
        self._playerUi:addCardToBoardFast(battleCard)

    elseif cardBlock == CARD_BLOCK.OPPONENT_BOARD and pos > 0 and pos <= Data.MAX_CARD_COUNT_ON_BOARD then
        local battleCard = B.createCard(infoId, 1)
        self._opponent:addCardToCards(battleCard)
        if isMulti then
            local position = 0
            for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
                if not self._opponent._boardCards[i] then
                    position = i
                    break
                end
            end
            if position > 0 then
                pos = position
                battleCard._pos = pos
            else
                return
            end
        elseif pos then battleCard._pos = pos end
        self._opponent._boardCards[pos] = battleCard

        local cardSprite = self._opponentUi:createCardSprite(battleCard)
        self:addChild(cardSprite)
        self._opponentUi:addCardToBoardFast(battleCard)

    elseif cardBlock == CARD_BLOCK.PLAYER_GRAVE then
        local battleCard = B.createCard(infoId, 1)
        self._player:addCardToCards(battleCard)
        self._player:addCardToGrave(battleCard)
        local cardSprite = self._playerUi:createCardSprite(battleCard)
        self:addChild(cardSprite)
        self._playerUi:addCardToGrave(battleCard, 0, 0)

    elseif cardBlock == CARD_BLOCK.OPPONENT_GRAVE then
        local battleCard = B.createCard(infoId, 1)
        self._opponent:addCardToCards(battleCard)
        self._opponent:addCardToGrave(battleCard)
        local cardSprite = self._opponentUi:createCardSprite(battleCard)
        self:addChild(cardSprite)
        self._opponentUi:addCardToGrave(battleCard, 0, 0)

    elseif cardBlock == CARD_BLOCK.PLAYER_HAND then
        if #self._player._handCards >= MAX_AMOUNT_HAND_CARDS then return end 
        local battleCard = B.createCard(infoId, 1)
        self._player:addCardToCards(battleCard)
        pos = 1
        if self._player._handCards ~= nil then
            pos = #self._player._handCards + 1
        end
        battleCard._pos = pos
        
        self._player:addCardToHand(battleCard)
        local cardSprite = self._playerUi:createCardSprite(battleCard)
        self:addChild(cardSprite)
        self._playerUi:addCardToHandFast(battleCard)

    elseif cardBlock == CARD_BLOCK.OPPONENT_HAND then
        if #self._opponent._handCards >= MAX_AMOUNT_HAND_CARDS then return end 
        local battleCard = B.createCard(infoId, 1)
        self._opponent:addCardToCards(battleCard)
        pos = 1
        if self._opponent._handCards ~= nil then
            pos = #self._opponent._handCards + 1
        end
        battleCard._pos = pos
        
        self._opponent:addCardToHand(battleCard)
        local cardSprite = self._opponentUi:createCardSprite(battleCard)
        self:addChild(cardSprite)
        self._opponentUi:addCardToHandFast(battleCard)
    elseif cardBlock == CARD_BLOCK.PLAYER_PILE then
        local battleCard = B.createCard(infoId, 1)
        self._player:addCardToCards(battleCard)
        battleCard._saved._pos = #self._player._pileCards + 1
        self._player:addCardToPile(battleCard)
        local cardSprite = self._playerUi:createCardSprite(battleCard)
        self:addChild(cardSprite)
        self._playerUi:addCardToPileFast(battleCard, 0, 0)
        self:updatePile(self._playerUi)

    elseif cardBlock == CARD_BLOCK.OPPONENT_PILE then
        local battleCard = B.createCard(infoId, 1)
        self._opponent:addCardToCards(battleCard)
        battleCard._saved._pos = #self._opponent._pileCards + 1
        self._opponent:addCardToPile(battleCard)
        local cardSprite = self._opponentUi:createCardSprite(battleCard)
        self:addChild(cardSprite)
        self._opponentUi:addCardToPileFast(battleCard, 0, 0)
        self:updatePile(self._opponentUi)

    end
end

--[[--
remove the card in the same position

in rare area and grave area, only remove cardsprivate in ui layer
--]]--
function _M:removeCard(cardBlock, pos) 
    if cardBlock == CARD_BLOCK.PLAYER_BOARD then
        local card = self._player._boardCards[pos]
        if card then
            local cardSprite = self._playerUi:getCardSprite(card)
            self._player:removeCardFromCards(card)
            self._player:removeCardFromBoard(card)
            self._playerUi:removeCardFromBoard(card)
            self._playerUi:removeCardFromSprites(cardSprite)
            cardSprite:removeFromParent()
        end
    elseif cardBlock == CARD_BLOCK.OPPONENT_BOARD then
        local card = self._opponent._boardCards[pos]
        if card then
            local cardSprite = self._opponentUi:getCardSprite(card)
            self._opponent:removeCardFromCards(card)
            self._opponent:removeCardFromBoard(card)
            self._opponentUi:removeCardFromBoard(card)
            self._opponentUi:removeCardFromSprites(cardSprite)
            cardSprite:removeFromParent()
        end
    elseif cardBlock == CARD_BLOCK.PLAYER_MAGIC_TRAP then
        --[[
        local card = self._player._showCards[pos]
        if card then
            local cardSprite = self._playerUi:getCardSprite(card)
            self._player:removeCardFromCards(card)
            self._player:removeCardFromShow(card)
            self._playerUi:removeCardFromBoard(card)
            self._playerUi:removeCardFromSprites(cardSprite)
            cardSprite:removeFromParent()
        end
        ]]
    elseif cardBlock == CARD_BLOCK.OPPONENT_MAGIC_TRAP then
        --[[
        local card = self._opponent._showCards[pos]
        if card then
            local cardSprite = self._opponentUi:getCardSprite(card)
            self._opponent:removeCardFromCards(card)
            self._opponent:removeCardFromShow(card)
            self._opponentUi:removeCardFromBoard(card)
            self._opponentUi:removeCardFromSprites(cardSprite)
            cardSprite:removeFromParent()
        end
        ]]
    end
end

function _M:reset()
    -- remove board and show cards
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        self:removeCard(CARD_BLOCK.PLAYER_BOARD, i)
        self:removeCard(CARD_BLOCK.OPPONENT_BOARD, i)
        self:removeCard(CARD_BLOCK.PLAYER_MAGIC_TRAP, i)
        self:removeCard(CARD_BLOCK.OPPONENT_MAGIC_TRAP, i)
    end
    
    -- remove grave
    length = #self._player._graveCards
    for i = length, 1, -1 do
        local card = self._player._graveCards[i]
        local cardSprite = self._playerUi:getCardSprite(card)
        self._player:removeCardFromGrave(card)
        self._player:removeCardFromCards(card)
        self._playerUi:removeCardFromGrave(card)
        self._playerUi:removeCardFromSprites(cardSprite)
        cardSprite:removeFromParent()
    end
    length = #self._opponent._graveCards
    for i = length, 1, -1 do
        local card = self._opponent._graveCards[i]
        local cardSprite = self._opponentUi:getCardSprite(card)
        self._opponent:removeCardFromGrave(card)
        self._opponent:removeCardFromCards(card)
        self._opponentUi:removeCardFromGrave(card)
        self._opponentUi:removeCardFromSprites(cardSprite)
        cardSprite:removeFromParent()
    end
    -- remove hand
    length = #self._player._handCards
    for i = length, 1, -1 do
        local card = self._player._handCards[i]
        local cardSprite = self._playerUi:getCardSprite(card)
        self._player:removeCardFromHand(card)
        self._player:removeCardFromCards(card)
        self._playerUi:removeCardFromHand(card)
        self._playerUi:removeCardFromSprites(cardSprite)
        cardSprite:removeFromParent()
        self._playerUi:replaceHandCards(0)
    end
    length = #self._opponent._handCards
    for i = length, 1, -1 do
        local card = self._opponent._handCards[i]
        local cardSprite = self._opponentUi:getCardSprite(card)
        self._opponent:removeCardFromHand(card)
        self._opponent:removeCardFromCards(card)
        self._opponentUi:removeCardFromHand(card)
        self._opponentUi:removeCardFromSprites(cardSprite)
        cardSprite:removeFromParent()
        self._opponentUi:replaceHandCards(0)
    end
    -- remove pile
    length = #self._player._pileCards
    for i = length, 1, -1 do
        local card = self._player._pileCards[i]
        local cardSprite = self._playerUi:getCardSprite(card)
        self._player:removeCardFromPile(card)
        self._player:removeCardFromCards(card)
        -- battle test: no cardspriate stored in table, do nothing
--                self._battleUi._playerUi:removeCardFromPile(card)
        self._playerUi:removeCardFromSprites(cardSprite)
--            cardSprite:removeFromParent()
        self:updatePile(self._playerUi)
    end
    length = #self._opponent._pileCards
    for i = length, 1, -1 do
        local card = self._opponent._pileCards[i]
        local cardSprite = self._opponentUi:getCardSprite(card)
        self._opponent:removeCardFromPile(card)
        self._opponent:removeCardFromCards(card)
        -- battle test: no cardspriate stored in table, do nothing
--                self._battleUi._opponentUi:removeCardFromPile(card)
        self._opponentUi:removeCardFromSprites(cardSprite)
--            cardSprite:removeFromParent()
        self:updatePile(self._opponentUi)
    end

    -- update hp
    self._playerUi:setFortressHp(8000)
    self._opponentUi:setFortressHp(8000)
end

function _M:onHpSet(hp, owner)
    if hp ~= nil and tonumber(hp) ~= nil then
        if owner == HP_OWNER.PLAYER then
            self._playerUi:setFortressHp(hp)
        elseif owner == HP_OWNER.OPPONENT then
            self._opponentUi:setFortressHp(hp)
        end
    end

end

function _M:onTouchCanceled()
    if not self._isTouching then return end
    self._isTouching = false

    if self._dropLayer then 
        return self._dropLayer:onTouchCanceled() 
    end
    
    if self._touchCard then
        local pCard = self._touchCard
        local player = pCard._card._owner
        local playerUi = pCard._ownerUi

        pCard:onTouchCanceled()
        self._touchCard = nil

        if self._selectTargetLayer then
            return self._selectTargetLayer:onTouchCanceled()
        end
        
        if pCard._touchEvent._touchCardType == CardSprite.TouchCardType.self_hand_card then
            if self._isOperating then
                self:hidePreview(pCard)
                playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)   
                         
            else
                playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)          
            end
            
        elseif pCard._touchEvent._touchCardType == CardSprite.TouchCardType.board_card then
            self:hidePreview(pCard)
            self:removeExchangeArrow()   
        end
    end
end
