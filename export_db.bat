@echo off
echo Fermeture de l'application...
adb shell am force-stop com.example.agneaux_app

echo.
echo Export de la base...
adb exec-out run-as com.example.agneaux_app cat databases/agneaux.db > agneaux.db

echo.
echo Terminé.
dir agneaux.db
pause