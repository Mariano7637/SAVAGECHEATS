--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║              SAVAGECHEATS_ AIMBOT UNIVERSAL v8.2              ║
    ║                  UI LIMPA + NOVAS FUNÇÕES                     ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  • UI reorganizada e limpa                                    ║
    ║  • Seletor de Time para Aimbot                                ║
    ║  • Munição Infinita separada                                  ║
    ║  • Rapid Fire ultra ajustável                                 ║
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
if _G.SAVAGE_V82 then
    pcall(function() _G.SAVAGE_V82_CLEANUP() end)
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
    TeamFilter = "Todos", -- Todos, Prisioneiros, Guardas, Criminosos, Inimigos
    
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
    
    -- Speed (CFrame apenas - seguro)
    SpeedEnabled = false,
    SpeedMultiplier = 0.2,
    
    -- Rapid Fire
    RapidFireEnabled = false,
    RapidFireRate = 0.05, -- 0.01 a 0.5
    
    -- Munição Infinita
    InfiniteAmmoEnabled = false,
    
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
    
    -- Prison Life teams
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
        if ShouldTarget(player) then
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
        if ShouldTarget(player) then
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
                        root.Transparency = 0.7
                        root.CanCollide = false
                        root.Material = Enum.Material.ForceField
                    else
                        root.Size = OriginalSizes[player] or Vector3.new(2, 2, 1)
                        root.Transparency = 1
                        root.Material = Enum.Material.SmoothPlastic
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
--                    CFRAME SPEED (SEGURO)
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
--                    RAPID FIRE + MUNIÇÃO INFINITA
-- ═══════════════════════════════════════════════════════════════

local ModifiedGuns = {}

local function ModifyGun(gun)
    if not gun then return false end
    if ModifiedGuns[gun] then return true end
    
    local success = pcall(function()
        local gunStates = gun:FindFirstChild("GunStates")
        if gunStates then
            local sM = require(gunStates)
            
            -- Rapid Fire
            if Config.RapidFireEnabled then
                sM["FireRate"] = Config.RapidFireRate
                sM["AutoFire"] = true
            end
            
            -- Munição Infinita
            if Config.InfiniteAmmoEnabled then
                sM["MaxAmmo"] = 999999
                sM["StoredAmmo"] = 999999
                sM["AmmoPerClip"] = 999999
                sM["ReloadTime"] = 0.01
            end
            
            -- Bônus
            sM["Range"] = 9999
            
            ModifiedGuns[gun] = true
        end
    end)
    
    return success
end

local function ApplyGunMods()
    -- Modificar armas no Backpack
    for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            ModifyGun(item)
        end
    end
    
    -- Modificar arma equipada
    if LocalPlayer.Character then
        for _, item in pairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") then
                ModifyGun(item)
            end
        end
    end
end

local function EnableRapidFire()
    ModifiedGuns = {} -- Reset para reaplicar
    ApplyGunMods()
    
    if not Connections.GunBackpack then
        Connections.GunBackpack = LocalPlayer.Backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                ModifyGun(child)
            end
        end)
    end
end

local function EnableInfiniteAmmo()
    ModifiedGuns = {} -- Reset para reaplicar
    ApplyGunMods()
    
    if not Connections.AmmoBackpack then
        Connections.AmmoBackpack = LocalPlayer.Backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                ModifyGun(child)
            end
        end)
    end
end

