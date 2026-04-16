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
Float Property NeutralReleaseGraceDuration = 10.0 Auto

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

Int UpdateModeNone = 0
Int UpdateModeAliasAcquire = 1
Int UpdateModeCleanup = 2
Int UpdateModeRedoStart = 3

Actor PendingSpeaker
Actor ActiveSpeaker

Int CurrentPhase = 0
Int CurrentSourceFlow = 0
Int CurrentCycleId = 0
Int CurrentThreadId = -1
Int CurrentUpdateMode = 0

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
	RegisterForModEvent("TFDPleasureAssign", "OnPleasureAssign")
	RegisterForModEvent("TFDPleasureClear", "OnPleasureClear")
	RegisterForModEvent("TFDPleasureAbort", "OnPleasureAbort")
	RegisterForModEvent("TFDPleasureBeginAfter", "OnPleasureBeginAfter")
	RegisterForModEvent("ostim_thread_start", "OnOStimThreadStart")
	RegisterForModEvent("ostim_thread_end", "OnOStimThreadEnd")
	RegisterForModEvent("ostim_end", "OnOStimEnd")
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

	CurrentPhase = PhasePleasureDialogue
	PendingOpenReason = "pleasure_begin"
	UpdatePleasureState(0)

	Debug.Trace("[TFD][PleasureQuest] BeginPleasure speaker=" + SafeActorName(akSpeaker) + " source=" + aiSourceFlow + " cycle=" + aiCycleId)

	ForceCoreAliases()
	BeginAliasAcquire("pleasure_begin")
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

	If abSendAbortEvent && !FinalOutcomeSent
		SendPackageEvent("TFDPleasureAborted", asReason, 0.0)
	EndIf

	ReleaseSourceFlowFallback(speakerRef, abStartCombat)
	CleanupPleasureNow(asReason)
EndFunction

Function AbortPleasureFromCombat(String asReason = "combat_break")
	AbortPleasureToNeutral(asReason, True, True)
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
	CurrentSourceFlow = SourceBleedout
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
	CurrentPhase = PhaseSceneRunning
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

	Debug.Trace("[TFD][PleasureQuest] HandleSceneEnded accepted reason=" + asReason + " thread=" + CurrentThreadId + " speaker=" + SafeActorName(ResolveCurrentSpeaker()))
	SendRuntimeSceneEvent("TFDOStimSceneEnded", ResolveCurrentSpeaker(), CurrentSourceFlow, CurrentThreadId)
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

	If CurrentUpdateMode == UpdateModeRedoStart
		CurrentUpdateMode = UpdateModeNone
		PerformDeferredRedoStart()
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

	; Pleasure owns this terminal outcome.
	; Do not hand off to PreCombat/InCombat/Bleedout release logic here.
	ReleaseSourceFlowFallback(speakerRef, False)
	EmitNeutralReleaseGrace(speakerRef)
	CleanupPleasureNow("release")
	Return True
EndFunction

Bool Function ResolveTerminalOutcomeRecruit()
	Actor speakerRef = ResolveCurrentSpeaker()
	Int sourceFlow = CurrentSourceFlow

	If !PrepareTerminalOutcome("recruit")
		Return False
	EndIf

	If speakerRef == None
		Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeRecruit failed no speaker")
		AbortPleasureToNeutral("recruit_no_speaker", False, False)
		Return False
	EndIf

	Bool ok = RouteRecruitOutcome(speakerRef)
	Debug.Trace("[TFD][PleasureQuest] ResolveTerminalOutcomeRecruit speaker=" + SafeActorName(speakerRef) + " source=" + CurrentSourceFlow + " ok=" + BoolText(ok))

	If !ok
		AbortPleasureToNeutral("recruit_route_failed", False, False)
		Return False
	EndIf

	SendAfterPleasureChoiceEvent("TFDAfterPleasureChoiceRecruit", speakerRef)
	CleanupPleasureNow("recruit")
	ReprimeAfterPleasureRecruit(speakerRef, sourceFlow)
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
	ElseIf CurrentSourceFlow == SourceBleedout || CurrentSourceFlow == SourceCaptive
		If bleedCtrl != None
			Bool ok = bleedCtrl.ResolveRelease()
			Debug.Trace("[TFD][PleasureQuest] RouteReleaseOutcome via Bleedout/Captive ok=" + BoolText(ok))
			Return ok
		EndIf
	EndIf

	Debug.Trace("[TFD][PleasureQuest] RouteReleaseOutcome no route source=" + CurrentSourceFlow)
	Return False
