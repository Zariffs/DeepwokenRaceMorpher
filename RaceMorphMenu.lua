
if not game:IsLoaded() then
	game.Loaded:Wait()
end

game:GetService("StarterGui"):SetCore("SendNotification",{
	Title = "Morph Gui's Loading...",
	Text = "(LeftCtrl + LeftAlt is the current shortcut.)",
	Duration = 10
})

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIP = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = ((RunService:IsStudio() and LocalPlayer.PlayerGui) or game.CoreGui)
local Slot = LocalPlayer:GetAttribute("DataSlot")

local AskedForRace = {}
local CURRENT_PROMPTING = false


if (not Slot or Slot == "") then	
	if RunService:IsStudio() then
		Slot = "STUDIO"
	else 
		repeat
			task.wait()
			Slot = LocalPlayer:GetAttribute("DataSlot")
		until not (not Slot or Slot == "")		
	end
end
--
local LoadedFiles = {}
local RaceConfig = {}
local GuildMates = {}

local Settings = {
	RespectOathEyeColor = true,
	--MixAndMatch = false,
	ReplicateToGuildMates = false,
	--DecideRelationships = false,
	--ForceVisionShaperEye = false,
	HideOathOrnaments = false,
	LastRace = "Adret",
	AskedForGlobal = {}
}

local OurChoices = {
	["CON_FIG_DEEZ_NUTS_IN_YO_MOUF"] = Settings
}

local MainGui -- synasset.

if RunService:IsStudio() then
	MainGui = script:WaitForChild("MorphGui")
else 	
	if not isfolder("DeepwokenMorphData") then
		LocalPlayer:Kick("Race Morph Checksum : \nThe Script couldn't find the whole folder, please make sure to set up the files correctly.")
	end

	if not isfile("DeepwokenMorphData/GuiItself.rbxm") then
		LocalPlayer:Kick("Race Morph Checksum : \nThe Script couldn't find the GUI, please make sure to set up the files correctly.")
	end

	MainGui = game:GetObjects(getsynasset("DeepwokenMorphData/GuiItself.rbxm"))[1]
end

local GlobalAssets = MainGui:WaitForChild("GlobalOrnaments")
GlobalAssets.Parent = script

local EnchantEffects = MainGui:WaitForChild("EnchantmentEffects")
EnchantEffects.Parent = script

if not RunService:IsStudio() then
	if isfolder("DeepwokenMorphData/CustomEnchantments") then
		local Files = syn_io_listdir("DeepwokenMorphData/CustomEnchantments")
		for i,File in pairs(Files) do 
			local LoadedEnchantment = game:GetObjects(getsynasset(File))[1]
			if EnchantEffects:FindFirstChild(LoadedEnchantment.Name) then
				EnchantEffects[LoadedEnchantment.Name]:Destroy()
			end
			LoadedEnchantment.Parent = EnchantEffects
		end
	end

	if isfolder("DeepwokenMorphData/CustomGlobalOrnaments") then
		local Files = syn_io_listdir("DeepwokenMorphData/CustomGlobalOrnaments")
		for i,File in pairs(Files) do 
			local NewOrnament = game:GetObjects(getsynasset(File))[1]
			NewOrnament.Parent = GlobalAssets
		end
	end
end

local OathEffects = MainGui:WaitForChild("OathOrnaments")
OathEffects.Parent = script

local CustomAccourtments = MainGui:WaitForChild("CustomAccourtments")
CustomAccourtments.Parent = script

local ExtraFaces = MainGui:WaitForChild("ExtraDeepFaces")
ExtraFaces.Parent = script

local MainFrame = MainGui:WaitForChild("CharacterFrame")

local TemplateButtons  = MainGui:WaitForChild("TemplateButtons")
TemplateButtons.Parent = script

local ColorPicker = MainFrame:WaitForChild("ColorPicker")

local CharacterMain = MainFrame:WaitForChild("Characters")
local CharacterPageLayout = CharacterMain:WaitForChild("UIPageLayout")

local Gradient = MainFrame:WaitForChild("Gradient")
local ConfigButtons = MainFrame:WaitForChild("Configuration")
local ConfigFrames = MainFrame:WaitForChild("ConfigMain")

local OurDescriptor = Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)

-- Deepwoken Assets
local DeepRaces = ReplicatedStorage:WaitForChild("Info"):WaitForChild("Races")
local DeepAssets = ReplicatedStorage:WaitForChild("Assets")

local DeepFaces = DeepAssets:WaitForChild("Faces")
local DeepFacialMarkings = DeepAssets:WaitForChild("FacialMarkings")
local DeepSclera = DeepAssets:WaitForChild("Sclera")
local DeepVespDesigns = DeepAssets:WaitForChild("VespDesigns")
local DeepOrnaments = DeepAssets:WaitForChild("RaceOrnaments")
-- Functions
local OutfitCache = {}
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local function tablefind(Haystack,Needle)
	for i,v in pairs(Haystack) do 
		if v == Needle then
			return i
		end
	end
	return nil
end

local function LoadMorphScript(Chunk,Ornament,Character,CurrentVarient)
	local NewEnv = {
		Character = Character,
		CurrentVarient = CurrentVarient
	}
	local Success,MainFunction

	if RunService:IsStudio() then
		Success,MainFunction = pcall(function()
			return function()
				for i,v in pairs(getfenv(1)) do 
					print(i,v)
				end

			end
		end)
	else 
		Success,MainFunction = pcall(function()
			return loadstring(
				Chunk
			)
		end)
	end


	if Success then
		local CurrentFuncENV = getfenv(MainFunction)
		CurrentFuncENV.Character = Character
		CurrentFuncENV.CurrentVarient = CurrentVarient
		CurrentFuncENV.Ornament = Ornament

		setfenv(MainFunction,CurrentFuncENV)

		local SeperateTask = task.spawn(MainFunction)
		return SeperateTask
	else 
		return nil
	end
end

local function FetchOutfitsForTarget(UserId)
	local Success,Request = nil,nil


	local Output = {
		UserId = UserId,
		Outfits = {}
	}

	if OutfitCache[UserId] then
		return OutfitCache[UserId]
	end

	if RunService:IsStudio() then
		Success,Request = pcall(function()
			return ReplicatedStorage.HttpRequest:InvokeServer(
				"https://avatar.roproxy.com/v1/users/"..UserId.."/outfits?page=1&itemsPerPage=100"
			)
		end)
	else 
		Success,Request = pcall(function()
			return game:HttpGet(
				"https://avatar.roblox.com/v1/users/"..UserId.."/outfits?page=1&itemsPerPage=100"
			)
		end)
	end


	if Success then
		local Data = HttpService:JSONDecode(Request).data
		for i,v in pairs(Data) do 
			if typeof(v) == "table" then
				Output.Outfits[i] = v.id
			end
		end
	else 
		--	warn(Request)
	end

	OutfitCache[UserId] = Output

	return Output
end

local UserDataCache = {
	UserNames = {},
	Descriptions = {}
}

local function GetUserId(UserName)
	if UserDataCache.UserNames[UserName] then
		return UserDataCache.UserNames[UserName]
	end

	local Success,UserId = pcall(function()
		return Players:GetUserIdFromNameAsync(UserName)
	end)

	if Success then
		UserDataCache.UserNames[UserName] = UserId
		return UserId
	else 
		return false
	end
end

local function GetUserDescription(UserId)
	if UserDataCache.Descriptions[UserId] then
		return UserDataCache.Descriptions[UserId]
	end

	local Success,UserData = nil,nil

	if RunService:IsStudio() then
		Success,UserData = pcall(function()
			--return game:HttpGet("https://users.roproxy.com/v1/users/"..UserId)
			return ReplicatedStorage.HttpRequest:InvokeServer(
				"https://users.roproxy.com/v1/users/"..UserId
			)
		end)
	else 
		Success,UserData = pcall(function()
			return game:HttpGet("https://users.roblox.com/v1/users/"..UserId)
		end)

	end

	if Success then
		local DeCoded = HttpService:JSONDecode(UserData)
		if DeCoded.description then
			UserDataCache.Descriptions[UserId] = DeCoded.description 
			return DeCoded.description 
		else 
			UserDataCache.Descriptions[UserId] = "Woah It's You!"
			return "Woah It's You!"
		end
	else 
		return "Woah It's You!"
	end
end

local function Tween(object,properties,time,style,dir,repeats,reverse,delay)
	local info = TweenInfo.new(time or 1,style or Enum.EasingStyle.Linear,dir or Enum.EasingDirection.Out,repeats or 0,reverse or false,delay or 0)
	local tween = TweenService:Create(object,info,properties)
	tween:Play()
	return tween;
end

local function ConnectWings(RootPart)
	local Sine = 0
	local Connection
	local WingMesh = RootPart.Parent.HelioWings

	local Joints = {
		Left = {
			RootPart["Wing1.L"],
			RootPart["Wing1.L"]["Wing2.L"],
			RootPart["Wing1.L"]["Wing2.L"]["Wing3.L"],
			RootPart["Wing1.L"]["Wing2.L"]["Wing3.L"]["Wing4.L"],
			RootPart["Wing1.L"]["Wing2.L"]["Wing3.L"]["Wing4.L"]["Wing5.L"],
			RootPart["Wing1.L"]["Wing2.L"]["Wing3.L"]["Wing4.L"]["Wing5.L"]["Wing6.L"],
			RootPart["Wing1.L"]["Wing2.L"]["Wing3.L"]["Wing4.L"]["Wing5.L"]["Wing6.L"]["Wing7.L"],
			RootPart["Wing1.L"]["Wing2.L"]["Wing3.L"]["Wing4.L"]["Wing5.L"]["Wing6.L"]["Wing7.L"]["Wing8.L"],

		},
		Right = {
			RootPart["Wing1.R"],
			RootPart["Wing1.R"]["Wing2.R"],
			RootPart["Wing1.R"]["Wing2.R"]["Wing3.R"],
			RootPart["Wing1.R"]["Wing2.R"]["Wing3.R"]["Wing4.R"],
			RootPart["Wing1.R"]["Wing2.R"]["Wing3.R"]["Wing4.R"]["Wing5.R"],
			RootPart["Wing1.R"]["Wing2.R"]["Wing3.R"]["Wing4.R"]["Wing5.R"]["Wing6.R"],
			RootPart["Wing1.R"]["Wing2.R"]["Wing3.R"]["Wing4.R"]["Wing5.R"]["Wing6.R"]["Wing7.R"],
			RootPart["Wing1.R"]["Wing2.R"]["Wing3.R"]["Wing4.R"]["Wing5.R"]["Wing6.R"]["Wing7.R"]["Wing8.R"],
		}
	}

	local Items = {
		AnimationSpeed = 1,
		CurrentAnimation = "Idle",
		PlayingLoop = false
	}	

	Connection = task.spawn(function()
		repeat
			if Items.PlayingLoop == true then
				Sine+=1
				task.wait()
				if Items.CurrentAnimation == "Fly" then
					for i = 1,8 do 
						local l = (8 - i)
						local L,R = Joints.Left[i],Joints.Right[i]
						L.Transform = L.Transform:Lerp(CFrame.Angles(math.rad(0 - (4*l) * math.sin((Sine + (l*7))/(15/Items.AnimationSpeed))),0,0),.1)
						R.Transform = R.Transform:Lerp(CFrame.Angles(math.rad(0 - (4*l) * math.sin((Sine + (l*7))/(15/Items.AnimationSpeed))),0,0),.1)
					end

				elseif Items.CurrentAnimation == "Glide" then
					for i = 1,8 do 
						local l = (8 - i)
						local L,R = Joints.Left[i],Joints.Right[i]
						L.Transform = L.Transform:Lerp(CFrame.Angles(math.rad((l*1.1) + l * math.cos((Sine + l*10)/(3/Items.AnimationSpeed))),0,math.rad(((4*l)/2) + (l) * math.sin((Sine + l*10)/(6/Items.AnimationSpeed)))),.1)
						R.Transform = R.Transform:Lerp(CFrame.Angles(math.rad((l*1.1) + l * math.cos((Sine - l*10)/(3/Items.AnimationSpeed))),0,math.rad(-((4*l)/2) - (l) * math.sin((Sine + l*10)/(6/Items.AnimationSpeed)))),.1)
					end
				elseif Items.CurrentAnimation == "Idle" then
					for i = 1,8 do 
						local l = (8 - i)
						local L,R = Joints.Left[i],Joints.Right[i]

						L.Transform = L.Transform:Lerp(CFrame.Angles(0,0,math.rad((l*1.1) - (l/4) * math.sin((Sine + l*10)/(30/Items.AnimationSpeed)))),.1)
						R.Transform = R.Transform:Lerp(CFrame.Angles(0,0,math.rad(-(l*1.1) + (l/4) * math.sin((Sine + l*10)/(30/Items.AnimationSpeed)))),.1)
					end
				end
			else 
				task.wait()
			end
		until nil
	end)

	game.ContentProvider:PreloadAsync(
		{
			WingMesh.Summon,WingMesh.Attachment.BurstCore
		}
	)

	local function PlayAnimation(Name)
		if Name == "Appear" then
			Items.PlayingLoop = false
			WingMesh.Transparency = 1
			WingMesh.Summon:Play()
			wait(.2)
			WingMesh.Attachment.FallOff:Emit(20)
			WingMesh.Attachment.BurstCore:Emit(5)
			WingMesh.Attachment.Burst:Emit(20)
			wait(.3)
			WingMesh.Transparency = 0
			Items.PlayingLoop = true
			PlayAnimation("Idle")
		else 
			Items.CurrentAnimation = Name
			Items.PlayingLoop = true
		end
	end

	return PlayAnimation,Connection
end

local function TheSwordTilter(Root)
	--warn("what")
	task.spawn(function()
		local apl = Root.l
		local aplc0 = apl.C0

		local apr = Root.r
		local aprc0 = apr.C0

		local Sine = 0

		local VelocityChange = Vector3.new(0,0,0)
		local RotVelocityChange = Vector3.new(0,0,0)

		repeat
			RunService.Stepped:Wait()

			local CurrentRotation = Root.RotVelocity
			local CurrentPosition = Root.Position

			local NewChange = CurrentPosition - VelocityChange
			local NewRotChange = CurrentRotation - RotVelocityChange

			if NewChange.Y < -.2 then
				NewChange = Vector3.new(NewChange.X,-.2,NewChange.Z)
			elseif NewChange.Y > .2 then
				NewChange = Vector3.new(NewChange.X,.2,NewChange.Z)
			end

			if NewChange.X < -.1 then
				NewChange = Vector3.new(-.1,NewChange.Y,NewChange.Z)
			elseif NewChange.X > .1 then
				NewChange = Vector3.new(.1,NewChange.Y,NewChange.Z)
			end

			if NewChange.Z < -.1 then
				NewChange = Vector3.new(NewChange.X,NewChange.Y,-.1)
			elseif NewChange.Z > .1 then
				NewChange = Vector3.new(NewChange.X,NewChange.Y,.1)
			end


			Sine+=1

			apl.C0 = apl.C0:Lerp(aplc0 * CFrame.new(0,0 + .3 * math.sin(Sine/30), 0 + .4 * math.cos(Sine/120)) * CFrame.Angles(math.rad(0 - (30 * (NewChange.Y/.2)) + 5 * math.sin(Sine/30) ),math.rad(RotVelocityChange.Y*5),0),.1)
			apr.C0 = apr.C0:Lerp(aprc0 * CFrame.new(0,0 + .3 * math.cos(Sine/30), 0 + .4 * math.sin(Sine/120))  * CFrame.Angles(math.rad(0 - (30 * (NewChange.Y/.2)) + 5 * math.cos(Sine/30) ),math.rad(RotVelocityChange.Y*5), 0),.1)

			VelocityChange = CurrentPosition	
			RotVelocityChange = CurrentRotation
		until not Root.Parent
	end)	
end

local function TheTailWiggler(Object,Head)
	task.spawn(function()
		local Bones = {}

		for i = 1,6 do 
			local Bone = Object:FindFirstChild("Bone.00"..i,true)
			if Bone then
				Bones[i] = {Bone.Transform,Bone}
			end
		end

		local Sine = 0 

		local OgHeadR = Head.RotVelocity
		local OgHeadY = Head.Position.Y

		local PreviousL = OgHeadR

		repeat
			RunService.Stepped:Wait()
			Sine+=1

			if not Head.Parent.Parent then
				--	warn("gone.")
				Object:Destroy()
				return
			end

			local CurrY = Head.Position.Y
			local CurrR = Head.RotVelocity

			local RDiff = CurrR - OgHeadR
			local YDiff = OgHeadY - CurrY

			PreviousL = PreviousL:Lerp(RDiff,.2)

			if YDiff > 1 then
				YDiff = 1
			elseif YDiff < -1 then
				YDiff = -1
			end

			for i,Bone in pairs(Bones) do 
				local OffSine = Sine + (35/i)

				Bone[2].Transform = Bone[2].Transform:Lerp(Bone[1] * CFrame.Angles(math.rad(10/i),0,math.rad(0 - 15 * math.cos(OffSine/10))) * CFrame.Angles(-math.rad((25 * YDiff)),0,math.rad(PreviousL.Y*25)),.1)

			end

			OgHeadR = CurrR
			OgHeadY = CurrY

		until not Object.Parent
	end)
end

local function ToggleBodypartVisiblity(Char,Type,Visible)

	local Transparency = 1

	if Visible == true then
		Transparency = 0
	end

	--warn(Char,Type,Visible)

	if Type == "All" then
		for i,Part in pairs(Char:GetChildren()) do 
			if Part:IsA("Part") and (Part.Name == "Torso" or Part.Name == "Head" or Part.Name == "Right Leg" or Part.Name == "Left Leg" or Part.Name == "Right Arm" or Part.Name == "Left Arm") then
				if Part.Name == "Head" then
					Part.Transparency = Transparency
					for _,Mount in pairs(Part:GetDescendants()) do 
						if Mount.Name == "FaceMount" then
							Mount.Transparency = 1
						elseif Mount:IsA("BasePart") then
							Mount.Transparency = Transparency
						elseif Mount:IsA("Decal") and Mount.Name == "ComeOnStepItUp" then
							Mount.Transparency = Transparency
						end
					end
				else 
					Part.Transparency = Transparency
				end
			elseif Part:IsA("Accessory") and Part:FindFirstChild("Handle") then
				Part.Handle.Transparency = Transparency
			end
		end
	else 
		if typeof(Type) == "string" then
			for _,v in pairs(Char:GetChildren()) do 
				if string.find(v.Name,Type) then
					if v:IsA("BasePart") then
						v.Transparency = Transparency
					elseif v:IsA("Model") then
						for _,Inst in pairs(v:GetDescendants()) do 
							if Inst:IsA("BasePart") then
								Inst.Transparency = Transparency
							end
						end
					end
				end
			end
			--	Type = Char:FindFirstChild(Type,true)
		else 
			Type.Transparency = Transparency
		end
	end
end

local function weldAttachments(attach1, attach2)
	local weld = Instance.new("Weld")
	weld.Part0 = attach1.Parent
	weld.Part1 = attach2.Parent
	weld.C0 = attach1.CFrame
	weld.C1 = attach2.CFrame
	weld.Parent = attach1.Parent
	return weld
end

local function buildWeld(weldName, parent, part0, part1, c0, c1)
	local weld = Instance.new("Weld")
	weld.Name = weldName
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0
	weld.C1 = c1
	weld.Parent = parent
	return weld
end

local function findFirstMatchingAttachment(model, name)
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("Attachment") and child.Name == name then
			return child
		elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then -- Don't look in hats or tools in the character
			local foundAttachment = findFirstMatchingAttachment(child, name)
			if foundAttachment then
				return foundAttachment
			end
		end
	end
end

local function addAccoutrement(character, accoutrement)  
	--accoutrement.Parent = character
	local handle = accoutrement:FindFirstChild("Handle")
	if handle then
		handle.CanCollide = false
		handle.Massless = true
		handle.CanTouch = false 
		handle.CanQuery = false
		local accoutrementAttachment = handle:FindFirstChildOfClass("Attachment")
		if accoutrementAttachment then
			local characterAttachment = findFirstMatchingAttachment(character, accoutrementAttachment.Name)
			if characterAttachment then
				weldAttachments(characterAttachment, accoutrementAttachment)
			end
		else
			local head = character:FindFirstChild("Head")
			if head then
				local attachmentCFrame = CFrame.new(0, 0.5, 0)
				local hatCFrame = accoutrement.AttachmentPoint
				buildWeld("HeadWeld", head, head, handle, attachmentCFrame, hatCFrame)
			end
		end
	end
end

