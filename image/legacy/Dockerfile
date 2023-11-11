ARG REGISTRY_BASE_IMAGE
FROM ${REGISTRY_BASE_IMAGE}

RUN \
    # Link ncurses libs version 6 to 5
    ln -sf /lib/x86_64-linux-gnu/libncurses.so.6 /lib/x86_64-linux-gnu/libncurses.so.5 && \
    ln -sf /lib/x86_64-linux-gnu/libncursesw.so.6 /lib/x86_64-linux-gnu/libncursesw.so.5 && \
    ## i386
    ln -sf /lib/i386-linux-gnu/libncurses.so.6 /lib/i386-linux-gnu/libncurses.so.5 && \
    ln -sf /lib/i386-linux-gnu/libncursesw.so.6 /lib/i386-linux-gnu/libncursesw.so.5 && \
    # Link tinfo libs version 6 to 5
    ## x86_64
    ln -sf /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5 && \
    ## i386
    ln -sf /lib/i386-linux-gnu/libtinfo.so.6 /lib/i386-linux-gnu/libtinfo.so.5 && \
    # Link ffi libs version 7 to 6
    ## x86_64
    ln -sf /usr/lib/x86_64-linux-gnu/libffi.so.7 /usr/lib/x86_64-linux-gnu/libffi.so.6 && \
    ## i386
    ln -sf /usr/lib/i386-linux-gnu/libffi.so.7 /usr/lib/i386-linux-gnu/libffi.so.6
