// HL dynamic class info
class X2EventListener_AmalgamationDynamicClassInfo extends X2EventListener dependson(X2SoldierClass_Amalgamation);

`define LogError(message) `LOG(`message, true, 'Amalgamation LISTENER ERROR')
`define LogInfo(message) `LOG(`message, true, 'Amalgamation LISTENER INFO')
`define LogDebug(message) `LOG(`message, class'X2SoldierClass_Amalgamation'.default.LogDebug, 'Amalgamation LISTENER DEBUG')

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;

    Templates.AddItem(CreateClassInfoListener());

    return Templates;
}

final static function X2EventListenerTemplate CreateClassInfoListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'AmalgamClassInfoListener');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('SoldierClassIcon', DynamicInfoFunction, ELD_Immediate);
	Template.AddCHEvent('SoldierClassDisplayName', DynamicInfoFunction, ELD_Immediate);
	Template.AddCHEvent('SoldierClassSummary', DynamicInfoFunction, ELD_Immediate);

	return Template;
}

final static function EventListenerReturn DynamicInfoFunction(out Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local XComGameState_Unit UnitState;
	local SpecMetaStruct Spec;

	UnitState = XComGameState_Unit(EventSource);

	// check if unit is amalgam
	if (class'X2SoldierClass_Amalgamation'.default.AmalgamationClasses.find(UnitState.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
		`LogDebug("Not Amalgam" @ UnitState.GetSoldierClassTemplateName());
		return ELR_NoInterrupt;
	}

	Spec = class'X2SoldierClass_Amalgamation'.static.FindMostInvestedSpec(UnitState);

	Tuple = XComLWTuple(EventData);

	switch (Event)
	{
		case 'SoldierClassIcon':
			Tuple.Data[0].s = Spec.SpecIcon;
			break;

		case 'SoldierClassDisplayName':
			Tuple.Data[0].s = Localize(string(Spec.Spec), "SpecName", "Amalgamation");
			break;

		case 'SoldierClassSummary':
			Tuple.Data[0].s = Localize(string(Spec.Spec), "SpecSummary", "Amalgamation");
			break;

		default:
			`LogError("Invalid event" @ Event);
			break;
	}

    return ELR_NoInterrupt;
}