local function GetHair(Descriptor:HumanoidDescription)
	local Accessories = {}

	if Descriptor.HairAccessory then
		local HairAccessories = string.split(Descriptor.HairAccessory,",")
		for i,v in pairs(HairAccessories) do
			local NewHair

			if tonumber(v) then
				if script:FindFirstChild(v) then
					NewHair = script[v]:Clone()
				else 
					if RunService:IsStudio() then
						NewHair = ReplicatedStorage.LoadAsset:InvokeServer(tonumber(v)):FindFirstChildOfClass("Accessory",true)
					else 
						NewHair = game:GetObjects("rbxassetid://"..v)[1]
					end

					local SpecialMesh = NewHair:WaitForChild("Handle"):FindFirstChildOfClass("SpecialMesh")

					if SpecialMesh then
						SpecialMesh.TextureId = "rbxassetid://7740973748"
					else 
						NewHair.Handle.Material = Enum.Material.Sand
					end
					--	SpecialMesh.VertexColor

					NewHair.Name = v
					NewHair:Clone().Parent = script
				end		
				Accessories[i] = NewHair				
			end

		end	
	end

	return Accessories
end

local function GetFacesForRace(RaceName,Folder)
	local FilteredOut = {}
	local Default = nil
	local Shortened = string.sub(RaceName,1,5)

	local DeepWokenNamesHorrifyUs = {
		["Auroran"] = {
			Default = DeepFaces.Auchura,
			Decals = {DeepFaces.Auchura}
		},
		["Celestial"] = {
			Default = DeepFaces.Nilsa,
			Decals = {DeepFaces.Nilsa,DeepFaces.DebtCollector}
		},

	}

	if DeepWokenNamesHorrifyUs[RaceName] then
		return DeepWokenNamesHorrifyUs[RaceName]
	end

	--	warn(Shortened)
	for i,v in pairs((Folder or DeepFaces):GetChildren()) do 
		if string.find(v.Name,Shortened) then
			FilteredOut[#FilteredOut+1] = v
			if v:FindFirstChild(RaceName.."Default") then
				Default = v
			end
		end
	end

	if #FilteredOut == 0 then
		if Folder then
			local Result = {
				Default = Folder:FindFirstChildOfClass("Decal"),
				Decals = Folder:GetChildren()
			}

			local ExtraCheck = ExtraFaces:FindFirstChild(RaceName)

			if ExtraCheck then
				for inc,Face in pairs(ExtraCheck:GetChildren()) do 
					if Face:IsA("Decal") then
						Face.Name = RaceName.."Extra"..inc
						Result.Decals[#Result.Decals+1] = Face
					end
				end
			end

			return Result
		else 
			return {
				Default = DeepFaces.Confident,
				Decals = {DeepFaces.Carefree,DeepFaces.Concerned,DeepFaces.Confident,DeepFaces.Furious,DeepFaces.Unimpressed}
			}
		end
	else 
		local Result = {
			Default = Default,
			Decals = FilteredOut
		}

		local ExtraCheck = ExtraFaces:FindFirstChild(RaceName)

		if ExtraCheck then
			for inc,Face in pairs(ExtraCheck:GetChildren()) do 
				if Face:IsA("Decal") then
					Face.Name = RaceName.."Extra"..inc
					Result.Decals[#Result.Decals+1] = Face
				end
			end
		end

		return Result
	end
end

local function ApplyFace(Decal,Part,EyeColor,ScleraColor)
	--	warn(Decal:GetFullName())
	local Decal = Decal:Clone()

	for i,v in pairs(Decal:GetChildren()) do 
		if string.find(v.Name,"Shape") then
			local NewSclera = DeepSclera[v.Name]:Clone()
			NewSclera.Name = "ComeOnStepItUp"
			NewSclera.Color3 = ScleraColor
			NewSclera.Parent = Part
		elseif v:IsA("Decal") then
			v.Name = "ComeOnStepItUp" 
			v.Parent = Part
		elseif v:IsA("Model") then
			for _,bp in pairs(v:GetChildren()) do 
				buildWeld("a",Decal,Part,bp,bp:FindFirstChildOfClass("Attachment").CFrame:Inverse(),CFrame.new(0,0,0))
				bp.Color = EyeColor
				bp.Parent = Decal
			end
			v:Destroy()
		end
	end

	Decal.Name = "ComeOnStepItUp"
	Decal.Color3 = EyeColor
	Decal.ZIndex = 10
	Decal.Parent = Part
end

local function HideEquipmentType(Type,Character)
	for i,Equipment in pairs(Character:GetChildren()) do
		if Equipment.Name == Type then
			if Equipment:IsA("Model") then
				for i,x in pairs(Equipment:GetDescendants()) do 
					if x:IsA("BasePart") then
						x.Transparency = 1
					end
				end
			else
				Equipment.Transparency = 1
			end
		end
	end
end


local function RegisterCloak(Character,AnimationController)
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if Humanoid and AnimationController then
		--warn("???")
		--	Instance.new("Animator",AnimationController)

		local Idle,Walk,Connected
		-- lol

		if AnimationController.Parent:FindFirstChild("Idle") then
			if RunService:IsStudio() and string.find(AnimationController.Parent.Idle.AnimationId,"rbxassetid") then
				AnimationController.Parent.Idle.AnimationId = game.KeyframeSequenceProvider:RegisterKeyframeSequence(AnimationController.Parent.Idle:FindFirstChildOfClass("KeyframeSequence"))
			end

			Idle = AnimationController:LoadAnimation(AnimationController.Parent.Idle)
		end

		if AnimationController.Parent:FindFirstChild("Run") then
			if RunService:IsStudio() and string.find(AnimationController.Parent.Run.AnimationId,"rbxassetid") then
				AnimationController.Parent.Run.AnimationId = game.KeyframeSequenceProvider:RegisterKeyframeSequence(AnimationController.Parent.Run:FindFirstChildOfClass("KeyframeSequence"))
			end

			Walk = AnimationController:LoadAnimation(AnimationController.Parent.Run)
		end

		if Idle or Walk then
			Connected = Humanoid.Running:Connect(function(ws)
				if AnimationController.Parent then
					if ws > 0 then

						if not Walk.IsPlaying then
							Walk:Play(0.100000001,1,ws/16)
						else 
							Walk:AdjustSpeed(ws/16)
						end

						if Idle.IsPlaying then
							Idle:Stop()
						end

					else 
						if not Idle.IsPlaying then
							Idle:Play()
						end

						if Walk.IsPlaying then
							Walk:Stop()
						end
					end					
				else 
					Connected:Disconnect()
				end

			end)

			if Humanoid.MoveDirection.Magnitude ~= 0 then
				Walk:Play(0.100000001,1,Humanoid.WalkSpeed/16)
			else 
				Idle:Play()
			end
		end
	end
end

local function ApplyDeepwokenAccourtment(Accourtment,Head,CurrentRace,NoBad)
	if 	Accourtment:IsA("Model") then		
		local NewAccourtment = Accourtment:Clone()
		NewAccourtment.Name = math.random(1,100000000)

		NewAccourtment.Parent = (Head.Parent:FindFirstChild("CustomOrnaments") or Head)

		if NewAccourtment:FindFirstChild("HideType") then
			HideEquipmentType(NewAccourtment.HideType.Value,Head.Parent)
		end

		local Shirt,Pants = NewAccourtment:FindFirstChildOfClass("Shirt"),NewAccourtment:FindFirstChildOfClass("Pants")

		if Shirt then
			local Cloth = Head.Parent:FindFirstChildOfClass("Shirt")
			if Cloth then
				Cloth.ShirtTemplate = Shirt.ShirtTemplate
			end
			Shirt:Destroy()		
		end

		if Pants then
			local Cloth = Head.Parent:FindFirstChildOfClass("Pants")
			if Cloth then
				Cloth.PantsTemplate = Pants.PantsTemplate
			end
			Pants:Destroy()		
		end

		for i,x in pairs(NewAccourtment:GetChildren()) do 
			if x:IsA("BasePart") then
				ApplyDeepwokenAccourtment(x,Head,CurrentRace,true)
			end
		end

		if NewAccourtment:FindFirstChild("HideBody") then
			ToggleBodypartVisiblity(Head.Parent,NewAccourtment.HideBody.Value)
		end

		if NewAccourtment:FindFirstChild("TailWeld") then
			if RunService:IsStudio() then
				if Head.Parent.Parent == workspace then
					TheTailWiggler(NewAccourtment,Head)
				end
			else 
				if Head.Parent.Parent:IsA("Folder") then
					TheTailWiggler(NewAccourtment,Head)
				end
			end
		end

		if NewAccourtment:FindFirstChildOfClass("AnimationController") then
			if RunService:IsStudio() then
				if Head.Parent.Parent == workspace then
					RegisterCloak(Head.Parent,NewAccourtment.AnimationController)
				end
			else 
				if Head.Parent.Parent:IsA("Folder") then
					RegisterCloak(Head.Parent,NewAccourtment.AnimationController)
				end
			end
		end

		if NewAccourtment:FindFirstChild("MainWeldo") then
			TheSwordTilter(NewAccourtment.MainWeldo)
		end

		return NewAccourtment
	else 
		local NewAccourtment

		if NoBad then
			NewAccourtment = Accourtment
		else 
			NewAccourtment = Accourtment:Clone()
		end

		if NewAccourtment:FindFirstChild("HideType") then
			HideEquipmentType(NewAccourtment.HideType.Value,Head.Parent)
		end

		if NewAccourtment:FindFirstChild("HideBody") then
			ToggleBodypartVisiblity(Head.Parent,NewAccourtment.HideBody.Value)
		end

		if NewAccourtment:IsA("BasePart") then
			NewAccourtment.CanCollide = false
			NewAccourtment.Massless = true
			NewAccourtment.CanQuery = false
		end

		if NewAccourtment.Name == "HelioWingsP" then
			NewAccourtment.HelioWings.Color = CurrentRace.CurrentVarient.CustomColor1.Value

			if (Head.Parent.Parent == workspace or Head.Parent.Parent:IsA("Folder")) then
				NewAccourtment.HelioWings.Transparency = 1

				task.spawn(function()
					local WingController,WingConnection = ConnectWings(NewAccourtment.RootPart)
					local Character = Head.Parent
					local Humnanoid = Character:FindFirstChildOfClass("Humanoid")
					local SecondConnection = nil
					local ThirdConnection = nil

					ThirdConnection = NewAccourtment:GetPropertyChangedSignal("Parent"):Connect(function()
						if not NewAccourtment.Parent or not NewAccourtment.Parent.Parent then
							SecondConnection:Disconnect()
							coroutine.close(WingConnection)
							ThirdConnection:Disconnect()
						end
					end)

					SecondConnection = Humnanoid.AnimationPlayed:Connect(function(AnimationTrack)
						if not AnimationTrack then
							return
						end

						--if AnimationTrack.Animation.AnimationId == "rbxassetid://12575722628" then
						if AnimationTrack.Animation.AnimationId == "rbxassetid://5167808907" then
							WingController("Fly")

							local LeftHipWeld = Instance.new("Weld",Character["Torso"])
							LeftHipWeld.Part1 = Character["Left Leg"]
							LeftHipWeld.Part0 = Character["Torso"]
							LeftHipWeld.C0 = CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
							LeftHipWeld.C1 = CFrame.new(-0.475, 0.232, 0.714) * CFrame.Angles(math.rad(0.679), math.rad(-104.985), math.rad(-5.089))	
							local LeftShoulderWeld = Instance.new("Weld",Character["Torso"])
							LeftShoulderWeld.Part1 = Character["Left Arm"]
							LeftShoulderWeld.Part0 = Character["Torso"]
							LeftShoulderWeld.C0 = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
							LeftShoulderWeld.C1 = CFrame.new(0.48, 0.828, -0.148) * CFrame.Angles(math.rad(6.284), math.rad(-96.337), math.rad(-0.695))
							local NeckWeld = Instance.new("Weld",Character["Torso"])
							NeckWeld.Part1 = Character["Head"]
							NeckWeld.Part0 = Character["Torso"]
							NeckWeld.C0 = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)
							NeckWeld.C1 = CFrame.new(0, -0.717000008, 0, -1, 0, 0, 0, 0.950549364, 0.310573518, 0, 0.310573518, -0.950549364)
							local RightHipWeld = Instance.new("Weld",Character["Torso"])
							RightHipWeld.Part1 = Character["Right Leg"]
							RightHipWeld.Part0 = Character["Torso"]
							RightHipWeld.C0 = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0)
							RightHipWeld.C1 = CFrame.new(0.43, 0.313, 0.493) * CFrame.Angles(math.rad(-4.58), math.rad(98.899), math.rad(34.643))
							local RightShoulderWeld = Instance.new("Weld",Character["Torso"])
							RightShoulderWeld.Part1 = Character["Right Arm"]
							RightShoulderWeld.Part0 = Character["Torso"]
							RightShoulderWeld.C0 = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0)
							RightShoulderWeld.C1 = CFrame.new(-0.48, 0.828, -0.148) * CFrame.Angles(math.rad(6.284), math.rad(96.337), math.rad(0.695))
							local RootJointWeld = Instance.new("Weld",Character["HumanoidRootPart"])
							RootJointWeld.Part1 = Character["Torso"]
							RootJointWeld.Part0 = Character["HumanoidRootPart"]
							RootJointWeld.C0 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)
							RootJointWeld.C1 = CFrame.new(0, 0, 0, -1, 0, 0, 0, -0.991158187, 0.132685825, 0, 0.132685825, 0.991158187)

							for _,Gliders in pairs(Head.Parent:GetChildren()) do 
								if Gliders:IsA("Model") and string.find(string.lower(Gliders.Name),"glide") then
									wait(.2)
									for _,BasePart in pairs(Gliders:GetDescendants()) do 
										if BasePart:IsA("BasePart") then
											warn("BasePart")
											BasePart.Transparency = 1
										end
									end
								end
							end						

							local HoverSine = 0
							local RotDiff = Character["HumanoidRootPart"].RotVelocity

							repeat
								task.wait()
								local currdiff = Character["HumanoidRootPart"].RotVelocity
								local CurrentRV = RotDiff - currdiff

								HoverSine+=1

								NeckWeld.C1 = NeckWeld.C1:Lerp(CFrame.new(0, -0.717, 0) * CFrame.Angles(math.rad(18.094  -  2 * math.cos(HoverSine/20) ), math.rad(180), 0),.1)
								RootJointWeld.C1 = RootJointWeld.C1:Lerp(CFrame.new(0,0,0 + .1 * math.cos(HoverSine/40)) * CFrame.Angles(math.rad(-7.625 +  2 * math.sin(HoverSine/	20)),math.rad(0 - (5 * CurrentRV.Y*15)), math.rad(180 - (2 * CurrentRV.Y*10) )),.1)

								RotDiff = currdiff
							until not AnimationTrack.IsPlaying
							--until nil

							NeckWeld:Destroy()
							RootJointWeld:Destroy()
							LeftShoulderWeld:Destroy()
							RightShoulderWeld:Destroy()
							LeftHipWeld:Destroy()
							RightHipWeld:Destroy()

							WingController("Idle")
						end

					end)

					WingController("Appear")
				end)
			end
		end



		for i,x in pairs(NewAccourtment:GetDescendants()) do 
			if x:IsA("BasePart") then
				x.CanCollide = false
				x.Massless = true
				x.CanQuery = false
			end

			if x:FindFirstChild("HairColor") then
				if x:IsA("SpecialMesh") then
					x.VertexColor = Vector3.new(CurrentRace.CurrentVarient.HairColor.Value.R,CurrentRace.CurrentVarient.HairColor.Value.G,CurrentRace.CurrentVarient.HairColor.Value.B)
				else 
					x.Parent.Color = CurrentRace.CurrentVarient.HairColor.Value
				end
			elseif x:FindFirstChild("LinerColor") then
				x.VertexColor = Vector3.new(CurrentRace.CurrentVarient.LinerColor.Value.R,CurrentRace.CurrentVarient.LinerColor.Value.G,CurrentRace.CurrentVarient.LinerColor.Value.B)
			elseif x:FindFirstChild("EyeColor") then
				local EyeColor = CurrentRace.CurrentVarient.EyeColor.Value

				if CurrentRace.CustomColors[CurrentRace.CurrentVarient] and CurrentRace.CustomColors[CurrentRace.CurrentVarient].EyeColor then
					EyeColor = CurrentRace.CustomColors[CurrentRace.CurrentVarient].EyeColor
				end

				x.Color = EyeColor
			elseif x:FindFirstChild("SkinColor") then
				if x:IsA("Decal") then	
					x.Color3 = CurrentRace.CurrentVarient.SkinColor.Value
				else 
					x.Color = CurrentRace.CurrentVarient.SkinColor.Value
				end
			elseif x:FindFirstChild("DesignColor") then
				x.Color3 = CurrentRace.CurrentVarient.DesignColor.Value
			elseif x:FindFirstChild("MaskColor") then
				x.Color = CurrentRace.CurrentVarient.MaskColor.Value
			elseif x:FindFirstChild("SkullColor") then
				x.Color = CurrentRace.CurrentVarient.SkullColor.Value
			elseif x:FindFirstChild("HornColor") then
				x.Color = CurrentRace.CurrentVarient.HornColor.Value
			elseif x:FindFirstChild("CircletColor") then
				x.Color = CurrentRace.CurrentVarient.CircletColor.Value
			elseif x:FindFirstChild("MarkingColor") then

				local MarkColor = (CurrentRace.CurrentVarient:FindFirstChild("TattooColor") or CurrentRace.CurrentVarient.HairColor).Value

				if CurrentRace.CustomColors[CurrentRace.CurrentVarient] and CurrentRace.CustomColors[CurrentRace.CurrentVarient].MarkColor then
					MarkColor = CurrentRace.CustomColors[CurrentRace.CurrentVarient].MarkColor
				end

				x.Color = MarkColor
			elseif x:FindFirstChild("CustomColor1") then
				--warn("what")
				if x:IsA("Decal") then	
					x.Color3 = CurrentRace.CurrentVarient.CustomColor1.Value
				else
					x.Color = CurrentRace.CurrentVarient.CustomColor1.Value
				end
			elseif x:FindFirstChild("CustomColor2") then
				if x:IsA("Decal") then	
					x.Color3 = CurrentRace.CurrentVarient.CustomColor2.Value
				else
					x.Color = CurrentRace.CurrentVarient.CustomColor2.Value
				end
			elseif x:FindFirstChild("CustomColor3") then
				if x:IsA("Decal") then	
					x.Color3 = CurrentRace.CurrentVarient.CustomColor3.Value
				else
					x.Color = CurrentRace.CurrentVarient.CustomColor3.Value
				end
			end
		end

		if NewAccourtment:FindFirstChild("HairColor") then
			NewAccourtment.Color = CurrentRace.CurrentVarient.HairColor.Value
		elseif NewAccourtment:FindFirstChild("EyeColor") then
			local EyeColor = CurrentRace.CurrentVarient.EyeColor.Value

			if CurrentRace.CustomColors[CurrentRace.CurrentVarient] and CurrentRace.CustomColors[CurrentRace.CurrentVarient].EyeColor then
				EyeColor = CurrentRace.CustomColors[CurrentRace.CurrentVarient].EyeColor
			end

			NewAccourtment.Color = EyeColor
		elseif NewAccourtment:FindFirstChild("DesignColor") then
			NewAccourtment.Color3 = CurrentRace.CurrentVarient.DesignColor.Value
		elseif NewAccourtment:FindFirstChild("MaskColor") then
			NewAccourtment.Color = CurrentRace.CurrentVarient.MaskColor.Value
		elseif NewAccourtment:FindFirstChild("SkinColor") then
			NewAccourtment.Color = CurrentRace.CurrentVarient.SkinColor.Value
		elseif NewAccourtment:FindFirstChild("HornColor") then
			NewAccourtment.Color = CurrentRace.CurrentVarient.HornColor.Value
		elseif NewAccourtment:FindFirstChild("SkullColor") then
			NewAccourtment.Color = CurrentRace.CurrentVarient.SkullColor.Value
		elseif NewAccourtment:FindFirstChild("CircletColor") then
			NewAccourtment.Color = CurrentRace.CurrentVarient.CircletColor.Value
		elseif NewAccourtment:FindFirstChild("MarkingColor") then

			local MarkColor = (CurrentRace.CurrentVarient:FindFirstChild("TattooColor") or CurrentRace.CurrentVarient.HairColor).Value

			if CurrentRace.CustomColors[CurrentRace.CurrentVarient] and CurrentRace.CustomColors[CurrentRace.CurrentVarient].MarkColor then
				MarkColor = CurrentRace.CustomColors[CurrentRace.CurrentVarient].MarkColor
			end

			NewAccourtment.Color = MarkColor
		elseif NewAccourtment:FindFirstChild("CustomColor1") then
			--warn("what")
			NewAccourtment.Color = CurrentRace.CurrentVarient.CustomColor1.Value
		elseif NewAccourtment:FindFirstChild("CustomColor2") then
			NewAccourtment.Color = CurrentRace.CurrentVarient.CustomColor2.Value
		elseif NewAccourtment:FindFirstChild("CustomColor3") then
			NewAccourtment.Color = CurrentRace.CurrentVarient.CustomColor3.Value
		end

		NewAccourtment.Anchored = false


		if not NoBad then
			NewAccourtment.Parent = (Head.Parent:FindFirstChild("CustomOrnaments") or Head)
		end

		local AccorutmentWeld = Instance.new("Weld",NewAccourtment)

		if Accourtment.Name == "Necklace" then
			AccorutmentWeld.Part0 = Head.Parent.Torso
		elseif Accourtment:GetAttribute("Part0") then
			AccorutmentWeld.Part0 = Head.Parent[Accourtment:GetAttribute("Part0")]
		else 
			AccorutmentWeld.Part0 =  Head
		end

		AccorutmentWeld.Part1 = NewAccourtment

		if NewAccourtment:FindFirstChildOfClass("Attachment") then
			AccorutmentWeld.C0 = NewAccourtment:FindFirstChildOfClass("Attachment").CFrame:Inverse()
		end

		return NewAccourtment	
	end

