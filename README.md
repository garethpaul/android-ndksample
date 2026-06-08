# Android NDK Sample

Legacy Android NDK port of the San Angeles OpenGL ES demo. The repository keeps
the original native C sources, Android makefiles, license files, and prebuilt
ABI libraries together for preservation.

## Artifact Policy

The checked-in `libs/*/libsanangeles.so` files and `obj/` tree are legacy native
build artifacts. Do not replace or remove them unless the change also documents:

- NDK version.
- Build command.
- Source revision.
- Target ABI list.
- Verification result on a device or emulator.

## Toolchain

The project uses the old Ant/NDK Android project layout:

- `project.properties` targets `Google Inc.:Google APIs:21`.
- Native build metadata lives in `jni/Android.mk` and `jni/Application.mk`.
- Java entrypoint is `src/com/example/SanAngeles/DemoActivity.java`.

This environment does not currently provide `ndk-build` or `ant`, so full native
or APK rebuild verification is unavailable here.

## Verify

Run the SDK-free provenance check:

```sh
scripts/check-baseline.sh
```

Future build verification should install a documented Android NDK and Ant, then
record the exact commands used to regenerate native libraries and package the
APK.
