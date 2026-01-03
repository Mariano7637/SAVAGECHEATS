--[[
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                    SAVAGECHEATS_ AIMBOT v9.0                          ║
    ║                   ULTIMATE EDITION - MOBILE OPTIMIZED                 ║
    ╠═══════════════════════════════════════════════════════════════════════╣
    ║  • Munição Infinita CORRIGIDA (múltiplos métodos)                     ║
    ║  • Rapid Fire EXTREMO (bypass de cooldown)                            ║
    ║  • Range Infinito (sem limite de distância)                           ║
    ║  • WALLBANG - Tiro através de paredes (Hitbox Teleport)               ║
    ║  • Silent Aim avançado com __namecall hook                            ║
    ║  • Otimizado para Mobile (baixo consumo)                              ║
    ║  • Compatível com: Fluxus, Arceus X, Delta, Codex                     ║
    ╚═══════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
--                          SERVIÇOS
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ═══════════════════════════════════════════════════════════════
--                      VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════════

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Detectar jogo
local GameId = game.PlaceId
local IsPrisonLife = GameId == 155615604 or GameId == 419601093
local GameName = IsPrisonLife and "Prison Life" or "Universal"

-- Limpar instância anterior
if _G.SAVAGE_V90 then
    pcall(function() _G.SAVAGE_V90_CLEANUP() end)
    task.wait(0.3)
end

-- ═══════════════════════════════════════════════════════════════
--                       CONFIGURAÇÕES
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Aimbot
    AimbotEnabled = false,
    SilentAim = false,
    IgnoreWalls = false,
    SkipDowned = true,
    AimPart = "Head",
    
    -- Team Filter
    TeamFilter = "Todos",
    
    -- FOV
    FOVRadius = 150,
    FOVVisible = true,
    
    -- Smoothing
    Smoothness = 0.3,
    
    -- ESP
    ESPEnabled = false,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPDistance = true,
    
    -- NoClip
    NoClipEnabled = false,
    
    -- Hitbox
    HitboxEnabled = false,
    HitboxSize = 5,
    
    -- Speed
    SpeedEnabled = false,
    SpeedMultiplier = 0.2,
    
    -- ═══════════════════════════════════════════════════════════
    --              NOVAS CONFIGURAÇÕES v9.0
    -- ═══════════════════════════════════════════════════════════
    
    -- Rapid Fire EXTREMO
    RapidFireEnabled = false,
    RapidFireMode = "Extreme", -- Normal, Fast, Extreme, Insane
    RapidFireDelay = 0.001, -- Delay entre tiros (quanto menor, mais rápido)
    
    -- Munição Infinita (CORRIGIDA)
    InfiniteAmmoEnabled = false,
    AmmoMethod = "Auto", -- Auto, Module, Hook, Spoof
    
    -- Range Infinito
    InfiniteRangeEnabled = false,
    CustomRange = 99999,
    
    -- WALLBANG (Tiro através de paredes)
    WallbangEnabled = false,
    WallbangMode = "HitboxTeleport", -- HitboxTeleport, RayBypass, BulletTP
    WallbangRange = 500,
    
    -- Misc
    ShowLine = false,
    MaxDistance = 1000,
    
    -- Mobile Optimization
    LowPowerMode = false,
    UpdateRate = 1, -- 1 = cada frame, 2 = a cada 2 frames, etc.
}

local State = {
    Target = nil,
    TargetPart = nil,
    Locked = false,
    FrameCount = 0,
    LastFireTime = 0,
    CurrentGun = nil,
    OriginalHitboxes = {},
}

local Connections = {}
local ESPObjects = {}
local HookedRemotes = {}

-- ═══════════════════════════════════════════════════════════════
--                         CORES DO TEMA
-- ═══════════════════════════════════════════════════════════════

local Theme = {
    Primary = Color3.fromRGB(200, 30, 30),
    Secondary = Color3.fromRGB(25, 25, 25),
    Background = Color3.fromRGB(15, 15, 15),
    Surface = Color3.fromRGB(35, 35, 35),
    SurfaceLight = Color3.fromRGB(45, 45, 45),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(50, 200, 50),
    Warning = Color3.fromRGB(255, 180, 0),
    Border = Color3.fromRGB(60, 60, 60),
    Accent = Color3.fromRGB(255, 80, 80),
    WallbangColor = Color3.fromRGB(255, 0, 255),
}

-- ═══════════════════════════════════════════════════════════════
--                    FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════════════════

local function GetScreenCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen and screenPos.Z > 0
end

local function Distance2D(a, b)
    return (a - b).Magnitude
end

local function Distance3D(a, b)
    return (a - b).Magnitude
end

local function IsAlive(character)
    if not character then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    
    if Config.SkipDowned then
        if character:FindFirstChild("Knocked") or 
           character:FindFirstChild("Downed") or
           hum:GetState() == Enum.HumanoidStateType.Physics then
            return false
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════
--                    SISTEMA DE TIMES
-- ═══════════════════════════════════════════════════════════════

local function GetPlayerTeamName(player)
    if not player.Team then return "Sem Time" end
    local teamName = player.Team.Name:lower()
    
    if teamName:find("prisoner") or teamName:find("prisioneiro") then
        return "Prisioneiros"
    elseif teamName:find("guard") or teamName:find("guarda") or teamName:find("police") then
        return "Guardas"
    elseif teamName:find("criminal") or teamName:find("criminoso") then
        return "Criminosos"
    end
    
    return player.Team.Name
end

local function ShouldTarget(player)
    if player == LocalPlayer then return false end
    
    local filter = Config.TeamFilter
    
    if filter == "Todos" then
        return player ~= LocalPlayer
    elseif filter == "Inimigos" then
        if not LocalPlayer.Team or not player.Team then return true end
        return LocalPlayer.Team ~= player.Team
    else
        local playerTeam = GetPlayerTeamName(player)
        return playerTeam == filter
    end
end

local function HasLineOfSight(origin, target)
    if Config.IgnoreWalls or Config.WallbangEnabled then return true end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local result = Workspace:Raycast(origin, (target - origin), params)
    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        return model and model:FindFirstChildOfClass("Humanoid") ~= nil
    end
    return true
end

local function GetTargetPart(character)
    local part = character:FindFirstChild(Config.AimPart)
    if not part then
        part = character:FindFirstChild("Head") or 
               character:FindFirstChild("HumanoidRootPart")
    end
    return part
end

-- ═══════════════════════════════════════════════════════════════
--                    SISTEMA DE ALVO
-- ═══════════════════════════════════════════════════════════════

local function FindTarget()
    local bestTarget, bestPart = nil, nil
    local bestDist = Config.FOVRadius
    local center = GetScreenCenter()
    local camPos = Camera.CFrame.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if ShouldTarget(player) then
            local char = player.Character
            if char and IsAlive(char) then
                local part = GetTargetPart(char)
                if part then
                    local maxDist = Config.WallbangEnabled and Config.WallbangRange or Config.MaxDistance
                    local dist3D = Distance3D(camPos, part.Position)
                    if dist3D <= maxDist then
                        local screenPos, visible = WorldToScreen(part.Position)
                        -- Para wallbang, não precisa estar visível na tela
                        if visible or Config.WallbangEnabled then
                            local dist2D = Distance2D(center, screenPos)
                            if dist2D < bestDist or Config.WallbangEnabled then
                                if HasLineOfSight(camPos, part.Position) then
                                    bestDist = dist2D
                                    bestTarget = player
                                    bestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget, bestPart
end

-- ═══════════════════════════════════════════════════════════════
--                    SISTEMA DE MIRA
-- ═══════════════════════════════════════════════════════════════

local function AimAt(position)
    if not position then return end
    
    local camPos = Camera.CFrame.Position
    local targetCF = CFrame.lookAt(camPos, position)
    
    if Config.Smoothness > 0 then
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 - Config.Smoothness)
    else
        Camera.CFrame = targetCF
    end
