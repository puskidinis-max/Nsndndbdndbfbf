-- =====================================================================================
-- SWILL MOBILE OMNI-FRAMEWORK v1.0 (ANDROID / IOS ADAPTED)
-- =====================================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    AimbotEnabled = true,
    WallCheck = true,
    TargetPart = "Head", -- По умолчанию наводится только на голову
    TeamCheck = false
}

-- Проверка видимости стен через Raycast
local function IsVisible(targetPart, character)
    if not Config.WallCheck then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = RaycastParams.FilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    rayParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = Workspace:Raycast(origin, direction, rayParams)
    
    if result then
        return result.Instance:IsDescendantOf(character)
    end
    return true
end

-- Поиск ближайшего игрока на экране телефона
local function GetClosestTarget()
    local bestTarget = nil
    local shortestDist = math.huge
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
                        if dist < shortestDist then
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

-- Мобильный цикл наведения на цель
RunService.RenderStepped:Connect(function()
    if Config.AimbotEnabled then
        local target = GetClosestTarget()
        if target then
            -- Мгновенный поворот камеры на цель (голову)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

-- =====================================================================================
-- МОБИЛЬНЫЙ ГРАФИЧЕСКИЙ ИНТЕРФЕЙС (UI ДЛЯ ТЕЛЕФОНОВ)
-- =====================================================================================

for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui.Name == "SwillMobileUI" then gui:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SwillMobileUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- Главное окно меню
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -140)
MainFrame.Size = UDim2.new(0, 300, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Верхняя панель
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
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Font = Enum.Font.Code
Title.Text = "SWILL MOBILE MENU"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Кнопка закрытия меню
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

-- Плавающая кнопка для повторного открытия меню на экране телефона
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

-- Иконка человека (Выбор хитбокса - Голова)
local ManikinBox = Instance.new("Frame")
ManikinBox.Parent = MainFrame
ManikinBox.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
ManikinBox.Position = UDim2.new(0, 15, 0, 45)
ManikinBox.Size = UDim2.new(0, 110, 0, 100)

local ManikinCorner = Instance.new("UICorner")
ManikinCorner.CornerRadius = UDim.new(0, 6)
ManikinCorner.Parent = ManikinBox

local HeadBtn = Instance.new("TextButton")
HeadBtn.Parent = ManikinBox
HeadBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 128) -- Зеленый = активна голова
HeadBtn.Position = UDim2.new(0.5, -18, 0, 10)
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
HitboxLabel.Position = UDim2.new(0, 0, 0, 55)
HitboxLabel.Size = UDim2.new(1, 0, 0, 40)
HitboxLabel.Font = Enum.Font.Code
HitboxLabel.Text = "Цель:\n[ГОЛОВА]"
HitboxLabel.TextColor3 = Color3.fromRGB(0, 255, 170)
HitboxLabel.TextSize = 9

HeadBtn.MouseButton1Click:Connect(function()
    Config.TargetPart = "Head"
    HitboxLabel.Text = "Цель:\n[ГОЛОВА]"
end)

-- Функция создания кнопок в меню
local function CreateButton(text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    btn.Position = UDim2.new(0, 135, 0, posY)
    btn.Size = UDim2.new(0, 150, 0, 45)
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

CreateButton("WallCheck: ON", 100, function(b)
    Config.WallCheck = not Config.WallCheck
    b.Text = "WallCheck: " .. (Config.WallCheck and "ON" or "OFF")
end)

print("[SWILL]: Mobile framework loaded successfully.")
