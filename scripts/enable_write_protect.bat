@echo off
:: Enable Software Write Protection for Removable Storage (ISO 27037 compliance)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies" /v WriteProtect /t REG_DWORD /d 1 /f
echo Write protection enabled.
pause