end

-- ═══════════════════════════════════════════════════════════════
--          SILENT AIM AVANÇADO (Hook __index e __namecall)
-- ═══════════════════════════════════════════════════════════════

local SilentAimHooked = false
local OldIndex = nil
local OldNamecall = nil

local function EnableSilentAim()
    if SilentAimHooked then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        local oldReadonly = isreadonly(mt)
        setreadonly(mt, false)
        
        OldIndex = mt.__index
        OldNamecall = mt.__namecall
        
        -- Hook __index para Mouse.Hit e Mouse.Target
        mt.__index = newcclosure(function(self, key)
            if Config.SilentAim and Config.AimbotEnabled then
                if typeof(self) == "Instance" and self:IsA("Mouse") then
                    local target, part = FindTarget()
                    if target and part then
                        if key == "Hit" then
                            return part.CFrame
                        elseif key == "Target" then
                            return part
                        elseif key == "X" then
                            local pos = WorldToScreen(part.Position)
                            return pos.X
                        elseif key == "Y" then
                            local pos = WorldToScreen(part.Position)
                            return pos.Y
                        end
                    end
                end
            end
            return OldIndex(self, key)
        end)
        
        -- Hook __namecall para interceptar FireServer/InvokeServer
        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            
            -- Interceptar chamadas de armas para modificar posição do tiro
            if Config.SilentAim and Config.AimbotEnabled then
                if method == "FireServer" or method == "InvokeServer" then
                    local target, part = FindTarget()
                    if target and part then
                        -- Modificar argumentos que parecem ser posições
                        for i, arg in pairs(args) do
                            if typeof(arg) == "CFrame" then
                                args[i] = part.CFrame
                            elseif typeof(arg) == "Vector3" then
                                args[i] = part.Position
                            end
                        end
                    end
                end
            end
            
            return OldNamecall(self, unpack(args))
        end)
        
        setreadonly(mt, oldReadonly)
        SilentAimHooked = true
    end)
end

local function DisableSilentAim()
    if not SilentAimHooked then return end
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        if OldIndex then mt.__index = OldIndex end
        if OldNamecall then mt.__namecall = OldNamecall end
        setreadonly(mt, true)
        SilentAimHooked = false
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    NOCLIP
-- ═══════════════════════════════════════════════════════════════

local NoClipConnection = nil
local NoClipBypassApplied = false

local function ApplyPrisonLifeBypass()
    if NoClipBypassApplied then return end
    pcall(function()
        local scripts = ReplicatedStorage:FindFirstChild("Scripts")
        if scripts then
            local collision = scripts:FindFirstChild("CharacterCollision")
            if collision then collision:Destroy() end
        end
        NoClipBypassApplied = true
    end)
end

