Scriptname TFDTransitionQuestScript extends Quest

Event OnInit()
	Debug.Trace("TFDTransitionQuestScript: legacy transition globals removed; native transition controller is authoritative.")
EndEvent

Event OnPlayerLoadGame()
	Debug.Trace("TFDTransitionQuestScript: load complete; no legacy transition globals are used.")
EndEvent
