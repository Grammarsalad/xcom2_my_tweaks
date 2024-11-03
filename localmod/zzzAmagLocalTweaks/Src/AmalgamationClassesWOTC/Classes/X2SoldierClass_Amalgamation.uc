// soldier class creation class
class X2SoldierClass_Amalgamation extends X2SoldierClass config(Amalgamation);

`define LogError(message) `LOG(`message, true, 'Amalgamation SOLDIER ERROR')
`define LogInfo(message) `LOG(`message, true, 'Amalgamation SOLDIER INFO')
`define LogDebug(message) `LOG(`message, class'X2SoldierClass_Amalgamation'.default.LogDebug, 'Amalgamation SOLDIER DEBUG')

struct SpecMetaStruct {
	var name Spec;
	var array<SoldierClassWeaponType> AllowedWeapons;
	var array<name> AllowedArmors;
	var name SquaddieWeapon;
	var string SpecIcon;
	var name NicknameSrc;
	var array<name> AllAbilities; // caching abilities for 2 less loops in most invested spec
};

struct SkillStatStruct {
	var name Deck;
	var SoldierClassAbilityType Skill;
	var array<SoldierClassStatType> Stats;
};

struct SpecDataStruct {
	var name Spec;
	var array<SkillStatStruct> Ranks;
};

struct NicknameEntry {
	var name ClassName;
	var array<name> Sources;
};

struct ExtraWeapon {
	var name SpecName;
	var SoldierClassWeaponType Weapon;
};

struct ExtraArmor {
	var name SpecName;
	var name ArmorType;
};

struct IncompatibleSpec {
	var name A;
	var name B;
};

var config bool LogDebug;

var config array<SpecMetaStruct> PrimarySpecs;
var config array<SpecMetaStruct> SecondarySpecs;
var config array<SpecMetaStruct> TertiarySpecs;
var config array<SoldierClassRandomAbilityDeck> AbilityDecks;
var config array<SpecDataStruct> SpecDataset;

var config array<name> AllClassAllowedArmors;
var config array<SoldierClassWeaponType> AllClassAllowedWeapons;

var config array<ExtraWeapon> ExtraAllowedWeapons;
var config array<ExtraArmor> ExtraAllowedArmors;
var config array<IncompatibleSpec> IncompatibleSpecs;

var config int PromotionAP;
var config int NumInForcedDeck;
var config int NumInDeck;

var config bool AllowAWC;
var config bool UnlockPhotoboothPoses;

var config(EvilNeverGoingToBeUsedConfigNameToDoHackyDataShareBetweenClasses) array<name> AmalgamationClasses;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	CreateAmalgamTemplates(Templates);
	
	return Templates;
}

final static function CreateAmalgamTemplates(out array<X2DataTemplate> Templates)
{
	local X2SoldierClassTemplate Template;

	local SpecMetaStruct PrimarySpec;
	local SpecMetaStruct SecondarySpec;
	local SpecMetaStruct TertiarySpec;

	local name ClassName;
	local name LoadoutName;
	local array<SoldierClassRank> NewSoldierRanks;
	local array<name> UsedRandomDecks;
	
	LogSpecs();

	// Cache spec abilities to be used with UI mod
	BuildAllAbilities();

	foreach default.PrimarySpecs(PrimarySpec)
	{
		foreach default.SecondarySpecs(SecondarySpec)
		{
			foreach default.TertiarySpecs(TertiarySpec)
			{
				ClassName = name(PrimarySpec.Spec $ "_" $ SecondarySpec.Spec $ "_" $ TertiarySpec.Spec);

				`LogDebug("Creating" @ ClassName);

				if (AreSpecsIncompatible(PrimarySpec.Spec, SecondarySpec.Spec, TertiarySpec.Spec))
				{
					`LogDebug("Incompatible combination of specs" @ ClassName);
					continue;
				}

				default.AmalgamationClasses.addItem(ClassName);

				// reset reusable arrays
				NewSoldierRanks.length = 0;
				UsedRandomDecks.length = 0;
				
				`CREATE_X2TEMPLATE(class'X2SoldierClassTemplate', Template, ClassName);

				Template.NumInForcedDeck = default.NumInForcedDeck;
				Template.NumInDeck = default.NumInDeck;

				Template.KillAssistsPerKill = 4;
				Template.PsiCreditsPerKill = 4;

				Template.bCanHaveBonds = true;
				Template.bAllowAWCAbilities = true;
				
				// add to highlander awc exclusion
				// bAllowAWCAbilities enables AP, and this highlander config excludes the perk row
				if (!default.AllowAWC)
				{
					class'CHHelpers'.default.ClassesExcludedFromAWCRoll.addItem(ClassName);
				}

				Template.BaseAbilityPointsPerPromotion = default.PromotionAP;
				
				// used in places without dynamic locs
				Template.DisplayName = 
					Localize(string(PrimarySpec.Spec), "SpecName", "Amalgamation") @ "-" 
					@ Localize(string(SecondarySpec.Spec), "SpecName", "Amalgamation") @ "-" 
					@ Localize(string(TertiarySpec.Spec), "SpecName", "Amalgamation");
				Template.ClassSummary = Localize(string(PrimarySpec.Spec), "SpecSummary", "Amalgamation");

				Template.IconImage = PrimarySpec.SpecIcon;

				Template.AbilityTreeTitles[0] = Localize(string(PrimarySpec.Spec), "SpecName", "Amalgamation");
				Template.AbilityTreeTitles[1] = Localize(string(SecondarySpec.Spec), "SpecName", "Amalgamation");
				Template.AbilityTreeTitles[2] = Localize(string(TertiarySpec.Spec), "SpecName", "Amalgamation");

				Template.AllowedWeapons = GetClassWeapons(PrimarySpec, SecondarySpec, TertiarySpec);
				Template.AllowedArmors = GetClassArmors(PrimarySpec, SecondarySpec, TertiarySpec);

				LoadoutName = MakeSquaddieLoadout(PrimarySpec.SquaddieWeapon, SecondarySpec.SquaddieWeapon);
				Template.SquaddieLoadout = LoadoutName;

				FillRanks_ListDecks(NewSoldierRanks, UsedRandomDecks, PrimarySpec.Spec, SecondarySpec.Spec, TertiarySpec.Spec);
				Template.SoldierRanks = NewSoldierRanks;
				Template.RandomAbilityDecks = GetDecksByNames(UsedRandomDecks);

				MakeNicknameEntry(ClassName, PrimarySpec, SecondarySpec, TertiarySpec);

				if (default.UnlockPhotoboothPoses)
				{
					MakePhotoboothEntry(ClassName, Template.AllowedWeapons);
				}
				
				Templates.AddItem(Template);
			}
		}
	}
}

