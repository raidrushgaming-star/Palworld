local Utils = require("Core.Utils")

local GiveModule = {}

local GarbageCollect = Utils.CollectGarbage
local FindFirstOf = Utils.FindFirstOf
local ipairs = Utils.ipairs
local FName = Utils.FName
local canPressKey = Utils.CreateKeyedChecker(Utils.KEY_DEBOUNCE)
local safeCall = Utils.safeCall
local isValidUObject = Utils.isValidUObject
local ExecuteWithDelay = Utils.ExecuteWithDelay
local Key = Utils.Key
local pcall = Utils.pcall
local rawget = Utils.rawget
local PLAYER_STATE = "PalPlayerState"
local PLAYER_INVENTORY = "PalPlayerInventoryData"
local keybindRegistered = false

local listDefinitions = {
    Materials = function()
        return {
            "Wood",
            "Wood_Fine",
            "Wood_WorldTree",
            "Fiber",
            "Stone",
            "Pal_crystal_S",
            "CopperOre",
            "Coal",
            "Sulfur",
            "Quartz",
            "CrudeOil",
            "Chromium",
            "NightStone",
            "RainbowCrystal",
            "ManganeseOre",
            "MeteorDrop",
            "SkyIslandOre",
            "WorldTreeOre",
            "Wool",
            "Leather",
            "Bone",
            "Horn",
            "ElectricOrgan",
            "Venom",
            "FireOrgan",
            "IceOrgan",
            "PalFluid",
            "PalOil",
            "PalDarkParts",
            "Wood_Ancient",
            "Lava_Ancient",
            "BeastBone_Ancient",
            "WorldTreeRelic_01",
            "WorldTreeRelic_02",
            "WorldTreeRelic_03",
            "WorldTreeRelic_04",
            "WorldTreeRelic_05",
            "WorldTreeHolyWater",
            "PalItem_ColorfulBird",
            "PalItem_PlantSlime",
            "PalItem_CaptainPenguin",
            "PalItem_CatMage",
            "PalItem_PinkRabbit",
            "PalItem_MopBaby",
            "PalItem_NegativeOctopus",
            "PalItem_RaijinDaughter",
            "PalItem_LizardMan",
            "UniqueMaterial_FlowerPrince",
            "UniqueMaterial_Mothman",
            "AncientParts3",
            "PalCrystal_Ex",
            "AncientParts2",
            "PredatorCrystal",
            "Cloth",
            "Cloth2",
            "Processed_Wood",
            "HighGrade_Processed_Wood",
            "MachineParts",
            "Gunpowder2",
            "MachineParts2",
            "Polymer",
            "Cement",
            "CarbonFiber",
            "Bio_Coolant",
            "Corrosive_Solvent",
            "Bio_Battery",
            "Thermal_Core",
            "Computer",
            "AIcore",
            "CopperIngot",
            "IronIngot",
            "SteelIngot",
            "Plastic",
            "StainlessSteel",
            "ManganeseIngot",
            "SkyislandIngot",
            "WorldTreeIngot",
            "YakushimaIngot001",
            "WhaleWhistleFragment_01",
            "WhaleWhistleFragment_02",
            "WhaleWhistleFragment_03",
            "WhaleWhistleFragment_04",
            "Poppy",
            "CaveMushroom",
            "Mushroom",
            "PoisonMushroom",
        }
    end,
    Consumables = function()
        return {
            "BountyProof_1",
            "BattleTicket",
            "DogCoin",
            "Money",
            "Potion_Extreme",
            "PalSphere_Ancient_2",
            "BeamLauncherBullet",
            "WingGlider_Fuel",
            "TreasureBoxKey03",
            "TreasureBoxKey02",
            "TreasureBoxKey01",
            "AncientTechnologyBook_G1",
            "TechnologyBook_G3",
            "LvUP_01",
            "PalRevive",
            "RepairKit",
            "Cake",
            "Cake03",
            "Cake04",
            "Cake05",
            "Cake02",
            "BerrySeeds",
            "WheatSeeds",
            "TomatoSeeds",
            "LettuceSeeds",
            "PotatoSeeds",
            "CarrotSeeds",
            "OnionSeeds",
        }
    end,
    Slabs = function()
        return {
            "PalSummon_NightLady",
            "PalSummon_NightLady_Dark",
            "PalSummon_KingBahamut_Dragon",
            "PalSummon_DarkMechaDragon",
            "PalSummon_YakushimaBoss002",
            "PalSummon_LegendDeer",
            "PalSummon_NightLady_Dark_2",
            "PalSummon_KingBahamut_Dragon_2",
            "PalSummon_DarkMechaDragon_2",
            "PalSummon_YakushimaBoss002_2",
            "PalSummon_LegendDeer_2",
        }
    end,
    Blueprints = function()
        return {
            "Blueprint_Hunter_GangFlag",
            "Blueprint_LilyQueenStatue",
            "Blueprint_ConservationGroupBannerA",
            "Blueprint_ConservationGroupBannerB",
            "Blueprint_Wire_Fence",
            "Blueprint_WoodenBarricade",
            "Blueprint_WallTorch02",
            "Blueprint_FireStand",
            "Blueprint_CandleStand",
            "Blueprint_LanternTop",
            "Blueprint_Shrine_Lantern",
            "Blueprint_GuardianDogStatue",
            "Blueprint_SF_Desk",
            "Blueprint_SF_Chair",
            "Blueprint_YakushimaBoss002_Relic",
            "Blueprint_Bat3_5",
            "Blueprint_Spear_ForestBoss_5",
            "Blueprint_Spear_ForestBoss2_5",
            "Blueprint_Sword_5",
            "Blueprint_Katana_5",
            "Blueprint_BeamSword_5",
            "Blueprint_SkyBeamSword_5",
            "Blueprint_WeakerBow_5",
            "Blueprint_BowGun_5",
            "Blueprint_CompoundBow_5",
            "Blueprint_SFBow_5",
            "Blueprint_SkyBow_5",
            "Blueprint_MakeshiftHandgun_5",
            "Blueprint_HandGun_Default_5",
            "Blueprint_OldRevolver_5",
            "Blueprint_MakeshiftShotgun_5",
            "Blueprint_DoubleBarrelShotgun_5",
            "Blueprint_PumpActionShotgun_5",
            "Blueprint_SemiAutoShotgun_5",
            "Blueprint_EnergyShotgun_5",
            "Blueprint_SkyShotgun_5",
            "Blueprint_WidePenetrateShotgun_5",
            "Blueprint_Musket_5",
            "Blueprint_SingleShotRifle_5",
            "Blueprint_SemiAutoRifle_5",
            "Blueprint_MakeshiftAssaultRifle_5",
            "Blueprint_AssaultRifle_Default5",
            "Blueprint_SkyAssaultRifle_5",
            "Blueprint_ElectricArcAssaultRifle_5",
            "Blueprint_MakeshiftSubmachineGun_5",
            "Blueprint_SubmachineGun_5",
            "Blueprint_SkySubmachineGun_5",
            "Blueprint_Launcher_Default_5",
            "Blueprint_LaserRifle_5",
            "Blueprint_ChargeLaserRifle_5",
            "Blueprint_OverheatRifle_5",
            "Blueprint_FlameThrower_5",
            "Blueprint_GatlingGun_5",
            "Blueprint_LaserGatlingGun_5",
            "Blueprint_GrenadeLauncher_5",
            "Blueprint_SkyGrenadeLauncher_5",
            "Blueprint_GuidedMissileLauncher_5",
            "Blueprint_MultiGuidedMissileLauncher_5",
            "Blueprint_EnergyRocketLauncher_5",
            "Blueprint_BeamLauncher_5",
            "Blueprint_DroneLauncher_5",
            "Blueprint_YakushimaBlade004_5",
            "Blueprint_YakushimaBlade002_5",
            "Blueprint_YakushimaGun001_5",
            "Blueprint_YakushimaLantern001_5",
            "Blueprint_YakushimaBlade003_5",
            "Blueprint_OctaviaRevolver_5",
            "Blueprint_OctaviaShotgun_5",
            "Blueprint_ClothArmor_5",
            "Blueprint_FurArmor_5",
            "Blueprint_CopperArmor_5",
            "Blueprint_IronArmor_5",
            "Blueprint_StealArmor_5",
            "Blueprint_PlasticArmor_5",
            "Blueprint_PlasticArmorWeight_5",
            "Blueprint_SFArmor_5",
            "Blueprint_SFArmorWeight_5",
            "Blueprint_AncientArmor_5",
            "Blueprint_AncientArmorWeight_5",
            "Blueprint_YakushimaArmor001_5",
            "Blueprint_Octavia001_Armor_5",
            "Blueprint_Octavia002_Armor_5",
            "Blueprint_FurHelmet_5",
            "Blueprint_CopperHelmet_5",
            "Blueprint_IronHelmet_5",
            "Blueprint_StealHelmet_5",
            "Blueprint_PlasticHelmet_5",
            "Blueprint_SFHelmet_5",
            "Blueprint_AncientHelmet_5",
            "Blueprint_YakushimaHeadEquip001_5",
            "Blueprint_YakushimaHeadEquip003_5",
            "Blueprint_YakushimaHeadEquip002_5",
            "Blueprint_YakushimaHeadEquip004_5",
        }
    end,
    Implants = function()
        return {
            "PalPassiveSkillChange_NonKilling",
            "PalPassiveSkillChange_Nocturnal",
            "PalPassiveSkillChange_HatchingSpeed_Up",
            "PalPassiveSkillChange_CoolTimeReduction_Up_2",
            "PalPassiveSkillChange_Stamina_Up_3",
            "PalPassiveSkillChange_MoveSpeed_up_3",
            "PalPassiveSkillChange_PAL_FullStomach_Down_3",
            "PalPassiveSkillChange_PAL_Sanity_Down_3",
            "PalPassiveSkillChange_PAL_ALLAttack_up3",
            "PalPassiveSkillChange_Deffence_up3",
            "PalPassiveSkillChange_CraftSpeed_up3",
            "PalPassiveSkillChange_Noukin",
            "PalPassiveSkillChange_TrainerATK_UP_1",
            "PalPassiveSkillChange_TrainerDEF_UP_1",
            "PalPassiveSkillChange_TrainerWorkSpeed_UP_1",
            "PalPassiveSkillChange_SalePrice_Up_2",
            "PalPassiveSkillChange_SwimSpeed_up_2",
            "PalPassiveSkillChange_TrainerMining_up1",
            "PalPassiveSkillChange_TrainerLogging_up1",
            "PalPassiveSkillChange_PAL_CorporateSlave",
            "PalPassiveSkillChange_PlayerSP_DecreaseRate_Passive",
            "PalPassiveSkillChange_AutoHPRegeneRate_Passive",
            "PalPassiveSkillChange_ReloadSpeedUp_Passive",
            "PalPassiveSkillChange_Consumable_WorldTree_ATK",
            "PalPassiveSkillChange_Consumable_WorldTree_DEF",
            "PalPassiveSkillChange_Consumable_WorldTree_CraftSpeed",
            "PalPassiveSkillChange_Consumable_WorldTree_FullStomach",
            "PalPassiveSkillChange_Consumable_WorldTree_Sanity",
            "PalPassiveSkillChange_Consumable_WorldTree_MoveSpeed",
            "PalPassiveSkillChange_Consumable_WorldTree_ATK_DEF",
            "PalPassiveSkillChange_Consumable_CraftSpeed_up3",
            "PalPassiveSkillChange_Consumable_Deffence_up3",
            "PalPassiveSkillChange_Consumable_PAL_ALLAttack_up3",
            "PalPassiveSkillChange_Consumable_PAL_FullStomach_Down_3",
            "PalPassiveSkillChange_Consumable_PAL_Sanity_Down_3",
            "PalPassiveSkillChange_Consumable_MoveSpeed_up_3",
            "PalPassiveSkillChange_Consumable_Stamina_Up_3",
            "PalPassiveSkillChange_Consumable_Vampire",
            "PalPassiveSkillChange_Consumable_SwimSpeed_up_3",
            "PalPassiveSkillChange_Consumable_MutationPal_Babysitter",
            "PalPassiveSkillChange_Consumable_MutationPal_Mutant",
            "PalPassiveSkillChange_Consumable_MutationPal_Immortal",
            "PalPassiveSkillChange_Consumable_MutationPal_ExplosionResist",
            "PalPassiveSkillChange_Consumable_RideJumpCount_Increase2",
        }
    end,
    Equipments = function()
        return {
            "WingGlider",
            "Shield_07",
            "LaserMiningTool",
            "GrapplingGun5",
            "BeamLauncher_5",
            "AncientArmorWeight_5",
            "AncientHelmet_5",
            "UnlockEquipmentSlot_Weapon_01",
            "UnlockEquipmentSlot_Weapon_02",
            "Lantern_High",
            "AutoMealPouch_Tier1",
            "AutoMealPouch_Tier2",
            "AutoMealPouch_Tier3",
            "AutoMealPouch_Tier4",
            "AutoMealPouch_Tier5",
            "UnlockEquipmentSlot_Accessory_01",
            "UnlockEquipmentSlot_Accessory_02",
            "Unlock_Picking_Tier1",
            "Unlock_Picking_Tier2",
            "Unlock_Picking_Tier3",
            "AdditionalInventory_001",
            "AdditionalInventory_002",
            "AdditionalInventory_003",
            "AdditionalInventory_004",
            "SphereModule_Homing",
            "Accessory_SuperJumpAir_2",
            "Accessory_NonkChecker_1",
            "Accessory_ExplosionResist",
            "Accessory_HeatColdResist_1",
            "GasMask",
            "WaterBuildKit",
        }
    end,
    Saddles = function()
        return {
            "SkillUnlock_Boar",
            "SkillUnlock_Kitsunebi",
            "SkillUnlock_Kitsunebi_Ice",
            "SkillUnlock_Alpaca",
            "SkillUnlock_FlyingManta",
            "SkillUnlock_FlyingManta_Thunder",
            "SkillUnlock_Hedgehog",
            "SkillUnlock_Hedgehog_Ice",
            "SkillUnlock_DreamDemon",
            "SkillUnlock_Garm",
            "SkillUnlock_NegativeOctopus",
            "SkillUnlock_NegativeOctopus_Neutral",
            "SkillUnlock_WeaselDragon",
            "SkillUnlock_WeaselDragon_Fire",
            "SkillUnlock_Carbunclo",
            "SkillUnlock_Monkey",
            "SkillUnlock_Monkey_Fire",
            "SkillUnlock_Deer",
            "SkillUnlock_Deer_Ground",
            "SkillUnlock_Kirin",
            "SkillUnlock_Kirin_Ice",
            "SkillUnlock_FlameBuffalo",
            "SkillUnlock_HawkBird",
            "SkillUnlock_Serpent",
            "SkillUnlock_Serpent_Ground",
            "SkillUnlock_Penguin",
            "SkillUnlock_Penguin_Electric",
            "SkillUnlock_FlowerRabbit",
            "SkillUnlock_ColorfulBird",
            "SkillUnlock_WindChimes",
            "SkillUnlock_WindChimes_Ice",
            "SkillUnlock_NaughtyCat",
            "SkillUnlock_FairyDragon",
            "SkillUnlock_FairyDragon_Water",
            "SkillUnlock_PurpleSpider",
            "SkillUnlock_BirdDragon",
            "SkillUnlock_BirdDragon_Ice",
            "SkillUnlock_MopKing",
            "SkillUnlock_RaijinDaughter",
            "SkillUnlock_RaijinDaughter_Water",
            "SkillUnlock_KingAlpaca",
            "SkillUnlock_KingAlpaca_Ice",
            "SkillUnlock_Eagle",
            "SkillUnlock_BlueDragon",
            "SkillUnlock_BlueDragon_Ice",
            "SkillUnlock_FlowerDinosaur",
            "SkillUnlock_FlowerDinosaur_Electric",
            "SkillUnlock_HadesBird",
            "SkillUnlock_HadesBird_Electric",
            "SkillUnlock_FengyunDeeper",
            "SkillUnlock_FengyunDeeper_Electric",
            "SkillUnlock_IceSeal",
            "SkillUnlock_LeafMomonga",
            "SkillUnlock_FeatherOstrich",
            "SkillUnlock_FireKirin",
            "SkillUnlock_FireKirin_Dark",
            "SkillUnlock_GrassMammoth",
            "SkillUnlock_GrassMammoth_Ice",
            "SkillUnlock_ThunderBird",
            "SkillUnlock_ThunderBird_Ice",
            "SkillUnlock_ThunderDog",
            "SkillUnlock_Thunderdog_Ice",
            "SkillUnlock_GhostAnglerfish",
            "SkillUnlock_GhostAnglerfish_Fire",
            "SkillUnlock_GrassPanda",
            "SkillUnlock_GrassPanda_Electric",
            "SkillUnlock_IceDeer",
            "SkillUnlock_Manticore",
            "SkillUnlock_Manticore_Dark",
            "SkillUnlock_RedArmorBird",
            "SkillUnlock_SakuraSaurus",
            "SkillUnlock_SakuraSaurus_Water",
            "SkillUnlock_TropicalOstrich",
            "SkillUnlock_Plesiosaur",
            "SkillUnlock_VolcanoDragon",
            "SkillUnlock_VolcanoDragon_Ice",
            "SkillUnlock_GhostBeast",
            "SkillUnlock_SkyDragon",
            "SkillUnlock_SkyDragon_Grass",
            "SkillUnlock_BlackMetalDragon",
            "SkillUnlock_MushroomDragon",
            "SkillUnlock_MushroomDragon_Dark",
            "SkillUnlock_ElecPanda",
            "SkillUnlock_WhiteAlienDragon",
            "SkillUnlock_GuardianDog",
            "SkillUnlock_IceNarwhal",
            "SkillUnlock_IceNarwhal_Fire",
            "SkillUnlock_VolcanicMonster",
            "SkillUnlock_VolcanicMonster_Ice",
            "SkillUnlock_Suzaku",
            "SkillUnlock_Suzaku_Water",
            "SkillUnlock_LazyDragon",
            "SkillUnlock_LazyDragon_Electric",
            "SkillUnlock_Yeti",
            "SkillUnlock_Yeti_Grass",
            "SkillUnlock_BlackGriffon",
            "SkillUnlock_GrassGolem",
            "SkillUnlock_GrassGolem_Dark",
            "SkillUnlock_CubeTurtle",
            "SkillUnlock_CubeTurtle_Neutral",
            "SkillUnlock_BadCatgirl",
            "SkillUnlock_MoonQueen",
            "SkillUnlock_SumoDog",
            "SkillUnlock_GoldenHorse",
            "SkillUnlock_IceSeal_Ground",
            "SkillUnlock_NightBlueHorse",
            "SkillUnlock_NightBlueHorse_Neutral",
            "SkillUnlock_AmaterasuWolf",
            "SkillUnlock_AmaterasuWolf_Dark",
            "SkillUnlock_BlackPuppy",
            "SkillUnlock_BlueThunderHorse",
            "SkillUnlock_Horus",
            "SkillUnlock_Horus_Water",
            "SkillUnlock_WhiteShieldDragon",
            "SkillUnlock_KingSunfish",
            "SkillUnlock_KingSunfish_Thunder",
            "SkillUnlock_ThunderFluffyBird",
            "SkillUnlock_DarkMechaDragon",
            "SkillUnlock_GhostDragon",
            "SkillUnlock_GhostDragon_Fire",
            "SkillUnlock_ThiefBird",
            "SkillUnlock_LotusDragon",
            "SkillUnlock_SnowTigerBeastman",
            "SkillUnlock_BlueSkyDragon",
            "SkillUnlock_Umihebi",
            "SkillUnlock_DomeArmorDragon",
            "SkillUnlock_Umihebi_Fire",
            "SkillUnlock_KingBahamut",
            "SkillUnlock_KingBahamut_Dragon",
            "SkillUnlock_WhiteDeer",
            "SkillUnlock_WhiteDeer_Dark",
            "SkillUnlock_SaintCentaur",
            "SkillUnlock_BlackCentaur",
            "SkillUnlock_IceHorse",
            "SkillUnlock_IceHorse_Dark",
            "SkillUnlock_PoseidonOrca",
            "SkillUnlock_LegendDeer",
            "SkillUnlock_JetDragon",
        }
    end,
}

