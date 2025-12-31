--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║              SAVAGECHEATS_ AIMBOT UNIVERSAL v7.0              ║
    ║         UI Redz Hub Style + CFrame Speed Bypass               ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  NOVIDADES v7.0:                                              ║
    ║  • UI estilo Redz Hub (externa)                               ║
    ║  • CFrame Speed (bypass real de anti-cheat)                   ║
    ║  • Não modifica WalkSpeed (indetectável)                      ║
    ║  • Multiplicador ajustável                                    ║
    ║  • Compatível com Prison Life                                 ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
--                          SERVIÇOS
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
if _G.SAVAGE_V7 then
    pcall(function() 
        _G.SAVAGE_V7_CLEANUP()
    end)
    task.wait(0.5)
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
    
    -- FOV
    FOVRadius = 150,
    FOVVisible = true,
    
    -- Smoothing
    Smoothness = 0.3,
    
    -- Team
    TeamCheck = true,
    
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
    
    -- CFrame Speed (NOVO - bypass real)
    CFrameSpeedEnabled = false,
    CFrameMultiplier = 0.5, -- 0.3 = seguro, 0.5 = moderado, 0.8+ = arriscado
    
    -- Misc
    ShowLine = false,
    MaxDistance = 1000,
}

-- ═══════════════════════════════════════════════════════════════
--                          ESTADO
-- ═══════════════════════════════════════════════════════════════

local State = {
    Target = nil,
    TargetPart = nil,
    Locked = false,
}

local Connections = {}
local ESPObjects = {}

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

local function IsSameTeam(player)
    if not Config.TeamCheck then return false end
    if not LocalPlayer.Team or not player.Team then return false end
    return LocalPlayer.Team == player.Team
end

local function HasLineOfSight(origin, target)
    if Config.IgnoreWalls then return true end
    
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
        if player ~= LocalPlayer and not IsSameTeam(player) then
            local char = player.Character
            if char and IsAlive(char) then
                local part = GetTargetPart(char)
                if part then
                    local dist3D = Distance3D(camPos, part.Position)
                    if dist3D <= Config.MaxDistance then
                        local screenPos, visible = WorldToScreen(part.Position)
                        if visible then
                            local dist2D = Distance2D(center, screenPos)
                            if dist2D < bestDist then
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
--                    SILENT AIM (BALA MÁGICA)
-- ═══════════════════════════════════════════════════════════════

local SilentAimHooked = false
local OldIndex = nil

local function EnableSilentAim()
    if SilentAimHooked then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        local oldReadonly = isreadonly(mt)
        setreadonly(mt, false)
        
        OldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if Config.SilentAim and Config.AimbotEnabled then
                if typeof(self) == "Instance" and self:IsA("Mouse") then
                    local target, part = FindTarget()
                    if target and part then
                        if key == "Hit" then
                            return part.CFrame
                        elseif key == "Target" then
                            return part
                        end
                    end
                end
            end
            return OldIndex(self, key)
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
        if OldIndex then
            mt.__index = OldIndex
        end
        setreadonly(mt, true)
        SilentAimHooked = false
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    NOCLIP COM BYPASS
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
        
        if LocalPlayer.Character then
            local head = LocalPlayer.Character:FindFirstChild("Head")
            if head and getconnections then
                for _, conn in pairs(getconnections(head:GetPropertyChangedSignal("CanCollide"))) do
                    conn:Disable()
                end
            end
        end
        
        NoClipBypassApplied = true
    end)
end

local function EnableNoClip()
    if NoClipConnection then return end
    
    if IsPrisonLife then
        ApplyPrisonLifeBypass()
    end
    
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
--              HITBOX EXPANDER
-- ═══════════════════════════════════════════════════════════════

local HitboxConnection = nil
local OriginalSizes = {}

local function UpdateHitboxes()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not IsSameTeam(player) then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    if not OriginalSizes[player] then
                        OriginalSizes[player] = root.Size
                    end
                    
                    if Config.HitboxEnabled then
                        local size = Config.HitboxSize
                        root.Size = Vector3.new(size, size, size)
                        root.Transparency = 0.8
                        root.CanCollide = false
                        root.Material = Enum.Material.ForceField
                    else
                        root.Size = OriginalSizes[player] or Vector3.new(2, 2, 1)
                        root.Transparency = 1
                        root.Material = Enum.Material.Plastic
                    end
                end
            end
        end
    end
