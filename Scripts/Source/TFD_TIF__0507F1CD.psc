;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname TFD_TIF__0507F1CD Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
;VICTORY PLEASURE
TFDSystemEventQuestScript sys = (TFDSystemEventQuest as TFDSystemEventQuestScript)
If sys != None
	sys.ResolvePleasure(akSpeaker)
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDSystemEventQuest Auto
