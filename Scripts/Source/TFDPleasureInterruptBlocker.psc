Scriptname TFDPleasureInterruptBlocker extends Quest

; =========================================================
; TFDPleasureInterruptBlocker
; ---------------------------------------------------------
; Quest helper terpisah untuk menjaga window eksklusif TFD.
; Tujuan:
; - TIDAK menyentuh TFDSystemEventQuestScript
; - TIDAK punya dependency compile ke script addon OStim
; - Bisa attach ke quest TFD yang selalu running
; - Saat TFD pegang dialogue / pleasure window, addon intrusion
;   dipaksa minggir lewat GlobalVariable yang diisi manual di CK
; =========================================================

; -----------------------------
; TFD globals (wajib)
; -----------------------------
GlobalVariable Property TFDPleasureState Auto
GlobalVariable Property TFDDialogueState Auto
GlobalVariable Property TFDInteractionState Auto
GlobalVariable Property TFDDefeatState Auto
GlobalVariable Property TFDPreCombatState Auto
GlobalVariable Property TFDInCombatState Auto
GlobalVariable Property TFDCaptiveState Auto

; -----------------------------
; Polling / debug
; -----------------------------
Float Property PollSeconds = 0.50 Auto
Float Property ReleaseDelaySeconds = 2.00 Auto
Bool Property DebugEnabled = False Auto

; -----------------------------
; Optional OPrivacy globals
; Isi manual di CK kalau OPrivacy terpasang.
; Kalau kosong, script tetap compile & jalan aman.
; -----------------------------
GlobalVariable Property OPrivacyApproachEnabled Auto
GlobalVariable Property OPrivacyLocationCounter Auto
GlobalVariable Property OPrivacyCombatCounter Auto
GlobalVariable Property OPrivacyActiveFollow Auto
GlobalVariable Property OPrivacyAPRunning Auto
GlobalVariable Property OPrivacySkipper Auto

; -----------------------------
; Optional generic addon globals
; Isi manual kalau ada addon lain yang perlu dibungkam.
; Set value sesuai "mode block" yang addon itu butuh.
; -----------------------------
GlobalVariable Property AddonBlockGlobal01 Auto
Float Property AddonBlockGlobal01Value = 0.0 Auto

GlobalVariable Property AddonBlockGlobal02 Auto
Float Property AddonBlockGlobal02Value = 0.0 Auto

GlobalVariable Property AddonBlockGlobal03 Auto
Float Property AddonBlockGlobal03Value = 0.0 Auto

GlobalVariable Property AddonBlockGlobal04 Auto
Float Property AddonBlockGlobal04Value = 0.0 Auto

GlobalVariable Property AddonBlockGlobal05 Auto
Float Property AddonBlockGlobal05Value = 0.0 Auto

GlobalVariable Property AddonBlockGlobal06 Auto
Float Property AddonBlockGlobal06Value = 0.0 Auto

GlobalVariable Property AddonBlockGlobal07 Auto
Float Property AddonBlockGlobal07Value = 0.0 Auto

GlobalVariable Property AddonBlockGlobal08 Auto
Float Property AddonBlockGlobal08Value = 0.0 Auto

; -----------------------------
; Internal state
; -----------------------------
Bool _installed = False
Bool _blockingActive = False
Bool _sceneLatched = False
Float _releaseAt = 0.0

Float _savedOPrivacyApproachEnabled = 0.0
Float _savedOPrivacyLocationCounter = 0.0
Float _savedOPrivacyCombatCounter = 0.0
Float _savedOPrivacyActiveFollow = 0.0
Float _savedOPrivacyAPRunning = 0.0
Float _savedOPrivacySkipper = 0.0

Float _savedAddon01 = 0.0
Float _savedAddon02 = 0.0
Float _savedAddon03 = 0.0
Float _savedAddon04 = 0.0
Float _savedAddon05 = 0.0
Float _savedAddon06 = 0.0
Float _savedAddon07 = 0.0
Float _savedAddon08 = 0.0

Bool _hasSavedOPrivacyApproachEnabled = False
Bool _hasSavedOPrivacyLocationCounter = False
Bool _hasSavedOPrivacyCombatCounter = False
Bool _hasSavedOPrivacyActiveFollow = False
Bool _hasSavedOPrivacyAPRunning = False
Bool _hasSavedOPrivacySkipper = False

