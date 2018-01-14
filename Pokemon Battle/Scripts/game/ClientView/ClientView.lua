local _M = {}

_M.SCR_SIZE = lc.Director:getVisibleSize()
_M.SCR_W = _M.SCR_SIZE.width
_M.SCR_CW = _M.SCR_W / 2
_M.SCR_H = _M.SCR_SIZE.height
_M.SCR_CH = _M.SCR_H / 2

----------------- Font -----------------
_M.TTF_FONT_BOLD = "res/updater/FZZDHJW.TTF"
_M.TTF_FONT = "res/updater/SIMHEI.TTF"

_M.FontSize = 
{
    B1                      = 48,
    B2                      = 36,
    M1                      = 32,
    M2                      = 28,
    S1                      = 26,
    S2                      = 22,
    S3                      = 20,
    S4                      = 18,
}

_M.BMFont = 
{   
    huali_20                = "res/fonts/huali_26.fnt",
    huali_26                = "res/fonts/huali_26.fnt",
    huali_32                = "res/fonts/huali_32.fnt",
    num_48                  = "res/fonts/num_48.fnt",
    num_43                  = "res/fonts/number_43.fnt",
    num_24                  = "res/fonts/yxw_number_csrd_24.fnt",

    number_legend           = "res/fonts/legend_num.fnt",

    skill                   = "res/fonts/skills_name.fnt",
}

_M.trophyGradeBones = 
{
    "qingtong",
    "baiying",
    "huangjin",
    "bojin",
    "chuanshuo",
}

_M.BMFONTS_COMMON           = {_M.BMFont.huali_26, _M.BMFont.huali_32, _M.BMFont.num_48, _M.BMFont.num_43}
_M.BMFONTS_CITY             = {_M.BMFont.vip, _M.BMFont.number_legend}
_M.BMFONTS_BATTLE           = {_M.BMFont.skill}

----------------- Shader -----------------

_M.SHADER_PRESS             = cc.ShaderEffect:create("res/shader/highlight.fsh")
_M.SHADER_DISABLE           = cc.ShaderEffect:create("res/shader/gray.fsh")
_M.SHADER_GRAY_FRAME        = cc.ShaderEffect:create("res/shader/gray_light.fsh")

_M.SHADER_G2B               = cc.ShaderEffect:create("res/shader/colorG2B.fsh")
_M.SHADER_G2Y               = cc.ShaderEffect:create("res/shader/colorG2Y.fsh")


_M.SHADER_COLORS = {
    cc.ShaderEffect:create("res/shader/colorGreen.fsh"),
    cc.ShaderEffect:create("res/shader/colorBlue.fsh"),
    cc.ShaderEffect:create("res/shader/colorPurple.fsh"),
    cc.ShaderEffect:create("res/shader/colorYellow.fsh"),
    cc.ShaderEffect:create("res/shader/colorRed.fsh")
}

_M.SHADER_TYPES = {
    [Data.CardType.monster] = cc.ShaderEffect:create("res/shader/colorYellow.fsh"),
    [Data.CardType.magic] = cc.ShaderEffect:create("res/shader/colorGreen.fsh"),
    [Data.CardType.trap] = cc.ShaderEffect:create("res/shader/colorPurple.fsh"),
    [Data.CardType.monster + 100] = cc.ShaderEffect:create("res/shader/colorOrange.fsh"),
}

_M.SHADER_COLOR_STAGE_SILVER = cc.ShaderEffect:create("res/shader/colorStageSilver.fsh")
_M.SHADER_COLOR_STAGE_BRONZE = cc.ShaderEffect:create("res/shader/colorStageBronze.fsh")

----------------- Constant -----------------

--[[--
Scale9 Rect
--]]--

_M.CRECT_COM_BG1 = cc.rect(56, 0, 3, 48)
_M.CRECT_COM_BG2 = cc.rect(8, 0, 122, 30)
_M.CRECT_COM_BG3 = cc.rect(17, 22, 1, 1)
_M.CRECT_COM_BG4 = cc.rect(22, 50, 1, 1)
_M.CRECT_COM_BG5 = cc.rect(17, 22, 1, 1)
_M.CRECT_COM_BG7 = cc.rect(17, 30, 1, 2)
_M.CRECT_COM_BG9 = cc.rect(28, 48, 2, 2)
_M.CRECT_COM_BG10 = cc.rect(18, 20, 2, 1)
_M.CRECT_COM_BG11 = cc.rect(20, 32, 2, 2)
_M.CRECT_COM_BG12 = cc.rect(28, 0, 2, 38)
_M.CRECT_COM_BG13 = cc.rect(0, 35, 256, 1)
_M.CRECT_COM_BG14 = cc.rect(28, 28, 4, 4)
_M.CRECT_COM_BG15 = cc.rect(24, 26, 1, 1)
_M.CRECT_COM_BG16 = cc.rect(70, 75, 1, 1)
_M.CRECT_COM_BG17 = cc.rect(51, 65, 1, 1)
_M.CRECT_COM_BG18 = cc.rect(257, 0, 1, 1)
_M.CRECT_COM_BG20 = cc.rect(6, 6, 1, 1)
_M.CRECT_COM_BG21 = cc.rect(88, 78, 1, 1)
_M.CRECT_COM_BG22 = cc.rect(30, 32, 2, 2)
_M.CRECT_COM_BG23 = cc.rect(4, 4, 2, 2)
_M.CRECT_COM_BG24 = cc.rect(63, 63, 1, 1)
_M.CRECT_COM_BG25 = cc.rect(24, 26, 2, 2)
_M.CRECT_COM_BG26 = cc.rect(11, 11, 1, 1)
_M.CRECT_COM_BG27 = cc.rect(8, 8, 2, 2)
_M.CRECT_COM_BG29 = cc.rect(18, 0, 1, 230)
_M.CRECT_COM_BG30 = cc.rect(16, 16, 2, 1)
_M.CRECT_COM_BG31 = cc.rect(42, 52, 2, 2)
_M.CRECT_COM_BG32 = cc.rect(33, 0, 1, 45)
_M.CRECT_COM_BG33 = cc.rect(20, 0, 2, 152)
_M.CRECT_COM_BG34 = cc.rect(19, 0, 2, 32)
_M.CRECT_COM_BG35 = cc.rect(20, 30, 2, 48)
_M.CRECT_COM_BG36 = cc.rect(7, 55, 1, 1)
_M.CRECT_COM_BG37 = cc.rect(25, 27, 1, 2)
_M.CRECT_COM_BG42 = cc.rect(8, 14, 1, 1)
_M.CRECT_COM_BG43 = cc.rect(88, 0, 2, 97)
_M.CRECT_COM_BG44 = cc.rect(88, 0, 2, 97)
_M.CRECT_COM_BG45 = cc.rect(51, 35, 113, 1)
_M.CRECT_COM_BG46 = cc.rect(35, 58, 1, 1)
_M.CRECT_COM_BG55 = cc.rect(24, 0, 1, 81)
_M.CRECT_COM_BG57 = cc.rect(7, 7, 1, 1)
_M.CRECT_COM_BG58 = cc.rect(58, 0, 1, 34)

_M.CRECT_FRAME1 = cc.rect(14, 18, 1, 1)
_M.CRECT_FRAME2 = cc.rect(32, 50, 1, 1)

_M.CRECT_FORM_FRAME = cc.rect(74, 64, 1, 1)
_M.CRECT_FORM_TITLE_BG2 = cc.rect(240, 0, 3, 54)
_M.CRECT_RECT_INTERNAL = cc.rect(44, 93, 1, 1)
_M.CRECT_TIP_BG = cc.rect(40, 40, 1, 1)
_M.CRECT_TOAST_BG = cc.rect(45, 43, 2, 1)
_M.CRECT_UI_FRAME = cc.rect(25, 25, 1, 1)

_M.CRECT_TITLE_AREA_BG = cc.rect(30, 0, 69, 72)
_M.CRECT_TITLE_BG = cc.rect(115, 0, 1, 51)

_M.CRECT_BUTTON = cc.rect(20, 0, 1, 78)
_M.CRECT_BUTTON_S = cc.rect(20, 0, 6, 54)
_M.CRECT_BUTTON_SQUARE = cc.rect(30, 0, 3, 61)
_M.CRECT_BUTTON_CHECK = cc.rect(22, 0, 2, 46)
_M.CRECT_BUTTON_TAB_2 = cc.rect(25, 0, 1, 54)

_M.CRECT_ARROW_3 = cc.rect(0, 32, 40, 1)
_M.CRECT_ARROW_4 = cc.rect(0, 32, 40, 1)

_M.CRECT_PROGRESS_BG = cc.rect(14, 0, 1, 27)
_M.CRECT_PROGRESS_FG = cc.rect(13, 0, 1, 23)

_M.CRECT_LABEL_DECORATION = cc.rect(124, 0, 1 , 7)

_M.CRECT_FORM_TITLE_BG1_CRECT = cc.rect(188, 0, 1, 63)
_M.CRECT_FORM_TITLE_LIGHT1_CRECT = cc.rect(47, 0, 2, 40)

_M.CRECT_INPUT_BOX_BG = cc.rect(36, 14, 2, 2)
_M.CRECT_BUTTON_1_S = cc.rect(23, 0, 1, 55)
_M.CRECT_TROOP_BG = cc.rect(20, 20, 2, 2)

--[[--
Size related
--]]--

_M.UI_SCENE_TITLE_HEIGHT = 51
_M.VERTICAL_TAB_WIDTH = 250
_M.HORIZONTAL_TAB_HEIGHT = 62

_M.AREA_MAX_WIDTH = 1300

_M.PANEL_BTN_WIDTH = 150
_M.PANEL_BOTTOM_HEIGHT = 80

_M.FRAME_INNER_TOP = 28
_M.FRAME_INNER_LEFT = 20
_M.FRAME_INNER_RIGHT = 20
_M.FRAME_INNER_BOTTOM = 28
_M.FRAME_TAB_WIDTH = 114

_M.UNION_BUTTON_AREA_SIZE = cc.size(280, 370)

--[[--
Text Color
--]]--

_M.COLOR_BMFONT = cc.c3b(255, 250, 240)

_M.COLOR_TEXT_TITLE = cc.c3b(253, 218, 106)
_M.COLOR_TEXT_TITLE_DESC = cc.c3b(230, 200, 160)
_M.COLOR_BUTTON_TITLE = cc.c3b(252, 234, 170)

_M.COLOR_LABEL_LIGHT = cc.c3b(240, 150, 70)
_M.COLOR_LABEL_DARK = cc.c3b(96, 64, 32)
_M.COLOR_TEXT_LIGHT = _M.COLOR_BMFONT
_M.COLOR_TEXT_DARK = cc.c3b(10, 10, 0)