final static function LogSpecs()
{
	local SpecMetaStruct Spec;
	
	`LogDebug("Primary specs:");
	foreach default.PrimarySpecs(Spec)
	{
		`LogDebug(Spec.Spec);
	}
	
	`LogDebug("Secondary specs:");
	foreach default.SecondarySpecs(Spec)
	{
		`LogDebug(Spec.Spec);	
	}
	
	`LogDebug("Tertiary specs:");
	foreach default.TertiarySpecs(Spec)
	{
		`LogDebug(Spec.Spec);	
	}
}

final static function array<SoldierClassWeaponType> GetClassWeapons(SpecMetaStruct Primary, SpecMetaStruct Secondary, SpecMetaStruct Tertiary)
{
	local array<SoldierClassWeaponType> result;

	MergeWeaponList(result, Primary.AllowedWeapons);
	MergeWeaponList(result, Secondary.AllowedWeapons);
	MergeWeaponList(result, Tertiary.AllowedWeapons);
	MergeWeaponList(result, GetExtraWeapons(Primary.Spec));
	MergeWeaponList(result, GetExtraWeapons(Secondary.Spec));
	MergeWeaponList(result, GetExtraWeapons(Tertiary.Spec));
	MergeWeaponList(result, default.AllClassAllowedWeapons);

	return result;
}

final static function MergeWeaponList(out array<SoldierClassWeaponType> result, array<SoldierClassWeaponType> set)
{
	local SoldierClassWeaponType entry;
	local int index;

	foreach set(entry)
	{
		index = result.find('WeaponType', entry.WeaponType);

		if (index == INDEX_NONE)
		{
			result.addItem(entry);		
		}
	}
}

