# DeepwokenRaceMorpher
Made by Ukiyo, all credit to Ukiyo 

# Donate to Ukiyos KoFi (original creator)
https://t.co/H7aNcgS7ST | 
https://discord.gg/f8rsP5gUBg


# SYNAPSE X ONLY + How to set it up

```txt
How to set Up

Download the files ( click the green code buttona dn click downlaod as zip )
create a folder called DeepwokenMorphData in your Synapse X Workspace folder
drag and drop the files that you just downloaded inside the new folder
execute the script
```

# keybinds are LeftCtrl + LeftAlt
To open hold LeftCtrl and click LeftAlt
```LUA
loadstring(game:HttpGet("https://raw.githubusercontent.com/AzurasDev/DeepwokenRaceMorpher/main/RaceMorphMenu.lua"))()
```

# Update Log
 + Added More Races
 + Added More Ornaments
 + Added More Enchants

# Documentation

-- Custom Race Documentation
(Best to look at existing custom races, since theyre set up the same way.)

-- Sections : 
   -- Basic Structure
-- Setting up textures.
-- Using Internal Deep Decals.
   -- Ornaments
   -- Race Based Coloring.
-- Race Data itself.

-- [[Basic Structure]]
The race folder will contain everything that you want to add that is
external in a sense, not all of it is required, the only folder being
"RaceData" (Mentioned below)

The Hierchy of a RaceData folder should look something like this.
(where --[ is a folder.)
--[RaceName] --[ Faces]
	 --[ Markings ]
	 --[ Ornaments]
	 --[ RaceData ]

Any folder that isint needed can be left empty, aslong as it itself is made inside the main folder.

-- [[Setting up textures]]
For any form of texture, face or marking, it needs to be a decal offset with the race name
in mind, like example "MyRace", followed by any suffix, this will allow the code to consider
every decal as seperate, the names dont need to be specifically anything, aslong as their prefixed
by the racename.

if you want to allow for coloring, you must assume that the decal itself will be colorized in game by the code, so
every texture should be white, unless you want it specifically otherwise.

Markings themsevles will be colored by the current varients 'TattooColor' value, whilist Faces will use the 'EyeColor'
value. 

-- [[Using Internal Deep Decals.]]
If either the face, or making folder are left empty, the code will use the default list of faces that deepwoken uses,
(These are used on alot of races actually.)

Otherwise, for faces, every decal itself is the eyes, rather then the whole image, if you want to use several decals, put the decal that you have in mind for the eyes first, then parent every other decal inside it. (These will not be colorized), Otherwise, if you want to use deepwokens in built sclera, put a folder inside
the decal with the names ShapeA,ShapeB or ShapeC. (Image id's for reference : 7112663433,7112661833,7369678555), Sclera will be colored by
the current varients 'ScleraColor', or left white. Both arent a requirement, but are present if wanted.

-- [[ Ornaments ]]
This is one of the tricker bits, as there is several ways to set ornaments.

Ornaments can be consiered as either a model or a part. A model will be 1 object that will allow you to use every part as, well, part of the same ornaments.

As for parts, any of their descendants will not be touched.

Part's can have objects inside of them that will allow you to tap into the current race/varient's color information and copy it,if any object has the following names, then the part will be colorized :

EyeColor,SkinColor,TattooColor,HairColor,ScleraColor,CustomColor1,CustomColor2,CustomColor3.

By default, parts will weld too the head, with no offset at all.
To change where the part will weld, Add an attribute too the part called "Part0", with the value being a string with the part that you want to weld
toos name.

To offset a part, have an attachment inside of the part that goes by any name, the attachments cframe will count as its offset. (Picture it like an accessory.)
the easiest way to set this up is to set the worldcframe equal too a dummy that you put the item on.

While not required, you can give ornaments custom camera angles for thumbnails, to do so, add a CFrameValue inside the ornament with the name, 'CamCF'. The 
value of this object will be the offset itself. the offset will be applied from either its own cframe, or, if given, an attribute called 'RefPart' with the part name that you want from the character's cframe. (The formula being, Camera.CFrame = (RefPart or self).CFrame * Offset.)

-- [[ Race Data Itself.]]
Ok, last but not least, the race data folder.
the easiest way to set this up would be to copy an existing race's folder, however. at minimum, it requires the following : 

A String value with your races description, called, 'Desc'.
A Color3 value with your races eye color , skin color and hair color, called 'EyeColor' , 'SkinColor' and 'HairColor'
And, another String value called 'DefaultVarient' with your varient name in mind.

To add varients, add a folder inside the RaceData folder that copies the above objects, with the varient name that you want as the folders name.

# game if youre retarded
https://www.roblox.com/games/4111023553/Deepwoken-Verse-2
