ARG FROMIMAGE=cp.icr.io/cp/appc/ace-server-prod:12.0.12.0-r1-20240417-022324@sha256:a5b8899829a393f6bfacd8ccb64c7cfdc5546fd5600809330a4ecc47263d73d7

ARG BARNAME=serverPing.bar

FROM ${FROMIMAGE}

USER root

COPY bars/${BARNAME} /home/aceuser/initial-config/bars/

USER 1001