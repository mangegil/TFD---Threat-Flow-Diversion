;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 3
Scriptname TFD_TIF__050D52FD Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_2
Function Fragment_2(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
;AFTER PLEASURE RELEASE

TFDPleasureQuestScript pleasureCtrl = (TFDPleasureQuest as TFDPleasureQuestScript)
If pleasureCtrl != None
	pleasureCtrl.ChooseRelease()
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDPleasureQuest Auto