_M.COLOR_TEXT_WHITE = _M.COLOR_BMFONT
_M.COLOR_TEXT_GREEN = cc.c3b(200, 250, 150)
_M.COLOR_TEXT_GREEN_2 = cc.c3b(40, 210, 40)
_M.COLOR_TEXT_BLUE = cc.c3b(150, 220, 250)
_M.COLOR_TEXT_BLUE_2 = cc.c3b(0, 120, 230)
_M.COLOR_TEXT_PURPLE = cc.c3b(220, 130, 255)
_M.COLOR_TEXT_ORANGE = cc.c3b(255, 200, 60)
_M.COLOR_TEXT_RED = cc.c3b(255, 100, 100)
_M.COLOR_TEXT_GREEN_DARK = cc.c3b(60, 255, 80)
_M.COLOR_TEXT_BLUE_DARK = cc.c3b(0, 0, 128)
_M.COLOR_TEXT_PURPLE_DARK = cc.c3b(160, 0, 160)
_M.COLOR_TEXT_ORANGE_DARK = cc.c3b(150, 120, 20)
_M.COLOR_TEXT_RED_DARK = cc.c3b(180, 10, 10)
_M.COLOR_TEXT_GRAY = cc.c3b(96, 96, 96)
_M.COLOR_TEXT_LIGHT_BLUE = cc.c3b(75, 255, 250)
_M.COLOR_TEXT_MENU_WHITE = cc.c3b(196, 236, 255)

_M.COLOR_TEXT_VIP = cc.c3b(255, 100, 50)
_M.COLOR_TEXT_INGOT = cc.c3b(255, 255, 128)

_M.COLOR_GLOW = cc.c3b(250, 250, 120)
_M.COLOR_GLOW_BLUE = cc.c3b(180, 250, 250)
_M.COLOR_DARK_BG = cc.c4b(64, 64, 64)
_M.COLOR_DARK_OUTLINE = cc.c4b(15, 10, 23, 255)

_M.COLOR_UNION_TITLE = cc.c3b(254, 211, 117)
_M.COLOR_LEGEND_NUM = cc.c3b(255, 255, 120)

_M.COLOR_RES_LABEL_BG_LIGHT = cc.c3b(120, 60, 0)
_M.COLOR_RES_LABEL_BG_DARK = cc.c3b(60, 30, 0)
_M.COLOR_SHADOW_BG_BLUE = cc.c4b(5, 85, 100, 255)
_M.COLOR_SHADOW_BG_BROWN = cc.c4b(60, 30, 0, 255)

_M.COLOR_DIVIDING_LINE_DARK = cc.c3b(70, 45, 10)
_M.COLOR_DIVIDING_LINE_LIGHT = cc.c3b(180, 210, 240)

--_M.COLORS_TEXT_CLASH_GRADE = {cc.c3b(220, 160, 140), cc.c3b(200, 220, 220), lc.Color3B.yellow, lc.Color3B.white, cc.c3b(160, 220, 250), _M.COLOR_TEXT_ORANGE}
_M.COLORS_TEXT_CLASH_GRADE = {_M.COLOR_TEXT_WHITE, _M.COLOR_TEXT_WHITE, _M.COLOR_TEXT_WHITE, _M.COLOR_TEXT_WHITE, _M.COLOR_TEXT_WHITE, _M.COLOR_TEXT_WHITE}

--[[--
Mask layer opacity
--]]--

_M.MASK_OPACITY_LIGHT = 128
_M.MASK_OPACITY_DARK = 200

--[[--
Card
--]]--
_M.CARD_SIZE = cc.size(486, 678)
_M.BATTLE_ROTATION_X = 12
_M.MAX_STAR_COUNT = 15

--[[--
Other data
--]]--
_M.RICHTEXT_PARAM_DARK_S1 = {_normalClr = _M.COLOR_TEXT_DARK, _boldClr = _M.COLOR_TEXT_GREEN_DARK, _fontSize = _M.FontSize.S1}
_M.RICHTEXT_PARAM_DARK_S2 = {_normalClr = _M.COLOR_TEXT_DARK, _boldClr = _M.COLOR_TEXT_GREEN_DARK, _fontSize = _M.FontSize.S2}
_M.RICHTEXT_PARAM_LIGHT_S1 = {_normalClr = _M.COLOR_TEXT_LIGHT, _boldClr = _M.COLOR_TEXT_GREEN, _fontSize = _M.FontSize.S1}
_M.RICHTEXT_PARAM_LIGHT_S2 = {_normalClr = _M.COLOR_TEXT_LIGHT, _boldClr = _M.COLOR_TEXT_GREEN, _fontSize = _M.FontSize.S2}
_M.RICHTEXT_PARAM_DARK_GEEN_S2 = {_normalClr = lc.Color3B.black, _boldClr = _M.COLOR_TEXT_GREEN_2, _fontSize = _M.FontSize.S2}

_M.RICHTEXT_PARAM_LIGHT_S3 = {_normalClr = _M.COLOR_TEXT_LIGHT, _boldClr = _M.COLOR_TEXT_GREEN, _fontSize = _M.FontSize.S3}


--[[--
Classes requirement
--]]--

require("BasePanel")
require("BaseForm")
require("BaseScene")
require("BaseUIScene")

function _M.init()
    _M._resExchangeForms = {}

    _M._worldSwords = {}

    TextureManager.init()
end

function _M.blockTouch(parent)
    local layer = _M._blockTouchLayer
    if layer == nil then
        layer = _M.createTouchLayer()
        layer:setTouchEnabled(false)
        layer:retain()

        _M._blockTouchLayer = layer
    end

    if layer:getParent() then
        layer:removeFromParent()
    end

    layer:setTouchEnabled(true)
    layer:registerScriptHandler(function(evt)
        if evt == "exit" or evt == "cleanup" then
            layer:setTouchEnabled(false)
        end
    end)

    parent:addChild(layer)
end

function _M.createTouchLayer()
    local layer = cc.Layer:create()
    layer:setTouchEnabled(true)
    layer:registerScriptTouchHandler(function(evt, gx, gy)
        if evt == "began" then
            if layer == _M._blockTouchLayer then
                -- user tap on the block layer, notify the server for debug
                local parent, title = layer:getParent()
                if parent and parent._titleLabel and parent._titleLabel.getString then
                    title = parent._titleLabel:getString()
                end

                --lc.log("Block touch title: %s", title)
                --ClientData.sendUserEvent({touchOnBlockLayer = title, size = parent and string.format("(%d, %d)", lc.w(parent), lc.h(parent)) or "?"})
            end

            if layer:isTouchEnabled() then
                if layer._touchHandler then
                    return layer._touchHandler(evt, gx, gy)
                else
                    return 1
                end
            else
                return 0
            end
        end
    end, false, -2, true)

    return layer
end

function _M.createTouchSpriteWithMask(name, tapFunc)
    local sprite = lc.createSpriteWithMask(name)
    local widget = ccui.Widget:create()
    widget:setContentSize(sprite:getContentSize())
    widget:setTouchEnabled(true)
    widget:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    widget:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            tapFunc(sender)
        end
    end)
    lc.addChildToCenter(widget, sprite)
    widget._sprite = sprite
    return widget
end

function _M.createTouchSpriteWithShader(name, tapFunc)
    local sprite = cc.ShaderSprite:createWithFramename(name)
    local widget = ccui.Widget:create()
    widget:setContentSize(sprite:getContentSize())
    widget:setTouchEnabled(true)
    widget:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    widget:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            tapFunc(sender)
        end
    end)
    lc.addChildToCenter(widget, sprite)
    widget._sprite = sprite
    return widget
end

function _M.createLevelAreaNew(level)
    local levelBg = lc.createSprite("avatar_level_bg")
    levelBg:setCascadeOpacityEnabled(true)

    local levelValue = cc.Label:createWithTTF(string.format("Lv.%d", level), _M.TTF_FONT, _M.FontSize.S2)
    levelValue:setColor(_M.COLOR_TEXT_LIGHT)
    levelValue:setPosition(lc.w(levelBg) / 2, lc.h(levelBg) / 2)
    levelBg:addChild(levelValue)
    levelBg._level = levelValue

    function levelBg:setString(string)
        self._level:setString(string)
    end
    return levelBg
end

function _M.createEditBox(bgFrame, bgCRect, size, holderStr, isSingleLine, maxLength)    
    local editor = ccui.EditBox:create(size, ccui.Scale9Sprite:createWithSpriteFrameName(bgFrame, bgCRect))
    if isSingleLine then
        editor:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        editor:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    else
        editor:setInputMode(cc.EDITBOX_INPUT_MODE_ANY)
        editor:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    end
    editor:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_SENTENCE)
    editor:setFont(_M.TTF_FONT, _M.FontSize.S2)

    if maxLength then editor:setMaxLength(maxLength) end

    if holderStr then
        editor:setPlaceHolder(holderStr)
        editor:setPlaceholderFont(_M.TTF_FONT, _M.FontSize.S2)
    end

    editor.isValidName = function(self, width)
        width = width or ClientData.MAX_NAME_DISPLAY_LEN
        local name = string.trim(self:getText())
        if name == "" then
            return false
        end

        local ttf = _M.createTTF(name, _M.FontSize.S2)
        return lc.w(ttf) <= width
    end
    
    return editor
end

function _M.createSword(sword)
    local node = cc.Node:create()
    node:setAnchorPoint(cc.p(0.5, 0.5))
    node:setCascadeOpacityEnabled(true)
    
    local name = "img_sword"
    if sword ~= nil and sword > 0 then
        name = name..sword
    end

    local sprite1 = cc.Sprite:createWithSpriteFrameName(name)
    local sprite2 = cc.Sprite:createWithSpriteFrameName(name)

    local w = 200
    local h = lc.h(sprite1)
    node:setContentSize(cc.size(w, h))

    sprite1:setFlippedX(true)
    sprite1:setAnchorPoint(0.5, 0)
    sprite2:setAnchorPoint(0.5, 0)            
    sprite1:setPosition(0, 0)
    sprite2:setPosition(w, 0)
    node:addChild(sprite1, 1)
    node:addChild(sprite2, 1)   
    
    node._sprite1 = sprite1
    node._sprite2 = sprite2 

    local createAction = function(srcPos, dstPos, srcRotation, dstRotation, isParticle)
        local action1 = cc.Spawn:create(cc.MoveTo:create(0.3, dstPos), cc.RotateTo:create(0.3, dstRotation))
        local action2 = cc.Spawn:create(cc.MoveTo:create(0.3, srcPos), cc.RotateTo:create(0.3, srcRotation))
        local func = cc.CallFunc:create(function()
            if node:getOpacity() == 0xFF then  
                local particle = Particle.create("par_city_chapter") 
                particle:setPosition(w / 2, h / 2)
                node:addChild(particle)
            end                  
        end)

        if isParticle then
            return cc.Sequence:create(action1, func, cc.DelayTime:create(0.1), action2)
        else
            return cc.Sequence:create(action1, cc.DelayTime:create(0.1), action2)
        end
    end
    sprite1:runAction(cc.RepeatForever:create(createAction(cc.p(lc.x(sprite1), lc.y(sprite1)), cc.p(lc.x(sprite1) + 50, lc.y(sprite1)), sprite1:getRotation(), sprite1:getRotation() + 45, true)))
    sprite2:runAction(cc.RepeatForever:create(createAction(cc.p(lc.x(sprite2), lc.y(sprite2)), cc.p(lc.x(sprite2) - 50, lc.y(sprite2)), sprite2:getRotation(), sprite2:getRotation() - 45, false)))

    return node
