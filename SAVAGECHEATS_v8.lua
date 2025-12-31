--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║              SAVAGECHEATS_ AIMBOT UNIVERSAL v8.0              ║
    ║           UI PRÓPRIA COMPLETA - SEM DEPENDÊNCIAS              ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  • UI 100% própria (não depende de libs externas)             ║
    ║  • Design baseado na referência (vermelho/preto)              ║
    ║  • Botão flutuante arrastável                                 ║
    ║  • CFrame Speed (bypass real)                                 ║
    ║  • Compatível com Mobile                                      ║
    ╚═══════════════════════════════════════════════════════════════╝
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
if _G.SAVAGE_V8 then
    pcall(function() _G.SAVAGE_V8_CLEANUP() end)
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
    
    -- CFrame Speed
    CFrameSpeedEnabled = false,
    CFrameMultiplier = 0.5,
    
    -- Misc
    ShowLine = false,
    MaxDistance = 1000,
}

local State = {
    Target = nil,
    TargetPart = nil,
    Locked = false,
}

local Connections = {}
local ESPObjects = {}

-- ═══════════════════════════════════════════════════════════════
--                         CORES DO TEMA
-- ═══════════════════════════════════════════════════════════════

local Theme = {
    Primary = Color3.fromRGB(200, 30, 30),      -- Vermelho
    Secondary = Color3.fromRGB(25, 25, 25),     -- Preto escuro
    Background = Color3.fromRGB(15, 15, 15),    -- Fundo
    Surface = Color3.fromRGB(35, 35, 35),       -- Superfície
    Text = Color3.fromRGB(255, 255, 255),       -- Texto branco
    TextDim = Color3.fromRGB(180, 180, 180),    -- Texto cinza
    Success = Color3.fromRGB(50, 200, 50),      -- Verde
    Border = Color3.fromRGB(60, 60, 60),        -- Borda
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
--                    SILENT AIM
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
        if OldIndex then mt.__index = OldIndex end
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
--                    HITBOX
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
                    else
                        root.Size = OriginalSizes[player] or Vector3.new(2, 2, 1)
                        root.Transparency = 1
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

local CFrameSpeedConnection = nil

local function EnableCFrameSpeed()
    if CFrameSpeedConnection then return end
    
    CFrameSpeedConnection = RunService.Stepped:Connect(function()
        if not Config.CFrameSpeedEnabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + hum.MoveDirection * Config.CFrameMultiplier
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
--                    FOV CIRCLE
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
        FOVCircle.Color = Theme.Primary
        
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
end

local function DestroyDrawings()
    pcall(function()
        if FOVCircle then FOVCircle:Remove() FOVCircle = nil end
        if AimLine then AimLine:Remove() AimLine = nil end
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
    local color = IsSameTeam(player) and Theme.Success or Theme.Primary
    
    if Config.ESPBox then
        esp.Box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Color = color
        esp.Box.Visible = true
    else
        esp.Box.Visible = false
    end
    
    if Config.ESPName then
        esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 16)
        esp.Name.Text = player.Name
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
--                    UI PRÓPRIA COMPLETA
-- ═══════════════════════════════════════════════════════════════

local ScreenGui = nil
local MainFrame = nil
local FloatButton = nil
local CurrentTab = "AIM"
local UIVisible = false

-- Função para criar cantos arredondados
local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

-- Função para criar stroke (borda)
local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

-- Função para criar toggle
local function CreateToggle(parent, name, default, callback)
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(1, -10, 0, 35)
    container.BackgroundColor3 = Theme.Surface
    container.BorderSizePixel = 0
    container.Parent = parent
    AddCorner(container, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 44, 0, 22)
    toggleBg.Position = UDim2.new(1, -54, 0.5, -11)
    toggleBg.BackgroundColor3 = default and Theme.Primary or Theme.Border
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = container
    AddCorner(toggleBg, 11)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 18, 0, 18)
    toggleCircle.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    toggleCircle.BackgroundColor3 = Theme.Text
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleBg
    AddCorner(toggleCircle, 9)
    
    local enabled = default
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = container
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        local targetPos = enabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local targetColor = enabled and Theme.Primary or Theme.Border
        
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        
        if callback then callback(enabled) end
    end)
    
    return container
end

