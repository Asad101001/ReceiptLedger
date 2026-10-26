Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""c:\Users\Asad\Desktop\ReceiptLedger\scripts\start_backend.ps1""", 0, False