end

local function EnableHitbox()
    if HitboxConnection then return end
    
    HitboxConnection = RunService.Heartbeat:Connect(function()
        if Config.HitboxEnabled then
            UpdateHitboxes()
        end
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
--         CFRAME SPEED - BYPASS REAL DE ANTI-CHEAT
-- ═══════════════════════════════════════════════════════════════
--[[
    COMO FUNCIONA:
    - NÃO modifica WalkSpeed (permanece 16)
    - Move o personagem via CFrame
    - Anti-cheat verifica WalkSpeed mas não detecta CFrame
    - Multiplicador controla a velocidade extra
    
    VALORES RECOMENDADOS:
    - 0.3 = Boost leve (muito seguro)
    - 0.5 = Moderado (seguro)
    - 0.8 = Rápido (risco médio)
    - 1.0+ = Muito rápido (pode ser detectado por distância)
]]

local CFrameSpeedConnection = nil

local function EnableCFrameSpeed()
    if CFrameSpeedConnection then return end
    
    CFrameSpeedConnection = RunService.Stepped:Connect(function()
        if not Config.CFrameSpeedEnabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if hrp and hum then
            -- Só aplica se estiver se movendo
            if hum.MoveDirection.Magnitude > 0 then
                -- Move via CFrame (não detectável por WalkSpeed check)
                hrp.CFrame = hrp.CFrame + hum.MoveDirection * Config.CFrameMultiplier
            end
        end
    end)
end

local function DisableCFrameSpeed()
    if CFrameSpeedConnection then
        CFrameSpeedConnection:Disconnect()
        CFrameSpeedConnection = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--                    SISTEMA FOV CIRCLE
-- ═══════════════════════════════════════════════════════════════

local FOVCircle = nil
local AimLine = nil

local function CreateDrawings()
    pcall(function()
        if FOVCircle then FOVCircle:Remove() end
        if AimLine then AimLine:Remove() end
        
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 2
        FOVCircle.NumSides = 60
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Filled = false
        FOVCircle.Visible = false
        FOVCircle.ZIndex = 999
        FOVCircle.Color = Color3.fromRGB(200, 35, 35)
        
        AimLine = Drawing.new("Line")
        AimLine.Thickness = 2
        AimLine.Color = Color3.fromRGB(50, 200, 50)
        AimLine.Visible = false
        AimLine.ZIndex = 998
    end)
end

local function UpdateDrawings()
    if FOVCircle then
        FOVCircle.Position = GetScreenCenter()
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Visible = Config.FOVVisible and Config.AimbotEnabled
        FOVCircle.Color = State.Locked and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 35, 35)
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
end

local function DestroyDrawings()
    pcall(function()
        if FOVCircle then FOVCircle:Remove() FOVCircle = nil end
        if AimLine then AimLine:Remove() AimLine = nil end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                       SISTEMA ESP
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
        esp.Box.ZIndex = 997
        
        esp.Name.Size = 14
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.Visible = false
        esp.Name.ZIndex = 998
        
        esp.Health.Size = 12
        esp.Health.Center = true
        esp.Health.Outline = true
        esp.Health.Visible = false
        esp.Health.ZIndex = 998
        
        esp.Distance.Size = 12
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.Visible = false
        esp.Distance.ZIndex = 998
    end)
end