EndFunction

Bool Function RouteRecruitOutcome(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = TFDPreCombatQuest

	If preCtrl != None
		Bool ok = preCtrl.PromoteActorAsRecruitLikeOutcome(akSpeaker, CurrentSourceFlow == SourcePreCombat)
		Debug.Trace("[TFD][PleasureQuest] RouteRecruitOutcome via PreCombatQuest ok=" + BoolText(ok) + " source=" + CurrentSourceFlow)
		Return ok
	EndIf

	Debug.Trace("[TFD][PleasureQuest] RouteRecruitOutcome no route source=" + CurrentSourceFlow)
	Return False
EndFunction

Function ReprimeAfterPleasureRecruit(Actor akSpeaker, Int aiSourceFlow)
	TFDPreCombatQuestScript preCtrl = TFDPreCombatQuest

	If akSpeaker == None || akSpeaker.IsDead()
		Debug.Trace("[TFD][PleasureQuest] ReprimeAfterPleasureRecruit skipped invalid speaker")
		Return
	EndIf

	; AfterPleasure recruit can happen while the final dialogue/menu is still unwinding.
	; Re-prime once more after cleanup so the teammate package has a clean chance to evaluate.
	Utility.WaitMenuMode(0.25)

	If akSpeaker.IsDead()
		Debug.Trace("[TFD][PleasureQuest] ReprimeAfterPleasureRecruit skipped dead speaker")
		Return
	EndIf

	If preCtrl != None
		Bool ok = preCtrl.PromoteActorAsRecruitLikeOutcome(akSpeaker, aiSourceFlow == SourcePreCombat)
		Debug.Trace("[TFD][PleasureQuest] ReprimeAfterPleasureRecruit via PreCombatQuest ok=" + BoolText(ok) + " source=" + aiSourceFlow)
		Return
	EndIf

	akSpeaker.SetPlayerTeammate(True, False)
	akSpeaker.StopCombat()
	akSpeaker.StopCombatAlarm()
	akSpeaker.EvaluatePackage()
	Debug.Trace("[TFD][PleasureQuest] ReprimeAfterPleasureRecruit fallback package evaluate speaker=" + SafeActorName(akSpeaker))
EndFunction

Bool Function RouteCaptiveOutcome(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = TFDPreCombatQuest
	TFDBleedoutQuestScript bleedCtrl = TFDBleedoutQuest

	If CurrentSourceFlow == SourcePreCombat
		If preCtrl != None
			preCtrl.ResolveKidnap()
			Debug.Trace("[TFD][PleasureQuest] RouteCaptiveOutcome via PreCombat")
			Return True
		EndIf
	ElseIf CurrentSourceFlow == SourceBleedout || CurrentSourceFlow == SourceCaptive
		If bleedCtrl != None
			Bool ok = bleedCtrl.ResolveKidnap()
			Debug.Trace("[TFD][PleasureQuest] RouteCaptiveOutcome via Bleedout/Captive ok=" + BoolText(ok))
			Return ok
		EndIf
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
	ElseIf CurrentSourceFlow == SourceBleedout || CurrentSourceFlow == SourceCaptive
		If bleedCtrl != None
			bleedCtrl.ClearSpeakerForActor(akSpeaker)
			bleedCtrl.ClearDialogueBridgesAfterChoice()
			If abStartCombat
				SendModEvent("TFDBleedoutOutcomeReset")
			EndIf
		EndIf
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

	Return True
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
		AbortPleasure("redo_prepare_failed")
		Return
	EndIf

	AwaitingSceneStart = True
	Debug.Trace("[TFD][PleasureQuest] PerformDeferredRedoStart begin speaker=" + SafeActorName(ResolveCurrentSpeaker()))
	If StartSceneNow()
		Return
	EndIf

	AwaitingSceneStart = False
	Debug.Trace("[TFD][PleasureQuest] PerformDeferredRedoStart StartSceneNow failed")
	AbortPleasure("redo_start_failed")
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