-- Função para criar slider
local function CreateSlider(parent, name, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(1, -10, 0, 55)
    container.BackgroundColor3 = Theme.Surface
    container.BorderSizePixel = 0
    container.Parent = parent
    AddCorner(container, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -60, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Theme.Primary
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 8)
    sliderBg.Position = UDim2.new(0, 10, 0, 35)
    sliderBg.BackgroundColor3 = Theme.Border
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    AddCorner(sliderBg, 4)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Theme.Primary
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    AddCorner(sliderFill, 4)
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(1, 0, 1, 10)
    sliderButton.Position = UDim2.new(0, 0, 0, -5)
    sliderButton.BackgroundTransparency = 1
    sliderButton.Text = ""
    sliderButton.Parent = sliderBg
    
    local dragging = false
    
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = tostring(value)
        
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

-- Função para criar dropdown
local function CreateDropdown(parent, name, options, default, callback)
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(1, -10, 0, 35)
    container.BackgroundColor3 = Theme.Surface
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = parent
    AddCorner(container, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -10, 0, 35)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(0.5, -30, 0, 35)
    selectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = default
    selectedLabel.TextColor3 = Theme.Primary
    selectedLabel.TextSize = 13
    selectedLabel.Font = Enum.Font.GothamBold
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
    selectedLabel.Parent = container
    
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 35)
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.Primary
    arrow.TextSize = 10
    arrow.Font = Enum.Font.Gotham
    arrow.Parent = container
    
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(1, 0, 0, #options * 30)
    optionsFrame.Position = UDim2.new(0, 0, 0, 35)
    optionsFrame.BackgroundColor3 = Theme.Background
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    optionsFrame.Parent = container
    
    local optionsList = Instance.new("UIListLayout")
    optionsList.SortOrder = Enum.SortOrder.LayoutOrder
    optionsList.Parent = optionsFrame
    
    local expanded = false
    
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 30)
        optBtn.BackgroundColor3 = Theme.Surface
        optBtn.BackgroundTransparency = 0.5
        optBtn.Text = option
        optBtn.TextColor3 = Theme.Text
        optBtn.TextSize = 12
        optBtn.Font = Enum.Font.Gotham
        optBtn.BorderSizePixel = 0
        optBtn.Parent = optionsFrame
        
        optBtn.MouseButton1Click:Connect(function()
            selectedLabel.Text = option
            expanded = false
            optionsFrame.Visible = false
            container.Size = UDim2.new(1, -10, 0, 35)
            arrow.Text = "▼"
            if callback then callback(option) end
        end)
    end
    
    local mainButton = Instance.new("TextButton")
    mainButton.Size = UDim2.new(1, 0, 0, 35)
    mainButton.BackgroundTransparency = 1
    mainButton.Text = ""
    mainButton.Parent = container
    
    mainButton.MouseButton1Click:Connect(function()
        expanded = not expanded
        optionsFrame.Visible = expanded
        container.Size = expanded and UDim2.new(1, -10, 0, 35 + #options * 30) or UDim2.new(1, -10, 0, 35)
        arrow.Text = expanded and "▲" or "▼"
    end)
    
    return container
end

-- Função para criar seção
local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -10, 0, 25)
    section.BackgroundTransparency = 1
    section.Parent = parent
    
    local line1 = Instance.new("Frame")
    line1.Size = UDim2.new(0.3, 0, 0, 1)
    line1.Position = UDim2.new(0, 0, 0.5, 0)
    line1.BackgroundColor3 = Theme.Primary
    line1.BorderSizePixel = 0
    line1.Parent = section
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0.3, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Theme.Primary
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.Parent = section
    
    local line2 = Instance.new("Frame")
    line2.Size = UDim2.new(0.3, 0, 0, 1)
    line2.Position = UDim2.new(0.7, 0, 0.5, 0)
    line2.BackgroundColor3 = Theme.Primary
    line2.BorderSizePixel = 0
    line2.Parent = section
    
    return section
end

