Scriptname TFDCreatureTeammateBridge extends Quest

ReferenceAlias Property Teammate01 Auto
ReferenceAlias Property Teammate02 Auto
ReferenceAlias Property Teammate03 Auto
ReferenceAlias Property Teammate04 Auto
ReferenceAlias Property Teammate05 Auto
ReferenceAlias Property Teammate06 Auto

Faction Property PlayerFollowerFaction Auto
Faction Property CurrentFollowerFaction Auto

TFDPlayerTeammateQuestScript Property Registry Auto

Bool Property ApplyPlayerTeammateFlag = True Auto
Bool Property ApplyFollowerFactions = True Auto
Bool Property AllowAutoPackageEval = True Auto
Bool Property EnableTeammateRename = True Auto
String Property TeammateNamePrefix = "Tamed " Auto
Float Property UpdateInterval = 1.00 Auto
Float Property PostLoadRetryInterval = 0.50 Auto
Int Property PostLoadRetryCount = 6 Auto

String _originalName01 = ""
String _originalName02 = ""
String _originalName03 = ""
String _originalName04 = ""
String _originalName05 = ""
String _originalName06 = ""
Int _postLoadRetriesRemaining = 0

Function DetachFromTameBridge(Actor a)
	If a == None
		Return
	EndIf

	a.SendModEvent("TFDTameUnassign")
EndFunction

Function RegisterEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDCreatureTeammateAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDCreatureTeammateUnassign", "OnBridgeEvent")
	RegisterForModEvent("TFDCreatureTeammateClearAll", "OnBridgeEvent")
	TraceDebug("RegisterEvents done")
EndFunction

Function QueueNormalUpdate()
	RegisterForSingleUpdate(UpdateInterval)
EndFunction

Function QueuePostLoadRetry()
	RegisterForSingleUpdate(PostLoadRetryInterval)
EndFunction

Event OnInit()
	TraceDebug("OnInit")
	RegisterEvents()
	_postLoadRetriesRemaining = 0
	QueueNormalUpdate()
EndEvent

Event OnPlayerLoadGame()
	TraceDebug("OnPlayerLoadGame -> keep aliases + RegisterEvents")
	RegisterEvents()
	_postLoadRetriesRemaining = PostLoadRetryCount
	QueuePostLoadRetry()
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	TraceDebug("OnBridgeEvent name=" + eventName + " sender=" + FormLabel(sender))

	If eventName == "TFDCreatureTeammateAssign"
		Actor aAssign = sender as Actor
		If aAssign != None
			AssignActor(aAssign)
		Else
			TraceDebug("Assign ignored: sender is not Actor")
		EndIf
		Return
	EndIf

	If eventName == "TFDCreatureTeammateUnassign"
		Actor aClear = sender as Actor
		If aClear != None
			ClearActor(aClear)
		Else
			TraceDebug("Unassign ignored: sender is not Actor")
		EndIf
		Return
	EndIf

	If eventName == "TFDCreatureTeammateClearAll"
		ClearAll()
		Return
	EndIf

	TraceDebug("Unknown bridge event ignored")
EndEvent

Event OnUpdate()
	MaintainAllActors()

	If _postLoadRetriesRemaining > 0
		_postLoadRetriesRemaining -= 1
		QueuePostLoadRetry()
		Return
	EndIf

	QueueNormalUpdate()
EndEvent

Bool Function AssignActor(Actor a)
	If a == None
		TraceDebug("AssignActor ignored: actor=None")
		Return False
	EndIf

	TraceDebug("AssignActor begin actor=" + ActorLabel(a))
	PruneInvalidSlots()
	DetachFromTameBridge(a)

	ReferenceAlias existing = FindSlotHolding(a)
	If existing != None
		TraceDebug("AssignActor actor already held by " + SlotName(existing))
		ApplyTeammateState(a, existing)
		If Registry != None
			Registry.RegisterOrRefreshTeammate(a)
		EndIf
		If AllowAutoPackageEval
			PrimeTeammateAI(a)
		EndIf
		Return True
	EndIf

	ReferenceAlias slot = FindFreeSlot()
	If slot == None
		TraceDebug("AssignActor failed: no free slot")
		DumpSlots("AssignActor no free slot")
		Return False
	EndIf

	slot.ForceRefTo(a)

	If slot.GetReference() == a
		TraceDebug("AssignActor ForceRefTo success slot=" + SlotName(slot) + " actor=" + ActorLabel(a))
	Else
		TraceDebug("AssignActor ForceRefTo verify FAILED slot=" + SlotName(slot) + " now=" + FormLabel(slot.GetReference()))
		Return False
	EndIf

	ApplyTeammateState(a, slot)

	If Registry != None
		Registry.RegisterOrRefreshTeammate(a)
	EndIf

	If AllowAutoPackageEval
		PrimeTeammateAI(a)
	EndIf

	DumpSlots("AssignActor after ForceRefTo")
	Return True
