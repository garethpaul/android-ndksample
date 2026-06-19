#ifndef DEMO_TIMELINE_H
#define DEMO_TIMELINE_H

#include "elapsed-time.h"

typedef struct
{
    long startTick;
    long tick;
    int currentCamTrack;
    long currentCamTrackStartTick;
    long nextCamTrackStartTick;
    int started;
} DemoTimeline;

#define DEMO_TIMELINE_INITIALIZER { 0, 0, 0, 0, 0x7fffffffL, 0 }

static void demoTimelineReset(DemoTimeline *timeline)
{
    DemoTimeline reset = DEMO_TIMELINE_INITIALIZER;

    if (timeline != 0)
        *timeline = reset;
}

static long demoTimelineAdvance(DemoTimeline *timeline, long tick)
{
    if (timeline == 0)
        return 0;
    if (tick < 0)
        return timeline->tick;
    if (!timeline->started)
    {
        timeline->startTick = tick;
        timeline->started = 1;
    }
    timeline->tick = checkedSmoothedTick(timeline->tick,
                                         tick,
                                         timeline->startTick);
    return timeline->tick;
}

#endif
