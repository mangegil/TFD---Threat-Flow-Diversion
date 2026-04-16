Scriptname TFDCaptiveBridge extends Quest

ReferenceAlias Property OwnerCaptor Auto
ReferenceAlias Property CaptiveMarker Auto
ReferenceAlias Property EscapeDoor Auto
ReferenceAlias Property LootTarget Auto

Bool Property AllowAutoPackageEval = True Auto
Bool Property ClearAllOnPlayerLoadGame = False Auto
Float Property UpdateInterval = 0.10 Auto
Float Property DialogueCloseReleaseDelay = 0.10 Auto
Float Property CallCooldownSeconds = 60.0 Auto
Float Property PostLoadRetryInterval = 0.75 Auto
Int Property PostLoadRetryCount = 4 Auto

Bool captiveDialogueOwned = False
Bool captiveChoiceCommitted = False
Bool sawDialogueOpen = False
Bool dialogueClosePending = False

Float dialogueCloseResolveAt = 0.0
Float captiveCallCooldownUntil = 0.0

Actor currentCaptor
Actor lastDialogueCaptor
Actor dialogueCloseCaptor
Actor ownedDialogueCaptor
Int pendingPostLoadRetries = 0

Function RegisterEvents()
	UnregisterForAllModEvents()
	UnregisterForMenu("Dialogue Menu")
	UnregisterForMenu("DialogueMenu")

	RegisterForModEvent("TFDCaptiveAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDCaptiveClearAll", "OnBridgeEvent")
	RegisterForModEvent("TFDCaptiveUnassign", "OnBridgeEvent")

	RegisterForMenu("Dialogue Menu")
	RegisterForMenu("DialogueMenu")
EndFunction

Event OnInit()
	RegisterEvents()
EndEvent

Event OnPlayerLoadGame()
	If ClearAllOnPlayerLoadGame
		ClearAll()
	Else
		ResetDialogueStateOnLoad()
		PruneStaleRuntimeRefs()
	EndIf
	ClearCallCooldown()
	RegisterEvents()
	pendingPostLoadRetries = PostLoadRetryCount
	RegisterForSingleUpdate(PostLoadRetryInterval)
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	If eventName == "TFDCaptiveAssign"
		Actor aAssign = sender as Actor
		If aAssign != None
			AssignActor(aAssign)
		EndIf
		Return
	EndIf

	If eventName == "TFDCaptiveClearAll"
		ClearAll()
		Return
	EndIf

	If eventName == "TFDCaptiveUnassign"
		Actor aClear = sender as Actor
		If aClear != None
			ClearActor(aClear)
		EndIf
		Return
	EndIf
EndEvent

Event OnMenuOpen(String menuName)
	If !IsDialogueMenuName(menuName)
		Return
	EndIf

	Actor akCaptor = GetResolveCaptor()
	If akCaptor == None
		Return
	EndIf

	sawDialogueOpen = True
	lastDialogueCaptor = akCaptor
	ownedDialogueCaptor = akCaptor
	captiveDialogueOwned = True
	ClearDialogueClosePending()
EndEvent

Event OnMenuClose(String menuName)
	If !IsDialogueMenuName(menuName)
		Return
	EndIf

	If !sawDialogueOpen
		Return
	EndIf

	If captiveChoiceCommitted
		Return
	EndIf

	If GetResolveCaptor() == None
		Return
	EndIf

	QueueDialogueCloseResolve()
EndEvent

