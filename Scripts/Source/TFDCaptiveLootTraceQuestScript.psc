Scriptname TFDCaptiveLootTraceQuestScript extends Quest

ReferenceAlias Property LootTarget Auto
Int Property TraceObjective = 10 Auto
Bool Property EnableNotifications = True Auto
Float Property PollInterval = 1.0 Auto

ObjectReference LastTarget
Bool ObjectiveVisible = False

Event OnInit()
	RegisterForSingleUpdate(PollInterval)
EndEvent

Event OnUpdate()
	ObjectReference currentTarget = None
	If LootTarget
		currentTarget = LootTarget.GetReference()
	EndIf

	If currentTarget
		If !ObjectiveVisible
			SetObjectiveDisplayed(TraceObjective, True, True)
			SetActive(True)
			ObjectiveVisible = True
		EndIf

		If currentTarget != LastTarget
			If EnableNotifications
				Debug.Notification("TFD: Captive loot marker updated.")
			EndIf
			LastTarget = currentTarget
		EndIf
	Else
		If ObjectiveVisible
			SetObjectiveDisplayed(TraceObjective, False, False)
			ObjectiveVisible = False
		EndIf
		LastTarget = None
	EndIf

	RegisterForSingleUpdate(PollInterval)
EndEvent