Bool _hasSavedAddon01 = False
Bool _hasSavedAddon02 = False
Bool _hasSavedAddon03 = False
Bool _hasSavedAddon04 = False
Bool _hasSavedAddon05 = False
Bool _hasSavedAddon06 = False
Bool _hasSavedAddon07 = False
Bool _hasSavedAddon08 = False


Event OnInit()
	InstallBlocker()
EndEvent

Event OnPlayerLoadGame()
	ReinstallBlockerAfterLoad()
EndEvent

Function InstallBlocker()
	if _installed
		RegisterEvents()
		ArmPollingUpdate()
		Log("install refresh")
		return
	endif

	_installed = True
	RegisterEvents()
	Log("installed")
	ArmPollingUpdate()
EndFunction

Function ReinstallBlockerAfterLoad()
	_installed = True
	RegisterEvents()
	ArmPollingUpdate()
	Log("reinstalled after load")
EndFunction

Function ArmPollingUpdate()
	UnregisterForUpdate()
	QueuePollingUpdate()
EndFunction

Function QueuePollingUpdate()
	Float interval = PollSeconds

	if interval <= 0.0
		interval = 0.50
	endif

	RegisterForSingleUpdate(interval)
EndFunction

Function RegisterEvents()
	UnregisterForAllModEvents()

	RegisterForModEvent("TFDPreCombatPleasureStartPending", "OnTFDStartPending")
	RegisterForModEvent("TFDPreCombatPleasureStarted", "OnTFDSceneStarted")
	RegisterForModEvent("TFDOStimSceneStartPending", "OnTFDStartPending")
	RegisterForModEvent("TFDOStimSceneStarted", "OnTFDSceneStarted")
	RegisterForModEvent("TFDOStimSceneEnded", "OnTFDSceneEnded")
	RegisterForModEvent("TFDPreCombatPleasureEnded", "OnTFDSceneEnded")
	RegisterForModEvent("TFDPreCombatPleasureFailed", "OnTFDSceneEnded")
	RegisterForModEvent("TFDAfterPleasureEnter", "OnTFDAfterPleasureEnter")
	RegisterForModEvent("TFDAfterPleasureChoicePleasure", "OnTFDChoiceRedo")
	RegisterForModEvent("TFDAfterPleasureChoiceFinish", "OnTFDChoiceResolve")
	RegisterForModEvent("TFDAfterPleasureChoiceRecruit", "OnTFDChoiceResolve")
	RegisterForModEvent("TFDAfterPleasureChoiceJoinEnemy", "OnTFDChoiceResolve")
	RegisterForModEvent("TFDAfterPleasureChoiceRelease", "OnTFDChoiceResolve")
	RegisterForModEvent("TFDAfterPleasureChoiceWork", "OnTFDChoiceResolve")
	RegisterForModEvent("TFDAfterPleasureChoiceKidnap", "OnTFDChoiceResolve")
EndFunction

Event OnUpdate()
	Bool shouldBlock = ComputeExclusiveWindow()

	if shouldBlock
		_releaseAt = 0.0

		if !_blockingActive
			BeginBlock()
		else
			RefreshBlock()
		endif
	else
		if _blockingActive
			if _releaseAt <= 0.0
				_releaseAt = Utility.GetCurrentRealTime() + ReleaseDelaySeconds
				Log("release armed")
			elseif Utility.GetCurrentRealTime() >= _releaseAt
				EndBlock()
			endif
		endif
	endif

	QueuePollingUpdate()
EndEvent

Event OnTFDStartPending(String eventName, String strArg, Float numArg, Form sender)
	_sceneLatched = True
	Log("event " + eventName + " latched=1")
EndEvent

Event OnTFDSceneStarted(String eventName, String strArg, Float numArg, Form sender)
	_sceneLatched = True
	Log("event " + eventName + " scene=1")
EndEvent

Event OnTFDSceneEnded(String eventName, String strArg, Float numArg, Form sender)
	_sceneLatched = False
	_releaseAt = Utility.GetCurrentRealTime() + ReleaseDelaySeconds
	Log("event " + eventName + " scene=0 release armed")
EndEvent

Event OnTFDAfterPleasureEnter(String eventName, String strArg, Float numArg, Form sender)
	_sceneLatched = True
	Log("event " + eventName + " afterpleasure=1")
EndEvent

Event OnTFDChoiceRedo(String eventName, String strArg, Float numArg, Form sender)
	_sceneLatched = True
	Log("event " + eventName + " redo=1")
EndEvent

Event OnTFDChoiceResolve(String eventName, String strArg, Float numArg, Form sender)
	_sceneLatched = False
	_releaseAt = Utility.GetCurrentRealTime() + ReleaseDelaySeconds
	Log("event " + eventName + " resolve=1 release armed")
