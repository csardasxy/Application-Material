local _M = class("CardPackagePanel", require("BasePanel"))

local CardThumbnail = require("CardThumbnail")

_M.PACKAGE_CARD_COUNT = 5

_M.Mode = {
    open_one = 1,
    show_all = 2,
}

function _M.create(...)
    local form = _M.new(lc.EXTEND_LAYOUT_MASK) 
    form:init(...)

    return form   
end

function _M:init(mode, newCards, recruitInfo, recruitInfoOnce, packageIndex)
    _M.super.init(self, true)

    self._mode = mode
    self._newCards = newCards
    self._recruitInfo = recruitInfo
    self._recruitInfoOnce = recruitInfoOnce
    self._packageIndex = packageIndex or 1

    self._cardScale = 0.36

    -- ui
    self:addTouchEventListener(function(sender, type)
        if type == ccui.TouchEventType.ended then
            if self._isShowTotalList then
                -- do nothing
            elseif not self._isEndShowPackage then
                self:endPackageShow()
            elseif not self._isOpened then
                self:openPackage()

                -- Close the guide if exists
                GuideManager.closeNpcTipLayer()
                GuideManager.finishStepLater(1.5)
            end
        end
    end)
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end))

    if self._mode == _M.Mode.open_one then
        self:start()
    else
        self:showTotalCards()
    end
end

function _M:onExit()
    _M.super.onExit(self)
    
    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    if self._cardThumbnails then
        for i = 1, #self._cardThumbnails do
            CardThumbnail.releaseToPool(self._cardThumbnails[i]._cardSprite)
        end
    end
end

