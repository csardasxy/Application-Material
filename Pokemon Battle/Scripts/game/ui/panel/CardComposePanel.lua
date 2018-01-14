local _M = class("CardPackagePanel", require("BasePanel"))

local CardThumbnail = require("CardThumbnail")

_M.PACKAGE_CARD_COUNT = 5

function _M.create(...)
    local form = _M.new(lc.EXTEND_LAYOUT_MASK) 
    form:init(...)

    return form   
end

function _M:init(cardId)
    _M.super.init(self, true)

    self._cardId = cardId
    self:addTouchEventListener(function(sender, type)
        if type == ccui.TouchEventType.ended then
            return true
        end
    end)
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}

    self:start()
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
    lc.Audio.playAudio(AUDIO.E_TAVERN_OPEN_PACKAGE)

    self:runAction(lc.sequence(
        0, function ()
            local par = Particle.create("hecheng_1")
            lc.addChildToPos(self, par, cc.p(V.SCR_CW, V.SCR_CH + 260), 20)
        end,
        0.15, function () 
            local par = Particle.create("hecheng_2")
            lc.addChildToCenter(self, par, 20)
        end,
        0.65, function ()
            local par = Particle.create("hecheng_3")
            lc.addChildToCenter(self, par, 20)
        end, 
        0.15, function ()
            local par = Particle.create("hecheng_4")
            lc.addChildToCenter(self, par)
        end,
        0.15,function ()

            self:showCards()
        end
    ))
end

function _M:showCards()
    self._isEndShowCards = false

    local cardInfo = Data.getInfo(self._cardId)
    local cards = {cardInfo}
    self._cardThumbnails = {}
    for i = 1, #cards do
        local card = cards[i]
        local pos = cc.p(V.SCR_CW, V.SCR_CH)
        local rot = (i - 2) * 5

        local layout = ccui.Layout:create()
        layout:setAnchorPoint(0.5, 0.5)
        layout:setContentSize(cc.size(275, 410))
        lc.addChildToCenter(self, layout, 10)
        self._cardThumbnails[i] = layout
        layout._card = card

        local item = CardThumbnail.createFromPool(self._cardId, 1.0)
        item._thumbnail:updateFlag()
        lc.addChildToCenter(layout, item)
        layout._cardSprite = item


        local effectNode = cc.Node:create()
        lc.addChildToCenter(layout, effectNode)
        layout._effectNode = effectNode

        self:endShowCards()
    end
end

function _M:endShowCards()
    self._isEndShowCards = true

    local scale = 1
    local timeScales = {0.8, 1.2, 1.0}

    for i = 1, #self._cardThumbnails do
        local layout = self._cardThumbnails[i]
        local timeScale = timeScales[i] 
        local info = Data.getInfo(self._cardId)

        layout:runAction(lc.sequence(
            lc.scaleTo(0.2 *timeScale , scale * 1.1),
            lc.scaleTo(0.3 * timeScale, scale),
            function () 
                layout:runAction(lc.rep(lc.sequence(
                    lc.scaleTo(0.3 , scale * 1.05),
                    lc.scaleTo(0.4, scale)
                )))
            end
        ))

        layout:setTouchEnabled(true)
        layout:setTouchSwallow(true)
        layout:addTouchEventListener(function(sender, evt)
            if evt == ccui.TouchEventType.ended then
                return require("CardInfoPanel").create(self._cardId):show()
            end
        end) 
        
    end

    self:showButtons()
end

function _M:showButtons()

    local titleBg = lc.createSprite({_name = "img_form_title_bg_1", _crect = V.CRECT_FORM_TITLE_BG1_CRECT, _size = cc.size(560, V.CRECT_FORM_TITLE_BG1_CRECT.height)})
    lc.addChildToPos(self, titleBg, cc.p(lc.cw(self), lc.ch(self) + lc.h(titleBg) + 200), 10)

    local light = lc.createSprite({_name = "img_form_title_light_1", _crect = V.CRECT_FORM_TITLE_LIGHT1_CRECT, _size = cc.size(200, V.CRECT_FORM_TITLE_LIGHT1_CRECT.height)})
    lc.addChildToPos(titleBg, light, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4))

    local titleLabel = V.createTTF(Str(STR.COMPOSE)..Str(STR.SUCCESS), V.FontSize.M1, V.COLOR_TEXT_WHITE)
    titleLabel:setColor(V.COLOR_TEXT_TITLE)
    titleLabel:setPosition(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4)
    titleBg:addChild(titleLabel)
    self._titleLabel = titleLabel

    local node = cc.Node:create()
    lc.addChildToPos(self, node, cc.p(lc.cw(self), 70))

    local btnBack = V.createScale9ShaderButton("img_btn_1_s", function(sender)
        self:hide()
    end, V.CRECT_BUTTON_1_S, 300)
    lc.addChildToCenter(node, btnBack)
    btnBack:addLabel(Str(STR.BACK))
    self._btnBack = btnBack

    node:setScale(0)
    node:runAction(lc.sequence(
        lc.delay(0.4),
        lc.ease(lc.scaleTo(0.5, 1.0), "BackO")
        ))

end

return _M
