--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║              SAVAGECHEATS_ AIMBOT UNIVERSAL v6.0              ║
    ║           UI Completamente Redesenhada para Mobile            ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  CORREÇÕES v6.0:                                              ║
    ║  • UI nova sem bugs de sobreposição                           ║
    ║  • Botão flutuante interativo                                 ║
    ║  • Tiro automático sem cursor/seta na tela                    ║
    ║  • Hitbox funcional                                           ║
    ║  • Speed com bypass para Prison Life                          ║
    ║  • Layout responsivo para todas as telas                      ║
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
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════════════════════════════
--                      VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════════

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Limpar instância anterior
if _G.SAVAGE_V6 then
    pcall(function() _G.SAVAGE_V6:Destroy() end)
    task.wait(0.3)
end

-- Detectar jogo
local GameId = game.PlaceId
local IsPrisonLife = GameId == 155615604 or GameId == 419601093
local GameName = IsPrisonLife and "Prison Life" or "Universal"

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
    AimType = "OnShoot", -- "OnShoot" ou "Always"
    
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
    
    -- Auto Shoot (CORRIGIDO)
    AutoShoot = false,
    ShootDelay = 0.15,
    
    -- NoClip
    NoClipEnabled = false,
    
    -- Hitbox (CORRIGIDO)
    HitboxEnabled = false,
    HitboxSize = 5,
    
    -- Speed (NOVO - com bypass)
    SpeedEnabled = false,
    SpeedValue = 32,
    
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
    UIVisible = true,
    Dragging = false,
    LastShot = 0,
}

local Connections = {}
local ESPObjects = {}

-- ═══════════════════════════════════════════════════════════════
--                      CORES DO TEMA
-- ═══════════════════════════════════════════════════════════════

local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Secondary = Color3.fromRGB(25, 25, 25),
    Accent = Color3.fromRGB(200, 35, 35),
    AccentDark = Color3.fromRGB(150, 25, 25),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(50, 200, 50),
    Border = Color3.fromRGB(60, 60, 60),
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
    if not position or State.Dragging then return end
    
    local camPos = Camera.CFrame.Position
    local targetCF = CFrame.lookAt(camPos, position)
    
    if Config.Smoothness > 0 then
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 - Config.Smoothness)
    else
        Camera.CFrame = targetCF
    end
end

-- ═══════════════════════════════════════════════════════════════
--              SISTEMA DE DISPARO AUTOMÁTICO (CORRIGIDO)
-- ═══════════════════════════════════════════════════════════════
--[[
    CORREÇÃO: Não usa mais mouse1press que causa cursor na tela
    Usa método de Remote ou simula input sem bloquear movimento
]]

local ShootingInProgress = false

local function TryAutoShoot()
    if not Config.AutoShoot then return end
    if not Config.AimbotEnabled then return end
    if not State.Locked or not State.Target then return end
    if ShootingInProgress then return end
    
    local now = tick()
    if now - State.LastShot < Config.ShootDelay then return end
    
    State.LastShot = now
    ShootingInProgress = true
    
    -- Método 1: Tentar usar firetouchinterest (mais compatível)
    task.spawn(function()
        pcall(function()
            -- Procurar ferramenta equipada
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                -- Tentar ativar a ferramenta
                local remote = tool:FindFirstChildOfClass("RemoteEvent") or 
                              tool:FindFirstChildOfClass("RemoteFunction")
                if remote then
                    -- Disparar evento de tiro se encontrado
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer()
                    end
                end
            end
        end)
        
        task.wait(0.05)
        ShootingInProgress = false
    end)
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
        -- Remover script de colisão
        local scripts = ReplicatedStorage:FindFirstChild("Scripts")
        if scripts then
            local collision = scripts:FindFirstChild("CharacterCollision")
            if collision then collision:Destroy() end
        end
        
        -- Desabilitar conexões de CanCollide
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
--              HITBOX EXPANDER (CORRIGIDO)
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
                    -- Salvar tamanho original
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
    
    -- Restaurar tamanhos
    Config.HitboxEnabled = false
    UpdateHitboxes()
    OriginalSizes = {}
end

-- ═══════════════════════════════════════════════════════════════
--              SPEED COM BYPASS (NOVO)
-- ═══════════════════════════════════════════════════════════════

local SpeedBypassHooked = false
local SpeedConnection = nil
local OldSpeedIndex = nil