function _M:start()
    local recruitInfo = self._recruitInfoOnce

    -- craete package
    local layout = V.createCardPackage(recruitInfo)
    lc.addChildToPos(self, layout, cc.p(V.SCR_CW, -lc.ch(layout)), 10)
    self._package = layout
    
    -- count
    if #self._newCards > _M.PACKAGE_CARD_COUNT then
        local str = string.format("%d/%d", self._packageIndex, math.floor(#self._newCards / _M.PACKAGE_CARD_COUNT))
        local label = V.createTTF(str, V.FontSize.S1)
        lc.addChildToPos(self, label, cc.p(lc.cw(label) + 20, lc.ch(label) + 10))

        -- fast open
        local label = V.createTTF(Str(STR.RECRUIT_FAST_OPEN), V.FontSize.S1, V.COLOR_TEXT_GREEN)
        local widget = V.createShaderButton(nil, function(sender) 
            require("Dialog").showDialog(Str(STR.RECRUIT_FAST_OPEN_TIP), function ()
                _M.create(_M.Mode.show_all, self._newCards, self._recruitInfo, self._recruitInfoOnce, self._packageIndex + 1):show()
                self:removeFromParent()
            end)
        end)
        widget:setContentSize(cc.size(lc.w(label) + 16, lc.h(label) + 16))
        widget:setAnchorPoint(cc.p(0.5, 0.5))
        lc.addChildToCenter(widget, label)
        lc.addChildToPos(self, widget, cc.p(V.SCR_W - lc.cw(label) - 20, lc.ch(label) + 20))
    end

    -- start
    layout:runAction(lc.sequence( 
        lc.moveBy(1.0, cc.p(0, V.SCR_CH + lc.ch(layout))),
        function () self:endPackageShow() end
        ))

    self._isEndShowPackage = false
    self._isOpened = false
    self._isEndShowCards = false
    self._isAllCardsOpend = false
end

function _M:endPackageShow()
    self._isEndShowPackage = true

    local layout = self._package

    layout:stopAllActions()
    layout:setPosition(cc.p(V.SCR_CW, V.SCR_CH))

    layout:runAction(lc.rep(lc.sequence(
        lc.moveBy(0.8, cc.p(0, -20)),
        lc.moveBy(0.8, cc.p(0, 20))
    )))
end

function _M:openPackage()
    self._isOpened = true
    
    self._package:stopAllActions()

    lc.Audio.playAudio(AUDIO.E_TAVERN_OPEN_PACKAGE)

    self:runAction(lc.sequence(
        0, 
        function()
            local par = Particle.create("par_chouka02")
            lc.addChildToCenter(self, par, 20)
        end,
        function ()
            local par = Particle.create("par_chouka04")
            lc.addChildToCenter(self, par, 20)
        end,
        0.1, 
        function()
            local par = Particle.create("par_chouka05")
            lc.addChildToCenter(self, par, 20)

            self:showCards()
        end
    ))
end

--[[
    self:runAction(lc.sequence(
        0, function ()
            local par = Particle.create("par_chouka01")
            lc.addChildToPos(self, par, cc.p(V.SCR_CW, V.SCR_CH + 260), 20)
        end,
        0.15, function () 
            local par = Particle.create("par_chouka02")
            lc.addChildToCenter(self, par, 20)
        end,
        0.65, function ()
            local par = Particle.create("par_chouka04")
            lc.addChildToCenter(self, par, 20)

            local par = Particle.create("par_chouka05")
            lc.addChildToCenter(self, par, 20)
        end, 
        0.15, function ()
            local par = Particle.create("par_chouka03")
            lc.addChildToCenter(self, par)

            self:showCards()
        end
    ))
]]

function _M:showCards()
    self._isEndShowCards = false

    self._package:removeFromParent()
    self._package = nil

    local scale = self._cardScale

    local startIndex = (self._packageIndex - 1) * _M.PACKAGE_CARD_COUNT + 1
    local endIndex = math.min(#self._newCards, self._packageIndex * _M.PACKAGE_CARD_COUNT)

    local cards = {}
    for i = startIndex, endIndex do
        table.insert(cards, self._newCards[i])
    end
    local leftPos, rightPos = cc.p(V.SCR_CW - 340, V.SCR_CH + 200), cc.p(V.SCR_CW + 340, V.SCR_CH + 200)
    self._cardThumbnails = {}
    for i = 1, #cards do
        local card = cards[i]
        local pos, rot
        if i <= 3 then
            pos = cc.p(V.SCR_CW + 660 * (i - 2) * scale, V.SCR_CH + (600 - math.abs(i - 2) * 40) * scale)
            rot = (i - 2) * 3
        else
            pos = cc.p(V.SCR_CW + 350 * (i - 4.5) * 2 * scale, V.SCR_CH - 100)
            rot = (i - 4.5) * 4
        end
        local delay = i * 0.18
        local layout = ccui.Layout:create()
        lc.addChildToCenter(self, layout, 6)
        self._cardThumbnails[i] = layout
        self._cardThumbnails[i]._pos = pos
        self._cardThumbnails[i]._rot = rot
        layout._card = card

        local cardBack = lc.createSprite(V.getCardBackName())
        --cardBack:setScale(self._cardScale)
        layout:setContentSize(cardBack:getContentSize())
        layout:setAnchorPoint(cc.p(0.5, 0.5))
        lc.addChildToCenter(layout, cardBack)
        layout._cardBack = cardBack

        local item = CardThumbnail.createFromPool(card._infoId, 1.0)
        item._thumbnail:updateFlag()
        lc.addChildToCenter(layout, item)
        item:setVisible(false)
        layout._cardSprite = item

        local effectNode = cc.Node:create()
        lc.addChildToCenter(layout, effectNode)
        layout._effectNode = effectNode
        
        -- action
        layout:setScale(scale)
        layout:runAction(lc.sequence(
            function()
                local par1 = Particle.create("par_kbtw")
                lc.addChildToCenter(layout, par1, -1)
                layout._par1 = par1
                --par1:setPositionType(cc.POSITION_TYPE_GROUPED)
            end,
            lc.scaleTo(0.1, scale * 2),
            0.2,
            lc.scaleTo(0.25, scale * 1.4),
            --lc.scaleTo(0.2, scale * 1.8),
            --0.1,
            lc.spawn(
                lc.sequence(
                    lc.spawn(
                        cc.BezierBy:create(0.32, {cc.p(75,  150), cc.p(200, 150), cc.p(200, -50)}),
                        lc.rotateTo(0.32, 10, -30, 25),
                        lc.scaleTo(0.32, scale * 1.6)
                    ),
                    lc.spawn(
                        cc.BezierBy:create(0.55, {cc.p(-150,  - 450), cc.p(leftPos.x - 200 - lc.x(layout) - 300, leftPos.y - 100 - lc.y(layout) - 250), cc.p(leftPos.x - 200 - lc.x(layout), leftPos.y - 100 - lc.y(layout))}),
                        lc.rotateTo(0.55, -14, 0, 0),
                        lc.scaleTo(0.55, scale)
                    )
                )
                
            ),
            function()
                for j = 1, i do
                    layout:runAction(
                        lc.sequence(
                            0.32 * (j - 1),
                            lc.spawn(lc.moveTo(0.32, self._cardThumbnails[j]._pos), lc.rotateTo(0.3, self._cardThumbnails[j]._rot))
                        )
                    )
                end
            end,
            --lc.spawn( lc.moveTo(delay, pos), lc.rotateTo(delay, rot)),
            0.32 * i,
            function()
                local info = Data.getInfo(layout._card._infoId)
                if info._quality ~= Data.CardQuality.R and 
                   info._quality ~= Data.CardQuality.RR and 
                   info._quality ~= Data.CardQuality.SR and 
                   info._quality ~= Data.CardQuality.UR and 
                   info._quality ~= Data.CardQuality.HR then

                    self:openCard(layout)
                else
                    local par = Particle.create("par_urxz")
                    lc.addChildToCenter(layout, par, -1)
                    par:setPositionType(cc.POSITION_TYPE_GROUPED) 
                end
            end,
            function () self:endShowCards() end
            ))
    end
end

function _M:endShowCards()
    self._isEndShowCards = true

    local scale = self._cardScale
    local timeScales = {0.8, 1.2, 1.0, 0.9, 1.1}

    for i = 1, #self._cardThumbnails do
        local layout = self._cardThumbnails[i]
        local timeScale = timeScales[i] 
        local info = Data.getInfo(layout._card._infoId)
        --[[
        layout:runAction(lc.sequence(
            lc.scaleTo(0.8 * timeScale , scale),
            lc.scaleTo(0.9 * timeScale, scale * 0.95),
            function () 
                layout:runAction(lc.rep(lc.sequence(
                    lc.scaleTo(0.8 , scale),
                    lc.scaleTo(0.9, scale * 0.96)
                )))
            end
        ))
        ]]
        layout:setTouchEnabled(true)
        layout:setTouchSwallow(true)
        layout:addTouchEventListener(function(sender, evt)
            if evt == ccui.TouchEventType.ended then
                if not sender._isOpened then
                    return self:openCard(layout)
                else
                    for i = 1,  #lc._runningScene._scene:getChildren() do
                        local child = lc._runningScene._scene:getChildren()[i]
                        if child._panelName == "CardInfoPanel" then return end
                    end

                    return require("CardInfoPanel").create(sender._card._infoId):show()


                end
            end
        end) 
        
    end
end

function _M:openCard(layout)
    layout._isOpened = true
    local scale = self._cardScale
    lc.Audio.playAudio(AUDIO.E_TAVERN_FLIP)

    -- next step
    local isAllOpened = true
    for i = 1, #self._cardThumbnails do
        if not self._cardThumbnails[i]._isOpened then
            isAllOpened = false
            break
        end
    end

    if isAllOpened then
        self:showButtons()
    end

    -- fan zhuan
    layout._cardBack:runAction(lc.sequence(
        lc.spawn(lc.rotateTo(0.2, 0, -90, 0), lc.moveBy(0.2, 0, 210)),
        lc.hide()
    ))

    layout._cardSprite:setRotation3D({x = 0, y = 90, z = 0})
    layout._cardSprite:runAction(lc.sequence(
        0.2, lc.show(),
        lc.spawn(lc.rotateTo(0.2, 0, 0, 0), lc.moveBy(0.2, 0, -30))
    ))

    layout._effectNode:runAction(lc.rotateTo(0.3, 0, -180, 0))

    local waitTime = 0.8
    local x, y = lc.x(layout), lc.y(layout)
    local showPos = cc.p(V.SCR_CW, V.SCR_CH + 80)

    layout._effectNode:runAction(lc.sequence(function ()
        local info = Data.getInfo(layout._card._infoId)
        if info._quality == Data.CardQuality.RR then
            local par = Particle.create("par_rr")
            lc.addChildToCenter(layout._effectNode, par)
            par:setPositionType(cc.POSITION_TYPE_GROUPED) 
            layout:setLocalZOrder(9)
            layout:runAction(
                lc.sequence(
                    lc.spawn(
                        lc.moveTo(0.15, showPos),
                        lc.scaleTo(0.15, 2.1 * scale)
                    ),
                    waitTime,
                    lc.spawn(
                        lc.moveTo(0.15, cc.p(x, y)),
                        lc.scaleTo(0.15, scale)
                    )
                )
            ) 

        elseif info._quality == Data.CardQuality.R then
            local par = Particle.create("par_r")
            lc.addChildToCenter(layout._effectNode, par, 10)
            par:setPositionType(cc.POSITION_TYPE_GROUPED) 
            layout:setLocalZOrder(9)
            layout:runAction(
                lc.sequence(
                    lc.spawn(
                        lc.moveTo(0.15, showPos),
                        lc.scaleTo(0.15, 2.1 * scale)
                    ),
                    waitTime,
                    lc.spawn(
                        lc.moveTo(0.15, cc.p(x, y)),
                        lc.scaleTo(0.15, scale)
                    )
                )
            ) 

        elseif info._quality == Data.CardQuality.SR then

            local par = Particle.create("par_sr02")
            lc.addChildToCenter(layout._effectNode, par)
            par:setPositionType(cc.POSITION_TYPE_GROUPED) 

            local par = Particle.create("par_rr")
            lc.addChildToCenter(layout._effectNode, par)
            par:setPositionType(cc.POSITION_TYPE_GROUPED) 

            local par = Particle.create("par_srxz")
            lc.addChildToCenter(layout, par, -1)
            layout:setLocalZOrder(9)
            layout:runAction(
                lc.sequence(
                    lc.spawn(
                        lc.moveTo(0.15, showPos),
                        lc.scaleTo(0.15, 2.1 * scale)
                    ),
                    waitTime,
                    lc.spawn(
                        lc.moveTo(0.15, cc.p(x, y)),
                        lc.scaleTo(0.15, scale)
                    )
                )
            ) 

        elseif info._quality == Data.CardQuality.HR then
            local par = Particle.create("par_hr01")
            lc.addChildToCenter(layout._effectNode, par)
            par:setPositionType(cc.POSITION_TYPE_GROUPED) 

            local par = Particle.create("par_sr02")
            lc.addChildToCenter(layout._effectNode, par)
            par:setPositionType(cc.POSITION_TYPE_GROUPED) 

            local par = Particle.create("par_srxz")
            lc.addChildToCenter(layout, par, -1)
            layout:setLocalZOrder(9)
            layout:runAction(
                lc.sequence(
                    lc.spawn(
                        lc.moveTo(0.15, showPos),
                        lc.scaleTo(0.15, 2.1 * scale)
                    ),
                    waitTime,
                    lc.spawn(
                        lc.moveTo(0.15, cc.p(x, y)),
                        lc.scaleTo(0.15, scale)
                    )
                )
            ) 

        elseif info._quality == Data.CardQuality.UR then
            local par = Particle.create("par_ur01")
            lc.addChildToCenter(layout._effectNode, par)
            par:setPositionType(cc.POSITION_TYPE_GROUPED) 

            local par = Particle.create("par_ur02")
            lc.addChildToCenter(layout._effectNode, par)
            par:setPositionType(cc.POSITION_TYPE_GROUPED) 

            local par = Particle.create("par_ur03")
            lc.addChildToCenter(layout._effectNode, par)
            par:setPositionType(cc.POSITION_TYPE_GROUPED) 

            local par = Particle.create("par_urxz")
            lc.addChildToCenter(layout, par, -1)
            layout:setLocalZOrder(9)
            layout:runAction(
                lc.sequence(
                    lc.spawn(
                        lc.moveTo(0.15, showPos),
                        lc.scaleTo(0.15, 2.1 * scale)
                    ),
                    waitTime,
                    lc.spawn(
                        lc.moveTo(0.15, cc.p(x, y)),
                        lc.scaleTo(0.15, scale)
                    )
                )
            ) 

            lc.Audio.playAudio(AUDIO.E_TAVERN_FLIP_UR)
        end
        
        layout._par1:removeFromParent()
    end))
    
    --------------------------------------- Guide ------------------------------------------------------------------------
    GuideManager.closeNpcTipLayer()
    --------------------------------------- Guide ------------------------------------------------------------------------ 
end

function _M:showButtons()
    local tavernScene = lc._runningScene
    local isFinish = self._packageIndex * _M.PACKAGE_CARD_COUNT >= #self._newCards
    local isOnce = self._packageIndex == 1 and isFinish

    -- if self._packageIndex * _M.PACKAGE_CARD_COUNT >= #self._newCards then
    local node = cc.Node:create()
    lc.addChildToPos(self, node, cc.p(lc.cw(self), 70))

    if isFinish then
        local btnBack = V.createScale9ShaderButton("img_btn_1_s", function(sender)
            self:finish()
        end, V.CRECT_BUTTON_1_S, 300)
        lc.addChildToCenter(node, btnBack)
        btnBack:addLabel(Str(STR.BACK))
        self._btnBack = btnBack

    else
        local btnNext = V.createScale9ShaderButton("img_btn_1_s", function(sender)
            _M.create(_M.Mode.open_one, self._newCards, self._recruitInfo, self._recruitInfoOnce, self._packageIndex + 1):show()
            self:removeFromParent()
        end, V.CRECT_BUTTON_1_S, 300)
        btnNext:addLabel(Str(STR.RECRUIT_NEXT_ONE))
        lc.addChildToCenter(node, btnNext)
        self._btnNext = btnNext
    end

    node:setScale(0)
    node:runAction(lc.sequence(
        lc.delay(0.65),
        lc.ease(lc.scaleTo(0.5, 1.0), "BackO")
        ))

    --------------------------------------- Guide ------------------------------------------------------------------------
    GuideManager.finishStepLater(0.5)
    --------------------------------------- Guide ------------------------------------------------------------------------ 
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "open package" then
        GuideManager.setOperateLayer(self._package)
    elseif curStep == "click card" then
        GuideManager.setOperateLayer(self._cardThumbnails[1])
    elseif curStep == "leave card reward" then
        GuideManager.setOperateLayer(self._btnBack, nil, self._cardThumbnails)
        
        for i = 1,  #lc._runningScene._scene:getChildren() do
            local child = lc._runningScene._scene:getChildren()[i]
            if child._panelName == "CardInfoPanel" then 
                GuideManager.pauseGuide()
                break
            end
        end

    else
        return
    end
        
    event:stopPropagation()
end

function _M:finish()
    local cards = self._newCards

    self:hide()
    return lc._runningScene:afterOpenPackage(cards)
end

function _M:showTotalCards()
    self._isShowTotalList = true

    local cards = {}
    for i = 1, #self._newCards do
        local info = self._newCards[i]
        
        local index = #cards + 1
        for j = 1, #cards do
            if cards[j]._infoId == info._infoId then
                index = j
                break
            end
        end

        if not cards[index] then
            cards[index] = {_infoId = info._infoId, _num = 1}
        else
            cards[index]._num = cards[index]._num + 1
        end
    end
    table.sort(cards, function (a, b) return Data.getInfo(a._infoId)._quality > Data.getInfo(b._infoId)._quality  end)

    -- ui
    local titleBg = lc.createSprite("img_title_bg")
    titleBg:setScale(600 / lc.w(titleBg), 1)
    lc.addChildToPos(self, titleBg, cc.p(lc.w(self) / 2, lc.h(self) - 50))

    local title = V.createTTF(Str(STR.GET)..Str(STR.CARD), V.FontSize.S1, lc.Color3B.yellow)
    lc.addChildToPos(self, title, cc.p(lc.x(titleBg), lc.y(titleBg)))

    local width = math.min(V.SCR_W - 240, 800)
    self._cardList = require("CardList").create(cc.size(width, 510), 0.32, false)
    self._cardList:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self, self._cardList, cc.p(V.SCR_CW, V.SCR_CH + 20))

    local offsetx = 20
    self._cardList._pageLeft._pos = cc.p(-offsetx, lc.ch(self._cardList))
    self._cardList._pageRight._pos = cc.p(lc.w(self._cardList) + offsetx, lc.ch(self._cardList))

    offsetx = 240 - (lc.x(self._cardList) - lc.cw(self._cardList))
    local pageBg = lc.createSprite({_name = "img_page_bg", _size = cc.size(125, 33), _crect = cc.rect(11, 11, 4, 8)}) 
    lc.addChildToPos(self._cardList, pageBg, cc.p(lc.cw(self._cardList), -8), -1)
    pageBg:setFlippedX(true)
    pageBg:setScale(0.8)
    self._cardList._pageLabel:setPosition(cc.p(pageBg:getPosition()))

    self._cardList:setMode(require("CardList").ModeType.recruite_list)
    self._cardList._recruiteInfo = cards
    self._cardList:init(nil, {})
    self._cardList:refresh(true)

    self._cardList:registerCardSelectedHandler(function(data) 
        require("CardInfoPanel").create(data, 1, require("CardInfoPanel").OperateType.view):show()
    end)

    -- button
    local node = cc.Node:create()
    lc.addChildToPos(self, node, cc.p(lc.cw(self), 70))

    local btnBack = V.createScale9ShaderButton("img_btn_2_s", function(sender)
        self:finish()
    end, V.CRECT_BUTTON_1_S, 300)
    btnBack:addLabel(Str(STR.BACK))
    lc.addChildToCenter(node, btnBack)
    self._btnBack = btnBack

    -- animation
    self._cardList:setPosition(cc.p(V.SCR_CW, -lc.ch(self._cardList)))
    self._cardList:runAction(lc.sequence(
        lc.delay(0.5),
        lc.ease(lc.moveTo(0.5, cc.p(V.SCR_CW, V.SCR_CH + 20)), "BackO")
        ))

    node:setScale(0)
    node:runAction(lc.sequence(
        lc.delay(1.0),
        lc.ease(lc.scaleTo(0.5, 1.0), "BackO")
        ))
end

return _M
