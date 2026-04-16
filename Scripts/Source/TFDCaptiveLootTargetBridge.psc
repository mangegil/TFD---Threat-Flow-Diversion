Scriptname TFDCaptiveLootTargetBridge extends Quest

ReferenceAlias Property LootTarget Auto

Bool Property DebugMode = True Auto
Bool Property EnablePollFallback = True Auto
Bool Property ForceRefreshSameTarget = True Auto
Float Property PollInterval = 0.50 Auto

ObjectReference Property LastObservedTarget Auto Hidden
Bool Property Busy Auto Hidden

Function RegisterEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDLootTargetAssign", "OnLootBridgeEvent")
	RegisterForModEvent("TFDLootTargetClear", "OnLootBridgeEvent")
	RegisterForModEvent("TFDLootTargetClearAll", "OnLootBridgeEvent")
	TraceDebug("RegisterEvents done")
EndFunction

Event OnInit()
	TraceDebug("OnInit")
	RegisterEvents()
	HealFromCurrentAlias("OnInit")
	QueueNextPoll()
EndEvent

Event OnPlayerLoadGame()
	TraceDebug("OnPlayerLoadGame")
	Busy = False
	LastObservedTarget = None
	RegisterEvents()
	HealFromCurrentAlias("OnPlayerLoadGame")
	QueueNextPoll()
EndEvent

Event OnLootBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	TraceDebug("OnLootBridgeEvent name=" + eventName + " sender=" + FormLabel(sender))

	If eventName == "TFDLootTargetAssign"
		ObjectReference targetRef = sender as ObjectReference
		If targetRef != None
			AssignLootTarget(targetRef, "event-assign")
		Else
			TraceDebug("Assign ignored: sender is not ObjectReference")
		EndIf
		Return
	EndIf

	If eventName == "TFDLootTargetClear"
		ObjectReference clearRef = sender as ObjectReference
		If clearRef == None
			ClearLootTarget("event-clear sender=None")
		Else
			ObjectReference currentRef = GetCurrentLootTarget()
			If currentRef == clearRef
				ClearLootTarget("event-clear current-match")
			Else
				TraceDebug("Clear ignored: sender does not match current target")
			EndIf
		EndIf
		Return
	EndIf

	If eventName == "TFDLootTargetClearAll"
		ClearLootTarget("event-clearall")
		Return
	EndIf

	TraceDebug("Unknown event ignored")
EndEvent

Event OnUpdate()
	If EnablePollFallback
		HealFromCurrentAlias("poll")
	EndIf
	QueueNextPoll()
EndEvent

Function QueueNextPoll()
	UnregisterForUpdate()

	If !EnablePollFallback
		Return
	EndIf

	If PollInterval <= 0.0
		Return
	EndIf

	RegisterForSingleUpdate(PollInterval)
EndFunction

ObjectReference Function GetCurrentLootTarget()
	If LootTarget == None
		Return None
	EndIf

	Return LootTarget.GetReference()
EndFunction

Function HealFromCurrentAlias(String reason)
	If Busy
		TraceDebug("HealFromCurrentAlias skipped: Busy=True reason=" + reason)
		Return
	EndIf

	If LootTarget == None
		TraceDebug("HealFromCurrentAlias skipped: LootTarget=None")
		Return
	EndIf

	ObjectReference currentRef = LootTarget.GetReference()

	If currentRef == None
		If LastObservedTarget != None
			TraceDebug("HealFromCurrentAlias saw alias empty, reset last target")
			LastObservedTarget = None
		EndIf
		Return
	EndIf

	If currentRef != LastObservedTarget
		TraceDebug("HealFromCurrentAlias detected target change reason=" + reason + " target=" + FormLabel(currentRef))
		AssignLootTarget(currentRef, "heal-" + reason)
		Return
	EndIf
EndFunction

Bool Function AssignLootTarget(ObjectReference akTarget, String reason = "direct")
	If Busy
		TraceDebug("AssignLootTarget skipped: Busy=True target=" + FormLabel(akTarget))
		Return False
	EndIf

	If LootTarget == None
		TraceDebug("AssignLootTarget failed: LootTarget=None")
		Return False
	EndIf

	If akTarget == None
		TraceDebug("AssignLootTarget failed: akTarget=None")
		Return False
	EndIf

	Busy = True

	ObjectReference beforeRef = LootTarget.GetReference()
	TraceDebug("AssignLootTarget begin reason=" + reason + " before=" + FormLabel(beforeRef) + " target=" + FormLabel(akTarget))

	If beforeRef != None
		If beforeRef != akTarget
			LootTarget.Clear()
			TraceDebug("AssignLootTarget cleared old target")
		ElseIf ForceRefreshSameTarget
			LootTarget.Clear()
			TraceDebug("AssignLootTarget cleared same target for refresh")
		EndIf
	EndIf

	LootTarget.ForceRefTo(akTarget)

	ObjectReference afterRef = LootTarget.GetReference()
	LastObservedTarget = afterRef
	Busy = False

	If afterRef == akTarget
		TraceDebug("AssignLootTarget SUCCESS after=" + FormLabel(afterRef))
		Return True
	EndIf

	TraceDebug("AssignLootTarget FAILED after=" + FormLabel(afterRef))
	Return False
EndFunction

Function ClearLootTarget(String reason = "direct")
	If Busy
		TraceDebug("ClearLootTarget skipped: Busy=True")
		Return
	EndIf

	If LootTarget == None
		TraceDebug("ClearLootTarget ignored: LootTarget=None")
		Return
	EndIf

	Busy = True

	ObjectReference beforeRef = LootTarget.GetReference()
	TraceDebug("ClearLootTarget begin reason=" + reason + " before=" + FormLabel(beforeRef))

	LootTarget.Clear()
	LastObservedTarget = None

	ObjectReference afterRef = LootTarget.GetReference()
	Busy = False

	TraceDebug("ClearLootTarget done after=" + FormLabel(afterRef))
EndFunction

Function ForceRefreshCurrent()
	ObjectReference currentRef = GetCurrentLootTarget()
	If currentRef == None
		TraceDebug("ForceRefreshCurrent ignored: currentRef=None")
		Return
	EndIf

	AssignLootTarget(currentRef, "manual-force-refresh")
EndFunction

String Function FormLabel(Form f)
	If f == None
		Return "None"
	EndIf

	ObjectReference r = f as ObjectReference
	If r != None
		Return r.GetDisplayName() + "(" + f.GetFormID() + ")"
	EndIf

	Return "Form(" + f.GetFormID() + ")"
EndFunction

Function TraceDebug(String msg)
	If DebugMode
		Debug.Trace("[TFD][LootTargetBridge] " + msg)
	EndIf
EndFunction