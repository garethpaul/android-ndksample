#ifndef CHECKED_SIZE_H
#define CHECKED_SIZE_H

#include <limits.h>
#include <stddef.h>

static int checkedPositiveLongProduct(long left, long right, long *result)
{
    if (result == NULL || left <= 0 || right <= 0 || left > LONG_MAX / right)
        return 0;

    *result = left * right;
    return 1;
}

static int checkedArrayByteSize(long count, int components,
                                size_t componentSize, size_t *result)
{
    size_t elementCount;

    if (result == NULL || count <= 0 || components <= 0 || componentSize == 0)
        return 0;
    if ((unsigned long)count > (unsigned long)((size_t)-1))
        return 0;

    elementCount = (size_t)count;
    if (elementCount > (size_t)-1 / (size_t)components)
        return 0;
    elementCount *= (size_t)components;
    if (elementCount > (size_t)-1 / componentSize)
        return 0;

    *result = elementCount * componentSize;
    return 1;
}

#endif