EndFunction

Bool Function ClearActor(Actor a)
	If a == None
		TraceDebug("ClearActor ignored: actor=None")
		Return False
	EndIf

	TraceDebug("ClearActor begin actor=" + ActorLabel(a))

	ReferenceAlias slot = FindSlotHolding(a)
	If slot == None
		TraceDebug("ClearActor no slot holds actor=" + ActorLabel(a))
		DumpSlots("ClearActor no slot")
		RestoreNormalAI(a, None)
		Return False
	EndIf

	RestoreNormalAI(a, slot)

	If slot.GetReference() != None
		slot.Clear()
		TraceDebug("ClearActor cleared slot=" + SlotName(slot))
	EndIf

	If Registry != None
		Registry.UnregisterTeammate(a)
	EndIf

	DumpSlots("ClearActor after clear")
	Return True
EndFunction

Function ClearAll()
	TraceDebug("ClearAll begin")
	DumpSlots("ClearAll before")

	Actor a1 = GetAliasActor(Teammate01)
	Actor a2 = GetAliasActor(Teammate02)
	Actor a3 = GetAliasActor(Teammate03)
	Actor a4 = GetAliasActor(Teammate04)
	Actor a5 = GetAliasActor(Teammate05)
	Actor a6 = GetAliasActor(Teammate06)

	RestoreNormalAI(a1, Teammate01)
	RestoreNormalAI(a2, Teammate02)
	RestoreNormalAI(a3, Teammate03)
	RestoreNormalAI(a4, Teammate04)
	RestoreNormalAI(a5, Teammate05)
	RestoreNormalAI(a6, Teammate06)

	ClearAlias(Teammate01)
	ClearAlias(Teammate02)
	ClearAlias(Teammate03)
	ClearAlias(Teammate04)
	ClearAlias(Teammate05)
	ClearAlias(Teammate06)

	If Registry != None
		Registry.UnregisterTeammate(a1)
		Registry.UnregisterTeammate(a2)
		Registry.UnregisterTeammate(a3)
		Registry.UnregisterTeammate(a4)
		Registry.UnregisterTeammate(a5)
		Registry.UnregisterTeammate(a6)
	EndIf

	DumpSlots("ClearAll after")
	TraceDebug("ClearAll end")
EndFunction

Function MaintainAllActors()
	PruneInvalidSlots()
	MaintainAliasActor(Teammate01)
	MaintainAliasActor(Teammate02)
	MaintainAliasActor(Teammate03)
	MaintainAliasActor(Teammate04)
	MaintainAliasActor(Teammate05)
	MaintainAliasActor(Teammate06)
EndFunction

Function MaintainAliasActor(ReferenceAlias al)
	Actor a = GetAliasActor(al)
	If a == None
		Return
	EndIf

	If a.IsDead()
		TraceDebug("MaintainAliasActor dead -> clear alias=" + SlotName(al))
		If Registry != None
			Registry.UnregisterTeammate(a)
		EndIf
		RestoreNormalAI(a, al)
		al.Clear()
		Return
	EndIf

	; Jangan spam detach dari tame bridge setiap tick.
	; Cukup detach saat assign. Kalau actor masih kebawa di tame bridge,
	; bridge tame akan membersihkan sendiri saat actor sudah PlayerTeammate.
	ApplyTeammateState(a, al)

	If Registry != None
		Registry.RegisterOrRefreshTeammate(a)
	EndIf

	If AllowAutoPackageEval
		RefreshTeammateAI(a)
	EndIf
EndFunction

Function PruneInvalidSlots()
	PruneAlias(Teammate01)
	PruneAlias(Teammate02)
	PruneAlias(Teammate03)
	PruneAlias(Teammate04)
	PruneAlias(Teammate05)
	PruneAlias(Teammate06)
EndFunction

Function PruneAlias(ReferenceAlias slot)
	If slot == None
		Return
	EndIf

	ObjectReference ref = slot.GetReference()
	If ref == None
		ClearStoredOriginalName(slot)
		Return
	EndIf

	Actor a = ref as Actor
	If a == None
		TraceDebug("PruneAlias non-actor ref -> clear slot=" + SlotName(slot))
		ClearAlias(slot)
		Return
	EndIf

	If a.IsDead()
		TraceDebug("PruneAlias dead actor -> clear slot=" + SlotName(slot) + " actor=" + ActorLabel(a))
		If Registry != None
			Registry.UnregisterTeammate(a)
		EndIf
		RestoreNormalAI(a, slot)
		ClearAlias(slot)
	EndIf
