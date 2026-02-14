FROM ghcr.io/astral-sh/uv:0.9.5-trixie-slim AS build
LABEL title="SMTP Server"
LABEL license="BSD-2-Clause"
LABEL url="https://github.com/codingjoe/the-box"

# Install dependencies
COPY ./Aptfile /tmp
RUN cd /tmp && apt-get update && cat Aptfile | xargs apt-get download \
    && mkdir -p /dpkg && \
    for deb in *.deb; do dpkg --extract $deb /dpkg || exit 10; done

# UV
ARG UV_NO_DEV
ENV UV_NO_DEV=${UV_NO_DEV:-1}
ENV UV_PYTHON_PREFERENCE=only-managed
ENV UV_PYTHON_INSTALL_DIR=/opt/python
ENV UV_LINK_MODE=copy
ENV UV_COMPILE_BYTECODE=1

# Install Python and dependencies
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv --mount=type=bind,source=./uv.lock,target=uv.lock --mount=type=bind,source=./pyproject.toml,target=pyproject.toml uv sync --frozen --no-install-project --no-editable
COPY .. /app
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-editable


FROM gcr.io/distroless/cc:nonroot AS development

# Copy binary dependencies
COPY --from=build /dpkg /

# Copy Python dependencies
COPY --from=build --chown=root:root /opt/python /opt/python
COPY --from=build --chown=root:root /app/.venv /opt/venv

# Create the virtual environment
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app

ENTRYPOINT ["python"]

FROM development AS production

COPY .. /app
