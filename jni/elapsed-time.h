#ifndef ELAPSED_TIME_H
#define ELAPSED_TIME_H

#include <limits.h>
#include <stdint.h>

static long checkedElapsedMilliseconds(int64_t currentSeconds,
                                       int64_t currentMicroseconds,
                                       int64_t originSeconds,
                                       int64_t originMicroseconds,
                                       long previousElapsed)
{
    int64_t secondDelta;
    int64_t microsecondDelta;
    int64_t millisecondRemainder;
    int64_t elapsed;

    if (previousElapsed < 0)
        previousElapsed = 0;
    if (currentSeconds < 0 || originSeconds < 0 ||
        currentMicroseconds < 0 || currentMicroseconds >= 1000000 ||
        originMicroseconds < 0 || originMicroseconds >= 1000000)
        return previousElapsed;
    if (currentSeconds < originSeconds ||
        (currentSeconds == originSeconds &&
         currentMicroseconds < originMicroseconds))
        return previousElapsed;

    secondDelta = currentSeconds - originSeconds;
    microsecondDelta = currentMicroseconds - originMicroseconds;
    if (microsecondDelta < 0)
    {
        --secondDelta;
        microsecondDelta += 1000000;
    }

    if (secondDelta > LONG_MAX / 1000)
        return LONG_MAX;
    millisecondRemainder = microsecondDelta / 1000;
    if (secondDelta == LONG_MAX / 1000 &&
        millisecondRemainder > LONG_MAX % 1000)
        return LONG_MAX;
    elapsed = secondDelta * 1000 + millisecondRemainder;
    if (elapsed < previousElapsed)
        return previousElapsed;

    return (long)elapsed;
}

static long checkedPausedMilliseconds(long accumulatedPaused,
                                      long currentElapsed,
                                      long stoppedElapsed)
{
    long pauseDelta;

    if (accumulatedPaused < 0)
        accumulatedPaused = 0;
    if (currentElapsed < 0 || stoppedElapsed < 0 ||
        currentElapsed <= stoppedElapsed)
        return accumulatedPaused;

    pauseDelta = currentElapsed - stoppedElapsed;
    if (accumulatedPaused > LONG_MAX - pauseDelta)
        return LONG_MAX;
    return accumulatedPaused + pauseDelta;
}

static long checkedRenderMilliseconds(long elapsed, long paused)
{
    if (elapsed < 0)
        elapsed = 0;
    if (paused < 0)
        paused = 0;
    if (elapsed <= paused)
        return 0;
    return elapsed - paused;
}

#endif
