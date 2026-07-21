' Arranque sin ventana de consola (usa pythonw.exe del .venv local).
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
appDir = fso.GetParentFolderName(WScript.ScriptFullName)
pythonw = appDir & "\.venv\Scripts\pythonw.exe"
mainPy = appDir & "\main.py"
If Not fso.FileExists(pythonw) Then
    pythonw = appDir & "\.venv\Scripts\python.exe"
End If
sh.CurrentDirectory = appDir
sh.Environment("Process")("SMARTCSET_VENV_ACTIVE") = "1"
' 0 = sin ventana de consola; False = no esperar (un solo arranque).
sh.Run """" & pythonw & """ """ & mainPy & """", 0, False
