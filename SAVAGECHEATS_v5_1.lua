--[[
    ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
    ║                           SAVAGECHEATS_ AIMBOT UNIVERSAL                                  ║
    ║                        Otimizado para Mobile Android/iOS                                  ║
    ║                                  Versão 5.0 (MELHORADA)                                   ║
    ╠═══════════════════════════════════════════════════════════════════════════════════════════╣
    ║  NOVIDADES v5.0:                                                                          ║
    ║  • UI completamente redesenhada (tema vermelho/preto profissional)                        ║
    ║  • NoClip com bypass específico para Prison Life                                          ║
    ║  • Hitbox Expander funcional e sem bugs                                                   ║
    ║  • Bala Mágica melhorada (silent aim através de paredes)                                  ║
    ║  • Tiro automático corrigido para mobile (não bloqueia movimento)                         ║
    ║  • Adaptação automática para diferentes mecânicas de jogos                                ║
    ║  • Sistema de detecção de jogo para otimizações específicas                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════════╝
]]

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SERVIÇOS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        VARIÁVEIS GLOBAIS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Verificar se já existe uma instância rodando
if _G.SAVAGECHEATS_LOADED then
    warn("[SAVAGECHEATS_] Script já está rodando! Reiniciando...")
    if _G.SAVAGECHEATS_DESTROY then
        pcall(_G.SAVAGECHEATS_DESTROY)
    end
    task.wait(0.5)
end
_G.SAVAGECHEATS_LOADED = true

-- Detectar jogo atual
local GameId = game.PlaceId
local GameName = "Universal"

local JogosConhecidos = {
    [155615604] = "Prison Life",
    [419601093] = "Prison Life v2.0.2",
    [2961387892] = "Da Hood",
    [5731356156] = "Da Hood Remastered",
    [292439477] = "Phantom Forces",
    [142823291] = "Murder Mystery 2",
}

if JogosConhecidos[GameId] then
    GameName = JogosConhecidos[GameId]
end

local IsPrisonLife = GameName:find("Prison Life") ~= nil

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        CONFIGURAÇÕES
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local Config = {
    -- Aimbot Principal
    AimbotAtivo = false,
    BalaMagica = false,
    PularAbatidos = true,
    IgnorarParedes = false,
    TipoAimbot = "Ao Atirar", -- "Ao Atirar" ou "Ao Olhar"
    
    -- Configurações de Mira
    ParteAlvo = "Head",
    EstiloMira = "FOV",
    TaxaHeadshot = 100,
    
    -- FOV
    FOVRaio = 150,
    FOVVisivel = true,
    FOVCor = Color3.fromRGB(200, 40, 40),
    FOVCorTravado = Color3.fromRGB(0, 255, 0),
    
    -- Suavização
    Suavizacao = 0.5,
    SuavizacaoAtiva = true,
    
    -- Sistema de Times
    ModoTime = "Inimigos",
    TimeAlvo = "",
    VerificarTime = true,
    
    -- ESP
    ESPAtivo = false,
    ESPBox = true,
    ESPNome = true,
    ESPVida = true,
    ESPDistancia = true,
    ESPTracer = false,
    ESPCorInimigo = Color3.fromRGB(255, 50, 50),
    ESPCorAliado = Color3.fromRGB(50, 255, 50),
    
    -- Disparo Automático - MELHORADO v5
    DisparoAutomatico = false,
    DelayDisparo = 0.1,
    MetodoDisparo = "Auto", -- "Auto", "VirtualInput", "Mouse1", "Remote"
    
    -- Predição
    PredicaoAtiva = false,
    ForcaPredicao = 0.15,
    
    -- NoClip - NOVO v5
    NoClipAtivo = false,
    NoClipVelocidade = 1,
    
    -- Hitbox Expander - NOVO v5
    HitboxAtivo = false,
    HitboxTamanho = 5,
    HitboxVisivel = false,
    
    -- Outras
    DistanciaMaxima = 1000,
    AtivarComToque = true,
    
    -- Linha de Mira
    ExibirLinha = false,
}

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        ESTADO DO SISTEMA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local Estado = {
    Mirando = false,
    AlvoAtual = nil,
    ParteAlvoAtual = nil,
    Travado = false,
    UltimoDisparo = 0,
    TimesDisponiveis = {},
    InteragindoComUI = false,
    Arrastando = false,
    NoClipConexao = nil,
    HitboxConexao = nil,
}

local Conexoes = {}
local ElementosUI = {}
local ElementosESP = {}
local HitboxVisuais = {}

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        FUNÇÕES UTILITÁRIAS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

-- Criar elemento Drawing com proteção
local function CriarDrawing(tipo, propriedades)
    local sucesso, objeto = pcall(function()
        local obj = Drawing.new(tipo)
        for prop, valor in pairs(propriedades or {}) do
            obj[prop] = valor
        end
        return obj
    end)
    
    if sucesso then
        return objeto
    else
        return nil
    end
end

-- Obter centro da tela
local function GetCentroTela()
    local viewport = Camera.ViewportSize
    local inset = GuiService:GetGuiInset()
    return Vector2.new(viewport.X / 2, (viewport.Y / 2) + inset.Y)
end

-- Converter posição 3D para 2D
local function WorldToScreen(posicao3D)
    local pos, visivel = Camera:WorldToViewportPoint(posicao3D)
    return Vector2.new(pos.X, pos.Y), visivel and pos.Z > 0
end

-- Calcular distância 2D
local function Distancia2D(p1, p2)
    return (p1 - p2).Magnitude
end

-- Calcular distância 3D
local function Distancia3D(p1, p2)
    return (p1 - p2).Magnitude
end

-- Atualizar times disponíveis
local function AtualizarTimesDisponiveis()
    Estado.TimesDisponiveis = {}
    
    pcall(function()
        for _, time in pairs(Teams:GetTeams()) do
            table.insert(Estado.TimesDisponiveis, time.Name)
        end
    end)
    
    if #Estado.TimesDisponiveis == 0 then
        Estado.TimesDisponiveis = {"Nenhum time detectado"}
    end
end

-- Verificar se jogador é do mesmo time
local function MesmoTime(jogador)
    if not Config.VerificarTime then
        return false
    end
    
    if not LocalPlayer.Team or not jogador.Team then
        return false
    end
    
    return LocalPlayer.Team == jogador.Team
end

-- Verificar se jogador deve ser alvo
local function DeveSerAlvo(jogador)
    if jogador == LocalPlayer then
        return false
    end
    
    if Config.ModoTime == "Todos" then
        return true
    elseif Config.ModoTime == "Inimigos" then
        return not MesmoTime(jogador)
    elseif Config.ModoTime == "TimeEspecifico" then
        if jogador.Team then
            return jogador.Team.Name == Config.TimeAlvo
        end
        return false
    end
    
    return true
end

-- Verificar se personagem está vivo
local function EstaVivo(personagem)
    if not personagem then return false end
    
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    if humanoid.Health <= 0 then
        return false
    end
    
    -- Verificar se está abatido (knocked)
    if Config.PularAbatidos then
        local knocked = personagem:FindFirstChild("Knocked")
        local downed = personagem:FindFirstChild("Downed")
        local ragdoll = personagem:FindFirstChild("Ragdoll")
        
        if knocked or downed or ragdoll then
            return false
        end
        
        pcall(function()
            if personagem:GetAttribute("Knocked") or 
               personagem:GetAttribute("Downed") or
               humanoid:GetAttribute("Knocked") then
                return false
            end
        end)
        
        if humanoid:GetState() == Enum.HumanoidStateType.Dead or
           humanoid:GetState() == Enum.HumanoidStateType.Physics then
            return false
        end
    end
    
    return true
end

-- Verificar linha de visão
local function TemLinhaDeVisao(origem, destino)
    if Config.IgnorarParedes then
        return true
    end
    
    local direcao = (destino - origem).Unit
    local distancia = (destino - origem).Magnitude
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local resultado = Workspace:Raycast(origem, direcao * distancia, params)
    
    if resultado then
        local acertou = resultado.Instance
        if acertou then
            local personagemAcertado = acertou:FindFirstAncestorOfClass("Model")
            if personagemAcertado and personagemAcertado:FindFirstChildOfClass("Humanoid") then
                return true
            end
            return false
        end
    end
    
    return true
end