EndEvent

Bool Function ComputeExclusiveWindow()
	if _sceneLatched
		return True
	endif

	if ReadGV(TFDPleasureState) > 0.0
		return True
	endif

	if ReadGV(TFDDialogueState) > 0.0
		return True
	endif

	if ReadGV(TFDInteractionState) > 0.0
		return True
	endif

	; defeat/captive/precombat/incombat tetap dianggap eksklusif
	; supaya topic random addon tidak masuk saat TFD lagi pegang flow.
	if ReadGV(TFDDefeatState) > 0.0
		return True
	endif

	if ReadGV(TFDCaptiveState) > 0.0
		return True
	endif

	if ReadGV(TFDPreCombatState) > 0.0
		return True
	endif

	if ReadGV(TFDInCombatState) > 0.0
		return True
	endif

	return False
EndFunction

Function BeginBlock()
	SaveCurrentValues()
	ApplyBlockedValues()
	_blockingActive = True
	Log("block begin")
EndFunction

Function RefreshBlock()
	ApplyBlockedValues()
EndFunction

Function EndBlock()
	RestoreSavedValues()
	_blockingActive = False
	_releaseAt = 0.0
	Log("block end")
EndFunction

Function SaveCurrentValues()
	if OPrivacyApproachEnabled != None && !_hasSavedOPrivacyApproachEnabled
		_savedOPrivacyApproachEnabled = OPrivacyApproachEnabled.GetValue()
		_hasSavedOPrivacyApproachEnabled = True
	endif

	if OPrivacyLocationCounter != None && !_hasSavedOPrivacyLocationCounter
		_savedOPrivacyLocationCounter = OPrivacyLocationCounter.GetValue()
		_hasSavedOPrivacyLocationCounter = True
	endif

	if OPrivacyCombatCounter != None && !_hasSavedOPrivacyCombatCounter
		_savedOPrivacyCombatCounter = OPrivacyCombatCounter.GetValue()
		_hasSavedOPrivacyCombatCounter = True
	endif

	if OPrivacyActiveFollow != None && !_hasSavedOPrivacyActiveFollow
		_savedOPrivacyActiveFollow = OPrivacyActiveFollow.GetValue()
		_hasSavedOPrivacyActiveFollow = True
	endif

	if OPrivacyAPRunning != None && !_hasSavedOPrivacyAPRunning
		_savedOPrivacyAPRunning = OPrivacyAPRunning.GetValue()
		_hasSavedOPrivacyAPRunning = True
	endif

	if OPrivacySkipper != None && !_hasSavedOPrivacySkipper
		_savedOPrivacySkipper = OPrivacySkipper.GetValue()
		_hasSavedOPrivacySkipper = True
	endif

	if AddonBlockGlobal01 != None && !_hasSavedAddon01
		_savedAddon01 = AddonBlockGlobal01.GetValue()
		_hasSavedAddon01 = True
	endif

	if AddonBlockGlobal02 != None && !_hasSavedAddon02
		_savedAddon02 = AddonBlockGlobal02.GetValue()
		_hasSavedAddon02 = True
	endif

	if AddonBlockGlobal03 != None && !_hasSavedAddon03
		_savedAddon03 = AddonBlockGlobal03.GetValue()
		_hasSavedAddon03 = True
	endif

	if AddonBlockGlobal04 != None && !_hasSavedAddon04
		_savedAddon04 = AddonBlockGlobal04.GetValue()
		_hasSavedAddon04 = True
	endif

	if AddonBlockGlobal05 != None && !_hasSavedAddon05
		_savedAddon05 = AddonBlockGlobal05.GetValue()
		_hasSavedAddon05 = True
	endif

	if AddonBlockGlobal06 != None && !_hasSavedAddon06
		_savedAddon06 = AddonBlockGlobal06.GetValue()
		_hasSavedAddon06 = True
	endif

	if AddonBlockGlobal07 != None && !_hasSavedAddon07
		_savedAddon07 = AddonBlockGlobal07.GetValue()
		_hasSavedAddon07 = True
	endif

	if AddonBlockGlobal08 != None && !_hasSavedAddon08
		_savedAddon08 = AddonBlockGlobal08.GetValue()
		_hasSavedAddon08 = True
	endif
EndFunction

