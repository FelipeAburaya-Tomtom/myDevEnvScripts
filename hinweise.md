# Shell Befehle und Hinweise

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

### Setting up hooks

`$ ./Scripts/git_clang_format_and_dependencychecker_hook_install.sh`


# Building Navkit

## Newbie mistakes

At January 2018 I was using Ubuntu 16.04 (latest LTS release) and had the following issues when trying  a distributed build of Navkit:

* Forgot to install Apache Ivy. That is done by running the following pre-build command:

    `$ ./build.py -f your-profile.yaml -s Generate`

## Installing NK1

`$ Engines/Routing/Test/Scripts/createX86RunDir.py -t clang -x64 -m Debug|Release`

When building outside source (with QtCreator for example), you need to tell where to place the directory 'test-artifacts':

```
$ Engines/Routing/Test/Scripts/createX86RunDir.py --build-directory ../build-navkit-ClangLinux64-Debug/ \
                                                  --location ../build-navkit-ClangLinux64-Debug/ \
                                                  -t clang -x64 -m Debug|Release
```

### Running component tests

The first run of some component tests need to be invoked by the build script, so as to setup necessary resources. Example of command:

`$ ./build.py -f Linux-x86_64.yaml -j16 -s Test -tl component,NDS -tf "Engines.Routing.Test.AutomaticTest.RouteInfo.NavCore.InstructionTracking_componenttest.*"`

The next runs can find everything set below the directory `./Build/Output/Binary/x86_64-Linux-clang/Debug/test/component/`


### Running interface tests

Reflection tests can be started like this:

`$ ./build.py -f Linux-x86_64.yaml -j1 -s Test --test_labels_include interface,NDS --test_labels_exclude Quarantine,GeoRegionsSouthKorea,Performance,PMF -m Release|Debug`

(Definitions come from `Build/Output/Binary/x86_64-Linux-clang/Debug/test/res/test_definitions/test-def.xml` - Override this file with the configuration of the pipeline you want to reproduce, such as `./TestTools/TestDefs/NDS/Nightly/Linux-X86/Reflection/test-def.xml`)

while a single test can be run in ClientAPI/Test with

`$ ant singletest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtestclass=com.tomtom.testcases.reflection.routeConstructor.backToRoute.BackToRouteExtendedTest -Dtestcase=test_RTE_B2R_DeviateAfterEachViaPointWithAllViaPointsOnCrossings -Dinclude=NDS`

and all tests within a class can be run (also in ClientAPI/Test) with

`$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtest=InitialInDriveAlternativesParameterizedThrillingTest -Dinclude=NDS`

## Running smoke tests

First you might need to get a full set of maps from torrent. Check [this page](https://confluence.tomtomgroup.com/display/NAVKIT/Map+Distribution) to download the torrent file.

(Any specific version of the map you are looking for can be found in the script code of `./Engines/Routing/Test/Scripts/runGuidanceSmokeTest.py`).

### Before release 18

(At least in release 17.4, it is like this)

You need to build in RELEASE mode the target `Engines.Routing.Test.BatchRouter.Default.TileLeveling.FOR.NDS`.

Having built the release in a sandbox, for every map you run:
```
$ sandbox Engines/Routing/Test/Scripts/dumpInstructions.sh \
  Engines/Routing/Test/Scripts/etc/InstructionDumper/odpairs/smoketest/Europe_Regression.od \
  Europe_2.4.3_11503 \
  Engines/Routing/Test/Scripts/etc/InstructionDumper/reference/nds/Europe_Regression
```
(The relative path for the map is mentioned in `"Engines/Routing/Test/AutomaticTest/RouteInfo/Instructions/test_runner.py"`.)

The instructions will be dumped into the file `"./compare-NDS/dumps/Instructions.sqlite"`. For comparison with reference results, you run:
```
$ Engines/Routing/Test/Scripts/instr_dumper_analyzer/compareInstructions.py --verbose \
  Engines/Routing/Test/Scripts/etc/InstructionDumper/reference/nds/Europe_Regression.sqlite \
  compare-NDS/dumps/Instructions.sqlite
```
If you are updating the expectations for smoke tests, you must use the dump to update the references residing in the repository:
```
Engines/Routing/Test/Scripts/etc/InstructionDumper/reference/nds/Europe_Regression.sqlite
Engines/Routing/Test/Scripts/etc/InstructionDumper/reference/nds/USA_Canada_and_Mexico_Regression.sqlite
Engines/Routing/Test/Scripts/etc/InstructionDumper/reference/nds/China_Regression.sqlite
Engines/Routing/Test/Scripts/etc/InstructionDumper/reference/nds/Middle_East_Arabic_Regression.sqlite
```
A more thorough guide about smoke tests is available [here](https://confluence.tomtomgroup.com/pages/viewpage.action?spaceKey=NAVKIT&title=%5BGuidance%5D+Instructions+smoke+and+mass+testing).


### Recent releases

Just run `"Engines/Routing/Test/Scripts/runGuidanceSmokeTest.py"`. The dumps will be placed in separate files for each map.


## Running the batch router

From the runtime directory:

```
$ ./Engines.Routing.Test.BatchRouter.Default.TileLeveling.FOR.NDS \
  map=home/NDS_Automotive_2018.04_2.4.3_JPN_Zenrin_0918_Minor_V2/DATA \
  odfile=route.od routeFormat=kml dumpInstructions=1 maxThreads=1
```

## Converting real maps into mock maps

```
$ ./DataAccess.NDSMock.Test.NDS2TTM.FOR.NDS \
  --map /media/faburaya/EVO/maps/local_maps/navkit/NDSmaps/NDS_AutomotiveReference_2019.12_2.4.6_EUR_IQ \
  --area 48.092028,11.539556:48.095339,11.542066 \
  --languages "deu","eng" \
  --dump-coordinates \
  --dump-arc-lengths \
  --dump-arc-shapes \
  --dump-routing-angles \
  --dump-road-forms \
  --dump-functional-road-classes \
  --dump-administrative-road-classes \
  --dump-street-name \
  --dump-road-numbers \
  --dump-road-flags \
  --dump-number-lanes \
  --dump-lane-connectivity-across-features

```


## Running performance tests

1) Run PerfAgent in a terminal

`$ ./Output/Binary/x86_64-Linux/Release/bin/TestTools.PerfAgent.Posix`

2) Run NavKit in a 2nd terminal (tries to connect to PerfAgent)
```
$ cd ./Linux-x86_64-RunDir/test-artifacts/release/app
$ ./NavKitApp.NDS
```

