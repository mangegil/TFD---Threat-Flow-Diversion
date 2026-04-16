Scriptname TFDTameBridge extends Quest

ReferenceAlias Property Tame01 Auto
ReferenceAlias Property Tame02 Auto
ReferenceAlias Property Tame03 Auto
ReferenceAlias Property Tame04 Auto
ReferenceAlias Property Tame05 Auto
ReferenceAlias Property Tame06 Auto
ReferenceAlias Property Tame07 Auto
ReferenceAlias Property Tame08 Auto
ReferenceAlias Property Tame09 Auto
ReferenceAlias Property Tame10 Auto

Bool Property AllowAutoPackageEval = True Auto
Bool Property ClearAllOnPlayerLoadGame = True Auto
Float Property UpdateInterval = 0.50 Auto
Float Property PostLoadRetryInterval = 0.50 Auto
Int Property PostLoadRetryCount = 4 Auto

Int _postLoadRetriesRemaining = 0

Bool Function IsPromotedFollowerActor(Actor a)
	If a == None
		Return False
	EndIf

	If a.IsPlayerTeammate()
		Return True
	EndIf

	Return False
EndFunction

Function RegisterEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDTameAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDTameUnassign", "OnBridgeEvent")
	RegisterForModEvent("TFDTameClearAll", "OnBridgeEvent")
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
	TraceDebug("OnPlayerLoadGame")
	RegisterEvents()

	If ClearAllOnPlayerLoadGame
		TraceDebug("OnPlayerLoadGame -> ClearAll")
		ClearAll()
		_postLoadRetriesRemaining = 0
		QueueNormalUpdate()
		Return
	EndIf

	TraceDebug("OnPlayerLoadGame -> keep aliases + retry")
	_postLoadRetriesRemaining = PostLoadRetryCount
	QueuePostLoadRetry()
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	TraceDebug("OnBridgeEvent name=" + eventName + " sender=" + FormLabel(sender))

	If eventName == "TFDTameAssign"
		Actor aAssign = sender as Actor
		If aAssign != None
			AssignActor(aAssign)
		Else
			TraceDebug("Assign ignored: sender is not Actor")
		EndIf
		Return
	EndIf

	If eventName == "TFDTameUnassign"
		Actor aClear = sender as Actor
		If aClear != None
			ClearActor(aClear)
		Else
			TraceDebug("Unassign ignored: sender is not Actor")
		EndIf
		Return
	EndIf

	If eventName == "TFDTameClearAll"
		ClearAll()
		Return
	EndIf

	TraceDebug("Unknown bridge event ignored")
EndEvent

Event OnUpdate()
	PruneInvalidSlots()
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

	If IsPromotedFollowerActor(a)
		TraceDebug("AssignActor ignored: actor already promoted follower actor=" + ActorLabel(a))
		ClearActor(a)
		Return False
	EndIf

	PruneInvalidSlots()
	TraceDebug("AssignActor begin actor=" + ActorLabel(a))

	ReferenceAlias existing = FindSlotHolding(a)
	If existing != None
		TraceDebug("AssignActor actor already held by " + SlotName(existing))
		PrimeTameAI(a)
		Return True
	EndIf

	ReferenceAlias slot = FindFreeSlot()
	If slot == None
		TraceDebug("AssignActor failed: no free slot used=" + GetUsedSlotCount())
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

	PrimeTameAI(a)
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
		RestoreNormalAI(a)
		Return False
	EndIf

	If slot.GetReference() != None
		slot.Clear()
		TraceDebug("ClearActor cleared slot=" + SlotName(slot))
	EndIf

	RestoreNormalAI(a)
	DumpSlots("ClearActor after clear")
	Return True
EndFunction