local loadedLists = {}

local function getList(name)
    if loadedLists[name] then
        return loadedLists[name]
    end
    local definition = listDefinitions[name]
    if not definition then
        return nil
    end
    local list = definition()
    loadedLists[name] = list
    return list
end

local ArgToList = {
    [1] = {
        list = "Consumables",
        qty = 1000,
    },
    [2] = {
        list = "Materials",
        qty = 1000,
    },
    [3] = {
        list = "Slabs",
        qty = 100,
    },
    [4] = {
        list = "Implants",
        qty = 1,
    },
    [5] = {
        list = "Blueprints",
        qty = 1,
    },
    [6] = {
        list = "Equipments",
        qty = 1,
    },
    [7] = {
        list = "Saddles",
        qty = 1,
    },
}

local function getInventoryData()
    local playerState = safeCall(function()
        return FindFirstOf(PLAYER_STATE)
    end)
    if isValidUObject(playerState) then
        local inventory = safeCall(function()
            return playerState:GetInventoryData()
        end)
        if isValidUObject(inventory) then
            return inventory
        end
    end
    return safeCall(function()
        return FindFirstOf(PLAYER_INVENTORY)
    end)
end

local function safeAddItems(keyId, listName, qty)
    if not canPressKey(keyId) then
        return
    end
    local items = getList(listName)
    if not items then
        return
    end
    local inv = getInventoryData()
    if not isValidUObject(inv) then
        return
    end
    safeCall(function()
        for _, item in ipairs(items) do
            inv:AddItem_ServerInternal(FName(item), qty or 1, true, 0, false)
        end
    end)
    GarbageCollect()