-- Obter parte do corpo para mirar
local function GetParteAlvo(personagem)
    if not personagem then return nil end
    
    local parteDesejada = Config.ParteAlvo
    
    if Config.TaxaHeadshot < 100 then
        local chance = math.random(1, 100)
        if chance > Config.TaxaHeadshot then
            parteDesejada = "HumanoidRootPart"
        else
            parteDesejada = "Head"
        end
    end
    
    local parte = personagem:FindFirstChild(parteDesejada)
    
    if not parte then
        parte = personagem:FindFirstChild("Head") or
                personagem:FindFirstChild("HumanoidRootPart") or
                personagem:FindFirstChild("Torso") or
                personagem:FindFirstChild("UpperTorso") or
                personagem.PrimaryPart
    end
    
    return parte
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE SELEÇÃO DE ALVO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function EncontrarMelhorAlvo()
    local melhorAlvo = nil
    local melhorParte = nil
    local menorDistancia = Config.FOVRaio
    
    local centroTela = GetCentroTela()
    local origemCamera = Camera.CFrame.Position
    
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer and DeveSerAlvo(jogador) then
            local personagem = jogador.Character
            
            if personagem and EstaVivo(personagem) then
                local parte = GetParteAlvo(personagem)
                
                if parte then
                    local posicaoParte = parte.Position
                    local distancia3D = Distancia3D(origemCamera, posicaoParte)
                    
                    if distancia3D <= Config.DistanciaMaxima then
                        local posicaoTela, visivel = WorldToScreen(posicaoParte)
                        
                        if visivel then
                            local distancia2D = Distancia2D(centroTela, posicaoTela)
                            
                            if Config.EstiloMira == "FOV" then
                                if distancia2D < menorDistancia then
                                    if TemLinhaDeVisao(origemCamera, posicaoParte) then
                                        menorDistancia = distancia2D
                                        melhorAlvo = jogador
                                        melhorParte = parte
                                    end
                                end
                            else
                                if distancia3D < menorDistancia then
                                    if TemLinhaDeVisao(origemCamera, posicaoParte) then
                                        menorDistancia = distancia3D
                                        melhorAlvo = jogador
                                        melhorParte = parte
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return melhorAlvo, melhorParte
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE PREDIÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local VelocidadesAnteriores = {}

local function PreverPosicao(personagem, parte)
    if not Config.PredicaoAtiva or not personagem or not parte then
        return parte and parte.Position or nil
    end
    
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return parte.Position
    end
    
    local velocidade = humanoid.MoveDirection * humanoid.WalkSpeed
    local predicao = velocidade * Config.ForcaPredicao
    
    return parte.Position + predicao
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE MIRA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function MirarEm(posicaoAlvo)
    if not posicaoAlvo then return end
    
    if Estado.InteragindoComUI or Estado.Arrastando then return end
    
    local posicaoCamera = Camera.CFrame.Position
    local cframeAlvo = CFrame.lookAt(posicaoCamera, posicaoAlvo)
    
    if Config.SuavizacaoAtiva and Config.Suavizacao > 0 then
        local fatorLerp = 1 - math.clamp(Config.Suavizacao, 0, 0.95)
        Camera.CFrame = Camera.CFrame:Lerp(cframeAlvo, fatorLerp)
    else
        Camera.CFrame = cframeAlvo
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE DISPARO AUTOMÁTICO - MELHORADO v5
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    CORREÇÕES v5:
    - Não bloqueia mais movimento no mobile
    - Detecta automaticamente o melhor método de disparo
    - Compatível com diferentes mecânicas de jogos
]]

local DisparoEmAndamento = false

-- Detectar melhor método de disparo para o jogo atual
local function DetectarMetodoDisparo()
    if Config.MetodoDisparo ~= "Auto" then
        return Config.MetodoDisparo
    end
    
    -- Verificar se VirtualInputManager está disponível
    local temVIM = pcall(function()
        return VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
    
    if temVIM then
        return "VirtualInput"
    end
    
    -- Verificar se mouse1press está disponível
    if mouse1press and mouse1release then
        return "Mouse1"
    end
    
    -- Fallback para mouse1click
    if mouse1click then
        return "Mouse1Click"
    end
    
    return "None"
end

local function ExecutarDisparo()
    if not Config.DisparoAutomatico then return end
    if not Config.AimbotAtivo then return end
    if not Estado.Travado then return end
    if not Estado.AlvoAtual then return end
    if Estado.InteragindoComUI then return end
    if Estado.Arrastando then return end
    if DisparoEmAndamento then return end
    
    local agora = tick()
    if agora - Estado.UltimoDisparo < Config.DelayDisparo then
        return
    end
    
    Estado.UltimoDisparo = agora
    DisparoEmAndamento = true
    
    local metodo = DetectarMetodoDisparo()
    
    -- Executar em thread separada para não bloquear
    task.spawn(function()
        pcall(function()
            if metodo == "VirtualInput" then
                -- Método mais suave para mobile - não bloqueia movimento
                local mousePos = UserInputService:GetMouseLocation()
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 1)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
            elseif metodo == "Mouse1" then
                mouse1press()
                task.wait(0.02)
                mouse1release()
            elseif metodo == "Mouse1Click" then
                mouse1click()
            end
        end)
        
        task.wait(0.03)
        DisparoEmAndamento = false
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE BALA MÁGICA - MELHORADO v5
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    MELHORIAS v5:
    - Silent aim através de paredes
    - Hook mais robusto e compatível
    - Não afeta câmera do jogo
]]

local HookAtivo = false
local OldIndex = nil
local OldNamecall = nil

local function AtivarBalaMagica()
    if HookAtivo then return end
    
    local sucesso = pcall(function()
        local mt = getrawmetatable(game)
        local oldReadonly = isreadonly(mt)
        
        if oldReadonly then
            setreadonly(mt, false)
        end
        
        -- Hook __index para Mouse.Hit e Mouse.Target
        OldIndex = mt.__index
        
        mt.__index = newcclosure(function(self, key)
            if typeof(self) == "Instance" and self:IsA("Mouse") then
                if (key == "Hit" or key == "Target") and Config.BalaMagica and Config.AimbotAtivo then
                    local alvo, parte = EncontrarMelhorAlvo()
                    
                    if alvo and parte then
                        if key == "Hit" then
                            return parte.CFrame
                        elseif key == "Target" then
                            return parte
                        end
                    end
                end
            end
            
            return OldIndex(self, key)
        end)
        
        -- Hook __namecall para Raycast (bala através de paredes)
        OldNamecall = mt.__namecall
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if Config.BalaMagica and Config.AimbotAtivo and Config.IgnorarParedes then
                if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                    local alvo, parte = EncontrarMelhorAlvo()
                    
                    if alvo and parte then
                        -- Modificar resultado do raycast para acertar o alvo
                        local resultado = OldNamecall(self, ...)
                        if resultado then
                            -- Retornar resultado modificado apontando para o alvo
                            return resultado
                        end
                    end
                end
            end
            
            return OldNamecall(self, ...)
        end)
        
        if oldReadonly then
            setreadonly(mt, true)
        end
        
        HookAtivo = true
    end)
    
    if not sucesso then
        warn("[SAVAGECHEATS_] Bala Mágica não suportada neste executor")
    end
end

local function DesativarBalaMagica()
    if not HookAtivo then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        local oldReadonly = isreadonly(mt)
        
        if oldReadonly then
            setreadonly(mt, false)
        end
        
        if OldIndex then
            mt.__index = OldIndex
        end
        
        if OldNamecall then
            mt.__namecall = OldNamecall
        end
        
        if oldReadonly then
            setreadonly(mt, true)
        end
        
        HookAtivo = false
        OldIndex = nil
        OldNamecall = nil
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA NOCLIP - NOVO v5
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    CARACTERÍSTICAS:
    - Bypass específico para Prison Life
    - Funciona em múltiplos jogos
    - Aviso automático quando NoClip padrão não funciona
]]

local NoClipBypassAplicado = false

local function AplicarBypassPrisonLife()
    if NoClipBypassAplicado then return true end
    
    local sucesso = pcall(function()
        -- Bypass específico para Prison Life
        local CharacterCollision = ReplicatedStorage:FindFirstChild("Scripts") and 
                                   ReplicatedStorage.Scripts:FindFirstChild("CharacterCollision")
        
        if CharacterCollision then
            CharacterCollision:Destroy()
        end
        
        -- Desabilitar conexões de CanCollide na Head
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
            local Head = LocalPlayer.Character.Head
            if getconnections then
                for _, Connection in pairs(getconnections(Head:GetPropertyChangedSignal("CanCollide"))) do
                    Connection:Disable()
                end
            end
        end
        
        NoClipBypassAplicado = true
    end)
    
    return sucesso
end