local function EnableSpeedBypass()
    if SpeedBypassHooked then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        local oldReadonly = isreadonly(mt)
        setreadonly(mt, false)
        
        OldSpeedIndex = OldSpeedIndex or mt.__index
        
        -- Hook para retornar velocidade normal quando verificado
        local originalIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "WalkSpeed" and typeof(self) == "Instance" and self:IsA("Humanoid") then
                if self.Parent == LocalPlayer.Character then
                    return 16 -- Retorna valor normal para anti-cheat
                end
            end
            return originalIndex(self, key)
        end)
        
        setreadonly(mt, oldReadonly)
        SpeedBypassHooked = true
    end)
    
    -- Loop para manter velocidade
    if not SpeedConnection then
        SpeedConnection = RunService.Heartbeat:Connect(function()
            if Config.SpeedEnabled then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.WalkSpeed = Config.SpeedValue
                    end
                end
            end
        end)
    end
end

local function DisableSpeed()
    Config.SpeedEnabled = false
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
        end
    end
    
    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
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
        FOVCircle.Color = Theme.Accent
        
        AimLine = Drawing.new("Line")
        AimLine.Thickness = 2
        AimLine.Color = Theme.Success
        AimLine.Visible = false
        AimLine.ZIndex = 998
    end)
end

local function UpdateDrawings()
    if FOVCircle then
        FOVCircle.Position = GetScreenCenter()
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Visible = Config.FOVVisible and Config.AimbotEnabled
        FOVCircle.Color = State.Locked and Theme.Success or Theme.Accent
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
    
    local color = IsSameTeam(player) and Theme.Success or Theme.Accent
    
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
--            NOVA UI - COMPLETAMENTE REDESENHADA
-- ═══════════════════════════════════════════════════════════════
--[[
    CORREÇÕES:
    - Usa Scale ao invés de Offset para responsividade
    - Botão flutuante separado
    - Sem sobreposição de elementos
    - ClipsDescendants em todos os containers
    - Tamanho máximo limitado
    - ScrollingFrame para conteúdo
]]

local ScreenGui = nil
local MainFrame = nil
local FloatingButton = nil
local CurrentTab = "AIM"

-- Função para criar cantos arredondados
local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

-- Função para criar stroke
local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

-- Sistema de arraste otimizado para mobile
local function MakeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            State.Dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            task.delay(0.1, function() State.Dragging = false end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Criar Toggle/Checkbox
local function CreateToggle(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. text
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -20, 0, 35)
    container.LayoutOrder = #parent:GetChildren()
    
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Parent = container
    toggleBg.BackgroundColor3 = default and Theme.Accent or Theme.Secondary
    toggleBg.Position = UDim2.new(1, -50, 0.5, -12)
    toggleBg.Size = UDim2.new(0, 50, 0, 24)
    AddCorner(toggleBg, 12)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Parent = toggleBg
    toggleCircle.BackgroundColor3 = Theme.Text
    toggleCircle.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    toggleCircle.Size = UDim2.new(0, 20, 0, 20)
    AddCorner(toggleCircle, 10)
    
    local enabled = default
    
    local button = Instance.new("TextButton")
    button.Parent = container
    button.BackgroundTransparency = 1
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Text = ""
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        local targetPos = enabled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        local targetColor = enabled and Theme.Accent or Theme.Secondary
        
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        
        if callback then callback(enabled) end
    end)
    
    return container
end

-- Criar Slider
local function CreateSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. text
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -20, 0, 50)
    container.LayoutOrder = #parent:GetChildren()
    
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = container
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.Size = UDim2.new(0.4, 0, 0, 20)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Parent = container
    sliderBg.BackgroundColor3 = Theme.Secondary
    sliderBg.Position = UDim2.new(0, 0, 0, 28)
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    AddCorner(sliderBg, 4)
    
    local pct = (default - min) / (max - min)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = Theme.Accent
    sliderFill.Size = UDim2.new(pct, 0, 1, 0)
    AddCorner(sliderFill, 4)
    
    local dragging = false
    
    local function updateSlider(inputPos)
        local relX = math.clamp((inputPos.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * relX)
        
        sliderFill.Size = UDim2.new(relX, 0, 1, 0)
        valueLabel.Text = tostring(value)
        
        if callback then callback(value) end
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            State.Dragging = true
            updateSlider(input.Position)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            task.delay(0.1, function() State.Dragging = false end)
        end
    end)
    
    return container
end

