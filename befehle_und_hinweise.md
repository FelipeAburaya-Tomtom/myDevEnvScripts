# befehle_und_hinweise

## Einstellung der Umgebung

### Grafische Anwendungen in WSL laufen

Zuerst installieren Sie einen X-Server in Windows: [VcXsrv](https://sourceforge.net/projects/vcxsrv/)
```
$ sudo apt install xterm
$ export DISPLAY=localhost:0.0
```
Es ist aber möglich, dass andere Pakete notwendig sind, denn die Abhängigkeit ändern sich, je nach Ubuntu Version.

### Suchen nach apt-Packete

`$ apt-file search libGL.so.1`

### Installieren einer spezifische Version durch pip

```
$ sudo bash
$ pip3 install 'conan>=1.28.0'
```

### .deb Pakete installieren

```
$ sudo dpkg -i ./path_to/you_package.deb
$ sudo apt install -f
```

### Einrichtung der Entwicklungsumgebung für NK2

1. Wenn pkgsrc schon vorhanden ist, lösch es.
2. Stell sicher, dass Ubuntu python3 zur Verfügung stellt.
3. Wenn das System pip3 nicht zur Verfügung steht, installiert es durch `sudo apt install python3-pip`.
4. Dann:
```
$ sudo bash
$ /usr/bin/python3 -m pip install --user --upgrade --index-url https://artifactory.navkit-pipeline.tt3.com/artifactory/api/pypi/pypi-virtual/simple nk2-developer-setup
$ /usr/bin/python3 -m nk2_developer_setup
$ apt install wcstools ccache mesa-common-dev
```
5. Das pip3 im System darf nun gelöscht werden: `sudo apt remove python3-pip`.


### Clang mit CCache für Conan

Für ein Umgebung, das pkgsrc nutzt, läuf einfach das hier:
```
echo '#!/usr/bin/env bash
ccache /usr/local/pkg/bin/clang++ ${TT_CLANG_FLAGS_SANITIZERS} ${TT_CLANG_WARNING_FLAGS} "$@"' | sudo tee /usr/local/pkg/bin/clang++-ccache > /dev/null
 
sudo chmod +x /usr/local/pkg/bin/clang++-ccache
 
echo '#!/usr/bin/env bash
ccache /usr/local/pkg/bin/clang ${TT_CLANG_FLAGS_SANITIZERS} "$@"' | sudo tee /usr/local/pkg/bin/clang-ccache > /dev/null
 
sudo chmod +x /usr/local/pkg/bin/clang-ccache

```

### dependencychecker installieren

```
$ sudo wget -qO - http://artifactory.navkit-pipeline.tt3.com/artifactory/api/gpg/key/public | sudo apt-key add -
$ sudo add-apt-repository "deb http://artifactory.navkit-pipeline.tt3.com/artifactory/navkit-apt-local bionic main" -y
$ sudo apt update
$ sudo apt install dependencychecker=43.0.0+gf4af8ed
```
The version number is witchcraft:

`$ apt-cache madison dependencychecker | grep "43\."`


## NavKit2

### Wie entziffert man einen Aufrufstapel?

1. Man findet [hier](https://confluence.tomtomgroup.com/display/NAV/Android+-+19.1.0) heraus, welche Versionen von jeden Paket ein SDK-Release bilden.
2. Pakete müssen von dem [Artifactory](https://artifactory.navkit-pipeline.tt3.com/ui/repos/tree/General/navkit2-maven-release-local%2Fcom%2Ftomtom%2Fnavkit2%2Fndk) heruntergeladen werden;
3. Nachdem die Bibliotheken entpackt wurden, führ aus: "`ndk-stack -sym ./libraries/obj -dump call_stack_trace.txt`".


### Erstellung und Betrieb des NK2UI

1. `git clone` den Code von [GitHub Repository](https://github.com/tomtom-internal/nk2ui-main);
2. Nachdem man `./gradlew :updateEnvironment` ausgeführt hat, befinden sich die richtige JDK und Android-SDK im Repository;
3. Im Konsole muss man jedes mal zuerst `source environment_settings` ausführen, um die richtige SDK zu nutzen;
4. `./gradlew createEmulator` 
5. Füg dem Emulator eine große SD-Karte hinzu (etwa 32 GB);
6. `./gradlew startEmulator`
7. Die Erstellung des APK kann mithilfe Android Studio durchgeführt werden, dann `adb install -g built_application.apk`, ODER auf einmal mit `./gradlew installDebug`

Einrichtung des "onboard map":

8. Stell die SD-Karte als "portable storage" ein;
9. Läd die SD-Karte mit deiner ausgewählte Karte mithilfe `adb push`;
10. In NK2UI wähl Onboard-Navigation aus;
11. Estell eine Datei "`onboard-map-override.json`":
```
{
 "mapPath": "/sdcard/map/DATA",
 "mapKeystorePath": "/sdcard/map/NK_AUTO_DEV.NKS",
 "mapKeystorePassword": "dL8Oe.5pi9dk4-"
}
```
12. `adb push onboard-map-override.json /storage/emulated/0/Android/data/com.tomtom.navkit2ui/files/onboard-map-override.json`
13. Start die NK2UI Anwedung neu;

Bewegung an einer Route entlang kann so simuliert werden:

14. `adb shell am startservice -a com.tomtom.positioning.player.START -e sensor_off 255 -e "log_file" "/sdcard/file.ttp"`
15. `adb shell am startservice -a com.tomtom.positioning.player.STOP`

Und am Ende kann man entweder "`./gradlew stopEmulator`" oder "`./gradlew deleteEmulator`".


### Ist meine Änderung schon in NK2UI integriert?

1. Führt in NK2UI Repository `./gradlew :app:dependencies` aus, um festzustellen, welche Version von `com.tomtom.navkit2:core-bom` verwendet ist;
2. Diese Version findet man im [Verlauf des BOM für Android](https://bitbucket.tomtomgroup.com/projects/NAVKIT2/repos/nk2-bom-android/commits);
3. Deren Commit verrät, welche Version von ["cross platform BOM"](https://bitbucket.tomtomgroup.com/projects/NAVKIT2/repos/nk2-bom-crossplatform/browse) verwendet wurde;


### Erstellung der Awendung example-app-android

```
$ cd nk2/nk2-example-app-android
$ echo apiKey=AG4j98gQWvNRhb1UtKpXPAQzTARwZkBf > nk2-example-app-android/.env
$ ./gradlew assembleRelease
$ ./gradlew pushMapResources
```

### Wie kann man das guidance_kml_dumper debuggen?

Das ist ein Beispiel für die erwarteten Argumente in den Debug Einstellungen:
```
"program": "/home/aburaya/tom2/nk2/nk2-navigation-instruction-engine/build/bin/guidance_kml_dumper",
"args": [
    "-m",
    "instruction",
    "--map_path",
    "/home/aburaya/tom2/nk2/nk2-navigation-instruction-engine/build/bin/regression_test/instruction_regression/maps/hcp3_berlin/hcp3_berlin",
    "--keystore_path",
    "/home/aburaya/tom2/nk2/nk2-navigation-instruction-engine/build/bin/regression_test/instruction_regression/maps/hcp3_berlin/keystore.sqlite",
    "--keystore_password",
    "dL8Oe.5pi9dk4-",
    "-k",
    "/home/aburaya/tom2/nk2/nk2-navigation-instruction-engine/navigation-instruction-engine/test/regression/instruction_regression/reference/hcp3_berlin/berlin_turn_sharp_right.kml",
    "-i"
],
```

### Wie kann man das nav-engine debuggen?

Diese sind die Argumente für die Debug Einstellungen:
```
"args": [
    "./nav-engine",
    "--api",
    "AG4j98gQWvNRhb1UtKpXPAQzTARwZkBf",
    "--map",
    "/maps/local_maps/navkit/NDSmaps/NDS_AutomotiveReference_2019.12_2.4.6_EUR_IQ/DATA",
    "--keystore",
    "/maps/local_maps/navkit/NK_AUTO_DEV.NKS",
    "--password",
    "dL8Oe.5pi9dk4-",
    "--guidance-mode",
    "onboard-v2"
],
```

### Vorbereitung eines Pakets mit einem Schnitt einer NDS-Karte

1. Lade die Karte aus [NDS Web Viewer](https://nds.tomtomgroup.com/view_maps) herunter.
2. Entpack die Karte mithilfe `tar -xf`.
3. Lösche den Ordner `STATS`.
4. Für die nächsten Schritte wirst du das Skript `nds-utils.sh` anwenden. Mehr darüber erfahren: [hier](https://confluence.tomtomgroup.com/pages/viewpage.action?spaceKey=~shariful&title=NDS+shell+to+explore+update+regions+and+strip+from+NDS+maps) und [hier](https://confluence.tomtomgroup.com/pages/viewpage.action?spaceKey=NAV&title=Stripping+Europe+map+-+VCOT).
5. Du wirst `sqlite3_shell` gebrauchen. Gehe ins NAVKIT Repository und erstell das Ziel `sqlite3_shell`, dann `export NDS_SHELL=path_to/sqlite3_shell`
5. Gibt es viele Produkte innerhalb des Ordners `DATA`. Bitte liste alle `PRODUCT.NDS` Dateien auf.
6. Für jedes Produkt, liste bitte alle Regionen auf, indem du diesen Befehlt ausführst: `./nds_utils.sh DATA/123/456/PRODUCT.NDS`.
7. Du darfst alle Regionen löschen, die du nicht brauchst, indem diesen Befehl ausführst: `./nds_utils.sh DATA/123/456/PRODUCT.NDS 101 102 103 ...`
8. So sind die gelöschte Regionen aus der Datenbank verschwunden, aber die entsprechenden Ordner müssen noch gelöscht werden.
9. Die Verzeichnisstruktur muss diesem Muster folgen:
```
res/keystore.sqlite
res/DATA/ROOT.NDS
res/DATA/...
```
10. Pack mittels `tar cvf map.tar res` den Ordner.
11. Rechne das MD5-Hash mittels `md5sum file.tar`
12. Umbennene die Datei mittels `mv file.tar H45H000...`
13. Lade die Datei hoch: `curl -u root:root123 -T H45H000... "https://artifactory.navkit-pipeline.tt3.com/artifactory/navkit2-test-maps-local/MD5/"`
14. Folge den in [hier](https://confluence.tomtomgroup.com/pages/viewpage.action?spaceKey=NAV&title=How+to+create+new+Conan+map+packages) beschriebenen  Schritten.

## Hardware

### Mounting

`$ sudo mount /dev/cdrom /media/your_cdrom_dir`

### Speicherplatte

Check if you have a SSD disk installed. The source code should be located on the SSD to accelerate compiling. The map data can be stored on the harddisk. To find out if a disk, e.g. sda, is a SSD, execute

`$ cat /sys/block/sda/queue/rotational`

It returns 0 for SSDs and 1 for normal hard drives. To find out which disks are available look for sda, sdb etc in the directory /dev.

Man kann das Laufwerk so mounten:

`$ mount /what_to_mount /where`

oder unter WSL:

`$ sudo mount -t drvfs D: /mnt/d`


## GIT

### Working on a branch from previous release

Preparing the branch:
```
$ git remote add rel-19.4 https://bitbucket.tomtomgroup.com/scm/navkit/rel-19.4.git
$ git fetch rel-19.4
$ git checkout -b release19.4 rel-19.4/master
$ git branch --set-upstream-to=rel-19.4/master release19.4
```
And once you are done:

`$ git push -u rel-18.4 HEAD`


### Choosing files on merging conflict

`$ git cherry-pick -Xours ...`

OR

`$ git cherry-pick -Xtheirs ...`