local function EnableNoClip()
    if NoClipConnection then return end
    if IsPrisonLife then ApplyPrisonLifeBypass() end
    
    NoClipConnection = RunService.Stepped:Connect(function()
        if not Config.NoClipEnabled then return end
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function DisableNoClip()
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--                    HITBOX EXPANDER
-- ═══════════════════════════════════════════════════════════════

local HitboxConnection = nil
local OriginalSizes = {}

local function UpdateHitboxes()
    for _, player in pairs(Players:GetPlayers()) do
        if ShouldTarget(player) then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                
                if root then
                    if not OriginalSizes[player] then
                        OriginalSizes[player] = {
                            RootSize = root.Size,
                            HeadSize = head and head.Size or Vector3.new(1, 1, 1)
                        }
                    end
                    
                    if Config.HitboxEnabled then
                        local size = Config.HitboxSize
                        root.Size = Vector3.new(size, size, size)
                        root.Transparency = 0.7
                        root.CanCollide = false
                        root.Material = Enum.Material.ForceField
                        
                        if head then
                            head.Size = Vector3.new(size * 0.8, size * 0.8, size * 0.8)
                            head.Transparency = 0.7
                            head.CanCollide = false
                        end
                    else
                        local orig = OriginalSizes[player]
                        root.Size = orig.RootSize or Vector3.new(2, 2, 1)
                        root.Transparency = 1
                        root.Material = Enum.Material.SmoothPlastic
                        
                        if head then
                            head.Size = orig.HeadSize or Vector3.new(1, 1, 1)
                            head.Transparency = 0
                        end
                    end
                end
            end
        end
    end
end

local function EnableHitbox()
    if HitboxConnection then return end
    HitboxConnection = RunService.Heartbeat:Connect(function()
        if Config.HitboxEnabled then UpdateHitboxes() end
    end)
end

local function DisableHitbox()
    if HitboxConnection then
        HitboxConnection:Disconnect()
        HitboxConnection = nil
    end
    Config.HitboxEnabled = false
    UpdateHitboxes()
    OriginalSizes = {}
end

-- ═══════════════════════════════════════════════════════════════
--                    CFRAME SPEED
-- ═══════════════════════════════════════════════════════════════

local SpeedConnection = nil

local function EnableSpeed()
    if SpeedConnection then return end
    
    SpeedConnection = RunService.Stepped:Connect(function()
        if not Config.SpeedEnabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + hum.MoveDirection * Config.SpeedMultiplier
        end
    end)
end

local function DisableSpeed()
    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--       MUNIÇÃO INFINITA CORRIGIDA (Múltiplos Métodos)
-- ═══════════════════════════════════════════════════════════════

local AmmoHookEnabled = false
local OriginalAmmoValues = {}

-- Método 1: Modificar módulo GunStates (Prison Life)
local function ModifyGunModule(gun)
    if not gun then return false end
    
    local success = pcall(function()
        local gunStates = gun:FindFirstChild("GunStates")
        if gunStates and gunStates:IsA("ModuleScript") then
            local module = require(gunStates)
            
            -- Salvar valores originais
            if not OriginalAmmoValues[gun] then
                OriginalAmmoValues[gun] = {
                    MaxAmmo = module["MaxAmmo"],
                    CurrentAmmo = module["CurrentAmmo"],
                    StoredAmmo = module["StoredAmmo"],
                    AmmoPerClip = module["AmmoPerClip"],
                }
            end
            
            -- Aplicar munição infinita
            if Config.InfiniteAmmoEnabled then
                module["MaxAmmo"] = 999999
                module["CurrentAmmo"] = 999999
                module["StoredAmmo"] = 999999
                module["AmmoPerClip"] = 999999
                module["ReloadTime"] = 0.01
            end
            
            -- Aplicar range infinito
            if Config.InfiniteRangeEnabled then
                module["Range"] = Config.CustomRange
            end
            
            -- Aplicar rapid fire
            if Config.RapidFireEnabled then
                local delays = {
                    Normal = 0.1,
                    Fast = 0.05,
                    Extreme = 0.01,
                    Insane = 0.001
                }
                module["FireRate"] = delays[Config.RapidFireMode] or Config.RapidFireDelay
                module["AutoFire"] = true
            end
            
            return true
        end
    end)
    
    return success
end

-- Método 2: Modificar ValueObjects diretamente
local function ModifyGunValues(gun)
    if not gun then return false end
    
    local success = pcall(function()
        for _, child in pairs(gun:GetDescendants()) do
            local name = child.Name:lower()
            
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                if name:find("ammo") or name:find("clip") or name:find("magazine") then
                    if Config.InfiniteAmmoEnabled then
                        child.Value = 999999
                    end
                elseif name:find("range") or name:find("distance") then
                    if Config.InfiniteRangeEnabled then
                        child.Value = Config.CustomRange
                    end
                elseif name:find("firerate") or name:find("cooldown") or name:find("delay") then
                    if Config.RapidFireEnabled then
                        child.Value = Config.RapidFireDelay
                    end
                end
            end
        end
    end)
    
    return success
end

-- Método 3: Hook de RemoteEvents (mais confiável)
local function HookAmmoRemotes()
    if AmmoHookEnabled then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            
            if method == "FireServer" or method == "InvokeServer" then
                local remoteName = self.Name:lower()
                
                -- Interceptar reloads e modificar munição
                if remoteName:find("reload") or remoteName:find("ammo") then
                    if Config.InfiniteAmmoEnabled then
                        -- Modificar argumentos de munição
                        for i, arg in pairs(args) do
                            if typeof(arg) == "number" and arg < 1000 then
                                args[i] = 999999
                            end
                        end
                    end
                end
            end
            
            return oldNamecall(self, unpack(args))
        end)
        setreadonly(mt, true)
        
        AmmoHookEnabled = true
    end)
end

-- Método 4: Loop de refresh de munição
local AmmoRefreshConnection = nil

local function StartAmmoRefresh()
    if AmmoRefreshConnection then return end
    
    AmmoRefreshConnection = RunService.Heartbeat:Connect(function()
        if not Config.InfiniteAmmoEnabled then return end
        
        -- Atualizar arma no Character
        local char = LocalPlayer.Character
        if char then
            for _, item in pairs(char:GetChildren()) do
                if item:IsA("Tool") then
                    ModifyGunModule(item)
                    ModifyGunValues(item)
                end
            end
        end
        
        -- Atualizar armas no Backpack
        for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                ModifyGunModule(item)
                ModifyGunValues(item)
            end
        end
    end)
end

local function StopAmmoRefresh()
    if AmmoRefreshConnection then
        AmmoRefreshConnection:Disconnect()
        AmmoRefreshConnection = nil
    end
end

-- Função principal de munição infinita
local function EnableInfiniteAmmo()
    -- Aplicar todos os métodos
    if Config.AmmoMethod == "Auto" or Config.AmmoMethod == "Module" then
        -- Modificar armas existentes
        for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                ModifyGunModule(item)
                ModifyGunValues(item)
            end
        end
        
        if LocalPlayer.Character then
            for _, item in pairs(LocalPlayer.Character:GetChildren()) do
                if item:IsA("Tool") then
                    ModifyGunModule(item)
                    ModifyGunValues(item)
                end
            end
        end
    end
    
    if Config.AmmoMethod == "Auto" or Config.AmmoMethod == "Hook" then
        HookAmmoRemotes()
    end
    
    -- Iniciar refresh contínuo
    StartAmmoRefresh()
    
    -- Conectar para novas armas
    if not Connections.AmmoBackpack then
        Connections.AmmoBackpack = LocalPlayer.Backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                ModifyGunModule(child)
                ModifyGunValues(child)
            end
        end)
    end
    
    if LocalPlayer.Character and not Connections.AmmoCharacter then
        Connections.AmmoCharacter = LocalPlayer.Character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                ModifyGunModule(child)
                ModifyGunValues(child)
            end
        end)
    end
end

local function DisableInfiniteAmmo()
    StopAmmoRefresh()
    
    if Connections.AmmoBackpack then
        Connections.AmmoBackpack:Disconnect()
        Connections.AmmoBackpack = nil
    end
    
    if Connections.AmmoCharacter then
        Connections.AmmoCharacter:Disconnect()
        Connections.AmmoCharacter = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--              RAPID FIRE EXTREMO (Bypass de Cooldown)
-- ═══════════════════════════════════════════════════════════════

local RapidFireConnection = nil
local IsHoldingFire = false

local function SimulateClick()
    pcall(function()
        -- Método 1: VirtualInputManager
        VirtualInputManager:SendMouseButtonEvent(
            Mouse.X, Mouse.Y, 0, true, game, 1
        )
        task.wait(0.001)
        VirtualInputManager:SendMouseButtonEvent(
            Mouse.X, Mouse.Y, 0, false, game, 1
        )
    end)
