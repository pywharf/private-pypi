FROM python:3.8-slim-buster

ARG PIP_INDEX_URL

ADD dist /dist

RUN echo "PIP_INDEX_URL=$PIP_INDEX_URL"
RUN echo "PIP_TRUSTED_HOST=$PIP_TRUSTED_HOST"

RUN pip --no-cache-dir install -U pip \
    && pip --no-cache-dir install $(realpath /dist/private_pypi*.whl | head -n 1)

ENTRYPOINT ["private_pypi"]
