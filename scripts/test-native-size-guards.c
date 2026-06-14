#include <limits.h>
#include <stddef.h>
#include <stdio.h>

#include "../jni/checked-size.h"
#include "../jni/elapsed-time.h"

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
    long product = 0;
    size_t bytes = 0;

    expect(checkedPositiveLongProduct(6, 7, &product) && product == 42,
           "valid positive product");
    expect(!checkedPositiveLongProduct(0, 7, &product),
           "zero multiplicand rejected");
    expect(!checkedPositiveLongProduct(-1, 7, &product),
           "negative multiplicand rejected");
    expect(!checkedPositiveLongProduct(LONG_MAX, 2, &product),
           "signed long overflow rejected");
    expect(checkedPositiveLongProduct(LONG_MAX / 2, 2, &product),
           "largest representable even product accepted");
    expect(checkedPositiveLongProduct(LONG_MAX, 1, &product) &&
           product == LONG_MAX,
           "maximum signed long product accepted");
    expect(!checkedPositiveLongProduct(1, 1, NULL),
           "missing product output rejected");

    expect(checkedArrayByteSize(4, 3, 2, &bytes) && bytes == 24,
           "valid allocation byte count");
    expect(!checkedArrayByteSize(0, 3, 2, &bytes),
           "zero element count rejected");
    expect(!checkedArrayByteSize(4, 0, 2, &bytes),
           "zero component count rejected");
    expect(!checkedArrayByteSize(4, 3, 0, &bytes),
           "zero component size rejected");
    expect(!checkedArrayByteSize(LONG_MAX, 2, sizeof(long), &bytes),
           "allocation byte overflow rejected");
    expect(checkedArrayByteSize(1, 1, (size_t)-1, &bytes) &&
           bytes == (size_t)-1,
           "maximum allocation byte count accepted");
    expect(!checkedArrayByteSize(1, 1, 1, NULL),
           "missing byte output rejected");

    expect(checkedElapsedMilliseconds(10, 750000, 10, 250000, 0) == 500,
           "same-second elapsed milliseconds");
    expect(checkedElapsedMilliseconds(11, 250000, 10, 750000, 0) == 500,
           "microsecond borrow elapsed milliseconds");
    expect(checkedElapsedMilliseconds(9, 999999, 10, 0, 321) == 321,
           "backward clock preserves previous elapsed time");
    expect(checkedElapsedMilliseconds(10, 249999, 10, 250000, 321) == 321,
           "subsecond backward clock preserves previous elapsed time");
    expect(checkedElapsedMilliseconds(10, 1000000, 10, 0, 321) == 321,
           "invalid current microseconds preserve previous elapsed time");
    expect(checkedElapsedMilliseconds(10, 0, 10, -1, 321) == 321,
           "invalid origin microseconds preserve previous elapsed time");
    expect(checkedElapsedMilliseconds(10, 500000, 10, 0, 700) == 700,
           "elapsed time remains nondecreasing");
    expect(checkedElapsedMilliseconds(10, 500000, 10, 0, -1) == 500,
           "negative previous elapsed time is normalized");
    expect(checkedElapsedMilliseconds((int64_t)(LONG_MAX / 1000) + 1,
                                      0, 0, 0, 0) == LONG_MAX,
           "elapsed seconds saturate at long maximum");
    expect(checkedElapsedMilliseconds((int64_t)(LONG_MAX / 1000),
                                      999999, 0, 0, 0) == LONG_MAX,
           "elapsed milliseconds saturate at long maximum");

    if (failures != 0)
        return 1;

    puts("Native size guard tests passed.");
    return 0;
}
