Scriptname TFDPleasureQuestScript extends Quest

ReferenceAlias Property PlayerAlias Auto
ReferenceAlias Property SpeakerAlias Auto

TFDPreCombatQuestScript Property TFDPreCombatQuest Auto
TFDBleedoutQuestScript Property TFDBleedoutQuest Auto

GlobalVariable Property TFDInteractionState Auto
GlobalVariable Property TFDPleasureState Auto

Float Property AliasRetryDelay = 0.20 Auto
Int Property AliasRetryMax = 12 Auto
Float Property CleanupDelay = 0.35 Auto
Float Property RedoStartDelay = 0.12 Auto
Float Property PreCombatAutoStartDelay = 0.35 Auto
Float Property SceneStartWatchdogDelay = 0.25 Auto
Float Property SceneStartTimeout = 4.00 Auto
Float Property NeutralReleaseGraceDuration = 10.0 Auto
Float Property MinOStimSceneDurationForAfterPleasure = 1.50 Auto

Int PhaseIdle = 0
Int PhasePleasureDialogue = 1
Int PhaseSceneStarting = 2
Int PhaseSceneRunning = 3
Int PhaseAfterPleasurePending = 4
Int PhaseAfterPleasureDialogue = 5
Int PhaseFinalizing = 6

Int SourceNone = 0
Int SourcePreCombat = 1
Int SourceBleedout = 2
Int SourceCaptive = 3
Int SourceVictory = 4
Int SourceTeammate = 5
Int SourceInCombat = 6

String CaptiveRequestWorkEvent = "TFDCaptiveRequestWork"
String CaptiveRequestReturnEvent = "TFDCaptiveRequestReturn"
String CaptiveRequestReleaseEvent = "TFDCaptiveRequestRelease"
String CaptiveRequestEscapeEvent = "TFDCaptiveRequestEscape"
String PreCombatOutcomeCaptiveEvent = "TFDPreCombatOutcomeCaptive"

Int UpdateModeNone = 0
Int UpdateModeAliasAcquire = 1
Int UpdateModeCleanup = 2
Int UpdateModeRedoStart = 3
Int UpdateModeDeferredAutoStart = 4
Int UpdateModeSceneStartWatchdog = 5

Actor PendingSpeaker
Actor ActiveSpeaker

Int CurrentPhase = 0
Int CurrentSourceFlow = 0
Int CurrentCycleId = 0
Int CurrentThreadId = -1
Int CurrentUpdateMode = 0
Float SceneRunningStartAt = 0.0
Float SceneStartPendingAt = 0.0
String PendingAutoStartReason = ""

Bool AwaitingSceneStart = False
Bool AwaitingAfterPleasure = False
Bool PleasureDialogueOpened = False
Bool AfterPleasureDialogueOpened = False
Bool FinalOutcomeSent = False
Bool CleanupArmed = False
Bool QuestActive = False
Bool BranchChoiceLocked = False
Bool PendingAutoPleasureStart = False

Int AliasRetryCount = 0
String PendingOpenReason = ""
String PendingCleanupReason = ""

Event OnInit()
	RegisterEvents()
	ResetRuntime("OnInit")
EndEvent

Event OnPlayerLoadGame()
	RegisterEvents()
	SoftRecoverAfterLoad()
EndEvent

Function RegisterEvents()
	UnregisterForAllModEvents()
	UnregisterForMenu("Dialogue Menu")
	RegisterForModEvent("TFDPleasureAssign", "OnPleasureAssign")
	RegisterForModEvent("TFDPleasureClear", "OnPleasureClear")
	RegisterForModEvent("TFDPleasureAbort", "OnPleasureAbort")
	RegisterForModEvent("TFDInCombatEmergencyCancel", "OnInCombatEmergencyCancel")
	RegisterForModEvent("TFDPleasureBeginAfter", "OnPleasureBeginAfter")
	RegisterForModEvent("ostim_thread_start", "OnOStimThreadStart")
	RegisterForModEvent("ostim_thread_end", "OnOStimThreadEnd")
	RegisterForModEvent("ostim_end", "OnOStimEnd")
	RegisterForMenu("Dialogue Menu")
	Debug.Trace("[TFD][PleasureQuest] RegisterEvents done")
EndFunction

Function BeginPleasure(Actor akSpeaker, Int aiSourceFlow, Int aiCycleId = 0)
	If akSpeaker == None
		Debug.Trace("[TFD][PleasureQuest] BeginPleasure rejected speaker none")
		Return
	EndIf

	QuestActive = True
	PendingSpeaker = akSpeaker
	ActiveSpeaker = akSpeaker
	CurrentSourceFlow = aiSourceFlow
	CurrentCycleId = aiCycleId
	CurrentThreadId = -1

	AwaitingSceneStart = False
	AwaitingAfterPleasure = False
	PleasureDialogueOpened = False
	AfterPleasureDialogueOpened = False
	FinalOutcomeSent = False
	CleanupArmed = False
	BranchChoiceLocked = False
	PendingAutoPleasureStart = False
	SceneRunningStartAt = 0.0
	SceneStartPendingAt = 0.0
	PendingAutoStartReason = ""

	CurrentPhase = PhasePleasureDialogue
	PendingOpenReason = "pleasure_begin"
	UpdatePleasureState(0)

	Debug.Trace("[TFD][PleasureQuest] BeginPleasure speaker=" + SafeActorName(akSpeaker) + " source=" + aiSourceFlow + " cycle=" + aiCycleId)

	ForceCoreAliases()
	BeginAliasAcquire("pleasure_begin")
EndFunction

Bool Function BeginPleasureAutoStart(Actor akSpeaker, Int aiSourceFlow, Int aiCycleId = 0, String asReason = "")
	BeginPleasure(akSpeaker, aiSourceFlow, aiCycleId)

	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] BeginPleasureAutoStart failed inactive reason=" + asReason)
		Return False
	EndIf

	PendingAutoPleasureStart = True
	PendingAutoStartReason = asReason
	Debug.Trace("[TFD][PleasureQuest] BeginPleasureAutoStart armed reason=" + asReason + " speaker=" + SafeActorName(ResolveCurrentSpeaker()) + " phase=" + CurrentPhase + " source=" + aiSourceFlow)

	If aiSourceFlow == SourcePreCombat
		ArmDeferredAutoStart("precombat_auto_start_delay")
		Return True
	EndIf

	If aiSourceFlow == SourceInCombat
		; R93Z: InCombat pleasure is also a combat-to-scene handoff.  Give native
		; suppression one update window just like PreCombat before QuickStart.
		ArmDeferredAutoStart("incombat_auto_start_delay")
		Return True
	EndIf

	If AreCoreAliasesValid()
		Debug.Trace("[TFD][PleasureQuest] BeginPleasureAutoStart immediate start reason=" + asReason)
		Return ChoosePleasure()
	EndIf

	Debug.Trace("[TFD][PleasureQuest] BeginPleasureAutoStart waiting alias reason=" + asReason)
	Return True
EndFunction

Function BeginAfterPleasure()
	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] BeginAfterPleasure ignored quest inactive")
		Return
	EndIf

	If CurrentPhase == PhaseAfterPleasurePending || CurrentPhase == PhaseAfterPleasureDialogue || CurrentPhase == PhaseFinalizing
		Debug.Trace("[TFD][PleasureQuest] BeginAfterPleasure ignored phase=" + CurrentPhase)
		Return
	EndIf

	If ResolveCurrentSpeaker() == None
		Debug.Trace("[TFD][PleasureQuest] BeginAfterPleasure abort no speaker")
		AbortPleasure("after_no_speaker")
		Return
	EndIf

	CurrentPhase = PhaseAfterPleasurePending
	AwaitingAfterPleasure = True
	AfterPleasureDialogueOpened = False
	BranchChoiceLocked = False
	PendingAutoPleasureStart = False
	PendingOpenReason = "after_begin"
	UpdatePleasureState(2)

	Debug.Trace("[TFD][PleasureQuest] BeginAfterPleasure speaker=" + SafeActorName(ResolveCurrentSpeaker()) + " source=" + CurrentSourceFlow + " thread=" + CurrentThreadId)

	ForceCoreAliases()
	BeginAliasAcquire("after_begin")
EndFunction

Function ClearPleasure(String asReason = "")
	CleanupPleasureNow(asReason)
EndFunction