end

function GiveModule.Keybind(arg)
    local mapping = ArgToList[arg]
    if not mapping then
        return
    end
    safeAddItems(arg, mapping.list, mapping.qty)
end

local function registerKeybinds()
    if keybindRegistered then
        return true
    end
    local engineRegister = rawget(_G, "RegisterKeyBind")
    if not engineRegister then
        return false
    end
    local success = true
    local bindings = {
        {
            key = Key.F4,
            arg = 1,
        },
        {
            key = Key.F5,
            arg = 2,
        },
        {
            key = Key.F6,
            arg = 3,
        },
        {
            key = Key.F7,
            arg = 4,
        },
        {
            key = Key.F8,
            arg = 5,
        },
        {
            key = Key.F9,
            arg = 6,
        },
        {
            key = Key.F10,
            arg = 7,
        },
    }
    for _, binding in ipairs(bindings) do
        local ok = pcall(function()
            engineRegister(binding.key, function()
                GiveModule.Keybind(binding.arg)
            end)
        end)
        if not ok then
            success = false
        end
    end
    if success then
        keybindRegistered = true
    end
    return success
end

function GiveModule.Initialize()
    local registered = registerKeybinds()
    if not registered then
        ExecuteWithDelay(1000, registerKeybinds)
    end
    return true
end

return GiveModule