Event OnUpdate()
	If pendingPostLoadRetries > 0
		pendingPostLoadRetries -= 1
		PruneStaleRuntimeRefs()
		MaintainOwnerCaptor()
		RegisterForSingleUpdate(PostLoadRetryInterval)
		Return
	EndIf

	If dialogueClosePending
		If IsDialogueMenuOpenNow()
			sawDialogueOpen = True
			ClearDialogueClosePending()
			RegisterForSingleUpdate(UpdateInterval)
			Return
		EndIf

		If Utility.GetCurrentRealTime() < dialogueCloseResolveAt
			RegisterForSingleUpdate(UpdateInterval)
			Return
		EndIf

		If !captiveChoiceCommitted
			ResolveCaptiveDoNothing()
		Else
			ClearDialogueClosePending()
		EndIf

		If ShouldKeepUpdating()
			RegisterForSingleUpdate(UpdateInterval)
		EndIf
		Return
	EndIf

	MaintainOwnerCaptor()

	Actor akCaptor = GetResolveCaptor()
	If akCaptor == None
		Return
	EndIf

	If akCaptor.IsDead()
		ClearActor(akCaptor)
		If ShouldKeepUpdating()
			RegisterForSingleUpdate(UpdateInterval)
		EndIf
		Return
	EndIf

	If IsDialogueMenuOpenNow()
		sawDialogueOpen = True
		lastDialogueCaptor = akCaptor
		ownedDialogueCaptor = akCaptor
		captiveDialogueOwned = True
		ClearDialogueClosePending()
		RegisterForSingleUpdate(UpdateInterval)
		Return
	EndIf

	If sawDialogueOpen && !captiveChoiceCommitted
		QueueDialogueCloseResolve()
		RegisterForSingleUpdate(UpdateInterval)
		Return
	EndIf

	RegisterForSingleUpdate(UpdateInterval)
EndEvent

Function MarkCaptiveDialogueOwned(Actor akCaptor)
	Actor aOwned = akCaptor
	If aOwned == None
		aOwned = GetResolveCaptor()
	EndIf

	If aOwned != None
		currentCaptor = aOwned
		lastDialogueCaptor = aOwned
		ownedDialogueCaptor = aOwned
		SetOwnerCaptor(aOwned)
	EndIf

	captiveDialogueOwned = True
	captiveChoiceCommitted = False
	sawDialogueOpen = IsDialogueMenuOpenNow()
	ClearDialogueClosePending()
EndFunction

Function ClearCaptiveDialogueOwned()
	captiveDialogueOwned = False
	captiveChoiceCommitted = False
	sawDialogueOpen = False
	ownedDialogueCaptor = None
	ClearDialogueClosePending()
EndFunction

Function ResetDialogueStateOnLoad()
	currentCaptor = GetOwnerCaptor()
	lastDialogueCaptor = None
	ownedDialogueCaptor = None
	dialogueCloseCaptor = None
	captiveDialogueOwned = False
	captiveChoiceCommitted = False
	sawDialogueOpen = False
	ClearDialogueClosePending()
EndFunction

Function PruneStaleRuntimeRefs()
	Actor ownerActor = GetOwnerCaptor()
	If ownerActor != None && ownerActor.IsDead()
		ClearActor(ownerActor)
	EndIf
EndFunction

Function CommitCaptiveChoice()
	captiveChoiceCommitted = True
	ClearDialogueClosePending()
EndFunction

Function ResolveCaptiveDoNothing()
	If captiveChoiceCommitted
		Return
	EndIf

	captiveChoiceCommitted = True
	ReleaseOwnedCaptorInternal(True)
EndFunction

Function ReleaseOwnedCaptor()
	If !captiveChoiceCommitted
		captiveChoiceCommitted = True
	EndIf

	ReleaseOwnedCaptorInternal(True)
EndFunction

Function ReleaseOwnedCaptorNoCooldown()
	If !captiveChoiceCommitted
		captiveChoiceCommitted = True
	EndIf

	ReleaseOwnedCaptorInternal(False)
EndFunction

Function ReleaseOwnedCaptorInternal(Bool applyCooldown)
	Actor akCaptor = GetResolveCaptor()

	If akCaptor != None
		ClearActor(akCaptor)
	Else
		ClearOwnerCaptor()
	EndIf

	If applyCooldown
		StartCallCooldown()
	EndIf

	ClearCaptiveDialogueOwned()
EndFunction

