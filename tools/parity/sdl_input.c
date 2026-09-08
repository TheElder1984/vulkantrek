/* Linux-only SDL 1.2 event adapter for DOSBox 0.74 reference captures.
 * Script rows: milliseconds, SDL key symbol, pressed (0/1), modifiers.
 * The original game's memory and random generator are never modified.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct {
    uint8_t scancode;
    int sym;
    int mod;
    uint16_t unicode;
} Key;

typedef union {
    uint8_t type;
    struct { uint8_t type, which, state; Key keysym; } key;
    uint8_t pad[24];
} Event;

int SDL_PollEvent(Event *event) {
    static int (*original)(Event *);
    static FILE *file;
    static int ready, ms, sym, down, mod;
    static struct timespec start;
    if (!original) {
        original = dlsym(RTLD_NEXT, "SDL_PollEvent");
        const char *path = getenv("TREK_INPUT");
        if (!original || !path || !(file = fopen(path, "r"))) {
            fprintf(stderr, "Reference input adapter initialization failed\n");
            exit(1);
        }
        clock_gettime(CLOCK_MONOTONIC, &start);
    }
    if (!ready && file) {
        ready = fscanf(file, "%d %d %d %d", &ms, &sym, &down, &mod) == 4;
        if (!ready) {
            fclose(file);
            file = NULL;
        }
    }
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    long elapsed = (now.tv_sec - start.tv_sec) * 1000
                 + (now.tv_nsec - start.tv_nsec) / 1000000;
    if (ready && elapsed >= ms && event) {
        memset(event, 0, sizeof(*event));
        event->type = down ? 2 : 3;
        event->key.state = down;
        event->key.keysym.sym = sym;
        event->key.keysym.mod = mod;
        event->key.keysym.unicode = sym < 128 ? sym : 0;
        fprintf(stderr, "INPUT %ld %d %d\n", elapsed, sym, down);
        ready = 0;
        return 1;
    }
    return original(event);
}
