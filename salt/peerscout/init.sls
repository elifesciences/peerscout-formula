peerscout-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/peerscout.conf
        - source: salt://peerscout/config/etc-nginx-sites-enabled-peerscout.conf
        - template: jinja
        - require:
            - nginx-config
        - listen_in:
            - service: nginx-server-service

peerscout-build-essential:
    pkg.installed:
        - pkgs:
            - build-essential

peerscout-server-service-stopped:
    service.dead:
        - onlyif: ls /etc/init/peerscout-server.conf
        - name: peerscout-server

peerscout-server-service:
    file.managed:
        - name: /etc/init/peerscout-server.conf
        - source: salt://peerscout/config/etc-init-peerscout-server.conf
        - template: jinja
        - require:
            - peerscout-migrate-schema
            - peerscout-client-bundle
            - peerscout-cron

    service.running:
        - name: peerscout-server
        - require:
            - file: peerscout-server-service

peerscout-client-file-permissions:
  file.directory:
    - name: {{ pillar.reviewer_suggestions.installation_path }}/client
    - mode: 777

peerscout-client-install:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: {{ pillar.reviewer_suggestions.installation_path }}/client
        - name: |
            npm install
        - require:
            - peerscout-client-file-permissions

peerscout-client-bundle:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: {{ pillar.reviewer_suggestions.installation_path }}/client
        - name: |
            npm run bundle
        - require:
            - peerscout-client-install

peerscout-configure:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: {{ pillar.reviewer_suggestions.installation_path }}
        - name: |
            ./install.sh
        - require:
            - peerscout-build-essential
            - python-dev
            - peerscout-repository
            - peerscout-app-cfg
            - peerscout-newrelic-cfg
            - peerscout-gtag-head-cfg
            - peerscout-gtag-body-cfg

peerscout-app-cfg:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: {{ pillar.reviewer_suggestions.installation_path }}/app.cfg
        - source: 
            - salt://peerscout/config/srv-peerscout-app.cfg
        - template: jinja
        - replace: True
        - require:
            - peerscout-repository

peerscout-newrelic-cfg:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: {{ pillar.reviewer_suggestions.installation_path }}/client/.inject-html/newrelic.html
        - source: 
            - salt://peerscout/config/srv-peerscout-client-inject-html-newrelic-{{ pillar.elife.env }}.html
            - salt://peerscout/config/srv-peerscout-client-inject-html-newrelic-default.html
        - replace: True
        - makedirs: True
        - require:
            - peerscout-repository

peerscout-gtag-head-cfg:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: {{ pillar.reviewer_suggestions.installation_path }}/client/.inject-html/gtag.head.html
        - source: 
            - salt://peerscout/config/srv-peerscout-client-inject-html-gtag.head-{{ pillar.elife.env }}.html
            - salt://peerscout/config/srv-peerscout-client-inject-html-gtag.head-default.html
        - replace: True
        - makedirs: True
        - require:
            - peerscout-repository

peerscout-gtag-body-cfg:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: {{ pillar.reviewer_suggestions.installation_path }}/client/.inject-html/gtag.body.html
        - source: 
            - salt://peerscout/config/srv-peerscout-client-inject-html-gtag.body-{{ pillar.elife.env }}.html
            - salt://peerscout/config/srv-peerscout-client-inject-html-gtag.body-default.html
        - replace: True
        - makedirs: True
        - require:
            - peerscout-repository

peerscout-migrate-schema:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: {{ pillar.reviewer_suggestions.installation_path }}/preprocessing
        - name: |
            {{ pillar.reviewer_suggestions.installation_path }}/venv/bin/python ./migrateSchema.py
        - require:
            - postgres-db-exists
            - peerscout-configure
            - peerscout-server-service-stopped

peerscout-repository:
    builder.git_latest:
        - name: git@github.com:elifesciences/peerscout.git
        - identity: {{ pillar.elife.projects_builder.key or '' }}
        - rev: {{ salt['elife.rev']() }}
        - branch: {{ salt['elife.branch']() }}
        - target: {{ pillar.reviewer_suggestions.installation_path }}
        - force_fetch: True
        - force_checkout: True
        - force_reset: True

    file.directory:
        - name: {{ pillar.reviewer_suggestions.installation_path }}
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - recurse:
            - user
            - group
        - require:
            - builder: peerscout-repository

peerscout-aws-credentials:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/.aws/credentials
        - source: salt://peerscout/config/home-user-.aws-credentials
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - makedirs: True
        - template: jinja
        - require:
            - deploy-user

peerscout-cron:
    cron.present:
        - name: {{ pillar.reviewer_suggestions.installation_path }}/update-data-and-reload.sh
        - identifier: update-data
        - minute: 0
        - user: {{ pillar.elife.deploy_user.username }}

peerscout-server-service-enabled:
    service.running:
        - name: peerscout-server
        - require:
            - file: peerscout-server-service

peerscout-server-service-started:
    cmd.run:
        - order: last
        - user: {{ pillar.elife.deploy_user.username }}
        - name: |
            timeout 120 sh -c 'while ! nc -q0 -w1 -z localhost 8080 </dev/null >/dev/null 2>&1; do sleep 1; done'
        - require:
            - peerscout-server-service-enabled
