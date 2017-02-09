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
        # TODO:
        # - require:
        #    - reviewer-suggestions-repository

    service.running:
        - name: reviewer-suggestions-server
        - require:
            - file: reviewer-suggestions-server-service

