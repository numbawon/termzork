# termzork: Zork I/II/III in the browser, one container. A landing page
# (busybox httpd) picks the game; ttyd wraps frotz for the actual play,
# dispatching by URL argument (ttyd's -a/--url-arg) rather than a
# separate container or a real login-user switch per game, so nothing
# here needs root or setuid -- one non-root user, start to finish.
#
# Story files: Microsoft and Activision's November 2025 MIT-licensed
# release of the original ZIL source (github.com/historicalsource/
# zork{1,2,3}). COMPILED/zorkN.z3 in each repo is the pre-built
# Z-machine story file, so no ZIL compiler is needed here, just a
# pinned, checksummed download.
FROM alpine:3.22

RUN apk add --no-cache frotz busybox-extras ca-certificates wget

# Pinned to a specific release, not `latest`; sha256 verified so a
# compromised or replaced release asset fails the build instead of
# silently running.
ARG TTYD_VERSION=1.7.7
ARG TTYD_SHA256=8a217c968aba172e0dbf3f34447218dc015bc4d5e59bf51db2f2cd12b7be4f55
RUN wget -qO /usr/local/bin/ttyd \
      "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64" \
    && echo "${TTYD_SHA256}  /usr/local/bin/ttyd" | sha256sum -c - \
    && chmod +x /usr/local/bin/ttyd

# Each ARG is a commit, not a branch -- these repos have no tags/releases,
# so a commit is the only reproducible reference. sha256 of the story file
# itself is checked too: these are Infocom's original 1980s binaries,
# unchanged since; a hash mismatch means the wrong file arrived, not that
# a new release shipped.
ARG ZORK1_COMMIT=97b7b3d68c075dd9af7da499c3e9690ada3471fd
ARG ZORK2_COMMIT=3da9661098809788a99cef00f00c865c6c204f96
ARG ZORK3_COMMIT=3ec9ed412b5f3cafe65d83c727d07db1fe4a86a8
ARG ZORK1_SHA256=37084966477dff679282de42974b2077156b1bd68fad92a65d4ea94d8eb64d79
ARG ZORK2_SHA256=3ae7d5558943e9721f3e4b273c8a7faec1a03a604e1ae4ee1cde472c21cb24ac
ARG ZORK3_SHA256=b637a242865d059890184164ce8dec28554cc80901dcbf26c740b2d1ed0d4eb8

RUN mkdir -p /games \
    && wget -qO /games/zork1.z3 "https://raw.githubusercontent.com/historicalsource/zork1/${ZORK1_COMMIT}/COMPILED/zork1.z3" \
    && wget -qO /games/zork2.z3 "https://raw.githubusercontent.com/historicalsource/zork2/${ZORK2_COMMIT}/COMPILED/zork2.z3" \
    && wget -qO /games/zork3.z3 "https://raw.githubusercontent.com/historicalsource/zork3/${ZORK3_COMMIT}/COMPILED/zork3.z3" \
    && echo "${ZORK1_SHA256}  /games/zork1.z3" | sha256sum -c - \
    && echo "${ZORK2_SHA256}  /games/zork2.z3" | sha256sum -c - \
    && echo "${ZORK3_SHA256}  /games/zork3.z3" | sha256sum -c -

COPY landing /landing
COPY select.sh /select.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /select.sh /entrypoint.sh

# Green phosphor CRT palette matching the landing page's CSS. No
# fontFamily override alongside it: a client without a pinned custom font
# installed degrades xterm.js's cell-metrics measurement to a 0-size grid
# -- a blank screen that still silently accepts keystrokes. Color is
# safe to override this way; font is not, unless it's one every client
# is guaranteed to have. Override via -e ZORK_THEME=... if you want a
# different palette; must be a valid xterm.js ITheme JSON object.
ENV ZORK_THEME='{"background":"#0b0f0c","foreground":"#4ee88a","cursor":"#b8ffcf","cursorAccent":"#0b0f0c","selectionBackground":"#1e5c3a","selectionForeground":"#b8ffcf","black":"#0b0f0c","red":"#2b7a4e","green":"#4ee88a","yellow":"#6fffb0","blue":"#2b7a4e","magenta":"#4ee88a","cyan":"#4ee88a","white":"#b8ffcf","brightBlack":"#2b7a4e","brightRed":"#6fffb0","brightGreen":"#b8ffcf","brightYellow":"#e8fff0","brightBlue":"#6fffb0","brightMagenta":"#b8ffcf","brightCyan":"#b8ffcf","brightWhite":"#e8fff0"}'

# frotz refuses outright to run as root ("I won't run as root!"). Neither
# httpd nor ttyd needs root either -- both bind non-privileged ports --
# so the whole container runs as one fixed non-root user, no privilege
# split required.
RUN adduser -D -u 1000 player
USER player

EXPOSE 8080 7681
ENTRYPOINT ["/entrypoint.sh"]