Function AbortPleasure(String asReason = "")
	AbortPleasureToNeutral(asReason, False, True)
EndFunction

Function AbortPleasureToNeutral(String asReason = "", Bool abStartCombat = False, Bool abSendAbortEvent = True)
	Actor speakerRef = ResolveCurrentSpeaker()
	Debug.Trace("[TFD][PleasureQuest] AbortPleasureToNeutral reason=" + asReason + " startCombat=" + BoolText(abStartCombat) + " phase=" + CurrentPhase + " source=" + CurrentSourceFlow + " thread=" + CurrentThreadId)

	If !FinalOutcomeSent
		If abSendAbortEvent
			SendPackageEvent("TFDPleasureAborted", asReason, 0.0)
		EndIf
		FinalOutcomeSent = True
		BranchChoiceLocked = True
	EndIf

	ReleaseSourceFlowFallback(speakerRef, abStartCombat)
	CleanupPleasureNow(asReason)
EndFunction

Function AbortPleasureFromCombat(String asReason = "combat_break")
	AbortPleasureToNeutral(asReason, True, True)
EndFunction

Function EmergencyAbortInCombatPleasure(String asReason = "incombat_emergency_cancel")
	If !QuestActive
		Return
	EndIf

	Actor speakerRef = ResolveCurrentSpeaker()
	Debug.Trace("[TFD][PleasureQuest][R97A] EmergencyAbortInCombatPleasure reason=" + asReason + " speaker=" + SafeActorName(speakerRef) + " phase=" + CurrentPhase + " thread=" + CurrentThreadId)

	StopPendingOStimThread(asReason)
	If !FinalOutcomeSent
		SendPackageEvent("TFDPleasureAborted", asReason, CurrentThreadId as Float)
		FinalOutcomeSent = True
	EndIf

	BranchChoiceLocked = True
	CleanupPleasureNow(asReason)
	Game.EnablePlayerControls()
EndFunction

Function SuppressPreCombatSceneCombat(String asReason = "")
	Actor playerRef = Game.GetPlayer()
	Actor speakerRef = ResolveCurrentSpeaker()
	Debug.Trace("[TFD][PleasureQuest] SuppressPreCombatSceneCombat reason=" + asReason + " speaker=" + SafeActorName(speakerRef))

	If speakerRef != None && speakerRef.Is3DLoaded()
		speakerRef.StopCombat()
		speakerRef.StopCombatAlarm()
		speakerRef.SheatheWeapon()
		speakerRef.EvaluatePackage()
	EndIf

	If playerRef != None
		playerRef.StopCombat()
	EndIf
EndFunction

Bool Function IsSceneCombatUnsafe(String asReason = "")
	Actor playerRef = Game.GetPlayer()
	Actor speakerRef = ResolveCurrentSpeaker()

	If playerRef != None && playerRef.IsInCombat()
		If CurrentSourceFlow == SourceInCombat
			SuppressPreCombatSceneCombat(asReason + "_incombat_player_stale_combat")
			Debug.Trace("[TFD][PleasureQuest][R93Z] SceneCombatUnsafe ignored incombat player stale combat reason=" + asReason + " speaker=" + SafeActorName(speakerRef))
			Return False
		EndIf
		Debug.Trace("[TFD][PleasureQuest] SceneCombatUnsafe reason=" + asReason + " playerInCombat=true speaker=" + SafeActorName(speakerRef))
		Return True
	EndIf

	If speakerRef != None && speakerRef.IsInCombat()
		If CurrentSourceFlow == SourcePreCombat || CurrentSourceFlow == SourceInCombat
			SuppressPreCombatSceneCombat(asReason + "_speaker_stale_combat")
			Debug.Trace("[TFD][PleasureQuest][R93Z] SceneCombatUnsafe ignored passive-handoff speaker stale combat reason=" + asReason + " source=" + CurrentSourceFlow + " speaker=" + SafeActorName(speakerRef))
			Return False
		EndIf

		Debug.Trace("[TFD][PleasureQuest] SceneCombatUnsafe reason=" + asReason + " speakerInCombat=true speaker=" + SafeActorName(speakerRef))
		Return True
	EndIf

	Return False
EndFunction

Float Function GetSceneRunningDuration()
	If SceneRunningStartAt <= 0.0
		Return 0.0
	EndIf
	Return Utility.GetCurrentRealTime() - SceneRunningStartAt
EndFunction

Function FailPleasureScene(String asReason = "scene_failed", Bool abStartCombat = True)
	Actor speakerRef = ResolveCurrentSpeaker()
	Debug.Trace("[TFD][PleasureQuest] FailPleasureScene reason=" + asReason + " startCombat=" + BoolText(abStartCombat) + " duration=" + GetSceneRunningDuration() + " speaker=" + SafeActorName(speakerRef) + " phase=" + CurrentPhase + " thread=" + CurrentThreadId)

	If FinalOutcomeSent
		Debug.Trace("[TFD][PleasureQuest] FailPleasureScene ignored duplicate reason=" + asReason)
		Return
	EndIf

	FinalOutcomeSent = True
	BranchChoiceLocked = True

	If speakerRef != None
		SendRuntimeSceneEvent("TFDPreCombatPleasureFailed", speakerRef, CurrentSourceFlow, CurrentThreadId)
	Else
		SendPackageEvent("TFDPreCombatPleasureFailed", asReason, CurrentThreadId as Float)
	EndIf

	SceneRunningStartAt = 0.0
	SceneStartPendingAt = 0.0
	AbortPleasureToNeutral(asReason, abStartCombat, False)
EndFunction

Actor Function ResolveCurrentSpeaker()
	If PendingSpeaker != None
		Return PendingSpeaker
	EndIf

	If ActiveSpeaker != None
		Return ActiveSpeaker
	EndIf

	If SpeakerAlias != None
		Actor aliasSpeaker = SpeakerAlias.GetReference() as Actor
		If aliasSpeaker != None
			Return aliasSpeaker
		EndIf
	EndIf

	Return None
EndFunction

Actor Function GetSpeakerActor()
	Return ResolveCurrentSpeaker()
EndFunction

Bool Function HasActiveSpeaker()
	Return (ResolveCurrentSpeaker() != None)
EndFunction

Int Function GetSource()
	Return CurrentSourceFlow
EndFunction

Function SetSource(Int aiSourceValue)
	CurrentSourceFlow = aiSourceValue
EndFunction

Function SetSourcePreCombat()
	CurrentSourceFlow = SourcePreCombat
EndFunction

Function SetSourceBleedout()
	CurrentSourceFlow = SourceBleedout
EndFunction

Function SetSourceCaptive()
	CurrentSourceFlow = SourceCaptive
EndFunction

Function SetSourceInCombat()
	CurrentSourceFlow = SourceInCombat
EndFunction

Function ResetSource()
	CurrentSourceFlow = SourceNone
EndFunction

Function MarkChoiceCommitted()
	BranchChoiceLocked = True
EndFunction

Bool Function ResolvePleasure(Actor akSpeaker = None)
	TFDPreCombatQuestScript preCtrl = TFDPreCombatQuest
	TFDBleedoutQuestScript bleedCtrl = TFDBleedoutQuest
	Actor resolvedSpeaker = akSpeaker
	Int sourceFlow = SourceNone

	If CurrentPhase == PhaseAfterPleasureDialogue || CurrentPhase == PhaseAfterPleasurePending
		Debug.Trace("[TFD][PleasureQuest] ResolvePleasure reroute to redo phase=" + CurrentPhase)
		Return ChooseRedo()
	EndIf

	If QuestActive
		Debug.Trace("[TFD][PleasureQuest] ResolvePleasure reroute to choose pleasure quest already active")
		Return ChoosePleasure()
	EndIf

	If preCtrl != None
		If resolvedSpeaker == None
			resolvedSpeaker = preCtrl.ResolveCurrentSpeaker()
		EndIf
		If resolvedSpeaker != None && !resolvedSpeaker.IsDead()
			preCtrl.BeginPleasureLock(resolvedSpeaker)
			BeginPleasure(resolvedSpeaker, SourcePreCombat, 0)
			PendingAutoPleasureStart = True
			If AreCoreAliasesValid()
				Debug.Trace("[TFD][PleasureQuest] ResolvePleasure precombat immediate start")
				Return ChoosePleasure()
			EndIf
			BeginAliasAcquire("resolve_precombat_entry")
			Return True
		EndIf
	EndIf

	If bleedCtrl != None
		If resolvedSpeaker == None
			resolvedSpeaker = bleedCtrl.GetSpeaker()
		EndIf
		If resolvedSpeaker != None && !resolvedSpeaker.IsDead()
			If bleedCtrl.IsCaptiveContext()
				sourceFlow = SourceCaptive
			Else
				sourceFlow = SourceBleedout
			EndIf

			bleedCtrl.CommitCaptiveChoiceIfNeeded()
			bleedCtrl.ReleaseCaptiveBridgeForPleasureIfNeeded()
			bleedCtrl.HandoffSpeakerToPleasure(resolvedSpeaker)
			bleedCtrl.ClearDialogueBridgesAfterChoice()
			BeginPleasure(resolvedSpeaker, sourceFlow, 0)
			PendingAutoPleasureStart = True
			If AreCoreAliasesValid()
				SendModEvent("TFDBleedoutOutcomePleasure")
				Debug.Trace("[TFD][PleasureQuest] ResolvePleasure bleed immediate start")
				Return ChoosePleasure()
			EndIf
			SendModEvent("TFDBleedoutOutcomePleasure")
			BeginAliasAcquire("resolve_bleedout_entry")
			Return True
		EndIf
	EndIf

	Debug.Trace("[TFD][PleasureQuest] ResolvePleasure failed no valid speaker")
	Return False