final static function array<SoldierClassWeaponType> GetExtraWeapons(name SpecName)
{
	local array <SoldierClassWeaponType> Result;
	local ExtraWeapon Entry;

	`LogDebug("Extra Weapons for" @ SpecName);

	foreach default.ExtraAllowedWeapons(Entry)
	{
		`LogDebug(SpecName @ Entry.SpecName);
		if (Entry.SpecName == SpecName)
		{
			Result.addItem(Entry.Weapon);
		}
	}

	return Result;
}

final static function array<name> GetClassArmors(SpecMetaStruct Primary, SpecMetaStruct Secondary, SpecMetaStruct Tertiary)
{
	local array<name> Result;

	MergeArmorLists(result, Primary.AllowedArmors);
	MergeArmorLists(result, Secondary.AllowedArmors);
	MergeArmorLists(result, Tertiary.AllowedArmors);
	MergeArmorLists(result, GetExtraArmors(Primary.Spec));
	MergeArmorLists(result, GetExtraArmors(Secondary.Spec));
	MergeArmorLists(result, GetExtraArmors(Tertiary.Spec));
	MergeArmorLists(result, default.AllClassAllowedArmors);

	return Result;
}

final static function MergeArmorLists(out array<name> Result, array<name> Set)
{
	local name Entry;
	
	foreach Set(Entry)
	{
		if (Result.find(Entry) == INDEX_NONE)
		{
			Result.addItem(Entry);
		}
	}
}

final static function array<name> GetExtraArmors(name SpecName)
{
	local array <name> Result;
	local ExtraArmor Entry;

	foreach default.ExtraAllowedArmors(Entry)
	{
		if (Entry.SpecName == SpecName)
		{
			Result.addItem(Entry.ArmorType);
		}
	}

	return Result;
}

final static function name MakeSquaddieLoadout(name Primary, name Secondary)
{
	local name LoadoutName;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem Item;
	local int index;

	LoadoutName = name(Primary $ "_" $ Secondary $ "_loadout");

	Loadout.LoadoutName = LoadoutName;

	Item.Item = Primary;
	Loadout.Items.addItem(Item);
	
	Item.Item = Secondary;
	Loadout.Items.addItem(Item);

	index = class'X2DownloadableContentInfo_AmalgamationClassesWOTC'.default.LoadoutsToAdd.find('LoadoutName', Loadout.LoadoutName);
	
	if (index == INDEX_NONE)
	{
		class'X2DownloadableContentInfo_AmalgamationClassesWOTC'.default.LoadoutsToAdd.addItem(Loadout);
	}

	return LoadoutName;
}

final static function FillRanks_ListDecks(out array<SoldierClassRank> NewSoldierRanks, out array<name> UsedDecks, name Primary, name Secondary, name Tertiary)
{
	local SoldierClassRank Rank;
	local int i;

	local int PrimaryIndex;
	local int SecondaryIndex;
	local int TertiaryIndex;

	local SkillStatStruct PrimaryRank;
	local SkillStatStruct SecondaryRank;
	local SkillStatStruct TertiaryRank;

	PrimaryIndex = default.SpecDataset.find('Spec', Primary);
	SecondaryIndex = default.SpecDataset.find('Spec', Secondary);
	TertiaryIndex = default.SpecDataset.find('Spec', Tertiary);

	if (PrimaryIndex == INDEX_NONE)
	{
		`LogError("No SpecDataset found:" @ Primary);
		return;
	}
	
	if (SecondaryIndex == INDEX_NONE)
	{
		`LogError("No SpecDataset found:" @ Secondary);
		return;
	}

	if (TertiaryIndex == INDEX_NONE)
	{
		`LogError("No SpecDataset found:" @ Tertiary);
		return;
	}

	for (i = 0; i < default.SpecDataset[PrimaryIndex].Ranks.Length; i++)
	{
		PrimaryRank = default.SpecDataset[PrimaryIndex].Ranks[i];
		SecondaryRank = default.SpecDataset[SecondaryIndex].Ranks[i];
		TertiaryRank = default.SpecDataset[TertiaryIndex].Ranks[i];
		
		Rank.AbilitySlots = GetAbilitySlots(UsedDecks, PrimaryRank, SecondaryRank, TertiaryRank);
		
		Rank.aStatProgression = GetCombinedStats(PrimaryRank.Stats, SecondaryRank.Stats, TertiaryRank.Stats);

		NewSoldierRanks.addItem(Rank);
	}
}

final static function array<SoldierClassAbilitySlot> GetAbilitySlots(out array<name> UsedDecks, SkillStatStruct Primary,  SkillStatStruct Secondary,  SkillStatStruct Tertiary)
{
	local array<SoldierClassAbilitySlot> result;

	result.addItem(GetSingleSlot(UsedDecks, Primary));
	result.addItem(GetSingleSlot(UsedDecks, Secondary));
	result.addItem(GetSingleSlot(UsedDecks, Tertiary));

	return result;
}

final static function SoldierClassAbilitySlot GetSingleSlot(out array<name> UsedDecks, SkillStatStruct SkillStruct)
{
	local SoldierClassAbilitySlot Slot;

	if (SkillStruct.Deck != '')
	{
		Slot.RandomDeckName = SkillStruct.Deck;

		if (UsedDecks.find(SkillStruct.Deck) == INDEX_NONE)
		{
			UsedDecks.addItem(SkillStruct.Deck);		
		}
	}
	else
	{
		Slot.AbilityType = SkillStruct.Skill;
	}

	return Slot;
}

final static function array<SoldierClassRandomAbilityDeck> GetDecksByNames(array<name> UsedRandomDecks)
{
	local array<SoldierClassRandomAbilityDeck> result;
	local name entry;
	local int index;

	foreach UsedRandomDecks(entry)
	{
		index = default.AbilityDecks.find('DeckName', entry);

		if (index == INDEX_NONE)
		{
			`LogError("Found no AbilityDeck named:" @ entry);
		}
		else
		{
			result.addItem(default.AbilityDecks[index]);
		}
	}

	return result;
}

