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
