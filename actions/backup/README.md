# The Box - PostgreSQL Backup Action

## Usage

```workflow
name: Backup Database
on:
  schedule:
    - cron: '0 0 * * *' # Runs daily at midnight
  workflow_dispatch: # Allows manual triggering
jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
      - name: Run backup action
        uses: the-box/backup@v1
        with:

```