-- Criar Dropdown
local function CreateDropdown(parent, text, options, default, callback)
    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. text
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -20, 0, 35)
    container.ClipsDescendants = false
    container.LayoutOrder = #parent:GetChildren()
    container.ZIndex = 10
    
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 10
    
    local dropBtn = Instance.new("TextButton")
    dropBtn.Parent = container
    dropBtn.BackgroundColor3 = Theme.Secondary
    dropBtn.Position = UDim2.new(0.4, 5, 0, 2)
    dropBtn.Size = UDim2.new(0.6, -5, 0, 30)
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.Text = "  " .. (default or options[1])
    dropBtn.TextColor3 = Theme.Text
    dropBtn.TextSize = 12
    dropBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropBtn.ZIndex = 11
    AddCorner(dropBtn, 4)
    AddStroke(dropBtn, Theme.Border)
    
    local arrow = Instance.new("TextLabel")
    arrow.Parent = dropBtn
    arrow.BackgroundTransparency = 1
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Font = Enum.Font.GothamBold
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.Accent
    arrow.TextSize = 10
    arrow.ZIndex = 12
    
    local listFrame = Instance.new("Frame")
    listFrame.Parent = container
    listFrame.BackgroundColor3 = Theme.Secondary
    listFrame.Position = UDim2.new(0.4, 5, 1, 5)
    listFrame.Size = UDim2.new(0.6, -5, 0, #options * 28)
    listFrame.Visible = false
    listFrame.ZIndex = 100
    listFrame.ClipsDescendants = true
    AddCorner(listFrame, 4)
    AddStroke(listFrame, Theme.Accent)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listFrame
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local isOpen = false
    
    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Parent = listFrame
        optBtn.BackgroundColor3 = Theme.Secondary
        optBtn.BackgroundTransparency = 0
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.Font = Enum.Font.Gotham
        optBtn.Text = "  " .. opt
        optBtn.TextColor3 = Theme.Text
        optBtn.TextSize = 12
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.ZIndex = 101
        optBtn.LayoutOrder = i
        
        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundColor3 = Theme.Accent
        end)
        
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundColor3 = Theme.Secondary
        end)
        
        optBtn.MouseButton1Click:Connect(function()
            dropBtn.Text = "  " .. opt
            listFrame.Visible = false
            isOpen = false
            arrow.Text = "▼"
            if callback then callback(opt) end
        end)
    end
    
    dropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        listFrame.Visible = isOpen
        arrow.Text = isOpen and "▲" or "▼"
    end)
    
    return container
end

-- Criar Separador
local function CreateSeparator(parent)
    local sep = Instance.new("Frame")
    sep.Parent = parent
    sep.BackgroundColor3 = Theme.Accent
    sep.Size = UDim2.new(1, -20, 0, 1)
    sep.LayoutOrder = #parent:GetChildren()
    return sep
end

-- Criar Label/Título
local function CreateLabel(parent, text, isTitle)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -20, 0, isTitle and 30 or 20)
    label.Font = isTitle and Enum.Font.GothamBold or Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = isTitle and Theme.Accent or Theme.TextDim
    label.TextSize = isTitle and 16 or 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = #parent:GetChildren()
    return label
end


