; AutoHotkey
; Opens Terminal and exports EA's SET file.

Run, "C:\Program Files (x86)\XM UK MT4\terminal.exe"
WinWaitActive, ahk_exe terminal.exe
if ErrorLevel {
    MsgBox, WinWait timed out.
    return
}
Sleep, 500
Send, {Esc}, {Esc} ; Close popups.
Sleep, 500
ControlGet, IsVisible, Visible, , Button1, ahk_exe terminal.exe
if (!IsVisible) {
	; View Strategy Tester, if not present.
	Send, ^r
	Sleep, 200
}

; Press _Expert properties_ button.
ControlClick, Button1, ahk_exe terminal.exe
if ErrorLevel {
    MsgBox, Cannot find Expert properties.
    return
}
WinWaitActive, ahk_class #32770
Sleep, 200

; Press _Save_.
ControlClick, &Save, ahk_class #32770
if ErrorLevel {
    MsgBox, Cannot find Save button.
    return
}
Sleep, 2000

; Type filename, and confirm.
ControlSend, Edit1, Test.set, ahk_class #32770
if ErrorLevel {
    MsgBox, Cannot type the filename.
    return
}
Sleep, 200
Send, {Enter}
Sleep, 500

; If asked to replace the file, confirm.
Sleep, 2000
ControlGet, Handle, Hwnd, , Button1, ahk_class #32770
if (Handle) {
	ControlClick, , ahk_id %Handle%
}
Sleep, 200

; Press Accept.
ControlClick, Button5, ahk_class #32770
Sleep, 200

; Close Terminal.
Send, !fx, !{F4} ; File->Exit, Alt-F4
Sleep, 200