end

function _M.createBMFont(fontName, str, textHAlignment, maxWidth)
    local label
    if textHAlignment and maxWidth then
        label = cc.Label:createWithBMFont(fontName, str, textHAlignment, maxWidth)
    else     
        label = cc.Label:createWithBMFont(fontName, str)
    end
    label:setColor(_M.COLOR_BMFONT)
    return label
end

function _M.createTTF(str, fontSize, clr, ...)
    local ttf = cc.Label:createWithTTF(str, _M.TTF_FONT, fontSize or _M.FontSize.S3, ...)
    ttf:setColor(clr or _M.COLOR_TEXT_LIGHT)
    return ttf
end

function _M.createTTFBold(str, fontSize, clr, ...)
    local ttf = cc.Label:createWithTTF(str, _M.TTF_FONT_BOLD, fontSize or _M.FontSize.S2, ...)
    ttf:setColor(clr or _M.COLOR_TEXT_LIGHT)
    return ttf
end

function _M.createTTFStroke(str, fontSize, clr, outlineSize, ...)
    local ttf = cc.Label:createWithTTF(str, _M.TTF_FONT_BOLD, fontSize or _M.FontSize.S2, ...)
    ttf:setColor(clr or _M.COLOR_TEXT_LIGHT)
    ttf:enableOutline(V.COLOR_DARK_OUTLINE, outlineSize or 2)
    return ttf
end

function _M.createVerticalTitle(title, bgColor)
    local titleCharLen, lineH = title:len() / 3, 28

    local titleBg = lc.createSprite{_name = "img_com_bg_2", _crect = _M.CRECT_COM_BG2, _size = cc.size(titleCharLen * lineH + 20, 40)}
    titleBg:setRotation(90)
    titleBg:setColor(bgColor or lc.Color3B.black)
    titleBg:setOpacity(180)

    local area = lc.createNode(cc.size(lc.h(titleBg), lc.w(titleBg)))
    lc.addChildToCenter(area, titleBg)

    local title = _M.createBMFont(_M.BMFont.huali_26, title, cc.TEXT_ALIGNMENT_CENTER, lineH)
    title:setLineHeight(lineH)
    lc.addChildToCenter(area, title)
    area._title = title

    return area
end

function _M.addFixityName(fixity, name, color, bgColor, pos)
    name = name:gsub("%s", "")
    local nameCharLen = name:len() / 3

    local lineHeight = (nameCharLen > 3 and 32 or 38)

    local nameBg = ccui.Scale9Sprite:createWithSpriteFrameName("img_com_bg_2", _M.CRECT_COM_BG2)
    nameBg:setContentSize(nameCharLen * lineHeight + 50, 48)
    nameBg:setRotation(90)
    nameBg:setColor(bgColor or lc.Color3B.black)
    nameBg:setOpacity(120)
    lc.addChildToPos(fixity, nameBg, pos and pos or cc.p(0, lc.h(fixity) / 2), 1)

    local nameLabel = _M.createBMFont(_M.BMFont.huali_32, name, cc.TEXT_ALIGNMENT_CENTER, 30)
    nameLabel:setColor(color and color or _M.COLOR_BMFONT)
    nameLabel:setLineHeight(lineHeight)
    lc.addChildToPos(fixity, nameLabel, cc.p(lc.x(nameBg), lc.y(nameBg) + 6), 1)

    nameLabel._bg = nameBg
    fixity._name = nameLabel
    return nameLabel
end

function _M.createFrameBox(size, title)
    local frame = lc.createNode(size)
    if title then
        local frameBg = lc.createSprite({_name = 'img_troop_bg_5', _crect = cc.rect(28, 62, 2, 2), _size = size})
        lc.addChildToCenter(frame, frameBg, -2)
        frame._bg = frameBg
    else
        local frameBg = lc.createSprite({_name = 'img_troop_bg_1', _crect = cc.rect(25, 24, 2, 8), _size = size})
        lc.addChildToCenter(frame, frameBg, -2)
        frame._bg = frameBg
    end
    
    return frame
end

function _M.createHorizontalContentTab(size, tabInfos, tabWidth)
    -- The size is not including tab buttons
    local bg = lc.createSprite({_name = 'img_troop_bg_6', _size = size, _crect = cc.rect(20, 24, 2, 2)})
    
    if #tabInfos > 0 then
        local marginLeft = (tabInfos[1]._left or 80)
        local gap = 10
        bg._tabs = {}
        for i = 1, #tabInfos do
            local tabInfo = tabInfos[i]

            local btnWidth = tabInfo._width or 140 
            
            local tab = _M.createShaderButton(i == 1 and "img_btn_tab_bg_focus_6" or "img_btn_tab_bg_unfocus_6", function(sender) bg:showTab(i, false, true) end)
            lc.addChildToPos(bg, tab, cc.p(marginLeft + lc.w(tab) / 2, lc.h(bg) + lc.h(tab) / 2 - 4) , -1)
            tab._label = _M.createBMFont(_M.BMFont.huali_26, tabInfo._labelStr)
            lc.addChildToPos(tab, tab._label, cc.p(lc.w(tab) / 2 - 2, lc.h(tab) / 2))
            tab._handler = tabInfo._handler
            tab._checkHandler = tabInfo._checkHandler
            tab:setZoomScale(0)

            table.insert(bg._tabs, tab)

            marginLeft = marginLeft + lc.w(tab) + gap
        end
        
        bg.showTab = function(self, tabIndex, isForce, isUserBehavior)
            if self._focusTabIndex == tabIndex and not isForce then return end
            
            local newTabIndex = math.min(tabIndex, #self._tabs)
            local newTab = self._tabs[newTabIndex]
            if newTab._checkHandler and not newTab._checkHandler(newTabIndex, isUserBehavior) then
                return
            end

            if self._focusTabIndex ~= nil then
                local tab = self._tabs[self._focusTabIndex]
                tab:loadTextureNormal("img_btn_tab_bg_unfocus_6", ccui.TextureResType.plistType)
                --local btnWidth = tabInfos[self._focusTabIndex]._width or 140 
                --tab:setContentSize(btnWidth, 80)
                tab:setEnabled(true)
            end
            
            self._focusTabIndex = newTabIndex
            newTab:loadTextureNormal("img_btn_tab_bg_focus_6", ccui.TextureResType.plistType)
            --local btnWidth = tabInfos[self._focusTabIndex]._width or 140 
            --newTab:setContentSize(btnWidth, 80)
            newTab:setEnabled(false)

            if newTab._handler then newTab._handler(newTabIndex) end
        end
    end
    
    bg._content = lc.createNode(bg:getContentSize())
    lc.addChildToCenter(bg, bg._content)
    bg._focusTabIndex = 1
    
    return bg
end    



function _M.createLineSprite(fn, size)
    local height = lc.frameSize(fn).height
    local crect = cc.rect(1, 0, 1, height)
    local sprite = ccui.Scale9Sprite:createWithSpriteFrameName(fn, crect)
    sprite:setContentSize(size, height)
    return sprite
end

function _M.createDividingLine(w, color)
    local line = lc.createSprite("img_divide_line_8")
    if w then line:setScaleX(w / lc.w(line)) end
    if color then line:setColor(color) end
    return line
end

function _M.createCheckinTitle(title, w)
    --local bg = lc.createSprite{_name = "activity_tip_bg", _crect = cc.rect(0, 0, 84, 58), _size = cc.size(w, 58)}
    local title = _M.createBMFont(_M.BMFont.huali_32, title)
    --lc.addChildToPos(bg, title, cc.p(w / 2, lc.h(bg) / 2 + 3))
    return title
end

function _M.showHelpForm(title, helpType)
    local infos = {}
    for k, v in pairs(Data._helpInfo) do
        if v._type == helpType then
            table.insert(infos, v)
        end
    end
    table.sort(infos, function(a, b) return a._id < b._id end)

    local strs = {}
    for _, info in ipairs(infos) do
        table.insert(strs, Str(info._nameSid))
    end
    require("HelpForm").create(title, strs):show()
end

function _M.showVipExpEffect(parent, scaleX)
    local particle1 = Particle.create("vipjd2")
    local particle2 = Particle.create("vipjd3")
    if scaleX then
        particle1:setScaleX(scaleX)
        particle2:setScaleX(scaleX)
    end
    lc.addChildToCenter(parent, particle1)
    lc.addChildToCenter(parent, particle2)
end

function _M.addUISceneCommonFrames(parent, top)
    local frameZorder = 10

    -- Add frame top area
    local frameTopLine = _M.createLineSprite("img_divide_line_4", lc.w(parent))
    local y = top - lc.h(frameTopLine) / 2
    lc.addChildToPos(parent, frameTopLine, cc.p(lc.w(parent) / 2, y), frameZorder)
    parent._frameTopLine = frameTopLine

    local topBg = lc.createSprite("img_com_bg_8")
    topBg:setScaleX(lc.w(parent) / lc.w(topBg) + 0.1)           -- Add 0.1 to avoid transparent edge on left and right after scale
    lc.addChildToPos(parent, topBg, cc.p(lc.w(parent) / 2, y - lc.h(topBg) / 2))
    parent._frameTopBg = topBg
    
    -- Add frame bottom area
    local frameBottomLine = _M.createLineSprite("img_divide_line_4", lc.w(parent))
    frameBottomLine:setRotation(180)
    lc.addChildToPos(parent, frameBottomLine, cc.p(lc.w(parent) / 2, 4), frameZorder)
        
    local bottomBg = lc.createSprite("img_com_bg_8")
    bottomBg:setScaleX(lc.w(parent) / lc.w(bottomBg) + 0.1)      -- Add 0.1 to avoid transparent edge on left and right after scale
    bottomBg:setScaleY(2.0)
    lc.addChildToPos(parent, bottomBg, cc.p(lc.w(parent) / 2, lc.h(bottomBg) / 2 + 6))
    parent._frameBottomBg = bottomBg
end


function _M.addRoundEffect(parent, controlX)
    local PathFunc1 = function(controlX, controlY, w, h)
        local speed = 0.01
        local bezier1 = cc.BezierBy:create(speed * h, {cc.p(-controlX, 0), cc.p(-controlX, controlY), cc.p(0, controlY)})
        local move1 = cc.MoveBy:create(speed * w, cc.p(w, 0))
        local bezier2 = cc.BezierBy:create(speed * h, {cc.p(controlX, 0), cc.p(controlX, -controlY), cc.p(0, -controlY)})
        local move2 = cc.MoveBy:create(speed * w, cc.p(-w, 0))
        return cc.RepeatForever:create(cc.Sequence:create(bezier1, move1, bezier2, move2))
    end

    local PathFunc2 = function(controlX, controlY, w, h)
        local speed = 0.01
        local bezier1 = cc.BezierBy:create(speed * h, {cc.p(-controlX, 0), cc.p(-controlX, controlY), cc.p(0, controlY)})
        local move1 = cc.MoveBy:create(speed * w, cc.p(w, 0))
        local bezier2 = cc.BezierBy:create(speed * h, {cc.p(controlX, 0), cc.p(controlX, -controlY), cc.p(0, -controlY)})
        local move2 = cc.MoveBy:create(speed * w, cc.p(-w, 0))
        return cc.RepeatForever:create(cc.Sequence:create(bezier2, move2, bezier1, move1))
    end

    local particle1 = Particle.create("par_recharge")
    local particle2 = Particle.create("par_recharge")      
    local w = lc.sw(parent) - 2 * controlX
    local h = lc.sh(parent)
    particle1:setPositionType(cc.POSITION_TYPE_RELATIVE)
    particle1:setPosition(cc.p(controlX, 0))
    particle1:runAction(PathFunc1(controlX, lc.sh(parent), w, h))
    particle2:setPositionType(cc.POSITION_TYPE_RELATIVE)
    particle2:setPosition(cc.p(controlX + w, lc.sh(parent)))
    particle2:runAction(PathFunc2(controlX, lc.sh(parent), w, h))        
    parent:addChild(particle1)
    parent:addChild(particle2)  
end

function _M.addAvaiableArrow(node, x, y)
    if node._avaiableArrow then return end

    local arrow = lc.createSprite("img_arrow_up_2")
    arrow:setColor(_M.COLOR_TEXT_ORANGE)
    lc.addChildToPos(node, arrow, cc.p(x, y))

    local offY = 10
    arrow:runAction(lc.rep(lc.sequence(lc.moveBy(0.8, 0, offY), lc.moveBy(0.8, 0, -offY))))

    node._avaiableArrow = arrow
end


function _M.addIconValue(parent, iconName, value, x, y, isFlipX, valClr)
    local icon = lc.createSprite(iconName)
    lc.addChildToPos(parent, icon, cc.p(x, y))

    local value = _M.createBMFont(_M.BMFont.num_24, tostring(value))
   -- value:enableOutline(V.COLOR_DARK_OUTLINE, 1)
    value:setAnchorPoint(isFlipX and 1 or 0, 0.5)
    if valClr then value:setColor(valClr) end

    if isFlipX then
        lc.addChildToPos(parent, value, cc.p(lc.x(icon) - 30, y))
    else
        lc.addChildToPos(parent, value, cc.p(lc.x(icon) + 30, y))
    end

    return value, icon
end

function _M.addLockChains(parent, scale)
    local createChain = function(isFlipX)
        local rotation = 14
        local chain = lc.createSprite("img_chain")
        chain:setScale(scale)
        chain:setFlippedX(isFlipX)
        chain:setRotation(isFlipX and rotation or -rotation)
        return chain
    end

    local chain1 = createChain(false)
    lc.addChildToPos(parent, chain1, cc.p(lc.w(parent) / 2 + 5 * scale, lc.h(parent) / 2 - 20 * scale))

    local chain2 = createChain(true)
    lc.addChildToPos(parent, chain2, cc.p(lc.w(parent) / 2 - 5 * scale, lc.y(chain1)))

    local lock = lc.createSprite(("img_lock"))
    lock:setScale(scale)
    lc.addChildToPos(parent, lock, cc.p(lc.w(parent) / 2, lc.h(parent) / 2 - 50 * scale))
end

function _M.addUnionContribution(parent, str, strSize, x, y, act, wood)
    local label = _M.createTTF(str..": ", strSize)
    label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(parent, label, cc.p(x, y))

    local actValue = _M.addIconValue(parent, "img_icon_res13_s", act or 0, lc.right(label) + 16, lc.y(label))
--    local woodValue = _M.addIconValue(parent, "img_icon_res12_s", wood or 0, lc.right(label) + 140, lc.y(label))
--    woodValue:setColor(_M.COLOR_TEXT_DARK)
    return actValue--, woodValue
end

function _M.createTrophyGradeDB(grade)
    local bone = DragonBones.create(V.trophyGradeBones[grade])
    bone:gotoAndPlay("effect")
    return bone
end




function _M.checkIngot(need)
    if not P:hasResource(Data.ResType.ingot, need) then
        if ClientData.isHideCharge() then
            ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._resInfo[Data.ResType.ingot]._nameSid)))
        else
            require("PromptForm").ConfirmBuyIngot.create():show()
        end
        return false
    end

    return true