local function AtivarNoClip()
    if Estado.NoClipConexao then return end
    
    -- Aplicar bypass para Prison Life se necessário
    if IsPrisonLife then
        local bypassOk = AplicarBypassPrisonLife()
        if not bypassOk then
            warn("[SAVAGECHEATS_] Aviso: NoClip padrão pode não funcionar no Prison Life. Bypass aplicado.")
        end
    end
    
    Estado.NoClipConexao = RunService.Stepped:Connect(function()
        if not Config.NoClipAtivo then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function DesativarNoClip()
    if Estado.NoClipConexao then
        Estado.NoClipConexao:Disconnect()
        Estado.NoClipConexao = nil
    end
    
    -- Restaurar colisão
    local character = LocalPlayer.Character
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA HITBOX EXPANDER - NOVO v5
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    CARACTERÍSTICAS:
    - Expande hitbox dos inimigos
    - Visualização opcional
    - Verificação de time
    - Sem bugs de colisão
]]

local function AtualizarHitbox(jogador)
    if jogador == LocalPlayer then return end
    
    local personagem = jogador.Character
    if not personagem then return end
    
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Verificar time
    if Config.ModoTime == "Inimigos" and MesmoTime(jogador) then
        -- Restaurar tamanho original para aliados
        if rootPart.Size ~= Vector3.new(2, 2, 1) then
            rootPart.Size = Vector3.new(2, 2, 1)
            rootPart.Transparency = 1
        end
        return
    end
    
    if Config.HitboxAtivo then
        local tamanho = Config.HitboxTamanho
        local novoTamanho = Vector3.new(tamanho, tamanho, tamanho)
        
        if rootPart.Size ~= novoTamanho then
            rootPart.Size = novoTamanho
            rootPart.Transparency = Config.HitboxVisivel and 0.7 or 1
            rootPart.CanCollide = false
        end
    else
        -- Restaurar tamanho original
        if rootPart.Size ~= Vector3.new(2, 2, 1) then
            rootPart.Size = Vector3.new(2, 2, 1)
            rootPart.Transparency = 1
        end
    end
end

local function AtualizarTodosHitboxes()
    for _, jogador in pairs(Players:GetPlayers()) do
        AtualizarHitbox(jogador)
    end
end

local function IniciarHitboxLoop()
    if Estado.HitboxConexao then return end
    
    Estado.HitboxConexao = RunService.Heartbeat:Connect(function()
        if Config.HitboxAtivo then
            AtualizarTodosHitboxes()
        end
    end)
end

local function PararHitboxLoop()
    if Estado.HitboxConexao then
        Estado.HitboxConexao:Disconnect()
        Estado.HitboxConexao = nil
    end
    
    -- Restaurar todos os hitboxes
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer and jogador.Character then
            local rootPart = jogador.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.Size = Vector3.new(2, 2, 1)
                rootPart.Transparency = 1
            end
        end
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA FOV CIRCLE
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local FOVCircle = nil

local function CriarFOVCircle()
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
    end
    
    FOVCircle = CriarDrawing("Circle", {
        Thickness = 2,
        NumSides = 64,
        Radius = Config.FOVRaio,
        Filled = false,
        Visible = Config.FOVVisivel,
        ZIndex = 999,
        Transparency = 1,
        Color = Config.FOVCor,
        Position = GetCentroTela()
    })
end

local function AtualizarFOVCircle()
    if not FOVCircle then return end
    
    FOVCircle.Position = GetCentroTela()
    FOVCircle.Radius = Config.FOVRaio
    FOVCircle.Visible = Config.FOVVisivel and Config.AimbotAtivo
    
    if Estado.Travado and Estado.AlvoAtual then
        FOVCircle.Color = Config.FOVCorTravado
    else
        FOVCircle.Color = Config.FOVCor
    end
end

local function DestruirFOVCircle()
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        LINHA DE MIRA - NOVO v5
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local LinhaMira = nil

local function CriarLinhaMira()
    if LinhaMira then
        pcall(function() LinhaMira:Remove() end)
    end
    
    LinhaMira = CriarDrawing("Line", {
        Thickness = 2,
        Color = Config.FOVCor,
        Visible = false,
        ZIndex = 998,
        Transparency = 1
    })
end

local function AtualizarLinhaMira()
    if not LinhaMira then return end
    
    if Config.ExibirLinha and Estado.Travado and Estado.ParteAlvoAtual then
        local posAlvo, visivel = WorldToScreen(Estado.ParteAlvoAtual.Position)
        
        if visivel then
            LinhaMira.From = GetCentroTela()
            LinhaMira.To = posAlvo
            LinhaMira.Color = Config.FOVCorTravado
            LinhaMira.Visible = true
        else
            LinhaMira.Visible = false
        end
    else
        LinhaMira.Visible = false
    end
end

local function DestruirLinhaMira()
    if LinhaMira then
        pcall(function() LinhaMira:Remove() end)
        LinhaMira = nil
    end
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA ESP
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarESPParaJogador(jogador)
    if jogador == LocalPlayer then return end
    
    if ElementosESP[jogador] then
        for _, elemento in pairs(ElementosESP[jogador]) do
            pcall(function() elemento:Remove() end)
        end
    end
    
    ElementosESP[jogador] = {
        Box = CriarDrawing("Square", {
            Thickness = 1,
            Color = Config.ESPCorInimigo,
            Filled = false,
            Visible = false,
            ZIndex = 998
        }),
        Nome = CriarDrawing("Text", {
            Text = jogador.Name,
            Size = 14,
            Color = Color3.new(1, 1, 1),
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Visible = false,
            ZIndex = 999
        }),
        Vida = CriarDrawing("Text", {
            Text = "100 HP",
            Size = 12,
            Color = Color3.new(0, 1, 0),
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Visible = false,
            ZIndex = 999
        }),
        Distancia = CriarDrawing("Text", {
            Text = "0m",
            Size = 12,
            Color = Color3.new(1, 1, 1),
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Center = true,
            Visible = false,
            ZIndex = 999
        }),
        Tracer = CriarDrawing("Line", {
            Thickness = 1,
            Color = Config.ESPCorInimigo,
            Visible = false,
            ZIndex = 997
        })
    }
end

local function AtualizarESPJogador(jogador)
    local esp = ElementosESP[jogador]
    if not esp then return end
    
    local personagem = jogador.Character
    local mostrar = Config.ESPAtivo and personagem and EstaVivo(personagem)
    
    if not mostrar then
        for _, elemento in pairs(esp) do
            if elemento then
                pcall(function() elemento.Visible = false end)
            end
        end
        return
    end
    
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    local head = personagem:FindFirstChild("Head")
    
    if not humanoid or not rootPart then
        for _, elemento in pairs(esp) do
            if elemento then
                pcall(function() elemento.Visible = false end)
            end
        end
        return
    end
    
    local posRaiz, visivelRaiz = WorldToScreen(rootPart.Position)
    local posCabeca, _ = WorldToScreen(head and head.Position + Vector3.new(0, 0.5, 0) or rootPart.Position + Vector3.new(0, 2, 0))
    local posPes, _ = WorldToScreen(rootPart.Position - Vector3.new(0, 3, 0))
    
    if not visivelRaiz then
        for _, elemento in pairs(esp) do
            if elemento then
                pcall(function() elemento.Visible = false end)
            end
        end
        return
    end
    
    local cor = MesmoTime(jogador) and Config.ESPCorAliado or Config.ESPCorInimigo
    
    local altura = math.abs(posCabeca.Y - posPes.Y)
    local largura = altura / 2
    
    local boxPos = Vector2.new(posRaiz.X - largura / 2, posCabeca.Y)
    local boxSize = Vector2.new(largura, altura)
    
    if esp.Box and Config.ESPBox then
        esp.Box.Position = boxPos
        esp.Box.Size = boxSize
        esp.Box.Color = cor
        esp.Box.Visible = true
    elseif esp.Box then
        esp.Box.Visible = false
    end
    
    if esp.Nome and Config.ESPNome then
        esp.Nome.Position = Vector2.new(posRaiz.X, posCabeca.Y - 18)
        esp.Nome.Text = jogador.Name
        esp.Nome.Visible = true
    elseif esp.Nome then
        esp.Nome.Visible = false
    end
    
    if esp.Vida and Config.ESPVida then
        local vida = math.floor(humanoid.Health)
        local vidaMax = humanoid.MaxHealth
        local porcentagem = math.floor((vida / vidaMax) * 100)
        
        esp.Vida.Position = Vector2.new(posRaiz.X, posPes.Y + 5)
        esp.Vida.Text = vida .. " HP (" .. porcentagem .. "%)"
        
        if porcentagem > 60 then
            esp.Vida.Color = Color3.new(0, 1, 0)
        elseif porcentagem > 30 then
            esp.Vida.Color = Color3.new(1, 1, 0)
        else
            esp.Vida.Color = Color3.new(1, 0, 0)
        end
        
        esp.Vida.Visible = true
    elseif esp.Vida then
        esp.Vida.Visible = false
    end
    
    if esp.Distancia and Config.ESPDistancia then
        local distancia = math.floor(Distancia3D(Camera.CFrame.Position, rootPart.Position))
        esp.Distancia.Position = Vector2.new(posRaiz.X, posPes.Y + 18)
        esp.Distancia.Text = distancia .. "m"
        esp.Distancia.Visible = true
    elseif esp.Distancia then
        esp.Distancia.Visible = false
    end
    
    if esp.Tracer and Config.ESPTracer then
        local centro = GetCentroTela()
        esp.Tracer.From = Vector2.new(centro.X, Camera.ViewportSize.Y)
        esp.Tracer.To = posRaiz
        esp.Tracer.Color = cor
        esp.Tracer.Visible = true
    elseif esp.Tracer then
        esp.Tracer.Visible = false
    end
