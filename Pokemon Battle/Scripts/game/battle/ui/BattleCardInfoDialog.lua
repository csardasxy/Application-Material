local _M = class("BattleCardInfoDialog", lc.ExtendUIWidget)
BattleCardInfoDialog = _M

function _M.create(battleUi, card)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(battleUi, card)
    return panel
end

-------------------------------------------------------
-- init
-------------------------------------------------------

function _M:init(battleUi, card)
    self._battleUi = battleUi

    local pos = cc.p(V.SCR_CW, V.SCR_CH + 20)
    
    local pCard = CardSprite.create(card, self._battleUi._playerUi)
    pCard:setPosition(pos.x - 310, pos.y + 120)
    self:addChild(pCard)
    pCard:showCardInfo(false)

    if card:isMonster() then
        pCard._pAtkSpr:setString(ClientData.formatNum(card._maxAtk, 99999))
        pCard._pHpSpr:setString(ClientData.formatNum(card._maxHp, 99999))
    end

    -- All elements should be seen by 2D camera
    pCard:setCameraMask(ClientData.CAMERA_2D_FLAG)
end    

function _M:hide()
    self:removeFromParent()
end

return _M