Function QueueDialogueCloseResolve()
	Actor akCaptor = GetResolveCaptor()
	If akCaptor == None
		Return
	EndIf

	dialogueCloseCaptor = akCaptor
	dialogueClosePending = True
	dialogueCloseResolveAt = Utility.GetCurrentRealTime() + DialogueCloseReleaseDelay
EndFunction

Function ClearDialogueClosePending()
	dialogueClosePending = False
	dialogueCloseResolveAt = 0.0
	dialogueCloseCaptor = None
EndFunction

Function StartCallCooldown()
	captiveCallCooldownUntil = Utility.GetCurrentRealTime() + CallCooldownSeconds
EndFunction

Function ClearCallCooldown()
	captiveCallCooldownUntil = 0.0
EndFunction

Bool Function IsCallCooldownActive()
	Return Utility.GetCurrentRealTime() < captiveCallCooldownUntil
EndFunction

Function AssignActor(Actor a)
	If a == None
		Return
	EndIf

	If a.IsDead()
		Return
	EndIf

	If IsCallCooldownActive()
		Debug.Notification("TFD: No response yet")
		Return
	EndIf

	If currentCaptor == a
		SetOwnerCaptor(a)
		If AllowAutoPackageEval
			KickApproachAI(a)
		EndIf
		RegisterForSingleUpdate(UpdateInterval)
		Return
	EndIf

	If currentCaptor != None
		ClearActor(currentCaptor)
	EndIf

	If !SetOwnerCaptor(a)
		Return
	EndIf

	currentCaptor = a
	lastDialogueCaptor = a
	ownedDialogueCaptor = None
	captiveDialogueOwned = False
	captiveChoiceCommitted = False
	sawDialogueOpen = False
	ClearDialogueClosePending()

	If AllowAutoPackageEval
		KickApproachAI(a)
	EndIf

	RegisterForSingleUpdate(UpdateInterval)
EndFunction

Function ClearActor(Actor a)
	If a == None
		Return
	EndIf

	Actor aliasCaptor = GetOwnerCaptor()
	If aliasCaptor == a
		ClearOwnerCaptor()
	EndIf

	If currentCaptor == a
		currentCaptor = None
	EndIf

	If lastDialogueCaptor == a
		lastDialogueCaptor = None
	EndIf

	If dialogueCloseCaptor == a
		dialogueCloseCaptor = None
	EndIf

	If ownedDialogueCaptor == a
		ownedDialogueCaptor = None
	EndIf

	RestoreNormalAI(a)
EndFunction

Function ClearAll()
	Actor ownerActor = GetOwnerCaptor()

	ClearOwnerCaptor()
	ClearCaptiveMarker()
	ClearEscapeDoor()
	ClearLootTarget()

	RestoreNormalAI(ownerActor)

	currentCaptor = None
	lastDialogueCaptor = None
	ownedDialogueCaptor = None
	captiveDialogueOwned = False
	captiveChoiceCommitted = False
	sawDialogueOpen = False
	ClearDialogueClosePending()
EndFunction

Function MaintainOwnerCaptor()
	Actor a = GetOwnerCaptor()
	If a == None
		Return
	EndIf

	If a.IsDead()
		ClearActor(a)
		Return
	EndIf

	If a.Is3DLoaded()
		If a.IsInCombat()
			a.StopCombat()
			a.StopCombatAlarm()
		EndIf

		If a.IsWeaponDrawn()
			a.SheatheWeapon()
		EndIf

		If AllowAutoPackageEval
			a.EvaluatePackage()
		EndIf
	EndIf
EndFunction

Function KickApproachAI(Actor a)
	If a == None
		Return
	EndIf

	If !a.Is3DLoaded()
		Return
	EndIf

	If a.IsInCombat()
		a.StopCombat()
		a.StopCombatAlarm()
	EndIf

	If a.IsWeaponDrawn()
		a.SheatheWeapon()
	EndIf

	If AllowAutoPackageEval
		a.EvaluatePackage()
	EndIf
EndFunction

