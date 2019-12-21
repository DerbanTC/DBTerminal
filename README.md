# The Dummy Blob Terminal

**Installation**
```
wget --no-check-certificate -P /YOUR_DIRECTORY/DBTerminal/ https://raw.githubusercontent.com/DerbanTC/DBTerminal/master/install.sh && chmod +x /YOUR_DIRECTORY/DBTerminal/install.sh
cd YOUR_DIRECTORY
./install.sh
```
Wichtig: Ändere `YOUR_DIRECTORY` zu einem Ordner deiner Wahl z.B. `/home/`.

**Merke**
- Es wird ein Ordner `DBTerminal` erstellt abhängig davon, in welchem Ordner die Datei `install.sh` gestartet wurde
- Es wird ein Ordner `minecraft` erstellt abhängig von dem Eintrag `mcDir` in der Datei `stdvariables.sh`
- Standard-Ordner für Minecraft ist `/minecraft/`. Ändere den Eintrag `mcDir` und reboote dein Server
- Die `start.sh` welche für den Start des Minecraft-Servers dient muss aktuell manuell angepasst werden
