local _M = class("Particle", function() return cc.ParticleSystemQuad:create() end)
Particle = _M

function _M.create(str)
    local spr = _M.new()
    spr:init(str)
    
    spr:registerScriptHandler(function(evtName)
        if evtName == "cleanup" then
            spr:onCleanup()
        end
    end)
    
    return spr
end

function _M:onCleanup()
    if self._data == nil then
        return
    end
    
    local str = self._data.textureFileName
    
    if ClientData._particleTexture[str] ~= nil then
        ClientData._particleTexture[str] = ClientData._particleTexture[str] - 1
    end
    
    if ClientData._particleTexture[str] == 0 then
        local fname = "res/particle/"..self._data.textureFileName..".png"
        if lc.TextureCache:getTextureForKey(fname) ~= nil then
            lc.TextureCache:removeTextureForKey(fname)
            -- lc.log("unload paritcle  "..fname)
        end
    end
end

function _M:init(str)
    local data = nil
    for i, particleData in pairs(Data._particleInfo) do
        if str == particleData.name then
            data = particleData
            break
        end
    end
    
    if data == nil then
        print("@@@@@@@ unable to find particle data", str)

    else
        self._data = data
        self:initEmitter(data)
        
        ClientData._particleTexture = ClientData._particleTexture or {}

        local str = data.textureFileName
        ClientData._particleTexture[str] = (ClientData._particleTexture[str] or 0) + 1
    end
end

function _M:initEmitter(data)
    -- total particles
    self:setTotalParticles(data.maxParticles)
    
    if data.duration > 0 then
        self:setAutoRemoveOnFinish(true)
    else
        self:setAutoRemoveOnFinish(false)
    end
    
    self:setAngle(data.angle)
    self:setAngleVar(data.angleVariance)
    
    self:setDuration(data.duration)
    
    local str = "res/particle/"..data.textureFileName..".png"
    local texture = lc.TextureCache:getTextureForKey(str) or lc.TextureCache:addImage(str)
    self:setTexture(texture)
    self:setBlendFunc(data.blendFuncSource, data.blendFuncDestination)
    
    self:setStartColor(cc.c4f(data.startColorRed, data.startColorGreen, data.startColorBlue, data.startColorAlpha))
    self:setStartColorVar(cc.c4f(data.startColorVarianceRed, data.startColorVarianceGreen, data.startColorVarianceBlue, data.startColorVarianceAlpha))
    self:setEndColor(cc.c4f(data.finishColorRed, data.finishColorGreen, data.finishColorBlue, data.finishColorAlpha))
    self:setEndColorVar(cc.c4f(data.finishColorVarianceRed, data.finishColorVarianceGreen, data.finishColorVarianceBlue, data.finishColorVarianceAlpha))
    
    self:setStartSize(data.startParticleSize)
    self:setStartSizeVar(data.startParticleSizeVariance)
    self:setEndSize(data.finishParticleSize)
    self:setEndSizeVar(data.finishParticleSizeVariance)
    
    self:setPosition(cc.p(data.sourcePositionx, data.sourcePositiony))
    self:setPosVar(cc.p(data.sourcePositionVariancex, data.sourcePositionVariancey))
    
    self:setStartSpin(data.rotationStart)
    self:setStartSpinVar(data.rotationStartVariance)
    self:setEndSpin(data.rotationEnd)
    self:setEndSpinVar(data.rotationEndVariance)
    
    self:setEmitterMode(data.emitterType)

    -- Mode A: Gravity + tangential accel + radial accel
    if data.emitterType == 0 then
        -- gravity
        self:setGravity({x = data.gravityx, y = data.gravityy})
        
        -- speed
        self:setSpeed(data.speed)
        self:setSpeedVar(data.speedVariance)
        
        -- radial acceleration
        self:setRadialAccel(data.radialAcceleration)
        self:setRadialAccelVar(data.radialAccelVariance)
        self:setTangentialAccel(data.tangentialAcceleration)
        self:setTangentialAccelVar(data.tangentialAccelVariance)
        
        -- rotation is dir
        self:setRotationIsDir(false)

    -- Mode B: radius movement
    elseif data.emitterType == 1 then
        self:setStartRadius(data.maxRadius)
        self:setStartRadiusVar(data.maxRadiusVariance)
        
        self:setEndRadius(data.minRadius)
        self:setEndRadiusVar(data.minRadiusVariance)
        
        self:setRotatePerSecond(data.rotatePerSecond)
        self:setRotatePerSecondVar(data.rotatePerSecondVariance)

    end
    
    self:setLife(data.particleLifespan)
    self:setLifeVar(data.particleLifespanVariance)
    
    self:setEmissionRate(data.maxParticles / (data.particleLifespan <= 0 and 0.001 or data.particleLifespan))
end

return _M