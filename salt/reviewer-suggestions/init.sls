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

reviewer-suggestions-server-service:
    file.managed:
        - name: /etc/init/reviewer-suggestions-server.conf
        - source: salt://reviewer-suggestions/config/etc-init-reviewer-suggestions-server.conf
        - template: jinja
        - require:
            - reviewer-suggestions-repository

    service.running:
        - name: reviewer-suggestions-server
        - require:
            - file: reviewer-suggestions-server-service

reviewer-suggestions-repository:
    builder.git_latest:
        - name: git@github.com:elifesciences/reviewer-suggestions.git
        - identity: {{ pillar.elife.projects_builder.key or '' }}
        - rev: {{ salt['elife.rev']() }}
        - branch: {{ salt['elife.branch']() }}
        - target: /home/elife/prototype/project/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True

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
