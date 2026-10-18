@echo off
:: Disable Software Write Protection
reg add "HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies" /v WriteProtect /t REG_DWORD /d 0 /f
echo Write protection disabled.
pause