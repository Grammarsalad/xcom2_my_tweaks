class UIScreenListener_AmalgamPromoUISL extends UIScreenListener dependson (X2SoldierClass_Amalgamation);

event OnInit(UIScreen Screen)
{
	local int i;
	local UIInventory_ListItem CLI;
	local UIImage Img;
	local UIText Text;
	local UIScrollingTextField ScrlText;
	local array<string> arrAmalgams;
	local int PSpec;
	local int SSpec;
	local int TSpec;
	local string Weapons;

	if (Screen.IsA('UIChooseClass'))
	{
		for (i = 0; i < UIChooseClass(Screen).arrItems.Length; i++)
		{
			CLI = UIInventory_ListItem(UIChooseClass(Screen).List.GetItem(i));
			arrAmalgams = SplitString(CLI.ItemComodity.Title, " - ");
			if (arrAmalgams.Length != 3)
			{
				// Not Amalgam Class
				continue;
			}
			
			PSpec = FindSpec(class'X2SoldierClass_Amalgamation'.default.PrimarySpecs, arrAmalgams[0]);
			SSpec = FindSpec(class'X2SoldierClass_Amalgamation'.default.SecondarySpecs, arrAmalgams[1]);
			TSpec = FindSpec(class'X2SoldierClass_Amalgamation'.default.TertiarySpecs, arrAmalgams[2]);

			if (PSpec != INDEX_NONE)
			{
				// Primary Spec
				Weapons = GetWeaponCat(class'X2SoldierClass_Amalgamation'.default.PrimarySpecs[PSpec].AllowedWeapons);
			}
			if (SSpec != INDEX_NONE)
			{
				// Secondary Spec
				Img = CLI.Spawn(class'UIImage', CLI).InitImage(, class'X2SoldierClass_Amalgamation'.default.SecondarySpecs[SSpec].SpecIcon);
				Img.SetScale(0.75);
				Img.SetPosition(0, 75);
				Weapons @= "+" @ GetWeaponCat(class'X2SoldierClass_Amalgamation'.default.SecondarySpecs[SSpec].AllowedWeapons);
			}
			if (TSpec != INDEX_NONE)
			{
				// Tertiary Spec
				Img = CLI.Spawn(class'UIImage', CLI).InitImage(, class'X2SoldierClass_Amalgamation'.default.TertiarySpecs[TSpec].SpecIcon);
				Img.SetScale(0.75);
				Img.SetPosition(45.5, 75);
				if (GetWeaponCat(class'X2SoldierClass_Amalgamation'.default.TertiarySpecs[TSpec].AllowedWeapons) != "none")
				{
					Weapons @= "/" @ GetWeaponCat(class'X2SoldierClass_Amalgamation'.default.TertiarySpecs[TSpec].AllowedWeapons);
				}
			}

			ScrlText = CLI.Spawn(class'UIScrollingTextField', CLI);
			ScrlText.InitScrollingText(, "Init...");
			ScrlText.SetHTMLText("<font face='$TitleFont' size='24' color='#9acbcb'>" $ CLI.ItemComodity.Title $ "</font>");
			ScrlText.SetWidth(445);
			if (CLI.IsA('UIInventory_ClassListItem'))
			{
				ScrlText.SetWidth(364);
			}
			ScrlText.SetPosition(103, 0);
			OutlineScrollingTextField(ScrlText, 1.5);

			// Clear the text from under the scrolling one
			CLI.ItemComodity.Title = "";

			Text = CLI.Spawn(class'UIText', CLI);
			Text.InitText(, "Init...");
			Text.SetHtmlText("<font size='16' color='#9acbcb' face='$TitleFont'>" $ Weapons $ "</font>");
			Text.SetPosition(10, 130);
			OutlineTextField(Text, 1);
		}
	}
}

static function int FindSpec(array<SpecMetaStruct> Specs, string LocalizedName)
{
	local int i;

	for (i = 0; i < Specs.Length; i++)
	{
		if (Localize(string(Specs[i].Spec), "SpecName", "Amalgamation") == LocalizedName)
		{
			return i;
		}
	}
}

static function string GetWeaponCat(array<SoldierClassWeaponType> AllowedWeapons)
{
	if (AllowedWeapons.Length > 0)
	{
		return Localize("UIWeaponCat", string(AllowedWeapons[0].WeaponType), "Amalgamation");
	}
	return "none";
}

static function OutlineTextField(UIPanel panel, int thickness)
{
	local string path;
	local UIMovie mov;
	path = string(panel.MCPath) $ ".text";
	mov = panel.Movie;

	mov.SetVariableString(path $ ".shadowStyle", "s{" $ thickness $ ",0}{0," $ 
		thickness $ "}{" $ thickness $ "," $ thickness $ "}{" $ -1 * thickness $
		",0}{0," $ -1 * thickness $ "}{" $ -1 * thickness $ "," $ -1 * thickness $
		"}{" $ thickness $ "," $ -1 * thickness $ "}{" $ -1 * thickness $ ","
		$ thickness $ "}t{0,0}");
	mov.SetVariableNumber(path $ ".shadowColor", 0);
	mov.SetVariableNumber(path $ ".shadowBlurX", 1);
	mov.SetVariableNumber(path $ ".shadowBlurY", 1);
	mov.SetVariableNumber(path $ ".shadowStrength", thickness);
	mov.SetVariableNumber(path $ ".shadowAngle", 0);
	mov.SetVariableNumber(path $ ".shadowAlpha", 0.5);
	mov.SetVariableNumber(path $ ".shadowDistance", 0);
}

static function OutlineScrollingTextField(UIPanel panel, float thickness)
{
	local string path;
	local UIMovie mov;
	path = string(panel.MCPath) $ ".textField";
	mov = panel.Movie;

	mov.SetVariableString(path $ ".shadowStyle", "s{" $ thickness $ ",0}{0," $ 
		thickness $ "}{" $ thickness $ "," $ thickness $ "}{" $ -1 * thickness $
		",0}{0," $ -1 * thickness $ "}{" $ -1 * thickness $ "," $ -1 * thickness $
		"}{" $ thickness $ "," $ -1 * thickness $ "}{" $ -1 * thickness $ ","
		$ thickness $ "}t{0,0}");
	mov.SetVariableNumber(path $ ".shadowColor", 0);
	mov.SetVariableNumber(path $ ".shadowBlurX", 1);
	mov.SetVariableNumber(path $ ".shadowBlurY", 1);
	mov.SetVariableNumber(path $ ".shadowStrength", thickness);
	mov.SetVariableNumber(path $ ".shadowAngle", 0);
	mov.SetVariableNumber(path $ ".shadowAlpha", 0.5);
	mov.SetVariableNumber(path $ ".shadowDistance", 0);
}
