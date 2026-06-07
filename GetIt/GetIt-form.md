# GetIt submission form - LoggerPro 2.1.1

## Library Zip file URL

https://github.com/danieleteti/loggerpro/releases/download/v2.1.1/loggerpro-2.1.1.zip

> Upload `loggerpro-2.1.1.zip` as an asset of the GitHub release `v2.1.1` so this URL resolves.

## Installation process

LoggerPro is a source-only library: all units are runtime units, no design-time package or component installation is required.

To install:
1. Extract the zip. Sources are under the "loggerpro" folder: the root *.pas units, the "packages" folder (one runtime package per RAD Studio version) and the "samples" folder.
2. Add the "loggerpro" root folder to the IDE Library Path (Tools > Options > Language > Delphi > Library) for every target platform you use (Win32, Win64, ...). This is the only mandatory step: after it you can use any unit with "uses LoggerPro;".
3. (Optional) If you prefer a precompiled runtime BPL instead of compiling the sources into each project, open packages\d<XXX>\loggerproRT.dproj matching your RAD Studio version and build it. It is a runtime-only package ({$RUNONLY}), so nothing has to be installed into the IDE.

No external installer is executed and RAD Studio does NOT need to be closed during installation.

## Uninstallation process

1. Remove the "loggerpro" root folder entry from the IDE Library Path (Tools > Options > Language > Delphi > Library) for every platform where it was added.
2. If the optional runtime package was built, delete the generated loggerproRT*.bpl and loggerproRT*.dcp from your output / bpl folders.
3. Delete the extracted "loggerpro" folder.

No Windows uninstaller and no registered IDE package are involved.