EndFunction

Function ApplyTeammateState(Actor a, ReferenceAlias slot)
	If a == None
		Return
	EndIf

	If ApplyFollowerFactions
		If CurrentFollowerFaction != None
			If !a.IsInFaction(CurrentFollowerFaction)
				a.AddToFaction(CurrentFollowerFaction)
			EndIf
		EndIf

		If PlayerFollowerFaction != None
			If !a.IsInFaction(PlayerFollowerFaction)
				a.AddToFaction(PlayerFollowerFaction)
			EndIf
		EndIf
	EndIf

	If ApplyPlayerTeammateFlag
		a.SetPlayerTeammate(True, False)
	EndIf

	ApplyDisplayName(a, slot)
EndFunction

Function RestoreNormalAI(Actor a, ReferenceAlias slot)
	If a == None
		Return
	EndIf

	RestoreDisplayName(a, slot)

	If ApplyPlayerTeammateFlag
		a.SetPlayerTeammate(False, False)
	EndIf

	If ApplyFollowerFactions
		If CurrentFollowerFaction != None
			If a.IsInFaction(CurrentFollowerFaction)
				a.RemoveFromFaction(CurrentFollowerFaction)
			EndIf
		EndIf

		If PlayerFollowerFaction != None
			If a.IsInFaction(PlayerFollowerFaction)
				a.RemoveFromFaction(PlayerFollowerFaction)
			EndIf
		EndIf
	EndIf

	If AllowAutoPackageEval
		a.EvaluatePackage()
	EndIf
EndFunction

Function PrimeTeammateAI(Actor a)
	If a == None
		Return
	EndIf

	; Jangan paksa StopCombat di sini.
	; Kalau actor baru dipromote saat combat masih berjalan,
	; StopCombat justru bikin dia gagal bantu player.
	a.StopCombatAlarm()
	a.EvaluatePackage()
EndFunction

Function RefreshTeammateAI(Actor a)
	If a == None
		Return
	EndIf

	; Jangan StopCombat di sini, biar dia bisa bantu player lawan musuh
	a.EvaluatePackage()
EndFunction

Function ApplyDisplayName(Actor a, ReferenceAlias slot)
	If !EnableTeammateRename
		Return
	EndIf

	If a == None || slot == None
		Return
	EndIf

	String storedOriginal = GetStoredOriginalName(slot)
	String currentName = a.GetDisplayName()

	If storedOriginal == ""
		If currentName == ""
			storedOriginal = "Creature"
		Else
			storedOriginal = currentName
		EndIf
		SetStoredOriginalName(slot, storedOriginal)
	EndIf

	String desiredName = TeammateNamePrefix + storedOriginal
	If currentName != desiredName
		a.SetDisplayName(desiredName, True)
	EndIf
EndFunction

Function RestoreDisplayName(Actor a, ReferenceAlias slot)
	If !EnableTeammateRename
		Return
	EndIf

	If a == None || slot == None
		Return
	EndIf

	String storedOriginal = GetStoredOriginalName(slot)
	If storedOriginal != ""
		a.SetDisplayName(storedOriginal, True)
	EndIf

	ClearStoredOriginalName(slot)
EndFunction

ReferenceAlias Function FindFreeSlot()
	If Teammate01 != None
		If Teammate01.GetReference() == None
			Return Teammate01
		EndIf
	EndIf

	If Teammate02 != None
		If Teammate02.GetReference() == None
			Return Teammate02
		EndIf
	EndIf

	If Teammate03 != None
		If Teammate03.GetReference() == None
			Return Teammate03
		EndIf
	EndIf

	If Teammate04 != None
		If Teammate04.GetReference() == None
			Return Teammate04
		EndIf
	EndIf

	If Teammate05 != None
		If Teammate05.GetReference() == None
			Return Teammate05
		EndIf
	EndIf

	If Teammate06 != None
		If Teammate06.GetReference() == None
			Return Teammate06
		EndIf
	EndIf

	Return None
EndFunction

ReferenceAlias Function FindSlotHolding(Actor a)
	If a == None
		Return None
	EndIf

	If Teammate01 != None
		If Teammate01.GetReference() == a
			Return Teammate01
		EndIf
	EndIf

	If Teammate02 != None
		If Teammate02.GetReference() == a
			Return Teammate02
		EndIf
	EndIf

	If Teammate03 != None
		If Teammate03.GetReference() == a
			Return Teammate03
		EndIf
	EndIf

	If Teammate04 != None
		If Teammate04.GetReference() == a
			Return Teammate04
		EndIf
	EndIf

	If Teammate05 != None
		If Teammate05.GetReference() == a
			Return Teammate05
		EndIf
	EndIf

	If Teammate06 != None
		If Teammate06.GetReference() == a
			Return Teammate06
		EndIf
	EndIf

	Return None
