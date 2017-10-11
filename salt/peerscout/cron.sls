peerscout-cron:
    cron.present:
        - name: {{ pillar.peerscout.installation_path }}/update-data-and-reload.sh
        - identifier: update-data
        - minute: 0
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - peerscout-migrate-schema

