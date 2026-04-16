Scriptname TFDPassiveBreakStoryQuestScript extends Quest

Bool Property DebugTrace = False Auto

String Function ActorFormIDString(Actor akActor)
	If akActor == None
		Return ""
	EndIf

	Return "" + akActor.GetFormID()
EndFunction

Function TraceDebug(String asText)
	If !DebugTrace
		Return
	EndIf

	Debug.Trace("[TFDPassiveBreakStory] " + asText)
EndFunction

Function SendCrimeBreak(Actor akTarget, String asSource)
	String arg = ActorFormIDString(akTarget)
	TraceDebug("Send crime break source=" + asSource + " arg=" + arg)
	SendModEvent("TFDPassiveBreakCrime", arg, 0.0)
EndFunction

Function SendPickpocketBreak(Actor akTarget, String asSource)
	String arg = ActorFormIDString(akTarget)
	TraceDebug("Send pickpocket break source=" + asSource + " arg=" + arg)
	SendModEvent("TFDPassiveBreakPickpocket", arg, 0.0)
EndFunction

Actor Function ResolveActorFromRefs(ObjectReference akPrimary, ObjectReference akSecondary)
	Actor akActor = akPrimary as Actor
	If akActor != None
		Return akActor
	EndIf

	akActor = akSecondary as Actor
	If akActor != None
		Return akActor
	EndIf

	Return None
EndFunction

Function FinalizeStoryEvent()
	If IsRunning()
		Stop()
	EndIf
EndFunction

Event OnStoryAddToPlayer(ObjectReference akOwner, ObjectReference akContainer, Location akLocation, Form akItemBase, Int aiAcquireType)
	Actor akTarget = ResolveActorFromRefs(akOwner, akContainer)

	If aiAcquireType == 3
		SendPickpocketBreak(akTarget, "add_to_player_pickpocket")
	ElseIf aiAcquireType == 1
		SendCrimeBreak(akTarget, "add_to_player_steal")
	Else
		TraceDebug("Ignore add to player acquireType=" + aiAcquireType)
	EndIf

	FinalizeStoryEvent()
EndEvent

Event OnStoryTrespass(ObjectReference akVictim, ObjectReference akTrespasser, Location akLocation, Int aiCrime)
	If akTrespasser != Game.GetPlayer()
		FinalizeStoryEvent()
		Return
	EndIf

	If aiCrime == 0
		FinalizeStoryEvent()
		Return
	EndIf

	SendCrimeBreak(akVictim as Actor, "trespass")
	FinalizeStoryEvent()
EndEvent

Event OnStoryPickLock(ObjectReference akActor, ObjectReference akLock)
	If akActor != Game.GetPlayer()
		FinalizeStoryEvent()
		Return
	EndIf

	SendCrimeBreak(None, "pick_lock")
	FinalizeStoryEvent()
EndEvent