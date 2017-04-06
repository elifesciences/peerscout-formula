reviewer-suggestions-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/reviewer-suggestions.conf
        - source: salt://reviewer-suggestions/config/etc-nginx-sites-enabled-reviewer-suggestions.conf
        - template: jinja
        - require:
            - nginx-config
        - listen_in:
            - service: nginx-server-service

{% for title, user in pillar.reviewer_suggestions.web_users.items() %}
reviewer-suggestions-nginx-authentication-{{ title }}:
    webutil.user_exists:
        - name: {{ user.username }}
        - password: {{ user.password }}
        - htpasswd_file: /etc/nginx/reviewer-suggestions.htpasswd
        - require:
            - reviewer-suggestions-nginx-vhost
        - listen_in:
            - service: nginx-server-service
{% endfor %}

reviewer-suggestions-build-essential:
    pkg.installed:
        - pkgs:
            - build-essential

reviewer-suggestions-server-service-stopped:
    service.dead:
        - onlyif: ls /etc/init/reviewer-suggestions-server.conf
        - name: reviewer-suggestions-server

reviewer-suggestions-server-service:
    file.managed:
        - name: /etc/init/reviewer-suggestions-server.conf
        - source: salt://reviewer-suggestions/config/etc-init-reviewer-suggestions-server.conf
        - template: jinja
        - require:
            - reviewer-suggestions-migrate-schema
            - reviewer-suggestions-client-bundle
            - reviewer-suggestions-cron

    service.running:
        - name: reviewer-suggestions-server
        - require:
            - file: reviewer-suggestions-server-service

reviewer-suggestions-client-file-permissions:
  file.directory:
    - name: {{ pillar.reviewer_suggestions.installation_path }}/client
    - mode: 777

reviewer-suggestions-client-install:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: {{ pillar.reviewer_suggestions.installation_path }}/client
        - name: |
            npm install
        - require:
            - reviewer-suggestions-client-file-permissions

reviewer-suggestions-client-bundle:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: {{ pillar.reviewer_suggestions.installation_path }}/client
        - name: |
            npm run bundle
        - require:
            - reviewer-suggestions-client-install

reviewer-suggestions-configure:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: {{ pillar.reviewer_suggestions.installation_path }}
        - name: |
            ./install.sh
        - require:
            - reviewer-suggestions-build-essential
            - python-dev
            - reviewer-suggestions-repository
            - reviewer-suggestions-app-cfg

reviewer-suggestions-app-cfg:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: /srv/reviewer-suggestions/app.cfg
        - source: 
            - salt://reviewer-suggestions/config/srv-reviewer-suggestions-app.cfg
        - template: jinja
        - replace: True
        - require:
            - reviewer-suggestions-repository

reviewer-suggestions-migrate-schema:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: {{ pillar.reviewer_suggestions.installation_path }}/preprocessing
        - name: |
            {{ pillar.reviewer_suggestions.installation_path }}/venv/bin/python ./migrateSchema.py
        - require:
            - postgres-db-exists
            - reviewer-suggestions-configure
            - reviewer-suggestions-server-service-stopped

reviewer-suggestions-repository:
    builder.git_latest:
        - name: git@github.com:elifesciences/reviewer-suggestions.git
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
            - builder: reviewer-suggestions-repository

reviewer-suggestions-aws-credentials:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/.aws/credentials
        - source: salt://reviewer-suggestions/config/home-user-.aws-credentials
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - makedirs: True
        - template: jinja
        - require:
            - deploy-user

reviewer-suggestions-cron:
    cron.present:
        - name: {{ pillar.reviewer_suggestions.installation_path }}/update-data-and-reload.sh
        - identifier: update-data
        - minute: 0
        - user: {{ pillar.elife.deploy_user.username }}

reviewer-suggestions-server-service-started:
    service.running:
        - order: last
        - name: reviewer-suggestions-server
        - require:
            - file: reviewer-suggestions-server-service