end

function _M.checkGold(need)
    if not P:hasResource(Data.ResType.gold, need) then
        ToastManager.push(Str(STR.NOT_ENOUGH_GOLD))
        require("ExchangeResForm").create(Data.ResType.gold):show()
        return false
    end

    return true
end

function _M.getWorldDisplayName(display)
    if display == Data.WorldDisplay.map then
        return Str(STR.WORLD_DISPLAY_MAP)
    else
        return Str(STR.STORY_LINE + display - 1)
    end
end

function _M.useSweepCard(count, isTry, callback)
    local sweepCardUsed = count
    if not P._propBag:hasProps(Data.PropsId.sweep_card, sweepCardUsed) then
        if isTry then
            require("PromptForm").ConfirmSweep.create(sweepCardUsed, callback):show()
            return false
        else
             sweepCardUsed = P._propBag._props[Data.PropsId.sweep_card]._num
             local ingotNeed = (count - sweepCardUsed) * 2
             P:changeResource(Data.ResType.ingot, -ingotNeed)
        end
    end

    P._propBag:changeProps(Data.PropsId.sweep_card, -sweepCardUsed)
    return true
end

function _M.getSkillDisplayInfo(skill)
    local skillInfo = (type(skill) == "table" and skill or Data._skillInfo[skill])

    local skillType = Data.getSkillType(skillInfo._id)
    local iconName = skillType == Data.SkillType.monster_attack and 'card_skill_power' or 'card_skill_ability'
    local nameStr = Str(skillInfo._nameSid)
    local descStr = ClientData.getSkillDesc(skillInfo._id)
    local damageStr = skillInfo._val[1] < 10 and 10 * skillInfo._val[1] or skillInfo._val[1]
    local powerStr = skillType == Data.SkillType.monster_attack and skillInfo._power or ''

    return iconName, nameStr, descStr, damageStr, powerStr
end

function _M.getMenuUI()
    if _M.MenuUI == nil then
        _M.MenuUI = require("MenuPanel").create()
        _M.MenuUI:retain()
    end

    return _M.MenuUI
end

function _M:releaseMenuUI()
    if _M.MenuUI ~= nil then
        _M.MenuUI:onRelease()        
        _M.MenuUI:release()        
        _M.MenuUI = nil
    end
end

function _M.removeMenuFromParent()
    if _M.MenuUI ~= nil then
        _M.MenuUI:removeFromParent(false)
    end
end

function _M.getResourceUI()
    if _M.ResourceUI == nil then
        _M.ResourceUI = require("ResourcePanel").create()
        _M.ResourceUI:retain()
    end

    return _M.ResourceUI
end

function _M.releaseResourceUI()
    if _M.ResourceUI ~= nil then
        _M.ResourceUI:onRelease()
        _M.ResourceUI:release()
        _M.ResourceUI = nil
    end
end

function _M.removeResourceFromParent()
    if _M.ResourceUI ~= nil then
        _M.ResourceUI:removeFromParent(false)
    end
end


function _M.getActiveIndicator()
    if _M.ActiveIndicator == nil then
        _M.ActiveIndicator = require("ActiveIndicator").create()
        _M.ActiveIndicator:retain()
    end

    return _M.ActiveIndicator
end

function _M.releaseActiveIndicator()
    if _M.ActiveIndicator ~= nil then
        _M.ActiveIndicator:removeAllChildren()
        _M.ActiveIndicator:release()        
        _M.ActiveIndicator = nil
    end   
end

function _M.showClaimBonusResult(bonus, result)
    if result == Data.ErrorType.ok then
        local RewardPanel = require("RewardPanel")
        RewardPanel.create(bonus, RewardPanel.MODE_CLAIM):show()
        lc.Audio.playAudio(AUDIO.E_CLAIM)
    elseif result == Data.ErrorType.claimed then
        ToastManager.push(Str(STR.CLAIMED)..Str(STR.BONUS))
    elseif result == Data.ErrorType.claim_not_support then
        ToastManager.push(Str(STR.CANNOT_CLAIM)..Str(STR.BONUS))
    end
end

function _M.operateMember(member, item)
    if member._unionId == 0 then return end
    if member._id == P._id then return end
    
    local playerUnion = P._playerUnion
    
    local buttonDefs = {}
    table.insert(buttonDefs, {_str = Str(STR.INFO), _handler = function() _M.visitUser(member) end})
    --[[
    if member._unionId == P._unionId then
        table.insert(buttonDefs, {_str = Str(STR.COMPARE), _handler = function() _M.compareUser(member) end})    
    end
    ]]
    table.insert(buttonDefs, {_str = Str(STR.LEAVE_MESSAGE), _handler = function() _M.mailUser(member) end})
    
    if member._unionId == P._unionId then
        if playerUnion:canOperate(playerUnion.Operate.give_leader) == Data.ErrorType.ok then
            table.insert(buttonDefs, {_str = Str(STR.UNION_GIVE_LEADER), _handler = function()
                require("Dialog").showDialog(Str(STR.UNION_GIVE_LEADER_TIP), function() ClientData.sendUnionGiveLeader(member._id) end)
            end})
        end

        if playerUnion:canOperate(playerUnion.Operate.set_job) == Data.ErrorType.ok then
            if member._unionJob == Data.UnionJob.rookie then
                table.insert(buttonDefs, {_str = Str(STR.UNION_PROMOTE), _handler = function()
                    ClientData.sendUnionPromote(member._id)
                end})
            end        
            if member._unionJob == Data.UnionJob.elder then
                table.insert(buttonDefs, {_str = Str(STR.UNION_DEMOTE), _handler = function()
                    ClientData.sendUnionDemote(member._id)
                end})
            end
        end

        if playerUnion:canOperate(playerUnion.Operate.fire_member) == Data.ErrorType.ok and P._unionJob > member._unionJob then
            table.insert(buttonDefs, {_str = Str(STR.UNION_FIRE_MEMBER), _handler = function()
                require("Dialog").showDialog(Str(STR.UNION_KICK_OUT_TIP), function() ClientData.sendUnionKickout(member._id) end)
            end})
        end

        -- Insert a separator before union operations
        if #buttonDefs > 3 then
            table.insert(buttonDefs, 4, {_isSeparator = true})
        else
            if not ClientData.isAppStoreReviewing() then
                table.insert(buttonDefs, {_isSeparator = true})
            end
        end

        -- Impeach union leader
        if member._unionJob == Data.UnionJob.leader then
            if playerUnion:canOperate(playerUnion.Operate.impeach) == Data.ErrorType.ok then
                if (ClientData.getCurrentTime() - member._lastLogin ) / Data.DAY_SECONDS > 6 then
                    table.insert(buttonDefs, {_str = Str(STR.UNION_IMPEACH), _handler = function() _M.impeachLeader(member) end, _onButtonCreate = function(button)
                        button:setDisplayFrame("img_btn_3")
                    end})
                end
            end
        end

        --send gift
        if ClientData.isActivityValid(ClientData.getActivityByType(803)) then
            table.insert(buttonDefs, {_isSeparator = true})
            table.insert(buttonDefs, {_str = Str(STR.SEND_GIFT), _handler = function()
                require("GivePropForm").create(member, 803):show()
            end})
        end

    end

    _M.showOperateTopMostPanel(member._name, buttonDefs, item)