3) Run system metric collector in 3rd terminal (tries to find NavKit AND connect to PerfAgent)

`$ ./Output/Binary/x86_64-Linux/Release/bin/SystemMetricsSampler/collector.py`

4) Run test in 4th terminal (tries to connect to PerfAgent AND to NavKit)
```
$ cd ../ClientAPI/Test
$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux/Release/test/interface/reflection/ -Dtest=TheNameOfYourPerformanceTest
```

## Build & Deploy on device

Mount the sdcard in the PC and place the maps and keystore there, then
```
$ adb shell

root@italia: # cd /mnt/sdcard/ttndata
root@italia:/mnt/sdcard/ttndata # mv /storage/XXXX-YYYY/keystore_file files/keystore.sqlite
root@italia:/mnt/sdcard/ttndata # echo '/storage/XXXX-YYYY/map_directory' > altpath.dat
```

Enable your external NavKit:

`$ adb shell touch /sdcard/ttndata/files/forceUseExternalNavKit`

Build:
`$ ./build-no-ct-devenv -f Android-armv7.yaml -j16 -m Release NavKitService.NDS Publish.ServicesConnector`

Uninstall the previous packages and reinstall:
```
$ adb uninstall com.tomtom.navkit
$ adb uninstall com.tomtom.extension.services
$ adb install -g ./Output/Binary/armv7-Android/Release/bin/NavKitService.NDS-release.apk
$ adb install -g ./Output/Binary/armv7-Android/Release/bin/ServicesConnector-release.apk
```
(If you get INSTALL_FAILED_UPDATE_INCOMPATIBLE, then uninstall the package via device GUI. ServicesConnector might appear as an app with a blank name.)

If needed, one can get rid of the stock NavApp by running:
```
$ adb uninstall com.tomtom.navui.stocknavapp
```
While the application stack can be shut down by:
```
$ adb shell am force-stop com.tomtom.navui.stocknavapp && adb shell am force-stop com.tomtom.navkit
```

You can setup port forwarding in order to have DevUI on the desktop connected to NavKit in the device:

`$ adb forward tcp:3000 tcp:3000`

That can later be undone with

`$ adb forward --remove-all`

Fake GPS location (provided the service is already installed) can be set by:

`$ adb shell am startservice -a com.tomtom.tool.fakegps.START  -e lat '42.653791' -e lon '-83.233631'`

## Set up for testing with dynamic POI data

In QtCreator, you will build first the targets `NavKit.FOR.NDS` and `Extensions.ServiceConnectors.Host.CommandLine.Default`.

For getting data from Perseus and AMS, we use a channel secured by certificates. The default configuration for the connector and server certificates are already in place after running `"createX86RunDir.py"`:
```
$ cd ./test-artifacts/debug/app
$ nano connector.xml
```
Presumably, there is nothing to change in the default configuration because it already has
```
...
    <Protocol Id="12000" Name="AMS Client" Type="AMSClient">
...
<settingsGroup name="AMSClientProtocol">

    <setting name="Certificate" value="client.pem"/>

    <setting name="CertificateKey" value=""/>

    <setting name="CertificateBundle" value="tomtom-ams-server-side-ca.crt"/>
    ...
</settingsGroup>
...
<settingsGroup name="PerseusProtocol">

    <setting name="UseHostFromPerseusInitSession" value="true"/>

    <setting name="CertificateBundle" value="perseus.crt"/>
    ...
</settingsGroup>
```
But you do need to generate the **client.pem** from the client certificate file assigned to you:

