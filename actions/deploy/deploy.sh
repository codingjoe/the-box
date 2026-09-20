#!/bin/sh
set -e

COMPOSE_FILE="${COMPOSE_FILE:?COMPOSE_FILE is required}"
PROJECT_NAME="${PROJECT_NAME:?PROJECT_NAME is required}"
ROLLOUT_SERVICES="${ROLLOUT_SERVICES:-web}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-120}"
PAUSE_AUTOHEAL="${PAUSE_AUTOHEAL:-true}"
PRUNE_OLDER_THAN="${PRUNE_OLDER_THAN-72h}"

# Container name of the automatic recovery service of The Box stack.
AUTOHEAL_CONTAINER=autoheal

# Tracks whether this run stopped automatic recovery.
AUTOHEAL_PAUSED=false

compose() {
    docker compose --file "$COMPOSE_FILE" --project-name "$PROJECT_NAME" "$@"
}

rollout() {
    docker rollout --file "$COMPOSE_FILE" --project-name "$PROJECT_NAME" --timeout "$ROLLOUT_TIMEOUT" "$@"
}

resume_autoheal() {
    if [ "$AUTOHEAL_PAUSED" != "true" ]; then
        return 0
    fi
    AUTOHEAL_PAUSED=false
    echo "Starting $AUTOHEAL_CONTAINER"
    docker start "$AUTOHEAL_CONTAINER" >/dev/null
}

# Automatic recovery restarts a new replica that fails its healthcheck, and
# hides a deployment that should fail. Stop it for the rollout and start it
# again afterwards, also when the rollout or the whole deployment fails.
pause_autoheal() {
    if [ "$PAUSE_AUTOHEAL" != "true" ]; then
        return 0
    fi
    if ! docker inspect --format '{{.State.Running}}' "$AUTOHEAL_CONTAINER" 2>/dev/null | grep --quiet true; then
        echo "Automatic recovery is not running, leaving it alone"
        return 0
    fi
    echo "Stopping $AUTOHEAL_CONTAINER for the rollout"
    # Resume on any exit, including a cancellation of the workflow run.
    trap 'exit 143' INT TERM
    trap resume_autoheal EXIT
    AUTOHEAL_PAUSED=true
    docker stop "$AUTOHEAL_CONTAINER" >/dev/null
}

# Bring up all services that don't take part in the zero downtime rollout.
# One-shot services, like database migrations, run here before the rollout
# scales up new replicas of the traffic facing services.
# --no-deps leaves rollout services to the rollout step.
echo "::group::Deploying services without zero downtime rollout"
REST_SERVICES=""
for service in $(compose config --services); do
    case " $ROLLOUT_SERVICES " in
        *" $service "*) ;;
        *)
            REST_SERVICES="$REST_SERVICES $service"
            ;;
    esac
done
if [ -n "$REST_SERVICES" ]; then
    # shellcheck disable=SC2086 # REST_SERVICES must be unquoted to pass multiple services
    compose up --detach --no-deps --quiet-pull $REST_SERVICES
fi
echo "::endgroup::"

# Roll out each traffic facing service without downtime.
if [ -n "$ROLLOUT_SERVICES" ]; then
    pause_autoheal
fi
for service in $ROLLOUT_SERVICES; do
    echo "::group::Rolling out $service"
    rollout "$service"
    echo "::endgroup::"
done

# Start automatic recovery again before the housekeeping steps. They remove
# stopped containers that are older than the prune window, which would delete
# the autoheal container that this deployment stopped.
resume_autoheal

# Connect caddy to this project's ingress network so it can reach the app
# without sharing a network with any other app on the box.
echo "::group::Connecting caddy to ingress network"
docker network connect "${PROJECT_NAME}_ingress" caddy 2>/dev/null ||
echo "Caddy is already connected to ${PROJECT_NAME}_ingress"
echo "::endgroup::"

if [ -n "$PRUNE_OLDER_THAN" ]; then
    echo "::group::Pruning unused resources older than $PRUNE_OLDER_THAN"
    # Containers first, so their images become free in the same run.
    docker container prune --force --filter "until=$PRUNE_OLDER_THAN"
    docker image prune --all --force --filter "until=$PRUNE_OLDER_THAN"
    docker builder prune --force --filter "until=$PRUNE_OLDER_THAN"
    echo "::endgroup::"
fi