final static function array<SoldierClassStatType> GetCombinedStats(array<SoldierClassStatType> set1, array<SoldierClassStatType> set2, array<SoldierClassStatType> set3)
{
	local array<SoldierClassStatType> result;

	CombineStats(result, set1);
	CombineStats(result, set2);
	CombineStats(result, set3);

	return result;
}

final static function CombineStats(out array<SoldierClassStatType> result, array<SoldierClassStatType> set)
{
	local SoldierClassStatType entry;
	local int index;

	foreach set(entry)
	{
		index = result.find('StatType', entry.StatType);
		
		if (index == INDEX_NONE)
		{
			result.addItem(entry);
		}
		else
		{
			result[index].StatAmount += entry.StatAmount;
		}
	}
}

final static function SpecMetaStruct FindMostInvestedSpec(XComGameState_Unit Unit)
{
	local array<string> SpecStrings;
	local array<SpecMetaStruct> Specs;
	local array<int> Investment;

	SpecStrings = SplitString(string(Unit.GetSoldierClassTemplateName()), "_");

	Specs.AddItem(default.PrimarySpecs[default.PrimarySpecs.find('Spec', name(SpecStrings[0]))]);
	Specs.AddItem(default.SecondarySpecs[default.SecondarySpecs.find('Spec', name(SpecStrings[1]))]);
	Specs.AddItem(default.TertiarySpecs[default.TertiarySpecs.find('Spec', name(SpecStrings[2]))]);

	Investment = CountAbilityInvestments(Specs, Unit.GetEarnedSoldierAbilities());

	`LogDebug("Soldier abilities" @ SpecStrings[0] @ Investment[0] @ SpecStrings[1] @ Investment[1] @ SpecStrings[2] @ Investment[2]);

	// most primary
	if (Investment[1] <= Investment[0] && Investment[2] <= Investment[0])
	{
		return Specs[0];
	}

	// most secondary
	if (Investment[2] <= Investment[1])
	{
		return Specs[1];
	}

	return Specs[2];
}

final static function array<int> CountAbilityInvestments(array<SpecMetaStruct> Specs, array<SoldierClassAbilityType> EarnedAbilities)
{
	local array<int> Result;
	local SoldierClassAbilityType Ability;

	Result.Length = Specs.Length;

	foreach EarnedAbilities(Ability)
	{
		`LogDebug("Checking" @ Ability.AbilityName);
		if (Specs[0].AllAbilities.find(Ability.AbilityName) != INDEX_NONE)
		{
			`LogDebug("Primary");
			Result[0]++;
			continue;
		}

		if (Specs[1].AllAbilities.find(Ability.AbilityName) != INDEX_NONE)
		{
			`LogDebug("Secondary");
			Result[1]++;
			continue;
		}

		if (Specs[2].AllAbilities.find(Ability.AbilityName) != INDEX_NONE)
		{
			`LogDebug("Tertiary");
			Result[2]++;
			continue;
		}
		`LogDebug("None ???");
	}

	return Result;
}

