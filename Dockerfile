FROM nvidia/cuda:11.3.1-runtime-ubuntu20.04

# install ubuntu dependencies
ENV DEBIAN_FRONTEND=noninteractive 
RUN apt-get update && \
    apt-get -y install python3-pip xvfb ffmpeg git build-essential python-opengl
RUN ln -s /usr/bin/python3 /usr/bin/python

# install microrts dependencies
RUN apt-get -y -q install wget unzip default-jdk

# install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# install python dependencies
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen

# copy local files
COPY ./gym_microrts /gym_microrts
COPY ./experiments /experiments
RUN uv sync --frozen
# COPY build.sh build.sh
# RUN bash build.sh

COPY entrypoint.sh /usr/local/bin/
RUN chmod 777 /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

