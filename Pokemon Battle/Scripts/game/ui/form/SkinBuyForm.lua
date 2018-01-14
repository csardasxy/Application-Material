local _M = class("SkinBuyForm", BaseForm)

local FORM_SIZE = cc.size(820, 400)

function _M.create(skinId)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(skinId)
    
    return panel
end

function _M:init(skinId)
    _M.super.init(self, FORM_SIZE, nil, 0)

    self._isShowResourceUI = true
    self._skinId = skinId
    self._skinInfo = Data._skinInfo[skinId]
    self._monsterInfo = Data.getInfo(self._skinInfo._infoId)
    self._prices = {self._skinInfo._price3D, self._skinInfo._price7D, self._skinInfo._price}

    self:initSkinArea()
    self:initBuyArea()
   
    self:updateBuyArea()
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.prop_dirty, function() self:updateBuyArea() end))
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)
end

function _M:initSkinArea()
    local frame = V.createSkinFrame(self._skinId)
    lc.addChildToPos(self._frame, frame, cc.p(50 + lc.cw(frame), lc.ch(self._frame) - 10))
    self._skinFrame = frame
end

function _M:initBuyArea()
    self._priceLabels = {}
    self._btns = {}
    local y = lc.top(self._skinFrame)
    local offset = math.floor((lc.h(self._skinFrame) - 50) / 2)
    local strs = {string.format(Str(STR.SKIN_DAY), 3), string.format(Str(STR.SKIN_DAY), 7), Str(STR.SKIN_FOREVER)}
    for i = 1, 3 do
        local labelBg = lc.createSprite({_name = "img_com_bg_26", _crect = V.CRECT_COM_BG26, _size = cc.size(280, 50)})
        lc.addChildToPos(self._frame, labelBg, cc.p(lc.right(self._skinFrame) + 20 + lc.cw(labelBg), y - lc.ch(labelBg)))

        local label = V.createTTF(strs[i], V.FontSize.S1)
        lc.addChildToPos(labelBg, label, cc.p(20 + lc.cw(label), lc.ch(labelBg)))
        label:setColor(i == 3 and V.COLOR_LABEL_LIGHT or V.COLOR_TEXT_WHITE)

        local priceLabel = V.createResIconLabel(120, ClientData.getPropIconName(Data.PropsId.skin_crystal))
        priceLabel._label:setString(self._prices[i])
        lc.addChildToPos(labelBg, priceLabel, cc.p(lc.x(label) + 100 + lc.cw(priceLabel), lc.y(label)))
        self._priceLabels[i] = priceLabel._label
        
        local btn = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onBtn(sender) end, V.CRECT_BUTTON_S, 140)
        btn._index = i
        btn:addLabel(Str(STR.BUY))
        btn:setDisabledShader(V.SHADER_DISABLE)
        lc.addChildToPos(self._frame, btn, cc.p(lc.right(labelBg) + 20 + lc.cw(btn), lc.y(labelBg)))
        self._btns[i] = btn

        y = y - offset
    end  
end

function _M:updateBuyArea()
    local isBought = P._playerCard:hasSkin(self._skinId, true)
    local canUse = P._playerCard:hasSkin(self._skinId, false)

    for i = 1, 3 do
        self._btns[i]._label:setString(isBought and Str(STR.PURCHASED) or ((not canUse or i == 3) and Str(STR.BUY) or Str(STR.SKIN_IN_TRIAL)))
        self._btns[i]:setEnabled(not isBought and (not canUse or i == 3))
        self._priceLabels[i]:setColor(P._propBag:hasProps(Data.PropsId.skin_crystal, self._prices[i]) and lc.Color3B.white or lc.Color3B.red)
    end
end

function _M:onBtn(btn)
    local index = btn._index
    local days = {3, 7, 0}
    
    local propId = Data.PropsId.skin_crystal
    if not P._propBag:hasProps(propId, self._prices[index]) then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._propsInfo[propId]._nameSid)))
        require("ExchangeResForm").create(propId):show()
        return
    end

    if P._playerCard:buySkinId(self._skinId, days[index]) then
        P._propBag:changeProps(Data.PropsId.skin_crystal, -self._prices[index])
        ClientData.sendBuySkin(self._skinId, days[index])
        self:updateBuyArea()

        require("Dialog").showDialog(Str(STR.BUY_SKIN_SUCCEED), function()
            if P._playerCard:setSkinId(self._skinInfo._infoId, self._skinId) then
                ClientData.sendSetSkin(self._skinInfo._infoId, self._skinId)
                ToastManager.push(Str(STR.SET_SKIN_SUCCEED))
            else
                ToastManager.push(Str(STR.SET_SKIN_FAILED))
            end   
        end)
    else
        ToastManager.push(Str(STR.BUY_SKIN_FAILED))
    end
end

return _M