EndFunction

Bool Function HasFreeSlot()
	If FindFreeSlot() != None
		Return True
	EndIf
	Return False
EndFunction

Bool Function Contains(Actor a)
	If FindSlotHolding(a) != None
		Return True
	EndIf
	Return False
EndFunction

Int Function GetUsedSlotCount()
	Int total = 0

	If Teammate01 != None
		If Teammate01.GetReference() != None
			total += 1
		EndIf
	EndIf

	If Teammate02 != None
		If Teammate02.GetReference() != None
			total += 1
		EndIf
	EndIf

	If Teammate03 != None
		If Teammate03.GetReference() != None
			total += 1
		EndIf
	EndIf

	If Teammate04 != None
		If Teammate04.GetReference() != None
			total += 1
		EndIf
	EndIf

	If Teammate05 != None
		If Teammate05.GetReference() != None
			total += 1
		EndIf
	EndIf

	If Teammate06 != None
		If Teammate06.GetReference() != None
			total += 1
		EndIf
	EndIf

	Return total
EndFunction

Actor Function GetAliasActor(ReferenceAlias al)
	If al == None
		Return None
	EndIf
	Return al.GetActorReference()
EndFunction

Function ClearAlias(ReferenceAlias al)
	If al == None
		Return
	EndIf

	If al.GetReference() != None
		al.Clear()
	EndIf

	ClearStoredOriginalName(al)
EndFunction

String Function GetStoredOriginalName(ReferenceAlias slot)
	If slot == None
		Return ""
	EndIf

	If slot == Teammate01
		Return _originalName01
	ElseIf slot == Teammate02
		Return _originalName02
	ElseIf slot == Teammate03
		Return _originalName03
	ElseIf slot == Teammate04
		Return _originalName04
	ElseIf slot == Teammate05
		Return _originalName05
	ElseIf slot == Teammate06
		Return _originalName06
	EndIf

	Return ""
EndFunction

Function SetStoredOriginalName(ReferenceAlias slot, String value)
	If slot == None
		Return
	EndIf

	If slot == Teammate01
		_originalName01 = value
	ElseIf slot == Teammate02
		_originalName02 = value
	ElseIf slot == Teammate03
		_originalName03 = value
	ElseIf slot == Teammate04
		_originalName04 = value
	ElseIf slot == Teammate05
		_originalName05 = value
	ElseIf slot == Teammate06
		_originalName06 = value
	EndIf
EndFunction

Function ClearStoredOriginalName(ReferenceAlias slot)
	SetStoredOriginalName(slot, "")
EndFunction

String Function SlotName(ReferenceAlias slot)
	If slot == None
		Return "None"
	EndIf
	Return slot.GetName()
EndFunction

String Function BoolLabel(Bool value)
	If value
		Return "True"
	EndIf
	Return "False"
EndFunction

String Function ActorLabel(Actor a)
	If a == None
		Return "Actor(None)"
	EndIf
	Return a.GetLeveledActorBase().GetName() + " [0x" + IntToHex(a.GetFormID()) + "]"
EndFunction

String Function FormLabel(Form akForm)
	If akForm == None
		Return "Form(None)"
	EndIf
	Return akForm.GetName() + " [0x" + IntToHex(akForm.GetFormID()) + "]"
EndFunction

Function DumpSlots(String reason)
	TraceDebug("DumpSlots reason=" + reason + " used=" + GetUsedSlotCount())
	TraceDebug("  01=" + FormLabel(Teammate01.GetReference()))
	TraceDebug("  02=" + FormLabel(Teammate02.GetReference()))
	TraceDebug("  03=" + FormLabel(Teammate03.GetReference()))
	TraceDebug("  04=" + FormLabel(Teammate04.GetReference()))
	TraceDebug("  05=" + FormLabel(Teammate05.GetReference()))
	TraceDebug("  06=" + FormLabel(Teammate06.GetReference()))
EndFunction

String Function IntToHex(Int value)
	Int n = value
	If n < 0
		n = 0
	EndIf

	String digits = "0123456789ABCDEF"
	String out = ""
	Int i = 0
	While i < 8
		Int nibble = n % 16
		out = StringUtil.Substring(digits, nibble, 1) + out
		n = n / 16
		i += 1
	EndWhile
	Return out
EndFunction

Function TraceDebug(String msg)
	Debug.Trace("[TFD][CreatureTeammateBridge] " + msg)
EndFunction