EndFunction

Bool Function ResolvePleasureChoice(Actor akSpeaker = None)
	Return ResolvePleasure(akSpeaker)
EndFunction

Bool Function ResolveRecruitChoice(Actor akSpeaker = None)
	Return ChooseRecruit()
EndFunction

Bool Function ResolveJoinEnemyChoice(Actor akSpeaker = None)
	Return ChooseJoinEnemy()
EndFunction

Event OnPleasureAssign(String eventName, String strArg, Float numArg, Form sender)
	Actor a = sender as Actor
	Int sourceFlow = StringToIntSafe(strArg, SourceNone)
	Int cycleId = FloatToIntSafe(numArg, 0)

	If a == None
		Debug.Trace("[TFD][PleasureQuest] OnPleasureAssign ignored sender not actor")
		Return
	EndIf

	BeginPleasure(a, sourceFlow, cycleId)
EndEvent

Event OnPleasureClear(String eventName, String strArg, Float numArg, Form sender)
	Debug.Trace("[TFD][PleasureQuest] OnPleasureClear")
	ClearPleasure("native_clear")
EndEvent

Event OnPleasureAbort(String eventName, String strArg, Float numArg, Form sender)
	Debug.Trace("[TFD][PleasureQuest] OnPleasureAbort")
	AbortPleasure("native_abort")
EndEvent

Event OnInCombatEmergencyCancel(String eventName, String strArg, Float numArg, Form sender)
	If !QuestActive
		Return
	EndIf
	If CurrentSourceFlow != SourceInCombat
		Debug.Trace("[TFD][PleasureQuest][R97A] InCombatEmergencyCancel ignored source=" + CurrentSourceFlow)
		Return
	EndIf

	EmergencyAbortInCombatPleasure("incombat_emergency_cancel")
EndEvent

Event OnPleasureBeginAfter(String eventName, String strArg, Float numArg, Form sender)
	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] OnPleasureBeginAfter ignored inactive")
		Return
	EndIf
	Debug.Trace("[TFD][PleasureQuest] OnPleasureBeginAfter")
	BeginAfterPleasure()
EndEvent

Event OnOStimThreadStart(String eventName, String strArg, Float threadID, Form sender)
	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] OnOStimThreadStart ignored inactive")
		Return
	EndIf

	If !AwaitingSceneStart
		Debug.Trace("[TFD][PleasureQuest] OnOStimThreadStart ignored AwaitingSceneStart false thread=" + threadID)
		Return
	EndIf

	Int incomingThread = FloatToIntSafe(threadID, -1)
	If CurrentThreadId >= 0 && incomingThread >= 0 && incomingThread != CurrentThreadId
		Debug.Trace("[TFD][PleasureQuest] OnOStimThreadStart ignored mismatched thread current=" + CurrentThreadId + " incoming=" + incomingThread)
		Return
	EndIf

	CurrentThreadId = incomingThread
	AwaitingSceneStart = False
	BranchChoiceLocked = False
	CurrentUpdateMode = UpdateModeNone
	UnregisterForUpdate()
	CurrentPhase = PhaseSceneRunning
	SceneRunningStartAt = Utility.GetCurrentRealTime()
	SceneStartPendingAt = 0.0
	UpdatePleasureState(1)
	ForceCoreAliases()
	Debug.Trace("[TFD][PleasureQuest] OnOStimThreadStart accepted thread=" + CurrentThreadId + " speaker=" + SafeActorName(ResolveCurrentSpeaker()))
	SendRuntimeSceneEvent("TFDOStimSceneStarted", ResolveCurrentSpeaker(), CurrentSourceFlow, CurrentThreadId)
EndEvent

Event OnOStimThreadEnd(String eventName, String jsonArg, Float threadID, Form sender)
	HandleSceneEndedFromOStim(FloatToIntSafe(threadID, -1), "thread_end")
EndEvent

Event OnOStimEnd(String eventName, String jsonArg, Float numArg, Form sender)
	HandleSceneEndedFromOStim(FloatToIntSafe(numArg, -1), "ostim_end")
EndEvent

Event OnMenuClose(String menuName)
	If menuName != "Dialogue Menu"
		Return
	EndIf

	If ShouldCleanupAfterPleasureNoCommit()
		CleanupAfterPleasureNoCommit("dialogue_menu_closed_no_commit")
	EndIf
EndEvent

Bool Function IsQuestRuntimeActive()
	Return QuestActive
EndFunction

Bool Function ShouldBlockTeammateGreet(Actor akSpeaker = None)
	If !QuestActive
		Return False
	EndIf

	If CurrentPhase == PhaseIdle
		Return False
	EndIf

	If CurrentPhase == PhaseFinalizing && FinalOutcomeSent
		Return False
	EndIf

	Return True
EndFunction

Bool Function ShouldCleanupAfterPleasureNoCommit()
	If !QuestActive
		Return False
	EndIf

	If CurrentPhase != PhaseAfterPleasureDialogue
		Return False
	EndIf

	If !AfterPleasureDialogueOpened
		Return False
	EndIf

	If BranchChoiceLocked || FinalOutcomeSent
		Return False
	EndIf

	Return True
EndFunction

Function CleanupAfterPleasureNoCommit(String asReason = "")
	Actor speakerRef = ResolveCurrentSpeaker()

	If !ShouldCleanupAfterPleasureNoCommit()
		Debug.Trace("[TFD][PleasureQuest] CleanupAfterPleasureNoCommit ignored reason=" + asReason + " phase=" + CurrentPhase + " final=" + BoolText(FinalOutcomeSent))
		Return
	EndIf

	If asReason == ""
		asReason = "after_pleasure_no_commit"
	EndIf

	Debug.Trace("[TFD][PleasureQuest] CleanupAfterPleasureNoCommit reason=" + asReason + " speaker=" + SafeActorName(speakerRef) + " source=" + CurrentSourceFlow + " thread=" + CurrentThreadId)

	BranchChoiceLocked = True
	FinalOutcomeSent = True
	CurrentPhase = PhaseFinalizing
	CurrentUpdateMode = UpdateModeNone
	UnregisterForUpdate()

	If speakerRef != None && !speakerRef.IsDead()
		SendAfterPleasureChoiceEvent("TFDAfterPleasureChoiceFinish", speakerRef)
		SendModEvent("TFDSystemEventClearAfterPleasure", ActorFormIDString(speakerRef), 0.0)
	Else
		SendModEvent("TFDAfterPleasureChoiceFinish")
		SendModEvent("TFDSystemEventClearAfterPleasure")
	EndIf

	CleanupPleasureNow(asReason)
EndFunction

