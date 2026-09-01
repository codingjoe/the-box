#!/bin/sh
set -e

COMPOSE_FILE="${COMPOSE_FILE:?COMPOSE_FILE is required}"
PROJECT_NAME="${PROJECT_NAME:?PROJECT_NAME is required}"
ROLLOUT_SERVICES="${ROLLOUT_SERVICES:-web}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-120}"

compose() {
    docker compose --file "$COMPOSE_FILE" --project-name "$PROJECT_NAME" "$@"
}

rollout() {
    docker rollout --file "$COMPOSE_FILE" --project-name "$PROJECT_NAME" --timeout "$ROLLOUT_TIMEOUT" "$@"
}

# Bring up all services that don't take part in the zero downtime rollout.
# One-shot services, like database migrations, run here before the rollout
# scales up new replicas of the traffic facing services.
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
    compose up --detach --pull always --quiet-pull $REST_SERVICES
fi
echo "::endgroup::"

# Roll out each traffic facing service without downtime.
for service in $ROLLOUT_SERVICES; do
    echo "::group::Rolling out $service"
    rollout "$service"
    echo "::endgroup::"
done