end

-- process tha vesp maskies.
local VesperianMasks = CustomAccourtments:FindFirstChild("VesperianMasks")
local CHAR_OFFSET = 63

local SpecificMaskColors = {
	['Blindseer'] = {
		MaskColor = Color3.fromRGB(39, 49, 93),
		DesignColor = Color3.fromRGB(163, 133, 44)
	},
}

if VesperianMasks then
	VesperianMasks:ClearAllChildren()
else 
	VesperianMasks = Instance.new("Folder",CustomAccourtments)
	VesperianMasks.Name = "VesperianMasks"
end

for _,Shape in pairs(DeepOrnaments.VespMasks:GetChildren()) do 
	for _,Design in pairs(DeepVespDesigns:GetChildren()) do 
		CHAR_OFFSET+=1
		
		local NewDesign = Design:Clone()
		local NewShape = Shape:Clone()
		NewShape.Name = "VesperianMask"..string.char(CHAR_OFFSET)
		NewDesign.Parent = NewShape
		
		if SpecificMaskColors[Design.Name] then
			NewShape.Color = SpecificMaskColors[Design.Name].MaskColor
			NewDesign.Color3 = SpecificMaskColors[Design.Name].DesignColor
		else 
			Instance.new("BoolValue",NewShape).Name = "MaskColor"
			Instance.new("BoolValue",NewDesign).Name = "DesignColor"
		end
		
		NewShape.Parent = VesperianMasks
	end
end

local function GetDeepwokenOrnaments(RaceName)

	for i,v in pairs(CustomAccourtments:GetChildren()) do 
		if string.find(v.Name,RaceName) then
			--	warn(v.Name)
			return v:GetChildren()
		end
	end

	for i,v in pairs(DeepOrnaments:GetChildren()) do 
		if string.find(v.Name,RaceName) then
			return v:GetChildren()
		end
	end

	return nil
end

local function GetVarientsForRace(RaceFolder)
	local Varients = {
		[(RaceFolder:FindFirstChild("DefaultVariant") or {Value = RaceFolder.Name}).Value] = RaceFolder
	}

	for i,v in pairs(RaceFolder:GetChildren()) do 
		if v:FindFirstChild("SkinColor") then
			Varients[v.Name] = v
		end
	end

	return Varients

end

