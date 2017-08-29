reviewer_suggestions:
    installation_path: /srv/reviewer-suggestions

    aws:
        access_key_id: null
        secret_access_key: null
        region: us-east-1

    db:
        name: reviewer_suggestions
        username: foouser # case sensitive. use all lowercase
        password: barpass
        host: 127.0.0.1
        port: 5432

    auth:
        auth0_domain: elife.auth0.com
        auth0_client_id: s0mwbpPUuDBuYAAFMxYUT6J9xF6pn67O
        valid_email_domains: elifesciences.org

    storage:
        xml_dump_bucket: elife-ejp-ftp-db-xml-dump

        ecr_bucket: elife-ejp-ftp
        ecr_prefix: ejp_query_tool_query_id_380_DataScience:_Early_Career_Researchers

        editors_bucket: elife-ejp-ftp
        editors_prefix: ejp_query_tool_query_id_455_DataScience:_Editors
