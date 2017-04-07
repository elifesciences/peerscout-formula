postgres-db-user:
    postgres_user.present:
        - name: {{ pillar.reviewer_suggestions.db.username }}
        - encrypted: True
        - password: {{ pillar.reviewer_suggestions.db.password }}
        - refresh_password: True

        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}
        # remote psql
        - db_user: {{ salt['elife.cfg']('project.rds_username') }}        
        - db_password: {{ salt['elife.cfg']('project.rds_password') }}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% else %}
        - db_user: {{ pillar.elife.db_root.username }}
        - db_password: {{ pillar.elife.db_root.password }}
        {% endif %}
        - createdb: True

postgres-db-exists:
    postgres_database.present:
        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}    
        # remote psql
        - name: {{ salt['elife.cfg']('project.rds_dbname') }}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% else %}
        # local psql
        - name: {{ pillar.reviewer_suggestions.db.name }}
        {% endif %}
        - owner: {{ pillar.reviewer_suggestions.db.username }}
        - db_user: {{ pillar.elife.db_root.username }}
        - db_password: {{ pillar.elife.db_root.password }}
        - require:
            - postgres_user: postgres-db-user