Function HandleSceneEndedFromOStim(Int aiThreadId, String asReason)
	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] HandleSceneEnded ignored inactive reason=" + asReason)
		Return
	EndIf

	If CurrentPhase != PhaseSceneRunning
		Debug.Trace("[TFD][PleasureQuest] HandleSceneEnded ignored wrong phase=" + CurrentPhase + " reason=" + asReason)
		Return
	EndIf

	If CurrentThreadId >= 0 && aiThreadId >= 0 && aiThreadId != CurrentThreadId
		Debug.Trace("[TFD][PleasureQuest] HandleSceneEnded ignored mismatched thread current=" + CurrentThreadId + " incoming=" + aiThreadId)
		Return
	EndIf

	Float sceneDuration = GetSceneRunningDuration()
	If sceneDuration < MinOStimSceneDurationForAfterPleasure
		Debug.Trace("[TFD][PleasureQuest] HandleSceneEnded rejected short scene reason=" + asReason + " duration=" + sceneDuration + " min=" + MinOStimSceneDurationForAfterPleasure + " thread=" + CurrentThreadId + " speaker=" + SafeActorName(ResolveCurrentSpeaker()))
		FailPleasureScene("scene_ended_too_short", IsSceneCombatUnsafe("short_scene_end"))
		Return
	EndIf

	Debug.Trace("[TFD][PleasureQuest] HandleSceneEnded accepted reason=" + asReason + " thread=" + CurrentThreadId + " duration=" + sceneDuration + " speaker=" + SafeActorName(ResolveCurrentSpeaker()))
	SendRuntimeSceneEvent("TFDOStimSceneEnded", ResolveCurrentSpeaker(), CurrentSourceFlow, CurrentThreadId)
	SceneRunningStartAt = 0.0
	BeginAfterPleasure()
EndFunction

Function BeginAliasAcquire(String asReason)
	AliasRetryCount = 0
	PendingOpenReason = asReason
	CurrentUpdateMode = UpdateModeAliasAcquire
	Debug.Trace("[TFD][PleasureQuest] BeginAliasAcquire reason=" + asReason + " phase=" + CurrentPhase + " speaker=" + SafeActorName(ResolveCurrentSpeaker()))
	ForceCoreAliases()
	RegisterForSingleUpdate(AliasRetryDelay)
EndFunction

Function ForceCoreAliases()
	Actor playerRef = Game.GetPlayer()
	Actor speakerRef = ResolveCurrentSpeaker()

	If PlayerAlias != None
		PlayerAlias.ForceRefTo(playerRef)
	EndIf

	If SpeakerAlias != None
		If speakerRef != None
			SpeakerAlias.ForceRefTo(speakerRef)
		Else
			SpeakerAlias.Clear()
		EndIf
	EndIf

	If speakerRef != None
		ActiveSpeaker = speakerRef
	EndIf
EndFunction

Bool Function AreCoreAliasesValid()
	Actor playerRef = None
	Actor speakerRef = None
	Actor expectSpeaker = ResolveCurrentSpeaker()

	If PlayerAlias != None
		playerRef = PlayerAlias.GetReference() as Actor
	EndIf

	If SpeakerAlias != None
		speakerRef = SpeakerAlias.GetReference() as Actor
	EndIf

	If playerRef == None
		Return False
	EndIf

	If expectSpeaker == None
		Return False
	EndIf

	If speakerRef == None
		Return False
	EndIf

	If speakerRef != expectSpeaker
		Return False
	EndIf

	Return True
EndFunction

Bool Function EnsureAfterPleasureDialogueState(String asReason = "")
	Actor speakerRef = ResolveCurrentSpeaker()

	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] EnsureAfterPleasureDialogueState failed inactive reason=" + asReason)
		Return False
	EndIf

	If speakerRef == None
		Debug.Trace("[TFD][PleasureQuest] EnsureAfterPleasureDialogueState failed no speaker reason=" + asReason)
		Return False
	EndIf

	If CurrentPhase == PhaseAfterPleasureDialogue && AfterPleasureDialogueOpened
		Return True
	EndIf

	If CurrentPhase != PhaseAfterPleasurePending && CurrentPhase != PhaseAfterPleasureDialogue
		Debug.Trace("[TFD][PleasureQuest] EnsureAfterPleasureDialogueState failed wrong phase=" + CurrentPhase + " reason=" + asReason)
		Return False
	EndIf

	If !AreCoreAliasesValid()
		Debug.Trace("[TFD][PleasureQuest] EnsureAfterPleasureDialogueState retry alias reason=" + asReason)
		BeginAliasAcquire("ensure_after_dialogue")
		Return False
	EndIf

	AfterPleasureDialogueOpened = True
	AwaitingAfterPleasure = False
	CurrentPhase = PhaseAfterPleasureDialogue
	UpdatePleasureState(2)
	Debug.Trace("[TFD][PleasureQuest] EnsureAfterPleasureDialogueState commit reason=" + asReason + " speaker=" + SafeActorName(speakerRef) + " thread=" + CurrentThreadId)
	SendRuntimeSceneEvent("TFDAfterPleasureEnter", speakerRef, CurrentSourceFlow, CurrentThreadId)
	Return True
EndFunction

Event OnUpdate()
	If CurrentUpdateMode == UpdateModeCleanup
		CleanupPleasureNow(PendingCleanupReason)
		Return
	EndIf

	If CurrentUpdateMode == UpdateModeDeferredAutoStart
		CurrentUpdateMode = UpdateModeNone
		PerformDeferredAutoStart()
		Return
	EndIf

	If CurrentUpdateMode == UpdateModeRedoStart
		CurrentUpdateMode = UpdateModeNone
		PerformDeferredRedoStart()
		Return
	EndIf

	If CurrentUpdateMode == UpdateModeSceneStartWatchdog
		PerformSceneStartWatchdog()
		Return
	EndIf

	If !QuestActive
		Return
	EndIf

	If CurrentUpdateMode != UpdateModeAliasAcquire
		Return
	EndIf

	If !AreCoreAliasesValid()
		AliasRetryCount += 1
		If AliasRetryCount > AliasRetryMax
			Debug.Trace("[TFD][PleasureQuest] Alias acquire timeout reason=" + PendingOpenReason)
			AbortPleasure("alias_timeout")
			Return
		EndIf

		ForceCoreAliases()
		RegisterForSingleUpdate(AliasRetryDelay)
		Return
	EndIf

	CurrentUpdateMode = UpdateModeNone

	If CurrentPhase == PhasePleasureDialogue
		If PendingAutoPleasureStart
			PendingAutoPleasureStart = False
			ChoosePleasure()
			Return
		EndIf
		OpenPleasureDialogue()
		Return
	EndIf

	If CurrentPhase == PhaseAfterPleasurePending
		OpenAfterPleasureDialogue()
		EnsureAfterPleasureDialogueState("OnUpdate")
		Return
	EndIf
EndEvent

Function OpenPleasureDialogue()
	Actor speakerRef = ResolveCurrentSpeaker()
	If speakerRef == None
		AbortPleasure("open_pleasure_no_speaker")
		Return
	EndIf

	Debug.Trace("[TFD][PleasureQuest] OpenPleasureDialogue speaker=" + SafeActorName(speakerRef))

	If speakerRef.Is3DLoaded()
		speakerRef.StopCombat()
		speakerRef.StopCombatAlarm()
		speakerRef.EvaluatePackage()
	EndIf
EndFunction

Function OpenAfterPleasureDialogue()
	Actor speakerRef = ResolveCurrentSpeaker()
	If speakerRef == None
		AbortPleasure("open_after_no_speaker")
		Return
	EndIf

	Debug.Trace("[TFD][PleasureQuest] OpenAfterPleasureDialogue speaker=" + SafeActorName(speakerRef) + " phase=" + CurrentPhase)

	If speakerRef.Is3DLoaded()
		speakerRef.StopCombat()
		speakerRef.StopCombatAlarm()
		speakerRef.EvaluatePackage()
	EndIf
EndFunction

Function OnPleasureDialogueOpened()
	If !QuestActive
		Return
	EndIf

	If CurrentPhase != PhasePleasureDialogue
		Return
	EndIf

	If PleasureDialogueOpened
		Return
	EndIf

	If !AreCoreAliasesValid()
		Return
	EndIf

	PleasureDialogueOpened = True
	Debug.Trace("[TFD][PleasureQuest] OnPleasureDialogueOpened")
	SendPackageEvent("TFDPleasureDialogueOpened", "", CurrentCycleId as Float)
EndFunction

Function OnAfterPleasureDialogueOpened()
	EnsureAfterPleasureDialogueState("OnAfterPleasureDialogueOpened")
EndFunction