Function RestoreSavedValues()
	if OPrivacyApproachEnabled != None && _hasSavedOPrivacyApproachEnabled
		OPrivacyApproachEnabled.SetValue(_savedOPrivacyApproachEnabled)
	endif

	if OPrivacyLocationCounter != None && _hasSavedOPrivacyLocationCounter
		OPrivacyLocationCounter.SetValue(_savedOPrivacyLocationCounter)
	endif

	if OPrivacyCombatCounter != None && _hasSavedOPrivacyCombatCounter
		OPrivacyCombatCounter.SetValue(_savedOPrivacyCombatCounter)
	endif

	if OPrivacyActiveFollow != None && _hasSavedOPrivacyActiveFollow
		OPrivacyActiveFollow.SetValue(_savedOPrivacyActiveFollow)
	endif

	if OPrivacyAPRunning != None && _hasSavedOPrivacyAPRunning
		OPrivacyAPRunning.SetValue(_savedOPrivacyAPRunning)
	endif

	if OPrivacySkipper != None && _hasSavedOPrivacySkipper
		OPrivacySkipper.SetValue(_savedOPrivacySkipper)
	endif

	if AddonBlockGlobal01 != None && _hasSavedAddon01
		AddonBlockGlobal01.SetValue(_savedAddon01)
	endif

	if AddonBlockGlobal02 != None && _hasSavedAddon02
		AddonBlockGlobal02.SetValue(_savedAddon02)
	endif

	if AddonBlockGlobal03 != None && _hasSavedAddon03
		AddonBlockGlobal03.SetValue(_savedAddon03)
	endif

	if AddonBlockGlobal04 != None && _hasSavedAddon04
		AddonBlockGlobal04.SetValue(_savedAddon04)
	endif

	if AddonBlockGlobal05 != None && _hasSavedAddon05
		AddonBlockGlobal05.SetValue(_savedAddon05)
	endif

	if AddonBlockGlobal06 != None && _hasSavedAddon06
		AddonBlockGlobal06.SetValue(_savedAddon06)
	endif

	if AddonBlockGlobal07 != None && _hasSavedAddon07
		AddonBlockGlobal07.SetValue(_savedAddon07)
	endif

	if AddonBlockGlobal08 != None && _hasSavedAddon08
		AddonBlockGlobal08.SetValue(_savedAddon08)
	endif

	_hasSavedOPrivacyApproachEnabled = False
	_hasSavedOPrivacyLocationCounter = False
	_hasSavedOPrivacyCombatCounter = False
	_hasSavedOPrivacyActiveFollow = False
	_hasSavedOPrivacyAPRunning = False
	_hasSavedOPrivacySkipper = False

	_hasSavedAddon01 = False
	_hasSavedAddon02 = False
	_hasSavedAddon03 = False
	_hasSavedAddon04 = False
	_hasSavedAddon05 = False
	_hasSavedAddon06 = False
	_hasSavedAddon07 = False
	_hasSavedAddon08 = False
EndFunction

Function ApplyBlockedValues()
	; OPrivacy specific
	ForceSet(OPrivacyApproachEnabled, 0.0)
	ForceSet(OPrivacyLocationCounter, 0.0)
	ForceSet(OPrivacyCombatCounter, 0.0)
	ForceSet(OPrivacyActiveFollow, 0.0)
	ForceSet(OPrivacyAPRunning, 0.0)
	ForceSet(OPrivacySkipper, 0.0)

	; Generic addon globals
	ForceSet(AddonBlockGlobal01, AddonBlockGlobal01Value)
	ForceSet(AddonBlockGlobal02, AddonBlockGlobal02Value)
	ForceSet(AddonBlockGlobal03, AddonBlockGlobal03Value)
	ForceSet(AddonBlockGlobal04, AddonBlockGlobal04Value)
	ForceSet(AddonBlockGlobal05, AddonBlockGlobal05Value)
	ForceSet(AddonBlockGlobal06, AddonBlockGlobal06Value)
	ForceSet(AddonBlockGlobal07, AddonBlockGlobal07Value)
	ForceSet(AddonBlockGlobal08, AddonBlockGlobal08Value)
EndFunction

Function ForceSet(GlobalVariable gv, Float value)
	if gv == None
		return
	endif

	if gv.GetValue() != value
		gv.SetValue(value)
	endif
EndFunction

Float Function ReadGV(GlobalVariable gv)
	if gv == None
		return 0.0
	endif
	return gv.GetValue()
EndFunction

Function Log(String msg)
	if !DebugEnabled
		return
	endif
	Debug.Trace("[TFD][PleasureInterruptBlocker] " + msg)
EndFunction