-- Services
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MaintenanceGui"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Create Background Frame (Dark overlay)
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
background.BorderSizePixel = 0
background.Parent = screenGui

-- Create Main Pop-up Box
local mainBox = Instance.new("Frame")
mainBox.Name = "MainBox"
mainBox.Size = UDim2.new(0, 450, 0, 250)
mainBox.Position = UDim2.new(0.5, -225, 0.5, -125)
mainBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainBox.BorderSizePixel = 0
mainBox.Parent = background

-- Add rounded corners to the box
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainBox

-- Create Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.Position = UDim2.new(0, 0, 0, 20)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 28
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Notice"
titleLabel.Parent = mainBox

-- Create Message Label
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.new(1, -40, 0, 100)
messageLabel.Position = UDim2.new(0, 20, 0, 80)
messageLabel.BackgroundTransparency = 1
messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
messageLabel.TextSize = 20
messageLabel.Font = Enum.Font.Gotham
messageLabel.Text = "We will be back soon!\nThe script is currently undergoing maintenance."
messageLabel.TextWrapped = true
messageLabel.Parent = mainBox