Bool Function ChoosePleasure()
	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] ChoosePleasure failed inactive")
		Return False
	EndIf

	If CurrentPhase == PhaseAfterPleasureDialogue || CurrentPhase == PhaseAfterPleasurePending
		Debug.Trace("[TFD][PleasureQuest] ChoosePleasure reroute to redo phase=" + CurrentPhase)
		Return ChooseRedo()
	EndIf

	If CurrentPhase != PhasePleasureDialogue
		Debug.Trace("[TFD][PleasureQuest] ChoosePleasure failed wrong phase=" + CurrentPhase)
		Return False
	EndIf

	If BranchChoiceLocked
		Debug.Trace("[TFD][PleasureQuest] ChoosePleasure failed BranchChoiceLocked")
		Return False
	EndIf

	If !AreCoreAliasesValid()
		Debug.Trace("[TFD][PleasureQuest] ChoosePleasure retry alias")
		BeginAliasAcquire("choose_pleasure_retry")
		Return False
	EndIf

	If !CanPrepareSceneStart()
		Debug.Trace("[TFD][PleasureQuest] ChoosePleasure failed CanPrepareSceneStart")
		If CurrentSourceFlow == SourcePreCombat
			AbortPleasureToNeutral("choose_pleasure_prepare_failed", False, True)
		Else
			AbortPleasureFromCombat("choose_pleasure_prepare_failed")
		EndIf
		Return False
	EndIf

	PendingAutoPleasureStart = False
	BranchChoiceLocked = True
	CurrentPhase = PhaseSceneStarting
	AwaitingSceneStart = True
	UpdatePleasureState(1)

	Debug.Trace("[TFD][PleasureQuest] ChoosePleasure start speaker=" + SafeActorName(ResolveCurrentSpeaker()))

	If !StartSceneNow()
		PendingAutoPleasureStart = False
		BranchChoiceLocked = False
		CurrentPhase = PhasePleasureDialogue
		AwaitingSceneStart = False
		UpdatePleasureState(0)
		Debug.Trace("[TFD][PleasureQuest] ChoosePleasure StartSceneNow failed")
		Return False
	EndIf

	SendPackageEvent("TFDPleasureDialogueOpened", "scene_launch", CurrentCycleId as Float)
	Return True
EndFunction

Bool Function ChooseRedo()
	Actor speakerRef = ResolveCurrentSpeaker()

	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] ChooseRedo failed inactive")
		Return False
	EndIf

	If !EnsureAfterPleasureDialogueState("ChooseRedo")
		Debug.Trace("[TFD][PleasureQuest] ChooseRedo failed ensure after dialogue phase=" + CurrentPhase)
		Return False
	EndIf

	If BranchChoiceLocked
		Debug.Trace("[TFD][PleasureQuest] ChooseRedo failed BranchChoiceLocked")
		Return False
	EndIf

	If speakerRef == None
		Debug.Trace("[TFD][PleasureQuest] ChooseRedo failed speaker none")
		Return False
	EndIf

	If !AreCoreAliasesValid()
		Debug.Trace("[TFD][PleasureQuest] ChooseRedo retry alias")
		BeginAliasAcquire("choose_redo_retry")
		Return False
	EndIf

	If !CanPrepareSceneStart()
		Debug.Trace("[TFD][PleasureQuest] ChooseRedo failed CanPrepareSceneStart")
		Return False
	EndIf

	Debug.Trace("[TFD][PleasureQuest] ChooseRedo accepted speaker=" + SafeActorName(speakerRef) + " source=" + CurrentSourceFlow + " thread=" + CurrentThreadId)

	BranchChoiceLocked = True
	AfterPleasureDialogueOpened = False
	AwaitingAfterPleasure = False
	PendingAutoPleasureStart = False
	CurrentPhase = PhaseSceneStarting
	AwaitingSceneStart = False
	UpdatePleasureState(1)

	SendAfterPleasureChoiceEvent("TFDAfterPleasureChoicePleasure", speakerRef)
	Debug.Trace("[TFD][PleasureQuest] ChooseRedo sent event TFDAfterPleasureChoicePleasure")
	ArmRedoStart()
	Return True
EndFunction

Bool Function ChoosePay()
	Return SendFinalChoice("TFDAfterPleasureChoiceFinish", "pay")
EndFunction

Bool Function ChooseEnd()
	Return SendFinalChoice("TFDAfterPleasureChoiceFinish", "end")
EndFunction

Bool Function ChooseRelease()
	Return ResolveTerminalOutcomeRelease()
EndFunction

Bool Function ChooseCaptive()
	Return ResolveTerminalOutcomeCaptive()
EndFunction

Bool Function ChooseJoinEnemy()
	Return SendFinalChoice("TFDAfterPleasureChoiceJoinEnemy", "join_enemy")
EndFunction

Bool Function ChooseRecruit()
	Return ResolveTerminalOutcomeRecruit()
EndFunction

Bool Function ChooseExtendContract()
	Return ChooseRedo()
EndFunction

Bool Function ChooseTerminateContract()
	Return ChooseRelease()
EndFunction

Bool Function ChooseWork()
	If CurrentSourceFlow == SourceCaptive
		Return ResolveTerminalOutcomeWork()
	EndIf

	Return SendFinalChoice("TFDAfterPleasureChoiceWork", "work")
EndFunction

Bool Function ChooseKidnap()
	Return SendFinalChoice("TFDAfterPleasureChoiceKidnap", "kidnap")
EndFunction

Bool Function ResolveTerminalOutcomeRelease()
	Actor speakerRef = ResolveCurrentSpeaker()

	If !PrepareTerminalOutcome("release")
		Return False
	EndIf

	If speakerRef == None
		Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeRelease failed no speaker")
		AbortPleasureToNeutral("release_no_speaker", False, False)
		Return False
	EndIf

	Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeRelease speaker=" + SafeActorName(speakerRef) + " source=" + CurrentSourceFlow)
	SendAfterPleasureChoiceEvent("TFDAfterPleasureChoiceRelease", speakerRef)

	If CurrentSourceFlow == SourceCaptive
		SendCaptiveRequestEvent(CaptiveRequestReleaseEvent, speakerRef)
		Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeRelease via Captive release event")
	ElseIf CurrentSourceFlow == SourceInCombat
		Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeRelease via InCombat after-pleasure native event only")
	Else
		ReleaseSourceFlowFallback(speakerRef, False)
	EndIf

	EmitNeutralReleaseGrace(speakerRef)
	CleanupPleasureNow("release")
	Return True
EndFunction

Bool Function ResolveTerminalOutcomeRecruit()
	Actor speakerRef = ResolveCurrentSpeaker()

	If !PrepareTerminalOutcome("recruit")
		Return False
	EndIf

	If speakerRef == None
		Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeRecruit failed no speaker")
		AbortPleasureToNeutral("recruit_no_speaker", False, False)
		Return False
	EndIf

	Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeRecruit native_owned=true registry_deferred_to_native=true speaker=" + SafeActorName(speakerRef) + " source=" + CurrentSourceFlow)
	SendAfterPleasureChoiceEvent("TFDAfterPleasureChoiceRecruit", speakerRef)
	CleanupPleasureNow("recruit")
	Return True
EndFunction

Bool Function ResolveTerminalOutcomeCaptive()
	Actor speakerRef = ResolveCurrentSpeaker()

	If !PrepareTerminalOutcome("captive")
		Return False
	EndIf

	If speakerRef == None
		Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeCaptive failed no speaker")
		AbortPleasureToNeutral("captive_no_speaker", False, False)
		Return False
	EndIf

	Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeCaptive speaker=" + SafeActorName(speakerRef) + " source=" + CurrentSourceFlow)
	SendAfterPleasureChoiceEvent("TFDAfterPleasureChoiceKidnap", speakerRef)

	Bool routed = RouteCaptiveOutcome(speakerRef)
	If !routed
		Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeCaptive fallback neutral")
		ReleaseSourceFlowFallback(speakerRef, False)
	EndIf

	CleanupPleasureNow("captive")
	Return routed
EndFunction

