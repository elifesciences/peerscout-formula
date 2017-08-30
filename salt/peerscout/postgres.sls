postgres-db-user:
    postgres_user.present:
        - name: {{ pillar.peerscout.db.username }}
        - encrypted: True
        - password: {{ pillar.peerscout.db.password }}
        - refresh_password: True
        - createdb: True

        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}
        # remote psql
        - db_user: {{ salt['elife.cfg']('project.rds_username') }}        
        - db_password: {{ salt['elife.cfg']('project.rds_password') }}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% else %}
        # local psql
        - db_user: {{ pillar.elife.db_root.username }}
        - db_password: {{ pillar.elife.db_root.password }}
        {% endif %}

postgres-db-exists:
    postgres_database.present:
        - owner: {{ pillar.peerscout.db.username }}

        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}
        # remote psql
        - name: {{ salt['elife.cfg']('project.rds_dbname') }}
        - db_user: {{ salt['elife.cfg']('project.rds_username') }}        
        - db_password: {{ salt['elife.cfg']('project.rds_password') }}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% else %}
        # local psql
        - name: {{ pillar.peerscout.db.name }}
        - db_user: {{ pillar.elife.db_root.username }}
        - db_password: {{ pillar.elife.db_root.password }}
        {% endif %}

        - require:
            - postgres_user: postgres-db-user
