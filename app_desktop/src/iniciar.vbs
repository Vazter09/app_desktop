' Arranque sin ventana de consola (usa pythonw.exe de runtime/.venv).
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
srcDir = fso.GetParentFolderName(WScript.ScriptFullName)
moduleDir = fso.GetParentFolderName(srcDir)
pythonw = moduleDir & "\runtime\.venv\Scripts\pythonw.exe"
mainPy = srcDir & "\main.py"
If Not fso.FileExists(pythonw) Then
    pythonw = moduleDir & "\runtime\.venv\Scripts\python.exe"
End If
sh.CurrentDirectory = srcDir
sh.Environment("Process")("SMARTCSET_VENV_ACTIVE") = "1"
' 0 = sin ventana de consola; False = no esperar (un solo arranque).
sh.Run """" & pythonw & """ """ & mainPy & """", 0, False