Function ClearAll()
	TraceDebug("ClearAll begin")
	DumpSlots("ClearAll before")

	Actor a1 = GetAliasActor(Tame01)
	Actor a2 = GetAliasActor(Tame02)
	Actor a3 = GetAliasActor(Tame03)
	Actor a4 = GetAliasActor(Tame04)
	Actor a5 = GetAliasActor(Tame05)
	Actor a6 = GetAliasActor(Tame06)
	Actor a7 = GetAliasActor(Tame07)
	Actor a8 = GetAliasActor(Tame08)
	Actor a9 = GetAliasActor(Tame09)
	Actor a10 = GetAliasActor(Tame10)

	ClearAlias(Tame01)
	ClearAlias(Tame02)
	ClearAlias(Tame03)
	ClearAlias(Tame04)
	ClearAlias(Tame05)
	ClearAlias(Tame06)
	ClearAlias(Tame07)
	ClearAlias(Tame08)
	ClearAlias(Tame09)
	ClearAlias(Tame10)

	RestoreNormalAI(a1)
	RestoreNormalAI(a2)
	RestoreNormalAI(a3)
	RestoreNormalAI(a4)
	RestoreNormalAI(a5)
	RestoreNormalAI(a6)
	RestoreNormalAI(a7)
	RestoreNormalAI(a8)
	RestoreNormalAI(a9)
	RestoreNormalAI(a10)

	DumpSlots("ClearAll after")
	TraceDebug("ClearAll end")
EndFunction

Function MaintainAllActors()
	MaintainAliasActor(Tame01)
	MaintainAliasActor(Tame02)
	MaintainAliasActor(Tame03)
	MaintainAliasActor(Tame04)
	MaintainAliasActor(Tame05)
	MaintainAliasActor(Tame06)
	MaintainAliasActor(Tame07)
	MaintainAliasActor(Tame08)
	MaintainAliasActor(Tame09)
	MaintainAliasActor(Tame10)
EndFunction

Function MaintainAliasActor(ReferenceAlias al)
	Actor a = GetAliasActor(al)
	If a == None
		Return
	EndIf

	If IsPromotedFollowerActor(a)
		TraceDebug("MaintainAliasActor promoted follower -> clear alias=" + SlotName(al) + " actor=" + ActorLabel(a))
		al.Clear()
		Return
	EndIf

	If a.IsDead()
		TraceDebug("MaintainAliasActor dead -> clear alias=" + SlotName(al))
		al.Clear()
		Return
	EndIf

	PrimeTameAI(a)
EndFunction

Function PrimeTameAI(Actor a)
	If a == None
		TraceDebug("PrimeTameAI ignored: actor=None")
		Return
	EndIf

	If IsPromotedFollowerActor(a)
		TraceDebug("PrimeTameAI ignored: promoted follower actor=" + ActorLabel(a))
		Return
	EndIf

	TraceDebug("PrimeTameAI begin actor=" + ActorLabel(a) + " loaded=" + BoolLabel(a.Is3DLoaded()) + " inCombat=" + BoolLabel(a.IsInCombat()) + " weaponDrawn=" + BoolLabel(a.IsWeaponDrawn()))

	If !a.Is3DLoaded()
		TraceDebug("PrimeTameAI skip: actor 3D not loaded")
		Return
	EndIf

	If a.IsInCombat()
		a.StopCombat()
		a.StopCombatAlarm()
		TraceDebug("PrimeTameAI StopCombat")
	EndIf

	If a.IsWeaponDrawn()
		a.SheatheWeapon()
		TraceDebug("PrimeTameAI SheatheWeapon")
	EndIf

	If AllowAutoPackageEval
		a.EvaluatePackage()
		TraceDebug("PrimeTameAI EvaluatePackage done")
	EndIf
EndFunction

Function KickApproachAI(Actor a)
	PrimeTameAI(a)
EndFunction

