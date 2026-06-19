#include <stdio.h>

#include "../jni/demo-timeline.h"

static int failures = 0;

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
    DemoTimeline timeline = DEMO_TIMELINE_INITIALIZER;

    expect(demoTimelineAdvance(&timeline, 0) == 0,
           "timeline accepts a zero-valued first tick");
    expect(demoTimelineAdvance(&timeline, 100) == 50,
           "zero-valued first tick remains the timeline origin");

    demoTimelineReset(&timeline);
    expect(demoTimelineAdvance(&timeline, -1) == 0 && timeline.started == 0,
           "negative first tick cannot claim the timeline origin");
    expect(demoTimelineAdvance(&timeline, 100) == 0 && timeline.started == 1,
           "first valid tick claims the timeline origin");
    expect(demoTimelineAdvance(&timeline, 200) == 50,
           "timeline advances after rejecting a negative first tick");

    timeline.startTick = 10;
    timeline.tick = 900;
    timeline.currentCamTrack = 7;
    timeline.currentCamTrackStartTick = 400;
    timeline.nextCamTrackStartTick = 800;
    timeline.started = 1;
    demoTimelineReset(&timeline);
    expect(timeline.startTick == 0 && timeline.tick == 0 &&
           timeline.currentCamTrack == 0 &&
           timeline.currentCamTrackStartTick == 0 &&
           timeline.nextCamTrackStartTick == 0x7fffffffL &&
           timeline.started == 0,
           "native reinitialization clears all demo timeline state");

    if (failures != 0)
        return 1;

    puts("Demo timeline tests passed.");
    return 0;
}