end

local function EnableRapidFire()
    if RapidFireConnection then return end
    
    -- Aplicar modificações nas armas
    EnableInfiniteAmmo() -- Isso também aplica rapid fire nos módulos
    
    -- Sistema de rapid fire por simulação de clique
    RapidFireConnection = RunService.RenderStepped:Connect(function()
        if not Config.RapidFireEnabled then return end
        
        -- Verificar se está segurando botão de tiro (mobile ou PC)
        local firing = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        
        if firing then
            local currentTime = tick()
            local delay = Config.RapidFireDelay
            
            -- Ajustar delay baseado no modo
            if Config.RapidFireMode == "Normal" then
                delay = 0.1
            elseif Config.RapidFireMode == "Fast" then
                delay = 0.05
            elseif Config.RapidFireMode == "Extreme" then
                delay = 0.01
            elseif Config.RapidFireMode == "Insane" then
                delay = 0.001
            end
            
            if currentTime - State.LastFireTime >= delay then
                State.LastFireTime = currentTime
                
                -- Forçar disparo via ativação da ferramenta
                local char = LocalPlayer.Character
                if char then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        pcall(function()
                            tool:Activate()
                        end)
                    end
                end
            end
        end
    end)
end

local function DisableRapidFire()
    if RapidFireConnection then
        RapidFireConnection:Disconnect()
        RapidFireConnection = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--                    RANGE INFINITO
-- ═══════════════════════════════════════════════════════════════

local function EnableInfiniteRange()
    -- Modificar todas as armas
    for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            ModifyGunModule(item)
            ModifyGunValues(item)
        end
    end
    
    if LocalPlayer.Character then
        for _, item in pairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") then
                ModifyGunModule(item)
                ModifyGunValues(item)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--        WALLBANG - TIRO ATRAVÉS DE PAREDES (HITBOX TELEPORT)
-- ═══════════════════════════════════════════════════════════════

local WallbangConnection = nil
local TeleportedHitboxes = {}

--[[
    COMO FUNCIONA O WALLBANG:
    
    Método 1 - Hitbox Teleport:
    - Teleporta temporariamente a hitbox do inimigo para uma posição
      visível ao jogador (na frente da parede)
    - O tiro acerta a hitbox teleportada
    - A hitbox volta para a posição original
    - O dano é registrado no servidor
    
    Método 2 - Ray Bypass:
    - Modifica os parâmetros do raycast para ignorar paredes
    - Funciona apenas em alguns jogos
    
    Método 3 - Bullet TP:
    - Teleporta o projétil diretamente para o alvo
    - Mais detectável mas mais efetivo
]]

local function GetVisiblePosition(targetPos, camPos)
    -- Calcular uma posição entre a câmera e o alvo que seja visível
    local direction = (targetPos - camPos).Unit
    local distance = (targetPos - camPos).Magnitude
    
    -- Encontrar o ponto onde a parede está
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local result = Workspace:Raycast(camPos, direction * distance, params)
    
    if result then
        -- Retornar posição logo antes da parede
        return result.Position - direction * 2
    end
    
    return targetPos
end

local function TeleportHitboxToVisible(player, targetPart)
    if not player or not targetPart then return end
    
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    
    if not root then return end
    
    local camPos = Camera.CFrame.Position
    local originalPos = root.Position
    
    -- Salvar posição original
    if not TeleportedHitboxes[player] then
        TeleportedHitboxes[player] = {
            OriginalRootCF = root.CFrame,
            OriginalHeadCF = head and head.CFrame or nil
        }
    end
    
    -- Calcular posição visível
    local visiblePos = GetVisiblePosition(originalPos, camPos)
    
    -- Teleportar hitbox temporariamente
    pcall(function()
        root.CFrame = CFrame.new(visiblePos)
        if head then
            head.CFrame = CFrame.new(visiblePos + Vector3.new(0, 1.5, 0))
        end
    end)
    
    -- Agendar retorno à posição original
    task.delay(0.05, function()
        pcall(function()
            if TeleportedHitboxes[player] then
                root.CFrame = TeleportedHitboxes[player].OriginalRootCF
                if head and TeleportedHitboxes[player].OriginalHeadCF then
                    head.CFrame = TeleportedHitboxes[player].OriginalHeadCF
                end
                TeleportedHitboxes[player] = nil
            end
        end)
    end)
end

local function EnableWallbang()
    if WallbangConnection then return end
    
    WallbangConnection = RunService.RenderStepped:Connect(function()
        if not Config.WallbangEnabled then return end
        if not Config.AimbotEnabled then return end
        
        -- Verificar se está atirando
        local firing = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        
        if firing and State.Target and State.TargetPart then
            local camPos = Camera.CFrame.Position
            local targetPos = State.TargetPart.Position
            
            -- Verificar se há parede entre jogador e alvo
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = {LocalPlayer.Character, Camera, State.Target.Character}
            
            local result = Workspace:Raycast(camPos, (targetPos - camPos), params)
            
            if result then
                -- Há uma parede - aplicar wallbang
                if Config.WallbangMode == "HitboxTeleport" then
                    TeleportHitboxToVisible(State.Target, State.TargetPart)
                end
            end
        end
    end)
    
    -- Também expandir hitboxes para facilitar o acerto
    Config.HitboxEnabled = true
    EnableHitbox()
end

local function DisableWallbang()
    if WallbangConnection then
        WallbangConnection:Disconnect()
        WallbangConnection = nil
    end
    
    -- Restaurar hitboxes teleportadas
    for player, data in pairs(TeleportedHitboxes) do
        pcall(function()
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                if root and data.OriginalRootCF then
                    root.CFrame = data.OriginalRootCF
                end
                if head and data.OriginalHeadCF then
                    head.CFrame = data.OriginalHeadCF
                end
            end
        end)
    end
    TeleportedHitboxes = {}
end

-- ═══════════════════════════════════════════════════════════════
--                    FOV CIRCLE
-- ═══════════════════════════════════════════════════════════════

local FOVCircle = nil
local AimLine = nil
local WallbangIndicator = nil