local function GetMarkingsForRace(RaceName)
	if RaceName == "Adret" then
		RaceName = "Maudet"
	end

	local Output = {}

	for i,v in pairs(DeepFacialMarkings:GetChildren()) do 
		if string.find(v.Name,RaceName) then
			Output[#Output+1] = v
		end
	end

	if #Output < 1 then
		for i,v in pairs(DeepFacialMarkings:GetChildren()) do 
			if v:FindFirstChild("Default") and v:IsA("Decal") then
				Output[#Output+1] = v
			end
		end

		if #Output < 1 then
			return nil
		else 
			return Output
		end
	else 
		return Output
	end

end

local function RefreshOutfits()
	local OutfitData = FetchOutfitsForTarget(OurChoices["You."].Target_Id)

	for _,Label in pairs(ConfigFrames.UserConfig.ScrollingFrame.ChoiceTemplate:GetChildren()) do 
		if Label:IsA("ViewportFrame") then
			Label:Destroy()
		end
	end

	local NewButton = TemplateButtons.ThumbnailViewportConfig:Clone()
	NewButton.ImageLabel.Image = "rbxthumb://type=Avatar&id="..OutfitData.UserId.."&w=352&h=352"
	NewButton.LayoutOrder = 0

	if OurChoices["You."].Outfit_Id == "UserId" then
		NewButton.Selected.Visible = true
	end

	NewButton.Clickable.MouseButton1Click:Connect(function()
		OurChoices["You."].Outfit_Id = "UserId"

		for _,Label in pairs(ConfigFrames.UserConfig.ScrollingFrame.ChoiceTemplate:GetChildren()) do 
			if Label:IsA("ViewportFrame") then
				if Label == NewButton then
					Label.Selected.Visible = true
				else 
					Label.Selected.Visible = false
				end
			end
		end
	end)

	NewButton.Parent = ConfigFrames.UserConfig.ScrollingFrame.ChoiceTemplate

	for i,v in pairs(OutfitData.Outfits) do
		local NewButton = TemplateButtons.ThumbnailViewportConfig:Clone()
		NewButton.ImageLabel.Image = "rbxthumb://type=Outfit&id="..v.."&w=420&h=420"
		NewButton.LayoutOrder = i+1	

		if OurChoices["You."].Outfit_Id == v then
			NewButton.Selected.Visible = true
		end

		NewButton.Clickable.MouseButton1Click:Connect(function()
			OurChoices["You."].Outfit_Id = v

			for _,Label in pairs(ConfigFrames.UserConfig.ScrollingFrame.ChoiceTemplate:GetChildren()) do 
				if Label:IsA("ViewportFrame") then
					if Label == NewButton then
						Label.Selected.Visible = true
					else 
						Label.Selected.Visible = false
					end
				end
			end
		end)

		NewButton.Parent = ConfigFrames.UserConfig.ScrollingFrame.ChoiceTemplate
	end

	ConfigFrames.UserConfig.ScrollingFrame.ChoiceTemplate.Folder.Overlay.Size = UDim2.new(
		1,0,0,ConfigFrames.UserConfig.ScrollingFrame.ChoiceTemplate.UIGridLayout.AbsoluteContentSize.Y + 12
	)

	ConfigFrames.UserConfig.ScrollingFrame.CanvasSize = UDim2.fromOffset(ConfigFrames.UserConfig.ScrollingFrame.UIListLayout.AbsoluteContentSize.X,ConfigFrames.UserConfig.ScrollingFrame.UIListLayout.AbsoluteContentSize.Y)
end


local function LoadRace(Type,Data)
	if (Type == "InGame" and not RaceConfig[Data])then
		-- we deal with the dogshit that is deepwoken.

		local MainRaceButton = TemplateButtons:WaitForChild("CharacterViewport"):Clone()
		local ThumbnailDummy = 	MainRaceButton.WorldModel.ThumbnailDummy

		MainRaceButton.Clickable.MouseButton1Click:Connect(function()
			if CharacterPageLayout.ScrollWheelInputEnabled then
				CharacterPageLayout:JumpTo(MainRaceButton)
			end
		end)		

		local RaceData = DeepRaces[Data]
		local OurFaces = GetFacesForRace(Data)
		local OurOrnaments = GetDeepwokenOrnaments(Data)
		local Varients = GetVarientsForRace(RaceData)
		local FacialMarkings = GetMarkingsForRace(Data)

		--warn(Data)

		RaceConfig[Data] = {
			Faces = OurFaces,
			Ornaments = OurOrnaments,
			Varients = Varients,
			FacialMarkings = FacialMarkings,
			Description = ((RaceData:FindFirstChild("Desc") or {Value = "Missing Desc."})).Value,
			CurrentVarient = (RaceData:FindFirstChild("DefaultVariant") or {Value = RaceData.Name}).Value
		}

		if OurChoices[Data] then
			local PortedColors = {}	
			local PortedOrnaments = {}

			for i,v in pairs(OurChoices[Data].CustomColors) do

				local replacement = {}
				--warn(i,game.HttpService:JSONEncode(Varients))
				local NewKey = (Varients[i]	or RaceConfig[Data].CurrentVarient)				

				if v.EyeColor  then
					replacement.EyeColor = Color3.fromHex(v.EyeColor)
				end

				if v.MarkColor  then
					replacement.MarkColor = Color3.fromHex(v.MarkColor)
				end

				PortedColors[NewKey] = replacement
			end

			if OurOrnaments then
				for i,v in pairs(OurChoices[Data].Ornaments) do
					--	warn(OurOrnaments)#
					--	warn(Data)
					for _,Ornament in pairs(OurOrnaments) do 
						if Ornament.Name == i then
							PortedOrnaments[Ornament] = true
							break
						end
					end
					--print(i,v)
				end				
			end


			OurChoices[Data].CustomColors = PortedColors
			OurChoices[Data].Ornaments = PortedOrnaments

			if OurFaces then
				if OurChoices[Data].Face then
					for i,v in pairs(OurFaces.Decals) do
						if v.Name == OurChoices[Data].Face then
							OurChoices[Data].Face = v 
							break
						end
					end
				end
			end

			if FacialMarkings then
				if OurChoices[Data].FacialMarkings then
					for i,v in pairs(FacialMarkings) do
						if v.Name == OurChoices[Data].FacialMarkings then
							OurChoices[Data].FacialMarkings = v 
							break
						end
					end
				end
			end


			OurChoices[Data].CurrentVarient = (Varients[OurChoices[Data].CurrentVarient] or RaceData)				

		else 
			OurChoices[Data] = {
				Face = OurFaces.Default,
				Ornaments = {},
				CurrentVarient = RaceData,
				FacialMarkings = nil,
				CustomColors = {},
			}	
		end


		ApplyFace(OurFaces.Default,ThumbnailDummy.Faces,RaceData.EyeColor.Value,((RaceData:FindFirstChild("ScleraColor") and RaceData.ScleraColor.Value) or Color3.new(1,1,1) ))


		local BodyColors = Instance.new("BodyColors")
		local HairMeshes = GetHair(OurDescriptor)

		--
		BodyColors.TorsoColor3 = RaceData.SkinColor.Value
		BodyColors.HeadColor3 = RaceData.SkinColor.Value
		BodyColors.RightArmColor3 = RaceData.SkinColor.Value
		BodyColors.LeftArmColor3 = RaceData.SkinColor.Value
		BodyColors.LeftLegColor3 = RaceData.SkinColor.Value
		BodyColors.RightLegColor3 = RaceData.SkinColor.Value
		--
		MainRaceButton.Parent = CharacterMain
		MainRaceButton.Name = Data

		for i,v in pairs(HairMeshes) do 
			v:WaitForChild("Handle").Transparency = 0
			local HasMESH = v.Handle:FindFirstChildOfClass("SpecialMesh")
			if HasMESH then
				HasMESH.VertexColor = Vector3.new(
					RaceData.HairColor.Value.R,RaceData.HairColor.Value.G,RaceData.HairColor.Value.B
				)
			else 
				v.Handle.Color = RaceData.HairColor.Value
			end			
			addAccoutrement(ThumbnailDummy,v)
			v.Parent = ThumbnailDummy
		end

		local MainViewPortCamera = Instance.new("Camera",MainRaceButton)
		MainViewPortCamera.CFrame = ThumbnailDummy.Head.CFrame * CFrame.new(-5.05,0,-14) * CFrame.Angles(0,math.rad(200),0)
		MainViewPortCamera.FieldOfView = 10	

		BodyColors.Parent = ThumbnailDummy
		MainRaceButton.CurrentCamera = MainViewPortCamera

	elseif Type == "Custom" then
		-- we handle a file
		-- idk add syanpse loading at some point.
		local LoadedFile = Data

		local MainRaceButton = TemplateButtons:WaitForChild("CharacterViewport"):Clone()

		MainRaceButton.Clickable.MouseButton1Click:Connect(function()
			if CharacterPageLayout.ScrollWheelInputEnabled then
				CharacterPageLayout:JumpTo(MainRaceButton)
			end
		end)

		local ThumbnailDummy = 	MainRaceButton.WorldModel.ThumbnailDummy

		local RaceData = LoadedFile:WaitForChild("RaceData")
		local OurFaces = LoadedFile:FindFirstChild("Faces")
		local OurOrnaments = LoadedFile:FindFirstChild("Ornaments")
		local Varients = GetVarientsForRace(RaceData)
		local FacialMarkings = LoadedFile:FindFirstChild("Markings")

		if OurFaces and #OurFaces:GetChildren() > 0 then
			OurFaces = {
				Default = OurFaces:FindFirstChildOfClass("Decal"),
				Decals = OurFaces:GetChildren()
			}
		else 
			OurFaces = GetFacesForRace(LoadedFile.Name)
		end

		if OurOrnaments then
			OurOrnaments = OurOrnaments:GetChildren()
		end

		if FacialMarkings then
			FacialMarkings = FacialMarkings:GetChildren()

			if #FacialMarkings < 1 then
				FacialMarkings = GetMarkingsForRace(LoadedFile.Name)
			end
		end

		RaceConfig[LoadedFile.Name] = {
			Faces = OurFaces,
			Ornaments = OurOrnaments,
			Varients = Varients,
			FacialMarkings = FacialMarkings,
			Description = ((RaceData:FindFirstChild("Desc") or {Value = "Missing Desc."})).Value,
			CurrentVarient = (RaceData:FindFirstChild("DefaultVariant") or {Value = RaceData.Name}).Value
		}

		if OurChoices[LoadedFile.Name] then
			--	warn("a")
			local PortedColors = {}	
			local PortedOrnaments = {}

			for i,v in pairs(OurChoices[LoadedFile.Name].CustomColors) do

				local replacement = {}
				--warn(i,game.HttpService:JSONEncode(Varients))
				local NewKey = (Varients[i]	or RaceConfig[LoadedFile.Name].CurrentVarient)				

				if v.EyeColor  then
					replacement.EyeColor = Color3.fromHex(v.EyeColor)
				end

				if v.MarkColor  then
					replacement.MarkColor = Color3.fromHex(v.MarkColor)
				end

				PortedColors[NewKey] = replacement
			end

			for i,v in pairs(OurChoices[LoadedFile.Name].Ornaments) do
				for _,Ornament in pairs(OurOrnaments) do 
					if Ornament.Name == i then
						--	warn(Ornament)
						PortedOrnaments[Ornament] = true
						break
					end
				end

				--	print(i,v)
			end

			OurChoices[LoadedFile.Name].CustomColors = PortedColors
			OurChoices[LoadedFile.Name].Ornaments = PortedOrnaments

			if OurChoices[LoadedFile.Name].Face then
				for i,v in pairs(OurFaces.Decals) do
					if v.Name == OurChoices[LoadedFile.Name].Face then
						OurChoices[LoadedFile.Name].Face = v 
						break
					end
				end
			end

			if OurChoices[LoadedFile.Name].FacialMarkings then
				for i,v in pairs(FacialMarkings) do
					if v.Name == OurChoices[LoadedFile.Name].FacialMarkings then
						OurChoices[LoadedFile.Name].FacialMarkings = v 
						break
					end
				end
			end

			OurChoices[LoadedFile.Name].CurrentVarient = (Varients[OurChoices[LoadedFile.Name].CurrentVarient] or RaceData)				

		else 
			OurChoices[LoadedFile.Name] = {
				Face = OurFaces.Default,
				Ornaments = {},
				CurrentVarient = RaceData,
				FacialMarkings = nil,
				CustomColors = {}

			}
		end




		ApplyFace(OurFaces.Default,ThumbnailDummy.Faces,RaceData.EyeColor.Value,((RaceData:FindFirstChild("ScleraColor") and RaceData.ScleraColor.Value) or Color3.new(1,1,1) ))


		local BodyColors = Instance.new("BodyColors")
		local HairMeshes = GetHair(OurDescriptor)

		--
		BodyColors.TorsoColor3 = RaceData.SkinColor.Value
		BodyColors.HeadColor3 = RaceData.SkinColor.Value
		BodyColors.RightArmColor3 = RaceData.SkinColor.Value
		BodyColors.LeftArmColor3 = RaceData.SkinColor.Value
		BodyColors.LeftLegColor3 = RaceData.SkinColor.Value
		BodyColors.RightLegColor3 = RaceData.SkinColor.Value
		--
		MainRaceButton.Parent = CharacterMain
		MainRaceButton.Name = LoadedFile.Name

		for i,v in pairs(HairMeshes) do 
			v:WaitForChild("Handle").Transparency = 0
			local HasMESH = v.Handle:FindFirstChildOfClass("SpecialMesh")
			
			if HasMESH then
				HasMESH.VertexColor = Vector3.new(
					RaceData.HairColor.Value.R,RaceData.HairColor.Value.G,RaceData.HairColor.Value.B
				)
			else 
				v.Handle.Color = RaceData.HairColor.Value
			end			
			addAccoutrement(ThumbnailDummy,v)
			v.Parent = ThumbnailDummy
		end

		local MainViewPortCamera = Instance.new("Camera",MainRaceButton)
		MainViewPortCamera.CFrame = ThumbnailDummy.Head.CFrame * CFrame.new(-5.05,0,-14) * CFrame.Angles(0,math.rad(200),0)
		MainViewPortCamera.FieldOfView = 10	

		BodyColors.Parent = ThumbnailDummy
		MainRaceButton.CurrentCamera = MainViewPortCamera
	elseif Type == "You." then
		local LoadedFile = MainGui["You."]

		local MainRaceButton = TemplateButtons:WaitForChild("ThumbnailViewport"):Clone()

		MainRaceButton.Clickable.MouseButton1Click:Connect(function()
			if CharacterPageLayout.ScrollWheelInputEnabled then
				CharacterPageLayout:JumpTo(MainRaceButton)
			end
		end)

		local RaceData = LoadedFile:WaitForChild("RaceData")
		local Varients = GetVarientsForRace(RaceData)

		if OurChoices[LoadedFile.Name] then
			RaceConfig[LoadedFile.Name] = {
				Description = GetUserDescription(OurChoices[LoadedFile.Name].Target_Id),
				CurrentVarient = RaceData,
				Ornaments = nil,
				FacialMarkings = nil,
				CustomColors = {}
			}

			MainRaceButton.ImageLabel.Image = "rbxthumb://type=AvatarHeadShot&id="..OurChoices[LoadedFile.Name].Target_Id.."&w=150&h=150"
		else 
			RaceConfig[LoadedFile.Name] = {
				Description = GetUserDescription(LocalPlayer.UserId),
				CurrentVarient = RaceData,
				Ornaments = nil,
				FacialMarkings = nil,
				CustomColors = {}
			}

			MainRaceButton.ImageLabel.Image = "rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=150&h=150"

			OurChoices[LoadedFile.Name] = {
				Face = nil,
				Ornaments = {},
				CurrentVarient = RaceData,
				FacialMarkings = nil,
				CustomColors = {},
				Target_Id = LocalPlayer.UserId,
				Outfit_Id = "UserId"
			}
		end

		RefreshOutfits()		
		--
		MainRaceButton.Parent = CharacterMain
		MainRaceButton.Name = LoadedFile.Name

	end														
end


local OathColors = {
	["Visionshaper"] = Color3.fromRGB(221, 53, 255),
	["Jetstriker"] = Color3.fromRGB(123, 215, 255)
}

local function FetchOathEyeColor(Char)
	local TargetPlr = Players:GetPlayerFromCharacter(Char)
	if TargetPlr and TargetPlr:FindFirstChild("Backpack") then
		for i,Card in pairs(TargetPlr.Backpack:GetChildren()) do
			local OathPrefix = string.find(Card.Name,"Talent:Oath:")
			if Card:IsA("Folder") and OathPrefix then
				local OathName = string.gsub(string.sub(Card.Name,OathPrefix)," ","")

				if OathColors[OathName] then
					return OathColors[OathName],OathName
				else 
					return false,nil
				end
			end
		end
	end

	return false,nil
end

local OutfitDescriptionDump = Instance.new("Folder",nil)
local PlayerDescriptionDump = Instance.new("Folder",nil)
local Accessories

local function GetClothes(id)
	local NewClothing = nil
	local Success,ClothingID = pcall(function()
		local Request =  nil

		if RunService:IsStudio() then
			Request = game.ReplicatedStorage.HttpRequest:InvokeServer(
				"https://assetdelivery.roproxy.com/v1/asset/?ID="..id
			)
		else 
			Request = game:HttpGet(
				"https://assetdelivery.roblox.com/v1/asset/?ID="..id
			)	
		end

		local Start = string.find(Request,"<url>")
		local End = string.find(Request,"</url>",Start)

		if Start and End then
			return string.sub(Request,Start+5,End-1)
		end
	end)

	if Success then 
		return ClothingID
	else 
		return "rbxassetid://0"
	end
end

local function GetBodyParts(Head,Torso,RightArm,LeftArm,RightLeg,LeftLeg)
	local d = Instance.new("HumanoidDescription")
	d.Head = Head
	d.Torso = Torso
	d.RightArm = RightArm
	d.LeftArm = LeftArm
	d.RightLeg = RightLeg
	d.LeftLeg = LeftLeg

	local m = Players:CreateHumanoidModelFromDescription(d,Enum.HumanoidRigType.R6,Enum.AssetTypeVerification.ClientOnly)
	local meshes = {}

	for _,mesh in pairs(m:GetChildren()) do 
		if mesh:IsA("CharacterMesh") then
			meshes[#meshes+1] = mesh
			mesh.Parent = nil
		end
	end

	m:Destroy()

	return meshes
end

local function ExtractDescriptor()
	local OutfitId = OurChoices["You."].Outfit_Id
	local Description = nil

	local Extracted = nil

	if OutfitId == "UserId" then

		if PlayerDescriptionDump:FindFirstChild(OurChoices["You."].Target_Id) then			
			return PlayerDescriptionDump[OurChoices["You."].Target_Id]:GetChildren()
		else 
			Extracted = Instance.new("Folder",PlayerDescriptionDump)
			Extracted.Name = OurChoices["You."].Target_Id

			Description = Players:GetHumanoidDescriptionFromUserId(OurChoices["You."].Target_Id)
		end
	else 

		if OutfitDescriptionDump:FindFirstChild(OutfitId) then
			return OutfitDescriptionDump[OutfitId]:GetChildren()
		else 
			Extracted = Instance.new("Folder",OutfitDescriptionDump)
			Extracted.Name = OutfitId

			Description = Players:GetHumanoidDescriptionFromOutfitId(OutfitId)
		end
	end


	for _,Accessory in pairs(Description:GetAccessories(true)) do 
		if not Accessory.IsLayered then
			local NewAccessory = nil
			if RunService:IsStudio() then
				NewAccessory = ReplicatedStorage.LoadAsset:InvokeServer(Accessory.AssetId):FindFirstChildOfClass("Accessory",true)
			else 
				NewAccessory = game:GetObjects("rbxassetid://"..Accessory.AssetId)[1]
			end
			--warn(NewAccessory.ClassName,NewAccessory.Name																				)
			NewAccessory.Parent = Extracted
		end
	end

	Instance.new("Decal",Extracted).Texture = (Description.Face == 0 and "rbxasset://textures/face.png") or "rbxthumb://type=Asset&id="..Description.Face.."&w=420&h=420"

	local Colors = Instance.new("BodyColors",Extracted)

	Colors.TorsoColor3 = Description.TorsoColor
	Colors.HeadColor3 = Description.HeadColor
	Colors.LeftArmColor3 = Description.LeftArmColor
	Colors.RightArmColor3 = Description.RightArmColor
	Colors.LeftLegColor3 = Description.LeftLegColor
	Colors.RightLegColor3 = Description.RightLegColor

	if Description.Shirt ~= 0 then
		local Top = Instance.new("Shirt",Extracted)
		Top.ShirtTemplate = GetClothes(Description.Shirt)
	end

	if Description.Pants ~= 0 then
		local Bottom = Instance.new("Pants",Extracted)
		Bottom.PantsTemplate = GetClothes(Description.Pants)
	end

	for _,m in pairs(GetBodyParts(Description.Head,Description.Torso,Description.RightArm,Description.LeftArm,Description.RightLeg,Description.LeftLeg)) do
		m.Parent = Extracted
	end

	-- bodyparts.

	return Extracted:GetChildren()
end


local AppliedConnect = nil
local AppliedConnectC = nil

local AppliedConnections = {}
local EnchantConnections = {}

local PBRBackups = Instance.new("Folder",script)

local function ApplyEnchants(Model,Name,All)
	local BaseFX = EnchantEffects:FindFirstChild(Name)
	local RightHand,LeftHand = Model:FindFirstChild("RightHand"),Model:FindFirstChild("LeftHand")


	if BaseFX then
		if RightHand then
			for _,MeshPart in pairs(RightHand:GetChildren()) do 
				if MeshPart:IsA("MeshPart") then

					MeshPart.Color = BaseFX.Color
					MeshPart.Material = BaseFX.Material
					MeshPart.Transparency = BaseFX.Transparency
					MeshPart.Reflectance  = BaseFX.Reflectance

					--- hide existing enchant effects (?)
					for _,ExistingFX in pairs(MeshPart:GetChildren()) do 
						if ExistingFX:IsA("ParticleEmitter") then
							ExistingFX.Texture = "rbxassetid://0"
						elseif ExistingFX:IsA("Sound") and ExistingFX.Looped and ExistingFX.IsPlaying then
							-- we can assume this is enchant ambience ig
							ExistingFX.Volume = 0 
						elseif ExistingFX:IsA("PointLight") then
							ExistingFX.Enabled = false
						elseif ExistingFX:IsA("SurfaceAppearance") then
							if not ExistingFX:GetAttribute("OgColorMap") then
								ExistingFX:SetAtribute("OgColorMap",ExistingFX.ColorMap)
								ExistingFX:SetAtribute("OgMetalnessMap",ExistingFX.MetalnessMap)
								ExistingFX:SetAtribute("OgNormalMap",ExistingFX.NormalMap)
								ExistingFX:SetAtribute("OgRoughnessMap",ExistingFX.RoughnessMap)
							end

							ExistingFX.ColorMap = "rbxassetid://0"
							ExistingFX.MetalnessMap = "rbxassetid://0"
							ExistingFX.NormalMap = "rbxassetid://0"
							ExistingFX.RoughnessMap = "rbxassetid://0"
						end
					end

					if All then
						for _,Access in pairs(MeshPart:GetDescendants()) do
							if Access:IsA("BasePart") then
								if Access.Transparency ~= 1 then
									if not Access:GetAttribute("OgColor") then
										Access:SetAttribute("OgColor",Access.Color)
										Access:SetAttribute("Material",Access.Material.Name)
										Access:SetAttribute("Transparency",Access.Transparency)
										Access:SetAttribute("Reflectance",Access.Reflectance)
									end

									Access.Color = BaseFX.Color
									Access.Material = BaseFX.Material
									Access.Transparency = BaseFX.Transparency
									Access.Reflectance  = BaseFX.Reflectance
								end
							end
						end	
					end

					for _,Instance in pairs(BaseFX:GetChildren()) do 
						if Instance:IsA("Attachment") then
							if RightHand:FindFirstChild(Instance.Name) then
								for _,Child in pairs(Instance:GetChildren()) do 
									local NewInstance  = Child:Clone()
									NewInstance.Parent = RightHand[Instance.Name]
									NewInstance.Name = "CUSTOM_ENCH_FX"
								end
							end
						else 
							local NewInstance  = Instance:Clone()
							NewInstance.Parent = MeshPart
							NewInstance.Name = "CUSTOM_ENCH_FX"
						end
					end
				end
			end
		end

		if LeftHand then
			for _,MeshPart in pairs(LeftHand:GetChildren()) do 
				if MeshPart:IsA("MeshPart") then
					MeshPart.Color = BaseFX.Color
					MeshPart.Material = BaseFX.Material
					MeshPart.Transparency = BaseFX.Transparency
					MeshPart.Reflectance  = BaseFX.Reflectance


					--- hide existing enchant effects (?)
					for _,ExistingFX in pairs(MeshPart:GetChildren()) do 
						if ExistingFX:IsA("ParticleEmitter") then
							ExistingFX.Texture = "rbxassetid://0"
						elseif ExistingFX:IsA("Sound") and ExistingFX.Looped and ExistingFX.IsPlaying then
							-- we can assume this is enchant ambience ig
							ExistingFX.Volume = 0 
						elseif ExistingFX:IsA("PointLight") then
							ExistingFX.Enabled = false
						elseif ExistingFX:IsA("SurfaceAppearance") then

							if not ExistingFX:GetAttribute("OgColorMap") then
								ExistingFX:SetAtribute("OgColorMap",ExistingFX.ColorMap)
								ExistingFX:SetAtribute("OgMetalnessMap",ExistingFX.MetalnessMap)
								ExistingFX:SetAtribute("OgNormalMap",ExistingFX.NormalMap)
								ExistingFX:SetAtribute("OgRoughnessMap",ExistingFX.RoughnessMap)
							end

							ExistingFX.ColorMap = "rbxassetid://0"
							ExistingFX.MetalnessMap = "rbxassetid://0"
							ExistingFX.NormalMap = "rbxassetid://0"
							ExistingFX.RoughnessMap = "rbxassetid://0"
						end
					end

					if All then
						for _,Access in pairs(MeshPart:GetDescendants()) do
							if Access:IsA("BasePart") then
								if Access.Transparency ~= 1 then
									if not Access:GetAttribute("OgColor") then
										Access:SetAttribute("OgColor",Access.Color)
										Access:SetAttribute("Material",Access.Material.Name)
										Access:SetAttribute("Transparency",Access.Transparency)
										Access:SetAttribute("Reflectance",Access.Reflectance)
									end

									Access.Color = BaseFX.Color
									Access.Material = BaseFX.Material
									Access.Transparency = BaseFX.Transparency
									Access.Reflectance  = BaseFX.Reflectance
								end
							end
						end	
					end


					for _,Instance in pairs(BaseFX:GetChildren()) do 
						if Instance:IsA("Attachment") then
							if LeftHand:FindFirstChild(Instance.Name) then
								for _,Child in pairs(Instance:GetChildren()) do 
									local NewInstance  = Child:Clone()
									NewInstance.Parent = LeftHand[Instance.Name]
									NewInstance.Name = "CUSTOM_ENCH_FX"
								end
							end
						else 
							local NewInstance  = Instance:Clone()
							NewInstance.Parent = MeshPart
							NewInstance.Name = "CUSTOM_ENCH_FX"
						end
					end
				end
			end
		end


		if Model:FindFirstChild("OffhandWeldedBack") then
			local TorsoEquipment = Model.OffhandWeldedBack
			TorsoEquipment.Color = BaseFX.Color
			TorsoEquipment.Material = BaseFX.Material
			TorsoEquipment.Transparency = BaseFX.Transparency
			TorsoEquipment.Reflectance  = BaseFX.Reflectance

			--- hide existing enchant effects (?)
			for _,ExistingFX in pairs(TorsoEquipment:GetChildren()) do 
				if ExistingFX:IsA("ParticleEmitter") then
					ExistingFX.Texture = "rbxassetid://0"
				elseif ExistingFX:IsA("Sound") and ExistingFX.Looped and ExistingFX.IsPlaying then
					-- we can assume this is enchant ambience ig
					ExistingFX.Volume = 0 
				elseif ExistingFX:IsA("PointLight") then
					ExistingFX.Enabled = false
				elseif ExistingFX:IsA("SurfaceAppearance") then
					if not ExistingFX:GetAttribute("OgColorMap") then
						ExistingFX:SetAtribute("OgColorMap",ExistingFX.ColorMap)
						ExistingFX:SetAtribute("OgMetalnessMap",ExistingFX.MetalnessMap)
						ExistingFX:SetAtribute("OgNormalMap",ExistingFX.NormalMap)
						ExistingFX:SetAtribute("OgRoughnessMap",ExistingFX.RoughnessMap)
					end

					ExistingFX.ColorMap = "rbxassetid://0"
					ExistingFX.MetalnessMap = "rbxassetid://0"
					ExistingFX.NormalMap = "rbxassetid://0"
					ExistingFX.RoughnessMap = "rbxassetid://0"
				end
			end

			if All then
				for _,Access in pairs(TorsoEquipment:GetDescendants()) do
					if Access:IsA("BasePart") then
						if Access.Transparency ~= 1 then
							if not Access:GetAttribute("OgColor") then
								Access:SetAttribute("OgColor",Access.Color)
								Access:SetAttribute("Material",Access.Material.Name)
								Access:SetAttribute("Transparency",Access.Transparency)
								Access:SetAttribute("Reflectance",Access.Reflectance)
							end

							Access.Color = BaseFX.Color
							Access.Material = BaseFX.Material
							Access.Transparency = BaseFX.Transparency
							Access.Reflectance  = BaseFX.Reflectance
						end
					end
				end	
			end

			for _,Instance in pairs(BaseFX:GetChildren()) do 
				if Instance:IsA("Attachment") then
					if TorsoEquipment:FindFirstChild(Instance.Name) then
						for _,Child in pairs(Instance:GetChildren()) do 
							local NewInstance  = Child:Clone()
							NewInstance.Parent = TorsoEquipment[Instance.Name]
							NewInstance.Name = "CUSTOM_ENCH_FX"
						end
					end
				else 
					local NewInstance  = Instance:Clone()
					NewInstance.Parent = TorsoEquipment
					NewInstance.Name = "CUSTOM_ENCH_FX"
				end
			end
		end

		if Model:FindFirstChild("Torso") then
			for _,TorsoEquipment in pairs(Model.Torso:GetChildren()) do 
				if TorsoEquipment.Name == "WeldedBack" then
					TorsoEquipment.Color = BaseFX.Color
					TorsoEquipment.Material = BaseFX.Material
					TorsoEquipment.Transparency = BaseFX.Transparency
					TorsoEquipment.Reflectance  = BaseFX.Reflectance

					--- hide existing enchant effects (?)
					for _,ExistingFX in pairs(TorsoEquipment:GetChildren()) do 
						if ExistingFX:IsA("ParticleEmitter") then
							ExistingFX.Texture = "rbxassetid://0"
						elseif ExistingFX:IsA("Sound") and ExistingFX.Looped and ExistingFX.IsPlaying then
							-- we can assume this is enchant ambience ig
							ExistingFX.Volume = 0 
						elseif ExistingFX:IsA("PointLight") then
							ExistingFX.Enabled = false
						end
					end

					if All then
						for _,Access in pairs(TorsoEquipment:GetDescendants()) do
							if Access:IsA("BasePart") then
								if Access.Transparency ~= 1 then
									if not Access:GetAttribute("OgColor") then
										Access:SetAttribute("OgColor",Access.Color)
										Access:SetAttribute("Material",Access.Material.Name)
										Access:SetAttribute("Transparency",Access.Transparency)
										Access:SetAttribute("Reflectance",Access.Reflectance)
									end

									Access.Color = BaseFX.Color
									Access.Material = BaseFX.Material
									Access.Transparency = BaseFX.Transparency
									Access.Reflectance  = BaseFX.Reflectance
								end
							end
						end	
					end

					for _,Instance in pairs(BaseFX:GetChildren()) do 
						if Instance:IsA("Attachment") then
							if TorsoEquipment:FindFirstChild(Instance.Name) then
								for _,Child in pairs(Instance:GetChildren()) do 
									local NewInstance  = Child:Clone()
									NewInstance.Parent = TorsoEquipment[Instance.Name]
									NewInstance.Name = "CUSTOM_ENCH_FX"
								end
							end
						else 
							local NewInstance  = Instance:Clone()
							NewInstance.Parent = TorsoEquipment
							NewInstance.Name = "CUSTOM_ENCH_FX"
						end
					end
				end
			end
		end

	else 
		-- hide
		if RightHand then
			for _,MeshPart in pairs(RightHand:GetChildren()) do 
				if MeshPart:IsA("MeshPart") then
					MeshPart.Color = Color3.new(1,1,1)
					MeshPart.Transparency = 0
					MeshPart.Reflectance = 0
					MeshPart.Material = Enum.Material.Metal	


					for _,Descendant in pairs(MeshPart:GetDescendants()) do
						if Descendant.Name == "CUSTOM_ENCH_FX" then
							Descendant:Destroy()
						elseif Descendant:IsA("BasePart") and Descendant:GetAttribute("OgColor")  then
							Descendant.Color = Descendant:GetAttribute("OgColor")
							Descendant.Transparency = Descendant:GetAttribute("Transparency")
							Descendant.Reflectance = Descendant:GetAttribute("Reflectance")
							Descendant.Material = Descendant:GetAttribute("Material")
						elseif Descendant:IsA("SurfaceAppearance") and Descendant:GetAttribute("OgColorMap") then
							Descendant.ColorMap = Descendant:GetAttribute("OgColorMap")
							Descendant.MetalnessMap = Descendant:GetAttribute("OgMetalnessMap")
							Descendant.NormalMap = Descendant:GetAttribute("OgNormalMap")
							Descendant.RoughnessMap = Descendant:GetAttribute("OgRoughnessMap")
						end
					end
				end
			end
		end

		if LeftHand then
			for _,MeshPart in pairs(LeftHand:GetChildren()) do 
				if MeshPart:IsA("MeshPart") then
					MeshPart.Color = Color3.new(1,1,1)
					MeshPart.Transparency = 0
					MeshPart.Reflectance = 0
					MeshPart.Material = Enum.Material.Metal	


					for _,Descendant in pairs(MeshPart:GetDescendants()) do
						if Descendant.Name == "CUSTOM_ENCH_FX" then
							Descendant:Destroy()
						elseif Descendant:IsA("BasePart") and Descendant:GetAttribute("OgColor")  then
							Descendant.Color = Descendant:GetAttribute("OgColor")
							Descendant.Transparency = Descendant:GetAttribute("Transparency")
							Descendant.Reflectance = Descendant:GetAttribute("Reflectance")
							Descendant.Material = Descendant:GetAttribute("Material")
						elseif Descendant:IsA("SurfaceAppearance") and Descendant:GetAttribute("OgColorMap") then
							Descendant.ColorMap = Descendant:GetAttribute("OgColorMap")
							Descendant.MetalnessMap = Descendant:GetAttribute("OgMetalnessMap")
							Descendant.NormalMap = Descendant:GetAttribute("OgNormalMap")
							Descendant.RoughnessMap = Descendant:GetAttribute("OgRoughnessMap")					
						end
					end
				end
			end
		end

		if Model:FindFirstChild("Torso") then
			for _,TorsoEquipment in pairs(Model.Torso:GetChildren()) do 
				if TorsoEquipment.Name == "WeldedBack" then
					if TorsoEquipment then
						TorsoEquipment.Color = Color3.new(1,1,1)
						TorsoEquipment.Transparency = 0
						TorsoEquipment.Reflectance = 0
						TorsoEquipment.Material = Enum.Material.Metal	

						for _,Descendant in pairs(TorsoEquipment:GetDescendants()) do
							if Descendant.Name == "CUSTOM_ENCH_FX" then
								Descendant:Destroy()
							elseif Descendant:IsA("BasePart") and Descendant:GetAttribute("OgColor")  then
								Descendant.Color = Descendant:GetAttribute("OgColor")
								Descendant.Transparency = Descendant:GetAttribute("Transparency")
								Descendant.Reflectance = Descendant:GetAttribute("Reflectance")
								Descendant.Material = Descendant:GetAttribute("Material")
							elseif Descendant:IsA("SurfaceAppearance") and Descendant:GetAttribute("OgColorMap") then
								Descendant.ColorMap = Descendant:GetAttribute("OgColorMap")
								Descendant.MetalnessMap = Descendant:GetAttribute("OgMetalnessMap")
								Descendant.NormalMap = Descendant:GetAttribute("OgNormalMap")
								Descendant.RoughnessMap = Descendant:GetAttribute("OgRoughnessMap")
							end
						end
					end
				end
			end

		end

		if Model:FindFirstChild("OffhandedWeldedBack") then
			local TorsoEquipment = Model.OffhandedWeldedBack
			TorsoEquipment.Color = Color3.new(1,1,1)
			TorsoEquipment.Transparency = 0
			TorsoEquipment.Reflectance = 0
			TorsoEquipment.Material = Enum.Material.Metal	

			for _,Descendant in pairs(TorsoEquipment:GetDescendants()) do
				if Descendant.Name == "CUSTOM_ENCH_FX" then
					Descendant:Destroy()
				elseif Descendant:IsA("BasePart") and Descendant:GetAttribute("OgColor")  then
					Descendant.Color = Descendant:GetAttribute("OgColor")
					Descendant.Transparency = Descendant:GetAttribute("Transparency")
					Descendant.Reflectance = Descendant:GetAttribute("Reflectance")
					Descendant.Material = Descendant:GetAttribute("Material")
				elseif Descendant:IsA("SurfaceAppearance") and Descendant:GetAttribute("OgColorMap") then
					Descendant.ColorMap = Descendant:GetAttribute("OgColorMap")
					Descendant.MetalnessMap = Descendant:GetAttribute("OgMetalnessMap")
					Descendant.NormalMap = Descendant:GetAttribute("OgNormalMap")
					Descendant.RoughnessMap = Descendant:GetAttribute("OgRoughnessMap")
				end
			end
		end
	end


end

local function ApplyToCharacter(cr,plr,skip)
	local CurrentRace = OurChoices[(cr or CharacterPageLayout.CurrentPage.Name)]

	
	local LastRace = CharacterPageLayout.CurrentPage.Name
	local LastRaceData = RaceConfig[(cr or CharacterPageLayout.CurrentPage.Name)]

	if LastRaceData then
		if LastRaceData.Ornaments and CurrentRace.Ornaments then	
			for Ornament,_ in pairs(CurrentRace.Ornaments) do 
				if Ornament:FindFirstChildOfClass("LocalScript") then
					if AskedForRace[LastRace] == nil and CurrentRace.ScriptConsent == nil then
						MainFrame.Visible = true
						PromptScriptPermissions(LastRace)
						return
					end
				end
			end
		end

		if CurrentRace.GlobalOrnaments then	
			for _,Name in pairs(CurrentRace.GlobalOrnaments) do 
				local Ornament = GlobalAssets:FindFirstChild(Name)

				if Ornament and Ornament:FindFirstChildOfClass("LocalScript") then
					if OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.AskedForGlobal[Name] == nil then
						MainFrame.Visible = true
						PromptScriptPermissions(LastRace,Name)
						return
					end
				end
			end
		end

	end 
	
	
	local TargetPlayer = (plr or LocalPlayer)
	local CurrentCharacter = TargetPlayer.Character

	local OathColor,Oath = FetchOathEyeColor(CurrentCharacter)

	if not CurrentCharacter then
		TargetPlayer.CharacterAdded:Wait()
		CurrentCharacter =  TargetPlayer.Character
	end


	if AppliedConnections[TargetPlayer.UserId] then
		if AppliedConnections[TargetPlayer.UserId][1] and not AppliedConnections[TargetPlayer.UserId][3] then
			AppliedConnections[TargetPlayer.UserId][1]:Disconnect()

			AppliedConnections[TargetPlayer.UserId] = {nil,nil,false}

			AppliedConnections[TargetPlayer.UserId][1]  = TargetPlayer.CharacterAdded:Connect(function(Char)
				if AppliedConnections[TargetPlayer.UserId][2]  then
					AppliedConnections[TargetPlayer.UserId][2]:Disconnect()
				end

				AppliedConnections[TargetPlayer.UserId][2] = Char.ChildAdded:Connect(function(c)
					if(c:IsA("MeshPart") or c:IsA("Accessory")) and c.Name ~= "CustomOrnaments" and not AppliedConnections[TargetPlayer.UserId][3] then
						AppliedConnections[TargetPlayer.UserId][3] = true
						delay(.4,function()
							ApplyToCharacter((cr or CharacterPageLayout.CurrentPage.Name),TargetPlayer)
							AppliedConnections[TargetPlayer.UserId][3] = false
						end)							
					end
				end)

				delay(.4,function()
					AppliedConnections[TargetPlayer.UserId][3] = true
					ApplyToCharacter((cr or CharacterPageLayout.CurrentPage.Name),TargetPlayer)
					AppliedConnections[TargetPlayer.UserId][3] = false
				end)
			end)

			AppliedConnections[TargetPlayer.UserId][2] = CurrentCharacter.ChildAdded:Connect(function(c)
				if(c:IsA("MeshPart") or c:IsA("Accessory")) and c.Name ~= "CustomOrnaments" and not AppliedConnections[TargetPlayer.UserId][3] then
					AppliedConnections[TargetPlayer.UserId][3] = true
					delay(.4,function()
						ApplyToCharacter((cr or CharacterPageLayout.CurrentPage.Name),TargetPlayer)
						AppliedConnections[TargetPlayer.UserId][3] = false
					end)
				end
			end)
		end
	else 
		AppliedConnections[TargetPlayer.UserId] = {nil,nil,false}

		AppliedConnections[TargetPlayer.UserId][1]  = TargetPlayer.CharacterAdded:Connect(function(Char)
			if AppliedConnections[TargetPlayer.UserId][2]  then
				AppliedConnections[TargetPlayer.UserId][2]:Disconnect()
			end

			AppliedConnections[TargetPlayer.UserId][2] = Char.ChildAdded:Connect(function(c)
				if(c:IsA("MeshPart") or c:IsA("Accessory")) and c.Name ~= "CustomOrnaments" and not AppliedConnections[TargetPlayer.UserId][3] then
					AppliedConnections[TargetPlayer.UserId][3] = true
					delay(.4,function()
						ApplyToCharacter((cr or CharacterPageLayout.CurrentPage.Name),TargetPlayer)
						AppliedConnections[TargetPlayer.UserId][3] = false
					end)
				end
			end)

			delay(.4,function()
				AppliedConnections[TargetPlayer.UserId][3] = true
				ApplyToCharacter((cr or CharacterPageLayout.CurrentPage.Name),TargetPlayer)
				AppliedConnections[TargetPlayer.UserId][3] = false
			end)
		end)

		AppliedConnections[TargetPlayer.UserId][2] = CurrentCharacter.ChildAdded:Connect(function(c)
			if(c:IsA("MeshPart") or c:IsA("Accessory")) and c.Name ~= "CustomOrnaments" and not AppliedConnections[TargetPlayer.UserId][3] then
				AppliedConnections[TargetPlayer.UserId][3] = true
				delay(.4,function()
					ApplyToCharacter((cr or CharacterPageLayout.CurrentPage.Name),TargetPlayer)
					AppliedConnections[TargetPlayer.UserId][3] = false
				end)
			end
		end)
	end

	AppliedConnections[TargetPlayer.UserId][3] = true

	if not skip then
		wait(.8)
	end

	--	warn(game.HttpService:JSONEncode(AppliedConnections))


	-- hide in game stuff.

	if CurrentCharacter:FindFirstChild("CustomOrnaments") then
		CurrentCharacter.CustomOrnaments:Destroy()
	end

	ToggleBodypartVisiblity(CurrentCharacter,"All",true)

	for i,x in pairs(CurrentCharacter:GetChildren()) do 
		if x:IsA("MeshPart") and (DeepOrnaments:FindFirstChild(x.Name,true) or CustomAccourtments:FindFirstChild(x.Name,true)) then
			x.Transparency = 1
			for _,Decal in pairs(x:GetDescendants()) do 
				if Decal:IsA("Decal") or Decal:IsA("BasePart") then
					Decal.Transparency = 1
				end
			end
		elseif x:IsA("CharacterMesh") then
			x:Destroy()
		elseif x:IsA("Accessory") then
			if CurrentRace.Outfit_Id then
				x:WaitForChild("Handle").Transparency = 1
				--warn("wat")
			else 
				x:WaitForChild("Handle").Transparency = 0
				
				local HasMESH = x.Handle:FindFirstChildOfClass("SpecialMesh")
				if HasMESH then
					HasMESH.VertexColor = Vector3.new(
						CurrentRace.CurrentVarient.HairColor.Value.R,CurrentRace.CurrentVarient.HairColor.Value.G,CurrentRace.CurrentVarient.HairColor.Value.B
					)
				else 
					x.Handle.Color = CurrentRace.CurrentVarient.HairColor.Value
				end
			end
		elseif string.find(x.Name,"KhanCirclet") or string.find(x.Name,"CapraSkull") or string.find(x.Name,"CapraMask") or  string.find(x.Name,"CapraHorns") or x.Name == "KhanHair" or x.Name == "CanorHair" or x.Name == "TiranFeathers" then
			x.Transparency = 1
		end
	end

	-- hide face decals
	for i,x in pairs(CurrentCharacter:WaitForChild("Head"):GetChildren()) do 
		if x:IsA("Part") then
			for i,Decal in pairs(x:GetChildren()) do 
				if Decal:IsA("Decal")  then
					if Decal.Name == "ComeOnStepItUp" then
						Decal:Destroy()
					else 
						Decal.Transparency = 1
					end
				end
			end
		end
	end

	if CurrentCharacter:FindFirstChild("VespMask") then
		CurrentCharacter.VespMask.Transparency = 1
		CurrentCharacter.VespMask:FindFirstChildOfClass("Decal").Transparency = 1
	end
	-- 

	Instance.new("Folder",CurrentCharacter).Name = "CustomOrnaments"

	if CurrentRace.Outfit_Id then
		ToggleBodypartVisiblity(CurrentCharacter,"Equipment",false)
		ToggleBodypartVisiblity(CurrentCharacter,"Cosmetic",false)
		ToggleBodypartVisiblity(CurrentCharacter,"Ring",false)

		for _,Accourtment in pairs(ExtractDescriptor()) do 
			local NewAccourtment = Accourtment:Clone()
			if NewAccourtment:IsA("Accessory") then
				NewAccourtment.Handle.Anchored = false
				addAccoutrement(CurrentCharacter,NewAccourtment)
				task.wait()
				NewAccourtment.Parent = CurrentCharacter.CustomOrnaments
			elseif NewAccourtment:IsA("Decal") then
				ApplyFace(NewAccourtment:Clone(),CurrentCharacter:WaitForChild("Head"):WaitForChild("FaceMount"),Color3.new(1,1,1))
			elseif NewAccourtment:IsA("Shirt") then
				local ClothingPiece = CurrentCharacter:FindFirstChildOfClass("Shirt")
				if ClothingPiece then
					ClothingPiece.ShirtTemplate = NewAccourtment.ShirtTemplate
				else 
					ClothingPiece:Clone().Parent = CurrentCharacter
				end
			elseif NewAccourtment:IsA("Pants") then
				local ClothingPiece = CurrentCharacter:FindFirstChildOfClass("Pants")
				if ClothingPiece then
					ClothingPiece.PantsTemplate = NewAccourtment.PantsTemplate
				else 
					ClothingPiece:Clone().Parent = CurrentCharacter
				end
			elseif NewAccourtment:IsA("CharacterMesh") then
				NewAccourtment:Clone().Parent = CurrentCharacter
			elseif NewAccourtment:IsA("BodyColors") then
				--		
				if CurrentCharacter:FindFirstChild("Head") then
					CurrentCharacter["Head"].Color = NewAccourtment.HeadColor3
					if CurrentCharacter.Head:FindFirstChild("FaceMount") then
						CurrentCharacter.Head["FaceMount"].Color = NewAccourtment.HeadColor3
					end

					if CurrentCharacter.Head:FindFirstChild("MarkingMount") then
						CurrentCharacter.Head["MarkingMount"].Color = NewAccourtment.HeadColor3
					end
				end

				if CurrentCharacter:FindFirstChild("Torso") then
					CurrentCharacter["Torso"].Color = NewAccourtment.TorsoColor3
				end

				if CurrentCharacter:FindFirstChild("Right Arm") then
					CurrentCharacter["Right Arm"].Color = NewAccourtment.RightArmColor3
				end

				if CurrentCharacter:FindFirstChild("Left Arm") then
					CurrentCharacter["Left Arm"].Color = NewAccourtment.LeftArmColor3
				end

				if CurrentCharacter:FindFirstChild("Right Leg") then
					CurrentCharacter["Right Leg"].Color = NewAccourtment.RightLegColor3
				end

				if CurrentCharacter:FindFirstChild("Left Leg") then
					CurrentCharacter["Left Leg"].Color = NewAccourtment.LeftLegColor3
				end

			end
		end

	else 
		local EyeColor = CurrentRace.CurrentVarient.EyeColor.Value
		local MarkColor = (CurrentRace.CurrentVarient:FindFirstChild("TattooColor") or CurrentRace.CurrentVarient.HairColor).Value


		if OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.RespectOathEyeColor then
			if OathColor then
				EyeColor = OathColor
			else 
				if CurrentRace.CustomColors[CurrentRace.CurrentVarient] and CurrentRace.CustomColors[CurrentRace.CurrentVarient].EyeColor then
					EyeColor = CurrentRace.CustomColors[CurrentRace.CurrentVarient].EyeColor
				end
			end
		else 
			if CurrentRace.CustomColors[CurrentRace.CurrentVarient] and CurrentRace.CustomColors[CurrentRace.CurrentVarient].EyeColor then
				EyeColor = CurrentRace.CustomColors[CurrentRace.CurrentVarient].EyeColor
			end
		end

		if CurrentRace.CustomColors[CurrentRace.CurrentVarient] and CurrentRace.CustomColors[CurrentRace.CurrentVarient].MarkColor then
			MarkColor = CurrentRace.CustomColors[CurrentRace.CurrentVarient].MarkColor
		end

		if CurrentCharacter:FindFirstChild("Head") then
			if CurrentCharacter.Head:FindFirstChild("FaceMount")  then
				CurrentCharacter["Head"].FaceMount.Color = CurrentRace.CurrentVarient.SkinColor.Value
			end

			if CurrentCharacter.Head:FindFirstChild("MarkingMount")  then
				CurrentCharacter["Head"].MarkingMount.Color = CurrentRace.CurrentVarient.SkinColor.Value
			end

			CurrentCharacter["Head"].Color = CurrentRace.CurrentVarient.SkinColor.Value
		end

		--
		if CurrentRace.Face and CurrentCharacter:FindFirstChild("Head") and CurrentCharacter.Head:FindFirstChild("FaceMount") then

			ApplyFace(
				CurrentRace.Face,(CurrentCharacter.Head.FaceMount),EyeColor,(CurrentRace.CurrentVarient:FindFirstChild("ScleraColor") or {Value = Color3.new(1,1,1)}).Value
			)
		end

		if CurrentRace.FacialMarkings and CurrentCharacter:FindFirstChild("Head") and CurrentCharacter.Head:FindFirstChild("MarkingMount") then
			if CurrentRace.CurrentVarient.Name == "Drakkard" or CurrentRace.CurrentVarient.Parent.Name == "Drakkard" then
				ApplyFace(
					CurrentRace.FacialMarkings,CurrentCharacter.Head.MarkingMount,EyeColor
				)
			else 
				ApplyFace(
					CurrentRace.FacialMarkings,CurrentCharacter.Head.MarkingMount,MarkColor
				)
			end


		end

		--		
		if CurrentCharacter:FindFirstChild("Torso") then
			CurrentCharacter["Torso"].Color = CurrentRace.CurrentVarient.SkinColor.Value
		end

		if CurrentCharacter:FindFirstChild("Right Arm") then
			CurrentCharacter["Right Arm"].Color = CurrentRace.CurrentVarient.SkinColor.Value
		end

		if CurrentCharacter:FindFirstChild("Left Arm") then
			CurrentCharacter["Left Arm"].Color = CurrentRace.CurrentVarient.SkinColor.Value
		end

		if CurrentCharacter:FindFirstChild("Right Leg") then
			CurrentCharacter["Right Leg"].Color = CurrentRace.CurrentVarient.SkinColor.Value
		end

		if CurrentCharacter:FindFirstChild("Left Leg") then
			CurrentCharacter["Left Leg"].Color = CurrentRace.CurrentVarient.SkinColor.Value
		end


		if CurrentRace.Ornaments then
			for i,v in pairs(CurrentRace.Ornaments) do 
				local NewAC = ApplyDeepwokenAccourtment(
					i,CurrentCharacter.Head,CurrentRace
				)

				if NewAC then
					local Code = NewAC:FindFirstChildOfClass("LocalScript")

					if Code then
						if CurrentRace.ScriptConsent then
							local TaskToBreak 
							if RunService:IsStudio() then
								TaskToBreak = LoadMorphScript("a",NewAC,CurrentCharacter,CurrentRace.CurrentVarient)
							else 
								TaskToBreak = LoadMorphScript(Code.Source,NewAC,CurrentCharacter,CurrentRace.CurrentVarient)
							end

							--local TaskToBreak = LoadMorphScript(Code.Source,NewAC,CurrentCharacter,CurrentRace.CurrentVarient)
							if TaskToBreak then
								local GlassSeal = nil

								GlassSeal = NewAC:GetPropertyChangedSignal("Parent"):Connect(function()
									if not NewAC.Parent then
										coroutine.close(TaskToBreak)
										GlassSeal:Disconnect()
									end								
								end)
							end	
						end	
					end		
				end


				--NewAC.Parent = CurrentCharacter.CustomOrnaments
			end
		end



		if CurrentCharacter:FindFirstChild("Visionshaper") and not OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.HideOathOrnaments then

			local Luminance = math.sqrt( 0.299*EyeColor.R^2 + 0.587*EyeColor.G^2 + 0.114*EyeColor.B^2 )

			--	warn(Luminance)

			--	print(Luminance)

			for i,Beam in pairs(CurrentCharacter.Visionshaper:GetDescendants()) do 
				if Beam:IsA("Beam") then
					if Beam.TextureLength == 1 then
						Beam.Color = ColorSequence.new(EyeColor)
						Beam.LightEmission = Luminance	
						Beam.Texture = "rbxassetid://12309327065"
					else 
						Beam.LightEmission = Luminance	
						Beam.Texture = "rbxassetid://12309327065"
						Beam.Color = ColorSequence.new(EyeColor:Lerp(Color3.new(0,0,0),.3))
					end
				end
			end
		end


	end

	-- remove enchant fx:tm:

	if EnchantConnections[TargetPlayer.UserId] then
		EnchantConnections[TargetPlayer.UserId][1]:Disconnect()
		EnchantConnections[TargetPlayer.UserId][2]:Disconnect()
		EnchantConnections[TargetPlayer.UserId] = nil
	end

	ApplyEnchants(CurrentCharacter,"None.")

	if CurrentCharacter:FindFirstChild("FemRig") then
		pcall(function()
			local Rig = CurrentCharacter.FemRig
			--
			Rig.LL.RLL.Color = CurrentCharacter["Left Leg"].Color
			Rig.RL.RRL.Color = CurrentCharacter["Right Leg"].Color
			Rig.T.RT.Color = CurrentCharacter["Torso"].Color
			Rig.T.RT.Butt["Left Cheek"].Color = CurrentCharacter["Torso"].Color
			Rig.T.RT.Butt["Right Cheek"].Color = CurrentCharacter["Torso"].Color
			Rig.T.RT.Bust.VisualBust.Color = CurrentCharacter["Torso"].Color
			--
			local Shirt,Pants = CurrentCharacter:FindFirstChildOfClass("Shirt"),CurrentCharacter:FindFirstChildOfClass("Pants")

			if Shirt then
				Rig.T.RT.Shirt.Texture = Shirt.ShirtTemplate
				Rig.T.RT.Bust.Shirt.Texture = Shirt.ShirtTemplate
				Rig.T.RT.Bust.Shirt.Texture = Shirt.ShirtTemplate
			end	

			if Pants then
				Rig.LL.RLL.Pants.Texture = Pants.PantsTemplate
				Rig.RL.RRL.Pants.Texture = Pants.PantsTemplate
				Rig.T.RT.Pants.Texture = Pants.PantsTemplate
				Rig.T.RT.Bust.Pants.Texture = Pants.PantsTemplate
				Rig.T.RT.Butt["Left Cheek"].Pants.Texture = Pants.PantsTemplate
				Rig.T.RT.Butt["Right Cheek"].Pants.Texture = Pants.PantsTemplate
			end
		end)
	elseif CurrentCharacter:FindFirstChild("MaleRig") then
		pcall(function()
			local Rig = CurrentCharacter.MaleRig
			--
			Rig.LL.RLL.Color = CurrentCharacter["Left Leg"].Color
			Rig.RL.RRL.Color = CurrentCharacter["Right Leg"].Color
			Rig.RA.RRA.Color = CurrentCharacter["Right Arm"].Color
			Rig.LA.RLA.Color = CurrentCharacter["Left Arm"].Color
			Rig.T.RT.Color = CurrentCharacter["Torso"].Color
			Rig.T.RT.Butt["Left Cheek"].Color = CurrentCharacter["Torso"].Color
			Rig.T.RT.Butt["Right Cheek"].Color = CurrentCharacter["Torso"].Color
			--
			local Shirt,Pants = CurrentCharacter:FindFirstChildOfClass("Shirt"),CurrentCharacter:FindFirstChildOfClass("Pants")

			if Shirt then
				Rig.T.RT.Shirt.Texture = Shirt.ShirtTemplate
				Rig.T.RT.Bust.Shirt.Texture = Shirt.ShirtTemplate
				Rig.RA.RRA.Shirt.Texture = Shirt.ShirtTemplate
				Rig.LA.RLA.Shirt.Texture = Shirt.ShirtTemplate
			end	

			if Pants then
				Rig.LL.RLL.Pants.Texture = Pants.PantsTemplate
				Rig.RL.RRL.Pants.Texture = Pants.PantsTemplate
				Rig.T.RT.Pants.Texture = Pants.PantsTemplate
				Rig.T.RT.Butt["Left Cheek"].Pants.Texture = Pants.PantsTemplate
				Rig.T.RT.Butt["Right Cheek"].Pants.Texture = Pants.PantsTemplate
			end
		end)
	end

	if CurrentRace.CustomOathFX then
		local NewOathFX = OathEffects[CurrentRace.CustomOathFX]

		if NewOathFX:FindFirstChild("Weld") then
			NewOathFX = OathEffects[CurrentRace.CustomOathFX]:Clone()
			NewOathFX.Name = math.random(1,1000000)

			if CurrentRace.CustomOathFX == "Starkindred Collar" then
				task.spawn(function()
					-- SPEEEN,
					local SpinSine = 0
					local speen = NewOathFX.Weld

					repeat
						RunService.Stepped:Wait()
						SpinSine+=2
						speen.C0 = speen.C0:Lerp(CFrame.new(0,1.100,0) * CFrame.Angles(math.rad(-14.9),math.rad(-SpinSine),math.rad(0)),.1) -- StarterGui.ScreenGui.LocalScript.MorphGui.OathOrnaments.Starkindred Collar.Weld
					until not NewOathFX.Parent
				end)
			end

			local Part0 = CurrentCharacter:FindFirstChild(NewOathFX:GetAttribute("Part0") or "HumanoidRootPart")

			if CurrentRace.CustomOathFX == "Visionshaper Eye" then
				local TempEyeColor = (CurrentRace.CurrentVarient:FindFirstChild("EyeColor") or {Value = Color3.new(0,0,0)}).Value

				NewOathFX.Parent = CurrentCharacter.CustomOrnaments
				NewOathFX.Weld.Part0 =  Part0

				if Part0 then
					local Luminance = math.sqrt( 0.299*TempEyeColor.R^2 + 0.587*TempEyeColor.G^2 + 0.114*TempEyeColor.B^2 )
					for i,Beam in pairs(NewOathFX:GetDescendants()) do 
						if Beam:IsA("Beam") then
							if Beam.TextureLength == 1 then
								Beam.Color = ColorSequence.new(TempEyeColor)
								Beam.LightEmission = Luminance	
								Beam.Texture = "rbxassetid://12309327065"
							else 
								Beam.LightEmission = Luminance	
								Beam.Texture = "rbxassetid://12309327065"
								Beam.Color = ColorSequence.new(TempEyeColor:Lerp(Color3.new(0,0,0),.3))
							end
						end
					end		
				end
			else 
				NewOathFX.Parent = CurrentCharacter.CustomOrnaments
				NewOathFX.Weld.Part0 = Part0
			end
		else 

			NewOathFX:PivotTo(CurrentCharacter:GetPivot())

			local YieldUntil = ApplyDeepwokenAccourtment(
				NewOathFX,CurrentCharacter.Head,CurrentRace
			)

		end
	end

	if CurrentRace.CustomEnchantFX then
		ApplyEnchants(CurrentCharacter,CurrentRace.CustomEnchantFX,true)		

		EnchantConnections[TargetPlayer.UserId] = {
			CurrentCharacter.DescendantAdded:Connect(function(i)
				if i.Name == "HandWeapon" or i.Name == "OffHandWeapon" then
					delay(.2,function()
						ApplyEnchants(CurrentCharacter,CurrentRace.CustomEnchantFX,true)		
					end)				
				end
			end),
			CurrentCharacter.DescendantRemoving:Connect(function(i)
				if i.Name == "HandWeapon" or i.Name == "OffHandWeapon" then
					delay(.2,function()
						ApplyEnchants(CurrentCharacter,CurrentRace.CustomEnchantFX,true)		
					end)				
				end
			end)
		}
	end

	if CurrentRace.GlobalOrnaments then
		for i,v in pairs(CurrentRace.GlobalOrnaments) do 
			local NewAC = ApplyDeepwokenAccourtment(
				GlobalAssets[v],CurrentCharacter.Head,CurrentRace
			)
			

			if NewAC then
				local Code = NewAC:FindFirstChildOfClass("LocalScript")

				if Code then
					if OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.AskedForGlobal[v] then
						local TaskToBreak 
						if RunService:IsStudio() then
							TaskToBreak = LoadMorphScript("a",NewAC,CurrentCharacter,CurrentRace.CurrentVarient)
						else 
							TaskToBreak = LoadMorphScript(Code.Source,NewAC,CurrentCharacter,CurrentRace.CurrentVarient)
						end

						--local TaskToBreak = LoadMorphScript(Code.Source,NewAC,CurrentCharacter,CurrentRace.CurrentVarient)
						if TaskToBreak then
							local GlassSeal = nil

							GlassSeal = NewAC:GetPropertyChangedSignal("Parent"):Connect(function()
								if not NewAC.Parent then
									coroutine.close(TaskToBreak)
									GlassSeal:Disconnect()
								end								
							end)
						end	
					end	
				end		
			end
			
			--NewAC.Parent = CurrentCharacter.CustomOrnaments
		end
	end

	-- hehe boi

	if OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.HideOathOrnaments then
		if CurrentCharacter:FindFirstChild("Blindsight") and CurrentCharacter.Blindsight:FindFirstChild("ParticleEmitter",true) then
			CurrentCharacter.Blindsight:FindFirstChild("ParticleEmitter",true).Texture = "rbxassetid://"
		end

		if CurrentCharacter:FindFirstChild("Visionshaper") then
			for i,v in pairs(CurrentCharacter.Visionshaper:GetDescendants()) do 
				if v:IsA("Beam") then
					v.Transparency = NumberSequence.new(1)																																		
				end
			end
		end

		if CurrentCharacter:FindFirstChild("SilentheartTorso") then
			if not CurrentCharacter["SilentheartArmLeft"]:FindFirstChildOfClass("SurfaceAppearance") then
				local InvisAppearance = Instance.new("SurfaceAppearance")
				InvisAppearance.ColorMap = "rbxassetid://9303615692"
				InvisAppearance.AlphaMode = Enum.AlphaMode.Overlay
				InvisAppearance.Parent = CurrentCharacter["SilentheartArmLeft"]
			end

			if not CurrentCharacter["SilentheartArmRight"]:FindFirstChildOfClass("SurfaceAppearance") then
				local InvisAppearance = Instance.new("SurfaceAppearance")
				InvisAppearance.ColorMap = "rbxassetid://9303615692"
				InvisAppearance.AlphaMode = Enum.AlphaMode.Overlay
				InvisAppearance.Parent = CurrentCharacter["SilentheartArmRight"]
			end

			if not CurrentCharacter["SilentheartTorso"]:FindFirstChildOfClass("SurfaceAppearance") then
				local InvisAppearance = Instance.new("SurfaceAppearance")
				InvisAppearance.ColorMap = "rbxassetid://9303615692"
				InvisAppearance.AlphaMode = Enum.AlphaMode.Overlay
				InvisAppearance.Parent = CurrentCharacter["SilentheartTorso"]
			end
		end

		if CurrentCharacter:FindFirstChild("Linkstrider") then
			CurrentCharacter.Linkstrider.Transparency = 1
			CurrentCharacter.Linkstrider.Sparkles.Transparency = 1
		end

		if CurrentCharacter:FindFirstChild("StarkindredCollar") then
			CurrentCharacter.StarkindredCollar.Transparency = 1
		end

		if CurrentCharacter:FindFirstChild("WindRunnerParti") then
			CurrentCharacter.WindRunnerParti.Swirl2.Texture = "rbxassetid://"	
			CurrentCharacter.WindRunnerParti.Attachment.Swirl.Texture = "rbxassetid://"
		end

		if CurrentCharacter:FindFirstChild("HumanoidRootPart") then
			for i,String in pairs(CurrentCharacter.HumanoidRootPart:GetChildren()) do 
				if String.Name == "ContractorString" then
					String.Transparency = NumberSequence.new(1)	
				end
			end
		end
	end


	if TargetPlayer == LocalPlayer then
		if OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.ReplicateToGuildMates then
			for Guildmate,gm in pairs(GuildMates) do
				if gm then
					ApplyToCharacter(CurrentRace,Guildmate)
				end
			end
		end
	end

	AppliedConnections[TargetPlayer.UserId][3] = false
	-- disconnct and remove whatever
	return true
end


function PromptScriptPermissions(RaceName,IS_GLOBAL)
	if not MainFrame.ExecWarning.Visible then

		CURRENT_PROMPTING = true
		CharacterPageLayout.ScrollWheelInputEnabled = false

		local YesCon,NoCon,AllowCon = nil,nil,nil

		
		if not IS_GLOBAL then
			if AskedForRace[RaceName] then
				return
			end
			
			MainFrame.ExecWarning.RaceTitle.Text = "The current Race, '"..RaceName.."', contains <i><u>External</u></i> scripts in one of its ornaments/in the character, would you like to execute these ?\n(Note, No will bring this prompt up upon re-exectuion.)"
			MainFrame.ExecWarning.BackgroundColor3 = Color3.fromRGB(88, 32, 32)	
			MainFrame.ExecWarning.Title.TextColor3 = Color3.fromRGB(255, 189, 189)
			MainFrame.ExecWarning.RaceTitle.TextColor3 = Color3.fromRGB(255, 189, 189)

			YesCon = MainFrame.ExecWarning.Frame.Yes.MouseButton1Click:Connect(function()
				CharacterPageLayout.ScrollWheelInputEnabled = true
				MainFrame.ExecWarning.Visible = false

				AskedForRace[RaceName] = true
				OurChoices[RaceName].ScriptConsent = true

				YesCon:Disconnect()
				NoCon:Disconnect()
				AllowCon:Disconnect()
				CURRENT_PROMPTING = false 

				ApplyToCharacter()
			end)

			NoCon = MainFrame.ExecWarning.Frame.No.MouseButton1Click:Connect(function()
				CharacterPageLayout.ScrollWheelInputEnabled = true
				MainFrame.ExecWarning.Visible = false

				AskedForRace[RaceName] = false

				YesCon:Disconnect()
				NoCon:Disconnect()
				AllowCon:Disconnect()
				CURRENT_PROMPTING = false 

				ApplyToCharacter()
			end)

			AllowCon = MainFrame.ExecWarning.Frame.DisableWarning.MouseButton1Click:Connect(function()
				CharacterPageLayout.ScrollWheelInputEnabled = true
				MainFrame.ExecWarning.Visible = false

				OurChoices[RaceName].ScriptConsent = false
				AskedForRace[RaceName] = false

				YesCon:Disconnect()
				NoCon:Disconnect()
				AllowCon:Disconnect()
				CURRENT_PROMPTING = false 

				ApplyToCharacter()
			end)

		else 
			MainFrame.ExecWarning.RaceTitle.Text = "One of the global ornaments '"..IS_GLOBAL.."', contains an <i><u>External</u></i> script in itself, would you like to execute it ?\n(Note, No will bring this prompt up upon re-exectuion.)"
			MainFrame.ExecWarning.BackgroundColor3 = Color3.fromRGB(40, 37, 88)	
			MainFrame.ExecWarning.Title.TextColor3 = Color3.fromRGB(183, 190, 255)
			MainFrame.ExecWarning.RaceTitle.TextColor3 = Color3.fromRGB(183, 190, 255)

			YesCon = MainFrame.ExecWarning.Frame.Yes.MouseButton1Click:Connect(function()
				CharacterPageLayout.ScrollWheelInputEnabled = true
				MainFrame.ExecWarning.Visible = false

				OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.AskedForGlobal[IS_GLOBAL] = true

				YesCon:Disconnect()
				NoCon:Disconnect()
				AllowCon:Disconnect()
				CURRENT_PROMPTING = false 

				ApplyToCharacter()
			end)

			NoCon = MainFrame.ExecWarning.Frame.No.MouseButton1Click:Connect(function()
				CharacterPageLayout.ScrollWheelInputEnabled = true
				MainFrame.ExecWarning.Visible = false

				OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.AskedForGlobal[IS_GLOBAL] = false

				YesCon:Disconnect()
				NoCon:Disconnect()
				AllowCon:Disconnect()
				CURRENT_PROMPTING = false 

				ApplyToCharacter()
			end)

			AllowCon = MainFrame.ExecWarning.Frame.DisableWarning.MouseButton1Click:Connect(function()
				CharacterPageLayout.ScrollWheelInputEnabled = true
				MainFrame.ExecWarning.Visible = false

				OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.AskedForGlobal[IS_GLOBAL] = false

				YesCon:Disconnect()
				NoCon:Disconnect()
				AllowCon:Disconnect()
				CURRENT_PROMPTING = false 

				ApplyToCharacter()
			end)	
		end

		
		MainFrame.ExecWarning.Visible = true
	end	
end

-- Apply Guildmates
for i,PotentialMate in pairs(Players:GetPlayers()) do 
	if PotentialMate ~= LocalPlayer then
		local CGuild = PotentialMate:GetAttribute("Guild")

		if PotentialMate:GetAttribute("Guild") == LocalPlayer:GetAttribute("Guild") then
			GuildMates[PotentialMate] = true
		else
			GuildMates[PotentialMate] = nil
		end

		PotentialMate:GetAttributeChangedSignal("Guild"):Connect(function()
			if PotentialMate:GetAttribute("Guild") == LocalPlayer:GetAttribute("Guild") then
				GuildMates[PotentialMate] = true
			else 
				GuildMates[PotentialMate] = nil
			end
		end)

	end
end

----


-- Set up color picker.
local ConfirmContext = nil
local TargetColor = Color3.fromRGB(255,0,0)

local Hue,Sat,Value = 0,1,1

local CanDragHue,CanDragSat = false,false
local DragHue,DragSat = false,false

local LpS,LpH = {Vector2.new(0,0),UDim2.fromOffset(0,0)},{0,0}

local function SetColorPickerPosition(Color:Color3)
	Hue,Sat,Value = Color:ToHSV()

	ColorPicker.Hue.Button.BackgroundColor3 = Color3.fromHSV(Hue,1,1)
	ColorPicker.SaturationValue.ImageLabel.ImageColor3 = Color3.fromHSV(Hue,1,1)
	ColorPicker.SaturationValue.Button.BackgroundColor3 = Color3.fromHSV(Hue,Sat,Value)

	ColorPicker.Confirm.BackgroundColor3 = Color3.fromHSV(Hue,Sat,Value)
	ColorPicker.Cancel.BackgroundColor3 = Color3.fromHSV(Hue,Sat,Value)


	ColorPicker.Hue.Button.Position =  UDim2.new(.587,0,0,160*(1 - Hue))
	ColorPicker.SaturationValue.Button.Position = UDim2.fromOffset(145*(1- Sat),145*(1 - Value))
end

ColorPicker:WaitForChild("Hue"):WaitForChild("Button").MouseEnter:Connect(function(io)
	CanDragHue = true
	CanDragSat = false
end)

ColorPicker.Hue.Button.MouseLeave:Connect(function(io)
	CanDragHue = false
end)

ColorPicker:WaitForChild("SaturationValue"):WaitForChild("Button").MouseEnter:Connect(function(io)
	CanDragSat = true
	CanDragHue = false
end)

ColorPicker.SaturationValue.Button.MouseLeave:Connect(function(io)
	CanDragSat = false
end)

ColorPicker:WaitForChild("Cancel").MouseButton1Click:Connect(function()
	ColorPicker.Visible = false
end)


ColorPicker:WaitForChild("Confirm").MouseButton1Click:Connect(function()
	if ConfirmContext == "Face" then
		local RaceToChange = OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient

		if not OurChoices[CharacterPageLayout.CurrentPage.Name].CustomColors[RaceToChange] then
			OurChoices[CharacterPageLayout.CurrentPage.Name].CustomColors[RaceToChange] = {}
		end

		OurChoices[CharacterPageLayout.CurrentPage.Name].CustomColors[RaceToChange].EyeColor = Color3.fromHSV(Hue,Sat,Value)
	elseif ConfirmContext == "Mark" then
		local RaceToChange = OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient

		if not OurChoices[CharacterPageLayout.CurrentPage.Name].CustomColors[RaceToChange] then
			OurChoices[CharacterPageLayout.CurrentPage.Name].CustomColors[RaceToChange] = {}
		end

		OurChoices[CharacterPageLayout.CurrentPage.Name].CustomColors[RaceToChange].MarkColor = Color3.fromHSV(Hue,Sat,Value)

	end

	ColorPicker.Visible = false
end)

local function flashcopy(orig)
	-- i find it funny
	-- http://lua-users.org/wiki/CopyTable
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			if typeof(orig_key) == "Instance" then
				orig_key = orig_key.Name
			end

			if typeof(orig_value) == "Instance" then
				orig_value = orig_value.Name
			elseif typeof(orig_value) == "Color3" then
				orig_value = orig_value:ToHex()
			end
			copy[flashcopy(orig_key)] = flashcopy(orig_value)
		end
		setmetatable(copy, flashcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local function OutputSettings()
	local Choice_Flash = flashcopy(OurChoices)

	local JSON = game.HttpService:JSONEncode(Choice_Flash)
	if RunService:IsStudio() then
		if script:FindFirstChild(LocalPlayer.UserId.."_"..Slot) then
			script[LocalPlayer.UserId.."_"..Slot]:Destroy()
		end

		local SAVE_FAKE = Instance.new("StringValue",script)
		SAVE_FAKE.Name = LocalPlayer.UserId.."_"..Slot
		SAVE_FAKE.Value = JSON
	else 
		writefile("DeepwokenMorphData/Preferences/"..LocalPlayer.UserId.."_"..Slot..".txt",JSON)
	end
end

local function InputSettings()
	local JSON 

	if RunService:IsStudio() then
		if script:FindFirstChild(LocalPlayer.UserId.."_"..Slot) then
			JSON  = script[LocalPlayer.UserId.."_"..Slot].Value
		else 
			--warn("Missing data..")
			return nil
		end
	else 
		if isfile("DeepwokenMorphData/Preferences/"..LocalPlayer.UserId.."_"..Slot..".txt") then
			JSON = readfile("DeepwokenMorphData/Preferences/"..LocalPlayer.UserId.."_"..Slot..".txt")
		else 
			--	warn("Missing JSON data..")
			return nil
		end
	end

	if JSON then
		local Decoded = game.HttpService:JSONDecode(JSON)	
		OurChoices = Decoded

		for i,v in pairs(OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF) do 
			if Settings[i] == nil and i ~= "LastRace" then
				OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[i] = nil
			end
		end
		
		for i,v in pairs(Settings) do 
			if typeof(v) ~= "boolean" then
				if not OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[i] then
					OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[i] = v
				end
			end
		end
		
		return true
	end
end


RunService.RenderStepped:Connect(function()
	local MouseLocation = UIP:GetMouseLocation()
	if UIP:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		if DragHue == true then
			local Diff = (LpH[1] - MouseLocation.Y)
			local Loc = UDim2.new(.587,0,0,LpH[2] - Diff)

			if Loc.Y.Offset > 160 then
				Loc = UDim2.new(.587,0,0,160)
			elseif Loc.Y.Offset < 0 then
				Loc = UDim2.new(.587,0,0,0)
			end

			Hue = 1 - Loc.Y.Offset/160

			ColorPicker.Hue.Button.BackgroundColor3 = Color3.fromHSV(Hue,1,1)
			ColorPicker.SaturationValue.ImageLabel.ImageColor3 = Color3.fromHSV(Hue,1,1)
			ColorPicker.SaturationValue.Button.BackgroundColor3 = Color3.fromHSV(Hue,Sat,Value)

			ColorPicker.Confirm.BackgroundColor3 = Color3.fromHSV(Hue,Sat,Value)


			ColorPicker.Hue.Button.Position = Loc
		elseif DragSat == true then
			local Diff = LpS[1] - MouseLocation
			local Loc = UDim2.fromOffset(LpS[2].X.Offset - Diff.X,LpS[2].Y.Offset - Diff.Y)

			if Loc.X.Offset > 145 then
				Loc = UDim2.new(0,145,0,Loc.Y.Offset)
			elseif Loc.X.Offset < 0 then
				Loc = UDim2.new(0,0,0,Loc.Y.Offset)
			end

			if Loc.Y.Offset > 145 then
				Loc = UDim2.new(0,Loc.X.Offset,0,145)
			elseif Loc.Y.Offset < 0 then
				Loc = UDim2.new(0,Loc.X.Offset,0,0)
			end

			Value = 1 - (Loc.Y.Offset/145)
			Sat = 1 - (Loc.X.Offset/145)

			ColorPicker.SaturationValue.Button.BackgroundColor3 = Color3.fromHSV(Hue,Sat,Value)
			ColorPicker.SaturationValue.Button.Position = Loc
			ColorPicker.Confirm.BackgroundColor3 = Color3.fromHSV(Hue,Sat,Value)
		end	
	end
end)

UIP.InputBegan:Connect(function(io,gpe)
	if gpe then
		if io.UserInputType == Enum.UserInputType.MouseButton1 then
			if CanDragHue == true and DragSat == false then
				DragHue = true
				LpH = {UIP:GetMouseLocation().Y,ColorPicker.Hue.Button.Position.Y.Offset}
			elseif CanDragSat == true and DragHue == false then
				DragSat = true
				LpS = {UIP:GetMouseLocation(),ColorPicker.SaturationValue.Button.Position}
			end
		end
	end
end)

UIP.InputEnded:Connect(function(io,gpe)
	--	if not gpe then
	if io.UserInputType == Enum.UserInputType.MouseButton1 then

		DragHue = false
		DragSat = false

		TargetColor = Color3.fromHSV(Hue,Sat,Value)
	end
	--	end
end)



-- Set up ui


--
local HasData =  InputSettings()

if RunService:IsStudio() then
	for i,Race in pairs(ReplicatedStorage.CustomRaces:GetChildren()) do 
		LoadRace("Custom",Race)
	end	
else 
	local Files = syn_io_listdir("DeepwokenMorphData/CustomRaces")
	for i,File in pairs(Files) do 
		local LoadedRace = game:GetObjects(getsynasset(File))[1]

		if not LoadedFiles[LoadedRace.Name] and (LoadedRace.Name ~= "You." and LoadedRace.Name ~= "CON_FIG_DEEZ_NUTS_IN_YO_MOUF") then
			LoadedFiles[LoadedRace.Name] = File
			LoadedRace.Parent = script
			LoadRace(
				"Custom",LoadedRace
			)
		else 
			--warn(File.."|Already Loaded!!!\nInvalid Name or somth..")
		end
	end
end
--

for i,v in pairs(DeepRaces:GetChildren()) do 
	LoadRace("InGame",v.Name)
end

LoadRace("You.")

local OrderedEnchantEffects = EnchantEffects:GetChildren()
local OrderedOathEffects = OathEffects:GetChildren()

local OathLabels = {
	ConfigFrames.GlobalAccourtments.ScrollingFrame.NoOathEffect
}

local EnchantLabels = {
	ConfigFrames.GlobalAccourtments.ScrollingFrame.NoEnchant
}

table.sort(OrderedEnchantEffects,function(a,b)
	return a.Name < b.Name
end)

table.sort(OrderedOathEffects,function(a,b)
	return a.Name < b.Name
end)

for i,v in pairs(OrderedOathEffects) do 	
	local OathButton = TemplateButtons.Varient:Clone()
	OathButton.BackgroundColor3 = ((v:IsA("BasePart") and v.Color) or v:GetAttribute("ButtonColor") or Color3.new(.8,.8,.7))
	OathButton.LayoutOrder = 41+i
	OathButton.Text = v.Name
	OathButton.Parent = ConfigFrames.GlobalAccourtments.ScrollingFrame

	OathLabels[#OathLabels+1] = OathButton

	if OurChoices[CharacterPageLayout.CurrentPage.Name].CustomOathFX then
		if OurChoices[CharacterPageLayout.CurrentPage.Name].CustomOathFX == v.Name then
			OathButton.BorderSizePixel =  4
			ConfigFrames.GlobalAccourtments.ScrollingFrame.NoOathEffect.BorderSizePixel = 0
		end
	end

	OathButton.MouseButton1Click:Connect(function()	
		for _,OathLabel in pairs(OathLabels) do 
			if OathLabel == OathButton then
				OathLabel.BorderSizePixel =  4
				OurChoices[CharacterPageLayout.CurrentPage.Name].CustomOathFX = v.Name
			else 
				OathLabel.BorderSizePixel =  0
			end
		end
	end)
end

ConfigFrames.GlobalAccourtments.ScrollingFrame.NoOathEffect.MouseButton1Click:Connect(function()
	for _,OathLabel in pairs(OathLabels) do 
		if OathLabel == ConfigFrames.GlobalAccourtments.ScrollingFrame.NoOathEffect then
			OathLabel.BorderSizePixel =  4
			OurChoices[CharacterPageLayout.CurrentPage.Name].CustomOathFX = nil
		else 
			OathLabel.BorderSizePixel =  0
		end
	end
end)


for i,v in pairs(OrderedEnchantEffects) do 	
	local EnchantButton = TemplateButtons.Varient:Clone()

	if v:GetAttribute("ButtonColor") then
		EnchantButton.BackgroundColor3 = v:GetAttribute("ButtonColor")
	else 
		EnchantButton.BackgroundColor3 = v.Color
	end

	EnchantLabels[#EnchantLabels+1] = EnchantButton

	EnchantButton.LayoutOrder = 4+i
	EnchantButton.Text = v.Name
	EnchantButton.Parent = ConfigFrames.GlobalAccourtments.ScrollingFrame


	if OurChoices[CharacterPageLayout.CurrentPage.Name].CustomEnchantFX then
		if OurChoices[CharacterPageLayout.CurrentPage.Name].CustomEnchantFX  == v.Name then
			EnchantButton.BorderSizePixel =  4
			ConfigFrames.GlobalAccourtments.ScrollingFrame.NoEnchant.BorderSizePixel = 0
		end
	end

	EnchantButton.MouseButton1Click:Connect(function()	
		for _,EnchantLabel in pairs(EnchantLabels) do 
			if EnchantLabel == EnchantButton then
				EnchantLabel.BorderSizePixel =  4
				OurChoices[CharacterPageLayout.CurrentPage.Name].CustomEnchantFX = v.Name
			else 
				EnchantLabel.BorderSizePixel =  0
			end
		end
	end)
end

ConfigFrames.GlobalAccourtments.ScrollingFrame.NoEnchant.MouseButton1Click:Connect(function()
	for _,EnchantLabel in pairs(EnchantLabels) do 
		if EnchantLabel == ConfigFrames.GlobalAccourtments.ScrollingFrame.NoEnchant then
			EnchantLabel.BorderSizePixel =  4
			OurChoices[CharacterPageLayout.CurrentPage.Name].CustomEnchantFX = nil
		else 
			EnchantLabel.BorderSizePixel =  0
		end
	end
end)

if GlobalAssets then
	for i,v in pairs(GlobalAssets:GetChildren()) do 
		local SmallViewport = TemplateButtons:WaitForChild("ConfigViewportFrame"):Clone()
		SmallViewport.Name = v.Name 

		local ThumbnailDummy = 	SmallViewport.WorldModel.ThumbnailDummy
		SmallViewport.Parent = ConfigFrames.GlobalAccourtments.ScrollingFrame.ChoiceTemplate

		local MainViewPortCamera = Instance.new("Camera",SmallViewport)

		MainViewPortCamera.FieldOfView = 20	

		SmallViewport.CurrentCamera = MainViewPortCamera

		if v.Name:len() > 12 then
			SmallViewport.ToolTip.Text = "\""..(v.Name:sub(1,9)).."...\""
		else 
			SmallViewport.ToolTip.Text = "\""..v.Name.."\""
		end

		SmallViewport.Clickable.MouseEnter:Connect(function()
			SmallViewport.ToolTip.Visible = true
		end)

		SmallViewport.Clickable.MouseLeave:Connect(function()
			SmallViewport.ToolTip.Visible = false
		end)

		SmallViewport.Clickable.MouseButton1Click:Connect(function()
			local Enabled = not SmallViewport.Selected.Visible

			if not  OurChoices[CharacterPageLayout.CurrentPage.Name].GlobalOrnaments then
				OurChoices[CharacterPageLayout.CurrentPage.Name].GlobalOrnaments = {}
			end

			warn(i)


			if not Enabled then
				OurChoices[CharacterPageLayout.CurrentPage.Name].GlobalOrnaments[i] = nil
				--	table.remove(OurChoices[CharacterPageLayout.CurrentPage.Name].GlobalOrnaments,v.Name)
			else 
				OurChoices[CharacterPageLayout.CurrentPage.Name].GlobalOrnaments[i] = v.Name
			end

			SmallViewport.Selected.Visible = Enabled

			--	warn(game.HttpService:JSONEncode(OurChoices[CharacterPageLayout.CurrentPage.Name].GlobalOrnaments))
		end)

		local ThumbnailAcc = ApplyDeepwokenAccourtment(v,ThumbnailDummy.Head,OurChoices[CharacterPageLayout.CurrentPage.Name])

		if v:FindFirstChild("CamCF") then
			MainViewPortCamera.FieldOfView = 70
			--warn(v.Name)
			MainViewPortCamera.CFrame = ((v.CamCF:GetAttribute("RefPart") and ThumbnailDummy[v.CamCF:GetAttribute("RefPart")]) or ThumbnailAcc).CFrame * v.CamCF.Value
		else 
			MainViewPortCamera.CFrame = ThumbnailDummy.Head.CFrame * CFrame.new(-2.5,0,-7) * CFrame.Angles(0,math.rad(200),0)
		end


	end

	ConfigFrames.GlobalAccourtments.ScrollingFrame.ChoiceTemplate.Size = UDim2.new(
		.8,0,0,ConfigFrames.GlobalAccourtments.ScrollingFrame.ChoiceTemplate.UIGridLayout.AbsoluteContentSize.Y + 6
	)

	ConfigFrames.GlobalAccourtments.ScrollingFrame.CanvasSize = ConfigFrames.GlobalAccourtments.ScrollingFrame.ChoiceTemplate.Folder.Overlay.Size
end


-- Buttons

local PreviousPage = nil

CharacterPageLayout:GetPropertyChangedSignal("CurrentPage"):Connect(function()
	MainFrame.SelectedRaceName.Text = CharacterPageLayout.CurrentPage.Name
	MainFrame.SelectedDesc.Text = 	RaceConfig[CharacterPageLayout.CurrentPage.Name].Description


	local TextSize = TextService:GetTextSize(
		RaceConfig[CharacterPageLayout.CurrentPage.Name].Description,MainFrame.SelectedDesc.TextSize,MainFrame.SelectedDesc.Font,MainFrame.SelectedDesc.AbsoluteSize
	)

	MainFrame.Quotes.Size = UDim2.fromOffset(TextSize.X,50)

	CharacterPageLayout.CurrentPage.Frame:TweenSize(
		UDim2.new(1.6,0,1,0),Enum.EasingDirection.InOut,Enum.EasingStyle.Quad,.3,true
	)

	Tween(
		CharacterPageLayout.CurrentPage.Frame.Left,{
			ImageTransparency = 0
		},.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0
	)

	Tween(
		CharacterPageLayout.CurrentPage.Frame.Right,{
			ImageTransparency = 0
		},.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0
	)

	if PreviousPage then
		PreviousPage.Frame:TweenSize(
			UDim2.new(.7,0,1,0),Enum.EasingDirection.InOut,Enum.EasingStyle.Quad,.3,true
		)

		Tween(
			PreviousPage.Frame.Left,{
				ImageTransparency = 1
			},.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0
		)

		Tween(
			PreviousPage.Frame.Right,{
				ImageTransparency = 1
			},.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0
		)


		PreviousPage = CharacterPageLayout.CurrentPage
	else 
		PreviousPage = CharacterPageLayout.CurrentPage
	end

end)


ConfigFrames:WaitForChild("Faces"):WaitForChild("ScrollingFrame"):WaitForChild("TitleTemplate"):WaitForChild("CustomColor").MouseButton1Click:Connect(function()
	ConfirmContext = "Face"

	local TempData = OurChoices[CharacterPageLayout.CurrentPage.Name]

	if TempData.CustomColors[TempData.CurrentVarient] and TempData.CustomColors[TempData.CurrentVarient].EyeColor then
		SetColorPickerPosition(TempData.CustomColors[TempData.CurrentVarient].EyeColor)
	else 
		SetColorPickerPosition(OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient.EyeColor.Value)
	end

	ColorPicker.Visible = true
end)

ConfigFrames:WaitForChild("Markings"):WaitForChild("ScrollingFrame"):WaitForChild("TitleTemplate"):WaitForChild("CustomColor").MouseButton1Click:Connect(function()
	ConfirmContext = "Mark"

	local TempData = OurChoices[CharacterPageLayout.CurrentPage.Name]

	if TempData.CustomColors[TempData.CurrentVarient] and TempData.CustomColors[TempData.CurrentVarient].MarkColor then
		SetColorPickerPosition(TempData.CustomColors[TempData.CurrentVarient].MarkColor)
	else 
		SetColorPickerPosition((OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient:FindFirstChild("TattooColor") or OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient.HairColor).Value)
	end

	ColorPicker.Visible = true
end)

MainFrame.Save.MouseButton1Click:Connect(function()
	if CURRENT_PROMPTING == true then
		return
	end

	pcall(
		OutputSettings
	)
end)


MainFrame.Config.MouseButton1Click:Connect(function()
	if CURRENT_PROMPTING == true then
		return
	end

	if CharacterPageLayout.ScrollWheelInputEnabled then
		CharacterPageLayout.ScrollWheelInputEnabled = false

		Tween(
			Gradient.UIGradient,{
				Offset = Vector2.new(0,0)
			},.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0
		)

		ConfigButtons:TweenSize(
			UDim2.new(.35,0,1,-30),Enum.EasingDirection.InOut,Enum.EasingStyle.Quad,.3,true
		)

		if CharacterPageLayout.CurrentPage.Name == "You." then
			ConfigButtons.UserConfig.Visible = true
		else 
			ConfigButtons.UserConfig.Visible = false
		end

		if not RaceConfig[CharacterPageLayout.CurrentPage.Name].Varients then
			ConfigButtons.Varient.Visible = false
		else 
			ConfigButtons.Varient.Visible = true

			for i,v in pairs(ConfigFrames.Varients.ScrollingFrame:GetChildren()) do 
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end

			ConfigFrames.Varients.ScrollingFrame.Title.Text = CharacterPageLayout.CurrentPage.Name.."'s Variants." 

			for i,v in pairs(RaceConfig[CharacterPageLayout.CurrentPage.Name].Varients) do 
				local TextButt = TemplateButtons.Varient:Clone()
				TextButt.BackgroundColor3 = (
					(v.HairColor.Value)
				)
				TextButt.LayoutOrder = ((v:FindFirstChild("VariantID") and v.VariantID.Value) or -2 + #ConfigFrames.Varients.ScrollingFrame:GetChildren() + 1)
				TextButt.Text = i 
				TextButt.Parent = ConfigFrames.Varients.ScrollingFrame
				TextButt.Name = i

				if OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient and OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient == v then
					TextButt.BorderSizePixel = 4
				end

				TextButt.MouseButton1Click:Connect(function()
					--	print(OurChoices[CharacterPageLayout.CurrentPage.Name].Face)
					if OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient  then
						ConfigFrames.Varients.ScrollingFrame[(OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient:FindFirstChild("DefaultVariant") and OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient.DefaultVariant.Value) or OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient.Name].BorderSizePixel = 0				
					end

					TextButt.BorderSizePixel = 4
					OurChoices[CharacterPageLayout.CurrentPage.Name].CurrentVarient = v
				end)
			end

		end


		if not RaceConfig[CharacterPageLayout.CurrentPage.Name].Faces then
			ConfigButtons.Face.Visible = false
		else 

			for i,v in pairs(ConfigFrames.Faces.ScrollingFrame.ChoiceTemplate:GetChildren()) do 
				if v:IsA("ViewportFrame") then
					v:Destroy()
				end
			end

			ConfigButtons.Face.Visible = true
			ConfigFrames.Faces.ScrollingFrame.TitleTemplate.Text = CharacterPageLayout.CurrentPage.Name.."'s Faces." 

			local CVD = RaceConfig[CharacterPageLayout.CurrentPage.Name].Varients[RaceConfig[CharacterPageLayout.CurrentPage.Name].CurrentVarient]

			for i,v in pairs(RaceConfig[CharacterPageLayout.CurrentPage.Name].Faces.Decals) do 

				local SmallViewport = TemplateButtons:WaitForChild("ConfigViewportFrame"):Clone()
				SmallViewport.Name = v.Name 

				if v.Name:len() > 12 then
					SmallViewport.ToolTip.Text = "\""..(v.Name:sub(1,9)).."...\""
				else 
					SmallViewport.ToolTip.Text = "\""..v.Name.."\""
				end

				SmallViewport.Clickable.MouseEnter:Connect(function()
					SmallViewport.ToolTip.Visible = true
				end)

				SmallViewport.Clickable.MouseLeave:Connect(function()
					SmallViewport.ToolTip.Visible = false
				end)

				local ThumbnailDummy = 	SmallViewport.WorldModel.ThumbnailDummy
				SmallViewport.Parent = ConfigFrames.Faces.ScrollingFrame.ChoiceTemplate

				local MainViewPortCamera = Instance.new("Camera",SmallViewport)
				MainViewPortCamera.CFrame = ThumbnailDummy.Head.CFrame * CFrame.new(-2.5,0,-7) * CFrame.Angles(0,math.rad(200),0)
				MainViewPortCamera.FieldOfView = 20	

				if OurChoices[CharacterPageLayout.CurrentPage.Name].Face and OurChoices[CharacterPageLayout.CurrentPage.Name].Face == v then
					SmallViewport.Selected.Visible = true
				end

				SmallViewport.Clickable.MouseButton1Click:Connect(function()
					--	print(OurChoices[CharacterPageLayout.CurrentPage.Name].Face)
					if OurChoices[CharacterPageLayout.CurrentPage.Name].Face  then
						ConfigFrames.Faces.ScrollingFrame.ChoiceTemplate[OurChoices[CharacterPageLayout.CurrentPage.Name].Face.Name].Selected.Visible = false				
					end

					SmallViewport.Selected.Visible = true
					OurChoices[CharacterPageLayout.CurrentPage.Name].Face = v
				end)

				SmallViewport.CurrentCamera = MainViewPortCamera

				ApplyFace(v,ThumbnailDummy.Faces,CVD.EyeColor.Value,((CVD:FindFirstChild("ScleraColor") and CVD.ScleraColor.Value) or Color3.new(1,1,1) ))

			end

			ConfigFrames.Faces.ScrollingFrame.ChoiceTemplate.Folder.Overlay.Size = UDim2.new(
				1,0,0,ConfigFrames.Faces.ScrollingFrame.ChoiceTemplate.UIGridLayout.AbsoluteContentSize.Y + 12
			)

			ConfigFrames.Faces.ScrollingFrame.CanvasSize = ConfigFrames.Faces.ScrollingFrame.ChoiceTemplate.Folder.Overlay.Size

			--ConfigFrames.Accourtments.Visible = true

		end

		if not RaceConfig[CharacterPageLayout.CurrentPage.Name].Ornaments then
			ConfigButtons.Accourtment.Visible = false
		else 

			for i,v in pairs(ConfigFrames.Accourtments.ScrollingFrame.ChoiceTemplate:GetChildren()) do 
				if v:IsA("ViewportFrame") then
					v:Destroy()
				end
			end

			ConfigButtons.Accourtment.Visible = true
			ConfigFrames.Accourtments.ScrollingFrame.TitleTemplate.Text = CharacterPageLayout.CurrentPage.Name.."'s Ornaments." 


			for i,v in pairs(RaceConfig[CharacterPageLayout.CurrentPage.Name].Ornaments) do 

				local SmallViewport = TemplateButtons:WaitForChild("ConfigViewportFrame"):Clone()
				SmallViewport.Name = v.Name 

				if v.Name:len() > 12 then
					SmallViewport.ToolTip.Text = "\""..(v.Name:sub(1,9)).."...\""
				else 
					SmallViewport.ToolTip.Text = "\""..v.Name.."\""
				end

				SmallViewport.Clickable.MouseEnter:Connect(function()
					SmallViewport.ToolTip.Visible = true
				end)

				SmallViewport.Clickable.MouseLeave:Connect(function()
					SmallViewport.ToolTip.Visible = false
				end)

				local ThumbnailDummy = 	SmallViewport.WorldModel.ThumbnailDummy
				SmallViewport.Parent = ConfigFrames.Accourtments.ScrollingFrame.ChoiceTemplate

				local MainViewPortCamera = Instance.new("Camera",SmallViewport)


				MainViewPortCamera.FieldOfView = 20	

				SmallViewport.CurrentCamera = MainViewPortCamera

				if OurChoices[CharacterPageLayout.CurrentPage.Name].Ornaments[v] then
					SmallViewport.Selected.Visible = true
				end

				SmallViewport.Clickable.MouseButton1Click:Connect(function()
					local Suffixed = string.sub(v.Name,1,string.len(v.Name) - 1)
					local Ourselves = true
					--warn(Suffixed)
					for i,x in pairs(OurChoices[CharacterPageLayout.CurrentPage.Name].Ornaments) do 
						--warn(i.Name)
						if i == v then
							Ourselves = false
						end

						if string.find(i.Name,Suffixed) then
							OurChoices[CharacterPageLayout.CurrentPage.Name].Ornaments[i] = nil
							ConfigFrames.Accourtments.ScrollingFrame.ChoiceTemplate[i.Name].Selected.Visible = false
						end
					end

					if Ourselves then
						OurChoices[CharacterPageLayout.CurrentPage.Name].Ornaments[v] = true
						SmallViewport.Selected.Visible = true
					end

				end)

				local ThumbnailAcc = ApplyDeepwokenAccourtment(v,ThumbnailDummy.Head,OurChoices[CharacterPageLayout.CurrentPage.Name])

				if v:FindFirstChild("CamCF") then
					MainViewPortCamera.FieldOfView = 70
					--warn(v.Name)
					MainViewPortCamera.CFrame = ((v.CamCF:GetAttribute("RefPart") and ThumbnailDummy[v.CamCF:GetAttribute("RefPart")]) or ThumbnailAcc).CFrame * v.CamCF.Value
				else 
					MainViewPortCamera.CFrame = ThumbnailDummy.Head.CFrame * CFrame.new(-2.5,0,-7) * CFrame.Angles(0,math.rad(200),0)
				end

			end

			ConfigFrames.Accourtments.ScrollingFrame.ChoiceTemplate.Folder.Overlay.Size = UDim2.new(
				1,0,0,ConfigFrames.Accourtments.ScrollingFrame.ChoiceTemplate.UIGridLayout.AbsoluteContentSize.Y + 12
			)

			ConfigFrames.Accourtments.ScrollingFrame.CanvasSize = ConfigFrames.Accourtments.ScrollingFrame.ChoiceTemplate.Folder.Overlay.Size

			--ConfigFrames.Accourtments.Visible = true

		end

		if not RaceConfig[CharacterPageLayout.CurrentPage.Name].FacialMarkings then
			ConfigButtons.Marking.Visible = false
		else 

			for i,v in pairs(ConfigFrames.Markings.ScrollingFrame.ChoiceTemplate:GetChildren()) do 
				if v:IsA("ViewportFrame") then
					v:Destroy()
				end
			end

			ConfigButtons.Marking.Visible = true
			ConfigFrames.Markings.ScrollingFrame.TitleTemplate.Text = CharacterPageLayout.CurrentPage.Name.."'s Marks." 

			local CVD = RaceConfig[CharacterPageLayout.CurrentPage.Name].Varients[RaceConfig[CharacterPageLayout.CurrentPage.Name].CurrentVarient]

			for i,v in pairs(RaceConfig[CharacterPageLayout.CurrentPage.Name].FacialMarkings) do 

				local SmallViewport = TemplateButtons:WaitForChild("ConfigViewportFrame"):Clone()
				SmallViewport.Name = v.Name 

				if v.Name:len() > 12 then
					SmallViewport.ToolTip.Text = "\""..(v.Name:sub(1,9)).."...\""
				else 
					SmallViewport.ToolTip.Text = "\""..v.Name.."\""
				end

				SmallViewport.Clickable.MouseEnter:Connect(function()
					SmallViewport.ToolTip.Visible = true
				end)

				SmallViewport.Clickable.MouseLeave:Connect(function()
					SmallViewport.ToolTip.Visible = false
				end)

				local ThumbnailDummy = 	SmallViewport.WorldModel.ThumbnailDummy
				SmallViewport.Parent = ConfigFrames.Markings.ScrollingFrame.ChoiceTemplate

				local MainViewPortCamera = Instance.new("Camera",SmallViewport)
				MainViewPortCamera.CFrame = ThumbnailDummy.Head.CFrame * CFrame.new(-2.5,0,-7) * CFrame.Angles(0,math.rad(200),0)
				MainViewPortCamera.FieldOfView = 20	

				if OurChoices[CharacterPageLayout.CurrentPage.Name].FacialMarkings and OurChoices[CharacterPageLayout.CurrentPage.Name].FacialMarkings == v then
					SmallViewport.Selected.Visible = true
				end

				SmallViewport.Clickable.MouseButton1Click:Connect(function()
					--	print(OurChoices[CharacterPageLayout.CurrentPage.Name].Face)
					if OurChoices[CharacterPageLayout.CurrentPage.Name].FacialMarkings  then
						ConfigFrames.Markings.ScrollingFrame.ChoiceTemplate[OurChoices[CharacterPageLayout.CurrentPage.Name].FacialMarkings.Name].Selected.Visible = false				
					end

					SmallViewport.Selected.Visible = true
					OurChoices[CharacterPageLayout.CurrentPage.Name].FacialMarkings = v
				end)

				SmallViewport.CurrentCamera = MainViewPortCamera

				ApplyFace(v,ThumbnailDummy.Faces,(CVD:FindFirstChild("TattooColor") or {Value = CVD.HairColor.Value}).Value)

			end

			ConfigFrames.Markings.ScrollingFrame.ChoiceTemplate.Folder.Overlay.Size = UDim2.new(
				1,0,0,ConfigFrames.Markings.ScrollingFrame.ChoiceTemplate.UIGridLayout.AbsoluteContentSize.Y + 12
			)

			ConfigFrames.Markings.ScrollingFrame.CanvasSize = ConfigFrames.Markings.ScrollingFrame.ChoiceTemplate.Folder.Overlay.Size

			--ConfigFrames.Accourtments.Visible = true

		end
	end
end)

ConfigButtons.UserConfig.MouseButton1Click:Connect(function()
	if not CharacterPageLayout.ScrollWheelInputEnabled then
		ConfigFrames.UserConfig.Visible = not ConfigFrames.UserConfig.Visible

		ConfigFrames.Settings.Visible = false
		ConfigFrames.Accourtments.Visible = false
		ConfigFrames.Faces.Visible = false
		ConfigFrames.Varients.Visible = false
		ConfigFrames.Markings.Visible = false
		MainFrame.ColorPicker.Visible = false
	end
end)

ConfigButtons.GlobalOrnaments.MouseButton1Click:Connect(function()
	if not CharacterPageLayout.ScrollWheelInputEnabled then

		local DeezNutsAreVisibleLMA = OurChoices[CharacterPageLayout.CurrentPage.Name].GlobalOrnaments
		

		if DeezNutsAreVisibleLMA then
			for i,v in pairs(ConfigFrames.GlobalAccourtments.ScrollingFrame.ChoiceTemplate:GetChildren()) do 
				if v:IsA("ViewportFrame") then
					v.Selected.Visible = tablefind(DeezNutsAreVisibleLMA,v.Name) ~= nil
				end
			end	
		else 
			warn("why.")
			for i,v in pairs(ConfigFrames.GlobalAccourtments.ScrollingFrame.ChoiceTemplate:GetChildren()) do 
				if v:IsA("ViewportFrame") then
					v.Selected.Visible = false
				end
			end	
		end

		if OurChoices[CharacterPageLayout.CurrentPage.Name].CustomEnchantFX == nil then
			for _,EnchantLabel in pairs(EnchantLabels) do 
				if EnchantLabel.Text == "None." then
					EnchantLabel.BorderSizePixel =  4
				else 
					EnchantLabel.BorderSizePixel =  0
				end
			end
		else 
			for _,EnchantLabel in pairs(EnchantLabels) do 
				if EnchantLabel.Text == OurChoices[CharacterPageLayout.CurrentPage.Name].CustomEnchantFX then
					EnchantLabel.BorderSizePixel =  4
				else 
					EnchantLabel.BorderSizePixel =  0
				end
			end	
		end

		if OurChoices[CharacterPageLayout.CurrentPage.Name].CustomOathFX == nil then
			for _,OathLabel in pairs(OathLabels) do 
				if OathLabel.Text == "None." then
					OathLabel.BorderSizePixel =  4
				else 
					OathLabel.BorderSizePixel =  0
				end
			end
		else 
			for _,OathLabel in pairs(OathLabels) do 
				if OathLabel.Text == OurChoices[CharacterPageLayout.CurrentPage.Name].CustomOathFX
				then
					OathLabel.BorderSizePixel =  4
				else 
					OathLabel.BorderSizePixel =  0
				end
			end	
		end




		ConfigFrames.GlobalAccourtments.Visible = not ConfigFrames.GlobalAccourtments.Visible

		ConfigFrames.UserConfig.Visible = false
		ConfigFrames.Settings.Visible = false
		ConfigFrames.Accourtments.Visible = false
		ConfigFrames.Faces.Visible = false
		ConfigFrames.Varients.Visible = false
		ConfigFrames.Markings.Visible = false
		MainFrame.ColorPicker.Visible = false
	end
end)

ConfigButtons.Settings.MouseButton1Click:Connect(function()
	if not CharacterPageLayout.ScrollWheelInputEnabled then
		for i,v in pairs(OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF) do 
			if typeof(v) == "boolean" then
				if ConfigFrames.Settings.ScrollingFrame:FindFirstChild(i) then
					ConfigFrames.Settings.ScrollingFrame[i].Tick.TextLabel.Visible = v
				else 
					local NS = TemplateButtons.TemplateSetting:Clone()
					NS.Name = i 
					NS.Toggle.Text = string.gsub(i,"(%l)(%u)", "%1 %2")
					NS.Tick.TextLabel.Visible = v 
					NS.Parent = ConfigFrames.Settings	.ScrollingFrame

					NS.Toggle.MouseButton1Click:Connect(function()
						OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[i] = not OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[i]
						NS.Tick.TextLabel.Visible = OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[i]
					end)

				end
			end
		end

		ConfigFrames.Settings.Visible = not ConfigFrames.Settings.Visible

		ConfigFrames.Accourtments.Visible = false
		ConfigFrames.Faces.Visible = false
		ConfigFrames.Varients.Visible = false
		ConfigFrames.Markings.Visible = false
		MainFrame.ColorPicker.Visible = false
		ConfigFrames.GlobalAccourtments.Visible = false
		ConfigFrames.UserConfig.Visible = false


	end
end)

for i,v in pairs(ConfigFrames.Settings.ScrollingFrame:GetChildren()) do 
	if v:IsA("Frame") and OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[v.Name] ~= nil then
		v.Toggle.MouseButton1Click:Connect(function()
			OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[v.Name] = not OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[v.Name]
			v.Tick.TextLabel.Visible = OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF[v.Name]
		end)
	end
end

ConfigButtons.Close.MouseButton1Click:Connect(function()
	if not CharacterPageLayout.ScrollWheelInputEnabled then
		ConfigFrames.Accourtments.Visible = false
		ConfigFrames.Faces.Visible = false
		ConfigFrames.Varients.Visible = false
		ConfigFrames.Markings.Visible = false
		ConfigFrames.Settings.Visible = false
		MainFrame.ColorPicker.Visible = false
		ConfigFrames.Settings.Visible = false
		ConfigFrames.GlobalAccourtments.Visible = false
		ConfigFrames.UserConfig.Visible = false

		MainFrame.CreditF.Visible = false

		Tween(
			Gradient.UIGradient,{
				Offset = Vector2.new(1,0)
			},.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0
		)

		ConfigButtons:TweenSize(
			UDim2.new(0,0,1,-30),Enum.EasingDirection.InOut,Enum.EasingStyle.Quad,.3,true,function()
				CharacterPageLayout.ScrollWheelInputEnabled = true
			end
		)
	end
end)

ConfigButtons.Face.MouseButton1Click:Connect(function()
	if not CharacterPageLayout.ScrollWheelInputEnabled then
		ConfigFrames.Faces.Visible = not ConfigFrames.Faces.Visible
	end

	ConfigFrames.Accourtments.Visible = false
	ConfigFrames.Varients.Visible = false
	ConfigFrames.Markings.Visible = false
	MainFrame.ColorPicker.Visible = false
	ConfigFrames.Settings.Visible = false
	ConfigFrames.GlobalAccourtments.Visible = false
	ConfigFrames.UserConfig.Visible = false

end)

ConfigButtons.Accourtment.MouseButton1Click:Connect(function()
	if not CharacterPageLayout.ScrollWheelInputEnabled then
		ConfigFrames.Accourtments.Visible = not ConfigFrames.Accourtments.Visible
	end

	ConfigFrames.Faces.Visible = false
	ConfigFrames.Varients.Visible = false
	ConfigFrames.Markings.Visible = false
	MainFrame.ColorPicker.Visible = false
	ConfigFrames.Settings.Visible = false
	ConfigFrames.GlobalAccourtments.Visible = false
	ConfigFrames.UserConfig.Visible = false

end)

ConfigButtons.Varient.MouseButton1Click:Connect(function()

	if not CharacterPageLayout.ScrollWheelInputEnabled then
		ConfigFrames.Varients.Visible = not ConfigFrames.Varients.Visible
	end

	ConfigFrames.Faces.Visible = false
	ConfigFrames.Accourtments.Visible = false
	ConfigFrames.Markings.Visible = false
	ConfigFrames.Markings.Visible = false
	MainFrame.ColorPicker.Visible = false
	ConfigFrames.Settings.Visible = false
	ConfigFrames.GlobalAccourtments.Visible = false
	ConfigFrames.UserConfig.Visible = false

end)

ConfigButtons.Marking.MouseButton1Click:Connect(function()

	if not CharacterPageLayout.ScrollWheelInputEnabled then
		ConfigFrames.Markings.Visible = not ConfigFrames.Markings.Visible
	end

	ConfigFrames.Faces.Visible = false
	ConfigFrames.Accourtments.Visible = false
	ConfigFrames.Varients.Visible = false
	MainFrame.ColorPicker.Visible = false
	ConfigFrames.Settings.Visible = false
	ConfigFrames.GlobalAccourtments.Visible = false
	ConfigFrames.UserConfig.Visible = false

end)

MainFrame:WaitForChild("Apply").MouseButton1Click:Connect(function()
	if CURRENT_PROMPTING == true then
		return
	end

	OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.LastRace = CharacterPageLayout.CurrentPage.Name

	local LastRace = CharacterPageLayout.CurrentPage.Name
	local LastRaceConfig = OurChoices[LastRace]
	local LastRaceData = RaceConfig[LastRace]

	if LastRaceData then
		if LastRaceData.Ornaments and LastRaceConfig.Ornaments then	
			for Ornament,_ in pairs(LastRaceConfig.Ornaments) do 
				if Ornament:FindFirstChildOfClass("LocalScript") then
					if AskedForRace[LastRace] == nil and LastRaceConfig.ScriptConsent == nil then
						MainFrame.Visible = true
						PromptScriptPermissions(LastRace)
						return
					end
				end
			end
		end
		
		if LastRaceConfig.GlobalOrnaments then	
			for _,Name in pairs(LastRaceConfig.GlobalOrnaments) do 
				local Ornament = GlobalAssets:FindFirstChild(Name)

				if Ornament and Ornament:FindFirstChildOfClass("LocalScript") then
					if OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.AskedForGlobal[Name] == nil then
						MainFrame.Visible = true
						PromptScriptPermissions(LastRace,Name)
						return
					end
				end
			end
		end
		
	end 

	if not (string.gsub(MainFrame.CreditF.Credit.Text,"[%l%p%s]","") == "15HTFHFOO" and string.gsub(MainFrame.Credit.ContentText,"[%l%p%s]",""))  then return end
	ApplyToCharacter(nil,nil,true)

	MainFrame.Visible = false

	ConfigFrames.Faces.Visible = false
	ConfigFrames.Accourtments.Visible = false
	ConfigFrames.Varients.Visible = false
	ConfigFrames.Markings.Visible = false

	MainFrame.ColorPicker.Visible = false
	ConfigFrames.Settings.Visible = false
	ConfigFrames.GlobalAccourtments.Visible = false
	ConfigFrames.UserConfig.Visible = false


	MainFrame.CreditF.Visible = false

	Gradient.UIGradient.Offset = Vector2.new(1,0)
	ConfigButtons.Size = UDim2.new(0,0,1,-30)

	CharacterPageLayout.ScrollWheelInputEnabled = true
end)

MainFrame:WaitForChild("Credit").ClickMe.MouseButton1Click:Connect(function()
	MainFrame.CreditF.Visible = not MainFrame.CreditF.Visible 
end)

MainFrame:WaitForChild("CreditF").Kofi.MouseButton1Click:Connect(function()
	if not RunService:IsStudio() then
		setclipboard("https://ko-fi.com/ukiyodev")
	end

	MainFrame.CreditF.PaddinglessBehavoir.Copied.TextStrokeTransparency = 0
	MainFrame.CreditF.PaddinglessBehavoir.Copied.TextTransparency = 0

	wait()

	MainFrame.CreditF.PaddinglessBehavoir.Copied.Visible = true

	Tween(MainFrame.CreditF.PaddinglessBehavoir.Copied,{
		TextStrokeTransparency = 1,TextTransparency = 1
	},.7,Enum.EasingStyle.Circular,Enum.EasingDirection.In,0,false,0).Completed:Connect(function()

	end)

end)


MainFrame.CreditF.Twitter.MouseButton1Click:Connect(function()
	if not RunService:IsStudio() then
		setclipboard("https://twitter.com/Geno_Dev")
	end

	MainFrame.CreditF.PaddinglessBehavoir.Copied.TextStrokeTransparency = 0
	MainFrame.CreditF.PaddinglessBehavoir.Copied.TextTransparency = 0

	wait()

	MainFrame.CreditF.PaddinglessBehavoir.Copied.Visible = true

	Tween(MainFrame.CreditF.PaddinglessBehavoir.Copied,{
		TextStrokeTransparency = 1,TextTransparency = 1
	},.7,Enum.EasingStyle.Circular,Enum.EasingDirection.In,0,false,0).Completed:Connect(function()

	end)
end)
--

ConfigFrames.UserConfig.ScrollingFrame.TextBox.FocusLost:Connect(function()
	local FormattedName = string.gsub(ConfigFrames.UserConfig.ScrollingFrame.TextBox.Text,"[ \n]","")
	local UserID = GetUserId(FormattedName)
	if UserID then
		OurChoices["You."].Target_Id = UserID
		RaceConfig["You."].Description = GetUserDescription(UserID)		
		CharacterMain["You."].ImageLabel.Image = "rbxthumb://type=AvatarHeadShot&id="..UserID.."&w=150&h=150"
		MainFrame.SelectedDesc.Text = 	RaceConfig["You."].Description

		local TextSize = TextService:GetTextSize(
			RaceConfig["You."].Description,MainFrame.SelectedDesc.TextSize,MainFrame.SelectedDesc.Font,MainFrame.SelectedDesc.AbsoluteSize
		)

		MainFrame.Quotes.Size = UDim2.fromOffset(TextSize.X,50)


		RefreshOutfits()
	else 
		ConfigFrames.UserConfig.ScrollingFrame.TextBox.Text = "Invalid name.."
		--	RefreshOutfits()
	end
end)

UIP.InputBegan:Connect(function(io,gpe)
	if not gpe then
		if UIP:IsKeyDown(Enum.KeyCode.LeftControl) and io.KeyCode == Enum.KeyCode.LeftAlt then
			if not MainFrame.Visible then
				MainFrame.Visible = true
			else 
				-- Close function
				MainFrame.Visible = false

				ConfigFrames.Faces.Visible = false
				ConfigFrames.Accourtments.Visible = false
				ConfigFrames.Varients.Visible = false
				ConfigFrames.Markings.Visible = false

				MainFrame.ColorPicker.Visible = false
				ConfigFrames.Settings.Visible = false

				MainFrame.CreditF.Visible = false
				ConfigFrames.GlobalAccourtments.Visible = false
				ConfigFrames.UserConfig.Visible = false


				Gradient.UIGradient.Offset = Vector2.new(1,0)
				ConfigButtons.Size = UDim2.new(0,0,1,-30)

				CharacterPageLayout.ScrollWheelInputEnabled = true

			end -- basic toggle
		end
	end
end)


MainFrame.Visible = false
MainGui.Parent = PlayerGui


if HasData then
	if OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.LastRace then
		local LastRace = OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.LastRace

		local LastRaceConfig = OurChoices[LastRace]
		local LastRaceData = RaceConfig[LastRace]

		CharacterPageLayout:JumpTo(
			CharacterMain[LastRace]
		)

		if LastRaceData then
			if LastRaceData.Ornaments and LastRaceConfig.Ornaments then	
				for Ornament,_ in pairs(LastRaceConfig.Ornaments) do 
					if Ornament:FindFirstChildOfClass("LocalScript") then
						if not LastRaceConfig.ScriptConsent then
							MainFrame.Visible = true
							PromptScriptPermissions(LastRace)
							return
						end
					end
				end
			end
			
			if LastRaceConfig.GlobalOrnaments then	
				for _,Name in pairs(LastRaceConfig.GlobalOrnaments) do 
					local Ornament = GlobalAssets:FindFirstChild(Name)
					
					if Ornament and Ornament:FindFirstChildOfClass("LocalScript") then
						if OurChoices.CON_FIG_DEEZ_NUTS_IN_YO_MOUF.AskedForGlobal[Name] == nil then
							MainFrame.Visible = true
							PromptScriptPermissions(LastRace,Name)
							return
						end
					end
				end
			end
		end


		ApplyToCharacter()
	else 
		CharacterPageLayout:JumpTo(
			CharacterMain.Adret
		)
	end																										
end
