FROM scratch
ADD localhost.crt /
ADD localhost.key /
ADD main.out /
COPY data/ /data/
CMD ["/main.out", "-certs", "/", "-dataDir", "/data"]