end

function _M.operateGroupMember(item)
    local groupId = item._groupId
    local member = item._member
    local playerUnion = P._playerUnion

    if member._id == P._id or not (playerUnion._groupId and playerUnion._groupJob and playerUnion._groupId == groupId) then return end
    
    local buttonDefs = {}
    table.insert(buttonDefs, {_str = Str(STR.INFO), _handler = function() _M.visitUser(member) end})
    table.insert(buttonDefs, {_str = Str(STR.LEAVE_MESSAGE), _handler = function() _M.mailUser(member) end})
    
    if item._canOperate and playerUnion._groupJob == Data.GroupJob.leader then
        table.insert(buttonDefs, {_str = Str(STR.UNION_FIRE_MEMBER), _handler = function()
            require("Dialog").showDialog(Str(STR.GROUP_KICK_OUT_TIP), function() ClientData.sendGroupKick(groupId, member._id) end)
        end})
    end

    -- Insert a separator before group operations
    if #buttonDefs > 2 then
        table.insert(buttonDefs, 3, {_isSeparator = true})
    else
        if not ClientData.isAppStoreReviewing() then
            table.insert(buttonDefs, {_isSeparator = true})
        end
    end


    _M.showOperateTopMostPanel(member._name, buttonDefs, item)
end

function _M.operateUnion(union, item)
    local buttonDefs = {}
    table.insert(buttonDefs, {_str = Str(STR.UNION)..Str(STR.DETAIL), _handler = function()
        require("UnionDetailForm").create(union._id):show()
    end})

    if not P:hasUnion() and P:getMaxCharacterLevel() >= P._playerCity:getUnionUnlockLevel() then
        if union._joinType ~= Data.UnionJoinType.close then
            local isAny = union._joinType == Data.UnionJoinType.any
            local str = (isAny and Str(STR.JOIN) or Str(STR.APPLY)..Str(STR.JOIN))

            table.insert(buttonDefs, {_str = str, _handler = function()
                if not isAny then
                    ToastManager.push(Str(STR.UNION_APPLY_SEND))
                end

                ClientData.sendUnionApply(union._id, Str(STR.UNION_APPLY_MSG))
            end})
        end
    end

    _M.showOperateTopMostPanel(union._name, buttonDefs, item)
end

function _M.impeachLeader(member)
    require("ImpeachForm").create(member):show()
end

function _M.doPrivilege(privilege, param)
    if privilege == Data.Privilege.chat_ban then
        local user = param
        require("Dialog").showDialog(string.format(Str(STR.CONFIRM_CHAT_BAN), user._name), function()
            ClientData.sendChatBan(user._id)
        end)
    end
end

function _M.createBadge(badge, word)
    local badgeSprite = cc.Sprite:createWithSpriteFrameName(string.format("img_badge_%d", badge))
    --[[
    local leftArrow = cc.Sprite:createWithSpriteFrameName("img_badge_x3")
    local rightArrow = cc.Sprite:createWithSpriteFrameName("img_badge_x3")
    rightArrow:setFlippedX(true)    
    lc.addChildToPos(badgeSprite, leftArrow, cc.p(4 - lc.w(leftArrow) / 2, lc.h(badgeSprite) - lc.h(leftArrow) / 2), -1)
    lc.addChildToPos(badgeSprite, rightArrow, cc.p(lc.w(badgeSprite) + lc.w(rightArrow) / 2 - 6, lc.h(badgeSprite) - lc.h(rightArrow) / 2), -1)
    ]]
    if word then
        local wordBg = cc.Sprite:createWithSpriteFrameName("img_badge_word_bg")
        lc.addChildToPos(badgeSprite, wordBg, cc.p(lc.w(badgeSprite) / 2, lc.h(badgeSprite) / 2 + 4))

        local badgeWord = cc.Label:createWithTTF(word, _M.TTF_FONT, _M.FontSize.B1)
        badgeWord:setColor(lc.Color3B.yellow)
        lc.addChildToCenter(wordBg, badgeWord)    
    
        badgeSprite._bg = wordBg
        badgeSprite._label = badgeWord
    end
    
    badgeSprite.update = function(self, badge, word)
        self:setSpriteFrame(string.format("img_badge_%d", badge))
        if self._label then self._label:setString(word) end
    end
    
    return badgeSprite
end

function _M.createGroupAvatar(avatar)
    avatar = avatar or 1
    local badgeSprite = cc.Sprite:createWithSpriteFrameName(string.format("img_group_avatar_%d", avatar))
    function badgeSprite.update(avatar)
        badgeSprite:setSpriteFrame(string.format("img_group_avatar_%d", avatar))
    end
    return badgeSprite
end

function _M.createWavingBadge(badge, word)
    local FLAG_ROW = 13 -- (0 ~ 12) -> (0 * 4 * PI / 32 ~ 12 * 4 * PI /32) 
    local FLAG_COL = 2
    local FLAG_ANIMATION_COUNT = 32
    local FLAG_OFFSETX_MAX = 12
    local FLAG_OFFSETX_MIN = 4
    local FLAG_OFFSETY = 50
    local ROW_STEP = 1.0 / (FLAG_ROW - 1)
    local COL_STEP = 1.0 / (FLAG_COL - 1)
    
    if _M.WAVING_BADGE_SIN_VALUES == nil then
        _M.WAVING_BADGE_SIN_VALUES = {}
        for i = 0, FLAG_ANIMATION_COUNT * 2 do
            table.insert(_M.WAVING_BADGE_SIN_VALUES, math.sin(3.14 * i / FLAG_ANIMATION_COUNT))
        end
    end
    
    -- flag
    local flag = cc.Sprite:createWithSpriteFrameName(string.format("img_badge_%d", badge))
    local size = flag:getContentSize()
    flag:setPosition(size.width / 2, size.height / 2)
    
    -- label bg
    local labelBg = cc.Sprite:createWithSpriteFrameName("img_badge_word_bg")
    labelBg:setPosition(size.width / 2, size.height / 2 + 20)
    
    -- label
    local label = cc.Label:createWithTTF(word, _M.TTF_FONT, _M.FontSize.B1)
    label:setColor(lc.Color3B.yellow)
    lc.addChildToCenter(labelBg, label)
    
    -- render texture
    local rt = cc.RenderTexture:create(size.width, size.height)
    rt:begin()
    flag:visit()
    labelBg:visit()
    rt:endToLua()

    -- mesh sprite
    local meshFlag = cc.MeshSprite:create(FLAG_ROW, FLAG_COL, rt:getSprite():getTexture())
    for i = 0, FLAG_ROW - 1 do
        for j = 0, FLAG_COL - 1 do
            meshFlag:setTexCoord(i, j, cc.p(COL_STEP * j, ROW_STEP * (FLAG_ROW - 1 - i)))
        end
    end
    
    meshFlag.startWave = function(self)
        if self._schedulerID ~= nil then return end
        
        self._waveIndex = 0
        self._targetOffsetX = math.random(FLAG_OFFSETX_MIN, FLAG_OFFSETX_MAX)
        self:wave()
        self._schedulerID = lc.Scheduler:scheduleScriptFunc(function(dt)    
            self:wave()    
        end, 0.1, false)    
    end
    
    meshFlag.stopWave = function(self)
        if self._schedulerID ~= nil then
            lc.Scheduler:unscheduleScriptEntry(self._schedulerID)
            self._schedulerID = nil
        end
    end

    meshFlag.wave = function(self)
        self._waveIndex = (self._waveIndex + 1) % FLAG_ANIMATION_COUNT
            
        if self._waveIndex == 0 then self._targetOffsetX = math.random(FLAG_OFFSETX_MIN, FLAG_OFFSETX_MAX) end
        if self._offsetX == nil then self._offsetX = FLAG_OFFSETX_MIN end
            
        if self._offsetX - self._targetOffsetX > 0.1 then
            self._offsetX = math.max(self._targetOffsetX, self._offsetX - 0.25)
        elseif self._offsetX - self._targetOffsetX < -0.1 then
            self._offsetX = math.min(self._targetOffsetX, self._offsetX + 0.25)
        end 
                       
        local angleIndex = ((FLAG_ANIMATION_COUNT - self._waveIndex) * 2) % (FLAG_ANIMATION_COUNT * 2)
        local dx = self._offsetX * _M.WAVING_BADGE_SIN_VALUES[angleIndex + 1]

        --local color = 0xFF
        for i = 0, FLAG_ROW - 1 do
            local angleIndex = (i * 4 + ((FLAG_ANIMATION_COUNT - self._waveIndex) * 2)) % (FLAG_ANIMATION_COUNT * 2)
            for j = 0, FLAG_COL - 1 do
                --if angleIndex >= 5 and angleIndex <= 13 then
                --    color = 200 + math.abs(angleIndex - 9) * 12
                --end
                self:setVertice(i, j, cc.p(j * COL_STEP * size.width + self._offsetX * _M.WAVING_BADGE_SIN_VALUES[angleIndex + 1] - dx, (FLAG_ROW - 1 - i) * ROW_STEP * size.height + j * FLAG_OFFSETY))--, cc.c4b(color, color, color, 0xFF))
            end
        end
    end
    
    local pos = cc.p(size.width / 2 - 6, size.height / 2 + 10)
    local x1 = cc.Sprite:createWithSpriteFrameName("img_badge_x1")
    x1:setScale(1.4)
    lc.addChildToPos(meshFlag, x1, pos, -1)
    local x2 = cc.Sprite:createWithSpriteFrameName("img_badge_x2")
    x2:setScale(1.4)
    lc.addChildToPos(meshFlag, x2, pos)
    
    return meshFlag
end

