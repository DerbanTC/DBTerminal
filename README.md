# The Dummy Blob Terminal
### Wer braucht den Blob
- Jeder, welcher innert 5 Minuten einen Minecraft-Server braucht und keine Setups von Hostern will
- Minecraft-Developer welche oft Test-Server brauchen um Plugin-Konflikte oder Updates zu testen
- Minecraft-Server ohne automatische tägliche Backups

### Welche Features gibt es
- 3-Geteilte Konsole für Minecraft / Commands / bash
- Schnellinstallation eines MC-Server (EULA, IP und Port werden automatisch gesetzt)
- Start, Stop, Restart, SendText und weitere MC-Befele
- Sichere Stops jenachdem ob Spieler auf dem MC-Server eingeloggt sind oder nicht

### DBT-Installation
In erster Linie ist DBT dazu gedacht, auf einem frisch installierten Debian-vServer installiert zu werden.
Dabei werden alle nötigen Packages für DBT und Minecraft installiert, Standard-Ordner für DBT und Minecraft erstellt und die Scripte von DBT gedownloadet. Zudem wird sich DBT nach einem Reboot automatisch starten (Eintrag in der crontab).
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

**Getestete Distrubitionen**
- Debian 9.9 (minimal)

# MC-Features
### MC Schnell-Installation
1. Erstelle einen neuen Ordner im Standard Minecraft-Ordner
2. Lade deine gewünsche minecraft_server.jar in den neuen Ordner hoch
3. Wähle den Server im DBTerminal mit ServerWahl aus
4. Schreibe Start und warte bis der Server vollständig installiert wurde
   - eula.txt & backupconfig.txt wird generiert
   - start.sh wird kopiert
   - sobald die server.proberties generiert wurde wird IP & Port gesetzt
   - warte ca. 75 Sekunden bis der erste Start vollzogen ist
   - Server wird automatisch gestoppt und neu gestartet
5. Logge dich in deinen frisch Installierten Server ein. Done.

### MC Commands
1. Start
   - Installiert und/oder startet den Server
   - Server wird bei einem Ingame-Stop nach 10sek neu gestartet (loop)
2. Stop
   - Stoppt den gewählten und verhindert einen Neustart
   - Sind Spieler online geschieht dies mit Ankündigung und 30sek Verzögerung
3. Restart
   - Stoppt den gewählten Server und startet diesen nach 10sek neu (loop)
   - Sind Spieler online geschieht dies mit Ankündigung und 30se
4. SendText
   - Schreibe Ankündigungen (per tellraw) an die Spieler auf dem gewählten Server
