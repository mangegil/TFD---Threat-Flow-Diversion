;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 12
Scriptname TFD_QF_TFDTeammateRegistryUti_0504C779 Extends Quest Hidden

;BEGIN FRAGMENT Fragment_4
Function Fragment_4()
;BEGIN CODE
Quest __temp = self as Quest
TFDTeammateRegistryUtil kmyQuest = __temp as TFDTeammateRegistryUtil
kmyQuest.DebugUnregisterCrosshair()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_0
Function Fragment_0()
;BEGIN CODE
Quest __temp = self as Quest
TFDTeammateRegistryUtil kmyQuest = __temp as TFDTeammateRegistryUtil
kmyQuest.DebugRegisterCrosshair()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_8
Function Fragment_8()
;BEGIN CODE
Quest __temp = self as Quest
TFDTeammateRegistryUtil kmyQuest = __temp as TFDTeammateRegistryUtil
kmyQuest.DebugPrune()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_10
Function Fragment_10()
;BEGIN CODE
Quest __temp = self as Quest
TFDTeammateRegistryUtil kmyQuest = __temp as TFDTeammateRegistryUtil
kmyQuest.DebugClear()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_6
Function Fragment_6()
;BEGIN CODE
Quest __temp = self as Quest
TFDTeammateRegistryUtil kmyQuest = __temp as TFDTeammateRegistryUtil
kmyQuest.DebugPrintRegistry()
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
