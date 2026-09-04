-- =====================================================================================
-- SWILL ULTRA MOBILE v3.0 (PREMIUM ESP + FIXED WALLCHECK + CUSTOM FOV + AUTO-SHOOT)
-- =====================================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    AimbotEnabled = true,
    AutoShoot = true,
    NoRecoil = true,
    ESPEnabled = true,
    WallCheck = true,
    TargetPart = "Head",
    TeamCheck = false,
    FOV = 250 -- Настраиваемый радиус FOV
}

-- Улучшенный WallCheck с правильным исключением персонажей
local function IsVisible(targetPart, character)
    if not Config.WallCheck then return true end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    -- Исключаем своего персонажа и целевого персонажа из луча
    local filterList = {LocalPlayer.Character}
    if character then
        table.insert(filterList, character)
    end
    rayParams.FilterDescendantsInstances = filterList
    rayParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local result = Workspace:Raycast(origin, direction, rayParams)
    
    -- Если луч никого не встретил до цели или попал прямо в цель — значит, видно
    if not result or result.Instance:IsDescendantOf(character) then
        return true
    end
    return false
end

-- Поиск цели с учетом FOV и исправленного WallCheck
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
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if screenDist <= shortestDist then
                            if IsVisible(targetPart, char) then
                                shortestDist = screenDist
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

-- Красивый мобильный ESP (Плавные рамки, никнейм и полоска здоровья)
local ESPCache = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SwillESP_Pro"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 70, 0, 90)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    
    -- Главная рамка вокруг игрока
    local box = Instance.new("Frame")
    box.Parent = billboard
    box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    box.BackgroundTransparency = 0.85
    box.BorderColor3 = Color3.fromRGB(0, 255, 170)
    box.BorderSizePixel = 1
    box.Size = UDim2.new(1, 0, 1, 0)
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box
    
    -- Текст с ником и здоровьем
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = billboard
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 0, -0.3, 0)
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.Font = Enum.Font.Code
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 10
    nameLabel.TextStrokeTransparency = 0.3
    
    -- Полоска здоровья (HP Bar)
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Parent = box
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Position = UDim2.new(0, -5, 0, 0)
    hpBarBg.Size = UDim2.new(0, 3, 1, 0)
    
    local hpBarFill = Instance.new("Frame")
    hpBarFill.Parent = hpBarBg
    hpBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hpBarFill.BorderSizePixel = 0
    hpBarFill.Size = UDim2.new(1, 0, 1, 0)

    billboard.Parent = CoreGui
    ESPCache[player] = {Gui = billboard, Fill = hpBarFill, Label = nameLabel}
end

local function RemoveESP(player)
    if ESPCache[player] then
        ESPCache[player].Gui:Destroy()
        ESPCache[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- Главный игровой цикл
RunService.RenderStepped:Connect(function()
    local target = GetClosestTarget()
    
    -- Аим и авто-выстрел
    if Config.AimbotEnabled and target then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        
        if Config.AutoShoot then
            pcall(function()
                VirtualUser:Button1Down(Vector2.new(0,0))
                task.wait(0.04)
                VirtualUser:Button1Up(Vector2.new(0,0))
            end)
        end
    end
    
    -- Анти-отдача
    if Config.NoRecoil and LocalPlayer.Character then
        local shaker = LocalPlayer.Character:FindFirstChild("CameraShaker")
        if shaker then shaker:Destroy() end
        local cameraScript = LocalPlayer.Character:FindFirstChild("Recoil")
        if cameraScript then cameraScript:Destroy() end
    end
    
    -- Обновление красивого ESP
    for player, data in pairs(ESPCache) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if Config.ESPEnabled and char and root and hum and hum.Health > 0 then
            data.Gui.Adornee = root
            data.Gui.Enabled = true
            -- Динамическое заполнение полоски здоровья
            local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            data.Fill.Size = UDim2.new(1, 0, healthPercent, 0)
            data.Fill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
        else
            data.Gui.Enabled = false
        end
    end
end)

-- =====================================================================================
-- ПОЛЬЗОВАТЕЛЬСКИЙ ИНТЕРФЕЙС (МЕНЮ)
-- =====================================================================================

for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui.Name == "SwillMobileUIv3" then gui:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SwillMobileUIv3"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.Position = UDim2.new(0.5, -165, 0.5, -160)
MainFrame.Size = UDim2.new(0, 330, 0, 320)
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
Title.Size = UDim2.new(0, 240, 1, 0)
Title.Font = Enum.Font.Code
Title.Text = "SWILL ULTRA v3.0 [PRO]"
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

-- Иконка человека (Выбор головы)
local ManikinBox = Instance.new("Frame")
ManikinBox.Parent = MainFrame
ManikinBox.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
ManikinBox.Position = UDim2.new(0, 15, 0, 45)
ManikinBox.Size = UDim2.new(0, 110, 0, 110)

local ManikinCorner = Instance.new("UICorner")
ManikinCorner.CornerRadius = UDim.new(0, 6)
ManikinCorner.Parent = ManikinBox

local HeadBtn = Instance.new("TextButton")
HeadBtn.Parent = ManikinBox
HeadBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
HeadBtn.Position = UDim2.new(0.5, -18, 0, 12)
HeadBtn.Size = UDim2.new(0, 36, 0, 36)
HeadBtn.Font = Enum.Font.Code
HeadBtn.Text = "HEAD"
HeadBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
HeadBtn.TextSize = 7

local HeadCorner = Instance.new("UICorner")
HeadCorner.CornerRadius = UDim.new(0, 18)
HeadCorner.Parent = HeadBtn

local HitboxLabel = Instance.new("TextLabel")
HitboxLabel.Parent = ManikinBox
HitboxLabel.BackgroundTransparency = 1
HitboxLabel.Position = UDim2.new(0, 0, 0, 58)
HitboxLabel.Size = UDim2.new(1, 0, 0, 40)
HitboxLabel.Font = Enum.Font.Code
HitboxLabel.Text = "Цель:\n[ГОЛОВА]"
HitboxLabel.TextColor3 = Color3.fromRGB(0, 255, 170)
HitboxLabel.TextSize = 9

HeadBtn.MouseButton1Click:Connect(function()
    Config.TargetPart = "Head"
end)

local function CreateButton(text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    btn.Position = UDim2.new(0, 135, 0, posY)
    btn.Size = UDim2.new(0, 180, 0, 32)
    btn.Font = Enum.Font.Code
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    
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

CreateButton("Auto-Shoot: ON", 82, function(b)
    Config.AutoShoot = not Config.AutoShoot
    b.Text = "Auto-Shoot: " .. (Config.AutoShoot and "ON" or "OFF")
end)

CreateButton("Anti-Recoil: ON", 119, function(b)
    Config.NoRecoil = not Config.NoRecoil
    b.Text = "Anti-Recoil: " + (Config.NoRecoil and "ON" or "OFF")
end)

CreateButton("ESP Pro: ON", 156, function(b)
    Config.ESPEnabled = not Config.ESPEnabled
    b.Text = "ESP Pro: " .. (Config.ESPEnabled and "ON" or "OFF")
end)

CreateButton("WallCheck: ON", 193, function(b)
    Config.WallCheck = not Config.WallCheck
    b.Text = "WallCheck: " .. (Config.WallCheck and "ON" or "OFF")
end)

CreateButton("FOV Range: 250", 230, function(b)
    Config.FOV = Config.FOV + 100
    if Config.FOV > 550 then Config.FOV = 150 end
    b.Text = "FOV Range: " .. Config.FOV
end)

print("[SWILL]: v3.0 Pro framework initialized successfully.")