function _M.createWavingFlag(badge, word)
    local FLAG_ROW = 2
    local FLAG_COL = 19
    local FLAG_ANIMATION_COUNT = 9
    local FLAG_OFFSETX = 0
    local FLAG_OFFSETY = 4
    local ROW_STEP = 1.0 / (FLAG_ROW - 1)
    local COL_STEP = 1.0 / (FLAG_COL - 1)

    if _M.WAVING_FLAG_SIN_VALUES == nil then
        _M.WAVING_FLAG_SIN_VALUES = {}
        for i = 0, FLAG_ANIMATION_COUNT * 2 - 1 do
            table.insert(_M.WAVING_FLAG_SIN_VALUES, math.sin(3.14 * i / FLAG_ANIMATION_COUNT))
        end
    end

    -- flag
    local flag = cc.Sprite:createWithSpriteFrameName(string.format("union_war_flag_%02d", badge or 0))
    local size = flag:getContentSize()
    flag:setPosition(size.width / 2, size.height / 2)

    -- label
    local label = nil
    if word ~= nil then
        label = cc.Label:createWithTTF(word, _M.TTF_FONT, _M.FontSize.S1)
        label:setColor(lc.Color3B.yellow)
        label:setPosition(lc.w(flag) / 4, lc.h(flag) / 2)
    end

    -- render texture
    local rt = cc.RenderTexture:create(size.width, size.height)
    rt:begin()
    flag:visit()
    if label ~= nil then label:visit() end
    rt:endToLua()

    -- mesh sprite
    local meshFlag = cc.MeshSprite:create(FLAG_ROW, FLAG_COL, rt:getSprite():getTexture())
    for i = 0, FLAG_ROW - 1 do
        for j = 0, FLAG_COL - 1 do
            meshFlag:setTexCoord(i, j, cc.p(COL_STEP * j, ROW_STEP * (FLAG_ROW - 1 - i)))
        end
    end

    meshFlag.startWave = function(self)
        if self._schedulerID ~= nil then return end

        self._waveIndex = math.random(0, FLAG_ANIMATION_COUNT - 1)
        self:wave()
        self._schedulerID = lc.Scheduler:scheduleScriptFunc(function(dt)    
            self:wave()
        end, 0.1, false)
    end

    meshFlag.stopWave = function(self)
        if self._schedulerID ~= nil then
            lc.Scheduler:unscheduleScriptEntry(self._schedulerID)
            self._schedulerID = nil
        end
    end

    meshFlag.wave = function(self)
        self._waveIndex = ((self._waveIndex or 0) + 1) % FLAG_ANIMATION_COUNT

        local angleIndex = ((FLAG_ANIMATION_COUNT - self._waveIndex) * 2) % (FLAG_ANIMATION_COUNT * 2)
        local dy = FLAG_OFFSETY * _M.WAVING_FLAG_SIN_VALUES[angleIndex + 1]

        --local factor = 255
        for i = 0, FLAG_ROW - 1 do
            for j = 0, FLAG_COL - 1 do
                local angleIndex = (j + ((FLAG_ANIMATION_COUNT - self._waveIndex) * 2)) % (FLAG_ANIMATION_COUNT * 2)
                self:setVertice(i, j, cc.p(j * COL_STEP * size.width + j * FLAG_OFFSETX, (FLAG_ROW - 1 - i) * ROW_STEP * size.height + FLAG_OFFSETY * _M.WAVING_FLAG_SIN_VALUES[angleIndex + 1] - dy))
                --if angleIndex >= 5 and angleIndex <= 13 then
                --    factor = 200 + math.abs(angleIndex - 9) * 12
                --end
                --flag:setColor(i, j, cc.c4b(factor, factor, factor, factor));
            end
        end    
    end

    return meshFlag
end

function _M.addTapHandler(item, handler)
    item:setTouchEnabled(true)
    item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    item:addTouchEventListener(function(sender, evt)
        if evt == ccui.TouchEventType.ended then
            handler()
        end
    end)
end

function _M.addSkillTapHandler(item, skillId, skillLevel)
    _M.addTapHandler(item, function() require("SkillForm").create(skillId, skillLevel):show() end)
end

function _M.createClipNode(node, rect, isInverted)
    local clipping = cc.ClippingNode:create()
    clipping:setContentSize(node and node:getContentSize() or cc.size(rect.width, rect.height))
    if isInverted then clipping:setInverted(isInverted) end

    local stencil = cc.LayerColor:create(lc.Color4B.white, rect.width, rect.height)
    stencil:setPosition(rect.x, rect.y)   
    clipping:setStencil(stencil)

    if node then clipping:addChild(node) end
    return clipping
end

function _M.getPropExtra(infoId, parent, isSelf)
    local baseId, id = P._propBag:validPropId(infoId, isSelf)

    local extraIcon
    if baseId == Data.PropsId.avatar_frame_level_rank then
        local rank = id - baseId
        if rank > 0 then
            extraIcon = lc.createSprite(string.format("avatar_frame_7502_%d", rank))
            extraIcon:setPosition(lc.w(parent) / 2 or 0, 46)
        end

    elseif baseId == Data.PropsId.avatar_frame_xmas_1 then
        extraIcon = lc.createNode(parent:getContentSize())
        extraIcon:setPosition(lc.w(parent) / 2, lc.h(parent) / 2)

        if id == Data.PropsId.avatar_frame_xmas_2 then
            local bell = lc.createSprite("avatar_frame_7507_1")
            bell:setAnchorPoint(0.52, 0.77)
            bell:setRotation(-10)
            bell:runAction(lc.rep(lc.sequence(lc.rotateTo(1, 10), lc.rotateTo(1, -10))))
            lc.addChildToPos(extraIcon, bell, cc.p(lc.w(parent) / 2, 12))

            local light = lc.createSprite("avatar_frame_7507_2")            
            light:setColor(lc.Color3B.orange)
            extraIcon:addChild(light)
            light:runAction(lc.rep(lc.sequence(function()
                light:setPosition(12, 15)
            end, 1, function()
                light:setPosition(22, 7)
                light:setColor(lc.Color3B.yellow)
            end, 1, function()
                light:setPosition(84, 7)                
            end, 1, function()
                light:setPosition(94, 15)
                light:setColor(lc.Color3B.orange)
            end, 1)))
        end
    end

    return baseId, extraIcon
end

function _M.getAvatarVipOffset(infoId)
    local baseId = P._propBag:validPropId(infoId)
    if baseId == Data.PropsId.avatar_frame then
        return 0, 0
    end

    return 0, 0
end

function _M.containPos(node, globalPos)
    if node:getCameraMask() == ClientData.CAMERA_3D_FLAG then
        return lc.contain3D(node, globalPos, ClientData._camera3D)
    else
        if node.containPos then
            return node:containPos(globalPos)
        else
            return lc.contain(node, globalPos)
        end
    end
end

function _M.debugNode(node)
    local drawNode = cc.DrawNode:create()
    drawNode:setContentSize(node:getContentSize())
    drawNode:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(node, drawNode)
    drawNode:drawRect(cc.p(0, 0), cc.p(lc.w(drawNode), lc.h(drawNode)), cc.c4f(1, 1, 1, 1))
end

function _M.showResExchangeForm(resType)
    local types = {Data.ResType.gold, Data.ResType.grain, Data.ResType.ingot, Data.PropsId.dust_monster, Data.PropsId.dust_magic, Data.PropsId.dust_rare}
    for i = 1, #types do
        local t = types[i]
        local form = V._resExchangeForms[t]
        if form then
            if resType == t then
                return
            else
                form:hide()
                break
            end
        end
    end

    if resType == Data.ResType.ingot then
        if not ClientData.isHideCharge() then
            if ClientData.isAppStoreReviewing() then
                require("VIPForm").create(true):show()
            else
                lc.pushScene(require("RechargeScene").create())
            end
        end
    else
        require("ExchangeResForm").create(resType):show()
    end
end

function _M.createCardPackage(info, callback)
    local layout = cc.Node:create()

    -- frame
    local frameStr = string.format("res/jpg/lottery_%d.png", info._value)
    if info._value < 10201 or not lc.File:isFileExist(frameStr) then frameStr = "res/jpg/lottery_101001.png" end
    local frame = cc.ShaderSprite:createWithFilename(frameStr)

    -- head
    local headStr = string.format('res/jpg/tavern_item_head_%.2d.jpg', info._type == 1001 and 0 or 1)
    if Data.getIsGodPumpRecruite(info) then headStr = 'res/jpg/rare_shop_head.jpg' end
    lc.TextureCache:addImageWithMask(headStr)
    local head = cc.ShaderSprite:createWithFilename(headStr)

    -- foot
    local footStr = string.format('res/jpg/tavern_item_foot_%.2d.jpg', info._type == 1001 and 0 or 1)
    if Data.getIsGodPumpRecruite(info) then footStr = 'res/jpg/rare_shop_foot.jpg' end
    lc.TextureCache:addImageWithMask(footStr)
    local foot = cc.ShaderSprite:createWithFilename(footStr)

    -- layout
    layout:setContentSize(cc.size(lc.w(frame), lc.h(frame)))
    layout:setAnchorPoint(cc.p(0.5, 0.5))

    --lc.addChildToPos(layout, foot, cc.p(lc.cw(layout), lc.ch(foot)))
    --lc.addChildToPos(layout, head, cc.p(lc.cw(layout), lc.h(layout) - lc.ch(head)))
    lc.addChildToPos(layout, frame, cc.p(lc.cw(layout), lc.ch(frame)))

    -- particle
    if info._type == 1001 then
        local par = Particle.create("leiya")
        lc.addChildToCenter(frame, par)
        par:setPositionType(cc.POSITION_TYPE_GROUPED) 
        layout._particle = par
    end
    
    -- function
    layout.setGray = function (self)
        frame:setEffect(V.SHADER_DISABLE)

        if self._particle then
            self._particle:setVisible(false)
        end
    end

    return layout
end

function _M.startIAP(type)
    local appId = ClientData.getAppId() 
    if appId == '1223968820' or appId == '1224018227' then
        require("Dialog").showDialog(Str(STR.IAP_TIP_1, true), function() 
            lc.App:openUrl("http://jdzc_update.smbbgo.com")
        end)
        return
    end

    local subChannelName = ClientData.getSubChannelName()
    if subChannelName == 'huyacomp' then return end     
    if subChannelName ~= "uc" and subChannelName ~= "jinli" and subChannelName ~= "mhr" and subChannelName ~= "pptv" and subChannelName ~= "ewan" then
        V.getActiveIndicator():show(Str(STR.WAITING), nil, nil, 0)
    end
    ClientData.sendIAPStartReq(type)
end

function _M.iapPaySuccess()
    --[[
    if lc.App:getChannelName() == 'PP' or (lc.App:getChannelName() == 'ASDK' and lc.PLATFORM ~= cc.PLATFORM_OS_IPHONE and lc.PLATFORM ~= cc.PLATFORM_OS_IPAD) then
        V.getActiveIndicator():hide()
    end
    ]]
end

function _M.iapFinish()
    V.getActiveIndicator():hide()
end

