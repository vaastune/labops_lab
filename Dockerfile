FROM postgres:16
ENTRYPOINT []
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-psycopg2 cron nano && rm -rf /var/lib/apt/lists/*
WORKDIR /work
CMD ["bash"]
