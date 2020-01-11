FROM ubuntu:18.04

# JSON RPC port
EXPOSE 8899/tcp
EXPOSE 8086/tcp
EXPOSE 8001/tcp

# Install libssl
# RUN apt update -y && apt upgrade -y && \
#     apt-get install -y libssl-dev && \
#     rm -rf /var/lib/apt/lists/*

RUN apt update && \
    apt-get install -y libssl-dev && \
    rm -rf /var/lib/apt/lists/*

#Define the ENV variable
ENV CARGO_HOME /root/.cargo

# Volume configuration
VOLUME ["/root"]

WORKDIR "/usr/bin/"
COPY usr/bin /usr/bin/
COPY start.sh /usr/bin/demo/start.sh

ENTRYPOINT [ "./demo/start.sh" ]
CMD [""]