function _M.createUnionCardPackage(info, callback)
    local layout = cc.Node:create()

    -- frame
    local frameStr = string.format("res/jpg/union_shop_%d.png", info._type)
    local frame = cc.ShaderSprite:createWithFilename(frameStr)

    -- head
    local headStr = string.format('res/jpg/union_shop_head.jpg')
    lc.TextureCache:addImageWithMask(headStr)
    local head = cc.ShaderSprite:createWithFilename(headStr)

    -- foot
    local footStr = string.format('res/jpg/union_shop_foot.jpg')
    lc.TextureCache:addImageWithMask(footStr)
    local foot = cc.ShaderSprite:createWithFilename(footStr)

    -- layout
    layout:setContentSize(cc.size(lc.w(frame), lc.h(frame)))
    layout:setAnchorPoint(cc.p(0.5, 0.5))

    --lc.addChildToPos(layout, foot, cc.p(lc.cw(layout), lc.ch(foot)))
    --lc.addChildToPos(layout, head, cc.p(lc.cw(layout), lc.h(layout) - lc.ch(head)))
    lc.addChildToPos(layout, frame, cc.p(lc.cw(layout), lc.ch(frame)))

--    -- particle
--    if info._type == 1001 then
--        local par = Particle.create("leiya")
--        lc.addChildToCenter(frame, par)
--        par:setPositionType(cc.POSITION_TYPE_GROUPED) 
--        layout._particle = par
--    end
    
    -- function
    layout.setGray = function (self)
        frame:setEffect(V.SHADER_DISABLE)

        if self._particle then
            self._particle:setVisible(false)
        end
    end

    return layout
end

function _M.createRareCardPackage(info, callback)
    local layout = cc.Node:create()

    -- frame
    local frameStr = info._type == 0 and "res/jpg/rare_shop_0.png" or string.format("res/jpg/lottery_%d.png", info._type.."01")
    local frame = cc.ShaderSprite:createWithFilename(frameStr)

    -- head
    local headStr = "res/jpg/rare_shop_head.jpg"
    lc.TextureCache:addImageWithMask(headStr)
    local head = cc.ShaderSprite:createWithFilename(headStr)

    -- foot
    local footStr = "res/jpg/rare_shop_foot.jpg"
    lc.TextureCache:addImageWithMask(footStr)
    local foot = cc.ShaderSprite:createWithFilename(footStr)

    -- layout
    layout:setContentSize(cc.size(lc.w(frame), lc.h(frame)))
    layout:setAnchorPoint(cc.p(0.5, 0.5))

    --lc.addChildToPos(layout, foot, cc.p(lc.cw(layout), lc.ch(foot)))
    --lc.addChildToPos(layout, head, cc.p(lc.cw(layout), lc.h(layout) - lc.ch(head)))
    lc.addChildToPos(layout, frame, cc.p(lc.cw(layout), lc.ch(frame)))

    -- particle
    local par = Particle.create("leiya")
    lc.addChildToCenter(frame, par)
    par:setPositionType(cc.POSITION_TYPE_GROUPED) 
    layout._particle = par
    
    -- function
    layout.setGray = function (self)
        frame:setEffect(V.SHADER_DISABLE)

        if self._particle then
            self._particle:setVisible(false)
        end
    end

    return layout
end

function _M.createDiamondCardPackage(info, callback)
    local layout = cc.Node:create()

    -- frame
    local frameStr = info._type == 0 and "res/jpg/diamond_shop_0.png" or string.format("res/jpg/lottery_%d.png", info._type.."01")
    local frame = cc.ShaderSprite:createWithFilename(frameStr)

    -- head
    local headStr = "res/jpg/diamond_shop_head.jpg"
    lc.TextureCache:addImageWithMask(headStr)
    local head = cc.ShaderSprite:createWithFilename(headStr)

    -- foot
    local footStr = "res/jpg/diamond_shop_foot.jpg"
    lc.TextureCache:addImageWithMask(footStr)
    local foot = cc.ShaderSprite:createWithFilename(footStr)

    -- layout
    layout:setContentSize(cc.size(lc.w(frame), lc.h(frame)))
    layout:setAnchorPoint(cc.p(0.5, 0.5))

    --lc.addChildToPos(layout, foot, cc.p(lc.cw(layout), lc.ch(foot)))
    --lc.addChildToPos(layout, head, cc.p(lc.cw(layout), lc.h(layout) - lc.ch(head)))
    lc.addChildToPos(layout, frame, cc.p(lc.cw(layout), lc.h(foot) + lc.ch(frame)))

    -- particle
    local par = Particle.create("leiya")
    lc.addChildToCenter(frame, par)
    par:setPositionType(cc.POSITION_TYPE_GROUPED) 
    layout._particle = par
    
    -- function
    layout.setGray = function (self)
        frame:setEffect(V.SHADER_DISABLE)

        if self._particle then
            self._particle:setVisible(false)
        end
    end

    return layout
end

function _M.setMaxSize(target, width, height)
    if target.setScale==nil then return end
    local scale
    if width==nil and height~=nil then
        scale=height/lc.h(target)
    elseif width~=nil and height==nil then
        scale=width/lc.w(target)
    elseif width~=nil and height~=nil then
        scale=math.min(height/lc.h(target), width/lc.w(target))
    end
    if scale~=nil and scale<1 then
        target:setScale(scale)
    end
end

function _M.createCharacterHeadById(id)
    if id ~= -1 then
        return cc.ShaderSprite:createWithFramename(string.format("head_%02d", id))
    end
    return cc.ShaderSprite:createWithFramename("head_unknow")
end

function _M.addPriceToBtn(btn, price, resType, width, height)
    local iconName
    local resIcon = btn._resIcon
    local type = Data.getType(resType)
    if type == Data.CardType.props then
        iconName = ClientData.getPropIconName(resType)
    elseif type == Data.CardType.res then
        iconName = "img_icon_res"..resType.."_s"
    else
        if resIcon then
            resIcon:removeFromParent()
            btn._resIcon = nil
        end
        return
    end

    if resIcon == nil then
        resIcon = lc.createSprite(iconName)
        resIcon:setAnchorPoint(cc.p(0,0.5))
        _M.setMaxSize(resIcon, width, height)
        lc.addChildToPos(btn, resIcon, cc.p(lc.cw(btn)- width/2 - 2, lc.ch(btn)))
        btn._resIcon = resIcon
    else
        resIcon:setSpriteFrame(iconName)
    end

    local priceStr = ClientData.formatNum(price, 99999)
    local label = btn._resNumLabel
    local labelWidth = lc.cw(btn)+width/2-lc.right(resIcon)
    if label==nil then
        label = _M.createBMFont(_M.BMFont.huali_20, priceStr)
        label:setAnchorPoint(cc.p(0.5, 0.5))
        _M.setMaxSize(label, labelWidth)
        lc.addChildToPos(btn, label, cc.p(lc.right(resIcon)+labelWidth/2 + 4, lc.ch(btn)))
        btn._resNumLabel = label
        label:setColor(price>P:getItemCount(resType) and V.COLOR_TEXT_RED or V.COLOR_TEXT_WHITE)
    else
        label:setString(priceStr)
        label:setColor(price>P:getItemCount(resType) and V.COLOR_TEXT_RED or V.COLOR_TEXT_WHITE)
    end
end

function _M.createPageArrow(isLeft, pos, callback)
    local pageArrow = V.createShaderButton('img_page_right', callback)
    pageArrow:setAnchorPoint(0, 0.5)
    pageArrow:setFlippedX(isLeft)
    pageArrow:setTouchRect(cc.rect(-20, -20, lc.w(pageArrow) + 40, lc.h(pageArrow) + 40))
    pageArrow._pos = pos
    pageArrow.float = function(self)
        self:stopAllActions()
        self:setPosition(self._pos)
        self:runAction(lc.rep(lc.sequence({lc.moveTo(0.8, cc.p(self._pos.x + (isLeft and -8 or 8), self._pos.y)), lc.moveTo(0.8, self._pos)}))) 
    end
    return pageArrow
end

function _M.createSkinFrame(skinId, infoId, hideName)
    local skinInfo = Data._skinInfo[skinId]
    infoId = infoId or skinInfo._infoId
    local monsterInfo = Data.getInfo(infoId)

    local frame = lc.createSpriteWithMask('res/jpg/skin_frame.jpg')

    if not hideName then
        local nameBg = lc.createSprite({_name = 'img_com_bg_27', _crect = V.CRECT_COM_BG27, _size = cc.size(lc.w(frame) - 20, 50)})
        nameBg:setOpacity(160)
        lc.addChildToPos(frame, nameBg, cc.p(lc.cw(frame), lc.ch(nameBg) + 8), 1)

        local nameLabel = V.createTTF(Str(skinInfo._nameSid), V.FontSize.S1)
        nameLabel:setScale(0.8)
        lc.addChildToPos(frame, nameLabel, cc.p(lc.cw(frame), 44), 1)
        frame._nameLabel = nameLabel
    
        local monsterNameLabel = V.createTTF(Str(monsterInfo._nameSid), V.FontSize.S1)
        monsterNameLabel:setScale(0.8)
        monsterNameLabel:setColor(V.COLOR_LABEL_LIGHT)
        lc.addChildToPos(frame, monsterNameLabel, cc.p(lc.cw(frame), 22), 1)
        frame._monsterNameLabel = monsterNameLabel
    end

    frame.updateSkin = function(frame, skinId, infoId)
        local skinInfo = Data._skinInfo[skinId]
        infoId = infoId or skinInfo._infoId
        local monsterInfo = Data.getInfo(infoId)    

        if frame._bones ~= nil then 
            frame._bones:removeFromParent()
            frame._bones = nil
        end

        if skinInfo == nil or skinInfo._effect == 0 then
            if frame._image == nil then
                local image = cc.ShaderSprite:createWithFilename(V.getCardImageName(infoId, skinId))
                lc.addChildToCenter(frame, image)
                frame._image = image
            else
                frame._image:setTexture(lc.TextureCache:addImage(V.getCardImageName(infoId, skinId)))
            end
        else
            local bones = DragonBones.create(skinInfo._effect)
            bones:gotoAndPlay('effect')
            lc.addChildToCenter(frame, bones)
            frame._bones = bones
            if frame._image ~= nil then
                frame._image:removeFromParent()
                frame._image = nil
            end
        end
    end

    frame:updateSkin(skinId, infoId)
    
    return frame
end