-- ═══════════════════════════════════════════════════════════════
--                    CRIAR UI PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local function CreateUI()
    -- Criar ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SAVAGECHEATS_v6"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    _G.SAVAGE_V6 = ScreenGui
    
    -- ═══════════════════════════════════════════════════════════
    --              BOTÃO FLUTUANTE (NOVO)
    -- ═══════════════════════════════════════════════════════════
    
    FloatingButton = Instance.new("ImageButton")
    FloatingButton.Name = "FloatingButton"
    FloatingButton.Parent = ScreenGui
    FloatingButton.BackgroundColor3 = Theme.Accent
    FloatingButton.Position = UDim2.new(0, 15, 0.5, -25)
    FloatingButton.Size = UDim2.new(0, 50, 0, 50)
    FloatingButton.Image = ""
    FloatingButton.AutoButtonColor = false
    AddCorner(FloatingButton, 25)
    AddStroke(FloatingButton, Theme.AccentDark, 2)
    
    local floatIcon = Instance.new("TextLabel")
    floatIcon.Parent = FloatingButton
    floatIcon.BackgroundTransparency = 1
    floatIcon.Size = UDim2.new(1, 0, 1, 0)
    floatIcon.Font = Enum.Font.GothamBold
    floatIcon.Text = "S"
    floatIcon.TextColor3 = Theme.Text
    floatIcon.TextSize = 24
    
    MakeDraggable(FloatingButton)
    
    FloatingButton.MouseButton1Click:Connect(function()
        State.UIVisible = not State.UIVisible
        MainFrame.Visible = State.UIVisible
        
        -- Animação do botão
        TweenService:Create(FloatingButton, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 45, 0, 45)
        }):Play()
        task.wait(0.1)
        TweenService:Create(FloatingButton, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 50, 0, 50)
        }):Play()
    end)
    
    -- ═══════════════════════════════════════════════════════════
    --                    FRAME PRINCIPAL
    -- ═══════════════════════════════════════════════════════════
    
    -- Calcular tamanho responsivo
    local screenSize = Camera.ViewportSize
    local maxWidth = math.min(340, screenSize.X - 40)
    local maxHeight = math.min(450, screenSize.Y - 100)
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.Position = UDim2.new(0.5, -maxWidth/2, 0.5, -maxHeight/2)
    MainFrame.Size = UDim2.new(0, maxWidth, 0, maxHeight)
    MainFrame.ClipsDescendants = true
    AddCorner(MainFrame, 10)
    AddStroke(MainFrame, Theme.Accent, 2)
    
    -- Barra de título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = MainFrame
    titleBar.BackgroundColor3 = Theme.Secondary
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.ClipsDescendants = true
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Remover cantos inferiores do título
    local titleFix = Instance.new("Frame")
    titleFix.Parent = titleBar
    titleFix.BackgroundColor3 = Theme.Secondary
    titleFix.Position = UDim2.new(0, 0, 1, -10)
    titleFix.Size = UDim2.new(1, 0, 0, 10)
    titleFix.BorderSizePixel = 0
    
    local titleText = Instance.new("TextLabel")
    titleText.Parent = titleBar
    titleText.BackgroundTransparency = 1
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.Size = UDim2.new(1, -60, 1, 0)
    titleText.Font = Enum.Font.GothamBold
    titleText.Text = "SAVAGECHEATS v6"
    titleText.TextColor3 = Theme.Accent
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = titleBar
    closeBtn.BackgroundColor3 = Theme.Accent
    closeBtn.Position = UDim2.new(1, -35, 0.5, -12)
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.TextSize = 18
    AddCorner(closeBtn, 4)
    
    closeBtn.MouseButton1Click:Connect(function()
        State.UIVisible = false
        MainFrame.Visible = false
    end)
    
    MakeDraggable(titleBar)
    
    -- ═══════════════════════════════════════════════════════════
    --                    CONTAINER DE ABAS
    -- ═══════════════════════════════════════════════════════════
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Parent = MainFrame
    tabContainer.BackgroundColor3 = Theme.Secondary
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.Size = UDim2.new(1, 0, 0, 35)
    tabContainer.ClipsDescendants = true
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = tabContainer
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local tabs = {"AIM", "ESP", "MISC", "INFO"}
    local tabButtons = {}
    local tabContents = {}
    
    local tabWidth = 1 / #tabs
    
    for i, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. tabName
        tabBtn.Parent = tabContainer
        tabBtn.BackgroundColor3 = i == 1 and Theme.Accent or Theme.Secondary
        tabBtn.BackgroundTransparency = i == 1 and 0 or 0.5
        tabBtn.Size = UDim2.new(tabWidth, 0, 1, 0)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Theme.Text
        tabBtn.TextSize = 12
        tabBtn.LayoutOrder = i
        
        tabButtons[tabName] = tabBtn
        
        -- Conteúdo da aba
        local content = Instance.new("ScrollingFrame")
        content.Name = "Content_" .. tabName
        content.Parent = MainFrame
        content.BackgroundTransparency = 1
        content.Position = UDim2.new(0, 10, 0, 80)
        content.Size = UDim2.new(1, -20, 1, -90)
        content.ScrollBarThickness = 4
        content.ScrollBarImageColor3 = Theme.Accent
        content.Visible = i == 1
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.ClipsDescendants = true
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Parent = content
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 8)
        
        local contentPadding = Instance.new("UIPadding")
        contentPadding.Parent = content
        contentPadding.PaddingTop = UDim.new(0, 5)
        contentPadding.PaddingBottom = UDim.new(0, 10)
        
        tabContents[tabName] = content
        
        tabBtn.MouseButton1Click:Connect(function()
            CurrentTab = tabName
            
            for name, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = name == tabName and Theme.Accent or Theme.Secondary
                btn.BackgroundTransparency = name == tabName and 0 or 0.5
            end
            
            for name, cont in pairs(tabContents) do
                cont.Visible = name == tabName
            end
        end)
    end
    
    -- ═══════════════════════════════════════════════════════════
    --                    CONTEÚDO ABA AIM
    -- ═══════════════════════════════════════════════════════════
    
    local aimContent = tabContents["AIM"]
    
    CreateToggle(aimContent, "Ativar Aimbot", Config.AimbotEnabled, function(v)
        Config.AimbotEnabled = v
    end)
    
    CreateToggle(aimContent, "Silent Aim (Bala Mágica)", Config.SilentAim, function(v)
        Config.SilentAim = v
        if v then EnableSilentAim() else DisableSilentAim() end
    end)
    
    CreateToggle(aimContent, "Ignorar Paredes", Config.IgnoreWalls, function(v)
        Config.IgnoreWalls = v
    end)
    
    CreateToggle(aimContent, "Mostrar FOV", Config.FOVVisible, function(v)
        Config.FOVVisible = v
    end)
    
    CreateToggle(aimContent, "Mostrar Linha", Config.ShowLine, function(v)
        Config.ShowLine = v
    end)
    
    CreateSeparator(aimContent)
    
    CreateSlider(aimContent, "FOV", 50, 500, Config.FOVRadius, function(v)
        Config.FOVRadius = v
    end)
    
    CreateSlider(aimContent, "Suavização", 0, 95, math.floor(Config.Smoothness * 100), function(v)
        Config.Smoothness = v / 100
    end)
    
    CreateSeparator(aimContent)
    
    CreateDropdown(aimContent, "Parte Alvo", {"Head", "HumanoidRootPart", "Torso"}, Config.AimPart, function(v)
        Config.AimPart = v
    end)
    
    CreateDropdown(aimContent, "Tipo", {"OnShoot", "Always"}, Config.AimType, function(v)
        Config.AimType = v
    end)
    
    -- ═══════════════════════════════════════════════════════════
    --                    CONTEÚDO ABA ESP
    -- ═══════════════════════════════════════════════════════════
    
    local espContent = tabContents["ESP"]
    
    CreateToggle(espContent, "Ativar ESP", Config.ESPEnabled, function(v)
        Config.ESPEnabled = v
    end)
    
    CreateToggle(espContent, "Mostrar Box", Config.ESPBox, function(v)
        Config.ESPBox = v
    end)
    
    CreateToggle(espContent, "Mostrar Nome", Config.ESPName, function(v)
        Config.ESPName = v
    end)
    
    CreateToggle(espContent, "Mostrar Vida", Config.ESPHealth, function(v)
        Config.ESPHealth = v
    end)
    
    CreateToggle(espContent, "Mostrar Distância", Config.ESPDistance, function(v)
        Config.ESPDistance = v
    end)
    
    CreateSeparator(espContent)
    
    CreateToggle(espContent, "Verificar Time", Config.TeamCheck, function(v)
        Config.TeamCheck = v
    end)
    
    -- ═══════════════════════════════════════════════════════════
    --                    CONTEÚDO ABA MISC
    -- ═══════════════════════════════════════════════════════════
    
    local miscContent = tabContents["MISC"]
    
    -- Aviso Prison Life
    if IsPrisonLife then
        CreateLabel(miscContent, "⚠ Prison Life Detectado!", true)
        CreateLabel(miscContent, "Bypass automático será aplicado")
        CreateSeparator(miscContent)
    end
    
    CreateLabel(miscContent, "MOVIMENTO", true)
    
    CreateToggle(miscContent, "NoClip", Config.NoClipEnabled, function(v)
        Config.NoClipEnabled = v
        if v then EnableNoClip() else DisableNoClip() end
    end)
    
    CreateToggle(miscContent, "Speed Hack", Config.SpeedEnabled, function(v)
        Config.SpeedEnabled = v
        if v then EnableSpeedBypass() else DisableSpeed() end
    end)
    
    CreateSlider(miscContent, "Velocidade", 16, 150, Config.SpeedValue, function(v)
        Config.SpeedValue = v
    end)
    
    CreateSeparator(miscContent)
    CreateLabel(miscContent, "COMBATE", true)
    
    CreateToggle(miscContent, "Hitbox Expander", Config.HitboxEnabled, function(v)
        Config.HitboxEnabled = v
        if v then EnableHitbox() else DisableHitbox() end
    end)
    
    CreateSlider(miscContent, "Tamanho Hitbox", 3, 20, Config.HitboxSize, function(v)
        Config.HitboxSize = v
    end)
    
    CreateSeparator(miscContent)
    
    CreateToggle(miscContent, "Auto Shoot", Config.AutoShoot, function(v)
        Config.AutoShoot = v
    end)
    
    CreateSlider(miscContent, "Delay (ms)", 50, 500, math.floor(Config.ShootDelay * 1000), function(v)
        Config.ShootDelay = v / 1000
    end)
    
    -- ═══════════════════════════════════════════════════════════
    --                    CONTEÚDO ABA INFO
    -- ═══════════════════════════════════════════════════════════
    
    local infoContent = tabContents["INFO"]
    
    CreateLabel(infoContent, "SAVAGECHEATS v6.0", true)
    CreateLabel(infoContent, "Aimbot Universal Mobile")
    CreateSeparator(infoContent)
    
    CreateLabel(infoContent, "NOVIDADES v6:", true)
    CreateLabel(infoContent, "• UI completamente nova")
    CreateLabel(infoContent, "• Botão flutuante arrastável")
    CreateLabel(infoContent, "• Sem bugs de sobreposição")
    CreateLabel(infoContent, "• Tiro automático corrigido")
    CreateLabel(infoContent, "• Hitbox funcional")
    CreateLabel(infoContent, "• Speed com bypass")
    
    CreateSeparator(infoContent)
    CreateLabel(infoContent, "Jogo: " .. GameName, false)
    
    CreateSeparator(infoContent)
    
    local destroyBtn = Instance.new("TextButton")
    destroyBtn.Parent = infoContent
    destroyBtn.BackgroundColor3 = Theme.Accent
    destroyBtn.Size = UDim2.new(1, -20, 0, 40)
    destroyBtn.Font = Enum.Font.GothamBold
    destroyBtn.Text = "FECHAR SCRIPT"
    destroyBtn.TextColor3 = Theme.Text
    destroyBtn.TextSize = 14
    destroyBtn.LayoutOrder = 999
    AddCorner(destroyBtn, 6)
    
    destroyBtn.MouseButton1Click:Connect(function()
        DestroyAll()
    end)
    
    return ScreenGui
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
                
                -- Mirar se tipo for "Always"
                if Config.AimType == "Always" and not Config.SilentAim then
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
--                    INPUT HANDLER
-- ═══════════════════════════════════════════════════════════════

