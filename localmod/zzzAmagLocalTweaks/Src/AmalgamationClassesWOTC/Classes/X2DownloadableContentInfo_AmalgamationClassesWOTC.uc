// otpc and ability restrictions
class X2DownloadableContentInfo_AmalgamationClassesWOTC extends X2DownloadableContentInfo dependson(X2SoldierClass_Amalgamation);

`define LogError(message) `LOG(`message, true, 'Amalgamation DLCINFO ERROR')
`define LogInfo(message) `LOG(`message, true, 'Amalgamation DLCINFO INFO')
`define LogDebug(message) `LOG(`message, class'X2SoldierClass_Amalgamation'.default.LogDebug, 'Amalgamation DLCINFO DEBUG')

struct AbilityRestriction {
	var name AbilityName;
	var name WeaponCat;
	var EInventorySlot InvSlot;
};

var config(Amalgamation) array<AbilityRestriction> AbilityRestrictions;
var config(Amalgamation) array<name> RemoveGTSUnlock;
var config(Amalgamation) array<name> DisableClass;

var config(EvilNeverGoingToBeUsedConfigNameToDoHackyDataShareBetweenClasses) array<InventoryLoadout> LoadoutsToAdd;
var config(EvilNeverGoingToBeUsedConfigNameToDoHackyDataShareBetweenClasses) array<NicknameEntry> NicknamesToMerge;

static event OnPostTemplatesCreated()
{
	AddLoadouts();
	AddNicknames();
	RemoveGTSUnlocks();
	DisableClasses();
	PatchAbilities();
	PatchHeroSchematicsAndGuns();
}

final static function AddLoadouts()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local InventoryLoadout Loadout;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach default.LoadoutsToAdd(Loadout)
	{
		ItemTemplateManager.Loadouts.addItem(Loadout);
	}

	`LogInfo("Added loadouts" @ default.LoadoutsToAdd.length);
}