local function UpdateESP(player)
    local esp = ESPObjects[player]
    if not esp then return end
    
    local char = player.Character
    local show = Config.ESPEnabled and char and IsAlive(char)
    
    if not show then
        for _, obj in pairs(esp) do
            pcall(function() obj.Visible = false end)
        end
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if not root or not hum then
        for _, obj in pairs(esp) do
            pcall(function() obj.Visible = false end)
        end
        return
    end
    
    local rootPos, visible = WorldToScreen(root.Position)
    if not visible then
        for _, obj in pairs(esp) do
            pcall(function() obj.Visible = false end)
        end
        return
    end
    
    local headPos = WorldToScreen((head or root).Position + Vector3.new(0, 0.5, 0))
    local feetPos = WorldToScreen(root.Position - Vector3.new(0, 3, 0))
    
    local height = math.abs(headPos.Y - feetPos.Y)
    local width = height / 2
    
    local color = IsSameTeam(player) and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 35, 35)
    
    if Config.ESPBox then
        esp.Box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Color = color
        esp.Box.Visible = true
    else
        esp.Box.Visible = false
    end
    
    if Config.ESPName then
        esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 18)
        esp.Name.Text = player.Name
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end
    
    if Config.ESPHealth then
        local hp = math.floor(hum.Health)
        local maxHp = hum.MaxHealth
        local pct = math.floor((hp / maxHp) * 100)
        
        esp.Health.Position = Vector2.new(rootPos.X, feetPos.Y + 5)
        esp.Health.Text = hp .. " HP"
        esp.Health.Color = pct > 60 and Color3.new(0,1,0) or (pct > 30 and Color3.new(1,1,0) or Color3.new(1,0,0))
        esp.Health.Visible = true
    else
        esp.Health.Visible = false
    end
    
    if Config.ESPDistance then
        local dist = math.floor(Distance3D(Camera.CFrame.Position, root.Position))
        esp.Distance.Position = Vector2.new(rootPos.X, feetPos.Y + 18)
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
    for _, player in pairs(Players:GetPlayers()) do
        CreateESP(player)
    end
    
    Connections.PlayerAdded = Players.PlayerAdded:Connect(CreateESP)
    Connections.PlayerRemoving = Players.PlayerRemoving:Connect(RemoveESP)
end

local function DestroyESP()
    for player, _ in pairs(ESPObjects) do
        RemoveESP(player)
    end
end


-- ═══════════════════════════════════════════════════════════════
--                    CARREGAR UI REDZ HUB
-- ═══════════════════════════════════════════════════════════════

local redzlib = nil
local Window = nil

local function LoadRedzUI()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/tbao143/Library-ui/refs/heads/main/Redzhubui"))()
    end)
    
    if not success then
        -- Fallback: criar UI simples se Redz não carregar
        warn("[SAVAGECHEATS] Redz UI não carregou, usando UI alternativa")
        return nil
    end
    
    return result
end