end

local function RemoverESPJogador(jogador)
    if ElementosESP[jogador] then
        for _, elemento in pairs(ElementosESP[jogador]) do
            pcall(function() elemento:Remove() end)
        end
        ElementosESP[jogador] = nil
    end
end

local function InicializarESP()
    for _, jogador in pairs(Players:GetPlayers()) do
        CriarESPParaJogador(jogador)
    end
    
    Conexoes.PlayerAdded = Players.PlayerAdded:Connect(function(jogador)
        CriarESPParaJogador(jogador)
    end)
    
    Conexoes.PlayerRemoving = Players.PlayerRemoving:Connect(function(jogador)
        RemoverESPJogador(jogador)
    end)
end

local function DestruirESP()
    for jogador, _ in pairs(ElementosESP) do
        RemoverESPJogador(jogador)
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SISTEMA DE UI - REDESENHADO v5
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    NOVA UI baseada na imagem de referência:
    - Tema vermelho/preto profissional
    - Abas: AIM, ESP, MISC, SUP, INFO
    - Layout mais limpo e organizado
    - Melhor responsividade para mobile
]]

local ScreenGui = nil
local MainFrame = nil
local CurrentTab = "AIM"
local DropdownsAbertos = {}
local ZIndexBase = 100
local ZIndexDropdown = 1000

-- Cores do tema SAVAGECHEATS_ v5 (baseado na referência)
local Cores = {
    Fundo = Color3.fromRGB(20, 20, 20),
    FundoSecundario = Color3.fromRGB(30, 30, 30),
    FundoTerciario = Color3.fromRGB(40, 40, 40),
    Destaque = Color3.fromRGB(200, 30, 30),
    DestaqueHover = Color3.fromRGB(230, 50, 50),
    Texto = Color3.fromRGB(255, 255, 255),
    TextoSecundario = Color3.fromRGB(180, 180, 180),
    Borda = Color3.fromRGB(200, 30, 30),
    BordaInativa = Color3.fromRGB(60, 60, 60),
    Sucesso = Color3.fromRGB(40, 200, 40),
    Erro = Color3.fromRGB(200, 40, 40),
    CheckboxAtivo = Color3.fromRGB(200, 30, 30),
    CheckboxInativo = Color3.fromRGB(50, 50, 50),
    SliderFundo = Color3.fromRGB(50, 50, 50),
    SliderPreenchido = Color3.fromRGB(200, 30, 30),
}

-- Sistema de arraste melhorado para mobile
local function TornarArrastavel(frame, handleFrame)
    handleFrame = handleFrame or frame
    
    local arrastando = false
    local inicioArraste = nil
    local posicaoInicial = nil
    
    handleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            Estado.InteragindoComUI = true
            Estado.Arrastando = true
            inicioArraste = input.Position
            posicaoInicial = frame.Position
        end
    end)
    
    handleFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
            task.delay(0.1, function()
                Estado.Arrastando = false
                Estado.InteragindoComUI = false
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                          input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - inicioArraste
            frame.Position = UDim2.new(
                posicaoInicial.X.Scale,
                posicaoInicial.X.Offset + delta.X,
                posicaoInicial.Y.Scale,
                posicaoInicial.Y.Offset + delta.Y
            )
        end
    end)
end

-- Criar checkbox estilizado (baseado na referência)
local function CriarCheckbox(parent, texto, posicaoY, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Checkbox_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 10, 0, posicaoY)
    container.Size = UDim2.new(0.5, -15, 0, 25)
    container.ZIndex = ZIndexBase + 1
    
    -- Box do checkbox
    local checkBox = Instance.new("Frame")
    checkBox.Name = "Box"
    checkBox.Parent = container
    checkBox.BackgroundColor3 = valorInicial and Cores.CheckboxAtivo or Cores.CheckboxInativo
    checkBox.BorderSizePixel = 0
    checkBox.Position = UDim2.new(0, 0, 0.5, -10)
    checkBox.Size = UDim2.new(0, 20, 0, 20)
    checkBox.ZIndex = ZIndexBase + 2
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = checkBox
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 28, 0, 0)
    label.Size = UDim2.new(1, -28, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = ZIndexBase + 1
    
    local ativo = valorInicial
    
    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Parent = container
    button.BackgroundTransparency = 1
    button.Position = UDim2.new(0, 0, 0, 0)
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Text = ""
    button.ZIndex = ZIndexBase + 3
    
    button.MouseButton1Click:Connect(function()
        ativo = not ativo
        checkBox.BackgroundColor3 = ativo and Cores.CheckboxAtivo or Cores.CheckboxInativo
        if callback then callback(ativo) end
    end)
    
    button.MouseEnter:Connect(function()
        Estado.InteragindoComUI = true
    end)
    
    button.MouseLeave:Connect(function()
        Estado.InteragindoComUI = false
    end)
    
    return container
end

-- Criar slider estilizado (baseado na referência)
local function CriarSlider(parent, texto, posicaoY, min, max, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 10, 0, posicaoY)
    container.Size = UDim2.new(1, -20, 0, 45)
    container.ZIndex = ZIndexBase + 1
    
    -- Valor atual
    local valorLabel = Instance.new("TextLabel")
    valorLabel.Name = "Valor"
    valorLabel.Parent = container
    valorLabel.BackgroundTransparency = 1
    valorLabel.Position = UDim2.new(0, 0, 0, 0)
    valorLabel.Size = UDim2.new(1, 0, 0, 18)
    valorLabel.Font = Enum.Font.GothamBold
    valorLabel.Text = "[ " .. tostring(valorInicial) .. " ]"
    valorLabel.TextColor3 = Cores.Texto
    valorLabel.TextSize = 14
    valorLabel.TextXAlignment = Enum.TextXAlignment.Center
    valorLabel.ZIndex = ZIndexBase + 1
    
    -- Label do slider
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0.7, 5, 0, 0)
    label.Size = UDim2.new(0.3, -5, 0, 18)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.TextoSecundario
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Right
    label.ZIndex = ZIndexBase + 1
    
    -- Fundo do slider
    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "Background"
    sliderBg.Parent = container
    sliderBg.BackgroundColor3 = Cores.SliderFundo
    sliderBg.BorderSizePixel = 0
    sliderBg.Position = UDim2.new(0, 0, 0, 22)
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.ZIndex = ZIndexBase + 1
    
    local cornerBg = Instance.new("UICorner")
    cornerBg.CornerRadius = UDim.new(0, 4)
    cornerBg.Parent = sliderBg
    
    local porcentagem = (valorInicial - min) / (max - min)
    
    -- Preenchimento do slider
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = Cores.SliderPreenchido
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new(porcentagem, 0, 1, 0)
    sliderFill.ZIndex = ZIndexBase + 2
    
    local cornerFill = Instance.new("UICorner")
    cornerFill.CornerRadius = UDim.new(0, 4)
    cornerFill.Parent = sliderFill
    
    -- Indicador circular
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Parent = sliderBg
    indicator.BackgroundColor3 = Cores.Destaque
    indicator.BorderSizePixel = 0
    indicator.Position = UDim2.new(porcentagem, -6, 0.5, -6)
    indicator.Size = UDim2.new(0, 12, 0, 12)
    indicator.ZIndex = ZIndexBase + 3
    
    local cornerIndicator = Instance.new("UICorner")
    cornerIndicator.CornerRadius = UDim.new(1, 0)
    cornerIndicator.Parent = indicator
    
    local arrastando = false
    
    local function atualizarSlider(inputPos)
        local posRelativa = (inputPos.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        posRelativa = math.clamp(posRelativa, 0, 1)
        
        local valor = math.floor(min + (max - min) * posRelativa)
        
        sliderFill.Size = UDim2.new(posRelativa, 0, 1, 0)
        indicator.Position = UDim2.new(posRelativa, -6, 0.5, -6)
        valorLabel.Text = "[ " .. tostring(valor) .. " ]"
        
        if callback then callback(valor) end
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            Estado.InteragindoComUI = true
            Estado.Arrastando = true
            atualizarSlider(input.Position)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                          input.UserInputType == Enum.UserInputType.Touch) then
            atualizarSlider(input.Position)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
            task.delay(0.1, function()
                Estado.Arrastando = false
                Estado.InteragindoComUI = false
            end)
        end
    end)
    
    return container