Bool Function ResolveTerminalOutcomeWork()
	Actor speakerRef = ResolveCurrentSpeaker()

	If !PrepareTerminalOutcome("work")
		Return False
	EndIf

	If speakerRef == None
		Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeWork failed no speaker")
		AbortPleasureToNeutral("work_no_speaker", False, False)
		Return False
	EndIf

	Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeWork speaker=" + SafeActorName(speakerRef) + " source=" + CurrentSourceFlow)
	SendAfterPleasureChoiceEvent("TFDAfterPleasureChoiceWork", speakerRef)

	If CurrentSourceFlow == SourceCaptive
		SendCaptiveRequestEvent(CaptiveRequestWorkEvent, speakerRef)
		CleanupPleasureNow("work")
		Return True
	EndIf

	CleanupPleasureNow("work")
	Return True
EndFunction

Bool Function PrepareTerminalOutcome(String asReason)
	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] PrepareTerminalOutcome failed inactive reason=" + asReason)
		Return False
	EndIf

	If CurrentPhase == PhaseAfterPleasurePending
		If !EnsureAfterPleasureDialogueState("PrepareTerminalOutcome_" + asReason)
			Debug.Trace("[TFD][PleasureQuest] PrepareTerminalOutcome failed ensure reason=" + asReason)
			Return False
		EndIf
	EndIf

	If CurrentPhase != PhaseAfterPleasureDialogue && CurrentPhase != PhasePleasureDialogue
		Debug.Trace("[TFD][PleasureQuest] PrepareTerminalOutcome failed wrong phase=" + CurrentPhase + " reason=" + asReason)
		Return False
	EndIf

	If BranchChoiceLocked || FinalOutcomeSent
		Debug.Trace("[TFD][PleasureQuest] PrepareTerminalOutcome failed locked/final reason=" + asReason)
		Return False
	EndIf

	BranchChoiceLocked = True
	FinalOutcomeSent = True
	CurrentPhase = PhaseFinalizing
	CleanupArmed = False
	PendingCleanupReason = asReason
	CurrentUpdateMode = UpdateModeNone
	UnregisterForUpdate()
	Return True
EndFunction

Bool Function RouteReleaseOutcome(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = TFDPreCombatQuest
	TFDBleedoutQuestScript bleedCtrl = TFDBleedoutQuest

	If CurrentSourceFlow == SourcePreCombat
		If preCtrl != None
			preCtrl.ResolveReleaseForActor(akSpeaker)
			Debug.Trace("[TFD][PleasureQuest] RouteReleaseOutcome via PreCombat")
			Return True
		EndIf
	ElseIf CurrentSourceFlow == SourceBleedout
		If bleedCtrl != None
			Bool ok = bleedCtrl.ResolveRelease()
			Debug.Trace("[TFD][PleasureQuest] RouteReleaseOutcome via Bleedout ok=" + BoolText(ok))
			Return ok
		EndIf
	ElseIf CurrentSourceFlow == SourceCaptive
		SendCaptiveRequestEvent(CaptiveRequestReleaseEvent, akSpeaker)
		Debug.Trace("[TFD][PleasureQuest] RouteReleaseOutcome via Captive event")
		Return True
	ElseIf CurrentSourceFlow == SourceInCombat
		Float useDuration = NeutralReleaseGraceDuration
		If useDuration <= 0.0
			useDuration = 10.0
		EndIf
		SendModEvent("TFDInCombatOutcomeRelease", BuildActorArg(akSpeaker), useDuration)
		Debug.Trace("[TFD][PleasureQuest] RouteReleaseOutcome via InCombat release duration=" + useDuration)
		Return True
	EndIf

	Debug.Trace("[TFD][PleasureQuest] RouteReleaseOutcome no route source=" + CurrentSourceFlow)
	Return False
EndFunction

Bool Function RouteRecruitOutcome(Actor akSpeaker)
	Debug.Trace("[TFD][PleasureQuest] RouteRecruitOutcome disabled native_owned=true registry_deferred_to_native=true speaker=" + SafeActorName(akSpeaker) + " source=" + CurrentSourceFlow)
	Return True
EndFunction

Function ReprimeAfterPleasureRecruit(Actor akSpeaker, Int aiSourceFlow)
	Debug.Trace("[TFD][PleasureQuest] ReprimeAfterPleasureRecruit disabled native_owned=true no_promote=true no_package_eval=true speaker=" + SafeActorName(akSpeaker) + " source=" + aiSourceFlow)
EndFunction

Bool Function RouteCaptiveOutcome(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = TFDPreCombatQuest
	TFDBleedoutQuestScript bleedCtrl = TFDBleedoutQuest

	If CurrentSourceFlow == SourcePreCombat
		If preCtrl != None
			preCtrl.ReleasePleasureLock(True)
		EndIf
		SendModEvent(PreCombatOutcomeCaptiveEvent, BuildActorArg(akSpeaker))
		Debug.Trace("[TFD][PleasureQuest] RouteCaptiveOutcome via PreCombat direct event=" + PreCombatOutcomeCaptiveEvent + " speaker=" + SafeActorName(akSpeaker))
		Return True
	ElseIf CurrentSourceFlow == SourceBleedout
		If bleedCtrl != None
			Bool ok = bleedCtrl.ResolveKidnap()
			Debug.Trace("[TFD][PleasureQuest] RouteCaptiveOutcome via Bleedout ok=" + BoolText(ok))
			Return ok
		EndIf
	ElseIf CurrentSourceFlow == SourceCaptive
		SendCaptiveRequestEvent(CaptiveRequestReturnEvent, akSpeaker)
		Debug.Trace("[TFD][PleasureQuest] RouteCaptiveOutcome via Captive return event")
		Return True
	ElseIf CurrentSourceFlow == SourceInCombat
		SendModEvent("TFDInCombatOutcomeCaptive", BuildActorArg(akSpeaker))
		Debug.Trace("[TFD][PleasureQuest] RouteCaptiveOutcome via InCombat event")
		Return True
	EndIf

	Debug.Trace("[TFD][PleasureQuest] RouteCaptiveOutcome no route source=" + CurrentSourceFlow)
	Return False
EndFunction

Function ReleaseSourceFlowFallback(Actor akSpeaker, Bool abStartCombat = False)
	TFDPreCombatQuestScript preCtrl = TFDPreCombatQuest
	TFDBleedoutQuestScript bleedCtrl = TFDBleedoutQuest

	If CurrentSourceFlow == SourcePreCombat
		If preCtrl != None
			If abStartCombat
				preCtrl.CancelPleasureFlowForActor(akSpeaker, True)
			ElseIf akSpeaker != None
				preCtrl.ReleaseTruceOwnershipForActor(akSpeaker)
			Else
				preCtrl.ReleasePleasureLock(True)
			EndIf
		EndIf
	ElseIf CurrentSourceFlow == SourceBleedout
		If bleedCtrl != None
			bleedCtrl.ClearSpeakerForActor(akSpeaker)
			bleedCtrl.ClearDialogueBridgesAfterChoice()
			If abStartCombat
				SendModEvent("TFDBleedoutOutcomeReset")
			EndIf
		EndIf
	ElseIf CurrentSourceFlow == SourceCaptive
		If abStartCombat
			SendCaptiveRequestEvent(CaptiveRequestEscapeEvent, akSpeaker)
		Else
			SendCaptiveRequestEvent(CaptiveRequestReturnEvent, akSpeaker)
		EndIf
	ElseIf CurrentSourceFlow == SourceInCombat
		If abStartCombat
			SendModEvent("TFDInCombatOutcomeFailed", BuildActorArg(akSpeaker))
			Debug.Trace("[TFD][PleasureQuest] ReleaseSourceFlowFallback via InCombat failed")
		Else
			SendModEvent("TFDInCombatOutcomeCancel", BuildActorArg(akSpeaker))
			Debug.Trace("[TFD][PleasureQuest] ReleaseSourceFlowFallback via InCombat cancel")
		EndIf
	EndIf
EndFunction

Function SendCaptiveRequestEvent(String asEventName, Actor akSpeaker)
	Debug.Trace("[TFD][PleasureQuest] SendCaptiveRequestEvent event=" + asEventName + " speaker=" + SafeActorName(akSpeaker) + " source=" + CurrentSourceFlow)
	If akSpeaker != None && !akSpeaker.IsDead()
		akSpeaker.SendModEvent(asEventName, BuildActorArg(akSpeaker), 0.0)
	Else
		SendModEvent(asEventName)
	EndIf
EndFunction

Function EmitNeutralReleaseGrace(Actor akSpeaker)
	If akSpeaker == None || akSpeaker.IsDead()
		Debug.Trace("[TFD][PleasureQuest] EmitNeutralReleaseGrace skipped invalid speaker")
		Return
	EndIf

	Float useDuration = NeutralReleaseGraceDuration
	If useDuration <= 0.0
		useDuration = 10.0
	EndIf

	Debug.Trace("[TFD][PleasureQuest] EmitNeutralReleaseGrace speaker=" + SafeActorName(akSpeaker) + " duration=" + useDuration)
	SendModEvent("TFDPleasureOutcomeRelease", ActorFormIDString(akSpeaker), useDuration)
EndFunction

Bool Function SendFinalChoice(String asEventName, String asReason)
	Actor speakerRef = ResolveCurrentSpeaker()

	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] SendFinalChoice failed inactive event=" + asEventName)
		Return False
	EndIf

	If CurrentPhase != PhaseAfterPleasureDialogue && CurrentPhase != PhasePleasureDialogue && CurrentPhase != PhaseAfterPleasurePending
		Debug.Trace("[TFD][PleasureQuest] SendFinalChoice failed wrong phase=" + CurrentPhase + " event=" + asEventName)
		Return False
	EndIf

	If CurrentPhase == PhaseAfterPleasurePending
		If !EnsureAfterPleasureDialogueState("SendFinalChoice")
			Debug.Trace("[TFD][PleasureQuest] SendFinalChoice failed ensure event=" + asEventName)
			Return False
		EndIf
	EndIf

	If BranchChoiceLocked || FinalOutcomeSent
		Debug.Trace("[TFD][PleasureQuest] SendFinalChoice failed locked/final event=" + asEventName)
		Return False
	EndIf

	If speakerRef == None
		Debug.Trace("[TFD][PleasureQuest] SendFinalChoice failed speaker none event=" + asEventName)
		Return False
	EndIf

	Debug.Trace("[TFD][PleasureQuest] SendFinalChoice event=" + asEventName + " reason=" + asReason + " speaker=" + SafeActorName(speakerRef))

	BranchChoiceLocked = True
	FinalOutcomeSent = True
	CurrentPhase = PhaseFinalizing
	SendAfterPleasureChoiceEvent(asEventName, speakerRef)
	ArmCleanup(asReason)
	Return True
EndFunction

Bool Function StartSceneNow()
	Actor playerRef = Game.GetPlayer()
	Actor speakerRef = ResolveCurrentSpeaker()

	If playerRef == None
		Debug.Trace("[TFD][PleasureQuest] StartSceneNow failed player none")
		Return False
	EndIf

	If speakerRef == None
		Debug.Trace("[TFD][PleasureQuest] StartSceneNow failed speaker none")
		Return False
	EndIf

	If speakerRef.IsDead()
		Debug.Trace("[TFD][PleasureQuest] StartSceneNow failed speaker dead")
		Return False
	EndIf

	If IsSceneCombatUnsafe("StartSceneNow")
		Debug.Trace("[TFD][PleasureQuest] StartSceneNow failed combat unsafe speaker=" + SafeActorName(speakerRef))
		Return False
	EndIf

	SceneRunningStartAt = 0.0
	Actor[] participants = new Actor[2]
	participants[0] = playerRef
	participants[1] = speakerRef

	CurrentThreadId = OThread.QuickStart(participants)
	Debug.Trace("[TFD][PleasureQuest] StartSceneNow QuickStart result thread=" + CurrentThreadId + " speaker=" + SafeActorName(speakerRef) + " phase=" + CurrentPhase)
	If CurrentThreadId < 0
		CurrentThreadId = -1
		Return False
	EndIf

	SendRuntimeSceneEvent("TFDOStimSceneStartPending", speakerRef, CurrentSourceFlow, CurrentThreadId)
	Debug.Trace("[TFD][PleasureQuest] StartSceneNow sent TFDOStimSceneStartPending thread=" + CurrentThreadId)
	ArmSceneStartWatchdog("StartSceneNow")
	Return True
EndFunction

Bool Function CanPrepareSceneStart()
	Actor playerRef = Game.GetPlayer()
	Actor speakerRef = ResolveCurrentSpeaker()

	If playerRef == None
		Return False
	EndIf

	If speakerRef == None
		Return False
	EndIf

	If speakerRef.IsDead()
		Return False
	EndIf

	If IsSceneCombatUnsafe("CanPrepareSceneStart")
		Return False
	EndIf

	Return True
EndFunction

Function ArmDeferredAutoStart(String asReason = "")
	PendingAutoStartReason = asReason
	CurrentUpdateMode = UpdateModeDeferredAutoStart
	UnregisterForUpdate()
	Debug.Trace("[TFD][PleasureQuest] ArmDeferredAutoStart reason=" + asReason + " delay=" + PreCombatAutoStartDelay + " speaker=" + SafeActorName(ResolveCurrentSpeaker()))
	RegisterForSingleUpdate(PreCombatAutoStartDelay)
EndFunction

Function PerformDeferredAutoStart()
	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] PerformDeferredAutoStart ignored inactive")
		Return
	EndIf

	If CurrentPhase != PhasePleasureDialogue
		Debug.Trace("[TFD][PleasureQuest] PerformDeferredAutoStart ignored wrong phase=" + CurrentPhase)
		Return
	EndIf

	If !AreCoreAliasesValid()
		Debug.Trace("[TFD][PleasureQuest] PerformDeferredAutoStart aliases not ready reason=" + PendingAutoStartReason)
		BeginAliasAcquire("deferred_auto_start_alias")
		Return
	EndIf

	If !CanPrepareSceneStart()
		Debug.Trace("[TFD][PleasureQuest] PerformDeferredAutoStart failed CanPrepareSceneStart reason=" + PendingAutoStartReason)
		If CurrentSourceFlow == SourcePreCombat
			AbortPleasureToNeutral("precombat_deferred_start_unsafe", False, True)
		Else
			AbortPleasureFromCombat("precombat_deferred_start_unsafe")
		EndIf
		Return
	EndIf

	PendingAutoPleasureStart = False
	Debug.Trace("[TFD][PleasureQuest] PerformDeferredAutoStart start reason=" + PendingAutoStartReason + " speaker=" + SafeActorName(ResolveCurrentSpeaker()))
	ChoosePleasure()