local function CreateRedzUI()
    redzlib = LoadRedzUI()
    
    if not redzlib then
        -- Se Redz não carregar, usar Kavo como fallback
        pcall(function()
            redzlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
        end)
        
        if redzlib and redzlib.CreateLib then
            -- Usar Kavo UI
            Window = redzlib.CreateLib("SAVAGECHEATS v7.0", "DarkTheme")
            CreateKavoUI()
            return
        else
            warn("[SAVAGECHEATS] Nenhuma UI carregou!")
            return
        end
    end
    
    -- Criar janela Redz Hub
    Window = redzlib:MakeWindow({
        Title = "SAVAGECHEATS",
        SubTitle = "v7.0 | " .. GameName,
        SaveFolder = "SavageCheatsV7"
    })
    
    -- Botão minimizar
    Window:AddMinimizeButton({
        Button = {
            Image = "rbxassetid://71014873973869",
            BackgroundTransparency = 0
        },
        Corner = {
            CornerRadius = UDim.new(0, 8)
        }
    })
    
    -- ═══════════════════════════════════════════════════════════════
    --                         ABA AIM
    -- ═══════════════════════════════════════════════════════════════
    
    local AimTab = Window:MakeTab({"Aimbot", "crosshair"})
    Window:SelectTab(AimTab)
    
    -- Toggle Aimbot
    local AimbotToggle = AimTab:AddToggle({
        Name = "Ativar Aimbot",
        Description = "Liga/desliga o sistema de mira automática",
        Default = false
    })
    AimbotToggle:Callback(function(value)
        Config.AimbotEnabled = value
        if value then
            EnableSilentAim()
        end
    end)
    
    -- Silent Aim
    local SilentToggle = AimTab:AddToggle({
        Name = "Silent Aim (Bala Mágica)",
        Description = "Balas vão automaticamente para o alvo",
        Default = false
    })
    SilentToggle:Callback(function(value)
        Config.SilentAim = value
    end)
    
    -- Ignorar Paredes
    local WallsToggle = AimTab:AddToggle({
        Name = "Ignorar Paredes",
        Description = "Mira através de paredes",
        Default = false
    })
    WallsToggle:Callback(function(value)
        Config.IgnoreWalls = value
    end)
    
    -- Mostrar FOV
    local FOVToggle = AimTab:AddToggle({
        Name = "Mostrar FOV",
        Description = "Exibe círculo de FOV na tela",
        Default = true
    })
    FOVToggle:Callback(function(value)
        Config.FOVVisible = value
    end)
    
    -- Mostrar Linha
    local LineToggle = AimTab:AddToggle({
        Name = "Mostrar Linha",
        Description = "Linha até o alvo",
        Default = false
    })
    LineToggle:Callback(function(value)
        Config.ShowLine = value
    end)
    
    -- FOV Slider
    AimTab:AddSlider({
        Name = "Tamanho FOV",
        Min = 50,
        Max = 500,
        Increase = 10,
        Default = 150,
        Callback = function(value)
            Config.FOVRadius = value
        end
    })
    
    -- Smoothness Slider
    AimTab:AddSlider({
        Name = "Suavização",
        Min = 0,
        Max = 100,
        Increase = 5,
        Default = 30,
        Callback = function(value)
            Config.Smoothness = value / 100
        end
    })
    
    -- Dropdown Aim Part
    AimTab:AddDropdown({
        Name = "Parte do Corpo",
        Description = "Onde mirar",
        Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"},
        Default = "Head",
        Callback = function(value)
            Config.AimPart = value
        end
    })
    
    -- ═══════════════════════════════════════════════════════════════
    --                         ABA ESP
    -- ═══════════════════════════════════════════════════════════════
    
    local ESPTab = Window:MakeTab({"ESP", "eye"})
    
    -- Toggle ESP
    local ESPToggle = ESPTab:AddToggle({
        Name = "Ativar ESP",
        Description = "Mostra jogadores através de paredes",
        Default = false
    })
    ESPToggle:Callback(function(value)
        Config.ESPEnabled = value
    end)
    
    -- Box
    local BoxToggle = ESPTab:AddToggle({
        Name = "Box",
        Description = "Caixa ao redor dos jogadores",
        Default = true
    })
    BoxToggle:Callback(function(value)
        Config.ESPBox = value
    end)
    
    -- Nome
    local NameToggle = ESPTab:AddToggle({
        Name = "Nome",
        Description = "Mostra nome do jogador",
        Default = true
    })
    NameToggle:Callback(function(value)
        Config.ESPName = value
    end)
    
    -- Vida
    local HealthToggle = ESPTab:AddToggle({
        Name = "Vida",
        Description = "Mostra HP do jogador",
        Default = true
    })
    HealthToggle:Callback(function(value)
        Config.ESPHealth = value
    end)
    
    -- Distância
    local DistToggle = ESPTab:AddToggle({
        Name = "Distância",
        Description = "Mostra distância até o jogador",
        Default = true
    })
    DistToggle:Callback(function(value)
        Config.ESPDistance = value
    end)
    
    -- Team Check
    local TeamToggle = ESPTab:AddToggle({
        Name = "Verificar Time",
        Description = "Não mostra aliados",
        Default = true
    })
    TeamToggle:Callback(function(value)
        Config.TeamCheck = value
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                         ABA MISC
    -- ═══════════════════════════════════════════════════════════════
    
    local MiscTab = Window:MakeTab({"Misc", "settings"})
    
    -- Seção Speed
    local SpeedSection = MiscTab:AddSection({"CFrame Speed (Bypass)"})
    
    -- Aviso Prison Life
    if IsPrisonLife then
        MiscTab:AddParagraph({
            "⚠️ Prison Life Detectado",
            "Use valores baixos (0.3-0.5) para evitar detecção!\nValores altos podem causar kick."
        })
    end
    
    -- Toggle CFrame Speed
    local SpeedToggle = MiscTab:AddToggle({
        Name = "CFrame Speed",
        Description = "Velocidade via CFrame (não modifica WalkSpeed)",
        Default = false
    })
    SpeedToggle:Callback(function(value)
        Config.CFrameSpeedEnabled = value
        if value then
            EnableCFrameSpeed()
        else
            DisableCFrameSpeed()
        end
    end)
    
    -- Slider Multiplicador
    MiscTab:AddSlider({
        Name = "Multiplicador Speed",
        Min = 1,
        Max = 20,
        Increase = 1,
        Default = 5,
        Callback = function(value)
            Config.CFrameMultiplier = value / 10 -- 1 = 0.1, 5 = 0.5, 10 = 1.0
        end
    })
    
    MiscTab:AddParagraph({
        "Valores Recomendados",
        "1-3 = Seguro | 4-6 = Moderado | 7+ = Arriscado"
    })
    
    -- Seção NoClip
    local NoClipSection = MiscTab:AddSection({"NoClip"})
    
    -- Toggle NoClip
    local NoClipToggle = MiscTab:AddToggle({
        Name = "NoClip",
        Description = IsPrisonLife and "Com bypass para Prison Life" or "Atravessar paredes",
        Default = false
    })
    NoClipToggle:Callback(function(value)
        Config.NoClipEnabled = value
        if value then
            EnableNoClip()
        else
            DisableNoClip()
        end
    end)
    
    -- Seção Hitbox
    local HitboxSection = MiscTab:AddSection({"Hitbox Expander"})
    
    -- Toggle Hitbox
    local HitboxToggle = MiscTab:AddToggle({
        Name = "Hitbox Expander",
        Description = "Aumenta hitbox dos inimigos",
        Default = false
    })
    HitboxToggle:Callback(function(value)
        Config.HitboxEnabled = value
        if value then
            EnableHitbox()
        else
            DisableHitbox()
        end
    end)
    
    -- Slider Hitbox Size
    MiscTab:AddSlider({
        Name = "Tamanho Hitbox",
        Min = 2,
        Max = 20,
        Increase = 1,
        Default = 5,
        Callback = function(value)
            Config.HitboxSize = value
        end
    })
    
    -- ═══════════════════════════════════════════════════════════════
    --                         ABA INFO
    -- ═══════════════════════════════════════════════════════════════
    
    local InfoTab = Window:MakeTab({"Info", "info"})
    
    InfoTab:AddParagraph({
        "SAVAGECHEATS v7.0",
        "Aimbot Universal com UI Redz Hub\n\nJogo: " .. GameName .. "\nPlaceId: " .. GameId
    })
    
    InfoTab:AddParagraph({
        "Novidades v7.0",
        "• UI Redz Hub\n• CFrame Speed (bypass real)\n• Não modifica WalkSpeed\n• Compatível com Prison Life"
    })
    
    InfoTab:AddParagraph({
        "Créditos",
        "• SAVAGECHEATS Team\n• Redz Hub UI Library\n• tbao143"
    })
end

-- Fallback para Kavo UI
local function CreateKavoUI()
    if not Window then return end
    
    -- AIM Tab
    local AimTab = Window:NewTab("Aimbot")
    local AimSection = AimTab:NewSection("Configurações")
    
    AimSection:NewToggle("Ativar Aimbot", "Liga/desliga aimbot", function(state)
        Config.AimbotEnabled = state
        if state then EnableSilentAim() end
    end)
    
    AimSection:NewToggle("Silent Aim", "Bala mágica", function(state)
        Config.SilentAim = state
    end)
    
    AimSection:NewToggle("Ignorar Paredes", "Mirar através de paredes", function(state)
        Config.IgnoreWalls = state
    end)
    
    AimSection:NewToggle("Mostrar FOV", "Exibir círculo FOV", function(state)
        Config.FOVVisible = state
    end)
    
    AimSection:NewSlider("FOV", "Tamanho do FOV", 500, 50, function(value)
        Config.FOVRadius = value
    end)
    
    AimSection:NewDropdown("Aim Part", "Parte do corpo", {"Head", "HumanoidRootPart", "Torso"}, function(value)
        Config.AimPart = value
    end)
    
    -- ESP Tab
    local ESPTab = Window:NewTab("ESP")
    local ESPSection = ESPTab:NewSection("Configurações")
    
    ESPSection:NewToggle("Ativar ESP", "Mostra jogadores", function(state)
        Config.ESPEnabled = state
    end)
    
    ESPSection:NewToggle("Box", "Caixa ao redor", function(state)
        Config.ESPBox = state
    end)
    
    ESPSection:NewToggle("Nome", "Mostrar nome", function(state)
        Config.ESPName = state
    end)
    
    ESPSection:NewToggle("Vida", "Mostrar HP", function(state)
        Config.ESPHealth = state
    end)
    
    -- MISC Tab
    local MiscTab = Window:NewTab("Misc")
    local MiscSection = MiscTab:NewSection("Funções")
    
    MiscSection:NewToggle("CFrame Speed", "Velocidade via CFrame", function(state)
        Config.CFrameSpeedEnabled = state
        if state then EnableCFrameSpeed() else DisableCFrameSpeed() end
    end)
    
    MiscSection:NewSlider("Speed Mult", "Multiplicador (x10)", 20, 1, function(value)
        Config.CFrameMultiplier = value / 10
    end)
    
    MiscSection:NewToggle("NoClip", "Atravessar paredes", function(state)
        Config.NoClipEnabled = state
        if state then EnableNoClip() else DisableNoClip() end
    end)
    
    MiscSection:NewToggle("Hitbox", "Expandir hitbox", function(state)
        Config.HitboxEnabled = state
        if state then EnableHitbox() else DisableHitbox() end
    end)
    
    MiscSection:NewSlider("Hitbox Size", "Tamanho", 20, 2, function(value)
        Config.HitboxSize = value
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    LOOP PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local MainConnection = nil

local function MainLoop()
    MainConnection = RunService.RenderStepped:Connect(function()
        -- Atualizar alvo
        if Config.AimbotEnabled then
            local target, part = FindTarget()
            
            if target and part then
                State.Target = target
                State.TargetPart = part
                State.Locked = true
                
                -- Mirar se não for silent aim
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
        
        -- Atualizar drawings
        UpdateDrawings()
        
        -- Atualizar ESP
        for player, _ in pairs(ESPObjects) do
            UpdateESP(player)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    DESTRUIR TUDO
-- ═══════════════════════════════════════════════════════════════

local function DestroyAll()
    -- Parar loops
    if MainConnection then MainConnection:Disconnect() end
    
    -- Desconectar eventos
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    -- Desabilitar funções
    DisableSilentAim()
    DisableNoClip()
    DisableHitbox()
    DisableCFrameSpeed()
    
    -- Remover drawings
    DestroyDrawings()
    DestroyESP()
    
    _G.SAVAGE_V7 = nil
    
    print("[SAVAGECHEATS] Script encerrado!")
end

_G.SAVAGE_V7 = true
_G.SAVAGE_V7_CLEANUP = DestroyAll

-- ═══════════════════════════════════════════════════════════════
--                    INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("═══════════════════════════════════════════════════")
    print("       SAVAGECHEATS_ AIMBOT UNIVERSAL v7.0")
    print("═══════════════════════════════════════════════════")
    print("Jogo detectado: " .. GameName)
    
    if IsPrisonLife then
        print("⚠ Prison Life detectado!")
        print("  Use CFrame Speed com valores baixos (0.3-0.5)")
    end
    
    -- Criar UI
    CreateRedzUI()
    
    -- Criar drawings
    CreateDrawings()
    
    -- Inicializar ESP
    InitESP()
    
    -- Iniciar loop principal
    MainLoop()
    
    -- Reconectar ao respawn
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        
        if Config.NoClipEnabled then
            EnableNoClip()
        end
        
        if Config.CFrameSpeedEnabled then
            EnableCFrameSpeed()
        end
        
        if IsPrisonLife then
            NoClipBypassApplied = false
            ApplyPrisonLifeBypass()
        end
    end)
    
    print("═══════════════════════════════════════════════════")
    print("✓ Script carregado com sucesso!")
    print("✓ UI Redz Hub ativada")
    print("✓ CFrame Speed disponível (bypass)")
    print("═══════════════════════════════════════════════════")
end

-- Executar
Initialize()