local function CreateDrawings()
    pcall(function()
        if FOVCircle then FOVCircle:Remove() end
        if AimLine then AimLine:Remove() end
        if WallbangIndicator then WallbangIndicator:Remove() end
        
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 2
        FOVCircle.NumSides = 60
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Filled = false
        FOVCircle.Visible = false
        FOVCircle.ZIndex = 999
        FOVCircle.Color = Theme.Primary
        
        AimLine = Drawing.new("Line")
        AimLine.Thickness = 2
        AimLine.Color = Theme.Success
        AimLine.Visible = false
        AimLine.ZIndex = 998
        
        -- Indicador de Wallbang
        WallbangIndicator = Drawing.new("Text")
        WallbangIndicator.Size = 16
        WallbangIndicator.Center = true
        WallbangIndicator.Outline = true
        WallbangIndicator.Color = Theme.WallbangColor
        WallbangIndicator.Text = "WALLBANG"
        WallbangIndicator.Visible = false
        WallbangIndicator.ZIndex = 1000
    end)
end

local function UpdateDrawings()
    if FOVCircle then
        FOVCircle.Position = GetScreenCenter()
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Visible = Config.FOVVisible and Config.AimbotEnabled
        FOVCircle.Color = State.Locked and Theme.Success or Theme.Primary
    end
    
    if AimLine and Config.ShowLine and State.Locked and State.TargetPart then
        local targetPos, visible = WorldToScreen(State.TargetPart.Position)
        if visible then
            AimLine.From = GetScreenCenter()
            AimLine.To = targetPos
            AimLine.Visible = true
        else
            AimLine.Visible = false
        end
    elseif AimLine then
        AimLine.Visible = false
    end
    
    -- Indicador de Wallbang
    if WallbangIndicator then
        if Config.WallbangEnabled and State.Locked then
            WallbangIndicator.Position = Vector2.new(Camera.ViewportSize.X / 2, 50)
            WallbangIndicator.Visible = true
        else
            WallbangIndicator.Visible = false
        end
    end
end

local function DestroyDrawings()
    pcall(function()
        if FOVCircle then FOVCircle:Remove() FOVCircle = nil end
        if AimLine then AimLine:Remove() AimLine = nil end
        if WallbangIndicator then WallbangIndicator:Remove() WallbangIndicator = nil end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    ESP
-- ═══════════════════════════════════════════════════════════════

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    pcall(function()
        ESPObjects[player] = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Health = Drawing.new("Text"),
            Distance = Drawing.new("Text"),
        }
        
        local esp = ESPObjects[player]
        esp.Box.Thickness = 1
        esp.Box.Filled = false
        esp.Box.Visible = false
        
        for _, text in pairs({esp.Name, esp.Health, esp.Distance}) do
            text.Size = 13
            text.Center = true
            text.Outline = true
            text.Visible = false
        end
    end)
end

local function UpdateESP(player)
    local esp = ESPObjects[player]
    if not esp then return end
    
    local char = player.Character
    local show = Config.ESPEnabled and char and IsAlive(char)
    
    if not show then
        for _, obj in pairs(esp) do pcall(function() obj.Visible = false end) end
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if not root or not hum then
        for _, obj in pairs(esp) do pcall(function() obj.Visible = false end) end
        return
    end
    
    local rootPos, visible = WorldToScreen(root.Position)
    if not visible then
        for _, obj in pairs(esp) do pcall(function() obj.Visible = false end) end
        return
    end
    
    local headPos = WorldToScreen((head or root).Position + Vector3.new(0, 0.5, 0))
    local feetPos = WorldToScreen(root.Position - Vector3.new(0, 3, 0))
    
    local height = math.abs(headPos.Y - feetPos.Y)
    local width = height / 2
    
    local isTarget = ShouldTarget(player)
    local color = isTarget and Theme.Primary or Theme.Success
    
    if Config.ESPBox then
        esp.Box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Color = color
        esp.Box.Visible = true
    else
        esp.Box.Visible = false
    end
    
    if Config.ESPName then
        local teamName = GetPlayerTeamName(player)
        esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 16)
        esp.Name.Text = player.Name .. " [" .. teamName .. "]"
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end
    
    if Config.ESPHealth then
        local hp = math.floor(hum.Health)
        esp.Health.Position = Vector2.new(rootPos.X, feetPos.Y + 3)
        esp.Health.Text = hp .. " HP"
        esp.Health.Color = hp > 60 and Color3.new(0,1,0) or (hp > 30 and Color3.new(1,1,0) or Color3.new(1,0,0))
        esp.Health.Visible = true
    else
        esp.Health.Visible = false
    end
    
    if Config.ESPDistance then
        local dist = math.floor(Distance3D(Camera.CFrame.Position, root.Position))
        esp.Distance.Position = Vector2.new(rootPos.X, feetPos.Y + 16)
        esp.Distance.Text = dist .. "m"
        esp.Distance.Color = Color3.new(1, 1, 1)
        esp.Distance.Visible = true
    else
        esp.Distance.Visible = false
    end
end

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjects[player] = nil
    end
end

local function InitESP()
    for _, player in pairs(Players:GetPlayers()) do CreateESP(player) end
    Connections.PlayerAdded = Players.PlayerAdded:Connect(CreateESP)
    Connections.PlayerRemoving = Players.PlayerRemoving:Connect(RemoveESP)
end

local function DestroyESP()
    for player, _ in pairs(ESPObjects) do RemoveESP(player) end
end

-- ═══════════════════════════════════════════════════════════════
--                    UI PRÓPRIA - v9.0
-- ═══════════════════════════════════════════════════════════════

local ScreenGui = nil
local MainFrame = nil
local FloatButton = nil
local CurrentTab = "AIM"
local UIVisible = false

local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function AddPadding(parent, padding)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, padding)
    pad.PaddingBottom = UDim.new(0, padding)
    pad.PaddingLeft = UDim.new(0, padding)
    pad.PaddingRight = UDim.new(0, padding)
    pad.Parent = parent
    return pad
end

-- ═══════════════════════════════════════════════════════════════
--                    COMPONENTES UI
-- ═══════════════════════════════════════════════════════════════

local function CreateSectionHeader(parent, title)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = Theme.Primary
    header.BorderSizePixel = 0
    header.Parent = parent
    AddCorner(header, 4)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. title
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header
    
    return header
end

local function CreateToggle(parent, name, default, callback)
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = Theme.Surface
    container.BorderSizePixel = 0
    container.Parent = parent
    AddCorner(container, 4)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 40, 0, 20)
    toggleBg.Position = UDim2.new(1, -48, 0.5, -10)
    toggleBg.BackgroundColor3 = default and Theme.Primary or Theme.Border
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = container
    AddCorner(toggleBg, 10)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    toggleCircle.BackgroundColor3 = Theme.Text
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleBg
    AddCorner(toggleCircle, 8)
    
    local enabled = default
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = container
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        local targetPos = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local targetColor = enabled and Theme.Primary or Theme.Border
        
        TweenService:Create(toggleCircle, TweenInfo.new(0.15), {Position = targetPos}):Play()
        TweenService:Create(toggleBg, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
        
        if callback then callback(enabled) end
    end)
    
    return container