local function DisableGunMods()
    ModifiedGuns = {}
    
    if Connections.GunBackpack then
        Connections.GunBackpack:Disconnect()
        Connections.GunBackpack = nil
    end
    
    if Connections.AmmoBackpack then
        Connections.AmmoBackpack:Disconnect()
        Connections.AmmoBackpack = nil
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
    
    -- Cor baseada no time
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
--                    UI PRÓPRIA - REORGANIZADA
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
    ScreenGui.Name = "SAVAGECHEATS_V82"
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
    FloatButton.Text = "S"
    FloatButton.TextColor3 = Theme.Text
    FloatButton.TextSize = 20
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
    
    FloatButton.MouseButton1Click:Connect(function()
        UIVisible = not UIVisible
        MainFrame.Visible = UIVisible
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
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Theme.Secondary
    header.BorderSizePixel = 0
    header.Parent = MainFrame
    AddCorner(header, 8)
    
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = Theme.Secondary
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -45, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SAVAGE v8.2"
    title.TextColor3 = Theme.Text
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
    closeBtn.BackgroundColor3 = Theme.Primary
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    AddCorner(closeBtn, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        UIVisible = false
        MainFrame.Visible = false
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    TABS
    -- ═══════════════════════════════════════════════════════════════
    
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(1, -16, 0, 30)
    tabsContainer.Position = UDim2.new(0, 8, 0, 45)
    tabsContainer.BackgroundColor3 = Theme.Secondary
    tabsContainer.BorderSizePixel = 0
    tabsContainer.Parent = MainFrame
    AddCorner(tabsContainer, 6)
    
    local tabsList = Instance.new("UIListLayout")
    tabsList.FillDirection = Enum.FillDirection.Horizontal
    tabsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabsList.Padding = UDim.new(0, 4)
    tabsList.Parent = tabsContainer
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 3)
    tabPadding.Parent = tabsContainer
    
    -- Content Container
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Size = UDim2.new(1, -16, 1, -90)
    contentContainer.Position = UDim2.new(0, 8, 0, 80)
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.ScrollBarThickness = 3
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
        tabBtn.Size = UDim2.new(0, 60, 0, 24)
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
    
    CreateToggle(aimContent, "Silent Aim (Bala Mágica)", false, function(v)
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
    --                    ABA ARMAS
    -- ═══════════════════════════════════════════════════════════════
    
    local armasContent = tabContents["ARMAS"]
    
    CreateSectionHeader(armasContent, "Rapid Fire")
    
    CreateToggle(armasContent, "Ativar Rapid Fire", false, function(v)
        Config.RapidFireEnabled = v
        if v then EnableRapidFire() end
    end)
    
    CreateSlider(armasContent, "Fire Rate", 1, 50, 5, 0, function(v)
        Config.RapidFireRate = v / 100
        if Config.RapidFireEnabled then
            ModifiedGuns = {}
            ApplyGunMods()
        end
    end)
    
    CreateSpacer(armasContent, 4)
    CreateSectionHeader(armasContent, "Munição")
    
    CreateToggle(armasContent, "Munição Infinita", false, function(v)
        Config.InfiniteAmmoEnabled = v
        if v then EnableInfiniteAmmo() end
    end)
    
    CreateSpacer(armasContent, 4)
    CreateSectionHeader(armasContent, "Hitbox")
    
    CreateToggle(armasContent, "Hitbox Expander", false, function(v)
        Config.HitboxEnabled = v
        if v then EnableHitbox() else DisableHitbox() end
    end)
    
    CreateSlider(armasContent, "Tamanho", 3, 25, 5, 0, function(v)
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
    CreateSectionHeader(miscContent, "Informações")
    
    local infoBox = Instance.new("TextLabel")
    infoBox.Size = UDim2.new(1, 0, 0, 100)
    infoBox.BackgroundColor3 = Theme.Surface
    infoBox.Text = [[Jogo: ]] .. GameName .. [[

Dicas:
• Speed 1-3 é mais seguro
• Rapid Fire: valores baixos = mais rápido
• Focar Time: escolha quem o aimbot mira]]
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
    DisableSpeed()
    DisableGunMods()
    DestroyDrawings()
    DestroyESP()
    
    if ScreenGui then ScreenGui:Destroy() end
    
    _G.SAVAGE_V82 = nil
end

_G.SAVAGE_V82 = true
_G.SAVAGE_V82_CLEANUP = DestroyAll

-- ═══════════════════════════════════════════════════════════════
--                    INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("═══════════════════════════════════════════════════")
    print("       SAVAGECHEATS_ AIMBOT UNIVERSAL v8.2")
    print("═══════════════════════════════════════════════════")
    print("Jogo: " .. GameName)
    
    CreateUI()
    CreateDrawings()
    InitESP()
    MainLoop()
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        
        if Config.NoClipEnabled then EnableNoClip() end
        if Config.SpeedEnabled then EnableSpeed() end
        if Config.RapidFireEnabled or Config.InfiniteAmmoEnabled then
            ModifiedGuns = {}
            ApplyGunMods()
        end
        
        if IsPrisonLife then
            NoClipBypassApplied = false
            ApplyPrisonLifeBypass()
        end
        
        -- Reconectar eventos de armas
        if char then
            char.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    task.wait(0.1)
                    ModifyGun(child)
                end
            end)
        end
    end)
    
    print("═══════════════════════════════════════════════════")
    print("✓ Carregado! Clique no botão 'S' vermelho")
    print("═══════════════════════════════════════════════════")
end

Initialize()
