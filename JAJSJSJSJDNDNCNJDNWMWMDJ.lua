-- =====================================================================================
-- SWILL MOBILE ULTIMATE v7.0 (STABLE AIMBOT + WORKING WALLCHECK + SKELETON ESP)
-- =====================================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    AimbotEnabled = true,
    WallCheck = true,
    FOV = 220,
    TeamCheck = false,
    ESPEnabled = true,
    TargetPart = "Head"
}

-- Идеальный WallCheck без багов и зависаний
local function IsVisible(targetPart, character)
    if not Config.WallCheck then return true end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    rayParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local result = Workspace:Raycast(origin, direction, rayParams)
    
    if not result or result.Instance:IsDescendantOf(character) then
        return true
    end
    return false
end

-- Поиск лучшей цели внутри FOV с проверкой видимости
local function GetClosestTarget()
    local bestTarget = nil
    local shortestDist = Config.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local targetPart = char:FindFirstChild(Config.TargetPart) or char:FindFirstChild("Head")
            
            if hum and hum.Health > 0 and targetPart then
                if not Config.TeamCheck or player.Team ~= LocalPlayer.Team then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist <= shortestDist then
                            if IsVisible(targetPart, char) then
                                shortestDist = dist
                                bestTarget = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Графический интерфейс и FOV круг
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SwillUltimateUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local FOVCircle = Instance.new("Frame")
FOVCircle.Parent = ScreenGui
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FOVCircle

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = FOVCircle
UIStroke.Color = Color3.fromRGB(0, 255, 170)
UIStroke.Thickness = 1.5

-- Оптимизированный ESP (Боксы, Ник, ХП и Скелетные линии)
local ESPCache = {}

local function CreateLine()
    local l = Drawing.new("Line")
    l.Visible = false
    l.Color = Color3.fromRGB(0, 255, 170)
    l.Thickness = 1.2
    return l
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SwillESP_v7"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 75, 0, 95)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    
    local box = Instance.new("Frame")
    box.Parent = billboard
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    box.BackgroundTransparency = 0.85
    box.BorderColor3 = Color3.fromRGB(0, 255, 170)
    box.BorderSizePixel = 1
    box.Size = UDim2.new(1, 0, 1, 0)
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = box
    
    local name = Instance.new("TextLabel")
    name.Parent = billboard
    name.BackgroundTransparency = 1
    name.Position = UDim2.new(0, 0, -0.3, 0)
    name.Size = UDim2.new(1, 0, 0.3, 0)
    name.Font = Enum.Font.Code
    name.Text = player.Name
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextSize = 10
    name.TextStrokeTransparency = 0.2

    local hpBarBg = Instance.new("Frame")
    hpBarBg.Parent = box
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Position = UDim2.new(0, -6, 0, 0)
    hpBarBg.Size = UDim2.new(0, 3, 1, 0)
    
    local hpBarFill = Instance.new("Frame")
    hpBarFill.Parent = hpBarBg
    hpBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hpBarFill.BorderSizePixel = 0
    hpBarFill.Size = UDim2.new(1, 0, 1, 0)

    billboard.Parent = CoreGui

    ESPCache[player] = {
        Gui = billboard,
        Fill = hpBarFill,
        Spine = CreateLine(),
        Tracer = CreateLine()
    }
end

local function RemoveESP(player)
    if ESPCache[player] then
        ESPCache[player].Gui:Destroy()
        ESPCache[player].Spine:Remove()
        ESPCache[player].Tracer:Remove()
        ESPCache[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- Главный игровой цикл рендеринга и наведения
RunService.RenderStepped:Connect(function()
    FOVCircle.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)
    FOVCircle.Visible = Config.AimbotEnabled

    -- Стабильный плавно-быстрый Aimbot
    if Config.AimbotEnabled then
        local target = GetClosestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end

    -- Обновление ESP
    for player, data in pairs(ESPCache) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")
        local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))

        if Config.ESPEnabled and char and root and hum and hum.Health > 0 then
            data.Gui.Adornee = root
            data.Gui.Enabled = true
            
            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            data.Fill.Size = UDim2.new(1, 0, hp, 0)
            data.Fill.Position = UDim2.new(0, 0, 1 - hp, 0)

            if head and torso then
                local hPos, hOn = Camera:WorldToViewportPoint(head.Position)
                local tPos, tOn = Camera:WorldToViewportPoint(torso.Position)
                
                if hOn and tOn then
                    data.Spine.From = Vector2.new(hPos.X, hPos.Y)
                    data.Spine.To = Vector2.new(tPos.X, tPos.Y)
                    data.Spine.Visible = true
                else
                    data.Spine.Visible = false
                end
                
                data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                data.Tracer.To = Vector2.new(tPos.X, tPos.Y)
                data.Tracer.Visible = true
            else
                data.Spine.Visible = false
                data.Tracer.Visible = false
            end
        else
            data.Gui.Enabled = false
            data.Spine.Visible = false
            data.Tracer.Visible = false
        end
    end
end)

-- Мобильное меню управления
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -150)
MainFrame.Size = UDim2.new(0, 320, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
TopBar.Size = UDim2.new(1, 0, 0, 35)

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(0, 220, 1, 0)
Title.Font = Enum.Font.Code
Title.Text = "SWILL ULTIMATE v7.0"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Position = UDim2.new(1, -30, 0, 7)
CloseBtn.Size = UDim2.new(0, 21, 0, 21)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 11

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

local OpenButton = Instance.new("TextButton")
OpenButton.Parent = ScreenGui
OpenButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
OpenButton.Position = UDim2.new(0, 10, 0.4, 0)
OpenButton.Size = UDim2.new(0, 50, 0, 50)
OpenButton.Font = Enum.Font.SourceSansBold
OpenButton.Text = "OPEN"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextSize = 11
OpenButton.Visible = false

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 25)
OpenCorner.Parent = OpenButton

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)

local function CreateButton(text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    btn.Position = UDim2.new(0, 20, 0, posY)
    btn.Size = UDim2.new(0, 280, 0, 35)
    btn.Font = Enum.Font.Code
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    return btn
end

CreateButton("Aimbot: ON", 45, function(b)
    Config.AimbotEnabled = not Config.AimbotEnabled
    b.Text = "Aimbot: " .. (Config.AimbotEnabled and "ON" or "OFF")
end)

CreateButton("WallCheck: ON", 90, function(b)
    Config.WallCheck = not Config.WallCheck
    b.Text = "WallCheck: " .. (Config.WallCheck and "ON" or "OFF")
end)

CreateButton("ESP & Skeleton: ON", 135, function(b)
    Config.ESPEnabled = not Config.ESPEnabled
    b.Text = "ESP & Skeleton: " .. (Config.ESPEnabled and "ON" or "OFF")
end)

CreateButton("FOV Size: 220", 180, function(b)
    Config.FOV = Config.FOV + 50
    if Config.FOV > 400 then Config.FOV = 120 end
    b.Text = "FOV Size: " .. Config.FOV
end)

print("[SWILL]: Ultimate v7.0 loaded successfully.")