Function RestoreNormalAI(Actor a)
	If a == None
		Return
	EndIf

	If IsPromotedFollowerActor(a)
		TraceDebug("RestoreNormalAI ignored: promoted follower actor=" + ActorLabel(a))
		Return
	EndIf

	TraceDebug("RestoreNormalAI begin actor=" + ActorLabel(a) + " loaded=" + BoolLabel(a.Is3DLoaded()))

	If !a.Is3DLoaded()
		TraceDebug("RestoreNormalAI skip: actor 3D not loaded")
		Return
	EndIf

	; Jangan paksa StopCombat di sini.
	; Untuk release/unassign, native yang nentuin rehostile / calm final-nya.
	If AllowAutoPackageEval
		a.EvaluatePackage()
		TraceDebug("RestoreNormalAI EvaluatePackage done")
	EndIf
EndFunction

Function PruneInvalidSlots()
	PruneAlias(Tame01)
	PruneAlias(Tame02)
	PruneAlias(Tame03)
	PruneAlias(Tame04)
	PruneAlias(Tame05)
	PruneAlias(Tame06)
	PruneAlias(Tame07)
	PruneAlias(Tame08)
	PruneAlias(Tame09)
	PruneAlias(Tame10)
EndFunction

Function PruneAlias(ReferenceAlias al)
	If al == None
		Return
	EndIf

	ObjectReference ref = al.GetReference()
	If ref == None
		Return
	EndIf

	Actor a = ref as Actor
	If a == None
		TraceDebug("PruneAlias non-actor ref -> clear alias=" + SlotName(al))
		al.Clear()
		Return
	EndIf

	If a.IsDead()
		TraceDebug("PruneAlias dead actor -> clear alias=" + SlotName(al) + " actor=" + ActorLabel(a))
		al.Clear()
		Return
	EndIf

	If IsPromotedFollowerActor(a)
		TraceDebug("PruneAlias promoted follower -> clear alias=" + SlotName(al) + " actor=" + ActorLabel(a))
		al.Clear()
		Return
	EndIf
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

	If Tame01 != None && Tame01.GetReference() != None
		total += 1
	EndIf
	If Tame02 != None && Tame02.GetReference() != None
		total += 1
	EndIf
	If Tame03 != None && Tame03.GetReference() != None
		total += 1
	EndIf
	If Tame04 != None && Tame04.GetReference() != None
		total += 1
	EndIf
	If Tame05 != None && Tame05.GetReference() != None
		total += 1
	EndIf
	If Tame06 != None && Tame06.GetReference() != None
		total += 1
	EndIf
	If Tame07 != None && Tame07.GetReference() != None
		total += 1
	EndIf
	If Tame08 != None && Tame08.GetReference() != None
		total += 1
	EndIf
	If Tame09 != None && Tame09.GetReference() != None
		total += 1
	EndIf
	If Tame10 != None && Tame10.GetReference() != None
		total += 1
	EndIf

	Return total
EndFunction

Actor Function GetActorBySlotIndex(Int slotIndex)
	If slotIndex == 0
		Return GetAliasActor(Tame01)
	ElseIf slotIndex == 1
		Return GetAliasActor(Tame02)
	ElseIf slotIndex == 2
		Return GetAliasActor(Tame03)
	ElseIf slotIndex == 3
		Return GetAliasActor(Tame04)
	ElseIf slotIndex == 4
		Return GetAliasActor(Tame05)
	ElseIf slotIndex == 5
		Return GetAliasActor(Tame06)
	ElseIf slotIndex == 6
		Return GetAliasActor(Tame07)
	ElseIf slotIndex == 7
		Return GetAliasActor(Tame08)
	ElseIf slotIndex == 8
		Return GetAliasActor(Tame09)
	ElseIf slotIndex == 9
		Return GetAliasActor(Tame10)
	EndIf

	Return None
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
EndFunction

