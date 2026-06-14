/* San Angeles Observation OpenGL ES version example
 * Copyright 2009 The Android Open Source Project
 * All rights reserved.
 *
 * This source is free software; you can redistribute it and/or
 * modify it under the terms of EITHER:
 *   (1) The GNU Lesser General Public License as published by the Free
 *       Software Foundation; either version 2.1 of the License, or (at
 *       your option) any later version. The text of the GNU Lesser
 *       General Public License is included with this source in the
 *       file LICENSE-LGPL.txt.
 *   (2) The BSD-style license that is included with this source in
 *       the file LICENSE-BSD.txt.
 *
 * This source is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the files
 * LICENSE-LGPL.txt and LICENSE-BSD.txt for more details.
 */
#include <jni.h>
#include <sys/time.h>
#include <time.h>
#include <android/log.h>
#include <stdint.h>
#include "importgl.h"
#include "app.h"
#include "elapsed-time.h"

int   gAppAlive   = 1;

static int  sWindowWidth  = 320;
static int  sWindowHeight = 480;
static int  sNativeInitialized = 0;
static int  sDemoStopped  = 0;
static long sTimeOffset   = 0;
static int  sTimeOffsetInit = 0;
static long sTimeStopped  = 0;
static struct timeval sTimeOrigin;
static int  sTimeOriginInit = 0;
static long sLastElapsedTime = 0;

static void
_resetTime(void)
{
    sTimeOrigin.tv_sec = 0;
    sTimeOrigin.tv_usec = 0;
    sTimeOriginInit = 0;
    sLastElapsedTime = 0;
}

static long
_getTime(void)
{
    struct timeval  now;

    if (gettimeofday(&now, NULL) != 0)
        return sLastElapsedTime;
    if (!sTimeOriginInit) {
        sTimeOrigin = now;
        sTimeOriginInit = 1;
        sLastElapsedTime = 0;
        return 0;
    }

    sLastElapsedTime = checkedElapsedMilliseconds(
            (int64_t)now.tv_sec,
            (int64_t)now.tv_usec,
            (int64_t)sTimeOrigin.tv_sec,
            (int64_t)sTimeOrigin.tv_usec,
            sLastElapsedTime);
    return sLastElapsedTime;
}

/* Call to initialize the graphics state */
void
Java_com_example_SanAngeles_DemoRenderer_nativeInit( JNIEnv*  env, jclass  clazz )
{
    if (sNativeInitialized) {
        appDeinit();
        importGLDeinit();
        sNativeInitialized = 0;
    }

    _resetTime();

    if (!importGLInit()) {
        __android_log_print(
                ANDROID_LOG_ERROR,
                "SanAngeles",
                "OpenGL ES imports are unavailable");
        importGLDeinit();
        gAppAlive = 0;
        return;
    }

    sDemoStopped = 0;
    sTimeOffset = 0;
    sTimeOffsetInit = 0;
    sTimeStopped = 0;
    gAppAlive = 1;
    appInit();
    if (!gAppAlive) {
        __android_log_print(
                ANDROID_LOG_ERROR,
                "SanAngeles",
                "Demo resource initialization failed");
        appDeinit();
        importGLDeinit();
        return;
    }
    sNativeInitialized = 1;
}

void
Java_com_example_SanAngeles_DemoRenderer_nativeResize( JNIEnv*  env, jclass  clazz, jint w, jint h )
{
    if (w <= 0 || h <= 0) {
        __android_log_print(
                ANDROID_LOG_WARN,
                "SanAngeles",
                "Ignoring invalid surface dimensions");
        return;
    }

    sWindowWidth  = w;
    sWindowHeight = h;
    __android_log_print(ANDROID_LOG_INFO, "SanAngeles", "resize w=%d h=%d", w, h);
}

/* Call to finalize the graphics state */
void
Java_com_example_SanAngeles_DemoRenderer_nativeDone( JNIEnv*  env, jclass  clazz )
{
    if (!sNativeInitialized) {
        return;
    }

    gAppAlive = 0;
    appDeinit();
    importGLDeinit();
    sNativeInitialized = 0;
}

/* This is called to indicate to the render loop that it should
 * stop as soon as possible.
 */

void _pause()
{
    if (sDemoStopped) {
        return;
    }

  /* we paused the animation, so store the current
   * time in sTimeStopped for future nativeRender calls */
    sDemoStopped = 1;
    sTimeStopped = _getTime();
}

void _resume()
{
    if (!sDemoStopped) {
        return;
    }

  /* we resumed the animation, so adjust the time offset
   * to take care of the pause interval. */
    sDemoStopped = 0;
    sTimeOffset -= _getTime() - sTimeStopped;
}


void
Java_com_example_SanAngeles_DemoGLSurfaceView_nativeTogglePauseResume( JNIEnv*  env, jclass  clazz )
{
    if (sDemoStopped)
        _resume();
    else
        _pause();
}

void
Java_com_example_SanAngeles_DemoGLSurfaceView_nativePause( JNIEnv*  env, jclass  clazz )
{
    _pause();
}

void
Java_com_example_SanAngeles_DemoGLSurfaceView_nativeResume( JNIEnv*  env, jclass  clazz )
{
    _resume();
}

/* Call to render the next GL frame */
void
Java_com_example_SanAngeles_DemoRenderer_nativeRender( JNIEnv*  env, jclass  clazz )
{
    long   curTime;

    if (!sNativeInitialized || sWindowWidth <= 0 || sWindowHeight <= 0) {
        return;
    }

    /* NOTE: if sDemoStopped is TRUE, then we re-render the same frame
     *       on each iteration.
     */
    if (sDemoStopped) {
        curTime = sTimeStopped + sTimeOffset;
    } else {
        curTime = _getTime() + sTimeOffset;
        if (sTimeOffsetInit == 0) {
            sTimeOffsetInit = 1;
            sTimeOffset     = -curTime;
            curTime         = 0;
        }
    }

    //__android_log_print(ANDROID_LOG_INFO, "SanAngeles", "curTime=%ld", curTime);

    appRender(curTime, sWindowWidth, sWindowHeight);
}