final static function MakeNicknameEntry(name ClassName, SpecMetaStruct Primary, SpecMetaStruct Secondary, SpecMetaStruct Tertiary)
{
	local NicknameEntry Entry;

	Entry.ClassName = ClassName;

	if (Primary.NicknameSrc != '')
	{
		Entry.Sources.addItem(Primary.NicknameSrc);
	}

	if (Secondary.NicknameSrc != '')
	{
		Entry.Sources.addItem(Secondary.NicknameSrc);
	}

	if (Tertiary.NicknameSrc != '')
	{
		Entry.Sources.addItem(Tertiary.NicknameSrc);
	}

	class'X2DownloadableContentInfo_AmalgamationClassesWOTC'.default.NicknamesToMerge.addItem(Entry);
}

final static function bool AreSpecsIncompatible(name Spec1, name Spec2, name Spec3)
{
	local IncompatibleSpec Entry;

	foreach default.IncompatibleSpecs(Entry)
	{
		if ((Entry.A == Spec1 || Entry.A == Spec2 || Entry.A == Spec3)
		 && (Entry.B == Spec1 || Entry.B == Spec2 || Entry.B == Spec3))
		{
			return true;
		}
	}

	return false;
}

final static function BuildAllAbilities()
{
	local int i;

	for (i = 0; i < default.PrimarySpecs.length; i++)
	{
		default.PrimarySpecs[i].AllAbilities = GetAllAbilities(default.PrimarySpecs[i].Spec);
	}

	for (i = 0; i < default.SecondarySpecs.length; i++)
	{
		default.SecondarySpecs[i].AllAbilities = GetAllAbilities(default.SecondarySpecs[i].Spec);
	}

	for (i = 0; i < default.TertiarySpecs.length; i++)
	{
		default.TertiarySpecs[i].AllAbilities = GetAllAbilities(default.TertiarySpecs[i].Spec);
	}
}

final static function array<name> GetAllAbilities(name Spec)
{
	local array<name> UsedDecks;
	local array<name> Result;
	local int index;
	local SkillStatStruct Rank;
	local name Deck;
	local SoldierClassAbilityType DeckAbility;

	index = default.SpecDataset.find('Spec', Spec);

	foreach default.SpecDataset[index].Ranks(Rank)
	{
		if (Rank.Deck != '')
		{
			if (UsedDecks.Find(Rank.Deck) == INDEX_NONE)
			{
				UsedDecks.addItem(Rank.Deck);			
			}
		}
		else
		{
			Result.addItem(Rank.Skill.AbilityName);
		}
	}

	foreach UsedDecks(Deck)
	{
		index = default.AbilityDecks.find('DeckName', Deck);

		foreach default.AbilityDecks[index].Abilities(DeckAbility)
		{
			Result.addItem(DeckAbility.AbilityName);
		}
	}

	return Result;
}

final static function MakePhotoboothEntry(name ClassTemplateName, array<SoldierClassWeaponType> AllowedWeapons)
{
	local SoldierClassWeaponType Entry;
	local SoldierClassEnums ConfigEntry;

	ConfigEntry.SoldierClass = ClassTemplateName;

	// seems like in the end its the equipped loadout that limits the poses so we can just grant all here

	ConfigEntry.ClassFilter = ePAFT_Ranger;
	class'X2PhotoboothHelpers'.default.PhotoboothSoldierClassFilters.AddItem(ConfigEntry);
	ConfigEntry.ClassFilter = ePAFT_Sharpshooter;
	class'X2PhotoboothHelpers'.default.PhotoboothSoldierClassFilters.AddItem(ConfigEntry);
	ConfigEntry.ClassFilter = ePAFT_Specialist;
	class'X2PhotoboothHelpers'.default.PhotoboothSoldierClassFilters.AddItem(ConfigEntry);
	ConfigEntry.ClassFilter = ePAFT_Grenadier;
	class'X2PhotoboothHelpers'.default.PhotoboothSoldierClassFilters.AddItem(ConfigEntry);
}