local function SetupInput()
    -- Detectar quando está atirando (para aimbot "OnShoot")
    Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        -- Mouse click ou toque
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            
            if Config.AimbotEnabled and Config.AimType == "OnShoot" then
                if State.Locked and State.TargetPart and not Config.SilentAim then
                    AimAt(State.TargetPart.Position)
                end
            end
            
            -- Auto shoot
            TryAutoShoot()
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    DESTRUIR TUDO
-- ═══════════════════════════════════════════════════════════════

function DestroyAll()
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
    DisableSpeed()
    
    -- Remover drawings
    DestroyDrawings()
    DestroyESP()
    
    -- Remover UI
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    _G.SAVAGE_V6 = nil
    
    print("[SAVAGECHEATS] Script encerrado!")
end

-- ═══════════════════════════════════════════════════════════════
--                    INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("═══════════════════════════════════════════════════")
    print("       SAVAGECHEATS_ AIMBOT UNIVERSAL v6.0")
    print("═══════════════════════════════════════════════════")
    print("Jogo detectado: " .. GameName)
    
    if IsPrisonLife then
        print("⚠ Prison Life detectado - Bypass será aplicado!")
    end
    
    -- Criar UI
    CreateUI()
    
    -- Criar drawings
    CreateDrawings()
    
    -- Inicializar ESP
    InitESP()
    
    -- Configurar input
    SetupInput()
    
    -- Iniciar loop principal
    MainLoop()
    
    -- Reconectar ao respawn
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        
        if Config.NoClipEnabled then
            EnableNoClip()
        end
        
        if Config.SpeedEnabled then
            EnableSpeedBypass()
        end
        
        if IsPrisonLife then
            NoClipBypassApplied = false
            ApplyPrisonLifeBypass()
        end
    end)
    
    print("═══════════════════════════════════════════════════")
    print("✓ Script carregado com sucesso!")
    print("✓ Arraste o botão vermelho para mover")
    print("✓ Clique no botão para abrir/fechar menu")
    print("═══════════════════════════════════════════════════")
end

-- Executar
Initialize()