-- Criar UI Principal
local function CreateUI()
    -- ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SAVAGECHEATS_V8"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Botão Flutuante
    FloatButton = Instance.new("TextButton")
    FloatButton.Name = "FloatButton"
    FloatButton.Size = UDim2.new(0, 50, 0, 50)
    FloatButton.Position = UDim2.new(0, 20, 0.5, -25)
    FloatButton.BackgroundColor3 = Theme.Primary
    FloatButton.Text = "S"
    FloatButton.TextColor3 = Theme.Text
    FloatButton.TextSize = 24
    FloatButton.Font = Enum.Font.GothamBold
    FloatButton.BorderSizePixel = 0
    FloatButton.Parent = ScreenGui
    AddCorner(FloatButton, 25)
    AddStroke(FloatButton, Theme.Text, 2)
    
    -- Arrastar botão flutuante
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
    
    -- Toggle UI ao clicar
    FloatButton.MouseButton1Click:Connect(function()
        UIVisible = not UIVisible
        MainFrame.Visible = UIVisible
    end)
    
    -- Frame Principal
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    AddCorner(MainFrame, 10)
    AddStroke(MainFrame, Theme.Primary, 2)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = Theme.Secondary
    header.BorderSizePixel = 0
    header.Parent = MainFrame
    AddCorner(header, 10)
    
    -- Fix corner inferior do header
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 15)
    headerFix.Position = UDim2.new(0, 0, 1, -15)
    headerFix.BackgroundColor3 = Theme.Secondary
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SAVAGECHEATS v8.0"
    title.TextColor3 = Theme.Text
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -38, 0.5, -15)
    closeBtn.BackgroundColor3 = Theme.Primary
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    AddCorner(closeBtn, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        UIVisible = false
        MainFrame.Visible = false
    end)
    
    -- Tabs Container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(1, -20, 0, 35)
    tabsContainer.Position = UDim2.new(0, 10, 0, 50)
    tabsContainer.BackgroundColor3 = Theme.Secondary
    tabsContainer.BorderSizePixel = 0
    tabsContainer.Parent = MainFrame
    AddCorner(tabsContainer, 6)
    
    local tabsList = Instance.new("UIListLayout")
    tabsList.FillDirection = Enum.FillDirection.Horizontal
    tabsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabsList.Padding = UDim.new(0, 5)
    tabsList.Parent = tabsContainer
    
    -- Content Container
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Size = UDim2.new(1, -20, 1, -100)
    contentContainer.Position = UDim2.new(0, 10, 0, 90)
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.ScrollBarThickness = 4
    contentContainer.ScrollBarImageColor3 = Theme.Primary
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentContainer.Parent = MainFrame
    
    local contentList = Instance.new("UIListLayout")
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.Padding = UDim.new(0, 8)
    contentList.Parent = contentContainer
    
    -- Auto-ajustar canvas
    contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentContainer.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 10)
    end)
    
    -- Tabs e conteúdos
    local tabs = {"AIM", "ESP", "MISC", "INFO"}
    local tabButtons = {}
    local tabContents = {}
    
    -- Criar conteúdo de cada tab
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
        contentLayout.Padding = UDim.new(0, 6)
        contentLayout.Parent = content
        
        tabContents[tabName] = content
    end
    
    -- Criar botões de tab
    for _, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 65, 0, 28)
        tabBtn.BackgroundColor3 = tabName == "AIM" and Theme.Primary or Theme.Surface
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Theme.Text
        tabBtn.TextSize = 12
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabsContainer
        AddCorner(tabBtn, 6)
        
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
    --                    CONTEÚDO ABA AIM
    -- ═══════════════════════════════════════════════════════════════
    
    local aimContent = tabContents["AIM"]
    
    CreateToggle(aimContent, "Ativar Aimbot", false, function(v)
        Config.AimbotEnabled = v
        if v then EnableSilentAim() end
    end)
    
    CreateToggle(aimContent, "Silent Aim (Bala Mágica)", false, function(v)
        Config.SilentAim = v
    end)
    
    CreateToggle(aimContent, "Ignorar Paredes", false, function(v)
        Config.IgnoreWalls = v
    end)
    
    CreateToggle(aimContent, "Mostrar FOV", true, function(v)
        Config.FOVVisible = v
    end)
    
    CreateToggle(aimContent, "Mostrar Linha", false, function(v)
        Config.ShowLine = v
    end)
    
    CreateSlider(aimContent, "Tamanho FOV", 50, 400, 150, function(v)
        Config.FOVRadius = v
    end)
    
    CreateSlider(aimContent, "Suavização", 0, 100, 30, function(v)
        Config.Smoothness = v / 100
    end)
    
    CreateDropdown(aimContent, "Parte do Corpo", {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}, "Head", function(v)
        Config.AimPart = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    CONTEÚDO ABA ESP
    -- ═══════════════════════════════════════════════════════════════
    
    local espContent = tabContents["ESP"]
    
    CreateToggle(espContent, "Ativar ESP", false, function(v)
        Config.ESPEnabled = v
    end)
    
    CreateToggle(espContent, "Box", true, function(v)
        Config.ESPBox = v
    end)
    
    CreateToggle(espContent, "Nome", true, function(v)
        Config.ESPName = v
    end)
    
    CreateToggle(espContent, "Vida", true, function(v)
        Config.ESPHealth = v
    end)
    
    CreateToggle(espContent, "Distância", true, function(v)
        Config.ESPDistance = v
    end)
    
    CreateToggle(espContent, "Verificar Time", true, function(v)
        Config.TeamCheck = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    CONTEÚDO ABA MISC
    -- ═══════════════════════════════════════════════════════════════
    
    local miscContent = tabContents["MISC"]
    
    CreateSection(miscContent, "CFrame Speed")
    
    if IsPrisonLife then
        local warning = Instance.new("TextLabel")
        warning.Size = UDim2.new(1, -10, 0, 40)
        warning.BackgroundColor3 = Color3.fromRGB(80, 40, 0)
        warning.Text = "⚠ Prison Life: Use valores 3-5!"
        warning.TextColor3 = Color3.fromRGB(255, 200, 100)
        warning.TextSize = 12
        warning.Font = Enum.Font.GothamBold
        warning.TextWrapped = true
        warning.BorderSizePixel = 0
        warning.Parent = miscContent
        AddCorner(warning, 6)
    end
    
    CreateToggle(miscContent, "CFrame Speed", false, function(v)
        Config.CFrameSpeedEnabled = v
        if v then EnableCFrameSpeed() else DisableCFrameSpeed() end
    end)
    
    CreateSlider(miscContent, "Multiplicador (÷10)", 1, 20, 5, function(v)
        Config.CFrameMultiplier = v / 10
    end)
    
    CreateSection(miscContent, "NoClip")
    
    CreateToggle(miscContent, "NoClip", false, function(v)
        Config.NoClipEnabled = v
        if v then EnableNoClip() else DisableNoClip() end
    end)
    
    CreateSection(miscContent, "Hitbox")
    
    CreateToggle(miscContent, "Hitbox Expander", false, function(v)
        Config.HitboxEnabled = v
        if v then EnableHitbox() else DisableHitbox() end
    end)
    
    CreateSlider(miscContent, "Tamanho Hitbox", 2, 20, 5, function(v)
        Config.HitboxSize = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    CONTEÚDO ABA INFO
    -- ═══════════════════════════════════════════════════════════════
    
    local infoContent = tabContents["INFO"]
    
    local infoBox = Instance.new("TextLabel")
    infoBox.Size = UDim2.new(1, -10, 0, 150)
    infoBox.BackgroundColor3 = Theme.Surface
    infoBox.Text = [[SAVAGECHEATS v8.0
Aimbot Universal

Jogo: ]] .. GameName .. [[

PlaceId: ]] .. GameId .. [[


Novidades v8.0:
• UI própria (sem dependências)
• CFrame Speed (bypass real)
• Compatível com Mobile
• Design vermelho/preto]]
    infoBox.TextColor3 = Theme.Text
    infoBox.TextSize = 12
    infoBox.Font = Enum.Font.Gotham
    infoBox.TextWrapped = true
    infoBox.TextYAlignment = Enum.TextYAlignment.Top
    infoBox.BorderSizePixel = 0
    infoBox.Parent = infoContent
    AddCorner(infoBox, 6)
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = infoBox
end

-- ═══════════════════════════════════════════════════════════════
--                    LOOP PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local MainConnection = nil

local function MainLoop()
    MainConnection = RunService.RenderStepped:Connect(function()
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
        
        for player, _ in pairs(ESPObjects) do
            UpdateESP(player)
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
    DisableCFrameSpeed()
    DestroyDrawings()
    DestroyESP()
    
    if ScreenGui then ScreenGui:Destroy() end
    
    _G.SAVAGE_V8 = nil
    print("[SAVAGECHEATS] Script encerrado!")
end

_G.SAVAGE_V8 = true
_G.SAVAGE_V8_CLEANUP = DestroyAll

-- ═══════════════════════════════════════════════════════════════
--                    INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("═══════════════════════════════════════════════════")
    print("       SAVAGECHEATS_ AIMBOT UNIVERSAL v8.0")
    print("       UI PRÓPRIA - SEM DEPENDÊNCIAS")
    print("═══════════════════════════════════════════════════")
    print("Jogo: " .. GameName)
    
    if IsPrisonLife then
        print("⚠ Prison Life - Use CFrame Speed 3-5!")
    end
    
    CreateUI()
    CreateDrawings()
    InitESP()
    MainLoop()
    
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if Config.NoClipEnabled then EnableNoClip() end
        if Config.CFrameSpeedEnabled then EnableCFrameSpeed() end
        if IsPrisonLife then
            NoClipBypassApplied = false
            ApplyPrisonLifeBypass()
        end
    end)
    
    print("═══════════════════════════════════════════════════")
    print("✓ Carregado! Clique no botão 'S' vermelho")
    print("═══════════════════════════════════════════════════")
end

Initialize()