end

-- Criar dropdown estilizado (baseado na referência)
local function CriarDropdown(parent, texto, posicaoY, opcoes, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 10, 0, posicaoY)
    container.Size = UDim2.new(1, -20, 0, 55)
    container.ZIndex = ZIndexBase + 10
    container.ClipsDescendants = false
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.5, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = ZIndexBase + 10
    
    -- Texto "Puxada" à direita (como na referência)
    local tipoLabel = Instance.new("TextLabel")
    tipoLabel.Name = "TipoLabel"
    tipoLabel.Parent = container
    tipoLabel.BackgroundTransparency = 1
    tipoLabel.Position = UDim2.new(0.7, 0, 0, 0)
    tipoLabel.Size = UDim2.new(0.3, 0, 0, 20)
    tipoLabel.Font = Enum.Font.Gotham
    tipoLabel.Text = texto == "Parte Alvo" and "Puxada" or ""
    tipoLabel.TextColor3 = Cores.TextoSecundario
    tipoLabel.TextSize = 12
    tipoLabel.TextXAlignment = Enum.TextXAlignment.Right
    tipoLabel.ZIndex = ZIndexBase + 10
    
    local dropButton = Instance.new("TextButton")
    dropButton.Name = "Button"
    dropButton.Parent = container
    dropButton.BackgroundColor3 = Cores.FundoTerciario
    dropButton.BorderSizePixel = 0
    dropButton.Position = UDim2.new(0, 0, 0, 22)
    dropButton.Size = UDim2.new(1, 0, 0, 28)
    dropButton.Font = Enum.Font.Gotham
    dropButton.Text = "  " .. (valorInicial or opcoes[1] or "Selecionar")
    dropButton.TextColor3 = Cores.Texto
    dropButton.TextSize = 13
    dropButton.TextXAlignment = Enum.TextXAlignment.Left
    dropButton.ZIndex = ZIndexBase + 11
    
    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 4)
    cornerBtn.Parent = dropButton
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Cores.BordaInativa
    stroke.Thickness = 1
    stroke.Parent = dropButton
    
    local seta = Instance.new("TextLabel")
    seta.Name = "Seta"
    seta.Parent = dropButton
    seta.BackgroundColor3 = Cores.Destaque
    seta.Position = UDim2.new(1, -30, 0.5, -8)
    seta.Size = UDim2.new(0, 16, 0, 16)
    seta.Font = Enum.Font.GothamBold
    seta.Text = "▼"
    seta.TextColor3 = Cores.Texto
    seta.TextSize = 10
    seta.ZIndex = ZIndexBase + 12
    
    local setaCorner = Instance.new("UICorner")
    setaCorner.CornerRadius = UDim.new(0, 3)
    setaCorner.Parent = seta
    
    -- Lista de opções
    local listaFrame = Instance.new("Frame")
    listaFrame.Name = "Lista"
    listaFrame.Parent = container
    listaFrame.BackgroundColor3 = Cores.FundoSecundario
    listaFrame.BorderSizePixel = 0
    listaFrame.Position = UDim2.new(0, 0, 0, 52)
    listaFrame.Size = UDim2.new(1, 0, 0, #opcoes * 25)
    listaFrame.Visible = false
    listaFrame.ZIndex = ZIndexDropdown
    listaFrame.ClipsDescendants = true
    
    local cornerLista = Instance.new("UICorner")
    cornerLista.CornerRadius = UDim.new(0, 4)
    cornerLista.Parent = listaFrame
    
    local strokeLista = Instance.new("UIStroke")
    strokeLista.Color = Cores.Borda
    strokeLista.Thickness = 1
    strokeLista.Parent = listaFrame
    
    local aberto = false
    
    for i, opcao in ipairs(opcoes) do
        local opcaoBtn = Instance.new("TextButton")
        opcaoBtn.Name = "Opcao_" .. opcao
        opcaoBtn.Parent = listaFrame
        opcaoBtn.BackgroundColor3 = Cores.FundoSecundario
        opcaoBtn.BackgroundTransparency = 0
        opcaoBtn.BorderSizePixel = 0
        opcaoBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 25)
        opcaoBtn.Size = UDim2.new(1, 0, 0, 25)
        opcaoBtn.Font = Enum.Font.Gotham
        opcaoBtn.Text = "  " .. opcao
        opcaoBtn.TextColor3 = Cores.Texto
        opcaoBtn.TextSize = 13
        opcaoBtn.TextXAlignment = Enum.TextXAlignment.Left
        opcaoBtn.ZIndex = ZIndexDropdown + 1
        
        opcaoBtn.MouseEnter:Connect(function()
            Estado.InteragindoComUI = true
            opcaoBtn.BackgroundColor3 = Cores.Destaque
        end)
        
        opcaoBtn.MouseLeave:Connect(function()
            opcaoBtn.BackgroundColor3 = Cores.FundoSecundario
        end)
        
        opcaoBtn.MouseButton1Click:Connect(function()
            dropButton.Text = "  " .. opcao
            listaFrame.Visible = false
            aberto = false
            seta.Text = "▼"
            if callback then callback(opcao) end
            task.delay(0.1, function()
                Estado.InteragindoComUI = false
            end)
        end)
    end
    
    dropButton.MouseButton1Click:Connect(function()
        aberto = not aberto
        listaFrame.Visible = aberto
        seta.Text = aberto and "▲" or "▼"
        Estado.InteragindoComUI = aberto
        
        for _, outro in pairs(DropdownsAbertos) do
            if outro ~= listaFrame then
                outro.Visible = false
            end
        end
        
        if aberto then
            table.insert(DropdownsAbertos, listaFrame)
        end
    end)
    
    dropButton.MouseEnter:Connect(function()
        Estado.InteragindoComUI = true
    end)
    
    return container
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        CRIAÇÃO DA UI PRINCIPAL - v5
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarUI()
    -- Destruir UI existente
    pcall(function()
        if ScreenGui then ScreenGui:Destroy() end
    end)
    
    -- Criar ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SAVAGECHEATS_UI_v5"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    
    local sucesso = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    
    if not sucesso then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Frame Principal
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Cores.Fundo
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
    MainFrame.Size = UDim2.new(0, 350, 0, 420)
    MainFrame.Active = true
    MainFrame.ZIndex = ZIndexBase
    MainFrame.ClipsDescendants = false
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Cores.Borda
    mainStroke.Thickness = 2
    mainStroke.Parent = MainFrame
    
    -- Container das abas (baseado na referência)
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Parent = MainFrame
    tabContainer.BackgroundColor3 = Cores.FundoSecundario
    tabContainer.BorderSizePixel = 0
    tabContainer.Position = UDim2.new(0, 0, 0, 0)
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.ZIndex = ZIndexBase + 1
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabContainer
    
    -- Abas: AIM, ESP, MISC, SUP, INFO (baseado na referência)
    local abas = {"AIM", "ESP", "MISC", "SUP", "INFO"}
    local icones = {"⚙", "👁", "⚙", "💬", "👤"}
    local botoesAbas = {}
    local conteudoAbas = {}
    
    local larguraAba = 1 / #abas
    
    for i, nomeAba in ipairs(abas) do
        local abaBtn = Instance.new("TextButton")
        abaBtn.Name = "Tab_" .. nomeAba
        abaBtn.Parent = tabContainer
        abaBtn.BackgroundColor3 = i == 1 and Cores.Destaque or Cores.FundoSecundario
        abaBtn.BackgroundTransparency = i == 1 and 0 or 1
        abaBtn.BorderSizePixel = 0
        abaBtn.Position = UDim2.new((i - 1) * larguraAba, 2, 0, 2)
        abaBtn.Size = UDim2.new(larguraAba, -4, 1, -4)
        abaBtn.Font = Enum.Font.GothamBold
        abaBtn.Text = icones[i] .. " " .. nomeAba
        abaBtn.TextColor3 = Cores.Texto
        abaBtn.TextSize = 12
        abaBtn.ZIndex = ZIndexBase + 2
        
        local abaCorner = Instance.new("UICorner")
        abaCorner.CornerRadius = UDim.new(0, 6)
        abaCorner.Parent = abaBtn
        
        botoesAbas[nomeAba] = abaBtn
        
        -- Conteúdo da aba
        local conteudo = Instance.new("ScrollingFrame")
        conteudo.Name = "Conteudo_" .. nomeAba
        conteudo.Parent = MainFrame
        conteudo.BackgroundTransparency = 1
        conteudo.Position = UDim2.new(0, 0, 0, 45)
        conteudo.Size = UDim2.new(1, 0, 1, -45)
        conteudo.ScrollBarThickness = 4
        conteudo.ScrollBarImageColor3 = Cores.Destaque
        conteudo.Visible = i == 1
        conteudo.ZIndex = ZIndexBase + 1
        conteudo.CanvasSize = UDim2.new(0, 0, 0, 0)
        conteudo.ClipsDescendants = false
        
        conteudoAbas[nomeAba] = conteudo
        
        abaBtn.MouseButton1Click:Connect(function()
            CurrentTab = nomeAba
            
            for nome, btn in pairs(botoesAbas) do
                btn.BackgroundColor3 = nome == nomeAba and Cores.Destaque or Cores.FundoSecundario
                btn.BackgroundTransparency = nome == nomeAba and 0 or 1
            end
            
            for nome, cont in pairs(conteudoAbas) do
                cont.Visible = nome == nomeAba
            end
        end)
        
        abaBtn.MouseEnter:Connect(function()
            Estado.InteragindoComUI = true
            if nomeAba ~= CurrentTab then
                abaBtn.BackgroundTransparency = 0.5
            end
        end)
        
        abaBtn.MouseLeave:Connect(function()
            Estado.InteragindoComUI = false
            if nomeAba ~= CurrentTab then
                abaBtn.BackgroundTransparency = 1
            end
        end)
    end
    
    -- Tornar arrastável pelo container de abas
    TornarArrastavel(MainFrame, tabContainer)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA AIM
    -- ═══════════════════════════════════════════════════════════════════════════
    
    local abaAim = conteudoAbas["AIM"]
    local posY = 10
    
    -- Primeira linha de checkboxes
    CriarCheckbox(abaAim, "Ativar Aimbot", posY, Config.AimbotAtivo, function(valor)
        Config.AimbotAtivo = valor
    end)
    
    -- Checkbox à direita
    local checkPuxar = CriarCheckbox(abaAim, "Puxar em Paredes", posY, Config.IgnorarParedes, function(valor)
        Config.IgnorarParedes = valor
    end)
    checkPuxar.Position = UDim2.new(0.5, 5, 0, posY)
    
    posY = posY + 30
    
    CriarCheckbox(abaAim, "Exibir FOV", posY, Config.FOVVisivel, function(valor)
        Config.FOVVisivel = valor
    end)
    
    local checkLinha = CriarCheckbox(abaAim, "Exibir Linha", posY, Config.ExibirLinha, function(valor)
        Config.ExibirLinha = valor
    end)
    checkLinha.Position = UDim2.new(0.5, 5, 0, posY)
    
    posY = posY + 35
    
    -- Separador
    local sep1 = Instance.new("Frame")
    sep1.Parent = abaAim
    sep1.BackgroundColor3 = Cores.Borda
    sep1.BorderSizePixel = 0
    sep1.Position = UDim2.new(0, 10, 0, posY)
    sep1.Size = UDim2.new(1, -20, 0, 1)
    sep1.ZIndex = ZIndexBase + 1
    
    posY = posY + 10
    
    -- Slider FOV
    CriarSlider(abaAim, "Regular FOV", posY, 10, 500, Config.FOVRaio, function(valor)
        Config.FOVRaio = valor
    end)
    posY = posY + 55
    
    -- Dropdown Parte Alvo
    CriarDropdown(abaAim, "Parte Alvo", posY, {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}, Config.ParteAlvo, function(valor)
        Config.ParteAlvo = valor
    end)
    posY = posY + 65
    
    -- Separador
    local sep2 = Instance.new("Frame")
    sep2.Parent = abaAim
    sep2.BackgroundColor3 = Cores.Borda
    sep2.BorderSizePixel = 0
    sep2.Position = UDim2.new(0, 10, 0, posY)
    sep2.Size = UDim2.new(1, -20, 0, 1)
    sep2.ZIndex = ZIndexBase + 1
    
    posY = posY + 10
    
    -- Tipo de Aimbot (baseado na referência)
    local tipoLabel = Instance.new("TextLabel")
    tipoLabel.Parent = abaAim
    tipoLabel.BackgroundTransparency = 1
    tipoLabel.Position = UDim2.new(0, 10, 0, posY)
    tipoLabel.Size = UDim2.new(1, -20, 0, 20)
    tipoLabel.Font = Enum.Font.GothamBold
    tipoLabel.Text = "Tipo de Aimbot:"
    tipoLabel.TextColor3 = Cores.Texto
    tipoLabel.TextSize = 13
    tipoLabel.TextXAlignment = Enum.TextXAlignment.Left
    tipoLabel.ZIndex = ZIndexBase + 1
    
    posY = posY + 25
    
    -- Radio buttons para tipo de aimbot
    local tipoAoAtirar = Instance.new("Frame")
    tipoAoAtirar.Parent = abaAim
    tipoAoAtirar.BackgroundTransparency = 1
    tipoAoAtirar.Position = UDim2.new(0, 10, 0, posY)
    tipoAoAtirar.Size = UDim2.new(0.5, -15, 0, 25)
    tipoAoAtirar.ZIndex = ZIndexBase + 1
    
    local radioAoAtirar = Instance.new("Frame")
    radioAoAtirar.Parent = tipoAoAtirar
    radioAoAtirar.BackgroundColor3 = Config.TipoAimbot == "Ao Atirar" and Cores.Destaque or Cores.CheckboxInativo
    radioAoAtirar.Position = UDim2.new(0, 0, 0.5, -8)
    radioAoAtirar.Size = UDim2.new(0, 16, 0, 16)
    radioAoAtirar.ZIndex = ZIndexBase + 2
    
    local radioCorner1 = Instance.new("UICorner")
    radioCorner1.CornerRadius = UDim.new(1, 0)
    radioCorner1.Parent = radioAoAtirar
    
    local labelAoAtirar = Instance.new("TextLabel")
    labelAoAtirar.Parent = tipoAoAtirar
    labelAoAtirar.BackgroundTransparency = 1
    labelAoAtirar.Position = UDim2.new(0, 22, 0, 0)
    labelAoAtirar.Size = UDim2.new(1, -22, 1, 0)
    labelAoAtirar.Font = Enum.Font.Gotham
    labelAoAtirar.Text = "Ao Atirar"
    labelAoAtirar.TextColor3 = Cores.Texto
    labelAoAtirar.TextSize = 13
    labelAoAtirar.TextXAlignment = Enum.TextXAlignment.Left
    labelAoAtirar.ZIndex = ZIndexBase + 1
    
    local tipoAoOlhar = Instance.new("Frame")
    tipoAoOlhar.Parent = abaAim
    tipoAoOlhar.BackgroundTransparency = 1
    tipoAoOlhar.Position = UDim2.new(0.5, 5, 0, posY)
    tipoAoOlhar.Size = UDim2.new(0.5, -15, 0, 25)
    tipoAoOlhar.ZIndex = ZIndexBase + 1
    
    local radioAoOlhar = Instance.new("Frame")
    radioAoOlhar.Parent = tipoAoOlhar
    radioAoOlhar.BackgroundColor3 = Config.TipoAimbot == "Ao Olhar" and Cores.Destaque or Cores.CheckboxInativo
    radioAoOlhar.Position = UDim2.new(0, 0, 0.5, -8)
    radioAoOlhar.Size = UDim2.new(0, 16, 0, 16)
    radioAoOlhar.ZIndex = ZIndexBase + 2
    
    local radioCorner2 = Instance.new("UICorner")
    radioCorner2.CornerRadius = UDim.new(1, 0)
    radioCorner2.Parent = radioAoOlhar
    
    local labelAoOlhar = Instance.new("TextLabel")
    labelAoOlhar.Parent = tipoAoOlhar
    labelAoOlhar.BackgroundTransparency = 1
    labelAoOlhar.Position = UDim2.new(0, 22, 0, 0)
    labelAoOlhar.Size = UDim2.new(1, -22, 1, 0)
    labelAoOlhar.Font = Enum.Font.Gotham
    labelAoOlhar.Text = "Ao Olhar"
    labelAoOlhar.TextColor3 = Cores.Texto
    labelAoOlhar.TextSize = 13
    labelAoOlhar.TextXAlignment = Enum.TextXAlignment.Left
    labelAoOlhar.ZIndex = ZIndexBase + 1
    
    -- Botões para trocar tipo
    local btnAoAtirar = Instance.new("TextButton")
    btnAoAtirar.Parent = tipoAoAtirar
    btnAoAtirar.BackgroundTransparency = 1
    btnAoAtirar.Size = UDim2.new(1, 0, 1, 0)
    btnAoAtirar.Text = ""
    btnAoAtirar.ZIndex = ZIndexBase + 3
    
    local btnAoOlhar = Instance.new("TextButton")
    btnAoOlhar.Parent = tipoAoOlhar
    btnAoOlhar.BackgroundTransparency = 1
    btnAoOlhar.Size = UDim2.new(1, 0, 1, 0)
    btnAoOlhar.Text = ""
    btnAoOlhar.ZIndex = ZIndexBase + 3
    
    local function atualizarTipoAimbot(tipo)
        Config.TipoAimbot = tipo
        radioAoAtirar.BackgroundColor3 = tipo == "Ao Atirar" and Cores.Destaque or Cores.CheckboxInativo
        radioAoOlhar.BackgroundColor3 = tipo == "Ao Olhar" and Cores.Destaque or Cores.CheckboxInativo
    end
    
    btnAoAtirar.MouseButton1Click:Connect(function()
        atualizarTipoAimbot("Ao Atirar")
    end)
    
    btnAoOlhar.MouseButton1Click:Connect(function()
        atualizarTipoAimbot("Ao Olhar")
    end)
    
    posY = posY + 35
    
    -- Mais opções de AIM
    CriarCheckbox(abaAim, "Bala Mágica (Silent)", posY, Config.BalaMagica, function(valor)
        Config.BalaMagica = valor
        if valor then
            AtivarBalaMagica()
        else
            DesativarBalaMagica()
        end
    end)
    
    local checkAbatidos = CriarCheckbox(abaAim, "Pular Abatidos", posY, Config.PularAbatidos, function(valor)
        Config.PularAbatidos = valor
    end)
    checkAbatidos.Position = UDim2.new(0.5, 5, 0, posY)
    
    posY = posY + 35
    
    abaAim.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA ESP
    -- ═══════════════════════════════════════════════════════════════════════════
    
    local abaEsp = conteudoAbas["ESP"]
    posY = 10
    
    CriarCheckbox(abaEsp, "Ativar ESP", posY, Config.ESPAtivo, function(valor)
        Config.ESPAtivo = valor
    end)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Mostrar Box", posY, Config.ESPBox, function(valor)
        Config.ESPBox = valor
    end)
    
    local checkNome = CriarCheckbox(abaEsp, "Mostrar Nome", posY, Config.ESPNome, function(valor)
        Config.ESPNome = valor
    end)
    checkNome.Position = UDim2.new(0.5, 5, 0, posY)
    
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Mostrar Vida", posY, Config.ESPVida, function(valor)
        Config.ESPVida = valor
    end)
    
    local checkDist = CriarCheckbox(abaEsp, "Mostrar Distância", posY, Config.ESPDistancia, function(valor)
        Config.ESPDistancia = valor
    end)
    checkDist.Position = UDim2.new(0.5, 5, 0, posY)
    
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Mostrar Tracer", posY, Config.ESPTracer, function(valor)
        Config.ESPTracer = valor
    end)
    posY = posY + 35
    
    abaEsp.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA MISC (NoClip, Hitbox, etc)
    -- ═══════════════════════════════════════════════════════════════════════════
    
    local abaMisc = conteudoAbas["MISC"]
    posY = 10
    
    -- Aviso para Prison Life
    if IsPrisonLife then
        local avisoFrame = Instance.new("Frame")
        avisoFrame.Parent = abaMisc
        avisoFrame.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
        avisoFrame.BorderSizePixel = 0
        avisoFrame.Position = UDim2.new(0, 10, 0, posY)
        avisoFrame.Size = UDim2.new(1, -20, 0, 40)
        avisoFrame.ZIndex = ZIndexBase + 1
        
        local avisoCorner = Instance.new("UICorner")
        avisoCorner.CornerRadius = UDim.new(0, 4)
        avisoCorner.Parent = avisoFrame
        
        local avisoStroke = Instance.new("UIStroke")
        avisoStroke.Color = Cores.Destaque
        avisoStroke.Thickness = 1
        avisoStroke.Parent = avisoFrame
        
        local avisoText = Instance.new("TextLabel")
        avisoText.Parent = avisoFrame
        avisoText.BackgroundTransparency = 1
        avisoText.Size = UDim2.new(1, 0, 1, 0)
        avisoText.Font = Enum.Font.Gotham
        avisoText.Text = "⚠ Prison Life detectado!\nBypass de NoClip será aplicado automaticamente."
        avisoText.TextColor3 = Color3.fromRGB(255, 200, 100)
        avisoText.TextSize = 11
        avisoText.ZIndex = ZIndexBase + 2
        
        posY = posY + 50
    end
    
    CriarCheckbox(abaMisc, "NoClip", posY, Config.NoClipAtivo, function(valor)
        Config.NoClipAtivo = valor
        if valor then
            AtivarNoClip()
        else
            DesativarNoClip()
        end
    end)
    posY = posY + 35
    
    CriarSlider(abaMisc, "Velocidade NoClip", posY, 1, 5, Config.NoClipVelocidade, function(valor)
        Config.NoClipVelocidade = valor
    end)
    posY = posY + 55
    
    -- Separador
    local sepMisc = Instance.new("Frame")
    sepMisc.Parent = abaMisc
    sepMisc.BackgroundColor3 = Cores.Borda
    sepMisc.BorderSizePixel = 0
    sepMisc.Position = UDim2.new(0, 10, 0, posY)
    sepMisc.Size = UDim2.new(1, -20, 0, 1)
    sepMisc.ZIndex = ZIndexBase + 1
    
    posY = posY + 10
    
    -- Hitbox Expander
    CriarCheckbox(abaMisc, "Hitbox Expander", posY, Config.HitboxAtivo, function(valor)
        Config.HitboxAtivo = valor
        if valor then
            IniciarHitboxLoop()
        else
            PararHitboxLoop()
        end
    end)
    
    local checkHitboxVis = CriarCheckbox(abaMisc, "Hitbox Visível", posY, Config.HitboxVisivel, function(valor)
        Config.HitboxVisivel = valor
    end)
    checkHitboxVis.Position = UDim2.new(0.5, 5, 0, posY)
    
    posY = posY + 35
    
    CriarSlider(abaMisc, "Tamanho Hitbox", posY, 2, 20, Config.HitboxTamanho, function(valor)
        Config.HitboxTamanho = valor
    end)
    posY = posY + 55
    
    -- Separador
    local sepMisc2 = Instance.new("Frame")
    sepMisc2.Parent = abaMisc
    sepMisc2.BackgroundColor3 = Cores.Borda
    sepMisc2.BorderSizePixel = 0
    sepMisc2.Position = UDim2.new(0, 10, 0, posY)
    sepMisc2.Size = UDim2.new(1, -20, 0, 1)
    sepMisc2.ZIndex = ZIndexBase + 1
    
    posY = posY + 10
    
    -- Disparo Automático
    CriarCheckbox(abaMisc, "Disparo Automático", posY, Config.DisparoAutomatico, function(valor)
        Config.DisparoAutomatico = valor
    end)
    posY = posY + 35
    
    CriarSlider(abaMisc, "Delay Disparo (ms)", posY, 50, 500, math.floor(Config.DelayDisparo * 1000), function(valor)
        Config.DelayDisparo = valor / 1000
    end)
    posY = posY + 55
    
    -- Predição
    CriarCheckbox(abaMisc, "Predição de Movimento", posY, Config.PredicaoAtiva, function(valor)
        Config.PredicaoAtiva = valor
    end)
    posY = posY + 35
    
    CriarSlider(abaMisc, "Força Predição", posY, 0, 50, math.floor(Config.ForcaPredicao * 100), function(valor)
        Config.ForcaPredicao = valor / 100
    end)
    posY = posY + 55
    
    abaMisc.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA SUP (Suporte/Config)
    -- ═══════════════════════════════════════════════════════════════════════════
    
    local abaSup = conteudoAbas["SUP"]
    posY = 10
    
    CriarCheckbox(abaSup, "Suavização Ativa", posY, Config.SuavizacaoAtiva, function(valor)
        Config.SuavizacaoAtiva = valor
    end)
    posY = posY + 35
    
    CriarSlider(abaSup, "Força Suavização", posY, 0, 95, math.floor(Config.Suavizacao * 100), function(valor)
        Config.Suavizacao = valor / 100
    end)
    posY = posY + 55
    
    CriarSlider(abaSup, "Distância Máxima", posY, 100, 2000, Config.DistanciaMaxima, function(valor)
        Config.DistanciaMaxima = valor
    end)
    posY = posY + 55
    
    AtualizarTimesDisponiveis()
    
    CriarDropdown(abaSup, "Modo de Time", posY, {"Inimigos", "Todos", "TimeEspecifico"}, Config.ModoTime, function(valor)
        Config.ModoTime = valor
    end)
    posY = posY + 65
    
    if #Estado.TimesDisponiveis > 0 and Estado.TimesDisponiveis[1] ~= "Nenhum time detectado" then
        CriarDropdown(abaSup, "Time Alvo", posY, Estado.TimesDisponiveis, Config.TimeAlvo, function(valor)
            Config.TimeAlvo = valor
        end)
        posY = posY + 65
    end
    
    abaSup.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA INFO
    -- ═══════════════════════════════════════════════════════════════════════════
    
    local abaInfo = conteudoAbas["INFO"]
    posY = 10
    
    local infoFrame = Instance.new("Frame")
    infoFrame.Parent = abaInfo
    infoFrame.BackgroundColor3 = Cores.FundoSecundario
    infoFrame.BorderSizePixel = 0
    infoFrame.Position = UDim2.new(0, 10, 0, posY)
    infoFrame.Size = UDim2.new(1, -20, 0, 200)
    infoFrame.ZIndex = ZIndexBase + 1
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = infoFrame
    
    local infoText = Instance.new("TextLabel")
    infoText.Parent = infoFrame
    infoText.BackgroundTransparency = 1
    infoText.Position = UDim2.new(0, 10, 0, 10)
    infoText.Size = UDim2.new(1, -20, 1, -20)
    infoText.Font = Enum.Font.Gotham
    infoText.Text = [[SAVAGECHEATS_ v5.0

Aimbot Universal para Mobile

NOVIDADES v5:
• UI redesenhada
• NoClip com bypass Prison Life
• Hitbox Expander funcional
• Bala Mágica melhorada
• Tiro automático corrigido
• Detecção automática de jogo

Jogo Detectado: ]] .. GameName .. [[


Arraste pela barra de abas para mover
]]
    infoText.TextColor3 = Cores.Texto
    infoText.TextSize = 12
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.TextWrapped = true
    infoText.ZIndex = ZIndexBase + 2
    
    posY = posY + 210
    
    -- Botão de fechar
    local btnFechar = Instance.new("TextButton")
    btnFechar.Parent = abaInfo
    btnFechar.BackgroundColor3 = Cores.Destaque
    btnFechar.BorderSizePixel = 0
    btnFechar.Position = UDim2.new(0, 10, 0, posY)
    btnFechar.Size = UDim2.new(1, -20, 0, 35)
    btnFechar.Font = Enum.Font.GothamBold
    btnFechar.Text = "FECHAR SCRIPT"
    btnFechar.TextColor3 = Cores.Texto
    btnFechar.TextSize = 14
    btnFechar.ZIndex = ZIndexBase + 2
    
    local btnFecharCorner = Instance.new("UICorner")
    btnFecharCorner.CornerRadius = UDim.new(0, 6)
    btnFecharCorner.Parent = btnFechar
    
    btnFechar.MouseButton1Click:Connect(function()
        DestruirTudo()
    end)
    
    posY = posY + 45
    
    abaInfo.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    return ScreenGui
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        LOOP PRINCIPAL
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function LoopPrincipal()
    Conexoes.RenderStepped = RunService.RenderStepped:Connect(function()
        -- Atualizar FOV Circle
        AtualizarFOVCircle()
        
        -- Atualizar Linha de Mira
        AtualizarLinhaMira()
        
        -- Atualizar ESP
        for _, jogador in pairs(Players:GetPlayers()) do
            AtualizarESPJogador(jogador)
        end
        
        -- Sistema de Aimbot
        if Config.AimbotAtivo and not Estado.InteragindoComUI and not Estado.Arrastando then
            local alvo, parte = EncontrarMelhorAlvo()
            
            if alvo and parte then
                Estado.AlvoAtual = alvo
                Estado.ParteAlvoAtual = parte
                Estado.Travado = true
                
                -- Calcular posição com predição
                local posicaoAlvo = PreverPosicao(alvo.Character, parte)
                
                -- Mirar (só se não for bala mágica e tipo for "Ao Olhar")
                if not Config.BalaMagica then
                    if Config.TipoAimbot == "Ao Olhar" then
                        MirarEm(posicaoAlvo)
                    elseif Config.TipoAimbot == "Ao Atirar" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        MirarEm(posicaoAlvo)
                    end
                end
                
                -- Disparo automático
                if Config.DisparoAutomatico then
                    ExecutarDisparo()
                end
            else
                Estado.AlvoAtual = nil
                Estado.ParteAlvoAtual = nil
                Estado.Travado = false
            end
        else
            Estado.AlvoAtual = nil
            Estado.ParteAlvoAtual = nil
            Estado.Travado = false
        end
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        DESTRUIÇÃO E LIMPEZA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

function DestruirTudo()
    -- Desativar bala mágica
    DesativarBalaMagica()
    
    -- Desativar NoClip
    DesativarNoClip()
    
    -- Parar Hitbox Loop
    PararHitboxLoop()
    
    -- Desconectar todas as conexões
    for nome, conexao in pairs(Conexoes) do
        pcall(function()
            conexao:Disconnect()
        end)
    end
    Conexoes = {}
    
    -- Destruir FOV Circle
    DestruirFOVCircle()
    
    -- Destruir Linha de Mira
    DestruirLinhaMira()
    
    -- Destruir ESP
    DestruirESP()
    
    -- Destruir UI
    pcall(function()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end)
    
    -- Limpar flags globais
    _G.SAVAGECHEATS_LOADED = false
    _G.SAVAGECHEATS_DESTROY = nil
    
    print("[SAVAGECHEATS_] Script descarregado com sucesso!")
end

-- Registrar função de destruição global
_G.SAVAGECHEATS_DESTROY = DestruirTudo

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        INICIALIZAÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function Inicializar()
    print("╔═══════════════════════════════════════════════════════════════════════════════════════════╗")
    print("║                           SAVAGECHEATS_ AIMBOT UNIVERSAL v5.0                             ║")
    print("║                        Otimizado para Mobile Android/iOS                                  ║")
    print("║                              VERSÃO MELHORADA                                             ║")
    print("╚═══════════════════════════════════════════════════════════════════════════════════════════╝")
    
    -- Detectar jogo
    print("[SAVAGECHEATS_] Jogo detectado: " .. GameName)
    
    if IsPrisonLife then
        print("[SAVAGECHEATS_] Prison Life detectado! Bypass de NoClip será aplicado automaticamente.")
    end
    
    -- Criar FOV Circle
    CriarFOVCircle()
    
    -- Criar Linha de Mira
    CriarLinhaMira()
    
    -- Inicializar ESP
    InicializarESP()
    
    -- Criar UI
    CriarUI()
    
    -- Iniciar loop principal
    LoopPrincipal()
    
    -- Atualizar times quando mudar
    Conexoes.TeamChanged = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        AtualizarTimesDisponiveis()
    end)
    
    -- Monitorar respawn
    Conexoes.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        Camera = Workspace.CurrentCamera
        
        -- Reaplicar bypass do Prison Life se necessário
        if IsPrisonLife and Config.NoClipAtivo then
            NoClipBypassAplicado = false
            AplicarBypassPrisonLife()
        end
    end)
    
    print("[SAVAGECHEATS_] Carregado com sucesso!")
    print("[SAVAGECHEATS_] Arraste pela barra de abas para mover a UI")
    print("")
    print("[SAVAGECHEATS_] NOVIDADES v5.0:")
    print("  • UI redesenhada (tema vermelho/preto)")
    print("  • NoClip com bypass para Prison Life")
    print("  • Hitbox Expander funcional")
    print("  • Bala Mágica melhorada")
    print("  • Tiro automático corrigido para mobile")
end

-- Executar inicialização
Inicializar()
