//OrderControl.uc (Standalone) revision 1.1
class OrderControl extends Object;

static function X2DownloadableContentInfo GetMyInstance(string DLCName) {
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		//`log("LOOKING AT DLC: " $ DLCInfo.DLCIdentifier); 

		if (DLCInfo.DLCIdentifier == DLCName) {
			return DLCInfo;
		}
	}
	
	return none;
}

static function bool CheckForActiveMod(string DLCName) {
	local string CurrentMod;

	foreach class'XComModOptions'.default.ActiveMods(CurrentMod) {
		if (CurrentMod == DLCName) {
			return true;
		}
	}

	return false;
}