end

local function CreateSlider(parent, name, min, max, default, decimals, callback)
    decimals = decimals or 0
    
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Theme.Surface
    container.BorderSizePixel = 0
    container.Parent = parent
    AddCorner(container, 4)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.Position = UDim2.new(1, -55, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = decimals > 0 and string.format("%." .. decimals .. "f", default) or tostring(default)
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 11
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 0, 32)
    sliderBg.BackgroundColor3 = Theme.Border
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    AddCorner(sliderBg, 3)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Theme.Primary
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    AddCorner(sliderFill, 3)
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0, 14, 0, 14)
    sliderKnob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    sliderKnob.BackgroundColor3 = Theme.Text
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Parent = sliderBg
    AddCorner(sliderKnob, 7)
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(1, 0, 1, 16)
    sliderButton.Position = UDim2.new(0, 0, 0, -8)
    sliderButton.BackgroundTransparency = 1
    sliderButton.Text = ""
    sliderButton.Parent = sliderBg
    
    local dragging = false
    
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local rawValue = min + (max - min) * pos
        local value = decimals > 0 and (math.floor(rawValue * (10^decimals)) / (10^decimals)) or math.floor(rawValue)
        
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        sliderKnob.Position = UDim2.new(pos, -7, 0.5, -7)
        valueLabel.Text = decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(value)
        
        if callback then callback(value) end
    end
    
    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateSlider(input)
        end
    end)
    
    sliderButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)
    
    return container
end

local function CreateDropdown(parent, name, options, default, callback)
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = Theme.Surface
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = parent
    AddCorner(container, 4)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 0, 32)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.5, -15, 0, 26)
    dropBtn.Position = UDim2.new(0.5, 5, 0, 3)
    dropBtn.BackgroundColor3 = Theme.SurfaceLight
    dropBtn.Text = default .. " ▼"
    dropBtn.TextColor3 = Theme.Accent
    dropBtn.TextSize = 11
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.BorderSizePixel = 0
    dropBtn.Parent = container
    AddCorner(dropBtn, 4)
    
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(0.5, -15, 0, #options * 26)
    optionsFrame.Position = UDim2.new(0.5, 5, 0, 32)
    optionsFrame.BackgroundColor3 = Theme.SurfaceLight
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    optionsFrame.Parent = container
    AddCorner(optionsFrame, 4)
    
    local optionsList = Instance.new("UIListLayout")
    optionsList.SortOrder = Enum.SortOrder.LayoutOrder
    optionsList.Parent = optionsFrame
    
    local expanded = false
    
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = option
        optBtn.TextColor3 = Theme.Text
        optBtn.TextSize = 11
        optBtn.Font = Enum.Font.Gotham
        optBtn.BorderSizePixel = 0
        optBtn.Parent = optionsFrame
        
        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundTransparency = 0.5
            optBtn.BackgroundColor3 = Theme.Primary
        end)
        
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundTransparency = 1
        end)
        
        optBtn.MouseButton1Click:Connect(function()
            dropBtn.Text = option .. " ▼"
            expanded = false
            optionsFrame.Visible = false
            container.Size = UDim2.new(1, 0, 0, 32)
            if callback then callback(option) end
        end)
    end
    
    dropBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        optionsFrame.Visible = expanded
        container.Size = expanded and UDim2.new(1, 0, 0, 32 + #options * 26 + 4) or UDim2.new(1, 0, 0, 32)
    end)
    
    return container
end

local function CreateSpacer(parent, height)
    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, height or 8)
    spacer.BackgroundTransparency = 1
    spacer.Parent = parent
    return spacer
end