final static function AddNicknames()
{
	local X2SoldierClassTemplateManager Mgr;
	local X2SoldierClassTemplate Amalgam, Source;
	local NicknameEntry Entry;
	local name srcName;

	Mgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach default.NicknamesToMerge(Entry)
	{
		Amalgam = Mgr.FindSoldierClassTemplate(Entry.ClassName);

		foreach Entry.Sources(srcName)
		{
			Source = Mgr.FindSoldierClassTemplate(srcName);

			if (Source == none)
			{
				`LogError("Found no class with name" @ srcName);
				continue;
			}

			MergeNicknames(Amalgam, Source);
		}
	}

	`LogInfo("Added nicknames" @ default.NicknamesToMerge.length);
}

final static function MergeNicknames(out X2SoldierClassTemplate Amalgam, X2SoldierClassTemplate Source)
{
	local string Nickname;

	foreach Source.RandomNickNames(Nickname)
	{
		if (Amalgam.RandomNickNames.find(Nickname) != INDEX_NONE)
		{
			continue;
		}

		Amalgam.RandomNickNames.addItem(Nickname);
	}

	foreach Source.RandomNickNames_Male(Nickname)
	{
		if (Amalgam.RandomNickNames_Male.find(Nickname) != INDEX_NONE)
		{
			continue;
		}

		Amalgam.RandomNickNames_Male.addItem(Nickname);
	}

	foreach Source.RandomNickNames_Female(Nickname)
	{
		if (Amalgam.RandomNickNames_Female.find(Nickname) != INDEX_NONE)
		{
			continue;
		}

		Amalgam.RandomNickNames_Female.addItem(Nickname);
	}
}

final static function RemoveGTSUnlocks()
{
	local X2StrategyElementTemplateManager Mgr;
	local X2StrategyElementTemplate GTS;
	local name UnlockName;

	Mgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	GTS = Mgr.FindStrategyElementTemplate('OfficerTrainingSchool');

	foreach default.RemoveGTSUnlock(UnlockName)
	{
		X2FacilityTemplate(GTS).SoldierUnlockTemplates.removeItem(UnlockName);
	}
	
	`LogInfo("Removed GTS upgrades" @ default.RemoveGTSUnlock.length);
}

final static function DisableClasses()
{
	local X2SoldierClassTemplateManager Mgr;
	local array<X2DataTemplate> TemplateArray;
	local X2DataTemplate Template;
	local X2SoldierClassTemplate ClassTemplate;
	local name ClassName;

	Mgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach default.DisableClass(ClassName)
	{
		Mgr.FindDataTemplateAllDifficulties(ClassName, TemplateArray);

		if (TemplateArray.length == 0)
		{
			`LogError("No class template" @ ClassName);
		}

		foreach TemplateArray(Template)
		{
			ClassTemplate = X2SoldierClassTemplate(Template);

			if (ClassTemplate != none)
			{
				ClassTemplate.NumInForcedDeck = 0;
				ClassTemplate.NumInDeck = 0;
			}
			else
			{
				`LogError("Not a class template" @ Template.DataName);
			}
		}
	}

	`LogInfo("Disabled classes" @ default.DisableClass.length);
}

final static function PatchAbilities()
{
	local X2AbilityTemplateManager Mgr;
	local array<X2AbilityTemplate> DiffTemplates;
	local X2AbilityTemplate Template;

	Mgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Mgr.FindAbilityTemplateAllDifficulties('PistolStandardShot', DiffTemplates);

	foreach DiffTemplates(Template)
	{
		Template.bDontDisplayInAbilitySummary = false;
	}
	
	`LogInfo("Patched abilities");
}

final static function PatchHeroSchematicsAndGuns()
{
	RemoveClassRestriction('VektorRifle_MG_Schematic');
	RemoveClassRestriction('Bullpup_MG_Schematic');
	RemoveClassRestriction('Sidearm_MG_Schematic');
	RemoveClassRestriction('VektorRifle_BM_Schematic');
	RemoveClassRestriction('Bullpup_BM_Schematic');
	RemoveClassRestriction('Sidearm_BM_Schematic');

	`LogInfo("Patched hero weapon schematics");

	// Prototype Armoury compatibility
	RemoveClassRestrictionWeapon('VektorRifle_MG');
	RemoveClassRestrictionWeapon('Bullpup_MG');
	RemoveClassRestrictionWeapon('Sidearm_MG');
	RemoveClassRestrictionWeapon('VektorRifle_BM');
	RemoveClassRestrictionWeapon('Bullpup_BM');
	RemoveClassRestrictionWeapon('Sidearm_BM');

	`LogInfo("Patched hero weapon template restrictions");
}

final static function RemoveClassRestriction(name SchematicName)
{
	local X2ItemTemplateManager Mgr;
	local array<X2DataTemplate> DiffTemplates;
	local X2DataTemplate Template;
	local X2SchematicTemplate Schematic;

	Mgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	Mgr.FindDataTemplateAllDifficulties(SchematicName, DiffTemplates);

	if(DiffTemplates.length == 0)
	{
		`LogError("No template found with name" @ SchematicName);
		return;
	}

	foreach DiffTemplates(Template)
	{
		Schematic = X2SchematicTemplate(Template);
		Schematic.Requirements.RequiredSoldierClass = '';
	}

	`LogInfo("Patched" @ SchematicName);
}

final static function RemoveClassRestrictionWeapon(name WeaponName)
{
	local X2ItemTemplateManager Mgr;
	local array<X2DataTemplate> DiffTemplates;
	local X2DataTemplate Template;
	local X2WeaponTemplate Weapon;

	Mgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	
	Mgr.FindDataTemplateAllDifficulties(WeaponName, DiffTemplates);

	if(DiffTemplates.length == 0)
	{
		`LogError("No template found with name" @ WeaponName);
		return;
	}

	foreach DiffTemplates(Template)
	{
		Weapon = X2WeaponTemplate(Template);
		Weapon.Requirements.RequiredSoldierClass = '';
	}
	
	`LogInfo("Patched" @ WeaponName);
}

// Remove abilities that do not match the required weapon type
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local AbilitySetupData AbilityData;
	local array<name> AbilitiesToRemove;
	local name AbilityName;
	local int index;
	
	// check team and that unit is soldier
	if (UnitState.GetTeam() != eTeam_XCom || UnitState.IsSoldier() == false)
	{
		return;
	}

	// check if unit is amalgam
	if (class'X2SoldierClass_Amalgamation'.default.AmalgamationClasses.find(UnitState.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
		`LogDebug("Skipped FinalizeAbilities on" @ UnitState.GetSoldierClassTemplateName());
		return;
	}

	// find abilities with restrictions
	foreach SetupData(AbilityData)
	{
		// skip if no restrictions
		if (default.AbilityRestrictions.find('AbilityName', AbilityData.TemplateName) == INDEX_NONE)
		{
			continue;
		}

		`LogDebug("Checking restrictions for" @ AbilityData.TemplateName);

		// add for removal if no restriction is satisfied
		if (MeetsAnyRestriction(AbilityData, UnitState) == false)
		{
			AbilitiesToRemove.addItem(AbilityData.TemplateName);
		}
	}

	foreach AbilitiesToRemove(AbilityName)
	{
		`LogDebug("Removing" @ AbilityName);
	}

	// remove unwanted entries
	// decrement for loop so we can remove entries while looping without adjusting index
	for(index = SetupData.length - 1; index >= 0; index--)
	{
		if (AbilitiesToRemove.find(SetupData[index].TemplateName) != INDEX_NONE)
		{
			SetupData.remove(index, 1);
		}
	}
}

final static function bool MeetsAnyRestriction(AbilitySetupData AbilityData, XComGameState_Unit UnitState)
{
	local AbilityRestriction Restriction;
	local X2WeaponTemplate WeaponTemplate;

	foreach default.AbilityRestrictions(Restriction)
	{
		if (Restriction.AbilityName != AbilityData.TemplateName)
		{
			continue;
		}

		WeaponTemplate = X2WeaponTemplate(UnitState.GetItemInSlot(Restriction.InvSlot).GetMyTemplate());

		if (WeaponTemplate == none)
		{
			`LogInfo("No weapon template in" @ Restriction.InvSlot @ AbilityData.TemplateName);
			continue;
		}

		if (WeaponTemplate.WeaponCat == Restriction.WeaponCat)
		{
			`LogDebug(Restriction.WeaponCat @ "in" @ Restriction.InvSlot @ "matches restriction for" @ AbilityData.TemplateName);
			return true;
		}
	}

	return false;
}

// ---- debug commands ----

exec function DumpClassTemplates()
{
	local X2SoldierClassTemplateManager Mgr;
	local array<X2SoldierClassTemplate> TemplateArray;
	local X2SoldierClassTemplate Template;

	Mgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	TemplateArray = Mgr.GetAllSoldierClassTemplates();
	
	`LogInfo("Current class templates:");
	foreach TemplateArray(Template)
	{
		`LogInfo("dataname:" @ Template.DataName @ "| name:" @ Template.DisplayName @ "| numforced:" @ Template.NumInForcedDeck @ "| numdeck:" @ Template.NumInDeck);
	}
}

exec function DumpCurrentClassDeck()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local int index, amalgams, others;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (XComHQ == none)
	{
		`LogError("No XComHQ found!");
		return;
	}

	`LogInfo("Current soldier class deck:");
	for (index = 0; index < XComHQ.SoldierClassDeck.length; index++)
	{
		`LogInfo("index:" @ index @ "name:" @ XComHQ.SoldierClassDeck[index]);
		if (class'X2SoldierClass_Amalgamation'.default.AmalgamationClasses.find(XComHQ.SoldierClassDeck[index]) != INDEX_NONE)
		{
			amalgams++;
		}
		else
		{
			others++;
		}
	}

	`LogInfo("Total amalgams:" @ amalgams);
	`LogInfo("Total others:" @ others);
}
