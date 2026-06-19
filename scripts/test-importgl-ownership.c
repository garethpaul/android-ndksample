#include <stdio.h>
#include <string.h>

static int failures = 0;
static int openCount = 0;
static int closeCount = 0;
static int symbolCount = 0;
static int failClose = 0;
static int failSymbolAt = 0;
static int libraryHandle;

#define ANDROID_NDK
#define dlopen testDlopen
#define dlsym testDlsym
#define dlclose testDlclose
#include "../jni/importgl.c"
#undef dlopen
#undef dlsym
#undef dlclose

void *testDlopen(const char *path, int mode)
{
    (void)mode;
    if (strcmp(path, "libGLESv1_CM.so") != 0)
        return NULL;
    ++openCount;
    return &libraryHandle;
}

void *testDlsym(void *handle, const char *name)
{
    (void)handle;
    (void)name;
    ++symbolCount;
    if (failSymbolAt != 0 && symbolCount == failSymbolAt)
        return NULL;
    return &libraryHandle;
}

int testDlclose(void *handle)
{
    (void)handle;
    ++closeCount;
    return failClose ? -1 : 0;
}

static void expect(int condition, const char *message)
{
    if (!condition)
    {
        fprintf(stderr, "FAIL: %s\n", message);
        ++failures;
    }
}

int main(void)
{
    expect(importGLInit() == 1, "first ImportGL initialization succeeds");
    expect(importGLInit() == 1, "repeated ImportGL initialization is idempotent");
    expect(openCount == 1, "repeated ImportGL initialization owns one library reference");
    importGLDeinit();
    expect(closeCount == 1, "ImportGL teardown closes its one library reference");

    failClose = 1;
    failSymbolAt = 1;
    symbolCount = 0;
    expect(importGLInit() == 0, "partial ImportGL initialization reports failure");
    expect(openCount == 2, "partial ImportGL initialization opens one new reference");
    expect(importGLInit() == 0,
           "ImportGL refuses to overwrite a retained partial library handle");
    expect(openCount == 2,
           "failed ImportGL cleanup does not leak another library reference");

    if (failures != 0)
        return 1;

    puts("ImportGL ownership tests passed.");
    return 0;
}