-- ═══════════════════════════════════════════════════════════════
--                    CRIAR UI PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local function CreateUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SAVAGECHEATS_V90"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- ═══════════════════════════════════════════════════════════════
    --                    BOTÃO FLUTUANTE
    -- ═══════════════════════════════════════════════════════════════
    
    FloatButton = Instance.new("TextButton")
    FloatButton.Name = "FloatButton"
    FloatButton.Size = UDim2.new(0, 45, 0, 45)
    FloatButton.Position = UDim2.new(0, 15, 0.5, -22)
    FloatButton.BackgroundColor3 = Theme.Primary
    FloatButton.Text = "S9"
    FloatButton.TextColor3 = Theme.Text
    FloatButton.TextSize = 18
    FloatButton.Font = Enum.Font.GothamBold
    FloatButton.BorderSizePixel = 0
    FloatButton.Parent = ScreenGui
    AddCorner(FloatButton, 22)
    AddStroke(FloatButton, Theme.Text, 2)
    
    -- Drag do botão flutuante
    local draggingFloat = false
    local dragStartFloat, startPosFloat
    
    FloatButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFloat = true
            dragStartFloat = input.Position
            startPosFloat = FloatButton.Position
        end
    end)
    
    FloatButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFloat = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if draggingFloat and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartFloat
            FloatButton.Position = UDim2.new(
                startPosFloat.X.Scale, startPosFloat.X.Offset + delta.X,
                startPosFloat.Y.Scale, startPosFloat.Y.Offset + delta.Y
            )
        end
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    FRAME PRINCIPAL
    -- ═══════════════════════════════════════════════════════════════
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 300, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    AddCorner(MainFrame, 8)
    AddStroke(MainFrame, Theme.Primary, 2)
    
    -- Drag do frame principal
    local draggingMain = false
    local dragStartMain, startPosMain
    
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingMain = true
            dragStartMain = input.Position
            startPosMain = MainFrame.Position
        end
    end)
    
    MainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingMain = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if draggingMain and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartMain
            MainFrame.Position = UDim2.new(
                startPosMain.X.Scale, startPosMain.X.Offset + delta.X,
                startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Toggle UI
    FloatButton.MouseButton1Click:Connect(function()
        UIVisible = not UIVisible
        MainFrame.Visible = UIVisible
    end)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Theme.Secondary
    header.BorderSizePixel = 0
    header.Parent = MainFrame
    AddCorner(header, 8)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SAVAGE v9.0 - " .. GameName
    title.TextColor3 = Theme.Text
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Theme.Primary
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    AddCorner(closeBtn, 4)
    
    closeBtn.MouseButton1Click:Connect(function()
        UIVisible = false
        MainFrame.Visible = false
    end)
    
    -- Tabs Container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(1, -16, 0, 30)
    tabsContainer.Position = UDim2.new(0, 8, 0, 45)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Parent = MainFrame
    
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.Padding = UDim.new(0, 4)
    tabsLayout.Parent = tabsContainer
    
    -- Content Container
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Size = UDim2.new(1, -16, 1, -90)
    contentContainer.Position = UDim2.new(0, 8, 0, 80)
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.ScrollBarThickness = 4
    contentContainer.ScrollBarImageColor3 = Theme.Primary
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentContainer.Parent = MainFrame
    
    local contentList = Instance.new("UIListLayout")
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.Padding = UDim.new(0, 6)
    contentList.Parent = contentContainer
    
    contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentContainer.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 10)
    end)
    
    local tabs = {"AIM", "ESP", "ARMAS", "MISC"}
    local tabButtons = {}
    local tabContents = {}
    
    for _, tabName in ipairs(tabs) do
        local content = Instance.new("Frame")
        content.Name = tabName .. "Content"
        content.Size = UDim2.new(1, 0, 0, 0)
        content.BackgroundTransparency = 1
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.Visible = tabName == "AIM"
        content.Parent = contentContainer
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 5)
        contentLayout.Parent = content
        
        tabContents[tabName] = content
    end
    
    for _, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 65, 0, 26)
        tabBtn.BackgroundColor3 = tabName == "AIM" and Theme.Primary or Theme.Surface
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Theme.Text
        tabBtn.TextSize = 11
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabsContainer
        AddCorner(tabBtn, 4)
        
        tabButtons[tabName] = tabBtn
        
        tabBtn.MouseButton1Click:Connect(function()
            CurrentTab = tabName
            
            for name, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = name == tabName and Theme.Primary or Theme.Surface
            end
            
            for name, content in pairs(tabContents) do
                content.Visible = name == tabName
            end
        end)
    end
    
    -- ═══════════════════════════════════════════════════════════════
    --                    ABA AIM
    -- ═══════════════════════════════════════════════════════════════
    
    local aimContent = tabContents["AIM"]
    
    CreateSectionHeader(aimContent, "Aimbot")
    
    CreateToggle(aimContent, "Ativar Aimbot", false, function(v)
        Config.AimbotEnabled = v
        if v then EnableSilentAim() end
    end)
    
    CreateToggle(aimContent, "Silent Aim", false, function(v)
        Config.SilentAim = v
    end)
    
    CreateToggle(aimContent, "Ignorar Paredes", false, function(v)
        Config.IgnoreWalls = v
    end)
    
    CreateSpacer(aimContent, 4)
    CreateSectionHeader(aimContent, "Configurações")
    
    CreateDropdown(aimContent, "Alvo", {"Head", "HumanoidRootPart", "Torso"}, "Head", function(v)
        Config.AimPart = v
    end)
    
    CreateDropdown(aimContent, "Focar Time", {"Todos", "Inimigos", "Prisioneiros", "Guardas", "Criminosos"}, "Todos", function(v)
        Config.TeamFilter = v
    end)
    
    CreateSlider(aimContent, "Tamanho FOV", 50, 400, 150, 0, function(v)
        Config.FOVRadius = v
    end)
    
    CreateSlider(aimContent, "Suavização", 0, 100, 30, 0, function(v)
        Config.Smoothness = v / 100
    end)
    
    CreateSpacer(aimContent, 4)
    CreateSectionHeader(aimContent, "Visual")
    
    CreateToggle(aimContent, "Mostrar FOV", true, function(v)
        Config.FOVVisible = v
    end)
    
    CreateToggle(aimContent, "Mostrar Linha", false, function(v)
        Config.ShowLine = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    ABA ESP
    -- ═══════════════════════════════════════════════════════════════
    
    local espContent = tabContents["ESP"]
    
    CreateSectionHeader(espContent, "ESP")
    
    CreateToggle(espContent, "Ativar ESP", false, function(v)
        Config.ESPEnabled = v
    end)
    
    CreateSpacer(espContent, 4)
    CreateSectionHeader(espContent, "Elementos")
    
    CreateToggle(espContent, "Box", true, function(v)
        Config.ESPBox = v
    end)
    
    CreateToggle(espContent, "Nome + Time", true, function(v)
        Config.ESPName = v
    end)
    
    CreateToggle(espContent, "Vida", true, function(v)
        Config.ESPHealth = v
    end)
    
    CreateToggle(espContent, "Distância", true, function(v)
        Config.ESPDistance = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    ABA ARMAS (NOVA v9.0)
    -- ═══════════════════════════════════════════════════════════════
    
    local armasContent = tabContents["ARMAS"]
    
    CreateSectionHeader(armasContent, "🔥 Rapid Fire EXTREMO")
    
    CreateToggle(armasContent, "Ativar Rapid Fire", false, function(v)
        Config.RapidFireEnabled = v
        if v then EnableRapidFire() else DisableRapidFire() end
    end)
    
    CreateDropdown(armasContent, "Modo", {"Normal", "Fast", "Extreme", "Insane"}, "Extreme", function(v)
        Config.RapidFireMode = v
        if Config.RapidFireEnabled then
            EnableInfiniteAmmo() -- Reaplicar
        end
    end)
    
    CreateSpacer(armasContent, 4)
    CreateSectionHeader(armasContent, "🔫 Munição Infinita")
    
    CreateToggle(armasContent, "Munição Infinita", false, function(v)
        Config.InfiniteAmmoEnabled = v
        if v then EnableInfiniteAmmo() else DisableInfiniteAmmo() end
    end)
    
    CreateDropdown(armasContent, "Método", {"Auto", "Module", "Hook"}, "Auto", function(v)
        Config.AmmoMethod = v
        if Config.InfiniteAmmoEnabled then
            EnableInfiniteAmmo()
        end
    end)
    
    CreateSpacer(armasContent, 4)
    CreateSectionHeader(armasContent, "🎯 Range Infinito")
    
    CreateToggle(armasContent, "Range Infinito", false, function(v)
        Config.InfiniteRangeEnabled = v
        if v then EnableInfiniteRange() end
    end)
    
    CreateSlider(armasContent, "Range (studs)", 100, 99999, 9999, 0, function(v)
        Config.CustomRange = v
    end)
    
    CreateSpacer(armasContent, 4)
    CreateSectionHeader(armasContent, "💀 WALLBANG")
    
    CreateToggle(armasContent, "Tiro Através Paredes", false, function(v)
        Config.WallbangEnabled = v
        if v then EnableWallbang() else DisableWallbang() end
    end)
    
    CreateSlider(armasContent, "Alcance Wallbang", 100, 1000, 500, 0, function(v)
        Config.WallbangRange = v
    end)
    
    CreateSpacer(armasContent, 4)
    CreateSectionHeader(armasContent, "📦 Hitbox")
    
    CreateToggle(armasContent, "Hitbox Expander", false, function(v)
        Config.HitboxEnabled = v
        if v then EnableHitbox() else DisableHitbox() end
    end)
    
    CreateSlider(armasContent, "Tamanho Hitbox", 3, 30, 5, 0, function(v)
        Config.HitboxSize = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    ABA MISC
    -- ═══════════════════════════════════════════════════════════════
    
    local miscContent = tabContents["MISC"]
    
    CreateSectionHeader(miscContent, "Movimento")
    
    CreateToggle(miscContent, "Speed Hack", false, function(v)
        Config.SpeedEnabled = v
        if v then EnableSpeed() else DisableSpeed() end
    end)
    
    CreateSlider(miscContent, "Velocidade (÷10)", 1, 15, 2, 0, function(v)
        Config.SpeedMultiplier = v / 10
    end)
    
    CreateToggle(miscContent, "NoClip", false, function(v)
        Config.NoClipEnabled = v
        if v then EnableNoClip() else DisableNoClip() end
    end)
    
    CreateSpacer(miscContent, 4)
    CreateSectionHeader(miscContent, "Performance Mobile")
    
    CreateToggle(miscContent, "Modo Economia", false, function(v)
        Config.LowPowerMode = v
        Config.UpdateRate = v and 3 or 1
    end)
    
    CreateSpacer(miscContent, 4)
    CreateSectionHeader(miscContent, "Informações v9.0")
    
    local infoBox = Instance.new("TextLabel")
    infoBox.Size = UDim2.new(1, 0, 0, 140)
    infoBox.BackgroundColor3 = Theme.Surface
    infoBox.Text = [[Jogo: ]] .. GameName .. [[

NOVIDADES v9.0:
• Munição Infinita CORRIGIDA
• Rapid Fire EXTREMO (4 modos)
• Range Infinito (sem limite)
• WALLBANG - Tiro através paredes
• Otimizado para Mobile

Dicas:
• Ative Wallbang + Aimbot juntos
• Use Hitbox para facilitar acertos]]
    infoBox.TextColor3 = Theme.TextDim
    infoBox.TextSize = 10
    infoBox.Font = Enum.Font.Gotham
    infoBox.TextWrapped = true
    infoBox.TextYAlignment = Enum.TextYAlignment.Top
    infoBox.BorderSizePixel = 0
    infoBox.Parent = miscContent
    AddCorner(infoBox, 4)
    AddPadding(infoBox, 8)
end

-- ═══════════════════════════════════════════════════════════════
--                    LOOP PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local MainConnection = nil

local function MainLoop()
    MainConnection = RunService.RenderStepped:Connect(function()
        -- Otimização mobile: pular frames
        State.FrameCount = State.FrameCount + 1
        if Config.LowPowerMode and State.FrameCount % Config.UpdateRate ~= 0 then
            return
        end
        
        if Config.AimbotEnabled then
            local target, part = FindTarget()
            
            if target and part then
                State.Target = target
                State.TargetPart = part
                State.Locked = true
                
                if not Config.SilentAim then
                    AimAt(part.Position)
                end
            else
                State.Target = nil
                State.TargetPart = nil
                State.Locked = false
            end
        else
            State.Target = nil
            State.TargetPart = nil
            State.Locked = false
        end
        
        UpdateDrawings()
        
        -- Atualizar ESP (com otimização)
        if not Config.LowPowerMode or State.FrameCount % 2 == 0 then
            for player, _ in pairs(ESPObjects) do
                UpdateESP(player)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    CLEANUP
-- ═══════════════════════════════════════════════════════════════

local function DestroyAll()
    if MainConnection then MainConnection:Disconnect() end
    
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    DisableSilentAim()
    DisableNoClip()
    DisableHitbox()
    DisableSpeed()
    DisableInfiniteAmmo()
    DisableRapidFire()
    DisableWallbang()
    DestroyDrawings()
    DestroyESP()
    
    if ScreenGui then ScreenGui:Destroy() end
    
    _G.SAVAGE_V90 = nil
end

_G.SAVAGE_V90 = true
_G.SAVAGE_V90_CLEANUP = DestroyAll

-- ═══════════════════════════════════════════════════════════════
--                    INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("═══════════════════════════════════════════════════════════════")
    print("           SAVAGECHEATS_ AIMBOT v9.0 - ULTIMATE EDITION")
    print("═══════════════════════════════════════════════════════════════")
    print("Jogo: " .. GameName)
    print("")
    print("NOVIDADES v9.0:")
    print("  • Munição Infinita CORRIGIDA (múltiplos métodos)")
    print("  • Rapid Fire EXTREMO (4 modos de velocidade)")
    print("  • Range Infinito (sem limite de distância)")
    print("  • WALLBANG - Tiro através de paredes")
    print("  • Otimizado para Mobile")
    print("")
    
    CreateUI()
    CreateDrawings()
    InitESP()
    MainLoop()
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        
        if Config.NoClipEnabled then EnableNoClip() end
        if Config.SpeedEnabled then EnableSpeed() end
        if Config.InfiniteAmmoEnabled then EnableInfiniteAmmo() end
        if Config.RapidFireEnabled then EnableRapidFire() end
        if Config.InfiniteRangeEnabled then EnableInfiniteRange() end
        if Config.WallbangEnabled then EnableWallbang() end
        
        if IsPrisonLife then
            NoClipBypassApplied = false
            ApplyPrisonLifeBypass()
        end
        
        -- Reconectar eventos de armas
        if char then
            Connections.AmmoCharacter = char.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    task.wait(0.1)
                    if Config.InfiniteAmmoEnabled or Config.RapidFireEnabled or Config.InfiniteRangeEnabled then
                        ModifyGunModule(child)
                        ModifyGunValues(child)
                    end
                end
            end)
        end
    end)
    
    print("═══════════════════════════════════════════════════════════════")
    print("✓ Carregado! Clique no botão 'S9' vermelho para abrir o menu")
    print("═══════════════════════════════════════════════════════════════")
end

Initialize()
