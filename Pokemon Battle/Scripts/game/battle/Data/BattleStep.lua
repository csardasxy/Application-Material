local _M = PlayerBattle

-----------------------------------
-- reset functions
-----------------------------------

function _M:resetWhenBattleStart() 
    self._battleCondition:reset()
    self._battleEvent:reset()
    
    self._resultType = Data.BattleResult.draw
    self._isFinished = false
    self._isForwarding = false
    self._isReviewing = false
    self._isPaused = false
    self._pausedStatus = nil
    self._isRetreat = false
    self._isRemainUnusable = false
    self._isInitialDealed = false
    self._isUsedCard = false
    self._isDealDisabled = false
    self._destroyedPower = 0
    
    self._cardIdBase = self._isAttacker and BattleData.CardId.attacker_base or BattleData.CardId.defender_base

    -- tables    
    self._cards = {}
    self._pileCards = {}
    self._handCards = {}
    self._boardCards = {}
    self._graveCards = {}
    self._result = {}
    self._gemUnderSkills = {}
    self._tempLeaveCards = {}
    self._delaySkillCards = {}
    self._frozenAttackRounds = {}
    self._extraPowerCost = {}

    self._disableDrawbackRounds = {} 
    self._disableMainMonsterAbilityRounds = {}
    self._disable1118Rounds = {} 

    -- tabels in round begin
    self._castedSkillCounts = {}
    self._summonedMonsterCounts = {}
    self._isSummonDisabledBySelfStar = {}
    self._isSummonDisabledByOppoStar = {}

    self._replayIndex = 1
   
    -- properties
    self._stepStatus = BattleData.Status.default 
    self._macroStatus = BattleData.Status.default
    self._normalStatus = BattleData.Status.default
    self._round = 0
    self._ghostCard = nil
    
    -- fortress & boss
    self._fortress = BattleCard.new(0, 1, self)
    if self._fortressHp ~= 0 then self._fortress._updateInitHp = self._fortressHp end
    self._fortress:resetOnce()
    self._fortress._owner = self
    self._fortress._id = self._isAttacker and BattleData.CardId.attacker_base or BattleData.CardId.defender_base

    self._fortressSkill = nil
    if self._fortressSkillInfo and self._fortressSkillInfo._id and self._fortressSkillInfo._level and self._fortressSkillInfo._id == 60000 then    
        self._fortressSkill = B.createSkill(self._fortressSkillInfo._id, self._fortressSkillInfo._level, self._fortress)
    end

    
    -- first load levels
    local troopLevels = {}
    for i = 1, #self._troopLevels do
        local pbCardLevel = self._troopLevels[i]
        troopLevels[pbCardLevel.info_id] = pbCardLevel.level
    end

    -- then load skins
    local skins = {}
    if self._isClient then
        for _, pbTroopSkin in ipairs(self._troopSkins) do
            skins[pbTroopSkin.info_id] = pbTroopSkin.skin_id
        end
    end
    self._skins = skins

    -- then load cards
    local troopCards = {}
    local id = 1
    for _, pbTroopCard in ipairs(self._troopCards) do
        for i = 1, pbTroopCard.num do
            local troopCard = 
            {
                _id = id,
                _infoId = pbTroopCard.info_id,
                _level = troopLevels[pbTroopCard.info_id] or 1,
            }

            table.insert(troopCards, troopCard)
            id = id + 1

            if troopCard._id < 0 then
                self._hasHiredHero = true
            end
        end
    end
    
    for i = 1, #troopCards do
        local info = troopCards[i]
        local card = BattleCard.new(info._infoId, info._level, self)
        card._isTroopCard = true
        self:addCardToCards(card)
    end

    -- random pile
    local remainIndices = {}
    for i = 1, #self._cards do
        local card = self._cards[i]
        if card:isMonster() or card._type == Data.CardType.magic or card._type == Data.CardType.trap then
            card._status = BattleData.CardStatus.pile
            table.insert(remainIndices, i)
        end
    end

    -- use default random to upset cards if exists
    for i = 1, #remainIndices do
        local j = math.floor(self:getRandom() * (#remainIndices - i + 1)) + i
        local index = remainIndices[j]
        remainIndices[j] = remainIndices[i]

        local card = self._cards[index]
        self._pileCards[#self._pileCards + 1] = card
        card._pos = #self._pileCards
    end

    for i = 1, #self._cards do
        local card = self._cards[i]
        card:resetOnce()
    end

    -- reset
    --self._power = 0
    self._ball = BattleData.MAX_BALL_COUNT

    self._cardStatusToChange = {}
    self._cardPosToChange = {}
    self._eventToChange = {}
    self._saved = {}
    self._magicPool = nil
    self._winBy3190 = nil
    self._disableTrapBy4127 = nil

    -- score
    self._damageScore = {}
    self._damageScore[_M.KEY_TOTAL] = 0
    self._destroyCardScore = {}
    self._destroyCardScore[_M.KEY_TOTAL] = 0
    self._destroyHeroScore = {}
    self._destroyHeroScore[_M.KEY_TOTAL] = 0
    self._destroyMonsterCount = {}
    self._destroyMonsterCount[0] = 0
    self._totalSummonedMonsterCount = {0, 0, 0}
    self._totalCastedMagicCount = 0
    self._totalCastedTrapCount = 0
end

function _M:resetWhenRoundBegin()
    self._round = self._round + 1
    --self._power = math.max(0, math.min(BattleData.MAX_POWER_COUNT, math.min(self._power + 2, self._round - self._destroyedPower)))
    self._powerUsedCount = 0
    self._reorderDone = false
    self._eventDone = false
    self._haloDone = false
    self._trapDone = false
    self._saved = {}
    self._cardStatusToChange = {}
    self._cardPosToChange = {}
    self._eventToChange = {}

    self:removeGemUnderSkillsByRound()

    local cards = self:getAllCards()
    for i = 1, #cards do
        local card = cards[i]
        if card._owner == self then
            card:resetCardWhenRoundBegin()
        else
            card:resetCardWhenOppoRoundBegin()
        end
    end
    
    local cards = B.mergeTable({self:getBattleCards('BS'), self._opponent:getBattleCards('BS')})
    for i = 1, #cards do
        cards[i]._actionIndex = 1
        cards[i]._actionCount = 1
    end
    cards = B.mergeTable({self:getBattleCardsBySkillMode('G', Data.SkillMode.in_grave), self._opponent:getBattleCardsBySkillMode('G', Data.SkillMode.in_grave)})
    for i = 1, #cards do
        cards[i]._actionIndex = 1
        cards[i]._actionCount = 1
    end
    self._cardInAction = nil
	 
    self._isMonsterActioned = false
    self._isSummoned = false
    self._isNormalSummoned = false
    self._isSummonDisabled = false
    self._isMagicTrapDisabled = false
    
    self._isTrapTriggerDisabled = false
    self._opponent._isTrapTriggerDisabled = false

    self._specialMagicUsed = false
    self._castedSkillCounts = {}
    self._summonedMonsterCounts = {}
    self._isSummonDisabledBySelfStar = {}
    self._opponent._isSummonDisabledByOppoStar = {}

    self._extraMonsterDamageToMain = 0
    self._extraMonsterDamageToAll = 0
end

function _M:resetWhenInitialDeal()
    self._graveCards = {}
    
    self._fortress:reset()
end

function _M:resetActionCard()
    local actionCard = self._actionCard
    self._opponent._actionCard = nil
    
    actionCard._needAccount = false
    actionCard._spellingSkill = nil
end

function _M:resetAccount()
    local cards = self:getAllCards()
    for i = 1, #cards do
        local card = cards[i]
        card._castedSkills = {}
        card._changed = {}
    end
    
    local actionCard = self._actionCard or self._opponent._actionCard
    if actionCard ~= nil then 
        actionCard._needAccount = false 
    end
end

-----------------------------------
-- battle start and finish 
-----------------------------------

function _M:beginForward(round)
    self._isForwarding = true
    self._isReviewing = true
	self._forwardToRound = round
end

function _M:endForward()
    self._isForwarding = false
    self._isReviewing = false
	self._forwardToRound = nil
end

function _M:retreat()
    self._isRetreat = true
    
    local player = self:getActionPlayer()
    if player:checkFinish() then
        player._stepStatus = BattleData.Status.battle_end
        return player:step()
    end
end

function _M:pause()
    self._isPaused = true
end

function _M:resume()
    self._isPaused = false
    if self._pausedStatus ~= nil then
        self._pausedStatus = nil
        self:step()
    end
end

function _M:checkFinish()
    if self._isClient and ClientData._isAutoTesting then return false end
    if self._isClient and (self._battleType == Data.BattleType.unittest or self._battleType == Data.BattleType.teach) and (self._isAttacker and self._round == 1 and self._macroStatus == BattleData.Status.round_begin) then return false end

    if self._isFinished or self._opponent._isFinished then return true end
   
    local isFinished = false
    if self._isAttacker then
        isFinished = self:getIsLose() or self._opponent:getIsLose()
    else
        isFinished = self._opponent:getIsLose() or self:getIsLose()
    end
    
    if not isFinished then
        isFinished = self:getIsWin() or self._opponent:getIsWin()
    end

    return isFinished
end

function _M:getIsWin()
    return self._battleCondition:getIsWin()
end

function _M:getIsLose()
    --if retreat game
    if self._isRetreat then
        return true
    end
    
    -- if round larger then 25, then attacker lose
    if self:getIsRoundExceed() then
        return true
    end
    
    -- if fortress hp equals 0, then lose
    if self:getIsFortressDied() then
        return true
    end
    
    -- if not have more cards, or only remain horse then lose
    if self:getIsAllCardsDied() then
        return true
    end 

    -- pile empty
    if self._macroStatus == BattleData.Status.round_begin and self:getIsPileEmpty() and self._battleType ~= Data.BattleType.teach then
        return true
    end

    -- ball empty
    if self._ball == 0 then
        return true 
    end

    -- no main monster
    if self._macroStatus == BattleData.Status.round_begin and #self:getBattleCards('B') == 0 then 
        return true
    end

    --[[
    -- 3190
    local cards = self._opponent:getBattleCardsBySkills('H', {3190})
    if #cards > 0 then
        local info = Data._skillInfo[3190]
        local totalCount = 0
        local exists = {}
        cards = self._opponent:getBattleCardsByType('H', Data.CardType.monster)
        for i = 1, #cards do
            local infoId = cards[i]._infoId
            for j = 1, #info._refCards do
                if infoId == info._refCards[j] then 
                    if exists[j] == nil then
                        exists[j] = true 
                        totalCount = totalCount + 1
                    end
                end
            end
        end
        if totalCount == #info._refCards then 
            self._opponent._winBy3190 = true
            return true 
        end
    end
    ]]
    
    return false
end

function _M:getIsPileEmpty()
    return #self._pileCards == 0 
        and not (self._baseBattleType == Data.BattleType.base_PVE and not self._isAttacker) 
        and not (self._isClient and (ClientData._isTesting or P._guideID < 100))
end

function _M:getIsRoundExceed()
   -- if round larger then 25, then attacker lose
   local isRoundExceed = (self._round >= self._maxRound and self._opponent._round >= self._maxRound) 
        and (self._macroStatus == BattleData.Status.round_end or self._macroStatus == BattleData.Status.battle_end) 
        and (self._opponent._macroStatus == BattleData.Status.round_end or self._opponent._macroStatus == BattleData.Status.battle_end)

    if self._isOnlinePvp then return isRoundExceed
    else return self._isAttacker and isRoundExceed
    end
end

function _M:getIsFortressDied()
    -- if fortress hp equals 0, then lose
    return self._fortress._hp <= 0
end

function _M:getIsAllCardsDied()
    -- pile card
    if #self._pileCards > 0 then return false end

    -- board card
    if #self:getBattleCards('B') > 0 then return false end
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local boardCard = self._opponent._boardCards[i]
        if B.isAlive(boardCard) and boardCard._isBorrowed then
            return false
        end
    end
    
    -- hand card
    for i = 1, #self._handCards do
        local handCard = self._handCards[i]
        if handCard:isMonster() then
            return false
        elseif handCard._type == Data.CardType.magic and (self:canUseMagic(handCard, false)) then
            return false
        elseif handCard._type == Data.CardType.trap and (self:canUseTrap(handCard, false)) then
            return false
        end
    end
    
    -- cover card
    if #self:getBattleCards('CS') > 0 then return false end
    
    if #self._handCards > 0 then
        self._isRemainUnusable = true
    end

    return true
end

function _M:genResult(resultType)
    self._isFinished = true
    self._opponent._isFinished = true
        
    self._resultType = resultType
    self._opponent._resultType = (resultType == Data.BattleResult.draw) and resultType or -resultType
end

function _M:getResult()
    return self._resultType
end


-----------------------------------
-- battle step functions 
-----------------------------------
function _M:step()
    if self._isPaused then
        if self._pausedStatus == nil then
            self._pausedStatus = self._stepStatus
        end
        return
    end
    
    if self._stepStatus == BattleData.Status.battle_start then
        return self:start()
    elseif self._stepStatus == BattleData.Status.battle_end then
        return self:finish()
    elseif self._stepStatus == BattleData.Status.round_begin then
        return self:roundBegin()
    elseif self._stepStatus == BattleData.Status.deal then
        return self:deal()
    elseif self._stepStatus == BattleData.Status.use then
        return self:use()
    elseif self._stepStatus == BattleData.Status.action then
        return self:action()
    elseif self._stepStatus == BattleData.Status.round_end then
        return self:roundEnd()
    elseif self._stepStatus == BattleData.Status.initial_deal then
        return self:initialDeal()
    elseif self._stepStatus == BattleData.Status.select_main then
        return self:selectMain()
    
    elseif self._stepStatus == BattleData.Status.before_account_status then
        return self:beforeAccountStatus()
    elseif self._stepStatus == BattleData.Status.after_account_status then
        return self:afterAccountStatus()
    elseif self._stepStatus == BattleData.Status.before_account_reorder then 
        return self:beforeAccountReorder()
    elseif self._stepStatus == BattleData.Status.after_account_reorder then
        return self:afterAccountReorder()
    elseif self._stepStatus == BattleData.Status.before_account_pos_change then
        return self:beforeAccountPosChange()
    elseif self._stepStatus == BattleData.Status.after_account_pos_change then
        return self:afterAccountPosChange()
    elseif self._stepStatus == BattleData.Status.before_account_halo then
        return self:beforeAccountHalo()
    elseif self._stepStatus == BattleData.Status.after_account_halo then
        return self:afterAccountHalo()
    elseif self._stepStatus == BattleData.Status.before_account_spell then
        return self:beforeAccountSpell()
    elseif self._stepStatus == BattleData.Status.after_account_spell then
        return self:afterAccountSpell()
    elseif self._stepStatus == BattleData.Status.before_account_attack then 
        return self:beforeAccountAttack()
    elseif self._stepStatus == BattleData.Status.after_account_attack then
        return self:afterAccountAttack()
    elseif self._stepStatus == BattleData.Status.before_account_event then
        return self:beforeAccountEvent()
    elseif self._stepStatus == BattleData.Status.after_account_event then
        return self:afterAccountEvent()
    elseif self._stepStatus == BattleData.Status.before_account_finish then
        return self:beforeAccountFinish()
    elseif self._stepStatus == BattleData.Status.after_account_finish then
        return self:afterAccountFinish()
    elseif self._stepStatus == BattleData.Status.before_account_trap then
        return self:beforeAccountTrap()
    elseif self._stepStatus == BattleData.Status.after_account_trap then
        return self:afterAccountTrap()
    
    elseif self._stepStatus == BattleData.Status.account_status then
        return self:accountStatus()
    elseif self._stepStatus == BattleData.Status.account_reorder then
        return self:accountReorder()
    elseif self._stepStatus == BattleData.Status.account_pos_change then
        return self:accountPosChange()
    elseif self._stepStatus == BattleData.Status.account_halo then
        return self:accountHalo()
    elseif self._stepStatus == BattleData.Status.account_trap then
        return self:accountTrap()
       
    elseif self._stepStatus == BattleData.Status.spelling then
        return self:spelling()
    elseif self._stepStatus == BattleData.Status.under_spell then
        return self:underSpell()
    elseif self._stepStatus == BattleData.Status.under_defend_spell then
        return self:underDefendSpell()
    elseif self._stepStatus == BattleData.Status.under_spell_damage then
        return self:underSpellDamage()
    elseif self._stepStatus == BattleData.Status.under_counter_spell then
        return self:underCounterSpell()
    elseif self._stepStatus == BattleData.Status.account_spell then
        return self:accountSpell()
    elseif self._stepStatus == BattleData.Status.after_spell then
        return self:afterSpell()
    elseif self._stepStatus == BattleData.Status.end_spell then
        return self:endSpell()
     
    elseif self._stepStatus == BattleData.Status.account_event then
        return self:accountEvent()
    elseif self._stepStatus == BattleData.Status.account_finish then
        return self:accountFinish()
    
    elseif self._stepStatus == BattleData.Status.try_use_card then
        return self:tryUseCard()
    elseif self._stepStatus == BattleData.Status.do_use_card then
        return self:doUseCard()     
    elseif self._stepStatus == BattleData.Status.wait_oppo_use_card then
        return self:waitOppoUseCard()
    elseif self._stepStatus == BattleData.Status.wait_observe_use_card then
        return self:waitObserveUseCard()
    end
end

function _M:start()
    if self._macroStatus ~= BattleData.Status.battle_start then
        self:battleLog("[BATTLE] ==================================")
        
        self._macroStatus = BattleData.Status.battle_start
        
        self._stepStatus = BattleData.Status.battle_start
        self._opponent._stepStatus = BattleData.Status.wait_opponent

        -- events
        local type = BattleEvent.EventType.battle_start
        local events = self:getEvents(type)
        for i = 1, #events do
            local event = events[i]
            self:changeEvent(event, type)
        end
        
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.battle_start)
        end
    end
    
    -- events
    if next(self._eventToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_event
        return self:step()
    end

    self._stepStatus = ((not self._isInitialDealed) and self._round == 0) and BattleData.Status.initial_deal or BattleData.Status.round_begin
    return self:step()
end

function _M:finish()
    if self._macroStatus ~= BattleData.Status.battle_end then
        self:battleLog("[BATTLE] ==================================")

        local resultType = Data.BattleResult.draw
        local isSelfLose = self:getIsLose()
        local isOppoLose = self._opponent:getIsLose()
        if isSelfLose ~= isOppoLose then
            resultType = isSelfLose and Data.BattleResult.lose or Data.BattleResult.win
        elseif isSelfLose then -- both true
            if self._isOnlinePvp ~= true then
                -- attacker lose by exceed round
                resultType = self._isAttacker and Data.BattleResult.lose or Data.BattleResult.win
            end
        else -- both false
            if self._isOnlinePvp ~= true then
                -- attacker win by condition
                resultType = self._isAttacker and Data.BattleResult.win or Data.BattleResult.lose
            end
        end 

        --must behind calc isSelfLose and isOppoLose
        self._macroStatus = BattleData.Status.battle_end

        self:genResult(resultType)
        
        -- events
        local type = BattleEvent.EventType.battle_end
        local events = self:getEvents(type)
        for i = 1, #events do
            local event = events[i]
            self:changeEvent(event, type)
        end
        
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.battle_end)
        end
    end
    
    -- events
    if next(self._eventToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_event
        return self:step()
    end

    if self._battleType == Data.BattleType.unittest then
        BattleTestData.dealTestResult()
    elseif not self._isReviewing then
        return self:sendEvent(BattleData.Status.send_battle_end)
    end
end

function _M:initialDeal()
    if self._macroStatus ~= BattleData.Status.initial_deal then
        --log
        self:battleLog("")
        self:battleLog("[BATTLE] <INITIAL DEAL>")

        -- reset
        self._isInitialDealed = true
        self._macroStatus = BattleData.Status.initial_deal
        self._normalStatus = BattleData.Status.default
        self._initialDealIndex = 0 
        self:resetWhenInitialDeal()
        self._opponent:resetWhenInitialDeal()
    end

    -- check need stop in skilAllStory
    if self._isForwarding and self._forwardToRound == 1 then
        return
	end
	  
	-- acccount status
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
        return self:step()
    end
    
    if self._initialDealIndex == 0 then
        self:battleLog("")
        self:battleLog("[BATTLE] <INITIAL DEAL> 0")

        self._initialDealIndex = 1
        -- just send event
        if not self._isReviewing and (not self._opponent._isInitialDealed) then
            return self:sendEvent(BattleData.Status.initial_deal)
        end

    elseif self._initialDealIndex == 1 then
        self:battleLog("")
        self:battleLog("[BATTLE] <INITIAL DEAL> 1")

        if self._battleType == Data.BattleType.unittest then
            self._initialDealIndex = 6
        else
            self._initialDealIndex = 2
            -- pile to hand
            local count = math.min((self._isClient and P._guideID == 11) and 0 or Data.CARD_COUNT_OF_INITIAL_DEAL, math.min(#self._pileCards, Data.MAX_CARD_COUNT_IN_HAND - #self._handCards))
            for i = 1, count do
                local card = self._pileCards[i]
                --if not (self._isClient and (P._guideID >= 41 and P._guideID < 51) and card._infoId == 10036) then 
                    self:changeCardStatus(card, BattleData.CardStatus.pile, BattleData.CardStatus.hand)
                --end
            end
        end

    elseif self._initialDealIndex == 2 then
        self:battleLog("")
        self:battleLog("[BATTLE] <INITIAL DEAL> 2")

        -- try select monsters
        if #self:getBattleCardsByLevel('H', 0) > 0 then
            self._initialDealIndex = 3

            if self._playerType ~= BattleData.PlayerType.replay and not self._isReviewing then
                return self:sendEvent(BattleData.Status.initial_deal)
            else
                local type, ids = self:replayUseCard()
                if type == nil then
                    type, ids = self._ai:aiChooseMainWhenInitialDeal()
                end
                return self:useCard(type, ids)
            end
        else
            self._initialDealIndex = 5
            if not self._isReviewing then
                return self:sendEvent(BattleData.Status.initial_deal)
            end
        end

    elseif self._initialDealIndex == 3 then
        self:battleLog("")
        self:battleLog("[BATTLE] <INITIAL DEAL> 3")

        if #self:getBattleCardsByLevel('H', 0, Data.CARD_MAX_LEVEL, self._boardCards[1]) > 0 then
            self._initialDealIndex = 4
            if self._playerType ~= BattleData.PlayerType.replay and not self._isReviewing then
                return self:sendEvent(BattleData.Status.initial_deal)
            else
                local type, ids = self:replayUseCard()
                if type == nil then
                    type, ids = self._ai:aiChooseBackupWhenInitialDeal()
                end
                return self:useCard(type, ids)
            end
        else
            self._initialDealIndex = 6
        end

    elseif self._initialDealIndex == 4 then
        self:battleLog("")
        self:battleLog("[BATTLE] <INITIAL DEAL> 4")

        self._initialDealIndex = 6
        
    elseif self._initialDealIndex == 5 then
        self:battleLog("")
        self:battleLog("[BATTLE] <INITIAL DEAL> 5")

        -- swap pile and hand
        self._initialDealIndex = 2
        -- pile to hand
        for i = 1, #self._handCards do
            self:changeCardStatus(self._handCards[i], BattleData.CardStatus.hand, BattleData.CardStatus.pile)
        end
        local count = math.min((self._isClient and P._guideID == 11) and 0 or Data.CARD_COUNT_OF_INITIAL_DEAL, math.min(#self._pileCards, Data.MAX_CARD_COUNT_IN_HAND - #self._handCards))
        for i = 1, count do
            local card = self._pileCards[i]
            --if not (self._isClient and (P._guideID >= 41 and P._guideID < 51) and card._infoId == 10036) then 
                self:changeCardStatus(card, BattleData.CardStatus.pile, BattleData.CardStatus.hand)
            --end
        end
         
    elseif self._initialDealIndex == 6 then
        self:battleLog("")
        self:battleLog("[BATTLE] <INITIAL DEAL> 6")

    	-- step
		if self._opponent._isInitialDealed then
			self._opponent._stepStatus = BattleData.Status.round_begin
			self._stepStatus = BattleData.Status.wait_opponent 
			return self._opponent:step()	
		else
			self._opponent._stepStatus = BattleData.Status.initial_deal
			self._stepStatus = BattleData.Status.wait_opponent 
			return self._opponent:step()	
		end
    end

    return self:step()
end

function _M:roundBegin()
    if self._macroStatus ~= BattleData.Status.round_begin then
        -- reset
        self._macroStatus = BattleData.Status.round_begin
        self._normalStatus = BattleData.Status.default
        self._fortressSkillDone = false
        self._reorderDone = false
        self._haloDone = false
        
        self:resetWhenRoundBegin()
        
        -- log
        local attacker = self._isAttacker and self or self._opponent
        local defender = self._isAttacker and self._opponent or self
        self:battleLog("")
        self:battleLog("[BATTLE] <BEGIN>")
        self:battleLog("[BATTLE] %s ROUND %02d, P%d, H%d, B%d, HP %d", Str(self._isAttacker and STR.SELF or STR.OPPONENT), self._round, #self._pileCards, #self._handCards, #self:getBattleCards('B'), self._fortress._hp)
        local str = "[BATTLE] [H] "
        for i = 1, #defender._handCards do str = str..self:cardName(defender._handCards[i])..'\t' end
        self:battleLog(str)
        str = "[BATTLE] [B] "
        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do if defender._boardCards[i] ~= nil then str = str..self:cardName(defender._boardCards[i])..'\t' end end
        self:battleLog(str)
        str = "[BATTLE] [B] "
        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do if attacker._boardCards[i] ~= nil then str = str..self:cardName(attacker._boardCards[i])..'\t' end end
        self:battleLog(str)
        local str = "[BATTLE] [H] " 
        for i = 1, #attacker._handCards do str = str..self:cardName(attacker._handCards[i])..'\t' end
        self:battleLog(str)

        -- clear status
        if self._round > 1 then
            self._actionCard = self:getBattleCards('B')[1] or self:getGhostCard()
            if self._actionCard ~= nil then
                self:resetActionCard()
                self:resetAccount()

                local cards = self:getBattleCards('BC')
                for i = 1, #cards do
                    local card = cards[i]
                    self:decNegativeStatus(card, BattleData.NEGATIVE_CLEAR_WHEN_ROUND_BEGIN, false, card._id, 0, Data.SkillMode.once)
                    self:decPositiveStatus(card, BattleData.POSITIVE_CLEAR_WHEN_ROUND_BEGIN, false, card._id, 0, Data.SkillMode.once)
                    card:decShieldWhenRoundBegin()
                end
                self._fortress:decShieldWhenRoundBegin()
            
                self:account()
                self:removeDeadCards()
            end
        end

        -- events
        local type = BattleEvent.EventType.round_begin
        local events = self:getEvents(type)
        for i = 1, #events do
            local event = events[i]
            self:changeEvent(event, type)
        end

        if self._isClient and self._isOnlinePvp and self._playerType ~= BattleData.PlayerType.replay then
            self:sendEvent(BattleData.Status.pvp_timing_begin)
        end

        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.round_begin)
        end
    end

    if self._isForwarding and self._round == self._forwardToRound then
        self:sendEvent(BattleData.Status.round_begin)
		return
	end

    -- check finish
    if self:checkFinish() then
        self._stepStatus = BattleData.Status.before_account_finish
        return self:step()
    end

    -- acccount status
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
        return self:step()
    end

    -- events
    if next(self._eventToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_event
        return self:step()
    end

    -- fortress skill
    if not self._fortressSkillDone and self._fortressSkill ~= nil then
        self._fortressSkillDone = true

        self._actionCard = self:getGhostCard()
        self:resetActionCard()
        self:resetAccount()

        self._spellType = Data.SkillMode.round_begin
        self._stepStatus = BattleData.Status.before_account_spell
        return self:step()
    end

    if not self._fortressSkillDone then
        self._fortressSkillDone = true

        self._actionCard = self._fortress
        self:resetActionCard()
        self:resetAccount()

        self._spellType = Data.SkillMode.round_begin
        self._stepStatus = BattleData.Status.before_account_spell
        return self:step()
    end


    -- card skills when round begin
    if not B.isAlive(self._cardInAction) then self._cardInAction = nil end
    local actionCard = self._cardInAction
    if actionCard == nil then
        local cards = B.mergeTable({self:getBattleCards('BS'), self._opponent:getBattleCards('BS')})
        for i = 1, #cards do
            local card = cards[i]
            if B.isAlive(card) and (card._actionIndex <= card._actionCount) then
                actionCard = card
                break
            end
        end
    end

    if actionCard == nil then
        local cards = B.mergeTable({self:getBattleCardsBySkillMode('G', Data.SkillMode.in_grave), self._opponent:getBattleCardsBySkillMode('G', Data.SkillMode.in_grave)})
        for i = 1, #cards do
            local card = cards[i]
            if card._actionIndex <= card._actionCount then
                actionCard = card
                break
            end
        end
    end
    
    if actionCard ~= nil then
        if actionCard._actionIndex <= actionCard._actionCount then
            self._cardInAction = actionCard
            self._actionCard = actionCard
            self._spellType = actionCard._owner == self and Data.SkillMode.round_begin or Data.SkillMode.oppo_round_begin
            self._stepStatus = BattleData.Status.before_account_spell
            actionCard._actionIndex = actionCard._actionIndex + 1
            return self:step()
        else
            self._cardInAction = nil
            self._actionCard = nil
            self._stepStatus = BattleData.Status.round_begin
            return self:step()
        end
    end
    
    self._cardInAction = nil

    -- reorder
    if not self._reorderDone then
        self._reorderDone = true
        
        --self._stepStatus = BattleData.Status.before_account_reorder
        --return self:step()
    end

    -- account halo
    if not self._haloDone then
        self._haloDone = true
        self._stepStatus = BattleData.Status.before_account_halo
        return self:step()
    end
    
    -- step
    self._stepStatus = BattleData.Status.deal
    return self:step()
end

function _M:deal()
    if self._macroStatus ~= BattleData.Status.deal then
        --log
        self:battleLog("")
        self:battleLog("[BATTLE] <DEAL>")

        -- reset
        self._macroStatus = BattleData.Status.deal
        self._normalStatus = BattleData.Status.default

        -- temp leave
        local i = 1
        while true do
            local card = self._tempLeaveCards[i]
            if card == nil then break end
            if card._returnRound == self._round then
                self:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.hand)
                table.remove(self._tempLeaveCards, i)
            else
                i = i + 1
            end
        end

        if not self._isDealDisabled and self._round > 0 and not (self._isClient and (self._battleType == Data.BattleType.unittest or self._battleType == Data.BattleType.teach) and self._isAttacker and self._round <= 1) then
            if self._battleType == Data.BattleType.PVP_room and self._round == 1 then
                local card = B.createCard(20236, 1)
                self:addCardToCards(card)
                self:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.hand)
            else
                if #self._pileCards > 0 then
                    local count = math.min(Data.CARD_COUNT_OF_ROUND_DEAL, math.min(#self._pileCards, Data.MAX_CARD_COUNT_IN_HAND - #self._handCards))
                    for i = 1, count do
                        local card = self._pileCards[i]
                        if not (self._isClient and (P._guideID >= 41 and P._guideID < 51) and self._round == 1 and card._infoId == 10036) then 
                            self:changeCardStatus(card, BattleData.CardStatus.pile, BattleData.CardStatus.hand)
                        end
                    end
                end

                for i = 1, Data.POWER_DEAL_COUNT do
                    local card = B.createCard(39999, 1)
                    card._isTroopCard = true
                    card._status = BattleData.CardStatus.leave
                    self:addCardToCards(card)
                    self:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.hand)
                end

            end
        end

        self._isDealDisabled = false
        
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.deal)
        end
    end
    
    -- check finish
    if self:checkFinish() then
        self._stepStatus = BattleData.Status.before_account_finish
        return self:step()
    end
    
    -- acccount status
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
        return self:step()
    end
    
    -- step
    self._stepStatus = BattleData.Status.use
	return self:step()
end

function _M:use()
    if self._macroStatus ~= BattleData.Status.use then
        -- log
        self:battleLog("")
        self:battleLog("[BATTLE] <USE>")

        -- reset
        self._macroStatus = BattleData.Status.use
        self._normalStatus = BattleData.Status.default

        -- action index reset
        local cards = self:getBattleCards('B')
        for i = 1, #cards do
            cards[i]._actionIndex = 1
            cards[i]._actionCount = cards[i]:hasBuff(true, BattleData.PositiveType.actionCraze) and 2 or 1
        end
        
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.use)
        end
    end
    
    -- check finish
    if self:checkFinish() then
        self._stepStatus = BattleData.Status.before_account_finish
        return self:step()
    end

    -- acccount pos change
    if next(self._cardPosToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_pos_change
        return self:step()
    end

    -- acccount status
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
        return self:step()
    end

    -- check reorder
    --[[local needReorder = false
    for i = Data.MAX_CARD_COUNT_ON_BOARD, 2, -1 do
        if (not self:isBoardPosEmpty(i)) and self:isBoardPosEmpty(i - 1))
            or ((not self._opponent:isBoardPosEmpty(i)) and self._opponent:isBoardPosEmpty(i - 1)) then
            needReorder = true
            break
        end
    end
    if needReorder then
        self._stepStatus = BattleData.Status.before_account_reorder
        return self:step()
    end]]

    -- get use card, taret card
    local type, ids
    
    if self._isForwarding or self._playerType == BattleData.PlayerType.replay  or self._playerType == BattleData.PlayerType.observe or self._playerType == BattleData.PlayerType.opponent then
        type, ids = self:replayUseCard()

        if self._playerType == BattleData.PlayerType.replay and usedCard ~= nil then
            self:battleLog("")
            if usedCard._status == BattleData.CardStatus.hand then
                if targetCard ~= nil then
                    self:battleLog("[BATTLE] <REPLAY>\t%s  ^  %s", self:cardName(usedCard), self:cardName(targetCard))
                else
                    self:battleLog("[BATTLE] <REPLAY>\t%s", self:cardName(usedCard))
                end
            else
                if targetCard ~= nil then 
                    self:battleLog("[BATTLE] <REPLAY>\t%s <-> %s", self:cardName(usedCard), self:cardName(targetCard))
                else
                    self:battleLog("[BATTLE] <REPLAY>\t%s", self:cardName(usedCard))
                end
            end
        end

        if type == BattleData.UseCardType.retreat then
            if ids[1] == self._fortress._id then
                return self:retreat()
            else
                return self._opponent:retreat()
            end
        elseif type == BattleData.UseCardType.round then
            -- do nothing
        else
            if type == nil then
                if self._isForwarding then
                    return  -- return here to stop forwarding
                elseif self._playerType == BattleData.PlayerType.replay then
                    type, ids = self._ai:aiUseCard()
                elseif self._playerType == BattleData.PlayerType.observe then
                    return self:waitObserveUseCard()
                elseif self._playerType == BattleData.PlayerType.opponent then
                    return self:waitOppoUseCard()
                end
            end
        end

    elseif self._playerType == BattleData.PlayerType.player then
        return self:tryUseCard()
            
    elseif self._playerType == BattleData.PlayerType.ai then
        if self._ops and self._ops[self._replayIndex] then
            type, ids = self:replayUseCard()
        else
            type, ids = self._ai:aiUseCard()
        end

    end
    
    return self:useCard(type, ids)
end

function _M:action()
    if self._macroStatus ~= BattleData.Status.action then
        self:battleLog("")
        self:battleLog("[BATTLE] <ACTION>")

        -- reset 
        self._macroStatus = BattleData.Status.action
        self._normalStatus = BattleData.Status.default
        
        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD * 2 do
            local boardCard = i <= Data.MAX_CARD_COUNT_ON_BOARD and self._boardCards[i] or self._opponent._boardCards[i - Data.MAX_CARD_COUNT_ON_BOARD]
            if B.isAlive(boardCard) then
                boardCard._actionIndex = 1
                boardCard._actionCount = 1
            end
        end
        
        self._cardInAction = nil
        self._actionStep = 1
        
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.action)
        end
    end
    
    -- check finish
    if self:checkFinish() then
        self._stepStatus = BattleData.Status.before_account_finish
        return self:step()
    end
    
    local actionCard = self._cardInAction
    if actionCard == nil then
        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
            local boardCard = self._boardCards[i]
            if B.isAlive(boardCard) and (boardCard._actionIndex <= boardCard._actionCount) then
                actionCard = boardCard
                break
            end
        end
    end
    
    if actionCard ~= nil then
        if self._actionStep == 1 then
            self._actionStep = self._actionStep + 1
            
            self._cardInAction = actionCard
            self._actionCard = actionCard
            self._spellType = Data.SkillMode.spelling
            self._stepStatus = BattleData.Status.before_account_spell
            return self:step()
            
        elseif self._actionStep == 2 then
            self._actionStep = 1
            
            actionCard._actionIndex = actionCard._actionIndex + 1
            self._cardInAction = nil
            self._actionCard = nil
            self._stepStatus = BattleData.Status.action
            return self:step()
        end
    end
    
    self._cardInAction = nil
    self._stepStatus = BattleData.Status.round_end
    return self:step()
end

function _M:roundEnd()
    if self._macroStatus ~= BattleData.Status.round_end then
        -- reset
        self._macroStatus = BattleData.Status.round_end
        self._normalStatus = BattleData.Status.default
        self._reorderDone = false
        self._eventDone = false
        self._haloDone = true
        self._fortressSkillDone = (self._round < 0)
        self._isSummonDisabled = false

        self._opponent._disableTrapBy4127 = nil

        if self._battleType == Data.BattleType.PVP_room and self._round == 1 then
            local card = self:getBattleCardsByInfoId('H', 20236)[1]
            if card ~= nil then
                self:setCardStatus(card, BattleData.CardStatus.leave, cid, id, mode)
                self:account()
            end
        end

        local cards = B.mergeTable({self:getBattleCards('BS'), self._opponent:getBattleCards('BS')})
        for i = 1, #cards do
            cards[i]._actionIndex = 1
            cards[i]._actionCount = 1
        end
        for i = 1, #self._delaySkillCards do
            local card = self._delaySkillCards[i]
            card._actionIndex = 1
            card._actionCount = 1
        end
        for i = 1, #self._opponent._delaySkillCards do
            local card = self._opponent._delaySkillCards[i]
            card._actionIndex = 1
            card._actionCount = 1
        end
        self._cardInAction = nil
        
        local aliveBoardCards = B.mergeTable({self:getBattleCards('B'), self._opponent:getBattleCards('B')})
        if #aliveBoardCards > 0 then
            self._actionCard = aliveBoardCards[1]
            self:resetActionCard()
            self:resetAccount()
            
            -- remove negative status, reset attack times, return borrowed cards
            local oppoEmptyPosCount, curReturnCount = 0, 0
            for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
                if self._opponent:isBoardPosEmpty(i) then
                    oppoEmptyPosCount = oppoEmptyPosCount + 1
                end
            end
            for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
                local boardCard = self._boardCards[i]
                if B.isAlive(boardCard) then
                    boardCard._actionCount = 1
                    self:decPositiveStatus(boardCard, BattleData.POSITIVE_CLEAR_WHEN_ROUND_END, false, boardCard._id, 0, Data.SkillMode.once)
                    if boardCard._isBorrowed then
                        if curReturnCount < oppoEmptyPosCount then
                            self:changeCardStatus(boardCard, BattleData.CardStatus.board, BattleData.CardStatus.board, BattleData.CardStatusVal.b2b_oppo_once)
                            curReturnCount = curReturnCount + 1
                        else
                            self:changeCardStatus(boardCard, BattleData.CardStatus.board, BattleData.CardStatus.hand, BattleData.CardStatusVal.b2h_oppo_once)
                            if boardCard._horse ~= nil then
                                self:changeCardStatus(boardCard._horse, BattleData.CardStatus.board, BattleData.CardStatus.hand)
                            end
                        end
                    else
                        self:decNegativeStatus(boardCard, BattleData.NEGATIVE_CLEAR_WHEN_ROUND_END, false, boardCard._id, 0, Data.SkillMode.once)
                        if boardCard:hasBuff(false, BattleData.NegativeType.atkFrozen) then  
                            local value = boardCard:getBuffValue(false, BattleData.NegativeType.atkFrozen)
                            if value <= 1 then
                                self:decNegativeStatus(boardCard, BattleData.NegativeType.atkFrozen, false, boardCard._id, 0, Data.SkillMode.once)
                            else
                                boardCard:modifyBuffValue(false, BattleData.NegativeType.atkFrozen, value - 1)
                            end
                        end
                    end

                    boardCard:removeUnderSkillByRemoveMode(Data.SkillMode.round_end)
                end

                boardCard = self._opponent._boardCards[i]
                if B.isAlive(boardCard) then
                    boardCard:removeUnderSkillByRemoveMode(Data.SkillMode.oppo_round_end)
                end
            end
            self._fortress._actionCount = 1
            self:decPositiveStatus(self._fortress, BattleData.POSITIVE_CLEAR_WHEN_ROUND_END, false, self._fortress._id, 0, Data.SkillMode.once)
            self:decNegativeStatus(self._fortress, BattleData.NEGATIVE_CLEAR_WHEN_ROUND_END, false, self._fortress._id, 0, Data.SkillMode.once)
            
            self:account()
            self:removeDeadCards()
        end
        
        if not self._isReviewing  then
            return self:sendEvent(BattleData.Status.round_end)
        end
    end
    
    -- check finish
    if self:checkFinish() then
        self._stepStatus = BattleData.Status.before_account_finish
        return self:step()
    end
    
    -- account halo
    if not self._haloDone then
        self._haloDone = true
        self._stepStatus = BattleData.Status.before_account_halo
        return self:step()
    end
    
    -- acccount status
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
        return self:step()
    end
    
    -- events
    if not self._eventDone then
        self._eventDone = true
        
        local type = BattleEvent.EventType.round_end
        local events = self:getEvents(type)
        for _, event in ipairs(events) do
            self:changeEvent(event, type)
        end
    end
    
    if next(self._eventToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_event
        return self:step()
    end

    -- fortress skill
    if not self._fortressSkillDone and self._fortressSkill ~= nil then
        self._fortressSkillDone = true

        self._actionCard = self:getGhostCard()
        self:resetActionCard()
        self:resetAccount()

        self._spellType = Data.SkillMode.round_end
        self._stepStatus = BattleData.Status.before_account_spell
        return self:step()
    end

    -- card skills when round end
    local actionCard = self._cardInAction
    if actionCard == nil then
        local cards = B.mergeTable({self:getBattleCards('BS'), self._opponent:getBattleCards('BS')})
        for i = 1, #cards do
            local card = cards[i]
            if B.isAlive(card) and (card._actionIndex <= card._actionCount) then
                actionCard = card
                break
            end
        end
        if actionCard == nil then
            for i = 1, #self._delaySkillCards do
                local card = self._delaySkillCards[i]
                if card:hasSkillInMode(Data.SkillMode.round_end) and card._actionIndex <= card._actionCount then
                    actionCard = card
                    table.remove(self._delaySkillCards, i)
                    break
                end
            end 
        end
        if actionCard == nil then
            for i = 1, #self._opponent._delaySkillCards do
                local card = self._opponent._delaySkillCards[i]
                if card:hasSkillInMode(Data.SkillMode.oppo_round_end) and card._actionIndex <= card._actionCount then
                    actionCard = card
                    table.remove(self._opponent._delaySkillCards, i)
                    break
                end
            end 
        end
    end
    
    if actionCard ~= nil then
        if actionCard._actionIndex <= actionCard._actionCount then
            self._cardInAction = actionCard
            self._actionCard = actionCard
            self._spellType = actionCard._owner == self and Data.SkillMode.round_end or Data.SkillMode.oppo_round_end
            self._stepStatus = BattleData.Status.before_account_spell
            actionCard._actionIndex = actionCard._actionIndex + 1
            return self:step()
        else
            self._cardInAction = nil
            self._actionCard = nil
            self._stepStatus = BattleData.Status.round_end
            return self:step()
        end
    end
    
    self._cardInAction = nil

    -- reorder
    if not self._reorderDone then
        self._reorderDone = true
        
        --self._stepStatus = BattleData.Status.before_account_reorder
        --return self:step()
    end

    self._stepStatus = BattleData.Status.select_main
    return self:step()

    --[[
    -- log
    self:battleLog("----------------------------------------------------------------\n\n")
    
    self._opponent._stepStatus = ((not self._opponent._isInitialDealed) and self._opponent._round == 0) and BattleData.Status.initial_deal or BattleData.Status.round_begin
    self._stepStatus = BattleData.Status.wait_opponent 
    return self._opponent:step()
    ]]
end

function _M:selectMain()
    if self._macroStatus ~= BattleData.Status.select_main then
        self:battleLog("")
        self:battleLog("[BATTLE] <SELECT MAIN>")

        -- reset
        self._macroStatus = BattleData.Status.select_main
        self._normalStatus = BattleData.Status.default

        if self._boardCards[1] == nil then
            local cards = self._player:getBattleCards('B')
            if #cards > 0 then
                if self._playerType ~= BattleData.PlayerType.replay and not self._isReviewing then
                    return self:sendEvent(BattleData.Status.select_main)
                else
                    local type, ids = self:replayUseCard()
                    if type == nil then
                        type, ids = self._ai:aiChooseMainWhenRoundEnd()
                    end
                    return self:useCard(type, ids)
                end 
            end
        end
    end

    -- acccount pos change
    if next(self._cardPosToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_pos_change
        return self:step()
    end

    -- log
    self:battleLog("----------------------------------------------------------------\n\n")
    
    self._opponent._stepStatus = ((not self._opponent._isInitialDealed) and self._opponent._round == 0) and BattleData.Status.initial_deal or BattleData.Status.round_begin
    self._stepStatus = BattleData.Status.wait_opponent 
    return self._opponent:step()
    
end

----------------------------------------------------------------------
-- change status
----------------------------------------------------------------------

function _M:beforeAccountStatus()
    local statusChangeNode = self._cardStatusToChange[1]
    table.remove(self._cardStatusToChange, 1)
     
    local card = statusChangeNode._card
    card._sourceStatus = statusChangeNode._sourceStatus
    card._destStatus = statusChangeNode._destStatus
    card._statusVal = statusChangeNode._statusVal
    card._triggerCard = statusChangeNode._triggerCard
    
    self:saveStatus()
    self._actionCard = card
    self:resetActionCard()

    -- skip this
    if card._sourceStatus ~= card._status then
        self._stepStatus = BattleData.Status.after_account_status
        return self:step()
    end
    
    self._stepStatus = BattleData.Status.account_status
    self._normalStatus = BattleData.Status.default
    return self:step()
end

function _M:afterAccountStatus()
    if self._normalStatus ~= BattleData.Status.after_account_status then
        -- reset
        self._normalStatus = BattleData.Status.after_account_status
        self._eventDone = false
        self._costSpellDone = false
        self._spellDone = false
        self._trapDone = false
        
        local card = self._actionCard
        local sourceStatus, destStatus = card._sourceStatus, card._destStatus

        --self._haloDone = not ((card._type == Data.CardType.magic or card._type == Data.CardType.trap) and destStatus == BattleData.CardStatus.show) -- cause bind is in using phase
        self._haloDone = false

        -- halo 1
        if (card:isMonster() and (destStatus == BattleData.CardStatus.board or sourceStatus == BattleData.CardStatus.board or destStatus == BattleData.CardStatus.grave or sourceStatus == BattleData.CardStatus.grave))
            or ((card._type == Data.CardType.magic or card._type == Data.CardType.trap) and (destStatus == BattleData.CardStatus.show or sourceStatus == BattleData.CardStatus.show or destStatus == BattleData.CardStatus.grave or sourceStatus == BattleData.CardStatus.grave)) then
            self._stepStatus = BattleData.Status.before_account_halo
            return self:step()
        end
    end

    local card = self._actionCard

    -- cost spell, before trap
    if not self._costSpellDone then
        self._costSpellDone = true
        
        local sourceStatus, destStatus = card._sourceStatus, card._destStatus

        if card:isMonster() then
            if sourceStatus ~= BattleData.CardStatus.board and destStatus == BattleData.CardStatus.board then
                self._spellType = Data.SkillMode.cost
                self._stepStatus = BattleData.Status.before_account_spell
                return self:step()
            end
        end
    end

    -- trap
    if not self._trapDone then  
        self._trapDone = true
        self._stepStatus = BattleData.Status.before_account_trap
        return self:step()
    end
    
    -- other spell, after trap
    if not self._spellDone then
        self._spellDone = true
        
        local sourceStatus, destStatus, triggerCard = card._sourceStatus, card._destStatus, card._triggerCard
        
        -- spell by card type
        if card:isMonster() then
            if sourceStatus == BattleData.CardStatus.grave and destStatus == BattleData.CardStatus.board then
                self._spellType = Data.SkillMode.g2b
                self._stepStatus = BattleData.Status.before_account_spell
                return self:step()
            elseif sourceStatus ~= BattleData.CardStatus.board and destStatus == BattleData.CardStatus.board then
                self._spellType = Data.SkillMode.using
                self._stepStatus = BattleData.Status.before_account_spell
                return self:step()
            elseif sourceStatus == BattleData.CardStatus.board and (destStatus == BattleData.CardStatus.grave or destStatus == BattleData.CardStatus.leave) then
                self._spellType = card._statusVal ~= BattleData.CardStatusVal.b2g_sacrifice and Data.SkillMode.bcs2gl or Data.SkillMode.sacrifice
                self._stepStatus = BattleData.Status.before_account_spell
                return self:step()
            elseif sourceStatus == BattleData.CardStatus.board and destStatus ~= BattleData.CardStatus.board then
                self._spellType = card._statusVal ~= BattleData.CardStatusVal.b2g_sacrifice and Data.SkillMode.bcs2_ or Data.SkillMode.sacrifice
                self._stepStatus = BattleData.Status.before_account_spell
                return self:step()
            elseif sourceStatus == BattleData.CardStatus.hand and (destStatus == BattleData.CardStatus.grave or destStatus == BattleData.CardStatus.leave) and card._statusVal ~= BattleData.CardStatusVal.h2g_drop then
                if triggerCard ~= nil then
                    self._spellType = triggerCard._owner ~= card._owner and Data.SkillMode.h2g_by_oppo or Data.SkillMode.h2g_by_self
                    self._stepStatus = BattleData.Status.before_account_spell
                    return self:step()
                end
             elseif sourceStatus == BattleData.CardStatus.pile and (destStatus == BattleData.CardStatus.grave or destStatus == BattleData.CardStatus.leave) then
                if triggerCard ~= nil then
                    self._spellType = triggerCard._owner ~= card._owner and Data.SkillMode.p2g_by_oppo or Data.SkillMode.p2g_by_self
                    self._stepStatus = BattleData.Status.before_account_spell
                    return self:step()
                end
            end
        elseif card._type == Data.CardType.magic then
            if sourceStatus == BattleData.CardStatus.hand and 
                ((destStatus == BattleData.CardStatus.grave or destStatus == BattleData.CardStatus.leave) and card._statusVal == BattleData.CardStatusVal.h2g_magic) or (destStatus == BattleData.CardStatus.show) then
                card._owner._totalCastedMagicCount = card._owner._totalCastedMagicCount + 1
                self._spellType = Data.SkillMode.magic
                self._stepStatus = BattleData.Status.before_account_spell
                return self:step()
            elseif sourceStatus == BattleData.CardStatus.show and (destStatus == BattleData.CardStatus.grave or destStatus == BattleData.CardStatus.leave) then
                self._spellType = Data.SkillMode.bcs2gl
                self._stepStatus = BattleData.Status.before_account_spell
                return self:step()
            elseif sourceStatus == BattleData.CardStatus.show and destStatus ~= BattleData.CardStatus.show then
                self._spellType = Data.SkillMode.bcs2_
                self._stepStatus = BattleData.Status.before_account_spell
                return self:step()
            elseif sourceStatus == BattleData.CardStatus.hand and (destStatus == BattleData.CardStatus.grave or destStatus == BattleData.CardStatus.leave) and card._statusVal ~= BattleData.CardStatusVal.h2g_magic then
                if triggerCard ~= nil then
                    self._spellType = triggerCard._owner ~= card._owner and Data.SkillMode.h2g_by_oppo or Data.SkillMode.h2g_by_self
                    self._stepStatus = BattleData.Status.before_account_spell
                    return self:step()
                end
            elseif sourceStatus == BattleData.CardStatus.pile and (destStatus == BattleData.CardStatus.grave or destStatus == BattleData.CardStatus.leave) then
                if triggerCard ~= nil then
                    self._spellType = triggerCard._owner ~= card._owner and Data.SkillMode.p2g_by_oppo or Data.SkillMode.p2g_by_self
                    self._stepStatus = BattleData.Status.before_account_spell
                    return self:step()
                end
            end
        elseif card._type == Data.CardType.fortress then
            if card._statusVal == BattleData.CardStatusVal.f2f_fortress_damaged then
                self._spellType = Data.SkillMode.fortress_damaged
                self._stepStatus = BattleData.Status.before_account_spell
                return self:step()
            elseif card._statusVal == BattleData.CardStatusVal.f2f_halo then
                self._haloDone = false
            end
            
        end
    end

    -- halo 2
    if not self._haloDone then
        self._haloDone = true
        self._stepStatus = BattleData.Status.before_account_halo
        return self:step()
    end
    
    if not self._eventDone then 
        self._eventDone = true

        local type = BattleEvent.EventType.after_status_change
        if type ~= nil then
            local events = self:getEvents(type)
            for _, event in ipairs(events) do
                self:changeEvent(event, type)
            end
        end
    end
    
    if next(self._eventToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_event
        return self:step()
    end

    card._sourceStatus, card._destStatus, card._statusVal, card._triggerCard = nil, nil, nil, nil
    self._normalStatus = BattleData.Status.default
    return self:loadStatus()
end

function _M:beforeAccountReorder()
    self:saveStatus() 
    
    local tempActionCard = nil
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD * 2 do
        local card = (i <= Data.MAX_CARD_COUNT_ON_BOARD) and self._boardCards[i] or self._opponent._boardCards[i - Data.MAX_CARD_COUNT_ON_BOARD]
        if B.isAlive(card) then
            tempActionCard = card
            break
        end 
    end 
    
    if tempActionCard == nil then
        self._stepStatus = BattleData.Status.after_account_reorder
        return self:step()
    end
     
    self._actionCard = tempActionCard
    self:resetActionCard()
    
    self._normalStatus = BattleData.Status.default
    self._stepStatus = BattleData.Status.account_reorder
    return self:step()
end

function _M:afterAccountReorder()
    if self._normalStatus ~= BattleData.Status.after_account_reorder then
        -- reset
        self._normalStatus = BattleData.Status.after_account_reorder
        
        -- halo
        self._stepStatus = BattleData.Status.before_account_halo
        return self:step()
    end
    
    self._normalStatus = BattleData.Status.default
    return self:loadStatus()
end

function _M:beforeAccountPosChange()
    self:saveStatus()
    
    local cardPosToChange = {}
    for i = 1, #self._cardPosToChange do
        local boardCard = self._cardPosToChange[i]._card
        if B.isAlive(boardCard) then
            table.insert(cardPosToChange, boardCard)
        end
    end

    if #cardPosToChange == 0 then
        self._stepStatus = BattleData.Status.after_account_pos_change
        return self:step()
    end
     
    self._normalStatus = BattleData.Status.default
    self._stepStatus = BattleData.Status.account_pos_change
    return self:step()
end

function _M:afterAccountPosChange()
    if self._normalStatus ~= BattleData.Status.after_account_pos_change then
        -- reset
        self._normalStatus = BattleData.Status.after_account_pos_change
        self._cardPosToChange = {}
        
        -- halo
        self._stepStatus = BattleData.Status.before_account_halo
        return self:step()
    end
    
    self._normalStatus = BattleData.Status.default
    return self:loadStatus()
end

function _M:beforeAccountHalo()
    self:saveStatus() 
    
    local actionCard = self._actionCard 
    if actionCard == nil then
        actionCard = nil
        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD * 2 do
            local card = (i <= Data.MAX_CARD_COUNT_ON_BOARD) and self._boardCards[i] or self._opponent._boardCards[i - Data.MAX_CARD_COUNT_ON_BOARD]
            if B.isAlive(card) then
                actionCard = card
                break
            end 
        end 
    end
    if actionCard == nil then
        self._stepStatus = BattleData.Status.after_account_halo
        return self:step()
    end

    self._actionCard = actionCard
    self:resetActionCard()

    self._normalStatus = BattleData.Status.default
    self._stepStatus = BattleData.Status.account_halo
    return self:step()
end

function _M:afterAccountHalo()
    self._normalStatus = BattleData.Status.default
    return self:loadStatus()
end

function _M:beforeAccountSpell()
    self:saveStatus()
    self:resetActionCard()
    
    self._spellIndex = 0
    self._spellCountIndex = 0
    
    self._stepStatus = BattleData.Status.spelling
    self._normalStatus = BattleData.Status.default
    return self:step()
end

function _M:afterAccountSpell()
    self._normalStatus = BattleData.Status.default
    return self:loadStatus()
end

function _M:beforeAccountEvent()
    local eventChangeNode = self._eventToChange[1]
    table.remove(self._eventToChange, 1)
     
    local event = eventChangeNode._event
    local type = eventChangeNode._type
    
    self:saveStatus()
    
    if not event._owner:getIsEventSatisfied(event) then
        self._stepStatus = BattleData.Status.after_account_event
        return self:step()
    end
    
    self._actionEvent = event
    if self._actionCard == nil then
        self._actionCard = self._cards[1] or self._opponent._cards[1] or self:getGhostCard()
    end
    self:resetActionCard()
        
    self._normalStatus = BattleData.Status.default
    self._stepStatus = BattleData.Status.account_event
    return self:step()
end

function _M:afterAccountEvent()
    self._normalStatus = BattleData.Status.default
    return self:loadStatus()
end

function _M:beforeAccountFinish()
    self:saveStatus()
    
    self._normalStatus = BattleData.Status.default
    self._stepStatus = BattleData.Status.account_finish
    return self:step()
end

function _M:afterAccountFinish()
    self._normalStatus = BattleData.Status.default
    
    if self:checkFinish() then
        self._saved = {}
        self._stepStatus = BattleData.Status.battle_end
        return self:step()
    else
        return self:loadStatus()
    end
end

function _M:beforeAccountTrap()
    self:saveStatus()
    self:resetActionCard()
    
    self._stepStatus = BattleData.Status.account_trap
    self._normalStatus = BattleData.Status.default
    return self:step()
end

function _M:afterAccountTrap()
    self._normalStatus = BattleData.Status.default
    return self:loadStatus()
end

----------------------------------------------------------------------
-- normal status
----------------------------------------------------------------------

function _M:tryUseCard()
    if self._isPaused then return end

    if self._normalStatus ~= BattleData.Status.try_use_card then
        self._normalStatus = BattleData.Status.try_use_card
        
        -- events
        local type = BattleEvent.EventType.try_use_card
        local events = self:getEvents(type)
        for _, event in ipairs(events) do
            self:changeEvent(event, type)
        end
    end

    -- events
    if next(self._eventToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_event
        return self:step()
    end
    
    self._normalStatus = BattleData.Status.default
    return self:sendEvent(BattleData.Status.try_use_card)
end

function _M:doUseCard(type, ids)
    if self._isPaused then return end

    if self._normalStatus ~= BattleData.Status.do_use_card then
        self._normalStatus = BattleData.Status.do_use_card
        
        self._cardToTryUse = {_type = type, _ids = ids}
        
        -- events
        local type = BattleEvent.EventType.do_use_card
        local events = self:getEvents(type)
        for _, event in ipairs(events) do
            self:changeEvent(event, type)
        end
    end
    
    -- events
    if next(self._eventToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_event
        return self:step()
    end

    -- use card
    self._normalStatus = BattleData.Status.default
    
    local type, ids = self._cardToTryUse._type, self._cardToTryUse._ids
    self._cardToTryUse = {}
    
    return self:useCard(type, ids)
end

function _M:waitOppoUseCard()
    return self:sendEvent(BattleData.Status.wait_oppo_use_card)
end

function _M:waitObserveUseCard()
    return self:sendEvent(BattleData.Status.wait_observe_use_card)
end

function _M:useCard(type, ids)
    if type == BattleData.UseCardType.retreat then
        if ids[1] == self._fortress._id then
            return self:retreat()
        else
            return self._opponent:retreat()
        end
    elseif type == BattleData.UseCardType.round then
        return self:endRound(type, ids)

    elseif type == BattleData.UseCardType.init_b1 then
        return self:initMainMonster(type, ids)
    elseif type == BattleData.UseCardType.init_bx then
        return self:initBackupMonsters(type, ids)

    elseif type == BattleData.UseCardType.h2b then
        return self:monsterToBoard(type, ids)
    elseif type == BattleData.UseCardType.swap then
        return self:drawbackMonster(type, ids)
    elseif type == BattleData.UseCardType.drop then
        return self:dropHandCard(type, ids)

    elseif type == BattleData.UseCardType.spell then
        return self:useSpell(type, ids)
    end
end

function _M:endRound(type, ids)

    --[[ TODO
    if self._battleType == Data.BattleType.unittest and self._round > 0 then
        local usedCards = self._isAttacker and BattleTestData._playerUsedCards or BattleTestData._opponentUsedCards
        usedCards[#usedCards + 1] = 1
        usedCards[#usedCards + 1] = self._round
        usedCards[#usedCards + 1] = 0
    end
    ]]

    self._stepStatus = BattleData.Status.round_end
    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.use_card, type, ids)
    else
        return self:step()
    end
end

function _M:initMainMonster(type, ids)
    self:battleLog("[BATTLE] <INIT MAIN> %d", ids[1])

    local card = self:getCardById(ids[1])
    self:changeCardStatus(card, BattleData.CardStatus.hand, BattleData.CardStatus.board)

    self._stepStatus = BattleData.Status.initial_deal
    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.use_card, type, ids)
    else
        return self:step()
    end
end

function _M:initBackupMonsters(type, ids)
    self:battleLog("[BATTLE] <INIT BACKUP> %d, %d, %d, %d, %d", #ids, ids[1] or 0, ids[2] or 0, ids[3] or 0, ids[4] or 0)

    for i = 1, #ids do
        local card = self:getCardById(ids[i])
        self:changeCardStatus(card, BattleData.CardStatus.hand, BattleData.CardStatus.board)
    end

    self._stepStatus = BattleData.Status.initial_deal
    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.use_card, type, ids)
    else
        return self:step()
    end
end

function _M:monsterToBoard(type, ids)
    self:battleLog("[BATTLE] <USE CARD> %d, %d, %d, %d", ids[1] or 0, ids[2] or 0, ids[3] or 0, ids[4] or 0)

    local card = self:getCardById(ids[1])
    self._actionCard = card
    self:resetActionCard()
    self:resetAccount()

    --[[ TODO
    if self._battleType == Data.BattleType.unittest then
        local usedCards = self._isAttacker and BattleTestData._playerUsedCards or BattleTestData._opponentUsedCards
        usedCards[#usedCards + 1] = card and card._id or 0
        usedCards[#usedCards + 1] = target and target._id or 0
        usedCards[#usedCards + 1] = choice or 0
    end
    ]]

    --[[
    if card:isMonster() then
        if card._status == BattleData.CardStatus.hand then 
            if summonChoice == 1 then
                self._isNormalSummoned = true
            elseif summonChoice == 2 then
                local usedUnderSkill, usedIndex = nil, nil
                for i = 1, #self._gemUnderSkills do
                    local underSkill = self._gemUnderSkills[i]
                    if underSkill._sid == 3007 then
                        if card:getStar() <= underSkill._val then
                            usedUnderSkill, usedIndex = underSkill, i
                            break
                        end
                    elseif underSkill._sid == 3144 then
                        if card._info._keyword == underSkill._val then
                            usedUnderSkill, usedIndex = underSkill, i
                            break
                        end
                    elseif underSkill._sid == 3161 or underSkill._sid == 4058 then
                        if card._info._category == underSkill._val then
                            usedUnderSkill, usedIndex = underSkill, i
                            break
                        end
                    elseif underSkill._sid == 4068 then
                        usedUnderSkill, usedIndex = underSkill, i
                        break
                    elseif underSkill._sid == 7063 then
                        if card._info._category == underSkill._val and #self:getBattleCards('B') == 0 then
                            usedUnderSkill, usedIndex = underSkill, i
                            break
                        end
                    end
                end
                
                if usedUnderSkill ~= nil then
                    if usedUnderSkill._count == 1 then
                        table.remove(self._gemUnderSkills, usedIndex)
                    else
                        usedUnderSkill._count = usedUnderSkill._count - 1
                    end
                end
            end
        end
    end
    ]]

    card._ids = ids
    
    local nextStepStatus = BattleData.Status.before_account_status

    if card._status == BattleData.CardStatus.hand then
        if card._type == Data.CardType.magic then
            
        else
            if card._info._level == 0 then
                card._isEvolved = true
                self:changeCardStatus(card, BattleData.CardStatus.hand, BattleData.CardStatus.board, BattleData.CardStatusVal.h2b_normal)
            else
                local baseCard = self:getCardById(ids[2])
                local bindCard = baseCard._binds[1]
                self:changeCardStatus(baseCard, BattleData.CardStatus.board, BattleData.CardStatus.leave, BattleData.CardStatusVal.b2l_evolve)
                card._baseCard = baseCard
                card._isEvolved = true
                card._saved._pos = baseCard._pos
                card._saved._powerMark = baseCard:getBuffValue(true, BattleData.PositiveType.powerMark)
                card._saved._bind = bindCard
                card._updateHp = card._maxHp - (baseCard._maxHp - baseCard._hp)
                self:changeCardStatus(card, BattleData.CardStatus.hand, BattleData.CardStatus.board, BattleData.CardStatusVal.h2b_normal)
            end            
        end
    end

    self._stepStatus = nextStepStatus
    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.use_card, type, ids)
    else
        return self:step()
    end
end

function _M:drawbackMonster(type, ids)
    local card = self:getCardById(ids[1])
    self:changeCardPos(card, BattleData.CardPosChange.swap)

    local mainCard = self._boardCards[1]
    if mainCard ~= nil then
        self:changeCardPos(mainCard, BattleData.CardPosChange.swap)
    end

    self._cardInAction = nil
    self._actionCard = mainCard or card

    self._stepStatus = self._macroStatus == BattleData.Status.select_main and BattleData.Status.select_main or BattleData.Status.use

    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.use_card, type, ids)
    else
        return self:step()
    end
end

function _M:dropHandCard(type, ids)
    local card = self:getCardById(ids[1])
    self:changeCardStatus(card, BattleData.CardStatus.hand, BattleData.CardStatus.grave)

    self._stepStatus = BattleData.Status.use

    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.use_card, type, ids)
    else
        return self:step()
    end
end

function _M:useSpell(type, ids)
    local card = self:getCardById(ids[1])
    card._ids = ids

    self._actionCard = card
    local skill = card:getSkillById(ids[2])
    if card:isMonster() then
        self._spellType = Data.SkillMode.initiative
    elseif card._type == Data.CardType.magic then
        self._spellType = Data.SkillMode.magic
    end
    self._stepStatus = BattleData.Status.before_account_spell

    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.use_card, type, ids)
    else
        return self:step()
    end
end

function _M:replayUseCard()
    local op = self._ops[self._replayIndex]
    local opponentOp = self._opponent._ops[self._opponent._replayIndex]

    if op ~= nil then
        self._replayIndex = self._replayIndex + 1
        return op._type, op._ids
    end
end

function _M:accountStatus()
    if self._normalStatus ~= BattleData.Status.account_status then
        self._normalStatus = BattleData.Status.account_status
        self._eventDone = false
    end


    if not self._eventDone then
        self._eventDone = true
        local type = BattleEvent.EventType.before_status_change
        if type ~= nil then
            local events = self:getEvents(type)
            for _, event in ipairs(events) do
                self:changeEvent(event, type)
            end
        end
    end
    
    if next(self._eventToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_event
        return self:step()
    end


    local card = self._actionCard

    -- log
    local cardStatus = {"L", "P", "H", "B", "G", "R", "", "", "C", "S", "F"}
    self:battleLog("[BATTLE] %s\t%s->%s", self:cardName(card), cardStatus[card._sourceStatus], cardStatus[card._destStatus])
    
    -- score
    if card._sourceStatus == BattleData.CardStatus.board 
        and (card._destStatus == BattleData.CardStatus.grave or card._destStatus == BattleData.CardStatus.leave) 
        and (card._statusVal ~= BattleData.CardStatusVal.b2g_sacrifice) then
        card:getOriginOwner()._opponent:addDamageScore(card._hp)
        card:getOriginOwner()._opponent:addDestroyCardScore(card)
    end

    -- remove card
    if card._sourceStatus == BattleData.CardStatus.pile then
        card._owner:removeCardFromPile(card)
    elseif card._sourceStatus == BattleData.CardStatus.hand then
        card._owner:removeCardFromHand(card) 
    elseif card._sourceStatus == BattleData.CardStatus.board then
        card._owner:removeCardFromBoard(card)
    elseif card._sourceStatus == BattleData.CardStatus.grave then
        card._owner:removeCardFromGrave(card)
    elseif card._sourceStatus == BattleData.CardStatus.leave then
        card._owner:removeCardFromLeave(card)
    end
    
    -- add card
    if card._destStatus == BattleData.CardStatus.pile then
        card._owner:addCardToPile(card)
    elseif card._destStatus == BattleData.CardStatus.hand then
        card._owner:addCardToHand(card) 
    elseif card._destStatus == BattleData.CardStatus.board then
        card._owner:addCardToBoard(card)
    elseif card._destStatus == BattleData.CardStatus.grave then
        card._owner:addCardToGrave(card)
    elseif card._destStatus == BattleData.CardStatus.leave then
        card._owner:addCardToLeave(card)
    end

    -- step
    self._stepStatus = BattleData.Status.after_account_status
    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.account_status)
    else
        return self:step()
    end
end

function _M:accountReorder()
    self:battleLog("")
    self:battleLog("[BATTLE] <REORDER>")

    self._normalStatus = BattleData.Status.account_reorder

    self:doReorderBoard()
    self._opponent:doReorderBoard()
    
    self._stepStatus = BattleData.Status.after_account_reorder
    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.account_reorder) 
    else
        return self:step()
    end
end

function _M:doReorderBoard()
    local aliveCards = self:getBattleCards('B')
    self._boardCards = {}
    for i = 1, #aliveCards do
        local boardCard = aliveCards[i]
        boardCard._pos = i
        self._boardCards[i] = boardCard
    end
end

function _M:accountPosChange()
    self:battleLog("")
    self:battleLog("[BATTLE] <ACCOUNT POS CHANGE>")
    
    self._normalStatus = BattleData.Status.account_pos_change
    
    local player = self._cardPosToChange[1]._card._owner
    local type = self._cardPosToChange[1]._type
    local cards = {}
    for i = 1, #self._cardPosToChange do
        local boardCard = self._cardPosToChange[i]._card
        if B.isAlive(boardCard) then
            table.insert(cards, boardCard)
        end
    end
    
    if type == BattleData.CardPosChange.random then
        for i = 1, (#cards - 1) do
            local index = math.floor(self:getRandom() * (#cards - i)) + (i + 1)
            local preCard = cards[i]
            local curCard = cards[index]
            if curCard ~= nil then
                local prePos, curPos = preCard._pos, curCard._pos
                preCard._pos = curPos
                curCard._pos = prePos
                player._boardCards[prePos] = curCard
                player._boardCards[curPos] = preCard
                cards[i] = curCard
                cards[index] = preCard 

                self:battleLog("[BATTLE] %s\t%d->%d", self:cardName(curCard), curPos, prePos)
                self:battleLog("[BATTLE] %s\t%d->%d", self:cardName(preCard), prePos, curPos)
            end
        end
        
    elseif type == BattleData.CardPosChange.swap then
        local card1, card2 = cards[1], cards[2]
        local pos1, pos2 = card1._pos, card2 and card2._pos or 1
        local player1, player2 = card1._owner, card2 and card2._owner or card1._owner
        
        if player1 ~= player2 then
            player1:removeCardToOppo(card1)
            player2:removeCardToOppo(card2)
        end
        
        if card2 ~= nil then
            player1._boardCards[pos1] = card2
            player2._boardCards[pos2] = card1
            card1._pos = pos2
            card2._pos = pos1

            self:battleLog("[BATTLE] %s\t%d->%d", self:cardName(card1), pos1, pos2)
            self:battleLog("[BATTLE] %s\t%d->%d", self:cardName(card2), pos2, pos1)
        else
            player2._boardCards[pos2] = card1
            player1._boardCards[pos1] = nil
            card1._pos = pos2

            self:battleLog("[BATTLE] %s\t%d->%d", self:cardName(card1), pos1, pos2)
        end

        
    elseif type == BattleData.CardPosChange.loop then
        local poses = {}
        for i = 1, #cards do
            local card = cards[i]
            poses[card._pos] = true
            player._boardCards[card._pos] = nil
        end
        
        for i = 1, #cards do
            local card = cards[i]
            local index = card._pos + 1
            while true do
                if index > Data.MAX_CARD_COUNT_ON_BOARD then 
                    index = 1
                elseif not poses[index] then 
                    index = index + 1
                else
                    break
                end
            end

            self:battleLog("[BATTLE] %s\t%d->%d", self:cardName(card), card._pos, index)
            
            card._pos = index
            player._boardCards[index] = card
        end
    elseif type == BattleData.CardPosChange.shiftleft then
        for i = 1, #cards do
            local card = cards[i]
            player._boardCards[card._pos] = nil
            card._pos = card._pos - 1
            player._boardCards[card._pos] = card

            self:battleLog("[BATTLE] %s\t%d->%d", self:cardName(card), card._pos + 1, card._pos)
        end
    elseif type == BattleData.CardPosChange.shiftright then
        for i = 1, #cards do
            local card = cards[i]
            player._boardCards[card._pos] = nil
            card._pos = card._pos + 1
            player._boardCards[card._pos] = card

            self:battleLog("[BATTLE] %s\t%d->%d", self:cardName(card), card._pos - 1, card._pos)
        end
    end
    
    self._stepStatus = BattleData.Status.after_account_pos_change
    if not self._isReviewing then
        return self:sendEvent(BattleData.Status.account_pos_change) 
    else
        return self:step()
    end
end

function _M:accountHalo()
    local actionCard = self._actionCard

    local cards = B.mergeTable({self:getBattleCards('B'), self._opponent:getBattleCards('B'), self:getBattleCards('S'), self._opponent:getBattleCards('S')})

    -- remove all halo skills, positiveSkills/negativeSkills triggered by halo
    for i = 1, #cards do
        local card = cards[i]
        local index = 1
        while card._underSkills[index] ~= nil do
            if card._underSkills[index]._mode == Data.SkillMode.halo then
                table.remove(card._underSkills, index)
                actionCard._needAccount = true
            else
                index = index + 1
            end
        end

        if card._positiveSkills ~= nil then
            for j = 1, BattleData.PositiveType.count do
                local index = 1
                while card._positiveSkills[j][index] ~= nil do
                    if card._positiveSkills[j][index]._mode == Data.SkillMode.halo then
                        table.remove(card._positiveSkills[j], index)
                        actionCard._needAccount = true
                    else
                        index = index + 1
                    end
                end
            end
        end

        if card._negativeSkills ~= nil then
            for j = 1, BattleData.NegativeType.count do
                local index = 1
                while card._negativeSkills[j][index] ~= nil do
                    if card._negativeSkills[j][index]._mode == Data.SkillMode.halo then
                        table.remove(card._negativeSkills[j], index)
                        actionCard._needAccount = true
                    else
                        index = index + 1
                    end
                end
            end
        end
    end

    -- recast jingtian & tihu
    for i = 1, #cards do
        local card = cards[i]
        for j = 1, 0xFF do
            local skill = card:getSkillByMode(Data.SkillMode.halo, j)
            if skill == nil then break end
            local stepRound = skill._stepRound or 0
            local startRound = skill._startRound or 0
            local round = math.max(card._owner._round, card._owner._opponent._round)
            if B.skillHasMode(skill, Data.SkillMode.halo) and ((round >= startRound and ((round - startRound) % (stepRound + 1)) == 0)) then
                if skill._priority == 0 then
                    card._owner:castSkill(card, skill, Data.SkillMode.halo)
                    actionCard._needAccount = true
                end
            end
        end
    end

    -- account jintian & tihu
    for i = 1, #cards do
        local card = cards[i]
        card:updateSkillLevel() 
    end

    -- recast all halo skills
    local priority, minPriority = 1, 0xFF
    while true do
        for i = 1, #cards do
            local card = cards[i]
            for j = 1, 0xFF do
                local skill = card:getSkillByMode(Data.SkillMode.halo, j)
                if skill == nil then break end
                local stepRound = skill._stepRound or 0
                local startRound = skill._startRound or 0
                if B.skillHasMode(skill, Data.SkillMode.halo) and ((card._owner._round >= startRound and ((card._owner._round - startRound) % (stepRound + 1)) == 0)) then
                    if skill._priority == priority then
                        card._owner:castSkill(card, skill, Data.SkillMode.halo)
                    else
                        if skill._priority > priority and skill._priority < minPriority then
                            minPriority = skill._priority
                        end
                    end
                end
            end
        end
        if minPriority == 0xFF then break end
        priority = minPriority
        minPriority = 0xFF
    end

    -- account
    if actionCard._needAccount then
        self:account()
    end

    -- step
    self._stepStatus = BattleData.Status.after_account_halo
    if actionCard._needAccount and not self._isReviewing then
        return self:sendEvent(BattleData.Status.account_halo)
    else
        return self:step()
    end
end

function _M:spelling()
    local actionCard = self._actionCard
    self:resetActionCard()
    self:resetAccount()
    
    self._spellCountIndex = self._spellCountIndex + 1
    -- self._spellIndex = 0: for halo mode skills
    local skill = actionCard:getSkillByMode(self._spellType, self._spellIndex)
    if skill == nil or self._spellCountIndex >= skill._count then
        self._spellIndex = self._spellIndex + 1
        self._spellCountIndex = 0
        skill = actionCard:getSkillByMode(self._spellType, self._spellIndex)
    end

    -- check can cast
    local canCast = true
    if skill == nil then canCast = false end 

    if canCast and actionCard:isMonster() then
        if (self._spellType == Data.SkillMode.bcs2gl or self._spellType == Data.SkillMode.bcs2_) then
            --if (#actionCard._owner._opponent:getBattleCardsByBuff('B', true, BattleData.PositiveType.disableDyingSkill) > 0) then canCast = false end
            local info = Data._skillInfo[6064]
            if actionCard._triggerCard ~= nil and (actionCard._triggerCard:hasSkills(info._refSkills) or (actionCard._triggerCard:hasSkills({6064}) and actionCard._info._nature == info._refCards[1])) then canCast = false end
        end


        if self._spellType ~= Data.SkillMode.bcs2gl 
            and self._spellType ~= Data.SkillMode.bcs2_
            and self._spellType ~= Data.SkillMode.sacrifice
            and self._spellType ~= Data.SkillMode.round_begin and self._spellType ~= Data.SkillMode.oppo_round_begin
            and self._spellType ~= Data.SkillMode.round_end and self._spellType ~= Data.SkillMode.oppo_round_end
            and self._spellType ~= Data.SkillMode.after_attack 
            and self._spellType ~= Data.SkillMode.h2g_by_self and self._spellType ~= Data.SkillMode.h2g_by_oppo 
            and self._spellType ~= Data.SkillMode.p2g_by_self and self._spellType ~= Data.SkillMode.p2g_by_oppo 
            and (not B.isAlive(actionCard)) then 
            canCast = false 
        end
    end
    
    if not canCast then
        self._stepStatus = BattleData.Status.after_account_spell
        return self:step()
    end

    actionCard._owner:castSkill(actionCard, skill, self._spellType)
    
    if not actionCard._needAccount then
        self._stepStatus = BattleData.Status.end_spell
        return self:step()
    else
        actionCard._spellingSkill = skill
        self._stepStatus = (Data._skillInfo[skill._id]._isIgnoreDefend == 1) and BattleData.Status.account_spell or BattleData.Status.under_spell
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.spelling)
        else
            return self:step()
        end
    end
end

function _M:underSpell()
    local actionCard = self._actionCard
    self:resetAccount()
    
    local underSkillCards = self:getUnderSkillCards(actionCard._id, actionCard._spellingSkill._id)
    for i = 1, #underSkillCards do
        local targetCard = underSkillCards[i]
        if B.isAlive(targetCard) and
            targetCard:isMonster() then
            --if targetCard._owner ~= actionCard._owner then
            if true then
                -- [@ SKILL FROM @] cast under_spell skill from targetCard  
                local skillIndex = 1
                while true do
                    local skill = targetCard:getSkillByMode(Data.SkillMode.under_spell, skillIndex)
                    if skill == nil then break end
                    targetCard._owner:castSkill(targetCard, skill, Data.SkillMode.under_spell)
                    skillIndex = skillIndex + 1
                end
            end
        end
    end

    local skillType = math.floor(actionCard._spellingSkill._id / Data.INFO_ID_GROUP_SIZE)
    local underSkillTypeCards, underCastedModes = self:getHasUnderTypeCastedModeCards(skillType, actionCard._spellingSkill)
    for i = 1, #underSkillTypeCards do
        local targetCard = underSkillTypeCards[i]
        if (targetCard:isMonster() and targetCard._status == BattleData.CardStatus.board and B.isAlive(targetCard)) then
            --if targetCard._owner ~= actionCard._owner then
            if true then
                -- [@ SKILL FROM @] cast under_xxx_casted from targetCard  
                local skillIndex = 1
                while true do
                    local skill, skillMode = nil, nil
                    for j = 1, #underCastedModes do
                        skillMode = underCastedModes[j]
                        skill = targetCard:getSkillByMode(skillMode, skillIndex)
                        if skill ~= nil then break end
                    end
                    if skill == nil then break end
                    targetCard._owner:castSkill(targetCard, skill, skillMode)
                    skillIndex = skillIndex + 1
                end

                skillIndex = 1
                while true do
                    local skill = targetCard:getSkillByMode(Data.SkillMode.under_spell, skillIndex)
                    if skill == nil then break end
                    targetCard._owner:castSkill(targetCard, skill, Data.SkillMode.under_spell)
                    skillIndex = skillIndex + 1
                end
            end
        end
    end
    
    if not actionCard._needAccount then
        self._stepStatus = BattleData.Status.under_spell_damage
        return self:step()
    else
        self._stepStatus = BattleData.Status.under_defend_spell
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.under_spell)
        else
            return self:step()
        end
    end
end

function _M:underDefendSpell()
    local actionCard = self._actionCard
    self:resetAccount()
    
    local skillIndex = 1
    while true do
        local skill = actionCard:getSkillByMode(Data.SkillMode.under_defend_spell, skillIndex)
        if skill == nil then break end
        actionCard._owner:castSkill(actionCard, skill, Data.SkillMode.under_defend_spell)
        skillIndex = skillIndex + 1
    end
    
    self._stepStatus = BattleData.Status.under_spell_damage
    if actionCard._needAccount and (not self._isReviewing) then
        return self:sendEvent(BattleData.Status.under_defend_spell)
    else
        return self:step()
    end
end

function _M:underSpellDamage()
    local actionCard = self._actionCard
    self:resetAccount()
    
    local underSkillCards = self:getUnderSkillCards(actionCard._id, actionCard._spellingSkill._id)
    for i = 1, #underSkillCards do
        local targetCard = underSkillCards[i]
        if B.isAlive(targetCard) and targetCard:isMonster() then
            --if targetCard._owner ~= actionCard._owner then
            if true then
                -- [@ SKILL FROM @] cast under_spell_damage skill from targetCard  
                local skillIndex = 1
                while true do
                    local skill = targetCard:getSkillByMode(Data.SkillMode.under_spell_damage, skillIndex)
                    if skill == nil then break end
                    targetCard._owner:castSkill(targetCard, skill, Data.SkillMode.under_spell_damage)
                    skillIndex = skillIndex + 1
                end
            end
        end
    end
    
    if not actionCard._needAccount then
        self._stepStatus = BattleData.Status.account_spell
        return self:step()
    else
        self._stepStatus = BattleData.Status.under_counter_spell
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.under_spell_damage)
        else
            return self:step()
        end
    end
end

function _M:underCounterSpell()
    local actionCard = self._actionCard
    self:resetAccount()
    
    local skillIndex = 1
    while true do
        local skill = actionCard:getSkillByMode(Data.SkillMode.under_counter_spell, skillIndex)
        if skill == nil then break end
        actionCard._owner:castSkill(actionCard, skill, Data.SkillMode.under_counter_spell)
        skillIndex = skillIndex + 1
    end
    
    self._stepStatus = BattleData.Status.account_spell
    if actionCard._needAccount and (not self._isReviewing) then
        return self:sendEvent(BattleData.Status.under_counter_spell)
    else
        return self:step()
    end
end

function _M:accountSpell()
    if self._normalStatus ~= BattleData.Status.account_spell then
        self._normalStatus = BattleData.Status.account_spell
        self._haloDone = true
        
        self:resetAccount()
        self:account()
        self:removeDeadCards()
        
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.account_spell)
        end
    end
    
    if not self._haloDone then
        self._haloDone = true
        
        self._stepStatus = BattleData.Status.before_account_halo
        return self:step()
    end
    
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
        return self:step()
    end
    
    if next(self._cardPosToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_pos_change
        return self:step()
    end
    
    self._stepStatus = BattleData.Status.after_spell
    self._normalStatus = BattleData.Status.default
    return self:step()
end

function _M:afterSpell()    
    if self._normalStatus ~= BattleData.Status.after_spell then
        self._normalStatus = BattleData.Status.after_spell
        
        self._afterSpellIndex = 0
    end
    
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
        return self:step()
    end
    
    local actionCard = self._actionCard
    self:resetAccount()
    self._afterSpellIndex = self._afterSpellIndex + 1
    local skill = actionCard:getSkillByMode(Data.SkillMode.after_spell, self._afterSpellIndex)
    
    if (not B.isAlive(actionCard)) or skill == nil then
        self._stepStatus = BattleData.Status.end_spell
        self._normalStatus = BattleData.Status.default
        return self:step()
    end
    
    actionCard._owner:castSkill(actionCard, skill, Data.SkillMode.after_spell)
    
    if actionCard._needAccount then
        self:account()
        self:removeDeadCards()
    end
    
    self._stepStatus = BattleData.Status.after_spell
    if actionCard._needAccount and not self._isReviewing then
        return self:sendEvent(BattleData.Status.after_spell)
    else
        return self:step()
    end
end

function _M:endSpell()
    if self._normalStatus ~= BattleData.Status.end_spell then
        self._normalStatus = BattleData.Status.end_spell
        
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.end_spell)
        end
    end
    
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
    else
        self._stepStatus = BattleData.Status.spelling
    end
    return self:step()
end

function _M:accountEvent()
    if self._normalStatus ~= BattleData.Status.account_event then
        self:battleLog("")
        self:battleLog("[BATTLE] <EVENT>\tid = %d", self._actionEvent._info._id)
        
        self._normalStatus = BattleData.Status.account_event
        
        self._eventIndex = 1
        self._effectIndex = 0
        
        if not self._isReviewing then
            return self:sendEvent(BattleData.Status.account_event)
        end
    end
    
    -- account status
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
        return self:step()
    end
    
    local event = self._actionEvent
    local effect, effectVals = self:getActionEffect(event, self._eventIndex)
    
    if effect ~= nil then
        -- account story
        if self._effectIndex == 0 then
            self._effectIndex = self._effectIndex + 1
            
            self._stepStatus = BattleData.Status.account_event
            if not self._isReviewing then
                return self:sendEvent(BattleData.Status.account_event)
            else
                return self:step()
            end
            
        -- account effect, may need to account status
        elseif self._effectIndex == 1 then
            self._effectIndex = self._effectIndex + 1

            self:resetAccount()
            
            event._owner._battleEvent:castEffect(effect, effectVals, event)
            
            if self._actionCard._needAccount then
                self:account()
            end
            
            self._stepStatus = BattleData.Status.account_event
            if not self._isReviewing then
                return self:sendEvent(BattleData.Status.account_event)
            else
                return self:step()
            end
        
        -- account next effect
        elseif self._effectIndex == 2 then
            self._effectIndex = 0
            self._eventIndex = self._eventIndex + 1
            
            self._stepStatus = BattleData.Status.account_event
            return self:step()
            
        end
    end
    
    self._stepStatus = BattleData.Status.after_account_event
    return self:step()
end

function _M:accountFinish()
    if self._normalStatus ~= BattleData.Status.account_finish then
        self._normalStatsu = BattleData.Status.account_finish
    
        if self:getIsFortressDied() then
            local type = BattleEvent.EventType.fortress_died
            local events = self:getEvents(type)
            for i = 1, #events do
                local event = events[i]
                self:changeEvent(event, type)
            end
        end
        if self._opponent:getIsFortressDied() then
            local type = BattleEvent.EventType.fortress_died
            local events = self._opponent:getEvents(type)
            for _, event in ipairs(events) do
                self:changeEvent(event, type)
            end
        end
        if self:getIsAllCardsDied() then
            local type = BattleEvent.EventType.all_cards_died
            local events = self:getEvents(type)
            for _, event in ipairs(events) do
                self:changeEvent(event, type)
            end
        end
        if self._opponent:getIsAllCardsDied() then
            local type = BattleEvent.EventType.all_cards_died
            local events = self._opponent:getEvents(type)
            for _, event in ipairs(events) do
                self:changeEvent(event, type)
            end
        end
    end

    -- events
    if next(self._eventToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_event
        return self:step()
    end
    
    self._stepStatus = BattleData.Status.after_account_finish
    return self:step()
end

function _M:accountTrap()
    if self._normalStatus ~= BattleData.Status.account_trap then
        self._normalStatus = BattleData.Status.account_trap
    end

    local trapCards = B.mergeTable({self:getBattleCards('C'), self._opponent:getBattleCards('C')})
    for i = 1, #trapCards do
        local trapCard = trapCards[i]
        if trapCard._owner:canTriggerTrapWhenStatusChange(trapCard, self._actionCard) then
            trapCard._trapTarget = self._actionCard
            self:changeCardStatus(trapCard, trapCard._status, BattleData.CardStatus.show)
            break
        end
    end

    -- acccount status
    if next(self._cardStatusToChange) ~= nil then
        self._stepStatus = BattleData.Status.before_account_status
        return self:step()
    end
    
    self._stepStatus = BattleData.Status.after_account_trap
    return self:step()
end


-----------------------------------
-- step helper functions
-----------------------------------=

function _M:saveStatus()
    self._saved = {_saved = self._saved}
    local saved = self._saved
    
    saved._normalStatus = self._normalStatus
    saved._spellType = self._spellType
    saved._eventType = self._eventType
    saved._cardStatusToChange = self._cardStatusToChange
    saved._eventToChange = self._eventToChange
    saved._reorderDone = self._reorderDone
    saved._eventDone = self._eventDone
    saved._costSpellDone = self._costSpellDone
    saved._spellDone = self._spellDone
    saved._haloDone = self._haloDone
    saved._trapDone = self._trapDone
    
    saved._actionStep = self._actionStep
    saved._spellIndex = self._spellIndex
    saved._spellCountIndex = self._spellCountIndex
    saved._attackIndex = self._attackIndex
    saved._afterSpellIndex = self._afterSpellIndex
    saved._afterAttackIndex = self._afterAttackIndex

    saved._actionStatus = {}
    if self._actionCard ~= nil then
        saved._actionCard = self._actionCard
        saved._actionStatus._needAccount = self._actionCard._needAccount
        saved._actionStatus._spellingSkill = self._actionCard._spellingSkill
    end
    if self._actionEvent ~= nil then
        saved._actionEvent = self._actionEvent
        saved._actionStatus._eventIndex = self._eventIndex
        saved._actionStatus._effectIndex = self._effectIndex
    end

    self._cardStatusToChange = {}
    self._eventToChange = {}
end

function _M:loadStatus()
    assert(self._saved ~= nil and next(self._saved) ~= nil, "ERROR : can not load empty status")
    
    local saved = self._saved 
    self._saved = saved._saved
    
    self._normalStatus = saved._normalStatus
    self._spellType = saved._spellType
    self._eventType = saved._eventType
    self._cardStatusToChange = saved._cardStatusToChange
    self._eventToChange = saved._eventToChange
    self._reorderDone = saved._reorderDone
    self._eventDone = saved._eventDone
    self._costSpellDone = saved._costSpellDone
    self._spellDone = saved._spellDone
    self._haloDone = saved._haloDone
    self._trapDone = saved._trapDone
    
    self._actionStep = saved._actionStep
    self._spellIndex = saved._spellIndex
    self._spellCountIndex = saved._spellCountIndex
    self._attackIndex = saved._attackIndex
    self._afterSpellIndex = saved._afterSpellIndex
    self._afterAttackIndex = saved._afterAttackIndex

    if saved._actionCard ~= nil then
        self._actionCard = saved._actionCard
        self._actionCard._needAccount = saved._actionStatus._needAccount
        self._actionCard._spellingSkill = saved._actionStatus._spellingSkill
    end
    
    if saved._actionEvent ~= nil then
        self._actionEvent = saved._actionEvent
        self._eventIdnex = saved._actionStatus._eventIndex
        self._effectIndex = saved._actionStatus._effectIndex
    end

    -- status step
    if self._normalStatus == BattleData.Status.after_account_status then
        self._stepStatus = BattleData.Status.after_account_status
        return self:step()
    elseif self._normalStatus == BattleData.Status.account_status then
        self._stepStatus = BattleData.Status.account_status
        return self:step()
    elseif self._normalStatus == BattleData.Status.after_account_reorder then
        self._stepStatus = BattleData.Status.after_account_reorder
        return self:step()
    elseif self._normalStatus == BattleData.Status.after_account_pos_change then
        self._stepStatus = BattleData.Status.after_account_pos_change
        return self:step()
    elseif self._normalStatus == BattleData.Status.account_spell then
        self._stepStatus = BattleData.Status.account_spell
        return self:step()
    elseif self._normalStatus == BattleData.Status.after_spell then
        self._stepStatus = BattleData.Status.after_spell
        return self:step()
    elseif self._normalStatus == BattleData.Status.end_spell then
        self._stepStatus = BattleData.Status.end_spell
        return self:step()
    elseif self._normalStatus == BattleData.Status.account_event then
        self._stepStatus = BattleData.Status.account_event
        return self:step()
    elseif self._normalStatus == BattleData.Status.account_finish then
        self._stepStatus = BattleData.Status.account_finish
        return self:step()
    elseif self._normalStatus == BattleData.Status.account_trap then
        self._stepStatus = BattleData.Status.account_trap
        return self:step()
    elseif self._normalStatus == BattleData.Status.try_use_card then
        self._stepStatus = BattleData.Status.try_use_card
        return self:step()
    elseif self._normalStatus == BattleData.Status.do_use_card then
        self._stepStatus = BattleData.Status.do_use_card
        return self:step()
    end
    
    if self._macroStatus == BattleData.Status.battle_start then
        self._stepStatus = BattleData.Status.battle_start
        return self:step()
    elseif self._macroStatus == BattleData.Status.battle_end then
        self._stepStatus = BattleData.Status.battle_end
        return self:step()
    elseif self._macroStatus == BattleData.Status.round_begin then
        self._stepStatus = BattleData.Status.round_begin
        return self:step()
    elseif self._macroStatus == BattleData.Status.deal then
        self._stepStatus = BattleData.Status.deal
        return self:step()
    elseif self._macroStatus == BattleData.Status.use then
        self._stepStatus = BattleData.Status.use
        return self:step()
    elseif self._macroStatus == BattleData.Status.action then
        self._stepStatus = BattleData.Status.action
        return self:step()
    elseif self._macroStatus == BattleData.Status.round_end then
        self._stepStatus = BattleData.Status.round_end
        return self:step()
    elseif self._macroStatus == BattleData.Status.initial_deal then
        self._stepStatus = BattleData.Status.initial_deal
        return self:step()
    elseif self._macroStatus == BattleData.Status.select_main then
        self._stepStatus = BattleData.Status.select_main
        return self:step()
    end
end

function _M:removeDeadCards()
    local preDeadCards = {}
    local saved = self._saved
    while saved ~= nil and next(saved) ~= nil do
        for i = 1, #saved._cardStatusToChange do
            local statusChangeNode = saved._cardStatusToChange[i] 
            local card = statusChangeNode._card
            if statusChangeNode._sourceStatus == BattleData.CardStatus.board and statusChangeNode._destStatus == BattleData.CardStatus.grave then
                table.insert(preDeadCards, card)
            end
        end
        saved = saved._saved
    end
    
    local curDeadCards = {}
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD * 2 do
        local card = nil
        if i <= Data.MAX_CARD_COUNT_ON_BOARD then card = self._opponent._boardCards[i]
        elseif i <= Data.MAX_CARD_COUNT_ON_BOARD * 2 then card = self._boardCards[i - Data.MAX_CARD_COUNT_ON_BOARD]
        end
        
        if (card ~= nil and not B.isAlive(card)) then
            table.insert(curDeadCards, card)
        end
    end

    -- account
    for i = 1, #curDeadCards do
        local deadCard = curDeadCards[i]
        local isInList = false
        for j = 1, #preDeadCards do
            if preDeadCards[j]._id == deadCard._id then isInList = true break end
        end
        if not isInList then
            self:changeCardStatus(deadCard, BattleData.CardStatus.board, BattleData.CardStatus.grave)
        end
    end
end