EndFunction

Function ArmSceneStartWatchdog(String asReason = "")
	SceneStartPendingAt = Utility.GetCurrentRealTime()
	CurrentUpdateMode = UpdateModeSceneStartWatchdog
	UnregisterForUpdate()
	Debug.Trace("[TFD][PleasureQuest] ArmSceneStartWatchdog reason=" + asReason + " delay=" + SceneStartWatchdogDelay + " timeout=" + SceneStartTimeout + " thread=" + CurrentThreadId)
	RegisterForSingleUpdate(SceneStartWatchdogDelay)
EndFunction

Function StopPendingOStimThread(String asReason = "")
	If CurrentThreadId < 0
		Return
	EndIf

	Bool running = False
	running = OThread.IsRunning(CurrentThreadId)
	Debug.Trace("[TFD][PleasureQuest] StopPendingOStimThread reason=" + asReason + " thread=" + CurrentThreadId + " running=" + BoolText(running))

	If running
		OThread.Stop(CurrentThreadId)
	EndIf
EndFunction

Function PerformSceneStartWatchdog()
	If !QuestActive
		Return
	EndIf

	If CurrentPhase != PhaseSceneStarting || !AwaitingSceneStart
		Debug.Trace("[TFD][PleasureQuest] SceneStartWatchdog ignored phase=" + CurrentPhase + " awaiting=" + BoolText(AwaitingSceneStart))
		Return
	EndIf

	If IsSceneCombatUnsafe("scene_start_watchdog")
		StopPendingOStimThread("scene_start_combat_unsafe")
		If CurrentSourceFlow == SourcePreCombat || CurrentSourceFlow == SourceInCombat
			FailPleasureScene("scene_start_combat_unsafe", False)
		Else
			FailPleasureScene("scene_start_combat_unsafe", True)
		EndIf
		Return
	EndIf

	Float elapsed = Utility.GetCurrentRealTime() - SceneStartPendingAt
	If elapsed >= SceneStartTimeout
		Bool threadRunning = False
		If CurrentThreadId >= 0
			threadRunning = OThread.IsRunning(CurrentThreadId)
		EndIf
		If threadRunning
			; R93Z: OStim can report thread start late during combat-to-scene handoff.
			; If the thread is already running, accept it instead of aborting the scene.
			AwaitingSceneStart = False
			CurrentPhase = PhaseSceneRunning
			SceneRunningStartAt = Utility.GetCurrentRealTime()
			SceneStartPendingAt = 0.0
			UpdatePleasureState(2)
			Debug.Trace("[TFD][PleasureQuest][R93Z] SceneStartWatchdog accepted running thread=" + CurrentThreadId + " source=" + CurrentSourceFlow + " elapsed=" + elapsed)
			SendRuntimeSceneEvent("TFDOStimSceneStarted", ResolveCurrentSpeaker(), CurrentSourceFlow, CurrentThreadId)
			Return
		EndIf
		StopPendingOStimThread("scene_start_timeout")
		FailPleasureScene("scene_start_timeout", False)
		Return
	EndIf

	CurrentUpdateMode = UpdateModeSceneStartWatchdog
	RegisterForSingleUpdate(SceneStartWatchdogDelay)