Function RestoreNormalAI(Actor a)
	If a == None
		Return
	EndIf

	If !a.Is3DLoaded()
		Return
	EndIf

	a.EvaluatePackage()
EndFunction

Bool Function IsDialogueMenuName(String menuName)
	If menuName == "Dialogue Menu"
		Return True
	EndIf

	If menuName == "DialogueMenu"
		Return True
	EndIf

	Return False
EndFunction

Bool Function IsDialogueMenuOpenNow()
	If UI.IsMenuOpen("Dialogue Menu")
		Return True
	EndIf

	If UI.IsMenuOpen("DialogueMenu")
		Return True
	EndIf

	Return False
EndFunction

Bool Function ShouldKeepUpdating()
	If currentCaptor != None
		Return True
	EndIf

	If dialogueClosePending
		Return True
	EndIf

	If GetCurrentCaptor() != None
		Return True
	EndIf

	Return False
EndFunction

Actor Function GetResolveCaptor()
	If currentCaptor != None
		Return currentCaptor
	EndIf

	If ownedDialogueCaptor != None
		Return ownedDialogueCaptor
	EndIf

	If lastDialogueCaptor != None
		Return lastDialogueCaptor
	EndIf

	If dialogueCloseCaptor != None
		Return dialogueCloseCaptor
	EndIf

	Return GetCurrentCaptor()
EndFunction

Bool Function SetOwnerCaptor(Actor akCaptor)
	If OwnerCaptor == None
		Return False
	EndIf

	If akCaptor == None
		ClearOwnerCaptor()
		Return False
	EndIf

	OwnerCaptor.ForceRefTo(akCaptor)
	Return OwnerCaptor.GetReference() == akCaptor
EndFunction

Function ClearOwnerCaptor()
	If OwnerCaptor == None
		Return
	EndIf

	If OwnerCaptor.GetReference() != None
		OwnerCaptor.Clear()
	EndIf
EndFunction

Actor Function GetOwnerCaptor()
	If OwnerCaptor == None
		Return None
	EndIf

	Return OwnerCaptor.GetReference() as Actor
EndFunction

Actor Function GetCurrentCaptor()
	Return GetOwnerCaptor()
EndFunction

Bool Function SetCaptiveMarker(ObjectReference akMarker)
	Return SetAliasReference(CaptiveMarker, akMarker)
EndFunction

Function ClearCaptiveMarker()
	ClearAliasReference(CaptiveMarker)
EndFunction

ObjectReference Function GetCaptiveMarkerRef()
	Return GetAliasReference(CaptiveMarker)
EndFunction

Bool Function SetEscapeDoor(ObjectReference akDoor)
	Return SetAliasReference(EscapeDoor, akDoor)
EndFunction

Function ClearEscapeDoor()
	ClearAliasReference(EscapeDoor)
EndFunction

ObjectReference Function GetEscapeDoorRef()
	Return GetAliasReference(EscapeDoor)
EndFunction

Bool Function SetLootTarget(ObjectReference akTarget)
	Return SetAliasReference(LootTarget, akTarget)
EndFunction

Function ClearLootTarget()
	ClearAliasReference(LootTarget)
EndFunction

ObjectReference Function GetLootTargetRef()
	Return GetAliasReference(LootTarget)
EndFunction

Bool Function SetAliasReference(ReferenceAlias akAlias, ObjectReference akRef)
	If akAlias == None
		Return False
	EndIf

	If akRef == None
		If akAlias.GetReference() != None
			akAlias.Clear()
		EndIf
		Return False
	EndIf

	akAlias.ForceRefTo(akRef)
	Return akAlias.GetReference() == akRef
EndFunction

Function ClearAliasReference(ReferenceAlias akAlias)
	If akAlias == None
		Return
	EndIf

	If akAlias.GetReference() != None
		akAlias.Clear()
	EndIf
EndFunction

ObjectReference Function GetAliasReference(ReferenceAlias akAlias)
	If akAlias == None
		Return None
	EndIf

	Return akAlias.GetReference()
EndFunction