ReferenceAlias Function FindSlotHolding(Actor a)
	If a == None
		Return None
	EndIf

	If GetAliasActor(Tame01) == a
		Return Tame01
	EndIf
	If GetAliasActor(Tame02) == a
		Return Tame02
	EndIf
	If GetAliasActor(Tame03) == a
		Return Tame03
	EndIf
	If GetAliasActor(Tame04) == a
		Return Tame04
	EndIf
	If GetAliasActor(Tame05) == a
		Return Tame05
	EndIf
	If GetAliasActor(Tame06) == a
		Return Tame06
	EndIf
	If GetAliasActor(Tame07) == a
		Return Tame07
	EndIf
	If GetAliasActor(Tame08) == a
		Return Tame08
	EndIf
	If GetAliasActor(Tame09) == a
		Return Tame09
	EndIf
	If GetAliasActor(Tame10) == a
		Return Tame10
	EndIf

	Return None
EndFunction

ReferenceAlias Function FindFreeSlot()
	If Tame01 != None && Tame01.GetReference() == None
		Return Tame01
	EndIf
	If Tame02 != None && Tame02.GetReference() == None
		Return Tame02
	EndIf
	If Tame03 != None && Tame03.GetReference() == None
		Return Tame03
	EndIf
	If Tame04 != None && Tame04.GetReference() == None
		Return Tame04
	EndIf
	If Tame05 != None && Tame05.GetReference() == None
		Return Tame05
	EndIf
	If Tame06 != None && Tame06.GetReference() == None
		Return Tame06
	EndIf
	If Tame07 != None && Tame07.GetReference() == None
		Return Tame07
	EndIf
	If Tame08 != None && Tame08.GetReference() == None
		Return Tame08
	EndIf
	If Tame09 != None && Tame09.GetReference() == None
		Return Tame09
	EndIf
	If Tame10 != None && Tame10.GetReference() == None
		Return Tame10
	EndIf

	Return None
EndFunction

Function DumpSlots(String reason)
	TraceDebug("DumpSlots reason=" + reason 		+ " | Tame01=" + FormLabel(Tame01.GetReference()) 		+ " | Tame02=" + FormLabel(Tame02.GetReference()) 		+ " | Tame03=" + FormLabel(Tame03.GetReference()) 		+ " | Tame04=" + FormLabel(Tame04.GetReference()) 		+ " | Tame05=" + FormLabel(Tame05.GetReference()) 		+ " | Tame06=" + FormLabel(Tame06.GetReference()) 		+ " | Tame07=" + FormLabel(Tame07.GetReference()) 		+ " | Tame08=" + FormLabel(Tame08.GetReference()) 		+ " | Tame09=" + FormLabel(Tame09.GetReference()) 		+ " | Tame10=" + FormLabel(Tame10.GetReference()))
EndFunction

String Function SlotName(ReferenceAlias al)
	If al == None
		Return "None"
	EndIf

	If al == Tame01
		Return "Tame01"
	EndIf
	If al == Tame02
		Return "Tame02"
	EndIf
	If al == Tame03
		Return "Tame03"
	EndIf
	If al == Tame04
		Return "Tame04"
	EndIf
	If al == Tame05
		Return "Tame05"
	EndIf
	If al == Tame06
		Return "Tame06"
	EndIf
	If al == Tame07
		Return "Tame07"
	EndIf
	If al == Tame08
		Return "Tame08"
	EndIf
	If al == Tame09
		Return "Tame09"
	EndIf
	If al == Tame10
		Return "Tame10"
	EndIf

	Return "UnknownSlot"
EndFunction

String Function ActorLabel(Actor a)
	If a == None
		Return "None"
	EndIf

	Return a + " | dead=" + BoolLabel(a.IsDead()) + " | loaded=" + BoolLabel(a.Is3DLoaded())
EndFunction

String Function FormLabel(Form f)
	If f == None
		Return "None"
	EndIf
	Return f as String
EndFunction

String Function BoolLabel(Bool b)
	If b
		Return "1"
	EndIf
	Return "0"
EndFunction

Function TraceDebug(String s)
	Debug.Trace("[TFDTameBridge] " + s)
EndFunction