EndFunction

Function ArmRedoStart()
	CurrentUpdateMode = UpdateModeRedoStart
	UnregisterForUpdate()
	Debug.Trace("[TFD][PleasureQuest] ArmRedoStart delay=" + RedoStartDelay)
	RegisterForSingleUpdate(RedoStartDelay)
EndFunction

Function PerformDeferredRedoStart()
	If !QuestActive
		Debug.Trace("[TFD][PleasureQuest] PerformDeferredRedoStart ignored inactive")
		Return
	EndIf

	If CurrentPhase != PhaseSceneStarting
		Debug.Trace("[TFD][PleasureQuest] PerformDeferredRedoStart ignored wrong phase=" + CurrentPhase)
		Return
	EndIf

	If !CanPrepareSceneStart()
		Debug.Trace("[TFD][PleasureQuest] PerformDeferredRedoStart failed CanPrepareSceneStart")
		If CurrentSourceFlow == SourcePreCombat
			AbortPleasureToNeutral("redo_prepare_failed", False, True)
		Else
			AbortPleasureFromCombat("redo_prepare_failed")
		EndIf
		Return
	EndIf

	AwaitingSceneStart = True
	Debug.Trace("[TFD][PleasureQuest] PerformDeferredRedoStart begin speaker=" + SafeActorName(ResolveCurrentSpeaker()))
	If StartSceneNow()
		Return
	EndIf

	AwaitingSceneStart = False
	Debug.Trace("[TFD][PleasureQuest] PerformDeferredRedoStart StartSceneNow failed")
	If CurrentSourceFlow == SourcePreCombat
		AbortPleasureToNeutral("redo_start_failed", False, True)
	Else
		AbortPleasureFromCombat("redo_start_failed")
	EndIf
EndFunction

Function ArmCleanup(String asReason)
	CleanupArmed = True
	PendingCleanupReason = asReason
	CurrentUpdateMode = UpdateModeCleanup
	UnregisterForUpdate()
	Debug.Trace("[TFD][PleasureQuest] ArmCleanup reason=" + asReason + " delay=" + CleanupDelay)
	RegisterForSingleUpdate(CleanupDelay)
EndFunction

Function CleanupPleasureNow(String asReason = "")
	Debug.Trace("[TFD][PleasureQuest] CleanupPleasureNow reason=" + asReason + " phase=" + CurrentPhase + " thread=" + CurrentThreadId)
	UnregisterForUpdate()
	CurrentUpdateMode = UpdateModeNone
	SceneRunningStartAt = 0.0
	SceneStartPendingAt = 0.0
	PendingAutoStartReason = ""

	; PlayerAlias can be a non-optional forced player alias in CK.
	; Do not clear it here, only keep it from blocking pleasure cleanup.
	If SpeakerAlias != None
		SpeakerAlias.Clear()
	EndIf

	PendingSpeaker = None
	ActiveSpeaker = None
	ResetRuntime(asReason)
EndFunction

Function ResetRuntime(String asReason = "")
	CurrentPhase = PhaseIdle
	CurrentSourceFlow = SourceNone
	CurrentCycleId = 0
	CurrentThreadId = -1
	CurrentUpdateMode = UpdateModeNone

	AwaitingSceneStart = False
	AwaitingAfterPleasure = False
	PleasureDialogueOpened = False
	AfterPleasureDialogueOpened = False
	FinalOutcomeSent = False
	CleanupArmed = False
	QuestActive = False
	BranchChoiceLocked = False
	PendingAutoPleasureStart = False
	SceneStartPendingAt = 0.0
	PendingAutoStartReason = ""
	AliasRetryCount = 0
	PendingOpenReason = ""
	PendingCleanupReason = ""
	UpdatePleasureState(0)
	Debug.Trace("[TFD][PleasureQuest] ResetRuntime reason=" + asReason)
EndFunction

Function SoftRecoverAfterLoad()
	If !QuestActive
		CleanupPleasureNow("load_inactive")
		Return
	EndIf

	If PendingSpeaker == None && ActiveSpeaker == None
		CleanupPleasureNow("load_no_speaker")
		Return
	EndIf

	ForceCoreAliases()

	If CurrentPhase == PhasePleasureDialogue || CurrentPhase == PhaseAfterPleasurePending
		BeginAliasAcquire("recover_after_load")
	EndIf
EndFunction

Function UpdatePleasureState(Int aiValue)
	If TFDPleasureState != None
		TFDPleasureState.SetValueInt(aiValue)
	EndIf
EndFunction

Function SendPackageEvent(String asEventName, String asStrArg = "", Float afNumArg = 0.0)
	Debug.Trace("[TFD][PleasureQuest] SendPackageEvent event=" + asEventName + " strArg=" + asStrArg + " numArg=" + afNumArg)
	SendModEvent(asEventName, asStrArg, afNumArg)
EndFunction

Function SendRuntimeSceneEvent(String asEventName, Actor akSpeaker, Int aiSourceFlow, Int aiThreadId = -1)
	String eventArg = BuildEventArg(akSpeaker, aiSourceFlow, aiThreadId)
	SendPackageEvent(asEventName, eventArg, aiThreadId as Float)
EndFunction

Function SendAfterPleasureChoiceEvent(String asEventName, Actor akSpeaker)
	String eventArg = BuildEventArg(akSpeaker, CurrentSourceFlow, CurrentThreadId)
	SendPackageEvent(asEventName, eventArg, CurrentSourceFlow as Float)
EndFunction

String Function BuildEventArg(Actor akSpeaker, Int aiSourceFlow, Int aiThreadId = -1)
	String actorArg = BuildActorArg(akSpeaker)
	If aiThreadId >= 0
		Return actorArg + "|" + aiSourceFlow + "|" + aiThreadId
	EndIf
	Return actorArg + "|" + aiSourceFlow
EndFunction

String Function BuildActorArg(Actor akActor)
	If akActor == None
		Return ""
	EndIf
	Return "" + akActor.GetFormID()
EndFunction


String Function ActorFormIDString(Actor akActor)
	If akActor == None
		Return ""
	EndIf
	Return "" + akActor.GetFormID()
EndFunction


String Function BoolText(Bool abValue)
	If abValue
		Return "true"
	EndIf
	Return "false"
EndFunction

String Function SafeActorName(Actor akActor)
	If akActor == None
		Return "None"
	EndIf
	Return akActor.GetDisplayName() + "(" + akActor.GetFormID() + ")"
EndFunction

Int Function FloatToIntSafe(Float afValue, Int aiFallback = 0)
	Return afValue as Int
EndFunction

Int Function StringToIntSafe(String asValue, Int aiFallback = 0)
	If asValue == ""
		Return aiFallback
	EndIf

	If asValue == "0"
		Return 0
	ElseIf asValue == "1"
		Return 1
	ElseIf asValue == "2"
		Return 2
	ElseIf asValue == "3"
		Return 3
	ElseIf asValue == "4"
		Return 4
	ElseIf asValue == "5"
		Return 5
	EndIf

	If asValue == "None"
		Return SourceNone
	ElseIf asValue == "PreCombat"
		Return SourcePreCombat
	ElseIf asValue == "Bleedout"
		Return SourceBleedout
	ElseIf asValue == "Captive"
		Return SourceCaptive
	ElseIf asValue == "Victory"
		Return SourceVictory
	ElseIf asValue == "Teammate"
		Return SourceTeammate
	EndIf

	Return aiFallback
EndFunction