`$ openssl pkcs12 -in NavKit395.p12 -out client.pem -nodes`

(the password is "*changeit*")

You only get data for a region around your current position. In order to trigger the receival, from DevUI you can start the map viewer and place the car where dynamic data would be available.

## Verarbeitung der Spuranleitung

Wenn man ändert Spuranleitung, bitte erinner daran, die unten aufgelisteten Tests zu prüfen:

```
test ClientAPI.iRouteInfo.Test.AutomaticTest.Instructions_componenttest.ALL
test Engines.Routing.Test.Unittest.RouteInfo.Instructions_unittest.ALL
test Engines.Routing.Test.ComponentTest.InstructionsOnMockMap_componenttest.ALL
test Engines.Routing.Test.ComponentTest.RouteInfo.NavKitInstructionBuildingOnMockMap_componenttest.ALL
test Engines.Routing.Test.AutomaticTest.RouteInfo.DecisionPoints_componenttest.ALL
test Engines.Routing.Test.AutomaticTest.RouteInfo.Instructions_componenttest.ALL
test Engines.Routing.Test.AutomaticTest.RouteInfo.InstructionsOnMockMap_componenttest.ALL
test Engines.Routing.Test.AutomaticTest.RouteInfo.NavCore.NCInstructions_componenttest.ALL
```
Manchmal während einer Rückportierung scheitern einige Tests wegen fehlender Verbindungen zu den Karten. Wenn es so ist, können diese Befehle unter das Verzeichnis *./home* ausgeführt werden, um die Verbindungen zu herstellen:
```
$ ln -s /maps/local_maps/navkit/NDSmaps/USA_Canada_and_Mexico_2.4.6_2018.09_18211 USA_Canada_and_Mexico_NDS; \
  ln -s /maps/local_maps/navkit/NDSmaps/NDS_Automotive_2019.04_2.4.3_JPN_Zenrin_0120_Major_V1/DATA Japan_NDS; \
  ln -s /maps/local_maps/navkit/NDSmaps/China_5_Cities_2016.09_2.4.3_18068 China_NDS
```

```
$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtest=LaneGuidanceTest \
 -Dmap.name=NDS_AutomotiveReference_2019.12_2.4.6_EUR_IQ \
 -Dinclude=NDS

$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtest=LaneGuidanceTest \
 -Dmap.name=NDS_AutomotiveReference_2019.12_2.4.6_NAM_IQ \
 -Dinclude=NDS

$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtest=LaneGuidanceTest \
 -Dmap.name=Asia_Pacific_2.4.6_2018.09_17822 \
 -Dinclude=NDS

$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin \
 -Dtest=InstructionsFollowLaneTestUSA \
 -Dmap.name=NDS_AutomotiveReference_2019.12_2.4.6_NAM_IQ \
 -Dinclude=NDS

$ ant singletest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin \
 -Dtestclass=com.tomtom.testcases.reflection.routeInfo.DecisionPointInstructionsDataTest \
 -Dtestcase=test_Guidance_DecisionPointInstructions_LaneGuidanceData \
 -Dmap.name=NDS_AutomotiveReference_2019.12_2.4.6_EUR_IQ \
 -Dinclude=NDS
```

## Fixing direction in the legacy instruction builder

When making changes in the legacy builder with intention of fixing issued directions, additionally to the tests that have to be checked for work in lane guidance (see in the section above), remember to also check these:

```
test Engines.Routing.Test.ComponentTest.RouteInfo.InstructionTrackerOnMockMap_componenttest.ALL
test Engines.Routing.Test.AutomaticTest.RouteInfo.NavCore.SideRoads_componenttest.ALL
```
```
$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtest=InstructionsTest \
 -Dmap.name=NDS_AutomotiveReference_2019.12_2.4.6_EUR_IQ \
 -Dinclude=NDS

$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtest=InstructionsTest \
 -Dmap.name=Asia_Pacific_2.4.6_2018.09_17822 \
 -Dinclude=NDS

$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtest=RegionalTest \
 -Dmap.name=NDS_AutomotiveReference_2019.12_2.4.6_NAM_IQ \
 -Dinclude=NDS

$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtest=RegionalTest \
 -Dmap.name=Asia_Pacific_2.4.6_2018.09_17822 \
 -Dinclude=NDS

$ ant runtest -Djar.dir=../../Build/Output/Binary/x86_64-Linux-clang/Debug/test/interface/reflection/ \
 -Dapplication.path=../../Build/Output/Binary/x86_64-Linux-clang/Debug/bin -Dtest=InstructionsTest \
 -Dmap.name=Middle_East_and_Africa_2.4.6_2018.09_18220 \
 -Dinclude=NDS
```