function _M.setOrCreateFundTaskCell(layout, bonus, idx, showBtn)

    if not layout then
        layout = lc.createNode()--V.createShaderButton(nil, nil)

        local bg = lc.createSprite({_name = "img_troop_bg_6", _size = cc.size(520, 74), _crect = cc.rect(20, 24, 2, 2)})
        local cellSize = bg:getContentSize()
        layout:setContentSize(cellSize)
        lc.addChildToCenter(layout, bg)

        --[[
        local titleLabel = V.createTTF("", V.FontSize.S2, V.COLOR_TEXT_WHITE)
        lc.addChildToPos(layout, titleLabel, cc.p(cellSize.width / 4, cellSize.height / 2))
        layout._titleLabel = titleLabel
        ]]

        local dailyTaskPanel = lc.createSprite("img_dailyTask_panel")
        lc.addChildToPos(layout, dailyTaskPanel, cc.p(lc.cw(dailyTaskPanel) - 20, lc.ch(layout)))
        -- fix later
        local dailyTaskIcon = lc.createSprite("img_dailyTask_icon_"..math.random(1, 3))
        lc.addChildToCenter(dailyTaskPanel, dailyTaskIcon)
        
        local replaceBtn = V.createShaderButton('img_icon_close_2', function()
            P._playerBonus:sendResetFundTask(layout._bonus._info._cid)
        end)
        lc.addChildToPos(layout, replaceBtn, cc.p(cellSize.width + lc.cw(replaceBtn) - 2, cellSize.height - lc.ch(replaceBtn)), -1)
        
        local contentLabel = V.createTTF("", V.FontSize.S3, V.COLOR_TEXT_WHITE, cc.size(cellSize.width - 30, 60), cc.TEXT_ALIGNMENT_CENTER, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        --contentLabel:setAnchorPoint(0.5, 1)
        lc.addChildToPos(layout, contentLabel, cc.p(cellSize.width / 4 + 20, lc.ch(layout)))
        layout._contentLabel = contentLabel

        local claimBtn = V.createScale9ShaderButton("img_btn_1_s", nil, V.CRECT_BUTTON_S, 110, 45)
        lc.addChildToPos(layout, claimBtn, cc.p(lc.w(layout) - 16 - lc.cw(claimBtn), lc.ch(layout) - 1))
        claimBtn:addLabel(Str(STR.CLAIM))
        layout._claimBtn = claimBtn

        local bar = V.createScale9ShaderButton('img_btn_1_s', nil, V.CRECT_BUTTON_S, 110, 45)
        lc.addChildToPos(layout, bar, cc.p(lc.w(layout) - 16 - lc.cw(bar), lc.ch(layout) - 1))
        bar:setEnabled(false)
        bar:setZoomScale(0)
        bar:setPressedShader(nil)

        local barLabel = V.createBMFont(V.BMFont.huali_20, "")
        lc.addChildToCenter(bar, barLabel)

        local backLabel = V.createTTF(Str(STR.WAIT_FOR_TASK), V.FontSize.S3)
        lc.addChildToCenter(layout, backLabel)

        local rewardNode = lc.createNode()
        rewardNode:setScale(0.8)
        lc.addChildToPos(layout, rewardNode, cc.p(cellSize.width / 2 + 40, lc.ch(layout)))

        layout.hide = function()
            dailyTaskPanel:setVisible(false)
            bg:setEffect(V.SHADER_DISABLE)
            dailyTaskIcon:setVisible(false)
            --titleLabel:setVisible(false)
            replaceBtn:setVisible(false)
            --divide:setVisible(false)
            contentLabel:setVisible(false)
            claimBtn:setVisible(false)
            bar:setVisible(false)
            rewardNode:setVisible(false)
            backLabel:setVisible(true)
        end

        layout.show = function()
            dailyTaskPanel:setVisible(true)
            bg:setEffect(nil)
            dailyTaskIcon:setVisible(true)
            --titleLabel:setVisible(true)
            replaceBtn:setVisible(true)
            --divide:setVisible(true)
            contentLabel:setVisible(true)
            claimBtn:setVisible(true)
            bar:setVisible(true)
            rewardNode:setVisible(true)
            backLabel:setVisible(false)
            dailyTaskPanel:setVisible(true)
        end

        layout.update = function(bonus)
            rewardNode:removeAllChildren()

            if not bonus then
                layout.hide()
                return
            else
                layout.show()
            end

            layout._bonus = bonus

            if showBtn then
                if bonus:canClaim() then
                    claimBtn:setVisible(true)
                    bar:setVisible(false)
                else
                    claimBtn:setVisible(false)
                    bar:setVisible(true)
                end
                if P._playerBonus._fundResetCount > 0 and not bonus:canClaim() then
                    --replaceBtn:setVisible(true)
                else
                    --replaceBtn:setVisible(false)
                end
            else
                --replaceBtn:setVisible(false)
                claimBtn:setVisible(false)
                bar:setVisible(true)
            end

            local titleStr = ""
            if idx then
                titleStr = string.format(Str(STR.TASK_NO), idx)
            else
                titleStr = Str(STR.FUND_TASK)
            end
            --titleLabel:setString(titleStr)

            local bonusInfo = bonus._info
            local items = {}
            if bonusInfo then
                local contentStr = string.format(ClientData.str(bonusInfo._nameSid, true), bonusInfo._val)
                contentLabel:setString(contentStr)
                local ids = bonusInfo._rid
                local levels = bonusInfo._level
                local counts = bonusInfo._count
                local isFragments = bonusInfo._isFragment

                for i, id in ipairs(ids) do
                    local item = IconWidget.create({_infoId = id, _level = levels[i], _isFragment = isFragments[i] > 0, _count = counts[i]}, IconWidget.DisplayFlag.COUNT)
                    --local item = lc.createSprite("img_icon_res1_s")
                    item:setScale(0.75)
                    item._name:setColor(lc.Color3B.black)
                    item:setSwallowTouches(not showBtn)
                    table.insert(items, item)
                end

                --bar._bar:setPercent(100 * bonus._value / bonusInfo._val)
                if bonus._value >= bonusInfo._val then
                    barLabel:setString(Str(STR.CLAIM))
                else
                    barLabel:setString(bonus._value.."/"..bonusInfo._val)
                end
            end
            if #items > 0 then lc.addNodesToCenterH(rewardNode, items, 10) end
        end

        layout.runActionHideToShow = function()
            layout:runAction(lc.sequence(function() bar:setEnabled(false) backLabel:setVisible(false) end, lc.rotateTo(0.2, {x = 90, y = 0, z = 0}), lc.call(function() layout.update(layout._bonus) end), lc.rotateTo(0.2, {x = 0, y = 0, z = 0}), function() bar:setEnabled(true) end))
            return 0.4
        end

        layout.runActionShowToHide = function()
            layout:runAction(lc.sequence(function() bar:setEnabled(false) end, lc.rotateTo(0.2, {x = 90, y = 0, z = 0}), lc.call(function() layout.hide() end), lc.rotateTo(0.2, {x = 0, y = 0, z = 0}), function() bar:setEnabled(true) end))
            return 0.4
        end

        layout.runActionUpdateBonus = function(bo)
            local delay = 0
            if layout._bonus == nil and bo ~= nil then
                layout._bonus = bo
                delay = delay + layout.runActionHideToShow()
            elseif layout._bonus ~= nil and bo ~= nil then
                layout._bonus = bo
                --delay = delay + layout.runActionHideToShow()
                layout:runAction(lc.sequence(0.4, lc.call(function() layout.update(layout._bonus) end)))
                --layout.update(layout._bonus)
            elseif layout._bonus ~= nil and bo == nil then
                layout._bonus = bo
                delay = delay + layout.runActionShowToHide()
            end
            return delay
        end
    end
    layout.update(bonus)
    return layout
end

function _M.tryGotoFindClash(isPush)
    if P._playerWorld._curLevel[1] > 10104 then
        local scene = require("FindScene").create(Data.FindMatchType.clash)
        if isPush then lc.pushScene(scene)
        else lc.replaceScene(scene)
        end
        return true
    else
        ToastManager.push(string.format(Str(STR.FINDSCENE_LOCKED), Str(Data._chapterInfo[1]._nameSid)))
        return false
    end
end

function _M.tryGotoFindLadder(isPush)
    if P:getMaxCharacterLevel() >= Data._globalInfo._unlockLadder then
        local scene = require("FindScene").create(Data.FindMatchType.ladder)
        if isPush then lc.pushScene(scene)
        else lc.replaceScene(scene)
        end
        return true
    else
        local panel = require("BasePanel").new(lc.EXTEND_LAYOUT_MASK)
        panel:init(false, true)
        function panel:onCleanup()
            lc.TextureCache:removeTextureForKey("res/jpg/ad_20.jpg")
        end
        local ad = lc.createSpriteWithMask("res/jpg/ad_20.jpg")
        lc.addChildToCenter(panel, ad)
        panel:show()
        return false
    end
end
function _M.tryGotoUnionBattle(isPush)
    if P:getMaxCharacterLevel() < Data._globalInfo._unlock2v2 then
        local panel = require("BasePanel").new(lc.EXTEND_LAYOUT_MASK)
        panel:init(false, true)
        function panel:onCleanup()
            lc.TextureCache:removeTextureForKey("res/jpg/ad_18.jpg")
        end
        local ad = lc.createSpriteWithMask("res/jpg/ad_18.jpg")
        lc.addChildToCenter(panel, ad)
        panel:show()
        return false
    end
    local scene = require("FindScene").create(Data.FindMatchType.union_battle)
    if isPush then lc.pushScene(scene)
    else lc.replaceScene(scene)
    end
    return true
end
function _M.tryGotoExpedition(isPush)
    if P:getMaxCharacterLevel() >= Data._globalInfo._unlockExpedition then   
        local scene = require("ExpeditionScene").create(Data.FindMatchType.ladder)
        if isPush then lc.pushScene(scene)
        else lc.replaceScene(scene)
        end
        return true
    else
        local panel = require("BasePanel").new(lc.EXTEND_LAYOUT_MASK)
        panel:init(false, true)
        function panel:onCleanup()
            lc.TextureCache:removeTextureForKey("res/jpg/ad_25.jpg")
        end
        local ad = lc.createSpriteWithMask("res/jpg/ad_25.jpg")
        lc.addChildToCenter(panel, ad)
        panel:show()
        return false
    end
end

function _M.isPackageShowInRareShop(value)
    local productInfos = Data._rareProductsInfo
    for _, info in ipairs(productInfos) do
        if info._type == math.floor(value / 100) then
            return true
        end
    end
    return false
end

function _M.getProbabilityColor(probability)
    if probability < 1 then
        return cc.c3b(1, 92, 253)
    end
    if probability < 10 then
        return cc.c3b(0, 255, 66)
    end
    if probability < 25 then
        return cc.c3b(255, 233, 1)
    end
    if probability < 50 then
        return cc.c3b(203, 0, 253)
    end
    return cc.c3b(255, 56, 68)
end

function _M.createSpine(name, scale)
    local spine = sp.SkeletonAnimation:createWithBinaryFile('res/spine/'..name..'/'..name..'.skel', 'res/spine/'..name..'/'..name..'.atlas')
    spine:setScale(scale or 1.0)

    spine.setAutoRemoveAnimation = function(self, str, func)
         self:setAnimation(0, str, false)
         self:registerSpineEventHandler(function (event) 
                self:runAction(lc.sequence(0, function () 
                    self:removeFromParent() 
                    if func then func() end 
                end ))
            end, sp.EventType.SP_ANIMATION_COMPLETE)
    end

    return spine
end


ClientView = _M
V = ClientView
